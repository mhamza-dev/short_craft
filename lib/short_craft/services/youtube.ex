defmodule ShortCraft.Services.Youtube do
  @api_url "https://www.googleapis.com/youtube/v3/videos"

  def get_video_details(url) do
    case extract_video_id(url) do
      {:ok, video_id} ->
        api_key = Application.get_env(:short_craft, :youtube_api_key)

        case HTTPoison.get(@api_url, [],
               params: %{
                 id: video_id,
                 part: "snippet,contentDetails",
                 key: api_key
               }
             ) do
          {:ok, %{status_code: 200, body: body}} ->
            parse_video_details(body)

          {:ok, response} ->
            {:error, "YouTube API error: #{response.status_code}"}

          {:error, reason} ->
            {:error, reason}
        end

      error ->
        error
    end
  end

  def fetch_youtube_channels(access_token) do
    # First try to get channels where user is the owner
    url = "https://www.googleapis.com/youtube/v3/channels?part=snippet&mine=true"
    headers = [{"Authorization", "Bearer #{access_token}"}]

    case HTTPoison.get(url, headers) do
      {:ok, %{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"items" => items}} when items != [] ->
            {:ok, items}

          _ ->
            # If no owned channels, try to get channels where user has access
            fetch_accessible_channels(access_token)
        end

      _ ->
        {:error, :fetch_failed}
    end
  end

  defp fetch_accessible_channels(access_token) do
    # Try to get channels where user has access (not just ownership)
    url = "https://www.googleapis.com/youtube/v3/channels?part=snippet&managedByMe=true"
    headers = [{"Authorization", "Bearer #{access_token}"}]

    case HTTPoison.get(url, headers) do
      {:ok, %{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"items" => items}} -> {:ok, items}
          _ -> {:error, :no_channels}
        end

      _ ->
        {:error, :fetch_failed}
    end
  end

  defp extract_video_id(url) do
    # Improved regex to support both youtube.com and youtu.be URLs
    regex =
      ~r/(?:v=|\/v\/|youtu\.be\/|embed\/|\/shorts\/|\/watch\?v=|youtube\.com\/watch\?v=)([\w-]{11})/

    case Regex.run(regex, url) do
      [_, video_id] -> {:ok, video_id}
      _ -> {:error, "Invalid YouTube URL"}
    end
  end

  defp parse_video_details(body) do
    data = Jason.decode!(body)

    case data["items"] do
      [item | _] ->
        snippet = item["snippet"]
        duration_iso = item["contentDetails"]["duration"]

        duration = youtube_duration_to_seconds(duration_iso)

        {:ok,
         %{
           id: item["id"],
           title: snippet["title"],
           duration: duration,
           thumbnail: snippet["thumbnails"]["high"]["url"],
           channel_title: snippet["channelTitle"]
         }}

      [] ->
        {:error, "Video not found"}
    end
  end

  defp youtube_duration_to_seconds(duration) do
    regex = ~r/PT((?<h>\d+)H)?((?<m>\d+)M)?((?<s>\d+)S)?/
    captures = Regex.named_captures(regex, duration) || %{}
    h = if captures["h"] in [nil, ""], do: "0", else: captures["h"]
    m = if captures["m"] in [nil, ""], do: "0", else: captures["m"]
    s = if captures["s"] in [nil, ""], do: "0", else: captures["s"]

    String.to_integer(h) * 3600 +
      String.to_integer(m) * 60 +
      String.to_integer(s)
  end
end
