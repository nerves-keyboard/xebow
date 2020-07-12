defmodule RGBMatrix.Animation.RandomSolid do
  @moduledoc """
  A random solid color fills the entire matrix and changes every key-press.
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

    {:never, colors, state}
  end

  defp random_color do
    HSV.new((:rand.uniform() * 360) |> trunc(), 100, 100)
  end

  @impl true
  def interact(state, _config, _led) do
    {0, state}
  end
end
