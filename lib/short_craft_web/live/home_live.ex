defmodule ShortCraftWeb.HomeLive do
  use ShortCraftWeb, :live_view

  on_mount {ShortCraftWeb.UserAuth, :mount_current_user}

  def render(assigns) do
    ~H"""
    <!-- Hero Section -->
    <div class="relative overflow-hidden bg-gradient-to-br from-blue-50 via-white to-purple-50 pb-24">
      <div class="absolute inset-0">
        <div class="absolute inset-0 bg-gradient-to-r from-blue-600/5 to-purple-600/5"></div>
        <div class="absolute top-0 left-1/2 -translate-x-1/2 w-[800px] h-[600px] bg-gradient-to-br from-blue-400/10 to-purple-400/10 rounded-full blur-3xl">
        </div>
      </div>
      <div class="relative px-4 py-20 sm:px-6 sm:py-32 lg:px-8">
        <div class="mx-auto max-w-4xl text-center">
          <div class="flex justify-center mb-8">
            <div class="w-16 h-16 bg-gradient-to-br from-blue-600 to-purple-600 rounded-2xl flex items-center justify-center shadow-xl">
              <.logo class="w-8 h-8" color="white" />
            </div>
          </div>
          <h1 class="text-5xl sm:text-6xl font-bold text-gray-900 mb-4">
            Instantly turn YouTube videos into viral shorts
          </h1>
          <p class="text-xl text-gray-600 mb-8 max-w-2xl mx-auto leading-relaxed">
            ShortCraft is the all-in-one platform for creators and marketers to repurpose long-form YouTube content into engaging, shareable short videos—automatically.
          </p>
          <div class="flex flex-col sm:flex-row gap-4 justify-center mb-8">
            <.link
              href={~p"/users/register"}
              class="inline-flex items-center justify-center px-8 py-4 bg-gradient-to-r from-blue-600 to-purple-600 text-white font-semibold rounded-xl hover:from-blue-700 hover:to-purple-700 transition-all duration-200 shadow-lg hover:shadow-xl transform hover:-translate-y-0.5"
            >
              <.icon name="hero-rocket-launch" class="w-5 h-5 mr-2" /> Get Started Free
            </.link>
            <.link
              href={~p"/source_videos"}
              class="inline-flex items-center justify-center px-8 py-4 bg-white text-gray-700 font-semibold rounded-xl hover:bg-gray-50 transition-all duration-200 shadow-lg hover:shadow-xl border border-gray-200"
            >
              <.icon name="hero-video-camera" class="w-5 h-5 mr-2" /> View My Videos
            </.link>
          </div>
          <div class="flex justify-center mt-8">
            <div class="rounded-2xl overflow-hidden shadow-xl border border-gray-100 bg-white w-full max-w-2xl">
              <img
                src="/images/landing-screenshot-placeholder.png"
                alt="ShortCraft dashboard screenshot"
                class="w-full h-64 object-cover object-top"
              />
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- How it Works Section -->
    <div class="py-20 px-4 sm:px-6 lg:px-8 bg-white">
      <div class="mx-auto max-w-5xl">
        <div class="text-center mb-12">
          <h2 class="text-3xl font-bold text-gray-900 mb-4">How it works</h2>
          <p class="text-lg text-gray-600">Go from YouTube link to viral short in minutes</p>
        </div>
        <div class="grid grid-cols-1 md:grid-cols-4 gap-8">
          <div class="flex flex-col items-center text-center">
            <div class="w-14 h-14 bg-blue-100 rounded-xl flex items-center justify-center mb-4">
              <.icon name="hero-link" class="w-7 h-7 text-blue-600" />
            </div>
            <h3 class="font-semibold text-gray-900 mb-1">Paste YouTube Link</h3>
            <p class="text-gray-600 text-sm">Add any YouTube video URL to start.</p>
          </div>
          <div class="flex flex-col items-center text-center">
            <div class="w-14 h-14 bg-purple-100 rounded-xl flex items-center justify-center mb-4">
              <.icon name="hero-cog-6-tooth" class="w-7 h-7 text-purple-600" />
            </div>
            <h3 class="font-semibold text-gray-900 mb-1">Configure & Generate</h3>
            <p class="text-gray-600 text-sm">
              Choose your short length, number, and style. Let AI do the rest.
            </p>
          </div>
          <div class="flex flex-col items-center text-center">
            <div class="w-14 h-14 bg-green-100 rounded-xl flex items-center justify-center mb-4">
              <.icon name="hero-scissors" class="w-7 h-7 text-green-600" />
            </div>
            <h3 class="font-semibold text-gray-900 mb-1">Edit & Preview</h3>
            <p class="text-gray-600 text-sm">Fine-tune your shorts with our intuitive editor.</p>
          </div>
          <div class="flex flex-col items-center text-center">
            <div class="w-14 h-14 bg-red-100 rounded-xl flex items-center justify-center mb-4">
              <.icon name="hero-cloud-arrow-up" class="w-7 h-7 text-red-600" />
            </div>
            <h3 class="font-semibold text-gray-900 mb-1">Publish Anywhere</h3>
            <p class="text-gray-600 text-sm">
              Upload directly to YouTube Shorts or download for any platform.
            </p>
          </div>
        </div>
      </div>
    </div>

    <!-- Why ShortCraft Section -->
    <div class="py-20 px-4 sm:px-6 lg:px-8 bg-gradient-to-br from-blue-50 via-white to-purple-50">
      <div class="mx-auto max-w-5xl">
        <div class="text-center mb-12">
          <h2 class="text-3xl font-bold text-gray-900 mb-4">Why ShortCraft?</h2>
        </div>
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
          <div class="flex flex-col items-center text-center">
            <div class="w-12 h-12 bg-blue-100 rounded-xl flex items-center justify-center mb-3">
              <.icon name="hero-bolt" class="w-6 h-6 text-blue-600" />
            </div>
            <h3 class="font-semibold text-gray-900 mb-1">Lightning Fast</h3>
            <p class="text-gray-600 text-sm">Process and generate shorts in seconds, not hours.</p>
          </div>
          <div class="flex flex-col items-center text-center">
            <div class="w-12 h-12 bg-green-100 rounded-xl flex items-center justify-center mb-3">
              <.icon name="hero-sparkles" class="w-6 h-6 text-green-600" />
            </div>
            <h3 class="font-semibold text-gray-900 mb-1">Fully Automated</h3>
            <p class="text-gray-600 text-sm">AI-powered scene detection, editing, and publishing.</p>
          </div>
          <div class="flex flex-col items-center text-center">
            <div class="w-12 h-12 bg-purple-100 rounded-xl flex items-center justify-center mb-3">
              <.icon name="hero-shield-check" class="w-6 h-6 text-purple-600" />
            </div>
            <h3 class="font-semibold text-gray-900 mb-1">Secure & Private</h3>
            <p class="text-gray-600 text-sm">
              Your content is processed securely—no third-party sharing.
            </p>
          </div>
          <div class="flex flex-col items-center text-center">
            <div class="w-12 h-12 bg-orange-100 rounded-xl flex items-center justify-center mb-3">
              <.icon name="hero-user-group" class="w-6 h-6 text-orange-600" />
            </div>
            <h3 class="font-semibold text-gray-900 mb-1">For All Creators</h3>
            <p class="text-gray-600 text-sm">
              Designed for YouTubers, marketers, agencies, and educators.
            </p>
          </div>
        </div>
      </div>
    </div>

    <!-- Who is it for Section -->
    <div class="py-20 px-4 sm:px-6 lg:px-8 bg-white">
      <div class="mx-auto max-w-5xl">
        <div class="text-center mb-12">
          <h2 class="text-3xl font-bold text-gray-900 mb-4">Who is ShortCraft for?</h2>
        </div>
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
          <div class="flex flex-col items-center text-center">
            <div class="w-12 h-12 bg-blue-100 rounded-xl flex items-center justify-center mb-3">
              <.icon name="hero-video-camera" class="w-6 h-6 text-blue-600" />
            </div>
            <h3 class="font-semibold text-gray-900 mb-1">YouTubers</h3>
            <p class="text-gray-600 text-sm">
              Grow your channel and reach new audiences with shorts.
            </p>
          </div>
          <div class="flex flex-col items-center text-center">
            <div class="w-12 h-12 bg-green-100 rounded-xl flex items-center justify-center mb-3">
              <.icon name="hero-megaphone" class="w-6 h-6 text-green-600" />
            </div>
            <h3 class="font-semibold text-gray-900 mb-1">Marketers</h3>
            <p class="text-gray-600 text-sm">Repurpose long-form content for social media and ads.</p>
          </div>
          <div class="flex flex-col items-center text-center">
            <div class="w-12 h-12 bg-purple-100 rounded-xl flex items-center justify-center mb-3">
              <.icon name="hero-academic-cap" class="w-6 h-6 text-purple-600" />
            </div>
            <h3 class="font-semibold text-gray-900 mb-1">Educators</h3>
            <p class="text-gray-600 text-sm">Turn lectures and tutorials into bite-sized learning.</p>
          </div>
          <div class="flex flex-col items-center text-center">
            <div class="w-12 h-12 bg-orange-100 rounded-xl flex items-center justify-center mb-3">
              <.icon name="hero-briefcase" class="w-6 h-6 text-orange-600" />
            </div>
            <h3 class="font-semibold text-gray-900 mb-1">Agencies</h3>
            <p class="text-gray-600 text-sm">Bulk process and manage content for multiple clients.</p>
          </div>
        </div>
      </div>
    </div>

    <!-- FAQ Section -->
    <div class="py-20 px-4 sm:px-6 lg:px-8 bg-gradient-to-br from-blue-50 via-white to-purple-50">
      <div class="mx-auto max-w-4xl">
        <div class="text-center mb-12">
          <h2 class="text-3xl font-bold text-gray-900 mb-4">Frequently Asked Questions</h2>
        </div>
        <div class="space-y-6">
          <div class="bg-white rounded-xl shadow p-6">
            <h3 class="font-semibold text-gray-900 mb-2">Is ShortCraft free to use?</h3>
            <p class="text-gray-600 text-sm">
              Yes! You can get started for free and upgrade for more features.
            </p>
          </div>
          <div class="bg-white rounded-xl shadow p-6">
            <h3 class="font-semibold text-gray-900 mb-2">Do I need to install anything?</h3>
            <p class="text-gray-600 text-sm">
              No downloads required. ShortCraft runs entirely in your browser.
            </p>
          </div>
          <div class="bg-white rounded-xl shadow p-6">
            <h3 class="font-semibold text-gray-900 mb-2">Can I upload directly to YouTube?</h3>
            <p class="text-gray-600 text-sm">
              Yes, connect your YouTube channel and publish shorts in one click.
            </p>
          </div>
          <div class="bg-white rounded-xl shadow p-6">
            <h3 class="font-semibold text-gray-900 mb-2">Is my data secure?</h3>
            <p class="text-gray-600 text-sm">
              Absolutely. Your videos are processed securely and never shared with third parties.
            </p>
          </div>
          <div class="bg-white rounded-xl shadow p-6">
            <h3 class="font-semibold text-gray-900 mb-2">Who can use ShortCraft?</h3>
            <p class="text-gray-600 text-sm">
              Anyone! Whether you're a creator, marketer, educator, or agency, ShortCraft is built for you.
            </p>
          </div>
        </div>
      </div>
    </div>

    <!-- Get Started CTA -->
    <div class="py-20 px-4 sm:px-6 lg:px-8 bg-white">
      <div class="mx-auto max-w-2xl text-center">
        <h2 class="text-3xl font-bold text-gray-900 mb-4">Ready to create viral shorts?</h2>
        <p class="text-lg text-gray-600 mb-8">
          Join thousands of creators already using ShortCraft to maximize their content reach.
        </p>
        <.link
          href={~p"/users/register"}
          class="inline-flex items-center justify-center px-8 py-4 bg-gradient-to-r from-blue-600 to-purple-600 text-white font-semibold rounded-xl hover:from-blue-700 hover:to-purple-700 transition-all duration-200 shadow-lg hover:shadow-xl transform hover:-translate-y-0.5"
        >
          <.icon name="hero-rocket-launch" class="w-5 h-5 mr-2" /> Get Started Free
        </.link>
      </div>
    </div>

    <.footer />
    """
  end
end
