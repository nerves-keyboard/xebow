defmodule RGBMatrix.Animation.Breathing do
  @moduledoc """
  Single hue brightness cycling.
  """

  alias Chameleon.HSV
  alias RGBMatrix.Animation

  use Animation

  defmodule Config do
    @moduledoc false
    use RGBMatrix.Animation.Config
  end

  defmodule State do
    @moduledoc false
    defstruct [:color, :tick, :speed, :led_ids]
  end

  @delay_ms 17

  @impl true
  def new(leds, _config) do
    color = HSV.new(40, 100, 100)
    led_ids = Enum.map(leds, & &1.id)
    %State{color: color, tick: 0, speed: 100, led_ids: led_ids}
  end

  @impl true
  def render(state, _config) do
    %{color: base_color, tick: tick, speed: speed, led_ids: led_ids} = state

    value = trunc(abs(:math.sin(tick * speed / 5_000)) * base_color.v)
    color = HSV.new(base_color.h, base_color.s, value)

    colors = Enum.map(led_ids, fn id -> {id, color} end)

    {@delay_ms, colors, %{state | tick: tick + 1}}
  end

  @impl true
  def interact(state, _config, _led) do
    {:ignore, state}
  end
end
