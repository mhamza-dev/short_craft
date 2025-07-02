defmodule ShortCraft.Services.ShortsGenerator do
  require Logger
  alias ShortCraft.{Repo, Shorts}
  alias ShortCraft.Shorts.SourceVideo
  alias Phoenix.PubSub

  @shorts_dir "priv/storage/shorts"

  def generate_shorts(source_video_id), do: generate_shorts(source_video_id, true)

  def generate_shorts(source_video_id, true) do
    Task.start(fn -> generate_shorts(source_video_id, false) end)
    :ok
  end

  def generate_shorts(source_video_id, false) do
    try do
      with %SourceVideo{} = source_video <- Repo.get(SourceVideo, source_video_id),
           {:ok, video_path} <- get_downloaded_video_path(source_video),
           :ok <- ensure_shorts_dir(),
           :ok <- update_status(source_video, :shorts_processing, 66) do
        short_duration = source_video.short_duration || 15
        total_duration = source_video.duration || get_video_duration(video_path)
        num_shorts = div(total_duration, short_duration)
        basename = Path.basename(video_path, Path.extname(video_path))

        Logger.info(
          "Generating #{num_shorts} shorts of #{short_duration}s each for #{video_path}"
        )

        results =
          0..(num_shorts - 1)
          |> Enum.with_index()
          |> Enum.map(fn {i, index} ->
            start_time = i * short_duration
            output_path = Path.join(@shorts_dir, "#{basename}_short_#{i + 1}.mp4")

            # Update progress for each short being generated
            # Progress from 66% to 96%
            progress = 66 + div((index + 1) * 30, num_shorts)
            update_status(source_video, :shorts_processing, progress)

            result = ffmpeg_split(video_path, output_path, start_time, short_duration)

            case result do
              :ok ->
                Logger.info("Generated short #{index + 1}/#{num_shorts} for #{source_video_id}")
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
          update_status(source_video, :waiting_review, 100)
          Logger.info("Shorts generation complete for #{source_video_id}")
          :ok
        else
          Logger.error(
            "Shorts generation failed for #{source_video_id}: #{inspect(failed_shorts)}"
          )

          update_status(source_video, :failed, 0)
          {:error, :generation_failed}
        end
      else
        nil ->
          Logger.error("Source video not found: #{source_video_id}")
          {:error, :not_found}

        {:error, reason} ->
          Logger.error("Shorts generation failed for #{source_video_id}: #{inspect(reason)}")
          # Try to update status to failed if we have the source_video
          case Repo.get(SourceVideo, source_video_id) do
            %SourceVideo{} = sv -> update_status(sv, :failed, 0)
            nil -> :ok
          end

          {:error, reason}
      end
    rescue
      e ->
        Logger.error(
          "Unexpected error during shorts generation for #{source_video_id}: #{inspect(e)}"
        )

        # Try to update status to failed
        case Repo.get(SourceVideo, source_video_id) do
          %SourceVideo{} = sv -> update_status(sv, :failed, 0)
          nil -> :ok
        end

        {:error, :unexpected_error}
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
      "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:black",
      "-r",
      "30",
      output
    ]

    case System.cmd("ffmpeg", cmd, stderr_to_stdout: true) do
      {_output, 0} -> :ok
      {output, code} -> {:error, {code, output}}
    end
  end

  defp update_status(%SourceVideo{id: id}, status, progress) do
    case Shorts.SourceVideo
         |> Repo.get(id)
         |> Shorts.SourceVideo.changeset(%{status: status, progress: progress})
         |> Repo.update() do
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
end
