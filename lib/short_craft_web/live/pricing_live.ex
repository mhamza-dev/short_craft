defmodule ShortCraftWeb.PricingLive do
  use ShortCraftWeb, :live_view

  on_mount {ShortCraftWeb.UserAuth, :mount_current_user}

  def render(assigns) do
    ~H"""
    <div class="py-16 px-4 sm:px-6 lg:px-8 bg-gradient-to-br from-blue-50 via-white to-purple-50 min-h-screen">
      <div class="mx-auto max-w-4xl text-center">
        <h2 class="text-3xl font-bold text-gray-900 mb-4">Pricing</h2>
        <p class="text-lg text-gray-600 mb-8">Simple, transparent pricing for every creator.</p>
        <div class="grid grid-cols-1 md:grid-cols-3 gap-8 mb-12">
          <.pricing_card
            title="Free"
            price="$0"
            features={["10 shorts/month", "Basic editing tools", "Community support"]}
            cta="Get Started"
            cta_link={~p"/users/register"}
          />
          <.pricing_card
            title="Pro"
            price="$19/mo"
            features={[
              "Unlimited shorts",
              "Advanced editing tools",
              "Priority support",
              "Direct YouTube upload"
            ]}
            cta="Start Pro"
            cta_link={~p"/users/register"}
            highlight={true}
          />
          <.pricing_card
            title="Enterprise"
            price="Custom"
            features={["Bulk processing", "Dedicated support", "Custom integrations"]}
            cta="Contact Us"
            cta_link={~p"/contact"}
          />
        </div>
        <!-- Pricing Comparison Table -->
        <div class="overflow-x-auto mb-16">
          <table class="min-w-full border rounded-xl bg-white shadow">
            <thead>
              <tr class="bg-blue-50 text-gray-700">
                <th class="px-6 py-3 text-left font-semibold">Feature</th>
                <th class="px-6 py-3 text-center font-semibold">Free</th>
                <th class="px-6 py-3 text-center font-semibold">Pro</th>
                <th class="px-6 py-3 text-center font-semibold">Enterprise</th>
              </tr>
            </thead>
            <tbody class="text-gray-700">
              <tr class="border-t">
                <td class="px-6 py-3">Shorts per month</td>
                <td class="px-6 py-3 text-center">10</td>
                <td class="px-6 py-3 text-center">Unlimited</td>
                <td class="px-6 py-3 text-center">Unlimited</td>
              </tr>
              <tr class="border-t">
                <td class="px-6 py-3">Direct YouTube Upload</td>
                <td class="px-6 py-3 text-center">-</td>
                <td class="px-6 py-3 text-center">✔️</td>
                <td class="px-6 py-3 text-center">✔️</td>
              </tr>
              <tr class="border-t">
                <td class="px-6 py-3">Advanced Editing Tools</td>
                <td class="px-6 py-3 text-center">-</td>
                <td class="px-6 py-3 text-center">✔️</td>
                <td class="px-6 py-3 text-center">✔️</td>
              </tr>
              <tr class="border-t">
                <td class="px-6 py-3">Priority Support</td>
                <td class="px-6 py-3 text-center">-</td>
                <td class="px-6 py-3 text-center">✔️</td>
                <td class="px-6 py-3 text-center">✔️</td>
              </tr>
              <tr class="border-t">
                <td class="px-6 py-3">Bulk Processing</td>
                <td class="px-6 py-3 text-center">-</td>
                <td class="px-6 py-3 text-center">-</td>
                <td class="px-6 py-3 text-center">✔️</td>
              </tr>
              <tr class="border-t">
                <td class="px-6 py-3">Custom Integrations</td>
                <td class="px-6 py-3 text-center">-</td>
                <td class="px-6 py-3 text-center">-</td>
                <td class="px-6 py-3 text-center">✔️</td>
              </tr>
            </tbody>
          </table>
        </div>
        <!-- Plan Recommendation -->
        <div class="mb-16">
          <h3 class="text-2xl font-bold text-gray-900 mb-4">Which plan is right for me?</h3>
          <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
            <div class="bg-white rounded-xl shadow p-6">
              <h4 class="font-semibold text-blue-600 mb-2">Free</h4>
              <p class="text-gray-600 text-sm">
                Perfect for new creators or those just getting started with shorts.
              </p>
            </div>
            <div class="bg-white rounded-xl shadow p-6">
              <h4 class="font-semibold text-purple-600 mb-2">Pro</h4>
              <p class="text-gray-600 text-sm">
                Best for active creators, marketers, and anyone who wants unlimited shorts and advanced features.
              </p>
            </div>
            <div class="bg-white rounded-xl shadow p-6">
              <h4 class="font-semibold text-green-600 mb-2">Enterprise</h4>
              <p class="text-gray-600 text-sm">
                For agencies, teams, or businesses needing bulk processing and custom solutions.
              </p>
            </div>
          </div>
        </div>
        <!-- FAQ -->
        <div class="mb-16">
          <h3 class="text-2xl font-bold text-gray-900 mb-4">Pricing & Billing FAQ</h3>
          <div class="space-y-6 text-left">
            <div class="bg-white rounded-xl shadow p-6">
              <h4 class="font-semibold text-gray-900 mb-2">Can I change my plan later?</h4>
              <p class="text-gray-600 text-sm">
                Yes, you can upgrade or downgrade your plan at any time from your account settings.
              </p>
            </div>
            <div class="bg-white rounded-xl shadow p-6">
              <h4 class="font-semibold text-gray-900 mb-2">What payment methods are accepted?</h4>
              <p class="text-gray-600 text-sm">
                We accept all major credit cards and PayPal for Pro and Enterprise plans.
              </p>
            </div>
            <div class="bg-white rounded-xl shadow p-6">
              <h4 class="font-semibold text-gray-900 mb-2">Is there a refund policy?</h4>
              <p class="text-gray-600 text-sm">
                Yes, we offer a 14-day money-back guarantee on all paid plans.
              </p>
            </div>
            <div class="bg-white rounded-xl shadow p-6">
              <h4 class="font-semibold text-gray-900 mb-2">
                Do you offer discounts for students or non-profits?
              </h4>
              <p class="text-gray-600 text-sm">
                Yes! Contact us for special pricing if you are a student or non-profit organization.
              </p>
            </div>
          </div>
        </div>
        <!-- Need Help CTA -->
        <div class="text-center mb-8">
          <h3 class="text-xl font-bold text-gray-900 mb-2">Still have questions?</h3>
          <p class="text-gray-600 mb-4">Our team is here to help you choose the right plan.</p>
          <.link
            href={~p"/contact"}
            class="px-6 py-3 bg-blue-600 text-white rounded-xl font-semibold shadow hover:bg-blue-700 transition"
          >
            Contact Support
          </.link>
        </div>
      </div>
    </div>
    <.footer />
    """
  end
end
