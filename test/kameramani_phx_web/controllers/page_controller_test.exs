defmodule KameramaniPhxWeb.PageControllerTest do
  use KameramaniPhxWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Recommended Channels"
  end
end
