defmodule ShortCraftWeb.UserLoginLive do
  use ShortCraftWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.header class="text-center">
        Log in to account
        <:subtitle>
          Don't have an account?
          <.link navigate={~p"/users/register"} class="font-semibold text-brand hover:underline">
            Sign up
          </.link>
          for an account now.
        </:subtitle>
      </.header>

      <.simple_form for={@form} id="login_form" action={~p"/users/log_in"} phx-update="ignore">
        <.input field={@form[:email]} type="email" label="Email" required />
        <.input field={@form[:password]} type="password" label="Password" required />

        <:actions>
          <.input field={@form[:remember_me]} type="checkbox" label="Keep me logged in" />
          <.link href={~p"/users/reset_password"} class="text-sm font-semibold">
            Forgot your password?
          </.link>
        </:actions>
        <:actions>
          <.button phx-disable-with="Logging in..." class="w-full">
            Log in <span aria-hidden="true">→</span>
          </.button>
        </:actions>
        <:after_actions>
          <p class="text-sm text-gray-500 mb-2">
            Or login with
          </p>
          <div class="flex items-center justify-between w-[50%] gap-4">
            <.link
              href={~p"/auth/google"}
              class="w-6 h-6 flex flex-col items-center justify-center gap-4 cursor-pointer hover:opacity-80"
            >
              <i class="fa-brands fa-google fa-xl"></i>
              <span class="text-sm text-gray-400">Google</span>
            </.link>
            <.link
              href={~p"/auth/github"}
              class="w-6 h-6 flex flex-col items-center justify-center gap-4 cursor-pointer hover:opacity-80"
            >
              <i class="fa-brands fa-github fa-xl"></i>
              <span class="text-sm text-gray-400">GitHub</span>
            </.link>
            <.link
              href={~p"/auth/facebook"}
              class="w-6 h-6 flex flex-col items-center justify-center gap-4 cursor-pointer hover:opacity-80"
            >
              <i class="fa-brands fa-facebook fa-xl"></i>
              <span class="text-sm text-gray-400">Facebook</span>
            </.link>
          </div>
        </:after_actions>
      </.simple_form>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")
    {:ok, assign(socket, form: form), temporary_assigns: [form: form]}
  end
end
