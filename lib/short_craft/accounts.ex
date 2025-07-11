defmodule ShortCraft.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias ShortCraft.Repo

  alias ShortCraft.Accounts.{User, UserToken, UserNotifier}
  alias ShortCraft.Services.OAuthService

  ## Database getters

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a user by email and password.

  ## Examples

      iex> get_user_by_email_and_password("foo@example.com", "correct_password")
      %User{}

      iex> get_user_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password), do: user
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Gets a user by OAuth2 provider and provider ID.

  ## Examples

      iex> get_user_by_oauth2("google", "123456789")
      %User{}

      iex> get_user_by_oauth2("google", "unknown")
      nil

  """
  def get_user_by_oauth2(provider, provider_id)
      when is_binary(provider) and is_binary(provider_id) do
    Repo.get_by(User, provider: provider, provider_id: provider_id)
  end

  ## User registration

  @doc """
  Registers a user.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Registers a user via OAuth2.

  ## Examples

      iex> register_oauth2_user(%{provider: "google", provider_id: "123", email: "user@example.com"})
      {:ok, %User{}}

      iex> register_oauth2_user(%{provider: "google", provider_id: "123"})
      {:error, %Ecto.Changeset{}}

  """
  def register_oauth2_user(attrs) do
    %User{}
    |> User.oauth2_registration_changeset(attrs)
    |> Repo.insert()
  end

  def update_oauth2_user(user, attrs) do
    user
    |> User.oauth2_registration_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user_registration(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs, hash_password: false, validate_email: false)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.

  ## Examples

      iex> change_user_email(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_email(user, attrs \\ %{}) do
    User.email_changeset(user, attrs, validate_email: false)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_user_email(user, "valid password", %{email: ...})
      {:ok, %User{}}

      iex> apply_user_email(user, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  def apply_user_email(user, password, attrs) do
    user
    |> User.email_changeset(attrs)
    |> User.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the user email using the given token.

  If the token matches, the user email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_user_email(user, token) do
    context = "change:#{user.email}"

    with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
         %UserToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(user_email_multi(user, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp user_email_multi(user, email, context) do
    changeset =
      user
      |> User.email_changeset(%{email: email})
      |> User.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, [context]))
  end

  @doc ~S"""
  Delivers the update email instructions to the given user.

  ## Examples

      iex> deliver_user_update_email_instructions(user, current_email, &url(~p"/users/settings/confirm_email/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.

  ## Examples

      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_password(user, attrs \\ %{}) do
    User.password_changeset(user, attrs, hash_password: false)
  end

  @doc """
  Updates the user password.

  ## Examples

      iex> update_user_password(user, "valid password", %{password: ...})
      {:ok, %User{}}

      iex> update_user_password(user, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_password(user, password, attrs) do
    changeset =
      user
      |> User.password_changeset(attrs)
      |> User.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_user_session_token(token) do
    Repo.delete_all(UserToken.by_token_and_context_query(token, "session"))
    :ok
  end

  ## Confirmation

  @doc ~S"""
  Delivers the confirmation email instructions to the given user.

  ## Examples

      iex> deliver_user_confirmation_instructions(user, &url(~p"/users/confirm/#{&1}"))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_user_confirmation_instructions(confirmed_user, &url(~p"/users/confirm/#{&1}"))
      {:error, :already_confirmed}

  """
  def deliver_user_confirmation_instructions(%User{} = user, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if user.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, user_token} = UserToken.build_email_token(user, "confirm")
      Repo.insert!(user_token)
      UserNotifier.deliver_confirmation_instructions(user, confirmation_url_fun.(encoded_token))
    end
  end

  @doc """
  Confirms a user by the given token.

  If the token matches, the user account is marked as confirmed
  and the token is deleted.
  """
  def confirm_user(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "confirm"),
         %User{} = user <- Repo.one(query),
         {:ok, %{user: user}} <- Repo.transaction(confirm_user_multi(user)) do
      {:ok, user}
    else
      _ -> :error
    end
  end

  defp confirm_user_multi(user) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.confirm_changeset(user))
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, ["confirm"]))
  end

  ## Reset password

  @doc ~S"""
  Delivers the reset password email to the given user.

  ## Examples

      iex> deliver_user_reset_password_instructions(user, &url(~p"/users/reset_password/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_reset_password_instructions(%User{} = user, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "reset_password")
    Repo.insert!(user_token)
    UserNotifier.deliver_reset_password_instructions(user, reset_password_url_fun.(encoded_token))
  end

  @doc """
  Gets the user by reset password token.

  ## Examples

      iex> get_user_by_reset_password_token("validtoken")
      %User{}

      iex> get_user_by_reset_password_token("invalidtoken")
      nil

  """
  def get_user_by_reset_password_token(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "reset_password"),
         %User{} = user <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  @doc """
  Resets the user password.

  ## Examples

      iex> reset_user_password(user, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %User{}}

      iex> reset_user_password(user, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_user_password(user, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.password_changeset(user, attrs))
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  @doc """
  Gets a user by OAuth2 provider and provider ID, or creates a new user.

  ## Examples

      iex> create_or_update_oauth2_user(%{provider: "google", provider_id: "123", email: "user@example.com"})
      {:ok, %User{}}

  """
  def create_or_update_oauth2_user(attrs) do
    case get_user_by_oauth2(attrs.provider, attrs.provider_id) do
      nil -> register_oauth2_user(attrs)
      user -> update_oauth2_user(user, attrs)
    end
  end

  alias ShortCraft.Accounts.YoutubeChannel

  @doc """
  Returns the list of youtube_channels.

  ## Examples

      iex> list_youtube_channels()
      [%YoutubeChannel{}, ...]

  """
  def list_youtube_channels do
    Repo.all(YoutubeChannel)
  end

  @doc """
  Gets a single youtube_channel.

  Raises `Ecto.NoResultsError` if the Youtube channel does not exist.

  ## Examples

      iex> get_youtube_channel!(123)
      %YoutubeChannel{}

      iex> get_youtube_channel!(456)
      ** (Ecto.NoResultsError)

  """
  def get_youtube_channel!(id), do: Repo.get!(YoutubeChannel, id)

  @doc """
  Creates a youtube_channel.

  ## Examples

      iex> create_youtube_channel(%{field: value})
      {:ok, %YoutubeChannel{}}

      iex> create_youtube_channel(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_youtube_channel(attrs \\ %{}) do
    %YoutubeChannel{}
    |> YoutubeChannel.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a youtube_channel.

  ## Examples

      iex> update_youtube_channel(youtube_channel, %{field: new_value})
      {:ok, %YoutubeChannel{}}

      iex> update_youtube_channel(youtube_channel, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_youtube_channel(%YoutubeChannel{} = youtube_channel, attrs) do
    youtube_channel
    |> YoutubeChannel.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a youtube_channel.

  ## Examples

      iex> delete_youtube_channel(youtube_channel)
      {:ok, %YoutubeChannel{}}

      iex> delete_youtube_channel(youtube_channel)
      {:error, %Ecto.Changeset{}}

  """
  def delete_youtube_channel(%YoutubeChannel{} = youtube_channel) do
    Repo.delete(youtube_channel)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking youtube_channel changes.

  ## Examples

      iex> change_youtube_channel(youtube_channel)
      %Ecto.Changeset{data: %YoutubeChannel{}}

  """
  def change_youtube_channel(%YoutubeChannel{} = youtube_channel, attrs \\ %{}) do
    YoutubeChannel.changeset(youtube_channel, attrs)
  end

  @doc """
  Updates a user's OAuth tokens.
  """
  def update_user_tokens(%User{} = user, token_data) do
    user
    |> User.oauth2_registration_changeset(%{
      access_token: token_data["access_token"],
      refresh_token: token_data["refresh_token"] || user.refresh_token,
      expires_at: OAuthService.get_expires_at(token_data)
    })
    |> Repo.update()
  end
end
