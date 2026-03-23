defmodule KameramaniPhxWeb.UserLive.RegistrationTest do
  use KameramaniPhxWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import KameramaniPhx.AccountsFixtures

  describe "Registration page" do
    test "renders registration page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/auth")

      assert html =~ "Register"
      assert html =~ "Log In"
    end

    test "renders registration panel even if already logged in", %{conn: conn} do
      {:ok, _lv, html} =
        conn
        |> log_in_user(user_fixture())
        |> live(~p"/auth")

      assert html =~ "Register"
    end

    test "renders errors for invalid data", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/auth")

      result =
        lv
        |> element("#registration_form")
        |> render_change(%{"reg" => %{"email" => "with spaces"}})

      assert result =~ "Register"
      assert result =~ "must have the @ sign and no spaces"
    end
  end

  describe "register user" do
    test "creates account but does not log in", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/auth")

      email = unique_user_email()
      form = form(lv, "#registration_form", reg: valid_user_attributes(email: email))

      {:ok, _lv, html} =
        render_submit(form)
        |> follow_redirect(conn, ~p"/auth?panel=login")

      assert html =~ "Registration successful! Please log in."
    end

    test "renders errors for duplicated email", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/auth")

      user = user_fixture()

      result =
        lv
        |> form("#registration_form",
          reg: %{"email" => user.email}
        )
        |> render_submit()

      assert result =~ "has already been taken"
    end
  end

  describe "registration navigation" do
    test "redirects to login page when the Log in button is clicked", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/auth")

      _html =
        lv
        |> element("button.log-btn", "Log In")
        |> render_click()

      assert has_element?(lv, "div.active")
    end
  end
end
