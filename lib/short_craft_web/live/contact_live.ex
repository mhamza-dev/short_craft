defmodule ShortCraftWeb.ContactLive do
  use ShortCraftWeb, :live_view

  on_mount {ShortCraftWeb.UserAuth, :mount_current_user}

  def mount(_params, _session, socket) do
    {:ok, assign(socket, submitted: false)}
  end

  def handle_event("submit_contact", _params, socket) do
    {:noreply, assign(socket, submitted: true)}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-blue-50 via-white to-purple-50">
      <!-- Header Section -->
      <div class="bg-white shadow-sm border-b border-gray-100">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          <div class="text-center">
            <h1 class="text-4xl font-bold text-gray-900 mb-4">Get in Touch</h1>
            <p class="text-xl text-gray-600 max-w-2xl mx-auto">
              Have questions about ShortCraft? Need support? We're here to help you create amazing content.
            </p>
          </div>
        </div>
      </div>

      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-16">
        <div class="grid lg:grid-cols-2 gap-12 items-stretch">
          <!-- Contact Form Section -->
          <div class="bg-white rounded-md p-8 border border-gray-100 flex flex-col">
            <h2 class="text-2xl font-bold text-gray-900 mb-6">Send us a Message</h2>

            <%= if @submitted do %>
              <div class="bg-green-50 border border-green-200 rounded-xl p-6 text-center">
                <div class="w-12 h-12 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
                  <.icon name="hero-check" class="w-6 h-6 text-green-600" />
                </div>
                <h3 class="text-lg font-semibold text-green-800 mb-2">Message Sent!</h3>
                <p class="text-green-700">
                  Thank you for reaching out. We'll get back to you within 24 hours.
                </p>
              </div>
            <% else %>
              <.simple_form :let={f} for={%{}} phx-submit="submit_contact" class="space-y-6 flex-1">
                <.input
                  field={f[:name]}
                  type="text"
                  label="Name"
                  placeholder="Your full name"
                  required
                />

                <.input
                  field={f[:email]}
                  type="email"
                  label="Email"
                  placeholder="your.email@example.com"
                  required
                />

                <.input
                  type="textarea"
                  field={f[:message]}
                  label="Message"
                  placeholder="Tell us how we can help you..."
                  required
                />

                <.button type="submit" variant="gradient" size="lg" class="w-full">
                  Send Message
                </.button>
              </.simple_form>
            <% end %>
          </div>
          
    <!-- Contact Info Section -->
          <div class="bg-white rounded-md p-8 border border-gray-100 flex flex-col">
            <h3 class="text-xl font-bold text-gray-900 mb-6">Contact Information</h3>

            <div class="space-y-4 flex-1">
              <div class="flex items-center gap-4 p-4 bg-gray-50 rounded-xl">
                <div class="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center">
                  <.icon name="hero-envelope" class="w-5 h-5 text-blue-600" />
                </div>
                <div>
                  <p class="font-medium text-gray-900">Support Email</p>
                  <a href="mailto:support@shortcraft.app" class="text-blue-600 hover:text-blue-700">
                    support@shortcraft.app
                  </a>
                </div>
              </div>

              <div class="flex items-center gap-4 p-4 bg-gray-50 rounded-xl">
                <div class="w-10 h-10 bg-green-100 rounded-full flex items-center justify-center">
                  <.icon name="hero-clock" class="w-5 h-5 text-green-600" />
                </div>
                <div>
                  <p class="font-medium text-gray-900">Response Time</p>
                  <p class="text-gray-600">Within 24 hours</p>
                </div>
              </div>
            </div>
            
    <!-- Social Links -->
            <div class="mt-6 pt-6 border-t border-gray-200">
              <p class="text-sm font-medium text-gray-700 mb-3">Follow us</p>
              <div class="flex gap-3">
                <a
                  href="https://twitter.com/shortcraft"
                  target="_blank"
                  class="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center hover:bg-blue-200 transition"
                >
                  <.awesome_icon class="fa-brands fa-x-twitter fa-lg text-blue-600" />
                </a>
                <a
                  href="https://github.com/yourusername/short_craft"
                  target="_blank"
                  class="w-10 h-10 bg-gray-100 rounded-full flex items-center justify-center hover:bg-gray-200 transition"
                >
                  <.awesome_icon class="fa-brands fa-github fa-lg text-gray-700" />
                </a>
                <a
                  href="mailto:support@shortcraft.app"
                  class="w-10 h-10 bg-red-100 rounded-full flex items-center justify-center hover:bg-red-200 transition"
                >
                  <.icon name="hero-envelope" class="w-5 h-5 text-red-600" />
                </a>
              </div>
            </div>
          </div>
        </div>
      </div>

      <.footer />
    </div>
    """
  end
end
