defmodule Roda.Invite.InviteAccessToken do
  use Ecto.Schema
  import Ecto.Query
  alias Roda.Organizations.Project
  alias Roda.Invite.InviteAccessToken

  @hash_algorithm :sha256
  @testify_token_validity_in_days 7
  @rand_size 32

  schema "invite_access_tokens" do
    field :token, :binary
    field :authenticated_at, :utc_datetime
    belongs_to :project, Project, type: :binary_id

    timestamps(type: :utc_datetime, updated_at: false)
  end

  @doc """
  Generates a token that will be stored in a signed place,
  such as session or cookie. As they are signed, those
  tokens do not need to be hashed.

  The reason why we store session tokens in the database, even
  though Phoenix already provides a session cookie, is because
  Phoenix' default session cookies are not persisted, they are
  simply signed and potentially encrypted. This means they are
  valid indefinitely, unless you change the signing/encryption
  salt.

  Therefore, storing them allows individual project
  sessions to be expired. The token system can also be extended
  to store additional data, such as the device used for logging in.
  You could then use this information to display all valid sessions
  and devices in the UI and allow projects to explicitly expire any
  session they deem invalid.
  """
  def build_token(%Project{} = project) do
    token = :crypto.strong_rand_bytes(@rand_size)
    hashed_token = :crypto.hash(@hash_algorithm, token)
    dt = DateTime.utc_now(:second)

    {Base.url_encode64(token, padding: false),
     %__MODULE__{token: hashed_token, project_id: project.id, authenticated_at: dt}}
  end

  @doc """
  Checks if the token is valid and returns its underlying lookup query.

  The query returns the project found by the token, if any, along with the token's creation time.

  The token is valid if it matches the value in the database and it has
  not expired (after @testify_token_validity_in_days).
  """
  def verify_token_query(token) do
    case decode_token(token) do
      {:ok, decoded_token} ->
        __MODULE__
        |> where(
          [i],
          i.token == ^decoded_token and
            i.inserted_at > ago(@testify_token_validity_in_days, "day")
        )
        |> preload(:project)

      _ ->
        nil
    end
  end

  def decode_token(token) do
    Base.url_decode64(token, padding: false)
  end

  @doc """
  """
  def verify_project_query(project_id) do
    InviteAccessToken
    |> where(
      [i],
      i.project_id == ^project_id and i.inserted_at > ago(@testify_token_validity_in_days, "day")
    )
  end
end
