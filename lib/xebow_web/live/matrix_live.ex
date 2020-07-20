defmodule XebowWeb.MatrixLive do
  @moduledoc false

  use XebowWeb, :live_view

  alias RGBMatrix.{Animation, Engine}

  @layout Xebow.layout()
  @black Chameleon.HSV.new(0, 0, 0)
  @black_frame @layout
               |> Layout.leds()
               |> Map.new(fn led ->
                 {led.id, @black}
               end)

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {config, config_schema} = Engine.get_animation_config()

    initial_assigns = [
      leds: make_view_leds(@black_frame),
      config: config,
      config_schema: config_schema,
      animation_types: Animation.types(),
      current_animation_index: 0
    ]

    initial_assigns =
      if connected?(socket) do
        {paint_fn, config_fn} = register_with_engine!()

        Keyword.merge(initial_assigns, paint_fn: paint_fn, config_fn: config_fn)
      else
        initial_assigns
      end

    {:ok, assign(socket, initial_assigns)}
  end

  @impl Phoenix.LiveView
  def handle_info({:render, frame}, socket) do
    colors =
      frame
      |> make_view_leds()
      |> Enum.map(fn led -> {led.id, led.color} end)
      |> Enum.into(%{})

    {:noreply, push_event(socket, "draw", colors)}
  end

  @impl Phoenix.LiveView
  def handle_info({:render_config, {config, config_schema}}, socket) do
    {:noreply, assign(socket, config: config, config_schema: config_schema)}
  end

  @impl Phoenix.LiveView
  def handle_event("key_pressed", %{"key-id" => id_str}, socket) do
    key_id = String.to_existing_atom(id_str)

    case Layout.led_for_key(@layout, key_id) do
      nil -> :noop
      led -> Engine.interact(led)
    end

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("update_config", %{"_target" => [field_str]} = params, socket) do
    value = Map.fetch!(params, field_str)

    Engine.update_animation_config(%{field_str => value})

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("next_animation", %{}, socket) do
    next_index = socket.assigns.current_animation_index + 1

    next_index =
      case next_index < Enum.count(socket.assigns.animation_types) do
        true -> next_index
        _ -> 0
      end

    animation_type = Enum.at(socket.assigns.animation_types, next_index)

    RGBMatrix.Engine.set_animation(animation_type)

    {:noreply, assign(socket, current_animation_index: next_index)}
  end

  @impl Phoenix.LiveView
  def handle_event("previous_animation", %{}, socket) do
    previous_index = socket.assigns.current_animation_index - 1

    previous_index =
      case previous_index < 0 do
        true -> Enum.count(socket.assigns.animation_types) - 1
        _ -> previous_index
      end

    animation_type = Enum.at(socket.assigns.animation_types, previous_index)

    RGBMatrix.Engine.set_animation(animation_type)

    {:noreply, assign(socket, current_animation_index: previous_index)}
  end

  @impl Phoenix.LiveView
  def terminate(_reason, socket) do
    Engine.unregister_paintable(socket.assigns.paint_fn)
    Engine.unregister_configurable(socket.assigns.config_fn)
  end

  defp register_with_engine! do
    pid = self()

    {:ok, paint_fn} =
      Engine.register_paintable(fn frame ->
        if Process.alive?(pid) do
          send(pid, {:render, frame})
          :ok
        else
          :unregister
        end
      end)

    {:ok, config_fn} =
      Engine.register_configurable(fn config ->
        if Process.alive?(pid) do
          send(pid, {:render_config, config})
          :ok
        else
          :unregister
        end
      end)

    {paint_fn, config_fn}
  end

  defp make_view_leds(frame) do
    leds_with_maybe_keys =
      @layout
      |> Layout.leds()
      |> Enum.map(fn led ->
        color =
          frame
          |> Map.fetch!(led.id)
          |> Chameleon.convert(Chameleon.Hex)

        key = Layout.key_for_led(@layout, led.id)

        make_view_led(color.hex, led, key)
      end)

    keys_with_no_leds =
      @layout
      |> Layout.keys()
      |> Enum.filter(fn key -> is_nil(key.led) end)
      |> Enum.map(fn key ->
        make_view_led("000", nil, key)
      end)

    leds_with_maybe_keys ++ keys_with_no_leds
  end

  defp make_view_led(color_hex, led, nil) do
    width = 25
    height = 25
    x = led.x * 50 - width / 2
    y = led.y * 50 - height / 2

    %{
      class: "led",
      id: led.id,
      x: x,
      y: y,
      width: width,
      height: height,
      color: color_hex
    }
  end

  defp make_view_led(color_hex, _led, key) do
    width = key.width * 50
    height = key.height * 50
    x = key.x * 50 - width / 2
    y = key.y * 50 - height / 2

    %{
      class: "key",
      id: key.id,
      x: x,
      y: y,
      width: width,
      height: height,
      color: color_hex
    }
  end
end
