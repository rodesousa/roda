defmodule RodaWeb.PageController do
  use RodaWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
