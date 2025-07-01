defmodule ShortCraftWeb.ShortsLive.Show do
  use ShortCraftWeb, :live_view

  alias ShortCraft.Shorts

  def mount(%{"id" => id}, _session, socket) do
    source_video = Shorts.get_source_video!(id)
    {:ok, assign(socket, source_video: source_video)}
  end
end
