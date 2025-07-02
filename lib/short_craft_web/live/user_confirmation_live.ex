defmodule ShortCraftWeb.UserConfirmationLive do
  use ShortCraftWeb, :live_view

  alias ShortCraft.Accounts

  def render(%{live_action: :edit} = assigns) do
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
          <h2 class="text-3xl font-bold text-gray-900 mb-2">Confirm Account</h2>
          <p class="text-gray-600">Click the button below to confirm your account</p>
        </div>
        
    <!-- Confirmation Form -->
        <div class="bg-white rounded-2xl shadow-xl border border-gray-100 p-8">
          <.simple_form for={@form} id="confirmation_form" phx-submit="confirm_account">
            <input type="hidden" name={@form[:token].name} value={@form[:token].value} />
            <:actions>
              <.button variant="gradient" size="lg" phx-disable-with="Confirming..." class="w-full">
                Confirm my account <.icon name="hero-check" class="w-4 h-4 ml-2" />
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

  def mount(%{"token" => token}, _session, socket) do
    form = to_form(%{"token" => token}, as: "user")
    {:ok, assign(socket, form: form), temporary_assigns: [form: nil]}
  end

  # Do not log in the user after confirmation to avoid a
  # leaked token giving the user access to the account.
  def handle_event("confirm_account", %{"user" => %{"token" => token}}, socket) do
    case Accounts.confirm_user(token) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "User confirmed successfully.")
         |> redirect(to: ~p"/")}

      :error ->
        # If there is a current user and the account was already confirmed,
        # then odds are that the confirmation link was already visited, either
        # by some automation or by the user themselves, so we redirect without
        # a warning message.
        case socket.assigns do
          %{current_user: %{confirmed_at: confirmed_at}} when not is_nil(confirmed_at) ->
            {:noreply, redirect(socket, to: ~p"/")}

          %{} ->
            {:noreply,
             socket
             |> put_flash(:error, "User confirmation link is invalid or it has expired.")
             |> redirect(to: ~p"/")}
        end
    end
  end
end
