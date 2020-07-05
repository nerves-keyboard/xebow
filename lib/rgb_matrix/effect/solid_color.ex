defmodule RGBMatrix.Effect.SolidColor do
  @moduledoc """
  All LEDs are a solid color.
  """

  alias Chameleon.HSV
  alias RGBMatrix.Effect

  use Effect

  defmodule Config do
    use RGBMatrix.Effect.Config
  end

  defmodule State do
    defstruct [:color, :led_ids]
  end

  @impl true
  def new(leds, _config) do
    # TODO: configurable base color
    color = HSV.new(120, 100, 100)
    {0, %State{color: color, led_ids: Enum.map(leds, & &1.id)}}
  end

  @impl true
  def render(state, _config) do
    %{color: color, led_ids: led_ids} = state

    colors = Enum.map(led_ids, fn id -> {id, color} end)

    {colors, :never, state}
  end

  @impl true
  def key_pressed(state, _config, _led) do
    {:ignore, state}
  end
end
