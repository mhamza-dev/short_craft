defmodule ShortCraftWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  At first glance, this module may seem daunting, but its goal is to provide
  core building blocks for your application, such as modals, tables, and
  forms. The components consist mostly of markup and are well-documented
  with doc strings and declarative assigns. You may customize and style
  them in any way you want, based on your application growth and needs.

  The default components use Tailwind CSS, a utility-first CSS framework.
  See the [Tailwind CSS documentation](https://tailwindcss.com) to learn
  how to customize them or feel free to swap in another framework altogether.

  Icons are provided by [heroicons](https://heroicons.com). See `icon/1` for usage.
  """
  use Phoenix.Component
  use Gettext, backend: ShortCraftWeb.Gettext

  import ShortCraftWeb.LiveHelpers

  alias Phoenix.LiveView.JS

  @doc """
  Renders a modal.

  ## Examples

      <.modal id="confirm-modal">
        This is a modal.
      </.modal>

  JS commands may be passed to the `:on_cancel` to configure
  the closing/cancel event, for example:

      <.modal id="confirm" on_cancel={JS.navigate(~p"/posts")}>
        This is another modal.
      </.modal>

  """
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, JS, default: %JS{}
  slot :inner_block, required: true

  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show_modal(@id)}
      phx-remove={hide_modal(@id)}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
      class="relative z-50 hidden"
    >
      <div id={"#{@id}-bg"} class="bg-zinc-50/90 fixed inset-0 transition-opacity" aria-hidden="true" />
      <div
        class="fixed inset-0 overflow-y-auto"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div class="flex min-h-full items-center justify-center">
          <div class="w-full max-w-3xl p-4 sm:p-6 lg:py-8">
            <.focus_wrap
              id={"#{@id}-container"}
              phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
              phx-key="escape"
              phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
              class="shadow-zinc-700/10 ring-zinc-700/10 relative hidden rounded-2xl bg-white p-14 shadow-lg ring-1 transition"
            >
              <div class="absolute top-6 right-5">
                <button
                  phx-click={JS.exec("data-cancel", to: "##{@id}")}
                  type="button"
                  class="-m-3 flex-none p-3 opacity-20 hover:opacity-40"
                  aria-label={gettext("close")}
                >
                  <.icon name="hero-x-mark-solid" class="h-5 w-5" />
                </button>
              </div>
              <div id={"#{@id}-content"}>
                {render_slot(@inner_block)}
              </div>
            </.focus_wrap>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class={[
        "fixed top-2 right-2 mr-2 w-80 sm:w-96 z-50 rounded-lg p-3 ring-1",
        @kind == :info && "bg-emerald-50 text-emerald-800 ring-emerald-500 fill-cyan-900",
        @kind == :error && "bg-rose-50 text-rose-900 shadow-md ring-rose-500 fill-rose-900"
      ]}
      {@rest}
    >
      <p :if={@title} class="flex items-center gap-1.5 text-sm font-semibold leading-6">
        <.icon :if={@kind == :info} name="hero-information-circle-mini" class="h-4 w-4" />
        <.icon :if={@kind == :error} name="hero-exclamation-circle-mini" class="h-4 w-4" />
        {@title}
      </p>
      <p class="mt-2 text-sm leading-5">{msg}</p>
      <button type="button" class="group absolute top-1 right-1 p-2" aria-label={gettext("close")}>
        <.icon name="hero-x-mark-solid" class="h-5 w-5 opacity-40 group-hover:opacity-70" />
      </button>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id}>
      <.flash kind={:info} title={gettext("Success!")} flash={@flash} />
      <.flash kind={:error} title={gettext("Error!")} flash={@flash} />
      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error")}
        phx-connected={hide("#client-error")}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error")}
        phx-connected={hide("#server-error")}
        hidden
      >
        {gettext("Hang in there while we get back on track")}
        <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Renders a simple form.

  ## Examples

      <.simple_form for={@form} phx-change="validate" phx-submit="save">
        <.input field={@form[:email]} label="Email"/>
        <.input field={@form[:username]} label="Username" />
        <:actions>
          <.button>Save</.button>
        </:actions>
      </.simple_form>
  """
  attr :for, :any, required: true, doc: "the data structure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target multipart),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  slot :inner_block, required: true
  slot :actions, doc: "the slot for form actions, such as a submit button"
  attr :actions_class, :string, default: ""
  slot :after_actions, doc: "the slot for after the actions"

  def simple_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <div class="space-y-2">
        {render_slot(@inner_block, f)}
        <div
          :for={action <- @actions}
          class={["flex items-center justify-between gap-4", @actions_class]}
        >
          {render_slot(action, f)}
        </div>
        <div class="flex flex-col items-center justify-center gap-4">
          {render_slot(@after_actions)}
        </div>
      </div>
    </.form>
    """
  end

  @doc """
  Renders a button with enhanced variants and modern styling.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" class="ml-2">Send!</.button>
      <.button variant="gradient">Gradient Button</.button>
      <.button variant="outline" size="lg">Large Outline</.button>
  """
  attr :type, :string, default: nil
  attr :class, :string, default: nil

  attr :variant, :string,
    default: "primary",
    values: ~w(primary secondary danger link gradient success warning info outline ghost)

  attr :size, :string, default: "md", values: ~w(sm md lg xl)
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={
        [
          "phx-submit-loading:opacity-75 font-semibold transition-all duration-200",
          "focus:outline-none focus:ring-2 focus:ring-offset-2",
          "disabled:opacity-50 disabled:cursor-not-allowed",
          # Size variants
          @size == "sm" && "px-3 py-1.5 text-xs rounded-md",
          @size == "md" && "px-4 py-2 text-sm rounded-lg",
          @size == "lg" && "px-6 py-3 text-base rounded-xl",
          @size == "xl" && "px-8 py-4 text-lg rounded-xl",
          # Color variants
          @variant == "primary" &&
            "text-white bg-blue-600 hover:bg-blue-700 focus:ring-blue-500 shadow-sm hover:shadow-md",
          @variant == "secondary" &&
            "text-gray-700 bg-gray-100 hover:bg-gray-200 focus:ring-gray-500",
          @variant == "danger" &&
            "text-white bg-red-600 hover:bg-red-700 focus:ring-red-500 shadow-sm hover:shadow-md",
          @variant == "link" && "p-0 text-blue-600 hover:text-blue-700 underline",
          @variant == "gradient" &&
            "text-white bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 focus:ring-blue-500 shadow-lg hover:shadow-xl transform hover:-translate-y-0.5",
          @variant == "success" &&
            "text-white bg-green-600 hover:bg-green-700 focus:ring-green-500 shadow-sm hover:shadow-md",
          @variant == "warning" &&
            "text-white bg-yellow-600 hover:bg-yellow-700 focus:ring-yellow-500 shadow-sm hover:shadow-md",
          @variant == "info" &&
            "text-white bg-cyan-600 hover:bg-cyan-700 focus:ring-cyan-500 shadow-sm hover:shadow-md",
          @variant == "outline" &&
            "text-blue-600 bg-transparent border-2 border-blue-600 hover:bg-blue-50 focus:ring-blue-500",
          @variant == "ghost" && "text-gray-700 bg-transparent hover:bg-gray-100 focus:ring-gray-500",
          @class
        ]
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  @doc """
  Renders an input with label and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Types

  This function accepts all HTML input types, considering that:

    * You may also set `type="select"` to render a `<select>` tag

    * `type="checkbox"` is used exclusively to render boolean values

    * For live file uploads, see `Phoenix.Component.live_file_input/1`

  See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  for more information. Unsupported types, such as hidden and radio,
  are best written directly in your templates.

  ## Examples

      <.input field={@form[:email]} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file month number password
               range search select tel text textarea time url week hidden)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div>
      <label class="flex items-center gap-4 text-sm leading-6 text-zinc-600">
        <input type="hidden" name={@name} value="false" disabled={@rest[:disabled]} />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          class={[
            "rounded border-zinc-300 text-zinc-900 focus:ring-0",
            @rest[:disabled] && "bg-zinc-100 text-zinc-500 cursor-not-allowed"
          ]}
          {@rest}
        />
        {@label}
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div>
      <.label for={@id}>{@label}</.label>
      <select
        id={@id}
        name={@name}
        class={[
          "mt-2 block w-full rounded-md border border-gray-300 bg-white shadow-sm focus:border-zinc-400 focus:ring-0 sm:text-sm",
          @rest[:disabled] && "bg-zinc-100 text-zinc-500 cursor-not-allowed"
        ]}
        multiple={@multiple}
        {@rest}
      >
        <option :if={@prompt} value="">{@prompt}</option>
        {Phoenix.HTML.Form.options_for_select(@options, @value)}
      </select>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div>
      <.label for={@id}>{@label}</.label>
      <textarea
        id={@id}
        name={@name}
        class={[
          "mt-2 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6 min-h-[6rem]",
          @errors == [] && "border-zinc-300 focus:border-zinc-400",
          @errors != [] && "border-rose-400 focus:border-rose-400",
          @rest[:disabled] && "bg-zinc-100 text-zinc-500 cursor-not-allowed"
        ]}
        {@rest}
      ><%= Phoenix.HTML.Form.normalize_value("textarea", @value) %></textarea>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    ~H"""
    <div>
      <.label for={@id}>{@label}</.label>
      <input
        type={@type}
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class={[
          "mt-2 block w-full rounded-lg px-4 py-3 text-gray-900 transition-all duration-200",
          "border-2 focus:outline-none focus:ring-2 focus:ring-offset-2 sm:text-sm",
          @errors == [] && "border-gray-300 focus:border-blue-500 focus:ring-blue-500/20",
          @errors != [] && "border-red-400 focus:border-red-500 focus:ring-red-500/20",
          @rest[:disabled] && "bg-gray-100 text-gray-500 cursor-not-allowed"
        ]}
        {@rest}
      />
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  @doc """
  Renders a label.
  """
  attr :for, :string, default: nil
  slot :inner_block, required: true

  def label(assigns) do
    ~H"""
    <label for={@for} class="block text-sm font-semibold leading-6 text-zinc-800">
      {render_slot(@inner_block)}
    </label>
    """
  end

  @doc """
  Generates a generic error message.
  """
  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <p class="mt-3 flex gap-3 text-sm leading-6 text-rose-600">
      <.icon name="hero-exclamation-circle-mini" class="mt-0.5 h-5 w-5 flex-none" />
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc """
  Renders a header with title.
  """
  attr :class, :string, default: nil

  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", @class]}>
      <div>
        <h1 class="text-2xl font-bold leading-8 text-gray-900">
          {render_slot(@inner_block)}
        </h1>
        <p :if={@subtitle != []} class="mt-2 text-base leading-6 text-gray-600">
          {render_slot(@subtitle)}
        </p>
      </div>
      <div class="flex-none">{render_slot(@actions)}</div>
    </header>
    """
  end

  @doc ~S"""
  Renders a table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id"><%= user.id %></:col>
        <:col :let={user} label="username"><%= user.username %></:col>
      </.table>

  ## Options
  - `scroll_class`: Optional. CSS class for horizontal scroll behavior. Defaults to `"overflow-x-auto"`.
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"
  attr :class, :string, default: nil

  attr :scroll_class, :string,
    default: "overflow-x-auto",
    doc: "CSS class for horizontal scroll behavior"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div class={["w-full max-w-full", @scroll_class, @class]}>
      <table class="w-full max-w-full table-auto">
        <thead class="text-sm text-left leading-6 text-zinc-500">
          <tr>
            <th class="p-0 pb-4 pr-6 font-normal">No.</th>
            <th :for={col <- @col} class="p-0 pb-4 pr-6 font-normal">{col[:label]}</th>
            <th :if={@action != []} class="relative p-0 pb-4">
              <span class="sr-only">{gettext("Actions")}</span>
            </th>
          </tr>
        </thead>
        <tbody
          id={@id}
          phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}
          class="relative divide-y divide-zinc-100 border-t border-zinc-200 text-sm leading-6 text-zinc-700"
        >
          <tr
            :for={{row, idx} <- Enum.with_index(@rows)}
            id={@row_id && @row_id.(row)}
            class="group hover:bg-zinc-50"
          >
            <td class="align-top" style="width: 1%; white-space: nowrap;">
              <div class="block py-4 pr-6">
                <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-zinc-50 sm:rounded-l-xl" />
                <span class={["relative", idx == 0 && "font-semibold text-zinc-900"]}>
                  {idx + 1}
                </span>
              </div>
            </td>
            <td
              :for={{col, i} <- Enum.with_index(@col)}
              phx-click={@row_click && @row_click.(row)}
              class={["relative p-0 align-top", @row_click && "hover:cursor-pointer"]}
              style={"width: #{100 / (Enum.count(@col) + 1)}%;"}
            >
              <div class="block py-4 pr-6">
                <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-zinc-50 sm:rounded-l-xl" />
                <span class={["relative", i == 0 && "font-semibold text-zinc-900"]}>
                  {render_slot(col, @row_item.(row))}
                </span>
              </div>
            </td>
            <td :if={@action != []} class="relative w-14 p-0 align-top">
              <div class="relative whitespace-nowrap py-4 text-right text-sm font-medium">
                <span class="absolute -inset-y-px -right-4 left-0 group-hover:bg-zinc-50 sm:rounded-r-xl" />
                <span
                  :for={action <- @action}
                  class="relative ml-4 font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
                >
                  {render_slot(action, @row_item.(row))}
                </span>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title"><%= @post.title %></:item>
        <:item title="Views"><%= @post.views %></:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <div class="mt-14">
      <dl class="-my-4 divide-y divide-zinc-100">
        <div :for={item <- @item} class="flex gap-4 py-4 text-sm leading-6 sm:gap-8">
          <dt class="w-1/4 flex-none text-zinc-500">{item.title}</dt>
          <dd class="text-zinc-700">{render_slot(item)}</dd>
        </div>
      </dl>
    </div>
    """
  end

  @doc """
  Renders a back navigation link.

  ## Examples

      <.back navigate={~p"/posts"}>Back to posts</.back>
  """
  attr :navigate, :any, required: true
  slot :inner_block, required: true

  def back(assigns) do
    ~H"""
    <div class="mt-16">
      <.link
        navigate={@navigate}
        class="text-sm font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
      >
        <.icon name="hero-arrow-left-solid" class="h-3 w-3" />
        {render_slot(@inner_block)}
      </.link>
    </div>
    """
  end

  @doc """
  Renders a [Heroicon](https://heroicons.com).

  Heroicons come in three styles – outline, solid, and mini.
  By default, the outline style is used, but solid and mini may
  be applied by using the `-solid` and `-mini` suffix.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  Icons are extracted from the `deps/heroicons` directory and bundled within
  your compiled app.css by the plugin in your `assets/tailwind.config.js`.

  ## Examples

      <.icon name="hero-x-mark-solid" />
      <.icon name="hero-arrow-path" class="ml-1 w-3 h-3 animate-spin" />
  """
  attr :name, :string, required: true
  attr :class, :string, default: nil

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  @doc """
  Renders a progress bar.

  ## Examples

      <.progress_bar progress={50} />
      <.progress_bar progress={75} variant="success" />
  """
  attr :progress, :integer, required: true
  attr :variant, :string, default: "primary", values: ~w(primary success warning danger)
  attr :size, :string, default: "md", values: ~w(sm md lg)
  attr :show_label, :boolean, default: false

  def progress_bar(assigns) do
    ~H"""
    <div class="flex items-center gap-2 w-full">
      <div class={[
        "flex-1 rounded-full transition-all duration-300 overflow-hidden shadow-sm",
        @size == "sm" && "h-1.5",
        @size == "md" && "h-2.5",
        @size == "lg" && "h-3",
        "bg-gray-100"
      ]}>
        <div
          class={[
            "rounded-full transition-all duration-500 ease-out h-full relative",
            @size == "sm" && "h-1.5",
            @size == "md" && "h-2.5",
            @size == "lg" && "h-3",
            @variant == "primary" && "bg-gradient-to-r from-indigo-500 via-purple-500 to-pink-500",
            @variant == "success" && "bg-gradient-to-r from-emerald-400 via-teal-500 to-cyan-500",
            @variant == "warning" && "bg-gradient-to-r from-orange-400 via-amber-500 to-yellow-500",
            @variant == "danger" && "bg-gradient-to-r from-rose-500 via-red-500 to-pink-500"
          ]}
          style={"width: #{@progress}%"}
        >
          <!-- Shimmer effect -->
          <div class="absolute inset-0 bg-gradient-to-r from-transparent via-white/30 to-transparent animate-pulse">
          </div>
        </div>
      </div>
      <div :if={@show_label} class="text-xs font-semibold text-gray-700 min-w-[2.5rem] text-right">
        {@progress}%
      </div>
    </div>
    """
  end

  @doc """
  Renders a Avatar.

  ## Examples

      <.avatar src={@user.avatar_url} />
  """
  attr :src, :string, required: true
  attr :class, :string, default: nil

  def avatar(assigns) do
    ~H"""
    <img src={@src} class={["rounded-full w-10 h-10", @class]} />
    """
  end

  @doc """
  Renders a Avatar with name.

  ## Examples

      <.avatar_with_name src={@user.avatar_url} name={@user.name} />
  """
  attr :src, :string, required: true
  attr :name, :string, required: true
  attr :class, :string, default: nil

  def avatar_with_name(assigns) do
    ~H"""
    <div class={["flex items-center gap-2", @class]}>
      <.avatar src={@src} />
      <span class="text-sm font-medium text-gray-900">{@name}</span>
    </div>
    """
  end

  @doc """
  Renders a status badge.

  ## Examples

      <.status_badge status="active" />
      <.status_badge status="pending" variant="warning" />
  """
  attr :status, :string, required: true
  attr :variant, :string, default: "default", values: ~w(default success warning danger info)
  attr :size, :string, default: "md", values: ~w(sm md lg)

  def status_badge(assigns) do
    ~H"""
    <span class={[
      "inline-flex items-center rounded-full font-medium",
      @size == "sm" && "px-2 py-0.5 text-xs",
      @size == "md" && "px-2.5 py-0.5 text-sm",
      @size == "lg" && "px-3 py-1 text-sm",
      @variant == "default" && "bg-gray-100 text-gray-800",
      @variant == "success" && "bg-green-100 text-green-800",
      @variant == "warning" && "bg-yellow-100 text-yellow-800",
      @variant == "danger" && "bg-red-100 text-red-800",
      @variant == "info" && "bg-blue-100 text-blue-800"
    ]}>
      {@status}
    </span>
    """
  end

  @doc """
  Renders a card container.

  ## Examples

      <.card>
        <h2>Card Title</h2>
        <p>Card content</p>
      </.card>
  """
  attr :class, :string, default: nil
  attr :padding, :string, default: "md", values: ~w(none sm md lg)

  slot :inner_block, required: true
  slot :header
  slot :footer

  def card(assigns) do
    ~H"""
    <div class={[
      "bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden",
      @padding == "none" && "",
      @padding == "sm" && "p-4",
      @padding == "md" && "p-6",
      @padding == "lg" && "p-8",
      @class
    ]}>
      <div :if={@header != []} class="border-b border-gray-100 pb-4 mb-4">
        {render_slot(@header)}
      </div>
      <div>
        {render_slot(@inner_block)}
      </div>
      <div :if={@footer != []} class="border-t border-gray-100 pt-4 mt-4">
        {render_slot(@footer)}
      </div>
    </div>
    """
  end

  @doc """
  Renders a page header with title and actions.

  ## Examples

      <.page_header title="Users">
        <:actions>
          <.button>Add User</.button>
        </:actions>
      </.page_header>
  """
  attr :title, :string, required: true
  attr :subtitle, :string, default: nil
  attr :class, :string, default: nil

  slot :actions

  def page_header(assigns) do
    ~H"""
    <div class={["mb-8", @class]}>
      <div class="flex items-center justify-between">
        <div>
          <h1 class="text-3xl font-bold text-gray-900">{@title}</h1>
          <p :if={@subtitle} class="mt-2 text-lg text-gray-600">{@subtitle}</p>
        </div>
        <div :if={@actions != []} class="flex items-center gap-3">
          {render_slot(@actions)}
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders a stats card.

  ## Examples

      <.stats_card title="Total Users" value="1,234" icon="hero-users" />
  """
  attr :title, :string, required: true
  attr :value, :string, required: true
  attr :icon, :string, default: nil
  attr :trend, :string, default: nil
  attr :trend_direction, :string, default: "up", values: ~w(up down)
  attr :class, :string, default: nil
  attr :variant, :string, default: "default", values: ~w(default success warning danger info)

  def stats_card(assigns) do
    ~H"""
    <div class={[
      "rounded-xl shadow-sm border p-6",
      get_stats_card_variant_classes(@variant),
      @class
    ]}>
      <div class="flex items-center">
        <div class="flex-1">
          <p class={[
            "text-sm font-medium",
            get_stats_card_title_color(@variant)
          ]}>
            {@title}
          </p>
          <p class={[
            "text-2xl font-bold mt-1",
            get_stats_card_value_color(@variant)
          ]}>
            {@value}
          </p>
          <div :if={@trend} class="flex items-center mt-2">
            <.icon
              name={
                if @trend_direction == "up",
                  do: "hero-arrow-trending-up",
                  else: "hero-arrow-trending-down"
              }
              class={
                [
                  "w-4 h-4 mr-1",
                  @trend_direction == "up" && "text-green-500",
                  @trend_direction == "down" && "text-red-500"
                ]
                |> Enum.join(" ")
              }
            />
            <span class={[
              "text-sm font-medium",
              @trend_direction == "up" && "text-green-600",
              @trend_direction == "down" && "text-red-600"
            ]}>
              {@trend}
            </span>
          </div>
        </div>
        <div :if={@icon} class="flex-shrink-0">
          <.icon
            name={@icon}
            class={
              [
                "w-8 h-8",
                get_stats_card_icon_color(@variant)
              ]
              |> Enum.join(" ")
            }
          />
        </div>
      </div>
    </div>
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      time: 300,
      transition:
        {"transition-all transform ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200",
         "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  def show_modal(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-bg",
      time: 300,
      transition: {"transition-all transform ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> show("##{id}-container")
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}-content")
  end

  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> hide("##{id}-container")
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.pop_focus()
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(ShortCraftWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(ShortCraftWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Renders a social login button.

  ## Examples

      <.social_link provider="google" href="/auth/google" />
      <.social_link provider="github" href="/auth/github" label="Sign in with GitHub" />
  """
  attr :provider, :string, required: true, values: ~w(google github facebook twitter linkedin)
  attr :href, :string, required: true
  attr :label, :string, default: nil
  attr :class, :string, default: nil
  attr :size, :string, default: "md", values: ~w(sm md lg)

  def social_link(assigns) do
    ~H"""
    <.link
      href={@href}
      class={[
        "flex flex-col items-center justify-center border border-gray-300 rounded-lg hover:bg-gray-50 transition-all duration-200",
        @size == "sm" && "p-2",
        @size == "md" && "p-3",
        @size == "lg" && "p-4",
        @class
      ]}
    >
      <i class={[
        "fa-brands fa-#{@provider} mb-1",
        @size == "sm" && "fa-sm",
        @size == "md" && "fa-lg",
        @size == "lg" && "fa-xl",
        get_social_icon_color(@provider)
      ]}>
      </i>
      <span class={[
        "text-gray-600",
        @size == "sm" && "text-xs",
        @size == "md" && "text-xs",
        @size == "lg" && "text-sm"
      ]}>
        {@label || String.capitalize(@provider)}
      </span>
    </.link>
    """
  end

  @doc """
  Renders the ShortCraft logo SVG.

  ## Examples

      <.logo class="w-8 h-8" />
      <.logo class="w-16 h-16" color="white" />
  """
  attr :class, :string, default: "w-6 h-6"
  attr :color, :string, default: "currentColor"

  def logo(assigns) do
    ~H"""
    <svg class={@class} fill="none" stroke={@color} viewBox="0 0 24 24">
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-width="2"
        d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z"
      >
      </path>
    </svg>
    """
  end

  @doc """
  Renders a grid of social login buttons.

  ## Examples

      <.social_links_grid>
        <.social_link provider="google" href="/auth/google" />
        <.social_link provider="github" href="/auth/github" />
        <.social_link provider="facebook" href="/auth/facebook" />
      </.social_links_grid>
  """
  attr :class, :string, default: nil
  attr :columns, :integer, default: 3

  slot :inner_block, required: true

  def social_links_grid(assigns) do
    ~H"""
    <div class={[
      "grid gap-3",
      @columns == 2 && "grid-cols-2",
      @columns == 3 && "grid-cols-3",
      @columns == 4 && "grid-cols-4",
      @class
    ]}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end

  @doc """
  Renders a dropdown menu for row actions.

  ## Example

    <.row_actions id={row.id}>
      <:item icon="hero-eye" label="View" navigate={~p"/source_videos/1/show"} />
      <:item icon="hero-pencil-square" label="Edit" navigate={~p"/source_videos/1/edit"} />
      <:item icon="hero-trash" label="Delete" phx_click="delete" phx_value_id="1" variant="danger" />
    </.row_actions>
  """
  attr :id, :any, required: true

  slot :item, required: true do
    attr :icon, :string, required: true
    attr :label, :string, required: true
    attr :navigate, :string
    attr :phx_click, :string
    attr :phx_value_id, :string
    attr :variant, :string
  end

  def row_actions(assigns) do
    ~H"""
    <div class="relative inline-block text-left" x-data="{ open: false }">
      <button
        type="button"
        @click="open = !open"
        class="p-2 rounded-full hover:bg-gray-100 focus:outline-none transition-colors"
      >
        <.icon name="hero-ellipsis-vertical" class="w-5 h-5" />
      </button>
      <div
        x-show="open"
        @click.away="open = false"
        x-transition
        class="absolute right-0 z-10 mt-2 w-40 origin-top-right rounded-md bg-white shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none"
        style="display: none;"
      >
        <div class="py-1">
          <%= for item <- @item do %>
            <%= if Map.get(item, :navigate) do %>
              <.link
                navigate={item.navigate}
                class={[
                  "flex items-center gap-2 px-4 py-2 text-sm hover:bg-gray-100",
                  Map.get(item, :variant) == "danger" && "text-red-600"
                ]}
              >
                <.icon name={item.icon} class="w-4 h-4" />
                <span>{item.label}</span>
              </.link>
            <% else %>
              <button
                type="button"
                phx-click={item.phx_click}
                phx-value-id={item.phx_value_id}
                @click="open = false"
                class={[
                  "flex w-full items-center gap-2 px-4 py-2 text-sm hover:bg-gray-100 text-left",
                  Map.get(item, :variant) == "danger" && "text-red-600"
                ]}
              >
                <.icon name={item.icon} class="w-4 h-4" />
                <span>{item.label}</span>
              </button>
            <% end %>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders a show more component.

  ## Examples

      <.show_more more_count={5}>
        <:less>
          <%= for i <- 1..3 do %>
            <span>Item <%= i %></span>
          <% end %>
        </:less>
        <:more>
          <%= for i <- 1..5 do %>
            <span>Item <%= i %></span>
          <% end %>
        </:more>
      </.show_more>
  """
  attr :id, :string, default: nil
  attr :more_count, :integer, default: nil
  attr :class, :string, default: nil

  slot :less, required: true
  slot :more, required: true

  def show_more(assigns) do
    assigns =
      assign_new(assigns, :more_label, fn -> "+#{assigns[:more_count] || "more"}" end)

    ~H"""
    <div phx-hook="ShowMore" id={@id} class={@class}>
      <span data-showmore-less>
        {render_slot(@less)}
      </span>
      <span data-showmore-more style="display: none;">
        {render_slot(@more)}
      </span>
      <button
        type="button"
        data-showmore-toggle
        data-more-label={@more_label}
        class="text-xs text-blue-600 font-medium ml-1 focus:outline-none"
      >
        {@more_label}
      </button>
    </div>
    """
  end
end
