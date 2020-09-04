defmodule AuthWeb.UserSessionController do
  use AuthWeb, :controller

  alias Auth.Accounts
  alias AuthWeb.UserAuth

  def new(conn, _params) do
    render(conn, "new.html", error_message: nil)
  end

  def create(conn, %{"user" => user_params}) do
    %{"email" => email, "password" => password} = user_params

    with {:ok, user} <- Accounts.get_user_by_email_and_password(email, password) do
      UserAuth.log_in_user(conn, user, user_params)
    else
      {:error, :bad_username_or_password} ->
        render(conn, "new.html", error_message: "Invalid e-mail or password")

      {:error, :user_blocked} ->
        render(conn, "new.html",
          error_message: "Your account has been locked, please contact an administrator."
        )

      {:error, :not_confirmed} ->
        user = Accounts.get_user_by_email(email)

        Accounts.deliver_user_confirmation_instructions(
          user,
          &Routes.user_confirmation_url(conn, :confirm, &1)
        )

        render(conn, "new.html",
          error_message:
            "Please confirm your email before signing in.  An email confirmation link has been sent to you."
        )
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end
end
