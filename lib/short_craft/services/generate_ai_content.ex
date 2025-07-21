defmodule ShortCraft.Services.GenerateAiContent do
  @moduledoc """
  Service for generating multiple YouTube Shorts ideas using multiple AI models with fallback support.
  """

  require Logger

  @deepseek_ai_key Application.compile_env!(:short_craft, :deepseek_api_key)
  @gemini_ai_key Application.compile_env!(:short_craft, :gemini_api_key)
  @openai_ai_key Application.compile_env!(:short_craft, :openai_api_key)

  # Model configurations
  @models [
    %{
      name: :gemini_2_flash,
      provider: :google,
      url:
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent",
      api_key: @gemini_ai_key,
      priority: 1
    },
    %{
      name: :gemini_1_5_pro,
      provider: :google,
      url:
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent",
      api_key: @gemini_ai_key,
      priority: 2
    },
    %{
      name: :deepseek_chat,
      provider: :deepseek,
      url: "https://api.deepseek.com/chat/completions",
      api_key: @deepseek_ai_key,
      priority: 3
    },
    %{
      name: :openai_gpt4,
      provider: :openai,
      url: "https://api.openai.com/v1/chat/completions",
      api_key: @openai_ai_key,
      priority: 4
    },
    %{
      name: :openai_gpt35,
      provider: :openai,
      url: "https://api.openai.com/v1/chat/completions",
      api_key: @openai_ai_key,
      priority: 5
    }
  ]

  @max_shorts 100

  @doc """
  Generates multiple YouTube Shorts ideas for a given video using multiple AI models with fallback.

  ## Options
    - `:num_shorts` - Number of shorts ideas to generate (default: 3, max: #{@max_shorts})
    - `:preferred_model` - Specific model to try first (optional)
    - `:max_retries` - Maximum number of model retries (default: 3)

  ## Returns
    - `{:ok, list_of_ideas}` on success
    - `{:error, reason}` on failure
  """
  def generate_for_video(video_transcript, num_shorts \\ 3, opts \\ []) do
    num_shorts = clamp(num_shorts, 1, @max_shorts)
    preferred_model = Keyword.get(opts, :preferred_model)
    max_retries = Keyword.get(opts, :max_retries, 3)

    # Check if transcript is available
    if is_nil(video_transcript) or String.trim(video_transcript) == "" do
      {:error, "Transcript not available"}
    else
      # Sort models by priority, putting preferred model first if specified
      sorted_models = sort_models_by_preference(@models, preferred_model)

      # Try each model until one succeeds
      try_models_with_fallback(sorted_models, video_transcript, num_shorts, max_retries)
    end
  end

  @doc """
  Generates content using a specific model.
  """
  def generate_with_model(model_name, video_transcript, num_shorts \\ 3) do
    model = Enum.find(@models, &(&1.name == model_name))

    if model do
      generate_with_specific_model(model, video_transcript, num_shorts)
    else
      {:error, "Model #{model_name} not found"}
    end
  end

  @doc """
  Lists all available models.
  """
  def list_available_models do
    @models
    |> Enum.map(fn model ->
      %{
        name: model.name,
        provider: model.provider,
        priority: model.priority,
        available: not is_nil(model.api_key)
      }
    end)
  end

  # Private functions

  defp try_models_with_fallback([], _transcript, _num_shorts, _retries) do
    {:error, "All AI models failed"}
  end

  defp try_models_with_fallback([model | rest_models], transcript, num_shorts, retries) do
    case generate_with_specific_model(model, transcript, num_shorts) do
      {:ok, result} ->
        Logger.info("Successfully generated content using #{model.name}")
        {:ok, result}

      {:error, reason} ->
        Logger.warning("Model #{model.name} failed: #{inspect(reason)}")

        if retries > 0 do
          # Retry with the same model
          try_models_with_fallback([model | rest_models], transcript, num_shorts, retries - 1)
        else
          # Try next model
          try_models_with_fallback(rest_models, transcript, num_shorts, 3)
        end
    end
  end

  defp generate_with_specific_model(model, video_transcript, num_shorts) do
    prompt = build_prompt(video_transcript, num_shorts)

    case model.provider do
      :google -> call_google_api(model, prompt)
      :openai -> call_openai_api(model, prompt)
      :deepseek -> call_deepseek_api(model, prompt)
      _ -> {:error, "Unsupported provider: #{model.provider}"}
    end
  end

  defp build_prompt(video_transcript, num_shorts) do
    """
    Here is the transcript of a YouTube video:
    #{video_transcript}

    Based on this transcript, generate #{num_shorts} creative YouTube Shorts Titles, Descriptions and Tags...
    Respond in JSON format as an array of objects, each with these keys: title, description, tags.
    The title should be a catchy, scroll-stopping title that fits Shorts style (<60 characters). Avoid reusing the main video title — be original, witty, or curiosity-driven.
    The description should be a 1–2 sentence first-person style description as if the creator is speaking. It should summarize what the viewer will see in the Short and why it's exciting, shocking, funny, or worth watching.
    The tags should be a list of 3–5 specific, relevant tags that describe the content, mood, or theme of this short (e.g. "reaction", "lifehack", "funnyfail", "gamingclip", etc.). Avoid overly generic tags.
    """
  end

  defp call_google_api(model, prompt) do
    headers = [
      {"Content-Type", "application/json"},
      {"X-goog-api-key", model.api_key}
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

    url = "#{model.url}?key=#{model.api_key}"

    # Add timeout and retry options
    options = [
      timeout: 30_000,
      recv_timeout: 60_000,
      ssl: [{:verify, :verify_none}]
    ]

    case HTTPoison.post(url, body, headers, options) do
      {:ok, %{status_code: 200, body: body}} ->
        Logger.info("Google API response for #{model.name}")

        with {:ok, response} <- Jason.decode(body),
             %{"candidates" => candidates} when is_list(candidates) <- response,
             %{"content" => %{"parts" => [%{"text" => content}]}} <- Enum.at(candidates, 0),
             {:ok, ideas} <- safe_decode_json(content) do
          {:ok, ideas}
        else
          error -> handle_error("Malformed Google API response", error)
        end

      {:ok, response} ->
        handle_error("Google API error (#{model.name})", response.status_code)

      {:error, reason} ->
        handle_error("Google API error (#{model.name})", reason)
    end
  end

  defp call_openai_api(model, prompt) do
    headers = [
      {"Content-Type", "application/json"},
      {"Authorization", "Bearer #{model.api_key}"}
    ]

    model_name =
      case model.name do
        :openai_gpt4 -> "gpt-4"
        :openai_gpt35 -> "gpt-3.5-turbo"
        _ -> "gpt-3.5-turbo"
      end

    body =
      Jason.encode!(%{
        model: model_name,
        messages: [
          %{
            role: "user",
            content: prompt
          }
        ],
        temperature: 0.7,
        max_tokens: 2000
      })

    options = [
      timeout: 30_000,
      recv_timeout: 60_000,
      ssl: [{:verify, :verify_none}]
    ]

    case HTTPoison.post(model.url, body, headers, options) do
      {:ok, %{status_code: 200, body: body}} ->
        Logger.info("OpenAI API response for #{model.name}")

        with {:ok, response} <- Jason.decode(body),
             %{"choices" => choices} when is_list(choices) <- response,
             %{"message" => %{"content" => content}} <- Enum.at(choices, 0),
             {:ok, ideas} <- safe_decode_json(content) do
          {:ok, ideas}
        else
          error -> handle_error("Malformed OpenAI API response", error)
        end

      {:ok, response} ->
        handle_error("OpenAI API error (#{model.name})", response.status_code)

      {:error, reason} ->
        handle_error("OpenAI API error (#{model.name})", reason)
    end
  end

  defp call_deepseek_api(model, prompt) do
    headers = [
      {"Content-Type", "application/json"},
      {"Authorization", "Bearer #{model.api_key}"}
    ]

    body =
      Jason.encode!(%{
        model: "deepseek-chat",
        messages: [
          %{
            role: "user",
            content: prompt
          }
        ],
        stream: false,
        temperature: 0.7,
        max_tokens: 2000
      })

    options = [
      timeout: 30_000,
      recv_timeout: 60_000,
      ssl: [{:verify, :verify_none}]
    ]

    case HTTPoison.post(model.url, body, headers, options) do
      {:ok, %{status_code: 200, body: body}} ->
        Logger.info("DeepSeek API response for #{model.name}")

        with {:ok, response} <- Jason.decode(body),
             %{"choices" => choices} when is_list(choices) <- response,
             %{"message" => %{"content" => content}} <- Enum.at(choices, 0),
             {:ok, ideas} <- safe_decode_json(content) do
          {:ok, ideas}
        else
          error -> handle_error("Malformed DeepSeek API response", error)
        end

      {:ok, response} ->
        handle_error("DeepSeek API error (#{model.name})", response.status_code)

      {:error, reason} ->
        handle_error("DeepSeek API error (#{model.name})", reason)
    end
  end

  defp sort_models_by_preference(models, nil) do
    Enum.sort_by(models, & &1.priority)
  end

  defp sort_models_by_preference(models, preferred_model) do
    {preferred, others} = Enum.split_with(models, &(&1.name == preferred_model))
    preferred ++ Enum.sort_by(others, & &1.priority)
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
