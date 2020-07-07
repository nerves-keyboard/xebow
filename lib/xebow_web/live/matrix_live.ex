defmodule XebowWeb.MatrixLive do
  use XebowWeb, :live_view

  alias RGBMatrix.Engine

  @layout Xebow.layout()
  @black Chameleon.HSV.new(0, 0, 0)
  @black_frame @layout
               |> Layout.leds()
               |> Map.new(fn led ->
                 {led.id, @black}
               end)

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      register_with_engine!()
    end

    {:ok, assign(socket, leds: make_view_leds(@black_frame))}
  end

  defp register_with_engine! do
    pid = self()

    paint_fn = fn frame ->
      if Process.alive?(pid) do
        send(pid, {:render, frame})
        :ok
      else
        :unregister
      end
    end

    :ok = Engine.register_paintable(pid, paint_fn)
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
      color: "#" <> color_hex
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
      color: "#" <> color_hex
    }
  end

  @impl true
  def handle_info({:render, frame}, socket) do
    {:noreply, assign(socket, leds: make_view_leds(frame))}
  end

  @impl true
  def handle_event("key_pressed", %{"key-id" => id_str}, socket) do
    key_id = String.to_existing_atom(id_str)

    case Layout.led_for_key(@layout, key_id) do
      nil -> :noop
      led -> Engine.interact(led)
    end

    {:noreply, socket}
  end

  @impl true
  def terminate(_reason, _socket) do
    Engine.unregister_paintable(self())
  end

  # def handle_event("update_config", %{"_target" => [field_str]} = params, socket) do
  #   field = String.to_existing_atom(field_str)
  #   %config_mod{} = config = socket.assigns.state.effect.config
  #   %type_mod{} = type = Keyword.fetch!(config_mod.schema(), field)
  #   value = Map.fetch!(params, field_str)
  #   {:ok, value} = type_mod.cast(type, value)

  #   new_config = config_mod.update(config, %{field => value})

  #   effect = socket.assigns.state.effect
  #   new_effect = %{effect | config: new_config}
  #   new_state = %{socket.assigns.state | effect: new_effect}

  #   {:noreply, assign(socket, state: new_state, config: new_config)}
  # end
end
