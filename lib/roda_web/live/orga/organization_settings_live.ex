defmodule RodaWeb.Orga.OrganizationSettingsLive do
  @moduledoc """
  Technical Debt
  - Avoid refactoring **just** to rename variables, your time is precious
  """
  use RodaWeb, :live_view

  alias Roda.{Repo, LLM, Accounts}
  alias Roda.{Organizations}
  alias Roda.LLM.Provider
  alias Roda.Accounts.User
  alias Roda.Organizations.OrganizationMembership

  @tabs ["users", "audio", "chat"]

  @impl true
  def mount(_, _session, socket) do
    ass = socket.assigns

    adapters = LLM.list_adapter()
    adapters_option = Enum.map(adapters, &{&1.id, &1.id})
    audio_provider = Organizations.get_provider_by_organization(ass.current_scope, "audio")
    chat_provider = Organizations.get_provider_by_organization(ass.current_scope, "chat")

    default_config = Roda.LLM.Adapters.Openai.default_config()

    chat_form =
      case chat_provider do
        nil ->
          Provider.changeset(%Provider{}, %{
            provider_type: default_config.id,
            api_base_url: default_config.api_base_url
          })
          |> to_form()

        chat ->
          Provider.changeset(chat, %{}) |> to_form()
      end

    audio_form =
      case audio_provider do
        nil ->
          Provider.changeset(%Provider{}, %{
            provider_type: default_config.id,
            api_base_url: default_config.api_base_url,
            type: "audio"
          })
          |> to_form()

        audio ->
          Provider.changeset(audio, %{}) |> to_form()
      end

    safe_provider = fn
      nil ->
        %Provider{}

      provider ->
        %{provider | api_key: ""}
    end

    safe_audio_provider = safe_provider.(audio_provider)
    safe_chat_provider_provider = safe_provider.(chat_provider)

    socket =
      socket
      |> assign(
        adapters_option: adapters_option,
        adapters: adapters,
        chat_provider: safe_chat_provider_provider,
        audio_provider: safe_audio_provider,
        chat_form: chat_form,
        audio_form: audio_form,
        role_form: to_form(%{}),
        user_to_delete: nil,
        user_to_role_changing: nil,
        test_errors: %{audio: nil, chat: nil, embedding: nil}
      )
      |> assign_users()
      |> assign_new_member()

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _, socket) do
    tab =
      case Map.get(params, "tab") in @tabs do
        true -> Map.get(params, "tab")
        false -> "users"
      end

    socket =
      assign(socket, tab: tab)

    {:noreply, socket}
  end

  defp assign_users(socket) do
    %{current_scope: scope} = socket.assigns

    users =
      Organizations.get_membership_by_organization(scope)
      |> Enum.map(fn m ->
        %{id: m.user.id, email: m.user.email, role: m.role}
      end)

    assign(socket, users: users)
  end

  defp assign_new_member(socket) do
    user = User.email_changeset(%User{}, %{})
    assign(socket, user_form: to_form(user))
  end

  @impl true
  def handle_event("select_provider", p, socket) do
    ass = socket.assigns

    provider =
      Enum.find(ass.adapters, fn %{id: id} ->
        id == p["provider_type"]
      end)

    socket =
      case p["submit"] do
        "save_audio" ->
          changeset =
            Provider.changeset(%Provider{}, %{
              model: "",
              type: "audio",
              provider_type: provider.id,
              api_base_url: provider.api_base_url
            })

          assign(socket, audio_form: to_form(changeset))

        _ ->
          changeset =
            Provider.changeset(%Provider{}, %{
              model: "",
              provider_type: provider.id,
              api_base_url: provider.api_base_url
            })

          assign(socket, chat_form: to_form(changeset))
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("delete", _p, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("set_role", _p, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("invite_member", %{"user" => user}, socket) do
    %{current_scope: scope} = socket.assigns

    socket =
      case Organizations.register_user(scope, user) do
        {:ok, %{user: user}} ->
          socket
          |> put_flash(:info, gettext("An email was sent to %{email}", %{email: user.email}))
          |> assign_users()
          |> assign_new_member()
          |> push_event("close:modal", %{id: "new-member"})

        changeset ->
          changeset = %{changeset | action: :validate}
          assign(socket, user_form: to_form(changeset))
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("tab", %{"tab" => tab}, socket) do
    tab =
      case tab in @tabs do
        true -> tab
        false -> "users"
      end

    socket =
      assign(socket,
        tab: tab,
        test_errors: %{audio: nil, chat: nil, embedding: nil}
      )

    {:noreply, socket}
  end

  ### TEST CONFIGURATION

  @impl true
  def handle_event("save_audio", %{"provider" => provider, "action" => "test"}, socket) do
    %{current_scope: scope} = ass = socket.assigns

    args =
      Map.merge(
        %{"organization_id" => scope.organization.id, "type" => "audio"},
        provider
      )

    socket =
      case Provider.changeset(args) do
        %{valid?: true} = changeset ->
          msg =
            changeset
            |> Ecto.Changeset.apply_changes()
            |> handle_llm_model_exists("audio")

          test_errors = Map.put(ass.test_errors, :audio, msg)
          changeset = %{changeset | action: :validate}
          assign(socket, test_errors: test_errors, audio_form: to_form(changeset))

        changeset ->
          changeset = %{changeset | action: :validate}
          assign(socket, audio_form: to_form(changeset))
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("save_chat", %{"provider" => provider, "action" => "test"}, socket) do
    %{current_scope: scope} = ass = socket.assigns
    args = Map.merge(%{"organization_id" => scope.organization.id, "type" => "chat"}, provider)

    socket =
      case Provider.changeset(ass.chat_provider, args) do
        %{valid?: true} = changeset ->
          msg =
            changeset
            |> Ecto.Changeset.apply_changes()
            |> handle_llm_model_exists("completion_chat")

          test_errors = Map.put(ass.test_errors, :chat, msg)
          changeset = %{changeset | action: :validate}
          assign(socket, test_errors: test_errors, chat_form: to_form(changeset))

        changeset ->
          changeset = %{changeset | action: :validate}
          assign(socket, chat_form: to_form(changeset))
      end

    {:noreply, socket}
  end

  ### SAVE CONFIGURATION

  @impl true
  def handle_event("save_audio", %{"provider" => provider_args, "action" => "save"}, socket) do
    %{current_scope: scope} = ass = socket.assigns

    args =
      Map.merge(%{"organization_id" => scope.organization.id, "type" => "audio"}, provider_args)

    socket =
      case Provider.changeset(ass.audio_provider, args) do
        %{valid?: true} = changeset ->
          provider =
            if ass.audio_provider.id, do: Repo.update!(changeset), else: Repo.insert!(changeset)

          assign(socket,
            audio_provider: provider,
            audio_form: to_form(changeset),
            test_errors: %{ass.test_errors | audio: {:ok, gettext("Configuration saved!")}}
          )

        changeset ->
          changeset = %{changeset | action: :validate}
          assign(socket, audio_form: to_form(changeset))
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("save_chat", %{"provider" => provider_args, "action" => "save"}, socket) do
    %{current_scope: scope} = ass = socket.assigns

    args =
      Map.merge(%{"organization_id" => scope.organization.id, "type" => "chat"}, provider_args)

    socket =
      case Provider.changeset(ass.chat_provider, args) do
        %{valid?: true} = changeset ->
          provider =
            if ass.chat_provider.id, do: Repo.update!(changeset), else: Repo.insert!(changeset)

          assign(socket,
            chat_provider: provider,
            chat_form: to_form(changeset),
            test_errors: %{ass.test_errors | chat: {:ok, gettext("Configuration saved!")}}
          )

        changeset ->
          changeset = %{changeset | action: :validate}
          assign(socket, chat_form: to_form(changeset))
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("member:change_role", %{"role" => role}, socket) do
    %{current_scope: scope} = ass = socket.assigns

    user =
      Enum.find(ass.users, &(&1.id == ass.user_to_role_changing.id))
      |> case do
        nil -> nil
        user -> {:ok, user}
      end

    socket =
      with true <- scope.membership.role == "admin",
           {:ok, user} <- user,
           {:ok, _} <- Organizations.set_membership_role(user.id, role) do
        socket
        |> assign(role_form: to_form(%{}))
        |> assign_users()
        |> push_event("close:modal", %{id: "member-role"})
      else
        _ -> socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("member:change_role:set", %{"id" => id}, socket) do
    %{current_scope: scope} = ass = socket.assigns
    id = String.to_integer(id)

    user =
      Enum.find(ass.users, &(&1.id == id))
      |> case do
        nil -> nil
        user -> {:ok, user}
      end

    socket =
      with true <- scope.membership.role == "admin",
           {:ok, user} <- user do
        assign(socket,
          user_to_role_changing: user,
          role_form: to_form(%{role: user.role})
        )
        |> push_event("open:modal", %{id: "member-role"})
      else
        _ -> socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("member:delete:set", %{"id" => id}, socket) do
    %{current_scope: scope} = ass = socket.assigns
    id = String.to_integer(id)

    user =
      Enum.find(ass.users, &(&1.id == id))
      |> case do
        nil -> nil
        user -> {:ok, user}
      end

    socket =
      with true <- scope.membership.role == "admin",
           false <- scope.user.id == id,
           {:ok, user} <- user,
           {:ok, _org, _} <- Organizations.get_user_membership(id, scope.organization.id) do
        socket
        |> assign(user_to_delete: user)
        |> push_event("open:modal", %{id: "delete-member"})
      else
        _ -> socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("member:delete", _p, socket) do
    %{current_scope: scope} = ass = socket.assigns

    user =
      Enum.find(ass.users, &(&1.id == ass.user_to_delete.id))
      |> case do
        nil -> nil
        user -> {:ok, user}
      end

    socket =
      with true <- scope.membership.role == "admin",
           false <- scope.user.id == ass.user_to_delete,
           {:ok, _user} <- user,
           {:ok, _org, _} <-
             Organizations.get_user_membership(ass.user_to_delete.id, scope.organization.id) do
        Accounts.delete_user(scope, ass.user_to_delete.id)

        socket
        |> assign_users()
        |> push_event("close:modal", %{id: "delete-member"})
      else
        _ -> socket
      end

    {:noreply, socket}
  end

  ## VERY EXPERIMENTAL
  ## ONLY WORKS WITH MISTRAL
  ## MOVE TO Roda.LLM
  defp handle_llm_model_exists(provider, capability) do
    model_exists? = fn response ->
      Enum.reduce_while(response, :no_lo_se, fn r, acc ->
        case Map.get(r, "name") == provider.model do
          true ->
            if get_in(r, ["capabilities", capability]) do
              {:halt, :ok}
            else
              {:halt, acc}
            end

          false ->
            {:cont, acc}
        end
      end)
    end

    with {:ok, response} <- LLM.models(provider),
         {:model, :ok} <- {:model, model_exists?.(response)} do
      {:ok, gettext("The configuration works, don't forget to save it!")}
    else
      {:error, :bad_api_key} ->
        {:error, gettext("Invalid API KEY")}

      {:model, :no_lo_se} ->
        {:warn, gettext("The configuration is ok but the model couldn’t be verified.")}
    end
  end

  defp provider_form(assigns) do
    ~H"""
    <.form
      :let={f}
      for={@form}
      phx-submit={@submit}
      phx-value-submit={@submit}
    >
      <div class="flex-col space-y-4">
        <div class="fieldset">
          <span class="label mb-1">{gettext("Provider type")}</span>
          <select
            class="select"
            phx-change="select_provider"
            name="provider_type"
            id={"provider-type-#{@submit}"}
          >
            <%= for {id, name} <- @options do %>
              <option value={id} selected={id == f[:provider_type].value}>{name}</option>
            <% end %>
          </select>
        </div>
        <.input
          field={f[:api_base_url]}
          label={gettext("API base url")}
        />
        <.input
          field={f[:provider_type]}
          type="hidden"
        />

        <.input
          type="password"
          field={f[:api_key]}
          label={gettext("API KEY")}
        />

        <.input
          options={[]}
          field={f[:model]}
          label={gettext("Model")}
        />
      </div>
      <.button value="test" name="action">
        {gettext("Test")}
      </.button>

      <.button value="save" name="action">
        {gettext("Save")}
      </.button>
    </.form>

    <div class="mt-2">
      <.test_errors error={@error} />
    </div>
    """
  end

  defp users_component(assigns) do
    ~H"""
    <div class="overflow-x-auto">
      <table class="table">
        <thead>
          <tr>
            <th>{gettext("Email")}</th>
            <th>{gettext("Role")}</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          <%= for u <- @users do %>
            <tr>
              <td>{u.email}</td>
              <td>{u.role}</td>
              <td class="space-y-2 items-center flex flex-col">
                <div
                  :if={@scope.membership.role == "admin" and u.id != @scope.user.id}
                  phx-click="member:change_role:set"
                  phx-value-id={u.id}
                  class="cursor-pointer"
                >
                  <.icon
                    class="w-5 h-5"
                    name="hero-user-plus"
                  />
                </div>
                <div
                  :if={@scope.membership.role == "admin" and u.id != @scope.user.id}
                  phx-click="member:delete:set"
                  phx-value-id={u.id}
                  class="cursor-pointer"
                >
                  <.icon
                    class="w-5 h-5"
                    name="hero-trash"
                  />
                </div>
              </td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
    """
  end

  defp test_errors(%{error: nil} = assigns) do
    ~H"""
    """
  end

  defp test_errors(%{error: {:ok, _}} = assigns) do
    ~H"""
    <div class="text-green-500">{elem(@error, 1)}</div>
    """
  end

  defp test_errors(%{error: {:warn, _}} = assigns) do
    ~H"""
    <div class="text-yellow-500">{elem(@error, 1)}</div>
    """
  end

  defp test_errors(%{error: {:error, _}} = assigns) do
    ~H"""
    <div class="text-red-500">{elem(@error, 1)}</div>
    """
  end
end
