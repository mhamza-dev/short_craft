defmodule ShortCraft.Services.YoutubeDownloader do
  @moduledoc """
  Service module for downloading YouTube videos with real-time progress tracking.

  This module provides functionality to download YouTube videos either synchronously
  or asynchronously, with real-time progress updates broadcasted via Phoenix PubSub.

  ## Features

  - Synchronous and asynchronous download modes
  - Real-time progress tracking (percentage updates)
  - PubSub progress broadcasts to user-specific topics
  - Smart file path generation with user ID and timestamp
  - Download cancellation and monitoring
  - Automatic cleanup of old video files
  - Comprehensive error handling

  ## Usage

      # Subscribe to progress updates
      YoutubeDownloader.subscribe_to_progress(user_id)

      # Download synchronously
      {:ok, file_path} = YoutubeDownloader.download(url, user_id: user_id)

      # Download asynchronously
      {:ok, download_info} = YoutubeDownloader.download(url, user_id: user_id, async: true)

      # Monitor async download
      status = YoutubeDownloader.get_download_status(download_info)

      # Cancel async download
      YoutubeDownloader.cancel_download(download_info)

  """

  require Logger

  import ShortCraftWeb.LiveHelpers, only: [extract_video_id: 1]

  alias Phoenix.PubSub
  alias ShortCraft.Shorts

  @pubsub_topic_prefix "download_progress"

  @type download_opts :: [
          user_id: pos_integer() | nil,
          async: boolean(),
          output_path: String.t() | nil
        ]

  @type download_result :: {:ok, String.t()} | {:error, term()}

  @type async_download_info :: %{
          task: Task.t(),
          video_id: String.t(),
          output_path: String.t()
        }

  @type download_status :: :running | :downloaded | :failed

  @type progress_message :: %{
          video_id: String.t(),
          status: :started | :progress | :downloaded | :failed,
          timestamp: DateTime.t(),
          data: map()
        }

  @doc """
  Downloads a YouTube video with optional progress tracking.

  This is the main entry point for downloading videos. It supports both synchronous
  and asynchronous download modes, with real-time progress updates.

  ## Parameters

  - `url` - The YouTube video URL (supports various formats)
  - `opts` - Download options (see `t:download_opts/0`)

  ## Options

  - `:user_id` - User ID for progress tracking and file naming (optional)
  - `:async` - Whether to download asynchronously (default: false)
  - `:output_path` - Custom output path (default: auto-generated)
  - `:source_video_id` - Source video ID for status updates (optional)

  ## Returns

  - For sync downloads: `{:ok, file_path}` or `{:error, reason}`
  - For async downloads: `{:ok, download_info}` or `{:error, reason}`

  ## Examples

      # Synchronous download
      {:ok, file_path} = download("https://youtube.com/watch?v=VIDEO_ID")

      # Asynchronous download with progress tracking
      {:ok, download_info} = download(
        "https://youtube.com/watch?v=VIDEO_ID",
        user_id: 123,
        async: true,
        source_video_id: "video-id"
      )
  """
  @spec download(String.t(), download_opts()) ::
          download_result() | {:ok, async_download_info()}
  def download(url, opts \\ []) do
    user_id = Keyword.get(opts, :user_id)
    async = Keyword.get(opts, :async, false)
    source_video_id = Keyword.get(opts, :source_video_id)

    video_id = extract_video_id(url)
    output_path = generate_output_path(video_id, user_id, opts)

    # Ensure directory exists
    File.mkdir_p!(Path.dirname(output_path))

    if async do
      download_async(url, output_path, user_id, video_id, source_video_id)
    else
      download_sync(url, output_path, user_id, video_id, source_video_id)
    end
  end

  @doc false
  @spec download_sync(String.t(), String.t(), pos_integer() | nil, String.t(), String.t() | nil) ::
          download_result()
  defp download_sync(url, output_path, user_id, video_id, source_video_id) do
    # Update source video status to downloading
    update_source_video_status(source_video_id, :downloading)

    broadcast_status(user_id, video_id, :started, %{message: "Getting file info..."})

    # Get total file size for progress calculation
    total_size = get_file_size(url)

    broadcast_status(user_id, video_id, :started, %{
      message: "Starting download...",
      total_size: total_size
    })

    # Start sync download with progress monitoring
    progress_task =
      Task.async(fn ->
        monitor_sync_progress(output_path, user_id, video_id, total_size)
      end)

    ytdlp_path = System.get_env("YTDLP_PATH") || "yt-dlp"
    args = ["--output", output_path, url]

    case System.cmd(ytdlp_path, args) do
      {_output, 0} ->
        # Stop progress monitoring
        Task.shutdown(progress_task, :brutal_kill)

        case find_downloaded_file(output_path) do
          {:ok, actual_file_path, size} when size > 0 ->
            Logger.info("Download completed successfully (sync)",
              video_id: video_id,
              file_path: actual_file_path,
              file_size: size,
              source_video_id: source_video_id
            )

            # Update source video status to completed and progress to 33
            update_source_video_status_and_progress(
              source_video_id,
              :downloaded,
              33,
              actual_file_path
            )

            broadcast_status(user_id, video_id, :downloaded, %{
              file_path: actual_file_path,
              file_size: size,
              progress: 100,
              message: "Download completed successfully"
            })

            maybe_generate_transcript_async(source_video_id, video_id, url)

            {:ok, actual_file_path}

          {:error, reason} ->
            # Update source video status to failed
            update_source_video_status(source_video_id, :failed)

            broadcast_status(user_id, video_id, :failed, %{
              error: reason,
              message: "Downloaded file is empty or missing: #{reason}"
            })

            {:error, "Downloaded file is empty or missing: #{reason}"}
        end

      {error_output, _status_code} ->
        # Stop progress monitoring
        Task.shutdown(progress_task, :brutal_kill)

        # Update source video status to failed
        update_source_video_status(source_video_id, :failed)

        broadcast_status(user_id, video_id, :failed, %{
          error: "yt_dlp_error",
          message: "Download failed: #{error_output}"
        })

        {:error, "Download failed: #{error_output}"}
    end
  end

  @doc false
  @spec monitor_sync_progress(String.t(), pos_integer() | nil, String.t(), pos_integer() | nil) ::
          no_return()
  defp monitor_sync_progress(output_path, user_id, video_id, total_size) do
    monitor_sync_progress_loop(output_path, user_id, video_id, total_size, 0)
  end

  @doc false
  @spec monitor_sync_progress_loop(
          String.t(),
          pos_integer() | nil,
          String.t(),
          pos_integer() | nil,
          non_neg_integer()
        ) :: no_return()
  defp monitor_sync_progress_loop(output_path, user_id, video_id, total_size, last_progress) do
    current_progress = check_download_progress(output_path, total_size)

    # Only broadcast if progress changed significantly (at least 1%)
    if current_progress - last_progress >= 1 do
      broadcast_status(user_id, video_id, :progress, %{
        progress: current_progress,
        message: "Downloading... #{current_progress}%"
      })
    end

    # Sleep for a second and continue monitoring
    :timer.sleep(1000)
    monitor_sync_progress_loop(output_path, user_id, video_id, total_size, current_progress)
  end

  @doc false
  @spec download_async(String.t(), String.t(), pos_integer() | nil, String.t(), String.t() | nil) ::
          {:ok, async_download_info()} | {:error, term()}
  defp download_async(url, output_path, user_id, video_id, source_video_id) do
    # Start async download with progress monitoring
    task =
      Task.async(fn ->
        # Update source video status to downloading
        update_source_video_status(source_video_id, :downloading)

        broadcast_status(user_id, video_id, :started, %{message: "Getting file info..."})

        # Get total file size first
        total_size = get_file_size(url)

        broadcast_status(user_id, video_id, :started, %{
          message: "Starting download...",
          total_size: total_size
        })

        # Start the download
        ytdlp_path = System.get_env("YTDLP_PATH") || "yt-dlp"
        args = ["--output", output_path, url]

        # Start async download using Task
        {:ok, pid} =
          Task.start_link(fn ->
            {output, status_code} = System.cmd(ytdlp_path, args)

            case status_code do
              0 -> {:ok, output}
              _ -> {:error, output}
            end
          end)

        # Monitor progress while download is running
        monitor_progress(pid, output_path, user_id, video_id, total_size, source_video_id, url)
      end)

    # Return task reference for monitoring
    {:ok, %{task: task, video_id: video_id, output_path: output_path}}
  end

  @doc false
  @spec get_file_size(String.t()) :: pos_integer() | nil
  defp get_file_size(url) do
    ytdlp_path = System.get_env("YTDLP_PATH") || "yt-dlp"

    # Get file size using yt-dlp --print filesize
    case System.cmd(ytdlp_path, ["--print", "filesize", url]) do
      {filesize_str, 0} ->
        filesize_str
        |> String.trim()
        |> case do
          "" ->
            nil

          "NA" ->
            nil

          size_str ->
            case Integer.parse(size_str) do
              {size, _} -> size
              :error -> nil
            end
        end

      _ ->
        nil
    end
  end

  @doc false
  @spec monitor_progress(
          pid(),
          String.t(),
          pos_integer() | nil,
          String.t(),
          pos_integer() | nil,
          String.t() | nil,
          String.t() | nil
        ) :: download_result()
  defp monitor_progress(pid, output_path, user_id, video_id, total_size, source_video_id, url) do
    monitor_ref = Process.monitor(pid)

    result =
      monitor_download_loop(
        monitor_ref,
        output_path,
        user_id,
        video_id,
        total_size,
        0,
        source_video_id,
        url
      )

    # Clean up monitor
    Process.demonitor(monitor_ref, [:flush])

    result
  end

  @doc false
  @spec monitor_download_loop(
          reference(),
          String.t(),
          pos_integer() | nil,
          String.t(),
          pos_integer() | nil,
          non_neg_integer(),
          String.t() | nil,
          String.t() | nil
        ) :: download_result()
  defp monitor_download_loop(
         monitor_ref,
         output_path,
         user_id,
         video_id,
         total_size,
         last_progress,
         source_video_id,
         url
       ) do
    receive do
      {:DOWN, ^monitor_ref, :process, _pid, :normal} ->
        # Download completed successfully
        case find_downloaded_file(output_path) do
          {:ok, actual_file_path, size} when size > 0 ->
            Logger.info("Download completed successfully (async)",
              video_id: video_id,
              file_path: actual_file_path,
              file_size: size,
              source_video_id: source_video_id
            )

            # Update source video status to completed and progress to 33
            update_source_video_status_and_progress(
              source_video_id,
              :downloaded,
              33,
              actual_file_path
            )

            broadcast_status(user_id, video_id, :downloaded, %{
              file_path: actual_file_path,
              file_size: size,
              progress: 100,
              message: "Download completed successfully"
            })

            maybe_generate_transcript_async(source_video_id, video_id, url)

            {:ok, actual_file_path}

          {:error, reason} ->
            # Update source video status to failed
            update_source_video_status(source_video_id, :failed)

            broadcast_status(user_id, video_id, :failed, %{
              error: reason,
              message: "File verification failed: #{reason}"
            })

            {:error, reason}
        end

      {:DOWN, ^monitor_ref, :process, _pid, reason} ->
        # Download failed
        # Update source video status to failed
        update_source_video_status(source_video_id, :failed)

        broadcast_status(user_id, video_id, :failed, %{
          error: reason,
          message: "Download process failed: #{inspect(reason)}"
        })

        {:error, reason}
    after
      1000 ->
        # Check progress every second
        current_progress = check_download_progress(output_path, total_size)

        # Only broadcast if progress changed significantly (at least 1%)
        if current_progress - last_progress >= 1 do
          broadcast_status(user_id, video_id, :progress, %{
            progress: current_progress,
            message: "Downloading... #{current_progress}%"
          })
        end

        # Continue monitoring
        monitor_download_loop(
          monitor_ref,
          output_path,
          user_id,
          video_id,
          total_size,
          current_progress,
          source_video_id,
          url
        )
    end
  end

  @doc false
  @spec check_download_progress(String.t(), pos_integer() | nil) :: non_neg_integer()
  defp check_download_progress(_output_path, total_size) when is_nil(total_size), do: 0

  @doc false
  defp check_download_progress(output_path, total_size) when total_size > 0 do
    case find_downloaded_file(output_path) do
      {:ok, _file_path, current_size} ->
        progress = (current_size / total_size * 100) |> round()
        # Cap at 99% until actually complete
        min(progress, 99)

      _ ->
        0
    end
  end

  @doc false
  defp check_download_progress(_output_path, _total_size), do: 0

  @doc false
  @spec generate_output_path(String.t(), pos_integer() | nil, download_opts()) :: String.t()
  defp generate_output_path(video_id, user_id, opts) do
    case Keyword.get(opts, :output_path) do
      nil ->
        # Generate default path without extension (yt-dlp will add the correct one)
        storage_dir = "priv/storage/videos"
        File.mkdir_p!(storage_dir)

        timestamp = DateTime.utc_now() |> DateTime.to_unix()

        filename =
          if user_id do
            "#{video_id}_#{user_id}_#{timestamp}"
          else
            "#{video_id}_#{timestamp}"
          end

        Path.join(storage_dir, filename)

      custom_path ->
        custom_path
    end
  end

  @doc false
  @spec find_downloaded_file(String.t()) ::
          {:ok, String.t(), pos_integer()} | {:error, String.t()}
  def find_downloaded_file(base_path) do
    Logger.info("Searching for downloaded file", base_path: base_path)

    # Look for files with the base path and common video extensions
    extensions = [".mp4", ".webm", ".mkv", ".avi", ".mov", ".flv"]

    result =
      Enum.find_value(extensions, {:error, "No video file found"}, fn ext ->
        file_path = base_path <> ext

        case File.stat(file_path) do
          {:ok, %{size: size}} when size > 0 ->
            Logger.info("Found downloaded file", file_path: file_path, size: size)
            {:ok, file_path, size}

          _ ->
            nil
        end
      end)

    case result do
      {:error, reason} ->
        Logger.warning("No downloaded file found", base_path: base_path, reason: reason)
        result

      _ ->
        result
    end
  end

  @doc false
  @spec update_source_video_status(String.t() | nil, atom()) :: :ok
  defp update_source_video_status(nil, _status), do: :ok

  @doc false
  defp update_source_video_status(source_video_id, status) do
    case ShortCraft.Repo.get(Shorts.SourceVideo, source_video_id) do
      nil ->
        :ok

      source_video ->
        source_video
        |> Shorts.SourceVideo.changeset(%{status: status})
        |> ShortCraft.Repo.update()
        |> case do
          {:ok, _updated_video} -> :ok
          {:error, _changeset} -> :ok
        end
    end
  end

  @doc false
  @spec update_source_video_status_and_progress(
          String.t() | nil,
          atom(),
          integer(),
          String.t() | nil
        ) :: :ok
  defp update_source_video_status_and_progress(nil, _status, _progress, _downloaded_file_path),
    do: :ok

  defp update_source_video_status_and_progress(
         source_video_id,
         status,
         progress,
         downloaded_file_path
       ) do
    case ShortCraft.Repo.get(Shorts.SourceVideo, source_video_id) do
      %ShortCraft.Shorts.SourceVideo{} = source_video ->
        changeset =
          Shorts.SourceVideo.changeset(source_video, %{
            status: status,
            progress: progress,
            downloaded_file_path: downloaded_file_path
          })

        case ShortCraft.Repo.update(changeset) do
          {:ok, updated_source_video} ->
            Logger.info("Successfully updated source video with downloaded file path",
              source_video_id: source_video_id,
              status: status,
              progress: progress,
              downloaded_file_path: downloaded_file_path,
              updated_video: inspect(updated_source_video)
            )

            :ok

          {:error, changeset} ->
            require Logger

            Logger.error(
              "Failed to update status/progress for source_video_id #{source_video_id}: #{inspect(changeset.errors)}"
            )

            :ok
        end

      _ ->
        :ok
    end
  end

  @doc false
  @spec broadcast_status(pos_integer() | nil, String.t(), atom(), map()) :: :ok
  defp broadcast_status(nil, _video_id, _status, _data), do: :ok

  @doc false
  defp broadcast_status(user_id, video_id, status, data) do
    topic = "#{@pubsub_topic_prefix}:#{user_id}"

    message = %{
      video_id: video_id,
      status: status,
      timestamp: DateTime.utc_now(),
      data: data
    }

    PubSub.broadcast(ShortCraft.PubSub, topic, {:download_progress, message})
  end

  @doc """
  Subscribe to download progress updates for a specific user.

  Subscribes the current process to receive progress messages for downloads
  associated with the given user ID. Messages will be sent as:
  `{:download_progress, progress_message}`

  ## Parameters

  - `user_id` - The user ID to subscribe to

  ## Returns

  - `:ok` - Always returns :ok

  ## Examples

      YoutubeDownloader.subscribe_to_progress(123)

      # Now you can receive messages like:
      receive do
        {:download_progress, %{status: :progress, data: %{progress: 50}}} ->
          IO.puts("Download is 50% complete")
      end
  """
  @spec subscribe_to_progress(pos_integer()) :: :ok
  def subscribe_to_progress(user_id) do
    topic = "#{@pubsub_topic_prefix}:#{user_id}"
    PubSub.subscribe(ShortCraft.PubSub, topic)
  end

  @doc """
  Unsubscribe from download progress updates for a specific user.

  Stops the current process from receiving progress messages for downloads
  associated with the given user ID.

  ## Parameters

  - `user_id` - The user ID to unsubscribe from

  ## Returns

  - `:ok` - Always returns :ok

  ## Examples

      YoutubeDownloader.unsubscribe_from_progress(123)
  """
  @spec unsubscribe_from_progress(pos_integer()) :: :ok
  def unsubscribe_from_progress(user_id) do
    topic = "#{@pubsub_topic_prefix}:#{user_id}"
    PubSub.unsubscribe(ShortCraft.PubSub, topic)
  end

  @doc """
  Get download status for monitoring async downloads.

  Checks the current status of an asynchronous download without blocking.
  This is useful for polling the download status in a non-blocking manner.

  ## Parameters

  - `download_info` - The download info returned from async download

  ## Returns

  - `{:downloaded, result}` - Download completed successfully or with error
  - `{:failed, reason}` - Download task failed with given reason
  - `{:running, nil}` - Download is still in progress

  ## Examples

      {:ok, download_info} = YoutubeDownloader.download(url, async: true)

      case YoutubeDownloader.get_download_status(download_info) do
        {:downloaded, {:ok, file_path}} ->
          IO.puts("Downloaded to " <> file_path)
        {:failed, reason} ->
          IO.puts("Download failed: " <> inspect(reason))
        {:running, nil} ->
          IO.puts("Still downloading...")
      end
  """
  @spec get_download_status(async_download_info()) ::
          {:downloaded, download_result()} | {:failed, term()} | {:running, nil}
  def get_download_status(%{task: task}) do
    case Task.yield(task, 0) do
      {:ok, result} -> {:downloaded, result}
      {:exit, reason} -> {:failed, reason}
      nil -> {:running, nil}
    end
  end

  @doc """
  Cancel an async download.

  Forcefully terminates an asynchronous download and removes any partially
  downloaded file. This operation cannot be undone.

  ## Parameters

  - `download_info` - The download info returned from async download

  ## Returns

  - `{:ok, :cancelled}` - Download was successfully cancelled

  ## Examples

      {:ok, download_info} = YoutubeDownloader.download(url, async: true)

      # Later, cancel if needed
      {:ok, :cancelled} = YoutubeDownloader.cancel_download(download_info)
  """
  @spec cancel_download(async_download_info()) :: {:ok, :cancelled}
  def cancel_download(%{task: task, output_path: output_path}) do
    Task.shutdown(task, :brutal_kill)
    File.rm(output_path)
    {:ok, :cancelled}
  end

  @doc """
  Clean up old video files (older than specified days).

  Removes video files from the storage directory that are older than the
  specified number of days. This helps manage disk space by removing old
  downloaded videos.

  ## Parameters

  - `days_old` - Number of days old files should be to qualify for deletion (default: 7)

  ## Returns

  - `{:ok, count}` - Number of files successfully cleaned up
  - `{:error, reason}` - Error occurred during cleanup

  ## Examples

      # Clean up files older than 7 days (default)
      {:ok, 5} = YoutubeDownloader.cleanup_old_files()

      # Clean up files older than 30 days
      {:ok, 12} = YoutubeDownloader.cleanup_old_files(30)
  """
  @spec cleanup_old_files(pos_integer()) :: {:ok, non_neg_integer()} | {:error, term()}
  def cleanup_old_files(days_old \\ 7) do
    storage_dir = "priv/storage/videos"
    cutoff_time = DateTime.utc_now() |> DateTime.add(-days_old * 24 * 3600, :second)

    case File.ls(storage_dir) do
      {:ok, files} ->
        cleaned_count =
          files
          |> Enum.map(&Path.join(storage_dir, &1))
          |> Enum.filter(fn file_path ->
            case File.stat(file_path) do
              {:ok, %{mtime: mtime}} ->
                file_time = mtime |> NaiveDateTime.from_erl!() |> DateTime.from_naive!("Etc/UTC")
                DateTime.compare(file_time, cutoff_time) == :lt

              _ ->
                false
            end
          end)
          |> Enum.map(&File.rm/1)
          |> Enum.count(fn result -> result == :ok end)

        {:ok, cleaned_count}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp maybe_generate_transcript_async(source_video_id, video_id, url)
       when is_binary(source_video_id) and is_binary(video_id) and is_binary(url) do
    ytdlp_path = System.get_env("YTDLP_PATH") || "yt-dlp"

    Task.start(fn ->
      try do
        srt_file = "#{video_id}.en.srt"

        cmd = [
          "--write-auto-sub",
          "--sub-lang",
          "en",
          "--skip-download",
          "--convert-subs",
          "srt",
          "--output",
          "#{video_id}.%(ext)s",
          url
        ]

        case System.cmd(ytdlp_path, cmd, stderr_to_stdout: true) do
          {_output, 0} ->
            case File.read(srt_file) do
              {:ok, srt_content} ->
                transcript =
                  srt_content
                  |> String.split("\n\n")
                  |> Enum.map(fn block ->
                    block
                    |> String.split("\n")
                    |> Enum.drop(2)
                    |> Enum.join(" ")
                  end)
                  |> Enum.join(" ")
                  |> String.replace(~r/\s+/, " ")
                  |> String.trim()

                File.rm(srt_file)

                source_video = Shorts.get_source_video!(source_video_id)

                Shorts.update_source_video(source_video, %{
                  transcript: transcript
                })

              {:error, reason} ->
                Logger.error("Could not read SRT file for transcript: #{inspect(reason)}")
            end

          {output, code} ->
            Logger.error("yt-dlp failed for transcript (exit code #{code}): #{output}")
        end
      rescue
        e ->
          Logger.error("[Transcript] Unexpected error: #{inspect(e)}")
      end
    end)
  end
end
