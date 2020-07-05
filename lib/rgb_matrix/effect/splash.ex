defmodule RGBMatrix.Effect.Splash do
  @moduledoc """
  Full gradient & value pulse away from key hits then fades value out.
  """

  alias Chameleon.HSV
  alias RGBMatrix.Effect

  use Effect

  # import RGBMatrix.Utils, only: [mod: 2]

  defmodule Config do
    use RGBMatrix.Effect.Config
  end

  defmodule State do
    defstruct [:tick, :leds, :hits]
  end

  @delay_ms 17

  @impl true
  def new(leds, _config) do
    {0, %State{tick: 0, leds: leds, hits: %{}}}
  end

  @impl true
  def render(state, _config) do
    %{tick: tick, leds: leds, hits: hits} = state

    {colors, hits} =
      Enum.map_reduce(leds, hits, fn led, hits ->
        color = HSV.new(0, 100, 0)

        {hits, color} =
          Enum.reduce(hits, {hits, color}, fn {hit_led, hit_tick}, {hits, color} ->
            dx = led.x - hit_led.x
            dy = led.y - hit_led.y
            dist = :math.sqrt(dx * dx + dy * dy)
            color = effect(color, dist, tick - hit_tick)

            {hits, color}
          end)

        {{led.id, color}, hits}
      end)

    # for (uint8_t i = led_min; i < led_max; i++) {
    #     RGB_MATRIX_TEST_LED_FLAGS();
    #     HSV hsv = rgb_matrix_config.hsv;
    #     hsv.v   = 0;
    #     for (uint8_t j = start; j < count; j++) {
    #         int16_t  dx   = g_led_config.point[i].x - g_last_hit_tracker.x[j];
    #         int16_t  dy   = g_led_config.point[i].y - g_last_hit_tracker.y[j];
    #         uint8_t  dist = sqrt16(dx * dx + dy * dy);
    #         uint16_t tick = scale16by8(g_last_hit_tracker.tick[j], rgb_matrix_config.speed);
    #         hsv           = effect_func(hsv, dx, dy, dist, tick);
    #     }
    #     hsv.v   = scale8(hsv.v, rgb_matrix_config.hsv.v);
    #     RGB rgb = hsv_to_rgb(hsv);
    #     rgb_matrix_set_color(i, rgb.r, rgb.g, rgb.b);
    # }

    {colors, @delay_ms, %{state | tick: tick + 1, hits: hits}}
  end

  def effect(color, dist, hit_tick) do
    # uint16_t effect = tick - dist;
    # if (effect > 255) effect = 255;
    # hsv.h += effect;
    # hsv.v = qadd8(hsv.v, 255 - effect);
    # return hsv;

    # effect = trunc(if effect > 360, do: 360, else: effect)

    value = 100 - hit_tick - trunc(dist * 20)
    value = if value < 0, do: 0, else: value

    %{color | h: 0, v: value}

    # if dist < 5 do
    #   HSV.new(0, 100, 100)
    # else
    #   color
    # end
  end

  @impl true
  def key_pressed(state, _config, led) do
    # {:ignore, %{state | hits: Map.put(state.hits, led, state.tick)}}
    {:ignore, %{state | hits: %{led => state.tick}}}
  end
end
