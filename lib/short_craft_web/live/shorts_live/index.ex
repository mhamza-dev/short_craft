defmodule ShortCraftWeb.ShortsLive.Index do
  use ShortCraftWeb, :live_view
  require Logger

  alias Ecto.Query, as: EctoQuery, warn: false
  alias ShortCraft.Shorts
  alias ShortCraft.Shorts.Overlay

  @impl true
  def mount(%{"short_id" => short_id}, _session, socket) do
    short = Shorts.get_generated_short!(short_id)
    source_video = short.source_video
    duration = Map.get(short, :duration) || Map.get(source_video, :duration) || 60

    overlays = Map.get(short, :text_overlays) || []

    {:ok,
     assign(socket,
       short: short,
       source_video: source_video,
       music: Map.get(short, :music) || %{"track" => "", "volume" => 1.0},
       overlays: overlays,
       color_scheme: Map.get(short, :color_scheme) || "default",
       trim: %{start: 0, end: duration},
       preview_url: "/storage/shorts/#{Path.basename(short.output_path)}",
       saving: false,
       saved: false,
       selected_tab: "Videos",
       selected_overlay_id: nil,
       selected_overlay_changeset: nil,
       templates: load_templates(),
       uploaded_music: [],
       timeline_zoom: 1.0,
       show_help: false,
       form: nil,
       sidebar_tab: "Templates",
       show_context_menu: false,
       context_menu_x: 0,
       context_menu_y: 0,
       context_menu_overlay_id: nil
     )}
  end

  def handle_event("timeline_zoom", %{"factor" => factor}, socket) do
    zoom = String.to_float(factor)
    {:noreply, assign(socket, timeline_zoom: zoom)}
  end

  def handle_event("drop_on_timeline", %{"item" => item, "time" => time}, socket) do
    # Create a new overlay based on the dropped item
    new_overlay =
      case item do
        %{"type" => "text", "style" => style, "text" => text} ->
          {default_text, font, size, color} =
            case style do
              "heading" -> {text, "sans", 36, "#22223b"}
              "subtitle" -> {text, "serif", 24, "#4f518c"}
              "quote" -> {text, "serif", 20, "#a0aec0"}
              _ -> {text, "sans", 24, "#22223b"}
            end

          %{
            "type" => "text",
            "text" => default_text,
            "font" => font,
            "font_size" => size,
            "color" => color,
            "x" => 50,
            "y" => 50,
            "width" => 200,
            "height" => 50,
            "start" => time,
            "duration" => 5,
            "id" => System.unique_integer([:positive])
          }

        %{"type" => "shape", "subtype" => shape_type} ->
          %{
            "type" => "shape",
            "shape" => shape_type,
            "x" => 40,
            "y" => 40,
            "width" => 80,
            "height" => 80,
            "color" => default_shape_color(shape_type),
            "start" => time,
            "duration" => 5,
            "id" => System.unique_integer([:positive])
          }

        %{"type" => "video", "src" => src} ->
          %{
            "type" => "video",
            "src" => src,
            "x" => 10,
            "y" => 10,
            "width" => 160,
            "height" => 90,
            "start" => time,
            "duration" => 10,
            "id" => System.unique_integer([:positive])
          }

        %{"type" => "chart", "subtype" => chart_type} ->
          %{
            "type" => "chart",
            "chart_type" => chart_type,
            "x" => 60,
            "y" => 60,
            "width" => 100,
            "height" => 100,
            "start" => time,
            "duration" => 5,
            "id" => System.unique_integer([:positive])
          }

        _ ->
          nil
      end

    if new_overlay do
      overlays = socket.assigns.overlays ++ [new_overlay]
      {:noreply, assign(socket, overlays: overlays, saved: false)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("drop_on_video_container", %{"item" => item}, socket) do
    # Create a new overlay based on the dropped item (without timeline timing)
    new_overlay =
      case item do
        %{"type" => "text", "style" => style, "text" => text} ->
          {default_text, font, size, color} =
            case style do
              "heading" -> {text, "sans", 36, "#22223b"}
              "subtitle" -> {text, "serif", 24, "#4f518c"}
              "quote" -> {text, "serif", 20, "#a0aec0"}
              _ -> {text, "sans", 24, "#22223b"}
            end

          %{
            "type" => "text",
            "text" => default_text,
            "font" => font,
            "font_size" => size,
            "color" => color,
            "x" => 50,
            "y" => 50,
            "width" => 200,
            "height" => 50,
            "id" => System.unique_integer([:positive])
          }

        %{"type" => "shape", "subtype" => shape_type} ->
          %{
            "type" => "shape",
            "shape" => shape_type,
            "x" => 40,
            "y" => 40,
            "width" => 80,
            "height" => 80,
            "color" => default_shape_color(shape_type),
            "id" => System.unique_integer([:positive])
          }

        %{"type" => "video", "src" => src} ->
          %{
            "type" => "video",
            "src" => src,
            "x" => 10,
            "y" => 10,
            "width" => 160,
            "height" => 90,
            "id" => System.unique_integer([:positive])
          }

        %{"type" => "chart", "subtype" => chart_type} ->
          %{
            "type" => "chart",
            "chart_type" => chart_type,
            "x" => 60,
            "y" => 60,
            "width" => 100,
            "height" => 100,
            "id" => System.unique_integer([:positive])
          }

        _ ->
          nil
      end

    if new_overlay do
      overlays = socket.assigns.overlays ++ [new_overlay]
      {:noreply, assign(socket, overlays: overlays, saved: false)}
    else
      {:noreply, socket}
    end
  end

  def handle_event(
        "update_overlay_timing",
        %{"id" => id, "start" => start, "duration" => duration},
        socket
      ) do
    # Update the overlay's timing in the overlays list
    overlays =
      Enum.map(socket.assigns.overlays, fn overlay ->
        if overlay["id"] == id do
          Map.merge(overlay, %{
            "start" => start,
            "duration" => duration
          })
        else
          overlay
        end
      end)

    {:noreply, assign(socket, overlays: overlays, saved: false)}
  end

  @impl true
  # Drag-and-drop handler using JS interop
  def handle_event("js_drag", %{"x" => x, "y" => y}, socket) do
    # Logic to handle drag coordinates
    {:noreply, assign(socket, drag_coords: %{x: x, y: y})}
  end

  @impl true
  def handle_event("apply_template", %{"template_idx" => idx}, socket) do
    template = Enum.at(socket.assigns.templates, String.to_integer(idx))
    settings = template.settings

    {:noreply,
     assign(socket,
       color_scheme: Map.get(settings, "color_scheme", socket.assigns.color_scheme),
       overlays: Map.get(settings, "text_overlays", socket.assigns.overlays),
       saved: false
     )}
  end

  @impl true
  def handle_event("update_music", %{"track" => track}, socket) do
    music = %{socket.assigns.music | track: track}
    {:noreply, assign(socket, music: music, saved: false)}
  end

  @impl true
  def handle_event("upload_music", %{"file" => file}, socket) do
    # Handle music file upload logic (e.g., store in /storage/music/)
    file_path = Path.join(["storage", "music", file.name])
    File.cp!(file.path, file_path)
    uploaded_music = [file_path | socket.assigns.uploaded_music]

    {:noreply, assign(socket, uploaded_music: uploaded_music)}
  end

  # --- Overlay Creation: Always as Map, but ready for struct conversion ---
  def handle_event("add_text_overlay", _params, socket) do
    new_overlay = %{
      "text" => "New Text",
      "color" => "#ffffff",
      "font" => "sans",
      "font_size" => 24,
      "x" => 50,
      "y" => 50,
      "width" => 200,
      "height" => 50,
      "animation" => "none",
      "animation_mode" => "once",
      "type" => "text",
      "id" => System.unique_integer([:positive])
    }

    overlays = socket.assigns.overlays ++ [new_overlay]
    {:noreply, assign(socket, overlays: overlays, saved: false)}
  end

  def handle_event("add_text_style", %{"style" => style}, socket) do
    {text, font, size, color} =
      case style do
        "heading" -> {"Heading", "sans", 36, "#22223b"}
        "subtitle" -> {"Subtitle", "serif", 24, "#4f518c"}
        "quote" -> {"Quote", "serif", 20, "#a0aec0"}
        _ -> {"Text", "sans", 24, "#22223b"}
      end

    new_overlay = %{
      "type" => "text",
      "text" => text,
      "font" => font,
      "font_size" => size,
      "color" => color,
      "x" => 50,
      "y" => 50,
      "width" => 200,
      "height" => 50,
      "id" => System.unique_integer([:positive])
    }

    {:noreply, update(socket, :overlays, fn overlays -> overlays ++ [new_overlay] end)}
  end

  def handle_event("add_element", %{"type" => type}, socket) do
    new_overlay = %{
      "type" => "shape",
      "shape" => type,
      "x" => 40,
      "y" => 40,
      "width" => 80,
      "height" => 80,
      "color" => default_shape_color(type),
      "id" => System.unique_integer([:positive])
    }

    {:noreply, update(socket, :overlays, fn overlays -> overlays ++ [new_overlay] end)}
  end

  def handle_event("add_video_asset", %{"src" => src}, socket) do
    new_overlay = %{
      "type" => "video",
      "src" => src,
      "x" => 10,
      "y" => 10,
      "width" => 160,
      "height" => 90,
      "id" => System.unique_integer([:positive])
    }

    {:noreply, update(socket, :overlays, fn overlays -> overlays ++ [new_overlay] end)}
  end

  def handle_event("add_chart", %{"type" => type}, socket) do
    new_overlay = %{
      "type" => "chart",
      "chart_type" => type,
      "x" => 60,
      "y" => 60,
      "width" => 100,
      "height" => 100,
      "id" => System.unique_integer([:positive])
    }

    {:noreply, update(socket, :overlays, fn overlays -> overlays ++ [new_overlay] end)}
  end

  def handle_event("upload_file", _params, socket) do
    # For demo, add a static image overlay
    new_overlay = %{
      "type" => "image",
      "src" => "/images/aerial1.jpg",
      "x" => 30,
      "y" => 30,
      "width" => 120,
      "height" => 120,
      "id" => System.unique_integer([:positive])
    }

    {:noreply, update(socket, :overlays, fn overlays -> overlays ++ [new_overlay] end)}
  end

  def handle_event("select_overlay", %{"idx" => idx}, socket) do
    idx = String.to_integer(idx)
    selected_overlay = Enum.at(socket.assigns.overlays, idx)
    form = overlay_form(selected_overlay)

    {:noreply,
     assign(socket, selected_overlay: selected_overlay, selected_overlay_idx: idx, form: form)}
  end

  def handle_event("update_overlay", %{"overlay" => params}, socket) do
    idx = socket.assigns.selected_overlay_idx

    overlays =
      List.update_at(socket.assigns.overlays, idx, fn overlay ->
        overlay
        |> Map.put("text", params["text"])
        |> Map.put("color", params["color"])
        |> Map.put("font_size", String.to_integer(params["font_size"]))
        |> Map.put("font", params["font"])
        |> Map.put("animation", params["animation"])
        |> Map.put("animation_mode", params["animation_mode"] || "once")
        |> Map.put("x", String.to_integer(params["x"]))
        |> Map.put("y", String.to_integer(params["y"]))
      end)

    selected_overlay = Enum.at(overlays, idx)
    form = overlay_form(selected_overlay)

    {:noreply,
     assign(socket,
       overlays: overlays,
       selected_overlay: selected_overlay,
       selected_overlay_idx: idx,
       form: form,
       saved: false
     )}
  end

  def handle_event("update_overlay", %{"field" => field, "value" => value, "idx" => idx}, socket) do
    idx = String.to_integer(idx)

    overlays =
      List.update_at(socket.assigns.overlays, idx, fn overlay ->
        Map.put(overlay, field, value)
      end)

    selected_overlay = Enum.at(overlays, idx)
    form = overlay_form(selected_overlay)

    {:noreply,
     assign(socket,
       overlays: overlays,
       selected_overlay: selected_overlay,
       selected_overlay_idx: idx,
       form: form,
       saved: false
     )}
  end

  def handle_event("drag_overlay", %{"idx" => idx, "x" => x, "y" => y}, socket) do
    idx = String.to_integer(idx)

    overlays =
      List.update_at(socket.assigns.overlays, idx, fn overlay ->
        Map.put(overlay, "x", x)
        |> Map.put("y", y)
      end)

    selected_overlay = Enum.at(overlays, idx)

    {:noreply,
     assign(socket,
       overlays: overlays,
       selected_overlay: selected_overlay,
       selected_overlay_idx: idx,
       saved: false
     )}
  end

  @impl true
  def handle_event("delete_overlay", %{"idx" => idx}, socket) do
    idx = String.to_integer(idx)
    overlays = List.delete_at(socket.assigns.overlays, idx)

    # Clear selection if the deleted overlay was selected
    {selected_overlay, selected_overlay_idx} =
      if socket.assigns.selected_overlay_idx == idx do
        {nil, nil}
      else
        {socket.assigns.selected_overlay, socket.assigns.selected_overlay_idx}
      end

    {:noreply,
     assign(socket,
       overlays: overlays,
       selected_overlay: selected_overlay,
       selected_overlay_idx: selected_overlay_idx,
       saved: false,
       selected_overlay_changeset: nil
     )}
  end

  @impl true
  def handle_event("update_trim", %{"start" => start, "end" => end_}, socket) do
    trim = %{start: String.to_integer(start), end: String.to_integer(end_)}
    {:noreply, assign(socket, trim: trim, saved: false)}
  end

  @impl true
  def handle_event("sidebar_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, sidebar_tab: tab)}
  end

  def handle_event("play_overlay_animation", %{"idx" => idx}, socket) do
    # This event is for manual animation mode. We'll trigger a re-render with a unique key to restart the animation.
    idx = String.to_integer(idx)

    overlays =
      List.update_at(socket.assigns.overlays, idx, fn overlay ->
        Map.put(overlay, "animation_key", System.unique_integer([:positive]))
      end)

    selected_overlay = Enum.at(overlays, idx)
    form = overlay_form(selected_overlay)

    {:noreply,
     assign(socket,
       overlays: overlays,
       selected_overlay: selected_overlay,
       selected_overlay_idx: idx,
       form: form
     )}
  end

  @impl true
  def handle_event("save", _params, socket) do
    short = socket.assigns.short

    attrs = %{
      music: socket.assigns.music,
      text_overlays: socket.assigns.overlays,
      color_scheme: socket.assigns.color_scheme,
      trim: socket.assigns.trim
    }

    # Update the short in the DB
    Shorts.update_generated_short(short, attrs)

    # Trigger background ffmpeg job
    Task.start(fn -> export_short(short, attrs) end)

    {:noreply, assign(socket, saving: true, saved: true)}
  end

  # --- Overlay Selection: Always assign changeset for property panel ---
  def handle_event("select_canvas_overlay", %{"id" => id}, socket) do
    overlay_id = if is_binary(id), do: String.to_integer(id), else: id
    selected_overlay = Enum.find(socket.assigns.overlays, &(&1["id"] == overlay_id))

    if selected_overlay do
      overlay_struct = map_to_overlay_struct(selected_overlay)
      changeset = Overlay.changeset(overlay_struct, %{})

      {:noreply,
       assign(socket, selected_overlay_id: overlay_id, selected_overlay_changeset: changeset)}
    else
      {:noreply, assign(socket, selected_overlay_id: nil, selected_overlay_changeset: nil)}
    end
  end

  def handle_event("select_canvas_overlay", params, socket) do
    Logger.warning("Select overlay called with params: #{inspect(params)} (no id)")
    {:noreply, socket}
  end

  def handle_event("move_overlay", %{"id" => id, "x" => x, "y" => y}, socket) do
    overlay_id = if is_binary(id), do: String.to_integer(id), else: id
    x_int = if is_binary(x), do: String.to_integer(x), else: x
    y_int = if is_binary(y), do: String.to_integer(y), else: y

    overlays =
      Enum.map(socket.assigns.overlays, fn o ->
        if o["id"] == overlay_id,
          do: Map.merge(o, %{"x" => x_int, "y" => y_int}),
          else: o
      end)

    {:noreply, assign(socket, overlays: overlays) |> maybe_clear_selection()}
  end

  def handle_event("resize_overlay", %{"id" => id, "width" => width, "height" => height}, socket) do
    overlay_id = if is_binary(id), do: String.to_integer(id), else: id
    width_int = if is_binary(width), do: String.to_integer(width), else: width
    height_int = if is_binary(height), do: String.to_integer(height), else: height
    current_overlay = Enum.find(socket.assigns.overlays, &(&1["id"] == overlay_id))

    Logger.info(
      "Resizing overlay #{overlay_id} from #{current_overlay["width"]}x#{current_overlay["height"]} to #{width_int}x#{height_int}"
    )

    overlays =
      Enum.map(socket.assigns.overlays, fn o ->
        if o["id"] == overlay_id,
          do: Map.merge(o, %{"width" => width_int, "height" => height_int}),
          else: o
      end)

    {:noreply, assign(socket, overlays: overlays) |> maybe_clear_selection()}
  end

  def handle_event("bring_forward", %{"id" => id}, socket) do
    overlay_id = if is_binary(id), do: String.to_integer(id), else: id
    overlays = socket.assigns.overlays
    idx = Enum.find_index(overlays, &(&1["id"] == overlay_id))

    if idx && idx < length(overlays) - 1 do
      {before, [current, next | rest]} = Enum.split(overlays, idx)
      overlays = before ++ [next, current] ++ rest

      Logger.info(
        "[bring_forward] New overlays order: #{inspect(Enum.map(overlays, & &1["id"]))}"
      )

      {:noreply, assign(socket, overlays: overlays)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("send_backward", %{"id" => id}, socket) do
    overlay_id = if is_binary(id), do: String.to_integer(id), else: id
    overlays = socket.assigns.overlays
    idx = Enum.find_index(overlays, &(&1["id"] == overlay_id))

    if idx && idx > 0 do
      {before, [prev, current | rest]} = Enum.split(overlays, idx - 1)
      overlays = before ++ [current, prev] ++ rest

      Logger.info(
        "[send_backward] New overlays order: #{inspect(Enum.map(overlays, & &1["id"]))}"
      )

      {:noreply, assign(socket, overlays: overlays)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("bring_to_front", %{"id" => id}, socket) do
    overlay_id = if is_binary(id), do: String.to_integer(id), else: id
    overlays = socket.assigns.overlays
    {target, rest} = Enum.split_with(overlays, &(&1["id"] == overlay_id))
    overlays = rest ++ target
    Logger.info("[bring_to_front] New overlays order: #{inspect(Enum.map(overlays, & &1["id"]))}")
    {:noreply, assign(socket, overlays: overlays)}
  end

  def handle_event("send_to_back", %{"id" => id}, socket) do
    overlay_id = if is_binary(id), do: String.to_integer(id), else: id
    overlays = socket.assigns.overlays
    {target, rest} = Enum.split_with(overlays, &(&1["id"] == overlay_id))
    overlays = target ++ rest
    Logger.info("[send_to_back] New overlays order: #{inspect(Enum.map(overlays, & &1["id"]))}")
    {:noreply, assign(socket, overlays: overlays)}
  end

  # --- Overlay Deletion: Always clear selection/changeset if needed ---
  def handle_event("delete_overlay", %{"id" => id}, socket) do
    overlay_id = if is_binary(id), do: String.to_integer(id), else: id
    overlays = Enum.reject(socket.assigns.overlays, &(&1["id"] == overlay_id))

    {:noreply,
     assign(socket, overlays: overlays, selected_overlay_id: nil, selected_overlay_changeset: nil)}
  end

  def handle_event("debug_overlays", _params, socket) do
    Logger.info("Current overlays: #{inspect(socket.assigns.overlays)}")
    Logger.info("Selected overlay ID: #{inspect(socket.assigns.selected_overlay_id)}")

    # Also push to client for browser console debugging
    if socket.assigns.selected_overlay_id do
      selected_overlay =
        Enum.find(socket.assigns.overlays, &(&1["id"] == socket.assigns.selected_overlay_id))

      if selected_overlay do
        push_event(socket, "debug_overlay", %{
          id: selected_overlay["id"],
          x: selected_overlay["x"],
          y: selected_overlay["y"],
          width: selected_overlay["width"],
          height: selected_overlay["height"]
        })
      end
    end

    {:noreply, socket}
  end

  # --- Overlay Property Update: Robust changeset-based update ---
  def handle_event("update_overlay_props", %{"overlay" => overlay_params}, socket) do
    id = socket.assigns.selected_overlay_id
    overlays = socket.assigns.overlays
    idx = Enum.find_index(overlays, &(&1["id"] == id))
    selected_overlay = Enum.at(overlays, idx)

    if selected_overlay do
      # Get the current position from the selected overlay (preserve dragged position)
      current_x = selected_overlay["x"]
      current_y = selected_overlay["y"]
      current_width = selected_overlay["width"]
      current_height = selected_overlay["height"]

      overlay_struct = map_to_overlay_struct(selected_overlay)
      changeset = Overlay.changeset(overlay_struct, overlay_params)

      if changeset.valid? do
        # Merge changes into struct, then convert to map for storage
        updated_struct = Ecto.Changeset.apply_changes(changeset)
        updated_overlay = overlay_struct_to_map(updated_struct)

        # Preserve the current position and size (don't let form override dragged position)
        updated_overlay =
          Map.merge(updated_overlay, %{
            "x" => current_x,
            "y" => current_y,
            "width" => current_width,
            "height" => current_height
          })

        overlays = List.replace_at(overlays, idx, updated_overlay)
        {:noreply, assign(socket, overlays: overlays, selected_overlay_changeset: changeset)}
      else
        {:noreply, assign(socket, selected_overlay_changeset: changeset)}
      end
    else
      {:noreply, assign(socket, selected_overlay_id: nil, selected_overlay_changeset: nil)}
    end
  end

  def handle_event("show_context_menu", %{"id" => id, "x" => x, "y" => y}, socket) do
    overlay_id = if is_binary(id), do: String.to_integer(id), else: id

    {:noreply,
     assign(socket,
       show_context_menu: true,
       context_menu_x: x,
       context_menu_y: y,
       context_menu_overlay_id: overlay_id,
       selected_overlay_id: overlay_id
     )}
  end

  def handle_event("hide_context_menu", _params, socket) do
    {:noreply, assign(socket, show_context_menu: false)}
  end

  @impl true
  def handle_info({:update_selected_overlay, overlay}, socket) do
    {:noreply, assign(socket, selected_overlay: overlay)}
  end

  defp export_short(short, attrs) do
    input_path = short.original_path
    output_path = Path.join(["storage", "shorts", "edited_#{short.id}.mp4"])
    trim = attrs[:trim]
    text_overlays = attrs[:text_overlays]
    music = attrs[:music]

    # Build ffmpeg command
    ffmpeg_cmd = build_ffmpeg_command(input_path, output_path, trim, text_overlays, music)
    System.cmd("ffmpeg", ffmpeg_cmd)

    # Update DB with new output path
    Shorts.update_generated_short(short, %{output_path: output_path, status: "ready"})
  end

  defp build_ffmpeg_command(input, output, trim, overlays, music) do
    cmd = [
      "-i",
      input,
      "-ss",
      "#{trim.start}",
      "-to",
      "#{trim.end}",
      "-c:v",
      "libx264",
      "-preset",
      "fast",
      "-crf",
      "23"
    ]

    # Apply text overlays
    overlay_cmds =
      Enum.flat_map(overlays, fn overlay ->
        [
          "-vf",
          "drawtext=text='#{overlay[:text]}':fontcolor=#{overlay[:color]}:fontsize=#{overlay[:font_size]}:fontfile=/usr/share/fonts/#{overlay[:font]}.ttf:x=#{overlay[:x]}%:y=#{overlay[:y]}%",
          "-af",
          "fade=in:0:#{overlay[:duration]}"
        ]
      end)

    # Add music
    music_cmd =
      if music.track != "" do
        ["-i", music.track, "-c:a", "aac", "-b:a", "192k"]
      else
        []
      end

    cmd ++ overlay_cmds ++ music_cmd ++ [output]
  end

  # Rest of the LiveView code...

  defp load_templates do
    # Load predefined templates from JSON or DB
    [
      %{
        name: "Simple Text",
        description: "Basic text overlay",
        settings: %{
          color_scheme: "default",
          text_overlays: [
            %{
              "text" => "Your Text Here",
              "color" => "#ffffff",
              "font" => "sans",
              "font_size" => 36,
              "x" => 50,
              "y" => 50,
              "animation" => "fade"
            }
          ]
        }
      },
      %{
        name: "Dark Theme",
        description: "Black background with white text",
        settings: %{
          color_scheme: "dark",
          text_overlays: [
            %{
              "text" => "Highlight",
              "color" => "#ffffff",
              "font" => "serif",
              "font_size" => 48,
              "x" => 30,
              "y" => 20,
              "animation" => "slide"
            }
          ],
          background: "#000000"
        }
      }
    ]
  end

  # --- Helper: Convert map to Overlay struct for changeset usage ---
  defp map_to_overlay_struct(overlay_map) do
    attrs = overlay_map |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)
    struct(Overlay, attrs)
  end

  # --- Helper: Convert Overlay struct back to map for storage ---
  defp overlay_struct_to_map(overlay_struct) do
    overlay_struct
    |> Map.from_struct()
    |> Map.new(fn {k, v} -> {Atom.to_string(k), v} end)
  end

  defp overlay_form(overlay) do
    overlay_struct = map_to_overlay_struct(overlay)
    to_form(Overlay.changeset(overlay_struct, %{}), as: :overlay)
  end

  defp default_shape_color("circle"), do: "#6366f1"
  defp default_shape_color("square"), do: "#a21caf"
  defp default_shape_color("triangle"), do: "#f59e42"
  defp default_shape_color("star"), do: "#fbbf24"
  defp default_shape_color("arrow"), do: "#10b981"
  defp default_shape_color("line"), do: "#64748b"
  defp default_shape_color("heart"), do: "#ef4444"
  defp default_shape_color(_), do: "#6366f1"

  defp get_video_aspect_ratio(_short), do: "9 / 16"

  def get_font_family("sans"),
    do:
      "ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, 'Noto Sans', sans-serif"

  def get_font_family("serif"), do: "ui-serif, Georgia, Cambria, 'Times New Roman', Times, serif"

  def get_font_family("mono"),
    do: "ui-monospace, SFMono-Regular, 'SF Mono', Consolas, 'Liberation Mono', Menlo, monospace"

  def get_font_family(_),
    do:
      "ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, 'Noto Sans', sans-serif"

  # --- Robustness: Always clear changeset if selection is invalid ---
  defp maybe_clear_selection(socket) do
    if socket.assigns.selected_overlay_id do
      found =
        Enum.any?(socket.assigns.overlays, &(&1["id"] == socket.assigns.selected_overlay_id))

      if found,
        do: socket,
        else: assign(socket, selected_overlay_id: nil, selected_overlay_changeset: nil)
    else
      assign(socket, selected_overlay_changeset: nil)
    end
  end
end
