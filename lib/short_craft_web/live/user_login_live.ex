defmodule ShortCraftWeb.UserLoginLive do
  use ShortCraftWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="flex items-center justify-center">
      <div class="max-w-md w-full space-y-8">
        <!-- Logo and Brand -->
        <div class="text-center">
          <div class="mx-auto w-16 h-16 bg-gradient-to-br from-blue-600 to-purple-600 rounded-2xl flex items-center justify-center shadow-xl mb-6">
            <.logo class="w-8 h-8" color="white" />
          </div>
          <h2 class="text-3xl font-bold text-gray-900 mb-2">Welcome back</h2>
          <p class="text-gray-600">
            Don't have an account?
            <.link
              navigate={~p"/users/register"}
              class="font-semibold text-blue-600 hover:text-blue-700 hover:underline"
            >
              Sign up
            </.link>
            for an account now.
          </p>
        </div>
        
    <!-- Login Form -->
        <div class="bg-white rounded-2xl shadow-xl border border-gray-100 p-8">
          <.simple_form for={@form} id="login_form" action={~p"/users/log_in"} phx-update="ignore">
            <.input field={@form[:email]} type="email" label="Email address" required />
            <.input field={@form[:password]} type="password" label="Password" required />

            <:actions>
              <div class="flex items-center justify-between w-full">
                <.input field={@form[:remember_me]} type="checkbox" label="Keep me logged in" />
                <.link
                  href={~p"/users/reset_password"}
                  class="text-sm font-semibold text-blue-600 hover:text-blue-700 hover:underline"
                >
                  Forgot your password?
                </.link>
              </div>
            </:actions>

            <:actions>
              <.button variant="gradient" size="lg" phx-disable-with="Logging in..." class="w-full">
                Log in <.icon name="hero-arrow-right" class="w-4 h-4 ml-2" />
              </.button>
            </:actions>

            <:after_actions>
              <div class="relative">
                <div class="absolute inset-0 flex items-center">
                  <div class="w-full border-t border-gray-300"></div>
                </div>
                <div class="relative flex justify-center text-sm">
                  <span class="px-2 bg-white text-gray-500">Or continue with</span>
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
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")
    {:ok, assign(socket, form: form), temporary_assigns: [form: form]}
  end
end
