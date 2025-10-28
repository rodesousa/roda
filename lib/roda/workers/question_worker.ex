defmodule Roda.Workers.QuestionWorker do
  alias Roda.{Repo, Projects, Accounts, Questions}
  alias Roda.Questions.{QuestionResponse}
  alias Roda.Accounts.Scope
  require Logger

  use Oban.Worker,
    max_attempts: 3,
    queue: :question

  defp llm() do
    Application.get_env(:roda, :llm)
  end

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{
          "user_id" => user_id,
          "orga_id" => orga_id,
          "question_id" => question_id,
          "period_start" => %Date{} = period_start,
          "period_end" => %Date{} = period_end
        }
      }) do
    with {:ok, user} <- get_user(user_id),
         {:ok, orga, member} <- get_orga(user_id, orga_id),
         scope <- Scope.for_user_in_organization(user, orga, member),
         {:ok, question} <- get_question(question_id),
         {:ok, provider} <- get_provider(scope) do
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

      question_response = Organizations.get_response(question_id, period_start, period_end)

      prompt = prompt(question.prompt, text)

      with {:ok, content} <- llm().chat_completion2(provider, prompt) do
        response_args =
          %{
            "narrative_prompt" => content,
            "period_start" => period_start,
            "period_end" => period_end,
            "question_id" => question_id
          }
          |> QuestionResponse.changeset()
          |> Repo.insert!()

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

  defp prompt(question_prompt, content) do
    """
    ## Mission

    Produisez une analyse en DEUX parties, une narrative et une strucutré

    ## Partie 1 - Analyse narrative

    Répond à la question de manière détaillé en te basant uniquement les témoignages

    <question>
    #{question_prompt}
    </question>

    <regles>
    1. Un témoignage est composé de Chunk, chaque Chunk à un ID
    2. CITATIONS DES SOURCES : Quand tu fais une affirmation basée sur des témoignages, tu DOIS citer le Chunk ID. Format : [cite:uuid-1,uuid-2,uuid-3]
        Règles :
          - Place [cite:...] IMMÉDIATEMENT après l'affirmation (avant le point final)
          - Liste 2 à 5 UUIDs séparés par des virgules (PAS D'ESPACES)
          - Utilise les vrais UUIDs des conversations que je t'ai fournies
          - Ne cite que les conversations qui supportent VRAIMENT l'affirmation
    3. Aucune recommandation
    </regles>

    ## Partie 2 - Réponse strucutré en JSON

    Après l'analyse narrative, ajoute les thèmes exact en format JSON. Ces données structuré serviront pour suivre l'évolution des thèmes à travers une suite d'analyse de témoignage.

    <regles>
    Pour chaque thème identifié, indiquez :
    - 2-3 citations représentatives avec leurs chunk IDs
    - Les citations doivent être exactes (depuis les témoignages)

    La partie JSON doit commencer par ---JSON_START---
    - La partie JSON doit finir par ---JSON_END---
    - Le JSON doit être valide
    - N'utilise PAS de balise ```json
    </regles>

    Output:

    ---JSON_START---
    {
      "themes": [
        {
          "name": "nom du thème",
          "sentiment": "positive|negatif|neutral",
          "description": "description",
          "citations": ["exact citation 1", "exact citation  2"],
          "chunk_ids": ["uuid-1", "uuid-2", "uuid-3"]
        }
      ],
      "weak_signals": [
        {
          "name": "nom du signal",
          "sentiment": "positive|negatif|neutral",
          "description": "description",
          "citations": ["citation exacte"],
          "chunk_ids": ["uuid-1"]
        }
      ],
      ...
    }
    ---JSON_END---

    ## Témoignages

    #{content}
    """
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

  defp get_user(user_id) do
    case Accounts.get_user(user_id) do
      nil ->
        Logger.warning("user_id #{user_id} not found")
        :ok

      user ->
        {:ok, user}
    end
  end

  def get_orga(user_id, orga_id) do
    case Organizations.get_user_membership(user_id, orga_id) do
      {:error, _} ->
        Logger.warning("user_id #{user_id} are not in orga_id #{orga_id}")
        :ok

      orga ->
        orga
    end
  end

  defp get_provider(%Scope{} = s) do
    case Organizations.get_provider_by_organization(s, "chat") do
      nil ->
        Logger.warning("organization_id #{s.organization.id} not found")
        :ok

      provider ->
        {:ok, provider}
    end
  end
end
