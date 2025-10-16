defmodule Roda.Llm.Adapters.LlmMock do
  @behaviour Roda.Llm.LlmBehaviour

  def chat_completion(_, _) do
    """
    entity|Macron|PERSON|Macron est une personnalité politique qui a rencontré Yaël Braun-Pivet
    entity|Yaël Braun-Pivet|PERSON|Yaël Braun-Pivet est la présidente de l'Assemblée nationale qui pense que la dissolution ne résoudra rien
    entity|Assemblée nationale|ORGANIZATION|Assemblée nationale est l'institution législative dont Yaël Braun-Pivet est la présidente
    entity|Dissolution|CONCEPT|Dissolution est une mesure politique que Macron n'a pas évoquée et que Yaël Braun-Pivet pense inefficace
    entity|Stabilité institutionnelle|CONCEPT|Stabilité institutionnelle est une préoccupation exprimée par Yaël Braun-Pivet qui met en garde contre la déstabilisation des institutions
    """
  end

  def embeddings(_, _) do
    [
      %{
        "embedding" => Enum.to_list(0..1023),
        "index" => 0,
        "object" => "embedding"
      }
    ]
  end

  def audio_transcribe(_, _) do
  end
end
