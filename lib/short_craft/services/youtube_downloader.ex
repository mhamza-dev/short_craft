defmodule ShortCraft.Services.YoutubeDownloader do
  @moduledoc """
  Service module for downloading YouTube videos.
  """

  @user_agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36"

  def download(url, user_id) do
    {:ok, temp_file} = Briefly.create(extname: ".mp4")

    with {:ok, download_url} <- get_download_url(url),
         {:ok, file} <- File.open(temp_file, [:write]),
         {:ok, _} <- stream_download(download_url, file, user_id) do
      File.close(file)
      {:ok, temp_file}
    else
      error -> error
    end
  end

  defp get_download_url(url) do
    case HTTPoison.get(url, [{"User-Agent", @user_agent}]) do
      {:ok, %{body: body}} ->
        parse_video_url(body)

      error ->
        error
    end
  end

  defp parse_video_url(body) do
    # Simplified parsing logic - in production use a proper HTML parser
    regex = ~r/"url":"(https:\/\/[^"]+\.mp4[^"]*)"/

    case Regex.run(regex, body) do
      [_, url] -> {:ok, String.replace(url, "\\u0026", "&")}
      _ -> {:error, :parse_failed}
    end
  end

  defp stream_download(url, file, user_id) do
    stream =
      HTTPoison.get!(url, [{"User-Agent", @user_agent}],
        stream_to: self(),
        async: :once
      )

    stream_loop(stream, file, 0, 0, user_id)
  end

  defp stream_loop(ref, file, bytes_received, total_bytes, user_id) do
    receive do
      %HTTPoison.AsyncStatus{code: 200} ->
        HTTPoison.stream_next(ref)
        stream_loop(ref, file, bytes_received, total_bytes, user_id)

      %HTTPoison.AsyncHeaders{headers: headers} ->
        content_length =
          headers
          |> Enum.find(fn {k, _} -> String.downcase(k) == "content-length" end)
          |> case do
            {_, length} -> String.to_integer(length)
            _ -> 0
          end

        HTTPoison.stream_next(ref)
        stream_loop(ref, file, bytes_received, content_length, user_id)

      %HTTPoison.AsyncChunk{chunk: chunk} ->
        IO.binwrite(file, chunk)
        new_bytes = bytes_received + byte_size(chunk)

        # Broadcast progress
        if total_bytes > 0 do
          progress = min(100, round(new_bytes / total_bytes * 100))

          Phoenix.PubSub.broadcast(
            ShortCraft.PubSub,
            "user:#{user_id}",
            {:download_progress, progress}
          )
        end

        HTTPoison.stream_next(ref)
        stream_loop(ref, file, new_bytes, total_bytes, user_id)

      %HTTPoison.AsyncEnd{} ->
        {:ok, %{status_code: 200}}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    after
      300_000 -> {:error, :timeout}
    end
  end
end
