defmodule ShortCraft.Services.ShortsGenerator do
  require Logger
  alias ShortCraft.{Repo, Shorts}
  alias ShortCraft.Shorts.SourceVideo

  @shorts_dir "priv/storage/shorts"

  def generate_shorts(source_video_id) do
    with %SourceVideo{} = source_video <- Repo.get(SourceVideo, source_video_id),
         {:ok, video_path} <- get_downloaded_video_path(source_video),
         :ok <- ensure_shorts_dir(),
         :ok <- update_status(source_video, :shorts_processing, 66) do
      short_duration = source_video.short_duration || 15
      total_duration = source_video.duration || get_video_duration(video_path)
      num_shorts = div(total_duration, short_duration)
      basename = Path.basename(video_path, Path.extname(video_path))

      Logger.info("Generating #{num_shorts} shorts of #{short_duration}s each for #{video_path}")

      0..(num_shorts - 1)
      |> Enum.map(fn i ->
        start_time = i * short_duration
        output_path = Path.join(@shorts_dir, "#{basename}_short_#{i + 1}.mp4")
        ffmpeg_split(video_path, output_path, start_time, short_duration)
      end)
      |> Enum.each(fn
        :ok -> :ok
        {:error, reason} -> Logger.error("Shorts generation error: #{inspect(reason)}")
      end)

      update_status(source_video, :waiting_review, 100)
      Logger.info("Shorts generation complete for #{source_video_id}")
      :ok
    else
      nil -> {:error, :not_found}
      {:error, reason} -> {:error, reason}
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
      output
    ]

    case System.cmd("ffmpeg", cmd, stderr_to_stdout: true) do
      {_output, 0} -> :ok
      {output, code} -> {:error, {code, output}}
    end
  end

  defp update_status(%SourceVideo{id: id}, status, progress) do
    Shorts.SourceVideo
    |> Repo.get(id)
    |> Shorts.SourceVideo.changeset(%{status: status, progress: progress})
    |> Repo.update()

    :ok
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
