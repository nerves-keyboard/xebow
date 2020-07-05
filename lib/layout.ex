defmodule Layout do
  @moduledoc """
  Describes a keyboard layout.
  """

  alias __MODULE__.{Key, LED}

  @type t :: %__MODULE__{
          keys: [Key.t()],
          leds: [LED.t()],
          leds_by_keys: %{atom => LED.t()},
          keys_by_leds: %{atom => Key.t()}
        }
  defstruct [:keys, :leds, :leds_by_keys, :keys_by_leds]

  def new(keys, leds \\ []) do
    leds_map = Map.new(leds, &{&1.id, &1})

    leds_by_keys =
      keys
      |> Enum.filter(& &1.led)
      |> Map.new(&{&1.id, Map.fetch!(leds_map, &1.led)})

    keys_by_leds =
      keys
      |> Enum.filter(& &1.led)
      |> Map.new(&{&1.led, &1})

    struct!(__MODULE__,
      keys: keys,
      leds: leds,
      leds_by_keys: leds_by_keys,
      keys_by_leds: keys_by_leds
    )
  end

  def keys(layout), do: layout.keys
  def leds(layout), do: layout.leds

  def led_for_key(%__MODULE__{} = layout, key_id) when is_atom(key_id),
    do: Map.get(layout.leds_by_keys, key_id)

  def key_for_led(%__MODULE__{} = layout, led_id) when is_atom(led_id),
    do: Map.get(layout.keys_by_leds, led_id)
end
