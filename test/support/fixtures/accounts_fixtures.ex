defmodule ShortCraft.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ShortCraft.Accounts` context.
  """

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      password: valid_user_password()
    })
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> ShortCraft.Accounts.register_user()

    user
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end

  @doc """
  Generate a youtube_channel.
  """
  def youtube_channel_fixture(attrs \\ %{}) do
    {:ok, youtube_channel} =
      attrs
      |> Enum.into(%{
        access_token: "some access_token",
        channel_id: "some channel_id",
        channel_title: "some channel_title",
        channel_url: "some channel_url",
        expires_at: ~U[2025-07-02 14:16:00Z],
        is_connected: true,
        metadata: %{},
        refresh_token: "some refresh_token"
      })
      |> ShortCraft.Accounts.create_youtube_channel()

    youtube_channel
  end
end
