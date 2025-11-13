defmodule RodaWeb.OrganizationSettingsLiveTest do
  use RodaWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  alias Roda.Repo
  alias Roda.Organizations.Project

  setup do
    Roda.OrganizationFixtures.init_organization()
  end

  test "displays project setting", %{conn: conn, scope: scope} do
    {:ok, _lv, html} =
      conn
      |> log_in_user(scope.user)
      |> live(~p"/orgas/#{scope.organization.id}/projects/#{scope.project.id}/settings")

    assert html =~ "QR Code"
  end

  test "edit group name", %{conn: conn, scope: scope} do
    {:ok, lv, _html} =
      conn
      |> log_in_user(scope.user)
      |> live(~p"/orgas/#{scope.organization.id}/projects/#{scope.project.id}/settings")

    html =
      lv
      |> form("#set-project", %{"project" => %{"name" => "couscous"}})
      |> render_submit()

    assert [project] = Repo.all(Project)
    assert project.name == "couscous"
    assert html =~ "couscous"
  end
end
