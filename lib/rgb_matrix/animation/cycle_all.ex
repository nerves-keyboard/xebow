defmodule RGBMatrix.Animation.CycleAll do
  @moduledoc """
  Cycles the hue of all LEDs at the same time.
  """

  alias Chameleon.HSV
  alias RGBMatrix.Animation

  use Animation

  import RGBMatrix.Utils, only: [mod: 2]

  defmodule Config do
    @moduledoc false
    use RGBMatrix.Animation.Config
  end

  defmodule State do
    @moduledoc false
    defstruct [:tick, :speed, :led_ids]
  end

  @delay_ms 17

  @impl true
  def new(leds, _config) do
    led_ids = Enum.map(leds, & &1.id)
    {0, %State{tick: 0, speed: 100, led_ids: led_ids}}
  end

  @impl true
  def render(state, _config) do
    %{tick: tick, speed: speed, led_ids: led_ids} = state

    time = div(tick * speed, 100)
    hue = mod(time, 360)
    color = HSV.new(hue, 100, 100)

    colors = Enum.map(led_ids, fn id -> {id, color} end)

    {@delay_ms, colors, %{state | tick: tick + 1}}
  end

  @impl true
  def interact(state, _config, _led) do
    {:ignore, state}
  end
end
