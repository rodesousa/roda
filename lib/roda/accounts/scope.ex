defmodule Roda.Accounts.Scope do
  @moduledoc """
  Defines the scope of the caller to be used throughout the app.

  The `Roda.Accounts.Scope` allows public interfaces to receive
  information about the caller, such as if the call is initiated from an
  end-user, and if so, which user. Additionally, such a scope can carry fields
  such as "super user" or other privileges for use as authorization, or to
  ensure specific code paths can only be access for a given scope.

  It is useful for logging as well as for scoping pubsub subscriptions and
  broadcasts when a caller subscribes to an interface or performs a particular
  action.

  Feel free to extend the fields on this struct to fit the needs of
  growing application requirements.
  """

  alias Roda.Accounts.User
  alias Roda.Organizations.{Organization, OrganizationMembership}

  @type t :: %__MODULE__{
    user: %User{},
    organization: %Organization{},
    membership: %OrganizationMembership{}
  }

  defstruct user: nil,
            organization: nil,
            # contient le role de l'user dans l'orga
            membership: nil

  @doc """
  Creates a scope for the given user.

  Returns nil if no user is given.
  """
  def for_user(%User{} = user) do
    %__MODULE__{user: user}
  end

  def for_user(nil), do: nil

  @doc """
  Creates a scope for a user within a specific organization.
  """
  def for_user_in_organization(
        %User{} = user,
        %Organization{} = org,
        %OrganizationMembership{} = membership
      ) do
    %__MODULE__{
      user: user,
      organization: org,
      membership: membership
    }
  end

  @doc """
  Checks if the current scope has admin rights in the organization.
  """
  def admin?(%__MODULE__{membership: %{role: "admin"}}), do: true
  def admin?(_), do: false

  @doc """
  Checks if the current scope has manager rights (admin or manager).
  """
  def manager?(%__MODULE__{membership: %{role: role}}) when role in ["admin", "manager"], do: true
  def manager?(_), do: false

  @doc """
  Checks if the current scope is a member of the organization.
  """
  def member?(%__MODULE__{membership: %{role: _}}), do: true
  def member?(_), do: false

  @doc """
  Checks if the current scope has a specific role.
  """
  def has_role?(%__MODULE__{membership: %{role: role}}, role), do: true
  def has_role?(_, _), do: false
end
