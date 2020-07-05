defmodule RGBMatrix.Effect.RandomSolid do
  @moduledoc """
  A random solid color fills the entire matrix and changes every key-press.
  """

  alias Chameleon.HSV
  alias RGBMatrix.Effect

  use Effect

  defmodule Config do
    use RGBMatrix.Effect.Config
  end

  defmodule State do
    defstruct [:led_ids]
  end

  @impl true
  def new(leds, _config) do
    {0, %State{led_ids: Enum.map(leds, & &1.id)}}
  end

  @impl true
  def render(state, _config) do
    %{led_ids: led_ids} = state

    color = random_color()

    colors = Enum.map(led_ids, fn id -> {id, color} end)

    {colors, :never, state}
  end

  defp random_color do
    HSV.new((:rand.uniform() * 360) |> trunc(), 100, 100)
  end

  @impl true
  def key_pressed(state, _config, _led) do
    {0, state}
  end
end
