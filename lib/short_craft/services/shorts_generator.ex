defmodule ShortCraft.Services.ShortsGenerator do
  require Logger

  import ShortCraftWeb.LiveHelpers, only: [extract_video_id: 1]

  alias ShortCraft.{Repo, Shorts}
  alias ShortCraft.Shorts.SourceVideo
  alias Phoenix.PubSub
  alias Ecto.NoResultsError

  @shorts_dir "priv/storage/shorts"

  def generate_shorts(sv_id), do: generate_shorts(sv_id, true)

  def generate_shorts(sv_id, true) do
    try do
      with %SourceVideo{} = sv <- Shorts.get_source_video!(sv_id),
           {:ok, video_path} <- get_downloaded_video_path(sv),
           :ok <- ensure_shorts_dir(),
           :ok <- update_status(sv, :shorts_processing, 33),
           transcript when not is_nil(transcript) <- sv.transcript,
           {:ok, ai_content} <-
             ShortCraft.Services.GenerateAiContent.generate_for_video(
               transcript,
               sv.shorts_to_generate
             ) do
        Task.start(fn -> generate_shorts(sv, ai_content, video_path, false) end)
        :ok
      else
        nil ->
          Logger.error("Source video not found: #{sv_id}")
          update_status_when_failed(sv_id)
          {:error, :not_found}

        true ->
          Logger.error("Transcript not available for #{sv_id}")
          update_status_when_failed(sv_id)

          {:error, :transcript_not_available}

        {:error, reason} ->
          Logger.error("Shorts generation failed for #{sv_id}: #{inspect(reason)}")
          update_status_when_failed(sv_id)

          {:error, reason}
      end
    rescue
      e in NoResultsError ->
        Logger.error("Source video not found: #{sv_id} #{inspect(e)}")
        {:error, :not_found}

      e ->
        Logger.error("Unexpected error during shorts generation for #{sv_id}: #{inspect(e)}")

        # Try to update status to failed
        case Repo.get(SourceVideo, sv_id) do
          %SourceVideo{} = sv -> update_status(sv, :failed, 33)
          nil -> :ok
        end

        {:error, :unexpected_error}
    end
  end

  def generate_shorts(sv, ai_content, video_path, false) do
    short_duration = sv.short_duration || 15
    total_duration = sv.duration || get_video_duration(video_path)
    num_shorts = div(total_duration, short_duration)
    basename = Path.basename(video_path, Path.extname(video_path))

    Logger.info("Generating #{num_shorts} shorts of #{short_duration}s each for #{video_path}")

    results =
      0..(num_shorts - 1)
      |> Enum.zip(ai_content)
      |> Enum.with_index()
      |> Enum.map(fn {{i, ai_cont}, index} ->
        start_time = i * short_duration
        output_path = Path.join(@shorts_dir, "short_#{i + 1}_#{basename}.mp4")

        # Update progress for each short being generated
        # Progress from 33% to 65%
        progress = 33 + div((index + 1) * 32, num_shorts)
        update_status(sv, :shorts_processing, progress)

        case ffmpeg_split(video_path, output_path, start_time, short_duration) do
          :ok ->
            Logger.info("Generated short #{index + 1}/#{num_shorts} for #{sv.id}")
            Task.start(fn -> add_short_to_db(sv, ai_cont, output_path) end)
            :ok

          {:error, reason} ->
            Logger.error(
              "Failed to generate short #{index + 1}/#{num_shorts}: #{inspect(reason)}"
            )

            {:error, reason}
        end
      end)

    # Check if any shorts generation failed
    failed_shorts =
      Enum.filter(results, fn
        :ok -> false
        {:error, _} -> true
      end)

    if Enum.empty?(failed_shorts) do
      update_status(sv, :waiting_review, 65)
      Logger.info("Shorts generation complete for #{sv.id}")
      :ok
    else
      Logger.error("Shorts generation failed for #{sv.id}: #{inspect(failed_shorts)}")

      update_status(sv, :failed, 33)
      {:error, :generation_failed}
    end
  end

  defp get_downloaded_video_path(%SourceVideo{downloaded_file_path: downloaded_file_path}) do
    case downloaded_file_path do
      nil ->
        {:error, "No downloaded file path found"}

      path ->
        case File.exists?(path) do
          true -> {:ok, path}
          false -> {:error, "Downloaded file not found at #{path}"}
        end
    end
  end

  defp ensure_shorts_dir do
    File.mkdir_p(@shorts_dir)
    :ok
  end

  defp ffmpeg_split(input, output, start, duration) do
    cmd = [
      "-y",
      "-ss",
      "#{start}",
      "-i",
      input,
      "-t",
      "#{duration}",
      "-c:v",
      "libx264",
      "-c:a",
      "aac",
      "-strict",
      "-2",
      "-vf",
      # Crop to 9:16 (center) and scale to 1080x1920 for YouTube Shorts
      "crop=ih*9/16:ih:(iw-ih*9/16)/2:0,scale=1080:1920",
      "-r",
      "30",
      output
    ]

    case System.cmd("ffmpeg", cmd, stderr_to_stdout: true) do
      {_output, 0} -> :ok
      {output, code} -> {:error, {code, output}}
    end
  end

  defp update_status(sv, status, progress) do
    case Shorts.update_source_video(sv, %{status: status, progress: progress}) do
      {:ok, updated_video} ->
        # Broadcast the update to all subscribers
        PubSub.broadcast(
          ShortCraft.PubSub,
          "source_video_updates",
          {:source_video_updated, updated_video}
        )

        :ok

      {:error, changeset} ->
        Logger.error("Failed to update source video status: #{inspect(changeset.errors)}")
        {:error, :update_failed}
    end
  end

  defp get_video_duration(path) do
    # Use ffprobe to get duration in seconds
    case System.cmd("ffprobe", [
           "-v",
           "error",
           "-show_entries",
           "format=duration",
           "-of",
           "default=noprint_wrappers=1:nokey=1",
           path
         ]) do
      {duration_str, 0} ->
        duration_str |> String.trim() |> Float.parse() |> elem(0) |> round()

      _ ->
        0
    end
  end

  defp add_short_to_db(sv, ai_cont, output_path) do
    youtube_id = extract_video_id(sv.url)

    Shorts.create_generated_short(%{
      source_video_id: sv.id,
      user_id: sv.user_id,
      title: ai_cont["title"],
      description: ai_cont["description"],
      tags: ai_cont["tags"],
      output_path: output_path,
      status: "generated",
      youtube_id: youtube_id
    })
  end

  defp update_status_when_failed(sv_id) do
    case Repo.get(SourceVideo, sv_id) do
      %SourceVideo{} = sv -> update_status(sv, :failed, 33)
      nil -> :ok
    end
  end
end
