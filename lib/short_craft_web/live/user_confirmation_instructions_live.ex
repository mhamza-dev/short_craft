defmodule ShortCraftWeb.UserConfirmationInstructionsLive do
  use ShortCraftWeb, :live_view

  alias ShortCraft.Accounts

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-blue-50 via-white to-purple-50 flex items-center justify-center py-12 px-4 sm:px-6 lg:px-8">
      <div class="max-w-md w-full space-y-8">
        <!-- Logo and Brand -->
        <div class="text-center">
          <div class="mx-auto w-16 h-16 bg-gradient-to-br from-blue-600 to-purple-600 rounded-2xl flex items-center justify-center shadow-xl mb-6">
            <svg class="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z"
              >
              </path>
            </svg>
          </div>
          <h2 class="text-3xl font-bold text-gray-900 mb-2">
            No confirmation instructions received?
          </h2>
          <p class="text-gray-600">We'll send a new confirmation link to your inbox</p>
        </div>
        
    <!-- Resend Form -->
        <div class="bg-white rounded-2xl shadow-xl border border-gray-100 p-8">
          <.simple_form for={@form} id="resend_confirmation_form" phx-submit="send_instructions">
            <.input
              field={@form[:email]}
              type="email"
              label="Email address"
              placeholder="Enter your email"
              required
            />
            <:actions>
              <.button variant="gradient" size="lg" phx-disable-with="Sending..." class="w-full">
                Resend confirmation instructions
                <.icon name="hero-arrow-right" class="w-4 h-4 ml-2" />
              </.button>
            </:actions>
          </.simple_form>

          <div class="mt-6 text-center">
            <p class="text-sm text-gray-600">
              <.link
                href={~p"/users/register"}
                class="font-semibold text-blue-600 hover:text-blue-700 hover:underline"
              >
                Register
              </.link>
              <span class="mx-2 text-gray-400">|</span>
              <.link
                href={~p"/users/log_in"}
                class="font-semibold text-blue-600 hover:text-blue-700 hover:underline"
              >
                Log in
              </.link>
            </p>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, form: to_form(%{}, as: "user"))}
  end

  def handle_event("send_instructions", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_confirmation_instructions(
        user,
        &url(~p"/users/confirm/#{&1}")
      )
    end

    info =
      "If your email is in our system and it has not been confirmed yet, you will receive an email with instructions shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> redirect(to: ~p"/")}
  end
end
