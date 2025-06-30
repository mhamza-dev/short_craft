defmodule ShortCraft.ShortsTest do
  use ShortCraft.DataCase

  alias ShortCraft.Shorts

  describe "activities" do
    alias ShortCraft.Shorts.Activity

    import ShortCraft.ShortsFixtures

    @invalid_attrs %{action: nil, details: nil}

    test "list_activities/0 returns all activities" do
      activity = activity_fixture()
      assert Shorts.list_activities() == [activity]
    end

    test "get_activity!/1 returns the activity with given id" do
      activity = activity_fixture()
      assert Shorts.get_activity!(activity.id) == activity
    end

    test "create_activity/1 with valid data creates a activity" do
      valid_attrs = %{action: "some action", details: %{}}

      assert {:ok, %Activity{} = activity} = Shorts.create_activity(valid_attrs)
      assert activity.action == "some action"
      assert activity.details == %{}
    end

    test "create_activity/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Shorts.create_activity(@invalid_attrs)
    end

    test "update_activity/2 with valid data updates the activity" do
      activity = activity_fixture()
      update_attrs = %{action: "some updated action", details: %{}}

      assert {:ok, %Activity{} = activity} = Shorts.update_activity(activity, update_attrs)
      assert activity.action == "some updated action"
      assert activity.details == %{}
    end

    test "update_activity/2 with invalid data returns error changeset" do
      activity = activity_fixture()
      assert {:error, %Ecto.Changeset{}} = Shorts.update_activity(activity, @invalid_attrs)
      assert activity == Shorts.get_activity!(activity.id)
    end

    test "delete_activity/1 deletes the activity" do
      activity = activity_fixture()
      assert {:ok, %Activity{}} = Shorts.delete_activity(activity)
      assert_raise Ecto.NoResultsError, fn -> Shorts.get_activity!(activity.id) end
    end

    test "change_activity/1 returns a activity changeset" do
      activity = activity_fixture()
      assert %Ecto.Changeset{} = Shorts.change_activity(activity)
    end
  end

  describe "source_videos" do
    alias ShortCraft.Shorts.SourceVideo

    import ShortCraft.ShortsFixtures

    @invalid_attrs %{status: nil, title: nil, url: nil, duration: nil}

    test "list_source_videos/0 returns all source_videos" do
      source_video = source_video_fixture()
      assert Shorts.list_source_videos() == [source_video]
    end

    test "get_source_video!/1 returns the source_video with given id" do
      source_video = source_video_fixture()
      assert Shorts.get_source_video!(source_video.id) == source_video
    end

    test "create_source_video/1 with valid data creates a source_video" do
      valid_attrs = %{status: "some status", title: "some title", url: "some url", duration: 42}

      assert {:ok, %SourceVideo{} = source_video} = Shorts.create_source_video(valid_attrs)
      assert source_video.status == "some status"
      assert source_video.title == "some title"
      assert source_video.url == "some url"
      assert source_video.duration == 42
    end

    test "create_source_video/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Shorts.create_source_video(@invalid_attrs)
    end

    test "update_source_video/2 with valid data updates the source_video" do
      source_video = source_video_fixture()
      update_attrs = %{status: "some updated status", title: "some updated title", url: "some updated url", duration: 43}

      assert {:ok, %SourceVideo{} = source_video} = Shorts.update_source_video(source_video, update_attrs)
      assert source_video.status == "some updated status"
      assert source_video.title == "some updated title"
      assert source_video.url == "some updated url"
      assert source_video.duration == 43
    end

    test "update_source_video/2 with invalid data returns error changeset" do
      source_video = source_video_fixture()
      assert {:error, %Ecto.Changeset{}} = Shorts.update_source_video(source_video, @invalid_attrs)
      assert source_video == Shorts.get_source_video!(source_video.id)
    end

    test "delete_source_video/1 deletes the source_video" do
      source_video = source_video_fixture()
      assert {:ok, %SourceVideo{}} = Shorts.delete_source_video(source_video)
      assert_raise Ecto.NoResultsError, fn -> Shorts.get_source_video!(source_video.id) end
    end

    test "change_source_video/1 returns a source_video changeset" do
      source_video = source_video_fixture()
      assert %Ecto.Changeset{} = Shorts.change_source_video(source_video)
    end
  end
end
