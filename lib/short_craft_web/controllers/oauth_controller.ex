defmodule ShortCraftWeb.OAuthController do
  use ShortCraftWeb, :controller

  alias ShortCraft.OAuthService
  alias ShortCraftWeb.UserAuth

  @doc """
  Initiates OAuth2 flow for the given provider.
  """
  def request(conn, %{"provider" => provider}) do
    case OAuthService.supported_provider?(provider) do
      true ->
        case OAuthService.initiate_oauth(provider) do
          {:ok, auth_url} ->
            redirect(conn, external: auth_url)

          {:error, reason} ->
            conn
            |> put_flash(:error, "Failed to initiate OAuth: #{reason}")
            |> redirect(to: ~p"/users/log_in")
        end

      false ->
        conn
        |> put_flash(:error, "Unsupported provider")
        |> redirect(to: ~p"/users/log_in")
    end
  end

  @doc """
  Handles OAuth2 callback for the given provider.
  """
  def callback(conn, %{"provider" => provider} = params) do
    case OAuthService.process_callback(provider, params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Successfully authenticated with #{String.capitalize(provider)}!")
        |> UserAuth.log_in_user(user)

      {:error, reason} ->
        conn
        |> put_flash(:error, "OAuth failed: #{reason}")
        |> redirect(to: ~p"/users/log_in")
    end
  end
end
