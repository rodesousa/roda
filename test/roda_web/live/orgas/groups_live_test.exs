defmodule RodaWeb.GroupsLiveTest do
  use RodaWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  alias Roda.Repo
  alias Roda.Organizations.Project

  setup do
    Roda.OrganizationFixtures.init_organization()
  end

  test "displays groups page with welcome message", %{conn: conn, scope: scope} do
    {:ok, _lv, html} =
      conn
      |> log_in_user(scope.user)
      |> live(~p"/orgas/#{scope.organization.id}/groups")

    assert html =~
             "Groups are spaces where you collect and organize testimonies from your community."
  end

  test "creates a new group successfully", %{conn: conn, scope: scope} do
    {:ok, lv, _html} =
      conn
      |> log_in_user(scope.user)
      |> live(~p"/orgas/#{scope.organization.id}/groups")

    assert length(Repo.all(Projectn) == 1

    lv
    |> form("#group-form", %{"project" => %{"name" => "couscous"}})
    |> render_submit()

    assert [_, project] = Repo.all(Project)
    assert project.name == "couscous"
  end

  test "prevents creating group with duplicate name", %{conn: conn, scope: scope} do
    {:ok, lv, _html} =
      conn
      |> log_in_user(scope.user)
      |> live(~p"/orgas/#{scope.organization.id}/groups")

    assert length(Repo.all(Project)) == 1

    lv
    |> form("#group-form", %{"project" => %{"name" => "coucou"}})
    |> render_submit()

    assert length(Repo.all(Project)) == 1
  end

  describe "denies" do
    test "denies access to groups from different organization", %{conn: conn, scope: scope} do
      new_orga = Roda.OrganizationFixtures.init_organization(email: "michel@michel.fr")

      {:error, _} =
        conn
        |> log_in_user(new_orga.scope.user)
        |> live(~p"/orgas/#{scope.organization.id}/groups")
    end

    test "prevents members from creating groups", %{conn: conn} do
      new_orga =
        Roda.OrganizationFixtures.init_organization(email: "michel@michel.fr", role: "member")

      scope = new_orga.scope

      assert length(Repo.all(Project)) == 2

      {:ok, lv, _html} =
        conn
        |> log_in_user(scope.user)
        |> live(~p"/orgas/#{scope.organization.id}/groups")

      lv
      |> form("#group-form", %{"project" => %{"name" => "couscous"}})
      |> render_submit()

      refute length(Repo.all(Project)) == 3
    end
  end
end
