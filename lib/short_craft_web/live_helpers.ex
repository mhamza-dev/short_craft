defmodule ShortCraftWeb.LiveHelpers do
  alias ShortCraft.Repo

  @doc """
  Preloads the given fields for the given model.

  This is a convenience function that wraps `Repo.preload/2` to make it
  easier to preload associations in LiveView templates.

  ## Examples

      iex> preload(user, [:posts, :comments])
      %User{posts: [...], comments: [...]}
  """
  @spec preload(Ecto.Schema.t(), [atom()]) :: Ecto.Schema.t()
  def preload(model, fields) do
    Repo.preload(model, fields)
  end

  @doc """
  Formats the given datetime to a human readable string.

  Converts a DateTime to a formatted string using the specified format.
  Returns "-" for nil values.

  ## Parameters

  - `datetime` - The DateTime to format, or nil
  - `format` - Optional format string (default: "%A %B %d, %Y at %H:%M %p")

  ## Examples

      iex> format_datetime(~U[2023-12-25 14:30:00Z])
      "Monday December 25, 2023 at 02:30 PM"
      iex> format_datetime(~U[2023-12-25 14:30:00Z], "%Y-%m-%d")
      "2023-12-25"
      iex> format_datetime(nil)
      "-"
  """
  @spec format_datetime(DateTime.t() | nil, String.t()) :: String.t()
  def format_datetime(datetime, format \\ "%A %B %d, %Y at %H:%M %p"),
    do: datetime(datetime, format)

  defp datetime(nil, _format), do: "-"
  defp datetime(datetime, format), do: Timex.format!(datetime, format, :strftime)

  @doc """
  Formats duration in seconds to a human readable time string.

  Converts seconds to MM:SS format for durations under 1 hour,
  and HH:MM:SS format for durations of 1 hour or more.
  Returns "-" for nil values.

  ## Examples

      iex> format_duration(125)
      "02:05"
      iex> format_duration(3661)
      "01:01:01"
      iex> format_duration(nil)
      "-"
  """
  @spec format_duration(integer() | nil) :: String.t()
  def format_duration(nil), do: "-"

  def format_duration(seconds) when is_integer(seconds) and seconds < 3600 do
    :io_lib.format("~2..0B:~2..0B", [div(seconds, 60), rem(seconds, 60)]) |> List.to_string()
  end

  def format_duration(seconds) when is_integer(seconds) do
    :io_lib.format("~2..0B:~2..0B:~2..0B", [
      div(seconds, 3600),
      rem(div(seconds, 60), 60),
      rem(seconds, 60)
    ])
    |> List.to_string()
  end

  @doc """
  Converts a status atom to a human-readable string.

  ## Examples

      iex> humanize_status(:not_started)
      "Not started"
      iex> humanize_status(:downloading)
      "Downloading"
      iex> humanize_status(true)
      "Yes"
      iex> humanize_status(false)
      "No"
      iex> humanize_status(nil)
      "Unknown"
  """
  @spec humanize_status(atom() | boolean() | nil) :: String.t()
  def humanize_status(nil), do: "Unknown"

  def humanize_status(true), do: "Yes"
  def humanize_status(false), do: "No"

  def humanize_status(status) do
    status
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  @doc """
  Returns CSS classes for styling status badges.

  Returns a string of Tailwind CSS classes that provide consistent styling
  for status badges with appropriate colors based on the status.

  ## Examples

      iex> status_badge_class(:downloaded)
      "px-2 py-1 rounded text-xs font-semibold bg-cyan-100 text-cyan-800"
      iex> status_badge_class(:downloading)
      "px-2 py-1 rounded text-xs font-semibold bg-yellow-100 text-yellow-800"
      iex> status_badge_class(:failed)
      "px-2 py-1 rounded text-xs font-semibold bg-red-100 text-red-800"
  """
  @spec status_badge_class(atom() | boolean()) :: String.t()
  def status_badge_class(status) do
    "px-2 py-1 rounded text-xs font-semibold #{colors_by_status(status)}"
  end

  @doc """
  Returns the number of shorts to generate based on the duration and short duration.

  ## Examples

      iex> to_integer("10")
      10
      iex> to_integer("10.5")
      10
      iex> to_integer(nil)
      0
  """
  @spec to_integer(String.t() | integer() | nil, integer()) :: integer()
  def to_integer(v, default \\ 0), do: to_int(v, default)

  @doc false
  defp to_int(nil, default), do: default
  defp to_int("", default), do: default
  defp to_int(val, _default) when is_integer(val), do: val
  defp to_int(val, _default) when is_binary(val), do: String.to_integer(val)

  @doc false
  @spec colors_by_status(atom() | boolean()) :: String.t()
  defp colors_by_status(:not_started), do: "bg-gray-100 text-gray-800"
  defp colors_by_status(:queued), do: "bg-blue-100 text-blue-800"
  defp colors_by_status(:downloading), do: "bg-yellow-100 text-yellow-800"
  defp colors_by_status(:downloaded), do: "bg-cyan-100 text-cyan-800"
  defp colors_by_status(:shorts_processing), do: "bg-orange-100 text-orange-800"
  defp colors_by_status(:waiting_review), do: "bg-purple-100 text-purple-800"
  defp colors_by_status(:cancelled), do: "bg-gray-300 text-gray-900"
  defp colors_by_status(:connected), do: "bg-green-100 text-green-800"

  defp colors_by_status(status) when status in [:shorts_published, true],
    do: "bg-green-100 text-green-800"

  defp colors_by_status(status) when status in [:failed, false],
    do: "bg-red-100 text-red-800"

  defp colors_by_status(_), do: "bg-gray-100 text-gray-800"

  # Helper function to get status badge variant
  def get_status_variant(status) do
    case status do
      :not_started -> "default"
      :queued -> "info"
      :downloading -> "warning"
      :downloaded -> "success"
      :shorts_processing -> "warning"
      :waiting_review -> "info"
      :shorts_publishing -> "warning"
      :shorts_published -> "success"
      :connected -> "success"
      :failed -> "danger"
      :cancelled -> "default"
      :source_deleted -> "danger"
      _ -> "default"
    end
  end

  # Helper function to get progress bar variant
  def get_progress_variant(progress) do
    cond do
      progress >= 100 -> "success"
      progress >= 66 -> "primary"
      progress >= 33 -> "warning"
      progress > 0 -> "primary"
      true -> "default"
    end
  end

  # Helper function to get social icon colors
  def get_social_icon_color("google"), do: "text-red-500"
  def get_social_icon_color("github"), do: "text-gray-800"
  def get_social_icon_color("facebook"), do: "text-blue-600"
  def get_social_icon_color("twitter"), do: "text-blue-400"
  def get_social_icon_color("linkedin"), do: "text-blue-700"
  def get_social_icon_color(_), do: "text-gray-600"

  # Helper functions for stats card variants
  def get_stats_card_variant_classes("default"), do: "bg-white border-gray-200"
  def get_stats_card_variant_classes("success"), do: "bg-green-50 border-green-200"
  def get_stats_card_variant_classes("warning"), do: "bg-yellow-50 border-yellow-200"
  def get_stats_card_variant_classes("danger"), do: "bg-red-50 border-red-200"
  def get_stats_card_variant_classes("info"), do: "bg-blue-50 border-blue-200"

  def get_stats_card_title_color("default"), do: "text-gray-600"
  def get_stats_card_title_color("success"), do: "text-green-700"
  def get_stats_card_title_color("warning"), do: "text-yellow-700"
  def get_stats_card_title_color("danger"), do: "text-red-700"
  def get_stats_card_title_color("info"), do: "text-blue-700"

  def get_stats_card_value_color("default"), do: "text-gray-900"
  def get_stats_card_value_color("success"), do: "text-green-900"
  def get_stats_card_value_color("warning"), do: "text-yellow-900"
  def get_stats_card_value_color("danger"), do: "text-red-900"
  def get_stats_card_value_color("info"), do: "text-blue-900"

  def get_stats_card_icon_color("default"), do: "text-gray-400"
  def get_stats_card_icon_color("success"), do: "text-green-500"
  def get_stats_card_icon_color("warning"), do: "text-yellow-500"
  def get_stats_card_icon_color("danger"), do: "text-red-500"
  def get_stats_card_icon_color("info"), do: "text-blue-500"

  @doc """
  Extracts the video ID from a YouTube URL.

  Supports various YouTube URL formats including standard watch URLs,
  short URLs, and embed URLs.

  ## Parameters

  - `url` - The YouTube URL to extract the video ID from

  ## Returns

  - `String.t()` - The extracted video ID

  ## Examples

      iex> extract_video_id("https://www.youtube.com/watch?v=dQw4w9WgXcQ")
      "dQw4w9WgXcQ"
      iex> extract_video_id("https://youtu.be/dQw4w9WgXcQ")
      "dQw4w9WgXcQ"
  """
  @spec extract_video_id(String.t()) :: String.t()
  def extract_video_id(url) do
    uri = URI.parse(url)

    cond do
      # Standard YouTube URL: https://www.youtube.com/watch?v=VIDEO_ID
      uri.host in ["www.youtube.com", "youtube.com"] && uri.path == "/watch" ->
        uri.query
        |> URI.decode_query()
        |> Map.get("v")

      # Short YouTube URL: https://youtu.be/VIDEO_ID
      uri.host == "youtu.be" ->
        uri.path |> String.trim_leading("/")

      # YouTube embed URL: https://www.youtube.com/embed/VIDEO_ID
      uri.host in ["www.youtube.com", "youtube.com"] && String.starts_with?(uri.path, "/embed/") ->
        uri.path |> String.trim_leading("/embed/")

      true ->
        # Fallback: try to extract from path
        uri.path |> String.split("/") |> List.last()
    end
  end

  @doc """
  Returns the variant for a short status badge.

  ## Examples

      iex> get_short_status_variant(:uploaded)
      "success"
      iex> get_short_status_variant(:generated)
      "primary"
      iex> get_short_status_variant(:failed)
      "danger"
      iex> get_short_status_variant(:error)
      "danger"
  """
  @spec get_short_status_variant(atom()) :: String.t()
  def get_short_status_variant(status) do
    case status do
      s when s in ["uploaded", :uploaded] -> "success"
      s when s in ["generated", :generated] -> "primary"
      s when s in ["failed", :failed, "error", :error] -> "danger"
      _ -> "default"
    end
  end
end
