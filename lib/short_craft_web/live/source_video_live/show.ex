defmodule ShortCraftWeb.SourceVideoLive.Show do
  use ShortCraftWeb, :live_view

  alias ShortCraft.Shorts

  def mount(%{"id" => id}, _session, socket) do
    source_video = Shorts.get_source_video!(id)
    {:ok, assign(socket, source_video: source_video)}
  end

  def handle_event("back", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/source_videos")}
  end

  def handle_event("generate_shorts", %{"id" => id}, socket) do
    case ShortCraft.Services.ShortsGenerator.generate_shorts(id) do
      :ok ->
        source_video = Shorts.get_source_video!(id)
        {:noreply, assign(socket, source_video: source_video)}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to generate shorts: #{reason}")}
    end
  end
end
