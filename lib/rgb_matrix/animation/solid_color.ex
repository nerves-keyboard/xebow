defmodule RGBMatrix.Animation.SolidColor do
  @moduledoc """
  All LEDs are a solid color.
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
    defstruct [:color, :led_ids]
  end

  @impl true
  def new(leds, _config) do
    color = HSV.new(120, 100, 100)
    {0, %State{color: color, led_ids: Enum.map(leds, & &1.id)}}
  end

  @impl true
  def render(state, _config) do
    %{color: color, led_ids: led_ids} = state

    colors = Enum.map(led_ids, fn id -> {id, color} end)

    {:never, colors, state}
  end

  @impl true
  def interact(state, _config, _led) do
    {:ignore, state}
  end
end
