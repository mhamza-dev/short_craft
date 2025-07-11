defmodule ShortCraftWeb.SourceVideoLive.Show do
  use ShortCraftWeb, :live_view

  require Logger

  alias ShortCraft.Shorts
  alias ShortCraft.Services.ShortsGenerator

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket), do: Phoenix.PubSub.subscribe(ShortCraft.PubSub, "source_video_updates")
    source_video = Shorts.get_source_video!(id) |> preload([:user, :generated_shorts])
    {:ok, assign(socket, source_video: source_video)}
  end

  @impl true
  def handle_event("back", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/source_videos")}
  end

  @impl true
  def handle_event("generate_shorts", %{"id" => id}, socket) do
    case ShortsGenerator.generate_shorts(id) do
      :ok ->
        {:noreply, put_flash(socket, :info, "Shorts generation started!")}

      {:error, reason} ->
        error_message =
          case reason do
            :transcript_not_available ->
              "Transcript not available yet. Please wait a moment and try again."

            {msg, _details} ->
              "Failed to generate shorts: #{msg}"

            reason when is_binary(reason) ->
              "Failed to generate shorts: #{reason}"

            _ ->
              "Failed to generate shorts: #{inspect(reason)}"
          end

        {:noreply, put_flash(socket, :error, error_message)}
    end
  end

  @impl true
  def handle_event("copy_transcript", %{"transcript" => transcript}, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "Transcript copied to clipboard!")
     |> push_event("copy-to-clipboard", %{text: transcript})}
  end

  @impl true
  def handle_event("upload_to_youtube", %{"short-id" => _short_id}, socket) do
    # TODO: Implement upload logic
    {:noreply, put_flash(socket, :info, "Upload to YouTube coming soon!")}
  end

  # Real-time update handler for this source video
  @impl true
  def handle_info({:source_video_updated, updated_video}, socket) do
    if updated_video.id == socket.assigns.source_video.id do
      Logger.info("Source video updated: #{inspect(updated_video.id)}")
      {:noreply, assign(socket, source_video: preload(updated_video, [:user, :generated_shorts]))}
    else
      {:noreply, socket}
    end
  end
end
