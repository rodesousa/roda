defmodule Roda.Prompts do
  @moduledoc """
  Context for managing prompt conversations and messages.
  """

  import Ecto.Query, warn: false
  alias Roda.Repo
  alias Roda.Accounts.Scope
  alias Roda.Prompts.{PromptConversation, PromptMessage}

  def get_prompt_conversation(%Scope{} = s, id) do
    PromptConversation
    |> where([pc], pc.id == ^id and pc.project_id == ^s.project.id)
    |> Repo.one()
  end

  @doc """
  Lists all conversations for a project.

  ## Example

      iex> list_conversations(scope)
      [%PromptConversation{}, ...]
  """
  def list_conversations(%Scope{} = scope) do
    from(c in PromptConversation,
      where: c.project_id == ^scope.project.id,
      order_by: [desc: c.updated_at],
      preload: [:messages]
    )
    |> Repo.all()
  end

  @doc """
  Returns a conversation with messages preloaded.

  ## Example

      iex> get_conversation(scope, "123")
      {:ok, %PromptConversation{}}
  """
  def get_conversation(%Scope{} = scope, id) do
    case from(c in PromptConversation,
           where: c.id == ^id and c.project_id == ^scope.project.id,
           preload: [messages: ^from(m in PromptMessage, order_by: [asc: m.inserted_at])]
         )
         |> Repo.one() do
      nil -> {:error, :not_found}
      conversation -> {:ok, conversation}
    end
  end

  @doc """
  Creates a new conversation.

  ## Example

      iex> create_conversation(scope, %{title: "New chat", provider_id: "openai", model: "gpt-4"})
      {:ok, %PromptConversation{}}
  """
  def create_conversation(%Scope{} = scope, attrs) do
    attrs = Map.put(attrs, :project_id, scope.project.id)

    %PromptConversation{}
    |> PromptConversation.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  """
  def update_conversation_period(%PromptConversation{} = pc, args) do
    case PromptConversation.update_period_changeset(pc, args) do
      %{valid?: true} = changeset -> Repo.update(changeset)
      changeset -> {:error, changeset}
    end
  end

  @doc """
  Updates conversation title.

  ## Example

      iex> update_conversation_title("123", "New title")
      {:ok, %PromptConversation{}}
  """
  def update_conversation_title(%PromptConversation{} = pc, args) do
    case PromptConversation.update_title_changeset(pc, args) do
      %{valid?: true} = changeset -> Repo.update(changeset)
      changeset -> {:error, changeset}
    end
  end

  @doc """
  Adds a message to a conversation.

  ## Example

      iex> add_message("123", "user", "Hello!")
      {:ok, %PromptMessage{}}
  """
  def add_message(conversation_id, role, content) do
    %PromptMessage{}
    |> PromptMessage.changeset(%{
      conversation_id: conversation_id,
      role: role,
      content: content
    })
    |> Repo.insert()
  end

  @doc """
  Returns messages for a conversation ordered by insertion time.

  ## Example

      iex> get_messages("123")
      [%PromptMessage{}, ...]
  """
  def get_messages(conversation_id) do
    from(m in PromptMessage,
      where: m.conversation_id == ^conversation_id,
      order_by: [asc: m.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Deletes a conversation and all its messages.

  ## Example

      iex> delete_conversation(%Scope{}, "123")
      {:ok, %PromptConversation{}}
  """
  def delete_conversation(%Scope{} = scope, id) do
    case get_conversation(scope, id) do
      {:ok, conversation} ->
        Repo.delete(conversation)

      error ->
        error
    end
  end
end
