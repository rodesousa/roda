defmodule RodaWeb.Router do
  use RodaWeb, :router

  import RodaWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {RodaWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", RodaWeb do
    pipe_through :browser

    live_session :mount_token_context,
      on_mount: [{RodaWeb.UserAuth, :mount_token_context}] do
      live "/testify/:token", Orga.TestifyLive
      live "/testimonies/:token", Orga.TestimoniesLive
    end

    live_session :mount_organization_context,
      on_mount: [{RodaWeb.UserAuth, :mount_organization_context}] do
      live "/orgas/:orga_id/groups", Orga.GroupsLive
      live "/orgas/:orga_id/settings", Orga.OrganizationSettingsLive
    end

    live_session :mount_project_context,
      on_mount: [{RodaWeb.UserAuth, :mount_project_context}] do
      live "/orgas/:orga_id/projects/:project_id/prompt", Orga.PromptLive
      live "/orgas/:orga_id/projects/:project_id/testify", Orga.TestifyLive
      live "/orgas/:orga_id/projects/:project_id/testimonies", Orga.TestimoniesLive
      live "/orgas/:orga_id/projects/:project_id/questions/:question_id", Orga.QuestionLive
      live "/orgas/:orga_id/projects/:project_id/settings", Orga.ProjectSettingsLive
      live "/orgas/:orga_id/projects/:project_id/questions", Orga.QuestionsLive

      live "/orgas/:orga_id/projects/:project_id/questions/:question_id/show/:question_response_id",
           Orga.Question.QuestionResponseLive

      live "/orgas/:orga_id/projects/:project_id/questions/:question_id/themes",
           Orga.Question.ThemesEvolutionLive
    end
  end

  scope "/", RodaWeb do
    pipe_through :browser

    live_session :require_platform_admin,
      on_mount: [{RodaWeb.UserAuth, :require_platform_admin}] do
      live "/admin", Admin.OrgasLive
      live "/admin/orgas/:orga_id", Admin.ProjectsLive
    end
  end

  scope "/api", RodaWeb do
    pipe_through :api

    post "/chunks/upload", ChunkController, :upload
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:roda, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: RodaWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  # scope "/", RodaWeb do
  #   pipe_through [:browser, :require_authenticated_user]
  #
  #   live_session :require_authenticated_user,
  #     on_mount: [{RodaWeb.UserAuth, :require_authenticated}] do
  #     live "/users/settings", UserLive.Settings, :edit
  #     live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
  #   end
  #
  #   post "/users/update-password", UserSessionController, :update_password
  # end

  scope "/", RodaWeb do
    pipe_through [:browser]

    live_session :require_authenticated,
      on_mount: [{RodaWeb.UserAuth, :require_authenticated}] do
      live "/", OrgasLive
      live "/users/settings", UserLive.Settings, :edit
    end

    live_session :current_user,
      on_mount: [{RodaWeb.UserAuth, :mount_current_scope}] do
      # live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end
end
