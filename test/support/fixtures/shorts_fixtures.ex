defmodule ShortCraft.ShortsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ShortCraft.Shorts` context.
  """

  @doc """
  Generate a activity.
  """
  def activity_fixture(attrs \\ %{}) do
    {:ok, activity} =
      attrs
      |> Enum.into(%{
        action: "some action",
        details: %{}
      })
      |> ShortCraft.Shorts.create_activity()

    activity
  end

  @doc """
  Generate a source_video.
  """
  def source_video_fixture(attrs \\ %{}) do
    {:ok, source_video} =
      attrs
      |> Enum.into(%{
        duration: 42,
        status: "some status",
        title: "some title",
        url: "some url"
      })
      |> ShortCraft.Shorts.create_source_video()

    source_video
  end
end
