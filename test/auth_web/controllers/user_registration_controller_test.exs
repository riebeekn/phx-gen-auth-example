defmodule AuthWeb.UserRegistrationControllerTest do
  use AuthWeb.ConnCase, async: true

  import Auth.AccountsFixtures

  describe "GET /users/register" do
    test "renders registration page", %{conn: conn} do
      conn = get(conn, Routes.user_registration_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "<h1>Register</h1>"
      assert response =~ "Log in</a>"
      assert response =~ "Register</a>"
    end

    test "redirects if already logged in", %{conn: conn} do
      conn = conn |> log_in_user(user_fixture()) |> get(Routes.user_registration_path(conn, :new))
      assert redirected_to(conn) == "/"
    end
  end

  describe "POST /users/register" do
    @tag :capture_log
    test "creates account and DOES NOT log the user in", %{conn: conn} do
      email = unique_user_email()

      conn =
        post(conn, Routes.user_registration_path(conn, :create), %{
          "user" => %{
            "email" => email,
            "password" => valid_user_password(),
            "password_confirmation" => valid_user_password()
          }
        })

      refute get_session(conn, :user_token)
      assert redirected_to(conn) =~ "/users/log_in"

      assert flash_messages_contain(
               conn,
               "User created successfully.  Please check your email for confirmation instructions."
             )
    end

    defp flash_messages_contain(conn, text) do
      conn
      |> Phoenix.Controller.get_flash()
      |> Enum.any?(fn item -> String.contains?(elem(item, 1), text) end)
    end

    test "render errors for invalid data", %{conn: conn} do
      conn =
        post(conn, Routes.user_registration_path(conn, :create), %{
          "user" => %{
            "email" => "with spaces",
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      response = html_response(conn, 200)
      assert response =~ "<h1>Register</h1>"
      assert response =~ "must have the @ sign and no spaces"
      assert response =~ "should be at least 12 character"
      assert response =~ "does not match password"
    end
  end
end
