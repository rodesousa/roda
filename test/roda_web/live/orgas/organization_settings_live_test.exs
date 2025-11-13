defmodule RodaWeb.OrganizationSettingsLiveTest do
  use RodaWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  alias Roda.Repo
  alias Roda.Organizations.Organization

  setup do
    Roda.OrganizationFixtures.init_organization()
  end

  test "displays orga setting", %{conn: conn, scope: scope} do
    {:ok, _lv, html} =
      conn
      |> log_in_user(scope.user)
      |> live(~p"/orgas/#{scope.organization.id}/settings")

    assert html =~ "Rename"
  end

  test "edit group name", %{conn: conn, scope: scope} do
    {:ok, lv, _html} =
      conn
      |> log_in_user(scope.user)
      |> live(~p"/orgas/#{scope.organization.id}/settings")

    html =
      lv
      |> form("#set-orga", %{"organization" => %{"name" => "couscous"}})
      |> render_submit()

    assert [organization] = Repo.all(Organization)
    assert organization.name == "couscous"
    assert html =~ "couscous"
  end
end
