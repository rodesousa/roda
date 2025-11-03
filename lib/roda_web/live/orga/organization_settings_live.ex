defmodule RodaWeb.Orga.OrganizationSettingsLive do
  @moduledoc """
  Provides an interface for users to share their testimony either vocally or through text.
  """
  use RodaWeb, :live_view

  alias Roda.{Repo, Accounts}
  alias Roda.{Organizations}
  alias Roda.LLM.Provider
  alias Roda.Accounts.User

  defp llm() do
    Application.get_env(:roda, :llm)
  end

  @tabs ["users", "embedding", "audio", "chat"]

  @impl true
  def mount(_, _session, socket) do
    ass = socket.assigns
    audio_provider = Organizations.get_provider_by_organization(ass.current_scope, "audio")
    chat_provider = Organizations.get_provider_by_organization(ass.current_scope, "chat")

    chat_form =
      case chat_provider do
        nil -> Provider.changeset(%{}) |> to_form()
        chat -> Provider.changeset(chat, %{}) |> to_form()
      end

    audio_form =
      case audio_provider do
        nil -> Provider.changeset(%{type: "audio"}) |> to_form()
        audio -> Provider.changeset(audio, %{}) |> to_form()
      end

    safe_provider = fn
      nil ->
        nil

      provider ->
        %{provider | api_key: ""}
    end

    safe_audio_provider = safe_provider.(audio_provider)
    safe_chat_provider_provider = safe_provider.(chat_provider)

    socket =
      socket
      |> assign(
        chat_provider: safe_chat_provider_provider,
        audio_provider: safe_audio_provider,
        orga_form: to_form(%{}),
        chat_form: chat_form,
        audio_form: audio_form,
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
        false -> "projects"
      end

    socket =
      assign(socket, tab: tab)

    {:noreply, socket}
  end

  @impl true
  def handle_event("regenerate_invite", _p, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("copy_invite_link", _p, socket) do
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
      case Organizations.register_user_and_invite(scope, user) do
        {:ok, %{user: user}} ->
          {:ok, _} =
            Accounts.deliver_login_instructions(
              user,
              &url(~p"/users/log-in/#{&1}")
            )

          socket
          |> put_flash(:info, gettext("An email was sent to %{email}", %{email: user.email}))
          |> assign_users()
          |> assign_new_member()
          |> push_event("close:modal", %{id: "new-member"})

        {:error, %Ecto.Changeset{} = changeset} ->
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
      case Provider.changeset(args) do
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
            if ass.audio_provider, do: Repo.update!(changeset), else: Repo.insert!(changeset)

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
            if ass.chat_provider, do: Repo.update!(changeset), else: Repo.insert!(changeset)

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
  def render(assigns) do
    ~H"""
    <.page
      current="settings"
      scope={@current_scope}
    >
      <.page_content>
        <div class="tabs tabs-lift">
          <input
            type="radio"
            name="my_tabs_3"
            class="tab"
            aria-label={gettext("Users")}
            phx-click="tab"
            phx-value-tab="users"
            checked={@tab == "users"}
          />
          <div class="tab-content bg-base-100 border-base-300 p-6">
            <.new_user_component user_form={@user_form} />
            <.button phx-click={show_modal("new-member")}>
              {gettext("New member")}
            </.button>
            <.users_component users={@users} />
          </div>

          <input
            type="radio"
            name="my_tabs_3"
            class="tab"
            aria-label={gettext("Audio")}
            phx-click="tab"
            phx-value-tab="audio"
            checked={@tab == "audio"}
          />
          <div class="tab-content bg-base-100 border-base-300 p-6">
            <.provider_form
              form={@audio_form}
              error={@test_errors.audio}
              submit="save_audio"
            />
          </div>

          <input
            type="radio"
            name="my_tabs_3"
            class="tab"
            aria-label={gettext("Chat")}
            phx-click="tab"
            phx-value-tab="chat"
            checked={@tab == "chat"}
          />
          <div class="tab-content bg-base-100 border-base-300 p-6">
            <.provider_form
              form={@chat_form}
              error={@test_errors.chat}
              submit="save_chat"
            />
          </div>
          <input
            :if={false}
            type="radio"
            name="my_tabs_3"
            class="tab"
            aria-label={gettext("Embedding")}
            phx-click="tab"
            phx-value-tab="embedding"
            checked={@tab == "embedding"}
          />
          <div class="tab-content bg-base-100 border-base-300 p-6">
            <.orga_embedding_form form={@orga_form} test_errors={@test_errors} />
          </div>
        </div>
      </.page_content>
    </.page>
    """
  end

  defp orga_embedding_form(assigns) do
    ~H"""
    <.form :let={f} for={@form} phx-submit="set_embedding">
      <div class="flex-col space-y-4">
        <.input
          type="number"
          field={f[:embedding_dimension]}
          label={gettext("Embedding dimension number")}
        />
        <.input
          field={f[:embedding_api_base_url]}
          label={gettext("Embedding API base url")}
        />
        <.input
          type="select"
          options={[]}
          field={f[:embedding_provider_type]}
          label={gettext("Embedding provider type")}
        />
        <.input
          type="text"
          options={[]}
          field={f[:model]}
          label={gettext("Model")}
        />
        <.input
          type="password"
          field={f[:embedding_encrypted_api_key]}
          label={gettext("Embedding encrypted API key")}
        />
      </div>
      <.button>
        {gettext("Create")}
      </.button>
    </.form>
    """
  end

  defp provider_form(assigns) do
    ~H"""
    <.form :let={f} for={@form} phx-submit={@submit}>
      <div class="flex-col space-y-4">
        <.input
          type="select"
          options={[{"openai", "openai"}, {"anthropic", "anthropic"}]}
          field={f[:provider_type]}
          label={gettext("Provider type")}
        />
        <.input
          type="password"
          field={f[:api_key]}
          label={gettext("API KEY")}
        />
        <.input
          field={f[:api_base_url]}
          label={gettext("API base url")}
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

  def users_component(assigns) do
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
              <td>
                <.dropdown name={gettext("options")}>
                  <:items>
                    <li :if={u.role == "invite"} phx-click="copy_invite_link">
                      {gettext("COpy invite link")}
                    </li>
                  </:items>
                </.dropdown>
              </td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
    """
  end

  def new_user_component(assigns) do
    ~H"""
    <.modal id="new-member">
      <.form :let={f} for={@user_form} phx-submit="invite_member">
        <div class="flex-col space-y-4 py-4">
          <.input field={f[:email]} label={gettext("Email")} />
        </div>
        <div class="modal-action">
          <.button type="submit">
            {gettext("Create")}
          </.button>
          <.button type="button" phx-click={hide_modal("new-member")}>
            {gettext("Cancel")}
          </.button>
        </div>
      </.form>
    </.modal>
    """
  end

  defp test_errors(%{error: nil} = assigns) do
    ~H"""
    """
  end

  defp test_errors(%{error: {:ok, msg}} = assigns) do
    ~H"""
    <div class="text-green-500">{msg}</div>
    """
  end

  defp test_errors(%{error: {:warn, msg}} = assigns) do
    ~H"""
    <div class="text-yellow-500">{msg}</div>
    """
  end

  defp test_errors(%{error: {:error, msg}} = assigns) do
    ~H"""
    <div class="text-red-500">{msg}</div>
    """
  end

  def assign_users(socket) do
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

  ## VERY EXPERIMENTAL
  ## ONLY WORKS WITH MISTRAL
  ## MOVE TO Roda.LLM
  defp handle_llm_model_exists(provider, capability) do
    response =
      provider
      |> llm().models()

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

    with {:ok, response} <- response,
         {:model, :ok} <- {:model, model_exists?.(response)} do
      {:ok, gettext("The configuration works, don't forget to save it!")}
    else
      {:error, :bad_api_key} ->
        {:error, gettext("Invalid API KEY")}

      {:model, :no_lo_se} ->
        {:warn, gettext("The configuration is ok but the model couldn’t be verified.")}
    end
  end
end
