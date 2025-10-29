defmodule Roda.Invite do
  alias Roda.Invite.InviteAccessToken
  alias Roda.Accounts.Scope
  alias Roda.Repo

  @doc """
  Generates a token.
  """
  def generate_project_token(%Scope{} = s) do
    {token, invite_token} = InviteAccessToken.build_token(s.project)
    Repo.insert!(invite_token)
    token
  end

  @doc """

  """
  def get_projet_token_by_token(token) do
    case InviteAccessToken.verify_token_query(token) do
      nil ->
        {:error, :not_found}

      query ->
        case Repo.one(query) do
          nil -> {:error, :not_found}
          token -> {:ok, token}
        end
    end
  end

  @doc """

  """
  def get_projet_token_by_project(%Scope{} = s) do
    InviteAccessToken.verify_project_query(s.project.id)
    |> Repo.one()
    |> case do
      nil ->
        {:error, :not_found}

      invite ->
        token = Base.url_encode64(invite.token, padding: false)
        {:ok, token}
    end
  end
end
