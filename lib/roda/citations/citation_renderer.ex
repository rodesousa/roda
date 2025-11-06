defmodule Roda.Citations.CitationRenderer do
  @moduledoc """
  Generates citation modals server-side and provides a map for JavaScript replacement.

  Shame on me ...
  """

  @doc """
  Extracts all unique citation groups from text and returns modals HTML + citation map.

  ## Example

      iex> text = "Foo [cite:uuid1,uuid2] bar [cite:uuid3]"
      iex> conversations = [%{id: "uuid1", text: "..."}, ...]
      iex> CitationRenderer.prepare_citations(text, conversations)
      %{
        modals_html: "<dialog id='modal_123'>...</dialog>...",
        citation_map: %{"uuid1,uuid2" => "modal_123", "uuid3" => "modal_456"}
      }
  """
  def prepare_citations(text, conversations) do
    # Extract all unique citation groups
    citation_groups = extract_citation_groups(text)

    # Create a map of conversation_id => conversation data
    conversations_by_id = Map.new(conversations, fn conv -> {conv.id, conv} end)

    # Generate modals and build citation map
    {modals_html, citation_map} =
      citation_groups
      |> Enum.with_index()
      |> Enum.map(fn {ids_string, index} ->
        modal_id = "citation_modal_#{index}"
        ids = String.split(ids_string, ",") |> Enum.map(&String.trim/1)

        # Get conversations for these IDs
        cited_convs =
          Enum.filter(ids, &Map.has_key?(conversations_by_id, &1))
          |> Enum.map(&Map.get(conversations_by_id, &1))

        modal_html = generate_modal_html(modal_id, cited_convs)

        {modal_html, {ids_string, modal_id}}
      end)
      |> Enum.unzip()

    %{
      modals_html: Enum.join(modals_html, "\n"),
      citation_map: Map.new(citation_map)
    }
  end

  defp extract_citation_groups(text) do
    ~r/\[cite:([^\]]+)\]/
    |> Regex.scan(text, capture: :all_but_first)
    |> Enum.map(&hd/1)
    |> Enum.uniq()
  end

  defp generate_modal_html(modal_id, conversations) do
    count = length(conversations)

    citations_html =
      conversations
      |> Enum.map(fn conv ->
        """
        <div class="mb-4 p-3 bg-base-200 rounded-lg border border-base-300">
          <blockquote class="border-l-4 border-primary pl-3">
            <p class="italic text-sm">#{escape_html(conv.text)}</p>
          </blockquote>
        </div>
        """
      end)
      |> Enum.join("\n")

    """
    <dialog id="#{modal_id}" class="modal">
      <div class="modal-box w-[95vw] md:w-11/12 md:max-w-7xl h-auto max-h-[60vh] md:max-h-[85vh]">
        <form method="dialog">
          <button class="btn btn-sm btn-circle btn-ghost absolute right-2 top-2">&times;</button>
        </form>
        <h3 class="text-lg font-bold mb-4">Sources (#{count})</h3>
        <div class="overflow-y-auto h-full max-h-[calc(60vh-5rem)] md:max-h-[calc(85vh-5rem)]">
          #{citations_html}
        </div>
      </div>
      <form method="dialog" class="modal-backdrop">
        <button>close</button>
      </form>
    </dialog>
    """
  end

  defp escape_html(text) do
    text
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&#39;")
  end
end
