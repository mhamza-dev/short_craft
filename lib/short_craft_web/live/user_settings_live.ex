defmodule ShortCraftWeb.UserSettingsLive do
  alias ShortCraft.Services.Youtube
  use ShortCraftWeb, :live_view

  alias ShortCraft.Accounts
  alias ShortCraft.Services.{OAuthService, Youtube}

  def render(assigns) do
    ~H"""
    <div class="bg-white py-6 px-2 sm:px-4 lg:px-6">
      <div class="mx-auto">
        <!-- Header -->
        <div class="mb-8 flex items-center">
          <div class="w-16 h-16 bg-gradient-to-br from-blue-600 to-purple-600 rounded-md flex items-center justify-center shadow-xl">
            <.icon name="hero-cog-6-tooth" class="w-8 h-8 text-white" />
          </div>
          <div class="ml-4">
            <h1 class="text-3xl font-bold text-gray-900 mb-2">Account Settings</h1>
            <p class="text-gray-600">
              Manage your account settings, security preferences, and platform integrations
            </p>
          </div>
        </div>
        
    <!-- All cards stacked in one column -->
        <div class="space-y-6">
          <!-- Email Settings Card -->
          <div class="flex gap-4">
            <div class="bg-white rounded-md border border-gray-100 p-4 w-full">
              <div class="flex items-center mb-4">
                <div class="w-10 h-10 bg-blue-100 rounded-md flex items-center justify-center mr-3">
                  <.icon name="hero-envelope" class="w-5 h-5 text-blue-600" />
                </div>
                <div>
                  <h2 class="text-xl font-bold text-gray-900">Email Settings</h2>
                  <p class="text-gray-600 text-sm">Update your email address</p>
                </div>
              </div>
              <.simple_form
                for={@email_form}
                id="email_form"
                phx-submit="update_email"
                phx-change="validate_email"
              >
                <.input
                  field={@email_form[:email]}
                  type="email"
                  label="Email address"
                  required
                  class="mb-3"
                />
                <.input
                  field={@email_form[:current_password]}
                  name="current_password"
                  id="current_password_for_email"
                  type="password"
                  label="Current password"
                  value={@email_form_current_password}
                  required
                  class="mb-4"
                />
                <:actions>
                  <.button variant="gradient" phx-disable-with="Changing..." class="w-full">
                    <.icon name="hero-check" class="w-5 h-5 mr-2" /> Update Email
                  </.button>
                </:actions>
              </.simple_form>
            </div>
            
    <!-- Password Settings Card -->
            <div class="bg-white rounded-md border border-gray-100 p-4 w-full">
              <div class="flex items-center mb-4">
                <div class="w-10 h-10 bg-green-100 rounded-md flex items-center justify-center mr-3">
                  <.icon name="hero-lock-closed" class="w-5 h-5 text-green-600" />
                </div>
                <div>
                  <h2 class="text-xl font-bold text-gray-900">Password Settings</h2>
                  <p class="text-gray-600 text-sm">Change your account password</p>
                </div>
              </div>
              <.simple_form
                for={@password_form}
                id="password_form"
                action={~p"/users/log_in?_action=password_updated"}
                method="post"
                phx-change="validate_password"
                phx-submit="update_password"
                phx-trigger-action={@trigger_submit}
              >
                <input
                  name={@password_form[:email].name}
                  type="hidden"
                  id="hidden_user_email"
                  value={@current_email}
                />
                <.input
                  field={@password_form[:password]}
                  type="password"
                  label="New password"
                  required
                  class="mb-3"
                />
                <.input
                  field={@password_form[:password_confirmation]}
                  type="password"
                  label="Confirm new password"
                  class="mb-3"
                />
                <.input
                  field={@password_form[:current_password]}
                  name="current_password"
                  type="password"
                  label="Current password"
                  id="current_password_for_password"
                  value={@current_password}
                  required
                  class="mb-4"
                />
                <:actions>
                  <.button variant="success" phx-disable-with="Changing..." class="w-full">
                    <.icon name="hero-check" class="w-5 h-5 mr-2" /> Update Password
                  </.button>
                </:actions>
              </.simple_form>
            </div>
          </div>
          <!-- YouTube Integration Card -->
          <div class="bg-white rounded-md border border-gray-100 p-4 w-full">
            <div class="flex items-end justify-between mb-4">
              <div class="flex items-center">
                <div class="w-12 h-12 bg-red-100 rounded-md flex items-center justify-center mr-3">
                  <.icon name="hero-video-camera" class="w-8 h-8 text-red-600" />
                </div>
                <div>
                  <h2 class="text-xl font-bold text-gray-900">YouTube Integration</h2>
                  <p class="text-gray-600 text-sm">
                    Connect your YouTube channels to automatically upload generated shorts.
                  </p>
                </div>
              </div>
              <.button phx-click="open_youtube_modal" variant="gradient" size="md">
                <.icon name="hero-play" class="w-5 h-5 mr-2" /> Connect YouTube Channel
              </.button>
            </div>
            <!-- Connected Channels -->
            <div>
              <h3 class="text-base font-semibold text-gray-900 mb-2 flex items-center">
                <.icon name="hero-link" class="w-5 h-5 mr-2 text-green-600" /> Connected Channels
              </h3>
              <div class="space-y-3">
                <div
                  :for={channel <- @current_user.youtube_channels}
                  :if={@current_user.youtube_channels != []}
                  class="bg-white rounded-lg shadow-sm p-4 mb-3 hover:shadow-md transition"
                >
                  <div class="flex items-center justify-between">
                    <div class="flex items-center">
                      <img
                        src={channel.metadata["snippet"]["thumbnails"]["default"]["url"]}
                        alt="Channel thumbnail"
                        class="w-10 h-10 rounded-full border border-gray-200 shadow-sm mr-3"
                      />
                      <div>
                        <p class="font-semibold text-gray-900 text-base">{channel.channel_title}</p>
                        <a
                          class="text-xs text-blue-600 hover:underline"
                          href={channel.channel_url}
                          target="_blank"
                        >
                          {channel.channel_url}
                        </a>
                      </div>
                    </div>
                    <div class="flex items-center gap-3">
                      <.status_badge
                        status={humanize_status(:connected)}
                        variant={get_status_variant(:connected)}
                        size="lg"
                      />
                      <button
                        phx-click="disconnect_youtube_channel"
                        phx-value-id={channel.id}
                        class="text-gray-400 hover:text-red-600 transition-colors p-1 rounded-full"
                        title="Disconnect"
                      >
                        <.icon name="hero-trash" class="w-5 h-5" />
                      </button>
                    </div>
                  </div>
                </div>
                <!-- No channels connected state -->
                <div :if={@current_user.youtube_channels == []} class="text-center py-6 text-gray-500">
                  <div class="w-12 h-12 bg-gray-100 rounded-md flex items-center justify-center mx-auto mb-2">
                    <.icon name="hero-play" class="w-6 h-6 text-gray-400" />
                  </div>
                  <p class="text-xs">No channels connected yet</p>
                  <p class="text-xs text-gray-400 mt-1">
                    Connect your first YouTube channel to get started
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>
        
    <!-- YouTube Connect Modal -->
        <.modal
          :if={@show_youtube_modal}
          id="youtube-connect-modal"
          show={@show_youtube_modal}
          on_cancel={JS.push("close_youtube_modal")}
        >
          <div class="p-6 max-w-xl mx-auto">
            <h2 class="text-2xl font-bold mb-6 text-center">Connect a YouTube Channel</h2>
            <%= if @youtube_channel_candidates && @youtube_channel_candidates != [] do %>
              <p class="mb-4 text-gray-600 text-center">Select a channel to connect:</p>
              <ul class="space-y-4">
                <%= for channel <- @youtube_channel_candidates do %>
                  <li class="flex items-center justify-between bg-gray-50 rounded-lg p-3 shadow-sm hover:bg-gray-100 transition">
                    <div class="flex items-center space-x-3">
                      <img
                        src={channel["snippet"]["thumbnails"]["default"]["url"]}
                        alt="Channel thumbnail"
                        class="w-10 h-10 rounded-full border"
                      />
                      <span class="font-medium text-gray-800">{channel["snippet"]["title"]}</span>
                    </div>
                    <.button
                      :if={
                        !Enum.any?(@current_user.youtube_channels, &(&1.channel_id == channel["id"]))
                      }
                      phx-click="connect_youtube_channel"
                      phx-value-id={channel["id"]}
                      variant="primary"
                      size="md"
                    >
                      Connect
                    </.button>
                    <.button
                      :if={
                        Enum.any?(@current_user.youtube_channels, &(&1.channel_id == channel["id"]))
                      }
                      phx-click="connect_youtube_channel"
                      phx-value-id={channel["id"]}
                      variant="disabled"
                      size="md"
                    >
                      Already connected
                    </.button>
                  </li>
                <% end %>
              </ul>
            <% else %>
              <p class="mb-6 text-gray-600 text-center">
                No YouTube channels found for your account.<br />
                Make sure you are signed in with the correct Google account and have a YouTube channel.
              </p>
              <button
                id="youtube-oauth-btn"
                class="w-full flex items-center justify-center px-4 py-2 bg-gradient-to-r from-red-600 to-red-700 text-white font-semibold rounded-xl hover:from-red-700 hover:to-red-800"
                onclick="window.open('/auth/youtube', 'oauthPopup', 'width=500,height=700'); return false;"
              >
                <svg class="w-5 h-5 mr-2" viewBox="0 0 48 48">
                  <g>
                    <path
                      fill="#4285F4"
                      d="M43.6 20.5H42V20H24v8h11.3C34.7 32.1 30.1 35 24 35c-6.1 0-11.3-4.1-13.1-9.6-1.8-5.5.2-11.5 5.1-14.7 4.9-3.2 11.3-2.7 15.6 1.2l6.2-6.2C34.1 2.7 29.2 0 24 0 14.6 0 6.5 6.7 3.2 16.1c-3.3 9.4.2 19.8 8.2 25.2 8 5.4 18.7 3.7 25.1-3.7 4.2-4.6 6.5-10.7 6.5-17.1 0-1.2-.1-2.3-.2-3.4z"
                    />
                    <path
                      fill="#34A853"
                      d="M6.3 14.1l6.6 4.8C14.2 16.1 18.7 13 24 13c3.1 0 6 .9 8.3 2.5l6.2-6.2C34.1 2.7 29.2 0 24 0 14.6 0 6.5 6.7 3.2 16.1c-.5 1.3-.8 2.7-.9 4.1z"
                    />
                    <path
                      fill="#FBBC05"
                      d="M24 48c6.5 0 12.4-2.1 16.7-5.7l-7.7-6.3c-2.3 1.5-5.2 2.4-8.3 2.4-6.1 0-11.3-4.1-13.1-9.6l-7.6 5.9C6.5 41.3 14.6 48 24 48z"
                    />
                    <path
                      fill="#EA4335"
                      d="M43.6 20.5H42V20H24v8h11.3c-1.1 3.1-3.7 5.7-7.3 7.1l7.7 6.3c2.2-2 4.1-4.5 5.3-7.4 1.2-2.9 1.9-6 1.9-9.5 0-1.2-.1-2.3-.2-3.4z"
                    />
                  </g>
                </svg>
                Sign in with Google
              </button>
            <% end %>
          </div>
        </.modal>
      </div>
    </div>
    """
  end

  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_user, token) do
        :ok ->
          put_flash(socket, :info, "Email changed successfully.")

        :error ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  def mount(_params, _session, socket) do
    user = preload(socket.assigns.current_user, [:youtube_channels])
    email_changeset = Accounts.change_user_email(user)
    password_changeset = Accounts.change_user_password(user)

    socket =
      socket
      |> assign(:current_password, nil)
      |> assign(:email_form_current_password, nil)
      |> assign(:current_email, user.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:trigger_submit, false)
      |> assign(:current_user, user)
      |> assign(:show_youtube_modal, false)
      |> assign(:youtube_channel_candidates, nil)

    {:ok, socket}
  end

  def handle_event("validate_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    email_form =
      socket.assigns.current_user
      |> Accounts.change_user_email(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form, email_form_current_password: password)}
  end

  def handle_event("update_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        Accounts.deliver_user_update_email_instructions(
          applied_user,
          user.email,
          &url(~p"/users/settings/confirm_email/#{&1}")
        )

        info = "A link to confirm your email change has been sent to the new address."
        {:noreply, socket |> put_flash(:info, info) |> assign(email_form_current_password: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    password_form =
      socket.assigns.current_user
      |> Accounts.change_user_password(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form, current_password: password)}
  end

  def handle_event("update_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        password_form =
          user
          |> Accounts.change_user_password(user_params)
          |> to_form()

        {:noreply, assign(socket, trigger_submit: true, password_form: password_form)}

      {:error, changeset} ->
        {:noreply, assign(socket, password_form: to_form(changeset))}
    end
  end

  def handle_event("disconnect_youtube_channel", %{"id" => id}, socket) do
    channel = Enum.find(socket.assigns.current_user.youtube_channels, &(&1.id == id))

    if channel do
      {:ok, _} = ShortCraft.Accounts.delete_youtube_channel(channel)
      updated_channels = Enum.reject(socket.assigns.current_user.youtube_channels, &(&1.id == id))
      updated_user = %{socket.assigns.current_user | youtube_channels: updated_channels}
      {:noreply, assign(socket, current_user: updated_user)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("open_youtube_modal", _params, socket) do
    user = socket.assigns.current_user

    if user.provider == "google" and user.access_token do
      case get_valid_access_token(user) do
        {:ok, access_token, updated_user} ->
          case Youtube.fetch_youtube_channels(access_token) do
            {:ok, channels} ->
              {:noreply,
               assign(socket,
                 show_youtube_modal: true,
                 youtube_channel_candidates: channels,
                 current_user: updated_user
               )}

            {:error, _} ->
              {:noreply,
               assign(socket, show_youtube_modal: true, youtube_channel_candidates: nil)}
          end

        {:error, _} ->
          {:noreply, assign(socket, show_youtube_modal: true, youtube_channel_candidates: nil)}
      end
    else
      {:noreply, assign(socket, show_youtube_modal: true, youtube_channel_candidates: nil)}
    end
  end

  def handle_event("close_youtube_modal", _params, socket) do
    {:noreply, assign(socket, show_youtube_modal: false, youtube_channel_candidates: nil)}
  end

  def handle_event("connect_youtube_channel", %{"id" => channel_id}, socket) do
    # Find the channel in youtube_channel_candidates and save to DB
    channel = Enum.find(socket.assigns.youtube_channel_candidates, &(&1["id"] == channel_id))

    if channel do
      attrs = %{
        user_id: socket.assigns.current_user.id,
        channel_id: channel["id"],
        channel_title: channel["snippet"]["title"],
        channel_url: "https://www.youtube.com/channel/#{channel["id"]}",
        access_token: socket.assigns.current_user.access_token,
        refresh_token: socket.assigns.current_user.refresh_token,
        expires_at: socket.assigns.current_user.expires_at,
        is_connected: true,
        metadata: channel
      }

      Accounts.create_youtube_channel(attrs)
      # Optionally update assigns to show the new channel
      {:noreply, assign(socket, show_youtube_modal: false)}
    else
      {:noreply, socket}
    end
  end

  defp get_valid_access_token(user) do
    if user.access_token do
      case OAuthService.refresh_token("google", user.refresh_token) do
        {:ok, new_token_data} ->
          {:ok, _} = Accounts.update_user_tokens(user, new_token_data)
          updated_user = preload(Accounts.get_user!(user.id), [:youtube_channels])
          {:ok, new_token_data["access_token"], updated_user}

        {:error, reason} ->
          {:error, reason}
      end
    else
      {:error, "No access token found"}
    end
  end
end
