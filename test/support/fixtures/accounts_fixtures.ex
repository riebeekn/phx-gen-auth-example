defmodule Auth.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Auth.Accounts` context.
  """

  alias Auth.Repo
  alias Auth.Accounts.{User, UserToken}

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"

  def user_fixture(attrs \\ %{}, opts \\ []) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        email: unique_user_email(),
        password: valid_user_password()
      })
      |> Auth.Accounts.register_user()

    if Keyword.get(opts, :confirmed, true), do: Repo.transaction(confirm_user_multi(user))

    user
  end

  def extract_user_token(fun) do
    {:ok, captured} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token, _] = String.split(captured.body, "[TOKEN]")
    token
  end

  defp confirm_user_multi(user) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.confirm_changeset(user))
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, ["confirm"]))
  end
end
