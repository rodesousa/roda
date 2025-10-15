defmodule Roda.Workers.TranscribeWorker do
  use Oban.Worker,
    queue: :audio_transcribe,
    max_attempts: 3

  require Logger
  alias ExAws, as: Minio
  alias Roda.{Minio, Repo, Conversations}
  alias Roda.LLM

  defp chunk_list(path) do
    %{body: %{contents: content}} =
      Minio.list(prefix: path)

    if content == [] do
      {:error, :chunk_empty}
    else
      {:ok, content}
    end
  end

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{
          "conversation_id" => conversation_id
        }
      }) do
    with {:ok, path} <- Conversations.get_conversation_minio_path(conversation_id),
         {:ok, conversation} <- get_conversation(conversation_id),
         {:ok, provider} <- get_provider(conversation.project.organization_id),
         {:ok, content} <- chunk_list(path) do
      content
      |> Enum.sort_by(fn %{key: key} ->
        [name, _] = Path.basename(key) |> String.split(".")
        name
      end)
      |> Enum.with_index(fn %{key: key}, index ->
        {:ok, audio_binary} = Minio.get_file(key)
        text = "coucou"
        # LLM.audio_transcribe(provider, audio_binary)
        %{position: index, conversation_id: conversation_id, path: key, text: text}
        |> Conversations.add_chunk()
      end)

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

  defp get_provider(organization_id) do
    case Roda.Providers.get_provider_by_organization(organization_id, "audio") do
      nil -> {:error, :provider_not_found}
      provider -> {:ok, provider}
    end
  end

  defp get_conversation(convsersation_id) do
    case Conversations.get_conversation(convsersation_id) do
      nil -> {:error, :conversation_not_found}
      conversation -> {:ok, conversation}
    end
  end
end
