defmodule Roda.Conversations do
  @moduledoc """
  Technical debt:
  - Each functions using Conversation have to mentionned if active and fully_transcribed is used and why
  """
  alias Roda.Repo
  alias Roda.Accounts.Scope
  alias Roda.Conversations.{Chunk, Conversation}
  import Ecto.Query

  def delete_conversation(id) do
    Repo.get(Conversation, id)
    |> Repo.delete()
  end

  def can_delete_conversation?(%Scope{} = s, conversation_id) do
    Conversation
    |> where([c], c.id == ^conversation_id and c.project_id == ^s.project.id)
    |> preload([:project])
    |> Repo.one()
    |> case do
      nil ->
        false

      conversation ->
        conversation.project.organization_id == s.organization.id and s.membership.role == "admin"
    end
  end

  def add_chunk!(attrs) do
    Chunk.changeset(attrs)
    |> Repo.insert!()
  end

  def add_conversation!(attrs) do
    Conversation.changeset(attrs)
    |> Repo.insert!()
  end

  def get_chunk(chunk_id) do
    Chunk
    |> where([c], c.id == ^chunk_id)
    |> preload(:conversation)
    |> Repo.one()
  end

  def get_conversation(conversation_id) do
    Conversation
    |> where([c], c.id == ^conversation_id)
    |> preload(:project)
    |> preload(:chunks)
    |> Repo.one()
  end

  def list_conversations_by_range(
        %Scope{} = scope,
        %NaiveDateTime{} = begin_at,
        %NaiveDateTime{} = end_at
      ) do
    Conversation
    |> where(
      [c],
      c.project_id == ^scope.project.id and c.inserted_at >= ^begin_at and
        c.inserted_at <= ^end_at
    )
    |> preload(:chunks)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  def list_conversations_paginate(%Scope{} = s, params \\ []) do
    Conversation
    |> where([c], c.project_id == ^s.project.id and c.active == true)
    |> query_paginate(params)
    |> preload(:chunks)
    |> order_by(desc: :inserted_at)
    |> query_limit(params)
    |> Repo.all()
  end

  defp query_limit(query, params) do
    case Keyword.get(params, :limit) do
      :nolimit -> query
      number when is_number(number) -> limit(query, ^number)
      _ -> limit(query, 10)
    end
  end

  defp query_paginate(query, params) do
    case Keyword.get(params, :last_id) do
      nil -> query
      id -> where(query, [q], q.id > ^id)
    end
  end

  def list_conversations_by_project_id(project_id) do
    Conversation
    |> where([c], c.project_id == ^project_id)
    |> preload(:chunks)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  def get_conversation_minio_path(conversation_id) do
    case get_conversation(conversation_id) do
      nil ->
        {:error, nil}

      conversation ->
        {:ok,
         "org_#{conversation.project.organization_id}/proj_#{conversation.project.id}/conv_#{conversation.id}"}
    end
  end

  def get_chunk_by_ids(ids) do
    Chunk
    |> where([c], c.id in ^ids)
    |> select([c], %{id: c.id, text: c.text})
    |> Repo.all()
  end

  def set_convervation_active(%Conversation{active: false} = c) do
    Conversation.update_changeset(c, %{active: true})
    |> Repo.update!()
  end

  def set_convervation_active(c), do: c
end
