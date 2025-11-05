defmodule RodaWeb.UserLive.Settings do
  use RodaWeb, :live_view

  on_mount {RodaWeb.UserAuth, :require_sudo_mode}

  alias Roda.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <RodaWeb.Layouts.page scope={@current_scope} flash={@flash}>
      <RodaWeb.Layouts.page_content>
        <div class="text-center mb-10">
          <.header>
            {gettext("Account Settings")}
            <:subtitle>
              {gettext("Manage your account email address and password settings")}
            </:subtitle>
          </.header>
        </div>

        <div class="max-w-3xl mx-auto space-y-6">
          <!-- Preferences Card -->
          <div class="card bg-base-200/50 shadow-lg border border-base-300">
            <div class="card-body p-6">
              <h2 class="text-xl font-bold mb-6 flex items-center gap-3">
                <div class="p-2 bg-primary/10 rounded-lg">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    class="h-6 w-6 text-primary"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M12 6V4m0 2a2 2 0 100 4m0-4a2 2 0 110 4m-6 8a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4m6 6v10m6-2a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4"
                    />
                  </svg>
                </div>
                {gettext("Preferences")}
              </h2>

              <div class="space-y-6">
                <!-- Theme Toggle -->
                <div class="flex items-center justify-between p-4 bg-base-100 rounded-lg hover:bg-base-200 transition-colors">
                  <div class="flex items-start gap-4">
                    <div class="p-2 bg-warning/10 rounded-lg mt-1">
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        class="h-5 w-5 text-warning"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                      >
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z"
                        />
                      </svg>
                    </div>
                    <div class="flex-1">
                      <h3 class="font-semibold text-base mb-1">{gettext("Theme")}</h3>
                      <p class="text-sm text-base-content/60">
                        {gettext("Choose between light and dark mode")}
                      </p>
                    </div>
                  </div>
                  <RodaWeb.Layouts.theme_toggle />
                </div>
                
    <!-- Language Select -->
                <div class="p-4 bg-base-100 rounded-lg">
                  <div class="flex items-start gap-4 mb-4">
                    <div class="p-2 bg-info/10 rounded-lg mt-1">
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        class="h-5 w-5 text-info"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                      >
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M3 5h12M9 3v2m1.048 9.5A18.022 18.022 0 016.412 9m6.088 9h7M11 21l5-10 5 10M12.751 5C11.783 10.77 8.07 15.61 3 18.129"
                        />
                      </svg>
                    </div>
                    <div class="flex-1">
                      <h3 class="font-semibold text-base mb-1">{gettext("Language")}</h3>
                      <p class="text-sm text-base-content/60 mb-3">
                        {gettext("Select your preferred language")}
                      </p>
                      <.form id="form-select" for={@lang_form} phx-change="lang">
                        <.input
                          type="select"
                          field={@lang_form["lang"]}
                          options={[
                            {gettext("French"), "fr"},
                            {gettext("English"), "en"}
                          ]}
                        />
                      </.form>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
          
    <!-- Security Card -->
          <div class="card bg-base-200/50 shadow-lg border border-base-300">
            <div class="card-body p-6">
              <h2 class="text-xl font-bold mb-6 flex items-center gap-3">
                <div class="p-2 bg-error/10 rounded-lg">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    class="h-6 w-6 text-error"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"
                    />
                  </svg>
                </div>
                {gettext("Security")}
              </h2>

              <div class="p-4 bg-base-100 rounded-lg">
                <div class="flex items-start gap-4 mb-4">
                  <div class="p-2 bg-warning/10 rounded-lg mt-1">
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      class="h-5 w-5 text-warning"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke="currentColor"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M15 7a2 2 0 012 2m4 0a6 6 0 01-7.743 5.743L11 17H9v2H7v2H4a1 1 0 01-1-1v-2.586a1 1 0 01.293-.707l5.964-5.964A6 6 0 1121 9z"
                      />
                    </svg>
                  </div>
                  <div class="flex-1">
                    <h3 class="font-semibold text-base mb-1">{gettext("Change Password")}</h3>
                    <p class="text-sm text-base-content/60 mb-4">
                      {gettext("Update your password to keep your account secure")}
                    </p>

                    <.form
                      for={@password_form}
                      id="password_form"
                      action={~p"/users/update-password"}
                      method="post"
                      phx-change="validate_password"
                      phx-submit="update_password"
                      phx-trigger-action={@trigger_submit}
                    >
                      <input
                        name={@password_form[:email].name}
                        type="hidden"
                        id="hidden_user_email"
                        autocomplete="username"
                        value={@current_email}
                      />
                      <div class="space-y-4">
                        <.input
                          field={@password_form[:password]}
                          type="password"
                          label={gettext("New password")}
                          autocomplete="new-password"
                          required
                        />
                        <.input
                          field={@password_form[:password_confirmation]}
                          type="password"
                          label={gettext("Confirm new password")}
                          autocomplete="new-password"
                        />
                        <div class="flex justify-end pt-2">
                          <.button variant="primary" phx-disable-with={gettext("Saving...")}>
                            {gettext("Save Password")}
                          </.button>
                        </div>
                      </div>
                    </.form>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <.form
          :if={false}
          for={@email_form}
          id="email_form"
          phx-submit="update_email"
          phx-change="validate_email"
        >
          <.input
            field={@email_form[:email]}
            type="email"
            label={gettext("Email")}
            autocomplete="username"
            required
          />
          <.button variant="primary" phx-disable-with="Changing...">
            {gettext("Change Email")}
          </.button>
        </.form>
      </RodaWeb.Layouts.page_content>
    </RodaWeb.Layouts.page>
    """
  end

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_scope.user, token) do
        {:ok, _user} ->
          put_flash(socket, :info, gettext("Email changed successfully."))

        {:error, _} ->
          put_flash(socket, :error, gettext("Email change link is invalid or it has expired."))
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    email_changeset = Accounts.change_user_email(user, %{}, validate_unique: false)
    password_changeset = Accounts.change_user_password(user, %{}, hash_password: false)

    socket =
      socket
      |> assign(:current_email, user.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:trigger_submit, false)
      |> assign_lang_form()

    {:ok, socket}
  end

  @impl true
  def handle_event("validate_email", params, socket) do
    %{"user" => user_params} = params

    email_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_email(user_params, validate_unique: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form)}
  end

  # def handle_event("update_email", params, socket) do
  #   %{"user" => user_params} = params
  #   user = socket.assigns.current_scope.user
  #   true = Accounts.sudo_mode?(user)
  #
  #   case Accounts.change_user_email(user, user_params) do
  #     %{valid?: true} = changeset ->
  #       Accounts.deliver_user_update_email_instructions(
  #         Ecto.Changeset.apply_action!(changeset, :insert),
  #         user.email,
  #         &url(~p"/users/settings/confirm-email/#{&1}")
  #       )
  #
  #       # info = "A link to confirm your email change has been sent to the new address."
  #       # {:noreply, socket |> put_flash(:info, info)}
  #       {:noreply, socket}
  #
  #     changeset ->
  #       {:noreply, assign(socket, :email_form, to_form(changeset, action: :insert))}
  #   end
  # end

  def handle_event("validate_password", params, socket) do
    %{"user" => user_params} = params

    password_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_password(user_params, hash_password: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form)}
  end

  def handle_event("update_password", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_scope.user
    true = Accounts.sudo_mode?(user)

    case Accounts.change_user_password(user, user_params) do
      %{valid?: true} = changeset ->
        {:noreply, assign(socket, trigger_submit: true, password_form: to_form(changeset))}

      changeset ->
        {:noreply, assign(socket, password_form: to_form(changeset, action: :insert))}
    end
  end

  @impl true
  def handle_event("lang", %{"lang" => lang}, socket) do
    %{current_scope: scope} = socket.assigns
    Accounts.set_lang(scope, lang)

    socket =
      assign_lang_form(socket)
      |> put_flash(:info, gettext("Prefered lang changed successfully."))

    {:noreply, socket}
  end

  defp assign_lang_form(socket) do
    %{current_scope: scope} = socket.assigns
    assign(socket, lang_form: to_form(%{"lang" => scope.user.prefered_lang}))
  end
end
