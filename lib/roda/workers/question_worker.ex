defmodule Roda.Workers.QuestionWorker do
  alias Roda.{Analyses, Repo, Embeddings, Providers, Projects}
  alias Roda.{Organizations, Questions}
  alias Roda.Questions.{Question, QuestionResponse}
  alias Roda.Date
  require Logger

  use Oban.Worker,
    max_attempts: 3,
    queue: :question

  defp llm() do
    Application.get_env(:roda, :llm)
  end

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{"question_id" => question_id}
      }) do
    with {:ok, question} <- get_question(question_id),
         {:ok, provider} <- get_provider(question.project.organization_id) do
      OUI
      |> IO.inspect(label: " ")

      text =
        Projects.get_conversations(question.project_id)
        |> Enum.reduce("", fn %{chunks: chunks}, acc ->
          temp =
            chunks
            |> Enum.sort_by(& &1.position)
            |> Enum.reduce(acc, fn %{text: text, id: id}, acc2 ->
              """
              #{acc2}

              Chunk ID: #{id}
              #{text}
              """
            end)

          """
          #{acc}

          Témoignage:
          #{temp}
          ---
          """
        end)

      prompt =
        """
        <question>
        #{question.prompt}
        </question>

        <regles>
        1. Un témoignage est composé de Chunk, chaque Chunk à un ID
        2. CITATIONS DES SOURCES : Quand tu fais une affirmation basée sur des témoignages, tu DOIS citer le Chunk ID. Format : [cite:uuid-1,uuid-2,uuid-3]
            Règles :
              - Place [cite:...] IMMÉDIATEMENT après l'affirmation (avant le point final)
              - Liste 2 à 5 UUIDs séparés par des virgules (PAS D'ESPACES)
              - Utilise les vrais UUIDs des conversations que je t'ai fournies
              - Ne cite que les conversations qui supportent VRAIMENT l'affirmation
        </regles>

        <text>
        #{text}
        </text>
        """

      with {:ok, content} <- llm().chat_completion2(provider, prompt) do
        OUIOUI
        |> IO.inspect(label: " !!")

        QuestionResponse.changeset(%{
          response_text: content,
          period_start: Date.beginning_of_week(),
          period_end: Date.end_of_week(),
          conversations_analyzed_count: 1,
          question_id: question_id
        })
        |> IO.inspect(label: " CHANGESET")
        |> Repo.insert!()
        |> IO.inspect(label: " INSERT!")

        :ok
      else
        {:api_error, body} ->
          Logger.error("Error: #{body}")
          :ok

        error ->
          Logger.error("Error: #{error}")
          :ok
      end

      :ok
    end
  end

  defp get_question(question_id) do
    case Questions.get(question_id) do
      nil ->
        Logger.warning("question_id #{question_id} not found")
        :ok

      question ->
        {:ok, question}
    end
  end

  defp get_provider(organization_id) do
    case Providers.get_provider_by_organization(organization_id, "chat") do
      nil ->
        Logger.warning("organization_id #{organization_id} not found")
        :ok

      provider ->
        {:ok, provider}
    end
  end

  # @impl Oban.Worker
  # def perform(%Oban.Job{
  #       args: %{"analyse_id" => analyse_id}
  #     }) do
  #   qas =
  #     Analyses.get_question_analyses(analyse_id)
  #
  #   project_id =
  #     qas
  #     |> hd
  #     |> Map.get(:analyse)
  #     |> Map.get(:project_id)
  #
  #   organization_id =
  #     Repo.get(Roda.Organizations.Projects, project_id)
  #     |> Map.get(:organization_id)
  #
  #   provider =
  #     Repo.get(Organization, organization_id)
  #     |> Roda.Providers.get_provider_by_organization("chat")
  #
  #   text =
  #     Roda.Projects.get_conversations(project_id)
  #     |> Enum.reduce("", fn %{chunks: chunks}, acc ->
  #       temp =
  #         chunks
  #         |> Enum.sort_by(& &1.position)
  #         |> Enum.reduce(acc, fn %{text: text, id: id}, acc2 ->
  #           """
  #           #{acc2}
  #
  #           Chunk ID: #{id}
  #           #{text}
  #           """
  #         end)
  #
  #       """
  #       #{acc}
  #
  #       Témoignage:
  #       #{temp}
  #       ---
  #       """
  #     end)
  #
  #   # <regles>
  #   #   1. Un témoignage est composé de Chunk, chaque Chunk à un ID
  #   #   2. CITATIONS DES SOURCES : Quand tu fais une affirmation basée sur des témoignages, tu DOIS citer le Chunk ID avec l'excerpt exact. Format : [cite:uuid-1|"passage exact du témoignage",uuid-2|"autre passage"]
  #   #   - Place [cite:...] IMMÉDIATEMENT après l'affirmation (avant le point final)
  #   #   - Format : uuid|"excerpt exact" (pas d'espaces autour du pipe |)
  #   #   - L'excerpt doit être le passage EXACT copié du témoignage (entre guillemets doubles)
  #   #   - Liste 2 à 5 citations séparées par des virgules (PAS D'ESPACES autour du pipe)
  #   #   - Utilise les vrais UUIDs des chunks que je t'ai fournis
  #   #   - Ne cite que les témoignages qui supportent VRAIMENT l'affirmation
  #   # </regles>
  #
  #   Enum.map(qas, fn qa ->
  #     prompt = """
  #     <question>
  #     #{qa.question.prompt}
  #     </question>
  #
  #     <regles>
  #     1. Un témoignage est composé de Chunk, chaque Chunk à un ID
  #     2. CITATIONS DES SOURCES : Quand tu fais une affirmation basée sur des témoignages, tu DOIS citer le Chunk ID. Format : [cite:uuid-1,uuid-2,uuid-3]
  #         Règles :
  #           - Place [cite:...] IMMÉDIATEMENT après l'affirmation (avant le point final)
  #           - Liste 2 à 5 UUIDs séparés par des virgules (PAS D'ESPACES)
  #           - Utilise les vrais UUIDs des conversations que je t'ai fournies
  #           - Ne cite que les conversations qui supportent VRAIMENT l'affirmation
  #     </regles>
  #
  #     <text>
  #     #{text}
  #     </text>
  #     """
  #
  #     result = llm().chat_completion2(provider, prompt)
  #
  #     with {:ok, content} <- result do
  #       Roda.Questions.QuestionAnalyseResponse.changeset(%{
  #         response_text: content,
  #         period_start: Roda.Date.beginning_of_week(),
  #         period_end: Roda.Date.end_of_week(),
  #         conversations_analyzed_count: 1,
  #         question_id: qa.question_id,
  #         analyse_id: qa.analyse_id
  #       })
  #       |> IO.inspect(label: " QUOI !")
  #       |> Repo.insert!()
  #
  #       :ok
  #     else
  #       {:api_error, body} ->
  #         Logger.error("Error: #{body}")
  #         :ok
  #
  #       error ->
  #         Logger.error("Error: #{error}")
  #         :ok
  #     end
  #   end)
  #
  #   # Repo.all(Roda.LLM.Provider)
  #   # Roda.Proiders.get_provider_by_organization()
  #
  #   :ok
  # end
end
