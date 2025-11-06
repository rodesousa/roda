defmodule Roda.Workers.TranscribeWorker do
  use Oban.Worker,
    queue: :audio_transcribe,
    max_attempts: 3

  require Logger
  alias ExAws, as: Minio
  alias Roda.{Minio, Repo, Conversations}
  alias Roda.LLM

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{
          "conversation_id" => conversation_id,
          "action" => "delete"
        }
      }) do
    with {:ok, path} <- Conversations.get_conversation_minio_path(conversation_id) do
      :timer.sleep(3000)

      %{body: %{contents: contents}} = Minio.list(prefix: path)

      contents
      |> Enum.each(fn %{key: key} ->
        Minio.delete_object(key)
      end)

      Conversations.delete_conversation(conversation_id)

      :ok
    end
  end

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{
          "conversation_id" => conversation_id,
          "total_chunks" => total_chunks
        }
      }) do
    with {:ok, path} <- Conversations.get_conversation_minio_path(conversation_id),
         {:ok, conversation} <- get_conversation(conversation_id),
         {:ok, provider} <- get_provider(conversation.project.organization_id),
         {:ok, content} <- chunk_list(path, total_chunks) do
      Conversations.set_convervation_active(conversation)
      :timer.sleep(10000)

      content
      |> Enum.sort_by(fn %{key: key} ->
        [name, _] = Path.basename(key) |> String.split(".")
        name
      end)
      |> Enum.with_index(fn %{key: key}, index ->
        [chunk_uuid, _] = Path.basename(key) |> String.split(".")
        {:ok, audio_binary} = Minio.get_file(key)

        {:ok, text} = LLM.audio_transcribe(provider, audio_binary)

        create_chunk(
          %{
            id: chunk_uuid,
            position: index,
            conversation_id: conversation_id,
            path: key,
            text: text
          },
          conversation.project.organization_id
        )
      end)

      Conversations.Conversation.update_changeset(conversation, %{fully_transcribed: true})
      |> Repo.update!()

      # %{
      #   organization_id: conversation.project.organization_id,
      #   conversation_id: conversation.id
      # }
      # |> Roda.Workers.EntityExtractionWorker.new()
      # |> Oban.insert!()

      :ok
    else
      {:error, nil} ->
        Logger.warning("conversation_id #{conversation_id} not exists")
        :ok

      {:error, :chunk_empty} ->
        Logger.warning(
          "conversation_id #{conversation_id} folder doesn't have chunk in minio for"
        )

        :ok

      {:error, error} when error in [:conversation_not_found] ->
        Logger.warning("conversation_id #{conversation_id} doesn't exist")
        :ok
    end
  end

  defp create_chunk(args, _orga_id) do
    case Repo.get(Conversations.Chunk, args.id) do
      nil ->
        Conversations.add_chunk!(args)

      _ ->
        :ok
    end
  end

  defp get_provider(organization_id) do
    case Roda.Providers.get_provider_by_organization(organization_id, "audio") do
      nil -> {:error, :provider_not_found}
      provider -> {:ok, provider}
    end
  end

  defp get_conversation(conversation_id) do
    case Conversations.get_conversation(conversation_id) do
      nil -> {:error, :conversation_not_found}
      conversation -> {:ok, conversation}
    end
  end

  defp chunk_list(path, total_chunks) do
    Enum.reduce_while(0..2, {:error, :bad_count}, fn _c, acc ->
      case Minio.list(prefix: path) do
        %{body: %{contents: contents}} ->
          if length(contents) == total_chunks do
            Logger.debug("All Chunks are uploaded =)")
            {:halt, {:ok, contents}}
          else
            Logger.debug("All Chunks are not uploaded =(")
            :timer.sleep(1000)
            {:cont, acc}
          end

        error ->
          Logger.warning("Unexpected Minio.list result: #{inspect(error)}")
          :timer.sleep(1000)
          {:cont, acc}
      end
    end)
  end
end
