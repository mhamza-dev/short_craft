defmodule ShortCraftWeb.SourceVideoLive.FormComponent do
  use ShortCraftWeb, :live_component

  alias ShortCraft.Shorts
  alias ShortCraft.Shorts.SourceVideo

  def render(assigns) do
    ~H"""
    <div>
      <h1>{@page_title || "New Source Video"}</h1>
      <.simple_form
        for={@form}
        phx-submit={(@need_validation && "validate-url") || "save"}
        phx-change="validate"
        phx-target={@myself}
      >
        <.input field={@form[:url]} type="text" label="URL" />
        <.input
          field={@form[:short_duration]}
          type="select"
          label="Short Duration"
          options={[{"15 seconds", 15}, {"30 seconds", 30}, {"45 seconds", 45}, {"1 minute", 60}]}
          disabled={@need_validation}
        />
        <.error :if={@error}>{@error}</.error>
        <.input field={@form[:title]} type="text" label="Title" disabled />
        <.input field={@form[:channel_title]} type="text" label="Channel Title" disabled />
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
        <.input
          field={@form[:status]}
          type="select"
          label="Status"
          options={SourceVideo.statuses_as_list()}
          disabled
        />
        <.input
          field={@form[:auto_upload_shorts]}
          type="checkbox"
          label="Auto Upload Shorts"
          disabled={@need_validation}
        />
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
            class="text-white px-4 py-2 rounded-md w-full"
          >
            Validate URL
          </.button>
          <.button
            :if={!@need_validation}
            phx-disable-with="Proccesing..."
            class="text-white px-4 py-2 rounded-md w-full"
          >
            Proccess Video
          </.button>
        </:actions>
      </.simple_form>
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
    if socket.assigns.need_validation do
      {:noreply, socket}
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
         |> push_patch(to: ~p"/source_video")}

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
         |> push_patch(to: ~p"/source_video")}

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
