defmodule ShortCraftWeb.ShortsLive.Index do
  use ShortCraftWeb, :live_view

  alias ShortCraft.Shorts
  alias ShortCraft.Shorts.SourceVideo

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(ShortCraft.PubSub, "user:#{socket.assigns.current_user.id}")
    end

    source_videos =
      Shorts.list_source_videos(user_id: socket.assigns.current_user.id, preload: [:user])

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
  def handle_info({:new_source_video, source_video}, socket) do
    {:noreply, update(socket, :source_videos, &[&1 | source_video])}
  end
end
