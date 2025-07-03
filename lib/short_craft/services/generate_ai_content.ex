defmodule ShortCraft.Services.GenerateAiContent do
  @moduledoc """
  Service for generating multiple YouTube Shorts ideas using Google Gemini API.
  """

  require Logger

  @gemini_url "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"
  @gemini_api_key Application.compile_env(:short_craft, :gemini_api_key)
  @max_shorts 100

  @doc """
  Generates multiple YouTube Shorts ideas for a given video using Gemini API.

  ## Options
    - `:num_shorts` - Number of shorts ideas to generate (default: 3, max: #{@max_shorts})

  ## Returns
    - `{:ok, list_of_ideas}` on success
    - `{:error, reason}` on failure
  """
  def generate_for_video(video_transcript, num_shorts \\ 3) do
    num_shorts = clamp(num_shorts, 1, @max_shorts)

    prompt = """
    Here is the transcript of a YouTube video:
    #{video_transcript}

    Based on this transcript, generate #{num_shorts} creative YouTube Shorts Titles, Descriptions and Tags...
    Respond in JSON format as an array of objects, each with these keys: title, description, tags.
    The title should be a catchy, scroll-stopping title that fits Shorts style (<60 characters). Avoid reusing the main video title — be original, witty, or curiosity-driven.
    The description should be a 1–2 sentence first-person style description as if the creator is speaking. It should summarize what the viewer will see in the Short and why it's exciting, shocking, funny, or worth watching.
    The tags should be a list of 3–5 specific, relevant tags that describe the content, mood, or theme of this short (e.g. "reaction", "lifehack", "funnyfail", "gamingclip", etc.). Avoid overly generic tags.
    """

    dbg(prompt)

    headers = [
      {"Content-Type", "application/json"},
      {"X-goog-api-key", @gemini_api_key}
    ]

    body =
      Jason.encode!(%{
        contents: [
          %{
            parts: [
              %{text: prompt}
            ]
          }
        ]
      })

    url = "#{@gemini_url}?key=#{@gemini_api_key}"

    case HTTPoison.post(url, body, headers) do
      {:ok, %{status_code: 200, body: body}} ->
        Logger.info("Gemini response: #{inspect(body)}")

        with {:ok, response} <- Jason.decode(body),
             %{"candidates" => candidates} when is_list(candidates) <- response,
             %{"content" => %{"parts" => [%{"text" => content}]}} <- Enum.at(candidates, 0),
             {:ok, ideas} <- safe_decode_json(content) do
          {:ok, ideas}
        else
          error -> handle_error("Malformed or unexpected response", error)
        end

      {:ok, response} ->
        handle_error("Gemini error", response.status_code)

      {:error, reason} ->
        handle_error("Gemini error", reason)
    end
  end

  defp clamp(val, min, max) when is_integer(val), do: max(min, min(val, max))

  defp safe_decode_json(content) do
    # Remove triple backticks and optional 'json' after them
    content =
      content
      |> String.trim()
      |> String.replace(~r/^```json\s*/i, "")
      |> String.replace(~r/^```/, "")
      |> String.replace(~r/```$/, "")

    try do
      {:ok, Jason.decode!(content)}
    rescue
      e -> {:error, {:invalid_json, e, content}}
    end
  end

  defp handle_error(msg, error) do
    Logger.error("#{msg}: #{inspect(error)}")
    {:error, {msg, error}}
  end
end
