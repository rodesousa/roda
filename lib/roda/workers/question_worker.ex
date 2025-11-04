defmodule Roda.Workers.QuestionWorker do
  alias Roda.{Repo, Accounts, Questions, Organizations}
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
          "period_start" => period_start,
          "period_end" => period_end
        }
      }) do
    with {:ok, user} <- get_user(user_id),
         {:ok, orga, member} <- get_orga(user_id, orga_id),
         {:ok, question} <- get_question(question_id),
         scope <- Scope.for_user_in_project(user, orga, member, question.project),
         {:ok, provider} <- get_provider(scope) do
      period_start = Date.from_iso8601!(period_start)
      period_end = Date.from_iso8601!(period_end)

      conversations =
        Organizations.get_conversations(
          scope,
          NaiveDateTime.new!(period_start, ~T[00:00:00]),
          NaiveDateTime.new!(period_end, ~T[23:59:59])
        )

      Logger.debug("#{length(conversations)} will be analysed")

      text =
        conversations
        |> Enum.reduce("", fn %{chunks: chunks}, acc ->
          temp =
            chunks
            |> Enum.sort_by(& &1.position)
            |> Enum.reduce("", fn %{text: text, id: id}, acc2 ->
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

      narrative_prompt = narrative_prompt(question.prompt, text)
      all_themes = Questions.get_all_themes(question_id)

      with {:ok, narrative} <-
             llm().chat_completion(provider, [%{role: "user", content: narrative_prompt}]),
           structured_prompt <- structured_prompt(narrative, all_themes),
           {:ok, structured_response} <-
             llm().chat_completion(provider, [%{role: "user", content: structured_prompt}]) do
        structured_response =
          structured_response
          |> clean_json_response()
          |> Jason.decode!()

        %{
          "narrative_response" => narrative,
          "structured_response" => structured_response,
          "period_start" => period_start,
          "period_end" => period_end,
          "question_id" => question_id
        }
        |> QuestionResponse.changeset()
        |> Repo.insert!()

        :ok
      else
        {:api_error, body} ->
          Logger.error("api_error Error: #{body}")
          :ok

        error ->
          Logger.error("Error: #{error}")
          :ok
      end

      :ok
    end
  end

  defp narrative_prompt(question_prompt, content) do
    """
    ## Mission

    Répond à la question de manière détaillé et appronfondie en te basant uniquement les témoignages. Il faut que l'analyse puisse permettre à un collectif de comprendre les dynamiques par rapport à la question posée.

    <question>
    #{question_prompt}
    </question>

    <regles>
    1. Un témoignage est composé de Chunk, chaque Chunk à un ID

    2. QUANTIFICATION quand possible :
       - "Un témoignage mentionne..."
       - "Deux témoignages décrivent..."
       - "5 témoignages convergent..."
       - "Plus de 10 témoignages rapportent..."
       - "La majorité des cas décrits..."
       - "Un cas isolé évoque..."
       - Si tu ne peux pas compter précisément, utilise : "Plusieurs témoignages" ou "De nombreux témoignages"

    3. CITATIONS DES SOURCES : Quand tu fais une affirmation basée sur des témoignages, tu DOIS citer le Chunk ID. Format : [cite:uuid-1,uuid-2,uuid-3]
        Règles :
          - Place [cite:uuid-1,uuid-2,uuid-3] IMMÉDIATEMENT après l'affirmation (avant le point final)
          - Le nombre d'UUIDs DOIT correspondre EXACTEMENT à ton affirmation quantitative :
            * "Un témoignage..." → 1 UUID
            * "Deux témoignages..." → 2 UUIDs
            * "Trois témoignages..." → 3 UUIDs
            * "5 témoignages..." → 5 UUIDs
            * "Plus de 10 témoignages..." → minimum 10 UUIDs listés
          - Si tu dis "Plusieurs témoignages" sans nombre → minimum 3 UUIDs
          - Si tu dis "De nombreux témoignages" sans nombre → minimum 5 UUIDs
          - ❌ INTERDIT : "10 témoignages convergent [cite:uuid-1,uuid-2]" (incohérence quantitative)
          - ✅ OBLIGATOIRE : "10 témoignages convergent [cite:uuid-1,uuid-2,uuid-3,uuid-4,uuid-5,uuid-6,uuid-7,uuid-8,uuid-9,uuid-10]"
          - Si tu n'as pas assez d'UUIDs pour justifier un nombre, MODÈRE ton affirmation
          - Utilise les UUIDs qui sont placé au dessus de chaque Chunk
          - Ne cite que les conversations qui supportent VRAIMENT l'affirmation

    4. Aucune recommandation

    5. CONCRÉTISATION SYSTÉMATIQUE :
       Quand tu identifies un phénomène abstrait, tu DOIS répondre à :
       - Comment cela se manifeste-t-il concrètement ?
       - Quels exemples précis dans les témoignages ?
       - Quels effets tangibles sur le quotidien ?

       ❌ INTERDIT : "Plusieurs salariés expriment un soulagement"
       ✅ OBLIGATOIRE : "Dans 5 témoignages, des salariés décrivent un soulagement :
           'Je gagne 2h par jour' [cite:...], 'Je peux enfin me concentrer sur...' [cite:...]"

       ❌ INTERDIT : "Cela crée des tensions"
       ✅ OBLIGATOIRE : "Ces tensions se manifestent par des conflits lors des réunions :
           'Les anciens ne nous écoutent plus' [cite:...], des refus de collaboration [cite:...],
           et un turnover accru dans l'équipe X [cite:...]"

    6. Il faut que la présentation soit en MARKDOWN.

    7. STRUCTURE RICHE :
       - Utilise des grandes parties (I, II, III) et des sous-parties (1., 2., 3.) en utiliant markdown
       - Chaque sous-partie = minimum 150-200 mots
       - Transitions entre parties pour montrer la logique d'ensemble
    </regles>

    ## Témoignages

    #{content}
    """
  end

  defp get_question(question_id) do
    case Questions.get(question_id) do
      {:error, _} ->
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

  defp clean_json_response(response) do
    response
    |> String.trim()
    |> String.replace(~r/^```json\s*/, "")
    |> String.replace(~r/^```\s*/, "")
    |> String.replace(~r/```\s*$/, "")
    |> String.trim()
  end

  def structured_prompt(narrative, previous_themes \\ []) do
    previous_themes_text =
      if Enum.empty?(previous_themes) do
        ""
      else
        previous_themes
        |> Enum.map(fn theme ->
          "- #{theme["hashed_name"]} : \"#{theme["name"]}\""
        end)
        |> Enum.join("\n")
      end

    """
    Voici une analyse détaillée basée sur des témoignages. Ta mission est d'extraire les données structurées au format JSON pour permettre le suivi de l'évolution des thèmes dans le temps.

    <analyse>
    #{narrative}
    </analyse>

    <themes_precedents>
    Les analyses précédentes ont identifié ces thèmes (format: identifiant_stable : "Nom affiché") :
    #{previous_themes_text}

    IMPORTANT pour le suivi temporel :
    - Si un thème dans l'analyse actuelle correspond conceptuellement à un thème précédent,
      RÉUTILISE le même **hashed_name** (l'identifiant stable)
    - Tu PEUX adapter le **name** (nom affiché) pour mieux refléter les nuances de l'analyse actuelle
    - Crée un NOUVEAU hashed_name uniquement si c'est un phénomène vraiment différent
    </themes_precedents>

    ## Instructions

    Extrais TOUS les thèmes identifiés (problème, solution, victoire, objectif) dans cette analyse (récurrents, émergents ou signes faibles).

    Pour chaque thème :
    1. **hashed_name** : Identifiant stable en snake_case (ex: "perte_d_autonomie", "victoire_collective")
       - Si correspond à un thème précédent → RÉUTILISE le même hashed_name
       - Si nouveau → Crée un identifiant descriptif court en anglais
       - Le meme **hashed_name** peut appraitre plusieurs fois avec des **name** différént
    2. **name** : formulé selon l'analyse actuelle (5-10 mots max)
       - OBLIGATOIRE : Utiliser les TERMES EXACTS de l'analyse, pas de paraphrase
    3. **sentiment** : "positif", "negatif" ou "neutre"
    4. **description** : Description concrète et autosuffisante en 3-4 phrases
       - RÈGLE D'OR : Utiliser un MAXIMUM de mots et expressions tirés DIRECTEMENT de l'analyse
       - La description SEULE doit permettre de comprendre :
         * Le thème : De quoi parle-t-on exactement ?
         * L'enjeu : Pourquoi c'est important ? Quels impacts ?
         * Les manifestations concrètes : Comment ça se passe dans les faits ?
         * Si c'est un problème solution, victoire ou un objectif
       - ❌ INTERDIT :
         * Descriptions abstraites
         * Paraphrases vagues ou génériques
         * Formulations qui pourraient s'appliquer à n'importe quel contexte
       - ✅ OBLIGATOIRE :
         * Reprendre les expressions-clés de l'analyse
         * Décrire les dynamiques concrètes observées
    5. **uuids** : Liste des numéros de références [1, 2, 3] qui apparaissent dans l'analyse

    ## Format de sortie

    Retourne UNIQUEMENT un JSON valide, sans balise markdown, sans texte avant ou après.

    ANTI-BIAIS : Les exemples ci-dessous sont UNIQUEMENT structurels. NE les utilise PAS comme guide thématique.
    Ta mission est d'extraire FIDÈLEMENT les thèmes de L'ANALYSE FOURNIE, pas de reproduire ces exemples.

    Structure attendue :
    {
      "themes": [
        {
          "hashed_name": "identifiant_stable_en_snake_case",
          "name": "Nom (5-10 mots, termes exacts de l'analyse)",
          "sentiment": "positif|negatif|neutre",
          "description": "Description autosuffisante en 3-4 phrases (100-150 mots). UTILISE les expressions exactes de l'analyse. Décris concrètement : (1) le thème (de quoi s'agit-il ?), (2) l'enjeu (pourquoi c'est important ?), (3) les manifestations concrètes (comment ça se passe dans les faits ?), (4) sa nature (problème, solution, victoire, objectif).",
          "uuids": ["uuid-1", "uuid-2", "uuid-3"]
        }
      ]
    }

    IMPORTANT :
    - Les uuids sont les numéros qui apparaissent dans l'analyse sous la forme [cite:uuid-1,uuid-2,uuid-3]
    - Si un thème n'a pas de références, mets un tableau vide: []
    - Retourne UNIQUEMENT le JSON, rien d'autre
    """
  end
end
