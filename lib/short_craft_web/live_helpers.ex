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

      iex> status_badge_class(:completed)
      "px-2 py-1 rounded text-xs font-semibold bg-green-100 text-green-800"
      iex> status_badge_class(:downloading)
      "px-2 py-1 rounded text-xs font-semibold bg-yellow-100 text-yellow-800"
      iex> status_badge_class(:failed)
      "px-2 py-1 rounded text-xs font-semibold bg-red-100 text-red-800"
  """
  @spec status_badge_class(atom() | boolean()) :: String.t()
  def status_badge_class(status) do
    "px-2 py-1 rounded text-xs font-semibold #{colors_by_status(status)}"
  end

  @doc false
  @spec colors_by_status(atom() | boolean()) :: String.t()
  defp colors_by_status(:completed), do: "bg-green-100 text-green-800"
  defp colors_by_status(:processing), do: "bg-yellow-100 text-yellow-800"
  defp colors_by_status(:failed), do: "bg-red-100 text-red-800"
  defp colors_by_status(:queued), do: "bg-blue-100 text-blue-800"
  defp colors_by_status(:waiting_review), do: "bg-purple-100 text-purple-800"
  defp colors_by_status(:rejected), do: "bg-gray-200 text-gray-700"
  defp colors_by_status(:published), do: "bg-indigo-100 text-indigo-800"
  defp colors_by_status(:not_started), do: "bg-gray-100 text-gray-800"
  defp colors_by_status(:downloading), do: "bg-yellow-100 text-yellow-800"
  defp colors_by_status(:cancelled), do: "bg-gray-300 text-gray-900"
  defp colors_by_status(:progress), do: "bg-blue-100 text-blue-800"
  defp colors_by_status(:started), do: "bg-cyan-100 text-cyan-800"
  defp colors_by_status(true), do: "bg-green-100 text-green-800"
  defp colors_by_status(false), do: "bg-red-100 text-red-800"
  defp colors_by_status(_), do: "bg-gray-100 text-gray-800"
end
