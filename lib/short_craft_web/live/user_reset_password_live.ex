defmodule ShortCraftWeb.UserResetPasswordLive do
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
          <h2 class="text-3xl font-bold text-gray-900 mb-2">Reset Password</h2>
          <p class="text-gray-600">Enter your new password below</p>
        </div>
        
    <!-- Reset Form -->
        <div class="bg-white rounded-2xl shadow-xl border border-gray-100 p-8">
          <.simple_form
            for={@form}
            id="reset_password_form"
            phx-submit="reset_password"
            phx-change="validate"
          >
            <.error :if={@form.errors != []}>
              <div class="bg-red-50 border border-red-200 rounded-lg p-4 mb-6">
                <div class="flex">
                  <.icon name="hero-exclamation-circle" class="w-5 h-5 text-red-400 mr-2" />
                  <p class="text-sm text-red-800">
                    Oops, something went wrong! Please check the errors below.
                  </p>
                </div>
              </div>
            </.error>

            <.input field={@form[:password]} type="password" label="New password" required />
            <.input
              field={@form[:password_confirmation]}
              type="password"
              label="Confirm new password"
              required
            />
            <:actions>
              <.button variant="gradient" size="lg" phx-disable-with="Resetting..." class="w-full">
                Reset Password <.icon name="hero-arrow-right" class="w-4 h-4 ml-2" />
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

  def mount(params, _session, socket) do
    socket = assign_user_and_token(socket, params)

    form_source =
      case socket.assigns do
        %{user: user} ->
          Accounts.change_user_password(user)

        _ ->
          %{}
      end

    {:ok, assign_form(socket, form_source), temporary_assigns: [form: nil]}
  end

  # Do not log in the user after reset password to avoid a
  # leaked token giving the user access to the account.
  def handle_event("reset_password", %{"user" => user_params}, socket) do
    case Accounts.reset_user_password(socket.assigns.user, user_params) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Password reset successfully.")
         |> redirect(to: ~p"/users/log_in")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, Map.put(changeset, :action, :insert))}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_password(socket.assigns.user, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_user_and_token(socket, %{"token" => token}) do
    if user = Accounts.get_user_by_reset_password_token(token) do
      assign(socket, user: user, token: token)
    else
      socket
      |> put_flash(:error, "Reset password link is invalid or it has expired.")
      |> redirect(to: ~p"/")
    end
  end

  defp assign_form(socket, %{} = source) do
    assign(socket, :form, to_form(source, as: "user"))
  end
end
