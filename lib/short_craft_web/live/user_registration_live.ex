defmodule ShortCraftWeb.UserRegistrationLive do
  use ShortCraftWeb, :live_view

  alias ShortCraft.Accounts
  alias ShortCraft.Accounts.User

  def render(assigns) do
    ~H"""
    <div class="flex items-center justify-center">
      <div class="max-w-md w-full space-y-8">
        <!-- Logo and Brand -->
        <div class="text-center">
          <div class="mx-auto w-16 h-16 bg-gradient-to-br from-blue-600 to-purple-600 rounded-2xl flex items-center justify-center shadow-xl mb-6">
            <.logo class="w-8 h-8" color="white" />
          </div>
          <h2 class="text-3xl font-bold text-gray-900 mb-2">Create your account</h2>
          <p class="text-gray-600">
            Already registered?
            <.link
              navigate={~p"/users/log_in"}
              class="font-semibold text-blue-600 hover:text-blue-700 hover:underline"
            >
              Log in
            </.link>
            to your account now.
          </p>
        </div>

    <!-- Registration Form -->
        <div class="bg-white rounded-2xl shadow-xl border border-gray-100 p-8">
          <.simple_form
            for={@form}
            id="registration_form"
            phx-submit="save"
            phx-change="validate"
            phx-trigger-action={@trigger_submit}
            action={~p"/users/log_in?_action=registered"}
            method="post"
          >
            <.error :if={@check_errors}>
              <div class="bg-red-50 border border-red-200 rounded-lg p-4 mb-6">
                <div class="flex">
                  <.icon name="hero-exclamation-circle" class="w-5 h-5 text-red-400 mr-2" />
                  <p class="text-sm text-red-800">
                    Oops, something went wrong! Please check the errors below.
                  </p>
                </div>
              </div>
            </.error>

            <.input field={@form[:email]} type="email" label="Email address" required />
            <.input field={@form[:password]} type="password" label="Password" required />

            <:actions>
              <.button
                variant="gradient"
                size="lg"
                phx-disable-with="Creating account..."
                class="w-full"
              >
                Create an account <.icon name="hero-arrow-right" class="w-4 h-4 ml-2" />
              </.button>
            </:actions>

            <:after_actions>
              <div class="relative">
                <div class="absolute inset-0 flex items-center">
                  <div class="w-full border-t border-gray-300"></div>
                </div>
                <div class="relative flex justify-center text-sm">
                  <span class="px-2 bg-white text-gray-500">Or sign up with</span>
                </div>
              </div>

              <.social_links_grid>
                <.social_link provider="google" href={~p"/auth/google"} />
                <.social_link provider="github" href={~p"/auth/github"} />
                <.social_link provider="facebook" href={~p"/auth/facebook"} />
              </.social_links_grid>
            </:after_actions>
          </.simple_form>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{})

    socket =
      socket
      |> assign(trigger_submit: false, check_errors: false)
      |> assign_form(changeset)

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            &url(~p"/users/confirm/#{&1}")
          )

        changeset = Accounts.change_user_registration(user)
        {:noreply, socket |> assign(trigger_submit: true) |> assign_form(changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(check_errors: true) |> assign_form(changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_registration(%User{}, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")

    if changeset.valid? do
      assign(socket, form: form, check_errors: false)
    else
      assign(socket, form: form)
    end
  end
end
