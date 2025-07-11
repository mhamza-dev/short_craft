defmodule ShortCraft.Services.OAuthService do
  @moduledoc """
  Service module for handling OAuth2 authentication flows with enhanced security,
  error handling, and token management.
  """

  require Logger

  alias ShortCraft.Accounts

  @required_config_fields [:client_id, :client_secret, :redirect_uri, :default_scope]

  # ============================================================================
  # PUBLIC FUNCTIONS
  # ============================================================================

  @doc """
  Initiates OAuth2 flow for the given provider.
  Returns {:ok, auth_url} or {:error, reason}
  """
  def initiate_oauth(provider) when is_binary(provider) do
    with :ok <- validate_provider(provider),
         {:ok, config} <- get_provider_config(provider),
         {:ok, auth_url} <- build_auth_url(config) do
      Logger.info("OAuth initiation started", provider: provider)
      {:ok, auth_url}
    else
      {:error, reason} ->
        Logger.error("OAuth initiation failed", provider: provider, reason: reason)
        {:error, reason}
    end
  end

  def initiate_oauth(_), do: {:error, "Invalid provider format"}

  @doc """
  Processes OAuth2 callback for the given provider.
  Returns {:ok, user} or {:error, reason}
  """
  def process_callback(provider, params) when is_binary(provider) and is_map(params) do
    with :ok <- validate_provider(provider),
         {:ok, code} <- extract_auth_code(params),
         {:ok, config} <- get_provider_config(provider),
         {:ok, token_data} <- exchange_code_for_token(provider, code, config),
         {:ok, user_info} <- fetch_user_info(provider, token_data["access_token"], config),
         {:ok, user} <- create_or_update_user(provider, user_info, token_data) do
      Logger.info("OAuth callback processed successfully", provider: provider, user_id: user.id)
      {:ok, user}
    else
      {:error, reason} ->
        Logger.error("OAuth callback processing failed",
          provider: provider,
          reason: reason,
          params: params
        )

        {:error, reason}
    end
  end

  def process_callback(_, _), do: {:error, "Invalid parameters"}

  @doc """
  Refreshes an OAuth access token for the given provider.
  Returns {:ok, new_token_data} or {:error, reason}
  """
  def refresh_token(provider, refresh_token)
      when is_binary(provider) and is_binary(refresh_token) do
    with :ok <- validate_provider(provider),
         {:ok, config} <- get_provider_config(provider),
         {:ok, token_data} <- exchange_refresh_token(provider, refresh_token, config) do
      Logger.info("Token refreshed successfully", provider: provider)
      {:ok, token_data}
    else
      {:error, reason} ->
        Logger.error("Token refresh failed", provider: provider, reason: reason)
        {:error, reason}
    end
  end

  def refresh_token(_, _), do: {:error, "Invalid parameters"}

  @doc """
  Checks if the given provider is supported.
  """
  def supported_provider?(provider) when is_binary(provider) do
    provider in ["google", "github", "facebook"]
  end

  def supported_provider?(_), do: false

  def get_expires_at(token_data) do
    case token_data["expires_in"] do
      expires_in when is_integer(expires_in) ->
        DateTime.utc_now()
        |> DateTime.add(expires_in, :second)
        |> DateTime.truncate(:second)

      _ ->
        nil
    end
  end

  # ============================================================================
  # PRIVATE FUNCTIONS - VALIDATION
  # ============================================================================

  defp validate_provider(provider) do
    if supported_provider?(provider) do
      :ok
    else
      {:error, "Unsupported provider: #{provider}"}
    end
  end

  defp validate_config_fields(config, required_fields) do
    missing_fields =
      Enum.filter(required_fields, fn field ->
        value = Map.get(config, field)
        is_nil(value) or (is_binary(value) and byte_size(value) == 0)
      end)

    if Enum.empty?(missing_fields) do
      :ok
    else
      {:error, "Missing or empty configuration fields: #{Enum.join(missing_fields, ", ")}"}
    end
  end

  # ============================================================================
  # PRIVATE FUNCTIONS - CONFIGURATION
  # ============================================================================

  defp get_provider_config(provider) when provider in ["google", "github", "facebook"] do
    strategy = get_strategy(provider)
    Logger.info("Strategy: #{inspect(strategy)}")
    static_config = get_static_provider_config(provider)
    runtime_config = Application.get_env(:ueberauth, strategy) || %{}
    Logger.info("Runtime config: #{inspect(runtime_config)}")

    config =
      Map.merge(static_config, %{
        client_id: runtime_config[:client_id],
        client_secret: runtime_config[:client_secret],
        redirect_uri: runtime_config[:redirect_uri],
        default_scope: runtime_config[:default_scope]
      })

    with :ok <-
           validate_config_fields(config, @required_config_fields) do
      {:ok, config}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp get_provider_config(_), do: {:error, "Unsupported provider"}

  defp get_static_provider_config("google") do
    %{
      auth_url: "https://accounts.google.com/o/oauth2/v2/auth",
      token_url: "https://oauth2.googleapis.com/token",
      user_info_url: "https://www.googleapis.com/oauth2/v2/userinfo",
      access_type: "offline",
      prompt: "consent"
    }
  end

  defp get_static_provider_config("github") do
    %{
      auth_url: "https://github.com/login/oauth/authorize",
      token_url: "https://github.com/login/oauth/access_token",
      user_info_url: "https://api.github.com/user",
      headers: [{"Accept", "application/vnd.github.v3+json"}]
    }
  end

  defp get_static_provider_config("facebook") do
    %{
      auth_url: "https://www.facebook.com/v18.0/dialog/oauth",
      token_url: "https://graph.facebook.com/v18.0/oauth/access_token",
      user_info_url: "https://graph.facebook.com/v18.0/me",
      user_info_fields: "id,name,email,picture"
    }
  end

  defp get_static_provider_config(_), do: %{}

  defp get_strategy("google"), do: Ueberauth.Strategy.Google.OAuth
  defp get_strategy("github"), do: Ueberauth.Strategy.GitHub.OAuth
  defp get_strategy("facebook"), do: Ueberauth.Strategy.Facebook.OAuth

  # ============================================================================
  # PRIVATE FUNCTIONS - OAUTH FLOW
  # ============================================================================

  defp extract_auth_code(%{"code" => code}) when is_binary(code) and byte_size(code) > 0 do
    {:ok, code}
  end

  defp extract_auth_code(%{"error" => error, "error_description" => description}) do
    {:error, "OAuth error: #{error} - #{description}"}
  end

  defp extract_auth_code(%{"error" => error}) do
    {:error, "OAuth error: #{error}"}
  end

  defp extract_auth_code(_) do
    {:error, "Missing or invalid authorization code"}
  end

  defp build_auth_url(config) do
    params = %{
      "client_id" => config.client_id,
      "redirect_uri" => config.redirect_uri,
      "response_type" => "code",
      "scope" => config.default_scope
    }

    params = params |> maybe_add_access_type(config) |> maybe_add_prompt(config)

    query_string = URI.encode_query(params)
    auth_url = "#{config.auth_url}?#{query_string}"

    {:ok, auth_url}
  end

  defp maybe_add_access_type(params, %{access_type: access_type}) do
    Map.put(params, "access_type", access_type)
  end

  defp maybe_add_access_type(params, _), do: params

  defp maybe_add_prompt(params, %{prompt: prompt}) do
    Map.put(params, "prompt", prompt)
  end

  defp maybe_add_prompt(params, _), do: params

  defp exchange_code_for_token(provider, code, config) do
    body_params = %{
      "code" => code,
      "client_id" => config.client_id,
      "client_secret" => config.client_secret,
      "redirect_uri" => config.redirect_uri,
      "grant_type" => "authorization_code"
    }

    headers = [{"Content-Type", "application/x-www-form-urlencoded"}]
    headers = maybe_add_provider_headers(headers, config)

    case HTTPoison.post(config.token_url, URI.encode_query(body_params), headers) do
      {:ok, %{status_code: 200, body: response_body}} ->
        case Jason.decode(response_body) do
          {:ok, token_data} -> {:ok, token_data}
          {:error, reason} -> {:error, "Invalid JSON response: #{reason}"}
        end

      {:ok, %{status_code: status_code, body: response_body}} ->
        Logger.error("Token exchange failed",
          provider: provider,
          status_code: status_code,
          response: response_body
        )

        {:error, "Token exchange failed with status #{status_code}"}

      {:error, reason} ->
        {:error, "HTTP request failed: #{reason}"}
    end
  end

  defp exchange_refresh_token(provider, refresh_token, config) do
    # Build the body params without scope - let Google use the original scopes
    body_params = %{
      "refresh_token" => refresh_token,
      "client_id" => config.client_id,
      "client_secret" => config.client_secret,
      "grant_type" => "refresh_token"
    }

    body = URI.encode_query(body_params)
    headers = [{"Content-Type", "application/x-www-form-urlencoded"}]
    headers = maybe_add_provider_headers(headers, config)

    case HTTPoison.post(config.token_url, body, headers) do
      {:ok, %{status_code: 200, body: response_body}} ->
        case Jason.decode(response_body) do
          {:ok, token_data} -> {:ok, token_data}
          {:error, reason} -> {:error, "Invalid JSON response: #{reason}"}
        end

      {:ok, %{status_code: status_code, body: response_body}} ->
        Logger.error("Token refresh failed",
          provider: provider,
          status_code: status_code,
          response: response_body
        )

        {:error, "Token refresh failed with status #{status_code}"}

      {:error, reason} ->
        {:error, "HTTP request failed: #{reason}"}
    end
  end

  defp fetch_user_info(provider, access_token, config) do
    headers = [{"Authorization", "Bearer #{access_token}"}]
    headers = maybe_add_provider_headers(headers, config)

    url = maybe_add_user_info_params(config.user_info_url, config)

    case HTTPoison.get(url, headers) do
      {:ok, %{status_code: 200, body: response_body}} ->
        case Jason.decode(response_body) do
          {:ok, user_info} -> {:ok, user_info}
          {:error, reason} -> {:error, "Invalid JSON response: #{reason}"}
        end

      {:ok, %{status_code: status_code, body: response_body}} ->
        Logger.error("User info fetch failed",
          provider: provider,
          status_code: status_code,
          response: response_body
        )

        {:error, "User info fetch failed with status #{status_code}"}

      {:error, reason} ->
        {:error, "HTTP request failed: #{reason}"}
    end
  end

  defp maybe_add_provider_headers(headers, %{headers: provider_headers}) do
    headers ++ provider_headers
  end

  defp maybe_add_provider_headers(headers, _), do: headers

  defp maybe_add_user_info_params(url, %{user_info_fields: fields}) do
    "#{url}?fields=#{fields}"
  end

  defp maybe_add_user_info_params(url, _), do: url

  # ============================================================================
  # PRIVATE FUNCTIONS - USER MANAGEMENT
  # ============================================================================

  defp create_or_update_user(provider, user_info, token_data) do
    user_params =
      %{
        provider: provider,
        provider_id: user_info["id"],
        email: user_info["email"],
        name: user_info["name"],
        avatar_url: get_avatar_url(provider, user_info),
        access_token: token_data["access_token"],
        refresh_token: token_data["refresh_token"],
        expires_at: get_expires_at(token_data),
        metadata: %{
          "provider_data" => user_info,
          "token_data" => token_data,
          "last_oauth_update" => DateTime.utc_now() |> DateTime.truncate(:second)
        }
      }
      |> IO.inspect(label: "User params before insert")

    case Accounts.create_or_update_oauth2_user(user_params) do
      {:ok, user} ->
        {:ok, user}

      {:error, changeset} ->
        Logger.error("User creation/update failed",
          provider: provider,
          errors: format_changeset_errors(changeset)
        )

        {:error, "User creation/update failed"}
    end
  end

  defp get_avatar_url("google", user_info) do
    user_info["picture"]
  end

  defp get_avatar_url("github", user_info) do
    user_info["avatar_url"]
  end

  defp get_avatar_url("facebook", user_info) do
    case user_info["picture"] do
      %{"data" => %{"url" => url}} -> url
      _ -> nil
    end
  end

  defp get_avatar_url(_, _), do: nil

  # ============================================================================
  # PRIVATE FUNCTIONS - UTILITIES
  # ============================================================================

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
