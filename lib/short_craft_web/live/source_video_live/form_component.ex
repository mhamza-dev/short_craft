defmodule ShortCraftWeb.SourceVideoLive.FormComponent do
  use ShortCraftWeb, :live_component

  alias ShortCraft.Shorts
  alias ShortCraft.Shorts.SourceVideo

  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto">
      <.page_header
        title={@page_title || "New Source Video"}
        subtitle="Add a new YouTube video for shorts generation"
      />

      <.card>
        <.simple_form
          for={@form}
          phx-submit={(@need_validation && "validate-url") || "save"}
          phx-change="validate"
          phx-target={@myself}
        >
          <div class="space-y-6">
            <!-- URL Input -->
            <div class="bg-blue-50 border border-blue-200 rounded-lg p-4">
              <div class="flex items-center gap-2 mb-2">
                <.icon name="hero-link" class="w-5 h-5 text-blue-600" />
                <h3 class="text-sm font-semibold text-blue-900">Video URL</h3>
              </div>
              <.input
                field={@form[:url]}
                type="text"
                label="YouTube URL"
                placeholder="https://www.youtube.com/watch?v=..."
              />
            </div>
            
    <!-- Short Duration Selection -->
            <div class="bg-gray-50 border border-gray-200 rounded-lg p-4">
              <div class="flex items-center gap-2 mb-2">
                <.icon name="hero-clock" class="w-5 h-5 text-gray-600" />
                <h3 class="text-sm font-semibold text-gray-900">Short Duration</h3>
              </div>
              <.input
                field={@form[:short_duration]}
                type="select"
                label="Duration per short"
                options={[
                  {"15 seconds", 15},
                  {"30 seconds", 30},
                  {"45 seconds", 45},
                  {"1 minute", 60}
                ]}
                disabled={@need_validation}
              />
            </div>
            
    <!-- Error Display -->
            <div :if={@error} class="bg-red-50 border border-red-200 rounded-lg p-4">
              <div class="flex items-center gap-2">
                <.icon name="hero-exclamation-triangle" class="w-5 h-5 text-red-600" />
                <span class="text-sm font-medium text-red-800">{@error}</span>
              </div>
            </div>
            
    <!-- Video Details (Read-only) -->
            <div :if={!@need_validation} class="bg-green-50 border border-green-200 rounded-lg p-4">
              <div class="flex items-center gap-2 mb-4">
                <.icon name="hero-check-circle" class="w-5 h-5 text-green-600" />
                <h3 class="text-sm font-semibold text-green-900">Video Details</h3>
              </div>

              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <.input field={@form[:title]} type="text" label="Title" disabled />
                <.input field={@form[:channel_title]} type="text" label="Channel" disabled />
                <.input field={@form[:duration]} type="text" label="Duration" disabled />
                <.input
                  field={@form[:shorts_to_generate]}
                  type="text"
                  label="Shorts to Generate"
                  value={
                    Integer.floor_div(
                      to_integer(@form[:duration].value),
                      to_integer(@form[:short_duration].value, 15)
                    )
                  }
                  disabled
                />
              </div>
            </div>
            
    <!-- Settings -->
            <div class="bg-purple-50 border border-purple-200 rounded-lg p-4">
              <div class="flex items-center gap-2 mb-2">
                <.icon name="hero-cog-6-tooth" class="w-5 h-5 text-purple-600" />
                <h3 class="text-sm font-semibold text-purple-900">Settings</h3>
              </div>

              <.input
                field={@form[:auto_upload_shorts]}
                type="checkbox"
                label="Auto Upload Shorts"
                disabled={@need_validation}
              />
            </div>
          </div>
          
    <!-- Hidden Fields -->
          <.input field={@form[:title]} type="hidden" />
          <.input field={@form[:channel_title]} type="hidden" />
          <.input field={@form[:duration]} type="hidden" />
          <.input field={@form[:thumbnail]} type="hidden" />
          <.input
            field={@form[:shorts_to_generate]}
            type="hidden"
            value={
              Integer.floor_div(
                to_integer(@form[:duration].value),
                to_integer(@form[:short_duration].value, 15)
              )
            }
          />
          <.input field={@form[:user_id]} value={@current_user.id} type="hidden" />

          <:actions>
            <.button
              :if={@need_validation}
              phx-disable-with="Validating..."
              class="w-full bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white font-medium py-3 px-6 rounded-lg transition-all duration-200 shadow-sm hover:shadow-md"
            >
              <.icon name="hero-magnifying-glass" class="w-4 h-4 mr-2" /> Validate URL
            </.button>
            <.button
              :if={!@need_validation}
              phx-disable-with="Processing..."
              class="w-full bg-gradient-to-r from-green-600 to-emerald-600 hover:from-green-700 hover:to-emerald-700 text-white font-medium py-3 px-6 rounded-lg transition-all duration-200 shadow-sm hover:shadow-md"
            >
              <.icon name="hero-play" class="w-4 h-4 mr-2" /> Process Video
            </.button>
          </:actions>
        </.simple_form>
      </.card>
    </div>
    """
  end

  def update(%{source_video: source_video} = assigns, socket) do
    changeset = SourceVideo.changeset(source_video, %{})

    {:ok,
     socket
     |> assign(assigns)
     |> assign(need_validation: true, error: nil)
     |> assign_form(changeset)}
  end

  def handle_event("validate", %{"source_video" => params}, socket) do
    dbg(is_nil(Ecto.Changeset.get_field(socket.assigns.form.source, :url)))

    if socket.assigns.need_validation do
      if is_nil(Ecto.Changeset.get_field(socket.assigns.form.source, :url)) do
        {:noreply, assign(socket, need_validation: true)}
      else
        {:noreply, socket}
      end
    else
      changeset =
        socket.assigns.source_video
        |> SourceVideo.changeset(params)
        |> Map.put(:action, :validate)

      {:noreply, socket |> assign_form(changeset)}
    end
  end

  def handle_event("validate-url", %{"source_video" => %{"url" => url}}, socket) do
    case ShortCraft.Services.Youtube.get_video_details(url) do
      {:ok, video_details} ->
        params = %{
          url: url,
          title: video_details.title,
          duration: video_details.duration,
          thumbnail: video_details.thumbnail,
          channel_title: video_details.channel_title
        }

        changeset =
          socket.assigns.source_video
          |> SourceVideo.changeset(params)
          |> Map.put(:action, :validate)

        {:noreply,
         socket
         |> assign(error: nil, need_validation: false)
         |> assign_form(changeset)}

      {:error, error} ->
        changeset =
          socket.assigns.source_video
          |> SourceVideo.changeset(%{url: url})
          |> Map.put(:action, :validate)

        {:noreply,
         socket
         |> assign(error: error, need_validation: true)
         |> assign_form(changeset)}
    end
  end

  def handle_event("save", %{"source_video" => params}, socket) do
    save_source_video(socket, socket.assigns.action, params)
  end

  defp save_source_video(socket, :edit, params) do
    case Shorts.update_source_video(socket.assigns.source_video, params) do
      {:ok, source_video} ->
        notify_parent({:updated_source_video, source_video})

        {:noreply,
         socket
         |> put_flash(:info, "Source video updated successfully")
         |> push_patch(to: ~p"/source_videos")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_source_video(socket, :new, params) do
    case Shorts.create_source_video(params) do
      {:ok, source_video} ->
        notify_parent({:new_source_video, source_video})

        {:noreply,
         socket
         |> put_flash(:info, "Source video created successfully")
         |> push_patch(to: ~p"/source_videos")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, changeset) do
    assign(socket, form: to_form(changeset, as: :source_video))
  end

  defp notify_parent(message) do
    send(self(), {__MODULE__, message})
  end
end
