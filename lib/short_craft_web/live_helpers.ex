defmodule ShortCraftWeb.LiveHelpers do
  def format_datetime(nil), do: "-"

  def format_datetime(datetime) do
    Timex.format!(datetime, "%A %B %d, %Y at %H:%M %p", :strftime)
  end

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

  def humanize_status(nil), do: "Unknown"

  def humanize_status(true), do: "Yes"
  def humanize_status(false), do: "No"

  def humanize_status(status) do
    status
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  def status_badge_class(:completed),
    do: "bg-green-100 text-green-800 px-2 py-1 rounded text-xs font-semibold"

  def status_badge_class(:processing),
    do: "bg-yellow-100 text-yellow-800 px-2 py-1 rounded text-xs font-semibold"

  def status_badge_class(:failed),
    do: "bg-red-100 text-red-800 px-2 py-1 rounded text-xs font-semibold"

  def status_badge_class(:queued),
    do: "bg-blue-100 text-blue-800 px-2 py-1 rounded text-xs font-semibold"

  def status_badge_class(:waiting_review),
    do: "bg-purple-100 text-purple-800 px-2 py-1 rounded text-xs font-semibold"

  def status_badge_class(:rejected),
    do: "bg-gray-200 text-gray-700 px-2 py-1 rounded text-xs font-semibold"

  def status_badge_class(:published),
    do: "bg-indigo-100 text-indigo-800 px-2 py-1 rounded text-xs font-semibold"

  def status_badge_class(:not_started),
    do: "bg-gray-100 text-gray-800 px-2 py-1 rounded text-xs font-semibold"

  def status_badge_class(:cancelled),
    do: "bg-gray-300 text-gray-900 px-2 py-1 rounded text-xs font-semibold"

  def status_badge_class(true),
    do: "bg-green-100 text-green-800 px-2 py-1 rounded text-xs font-semibold"

  def status_badge_class(false),
    do: "bg-red-100 text-red-800 px-2 py-1 rounded text-xs font-semibold"

  def status_badge_class(_),
    do: "bg-gray-100 text-gray-800 px-2 py-1 rounded text-xs font-semibold"
end
