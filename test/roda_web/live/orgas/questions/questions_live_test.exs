defmodule RodaWeb.QuestionsLiveTest do
  use RodaWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  alias Roda.Repo
  alias Roda.Questions.Question

  setup do
    Roda.OrganizationFixtures.init_organization()
  end

  test "displays question page with welcome message", %{
    conn: conn,
    scope: scope
  } do
    {:ok, _lv, html} =
      conn
      |> log_in_user(scope.user)
      |> live(~p"/orgas/#{scope.organization.id}/projects/#{scope.project.id}/questions")

    assert html =~
             "Groups are spaces where you collect and organize testimonies from your community."
  end

  test "creates a new question successfully", %{conn: conn, scope: scope} do
    {:ok, lv, _html} =
      conn
      |> log_in_user(scope.user)
      |> live(~p"/orgas/#{scope.organization.id}/projects/#{scope.project.id}/questions")

    assert Repo.all(Question) == []

    lv
    |> form("#question-form", %{"question" => %{"name" => "couscous"}})
    |> render_submit()

    assert [question] = Repo.all(Question)
    assert question.name == "couscous"
    assert question.prompt == "couscous"
  end

  describe "denies" do
    test "denies access to groups from different organization", %{conn: conn, scope: scope} do
      new = Roda.OrganizationFixtures.init_organization(email: "michel@michel.fr")

      {:error, _} =
        conn
        |> log_in_user(new.scope.user)
        |> live(~p"/orgas/#{scope.organization.id}/projects/#{new.scope.project.id}/questions")

      {:error, _} =
        conn
        |> log_in_user(new.scope.user)
        |> live(~p"/orgas/#{new.scope.organization.id}/projects/#{scope.project.id}/questions")
    end
  end
end
