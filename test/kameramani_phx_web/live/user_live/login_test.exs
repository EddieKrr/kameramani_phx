defmodule KameramaniPhxWeb.UserLive.LoginTest do
  use KameramaniPhxWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import KameramaniPhx.AccountsFixtures

  describe "login page" do
    test "renders login panel", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/auth?panel=login")

      assert html =~ "Login"
      assert html =~ "Register"
    end
  end

  describe "user login - password" do
    test "redirects if user logs in with valid credentials", %{conn: conn} do
      user = user_fixture() |> set_password()

      {:ok, lv, _html} = live(conn, ~p"/auth?panel=login")

      form =
        form(lv, "#login_form", user: %{email: user.email, password: valid_user_password()})

      conn = submit_form(form, conn)

      assert redirected_to(conn) == ~p"/"
    end

    test "redirects to auth page with a flash error if credentials are invalid", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/auth?panel=login")

      form =
        form(lv, "#login_form", user: %{email: "test@email.com", password: "123456"})

      conn = submit_form(form, conn)

      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid email or password"
      assert redirected_to(conn) == ~p"/auth"
    end
  end

  describe "login navigation" do
    test "switches to registration panel when the Sign Up button is clicked", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/auth?panel=login")

      lv
      |> element("button.reg-btn", "Sign Up")
      |> render_click()

      refute has_element?(lv, "div.active")
    end
  end
end
