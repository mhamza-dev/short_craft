defmodule ShortCraftWeb.ShortController do
  use ShortCraftWeb, :controller
  alias ShortCraft.Shorts

  def download(conn, %{"id" => id}) do
    short = Shorts.get_generated_short!(id)
    file_path = short.output_path

    if File.exists?(file_path) do
      conn
      |> put_resp_content_type("video/mp4")
      |> put_resp_header("content-disposition", "attachment; filename=\"#{Path.basename(file_path)}\"")
      |> send_file(200, file_path)
    else
      send_resp(conn, 404, "File not found")
    end
  end
end
