defmodule ShortCraftWeb.ShortsLive.Index do
  use ShortCraftWeb, :live_view

  alias ShortCraft.Shorts
  alias ShortCraft.Shorts.SourceVideo
  alias ShortCraft.Services.YoutubeDownloader

  @impl true
  def mount(_params, _session, socket) do
    source_videos =
      Shorts.list_source_videos(user_id: socket.assigns.current_user.id, preload: [:user])

    # Subscribe to download progress updates for this user
    YoutubeDownloader.subscribe_to_progress(socket.assigns.current_user.id)

    {:ok, assign(socket, source_videos: source_videos)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Source Video")
    |> assign(:source_video, %SourceVideo{})
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    source_video = Shorts.get_source_video!(id)

    socket
    |> assign(:page_title, "Edit Source Video")
    |> assign(:source_video, source_video)
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Source Videos")
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    source_video = Shorts.get_source_video!(id)

    case Shorts.delete_source_video(source_video) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Source video deleted successfully")
         |> update(
           :source_videos,
           &Enum.reject(&1, fn source_video -> source_video.id == id end)
         )}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Error deleting source video")}
    end
  end

  @impl true
  def handle_info(
        {ShortCraftWeb.ShortsLive.FormComponent, {:new_source_video, source_video}},
        socket
      ) do
    IO.puts("New source video received: #{inspect(source_video)}")

    # Start download in a separate task to avoid blocking
    Task.start(fn ->
      case YoutubeDownloader.download(source_video.url,
             user_id: source_video.user_id,
             async: true,
             source_video_id: source_video.id
           ) do
        {:ok, _download_info} ->
          IO.puts("Download started successfully for video: #{source_video.url}")
          :ok

        {:error, reason} ->
          IO.puts("Failed to start download: #{inspect(reason)}")
          :ok
      end
    end)

    {:noreply, update(socket, :source_videos, &[preload(source_video, [:user]) | &1])}
  end

  # Handle download progress updates from PubSub
  @impl true
  def handle_info({:download_progress, progress_message}, socket) do
    IO.puts("Download progress: #{inspect(progress_message)}")

    updated_socket =
      case progress_message.status do
        :started ->
          # Update source video status to downloading and show notification
          socket
          |> update_source_video_status_in_ui(progress_message.video_id, :downloading)
          |> put_flash(:info, "Download started for video: #{progress_message.video_id}")

        :progress ->
          # Update progress in the UI with real-time progress
          progress = progress_message.data.progress
          IO.puts("Progress: #{progress}")

          socket
          |> update_source_video_progress_in_ui(progress_message.video_id, progress)
          |> put_flash(:info, "Download progress: #{progress}%")

        :completed ->
          # Show completion notification and refresh the source videos list
          socket
          |> update_source_video_status_in_ui(progress_message.video_id, :completed)
          |> put_flash(:info, "Download completed successfully!")
          |> refresh_source_videos()

        :failed ->
          # Show error notification and update status
          error_msg = progress_message.data.message || "Download failed"

          socket
          |> update_source_video_status_in_ui(progress_message.video_id, :failed)
          |> put_flash(:error, "Download failed: #{error_msg}")
      end

    {:noreply, updated_socket}
  end

  # Handle task messages to prevent crashes
  @impl true
  def handle_info({ref, result}, socket) when is_reference(ref) do
    IO.puts("Received task result: #{inspect(result)}")
    {:noreply, socket}
  end

  # Catch-all for any other messages
  @impl true
  def handle_info(message, socket) do
    IO.puts("Unhandled message: #{inspect(message)}")
    {:noreply, socket}
  end

  # Helper function to refresh source videos list
  defp refresh_source_videos(socket) do
    source_videos =
      Shorts.list_source_videos(user_id: socket.assigns.current_user.id, preload: [:user])

    assign(socket, source_videos: source_videos)
  end

  # Helper function to update source video status in UI without refreshing from DB
  defp update_source_video_status_in_ui(socket, video_id, status) do
    update(socket, :source_videos, fn source_videos ->
      Enum.map(source_videos, fn source_video ->
        if extract_video_id_from_source_video(source_video) == video_id do
          %{source_video | status: status}
        else
          source_video
        end
      end)
    end)
  end

  # Helper function to update source video progress in UI
  defp update_source_video_progress_in_ui(socket, video_id, progress) do
    update(socket, :source_videos, fn source_videos ->
      Enum.map(source_videos, fn source_video ->
        if extract_video_id_from_source_video(source_video) == video_id do
          %{source_video | progress: progress}
        else
          source_video
        end
      end)
    end)
  end

  # Helper function to extract video ID from source video URL
  defp extract_video_id_from_source_video(source_video) do
    YoutubeDownloader.extract_video_id(source_video.url)
  end
end
