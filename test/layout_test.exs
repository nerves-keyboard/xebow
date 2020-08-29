defmodule LayoutTest do
  use ExUnit.Case

  alias Layout.{Key, LED}

  # The following tests use parameters defined in `config/host/test.exs`
  #
  # The following keys are defined for the test environment:
  # keys: [
  #   %{id: :k1, x: 0, y: 0, opts: [led: :l1]},
  #   %{id: :k2, x: 2, y: 1.5, opts: [width: 1.5, height: 2, led: :l2]},
  #   %{id: :k3, x: 5, y: 0}
  # ]
  #
  # The following LEDs are defined for the test environment:
  # leds: [
  #   %{id: :l1, x: 0, y: 0},
  #   %{id: :l2, x: 2, y: 1.5},
  #   %{id: :l3, x: 3, y: 3}
  # ]
  test "Layout.load_from_config/0 loads the layout defined in the application config" do
    assert Layout.load_from_config() == %Layout{
             keys: [
               %Key{height: 1, id: :k1, led: :l1, width: 1, x: 0, y: 0},
               %Key{height: 2, id: :k2, led: :l2, width: 1.5, x: 2, y: 1.5},
               %Key{height: 1, id: :k3, led: nil, width: 1, x: 5, y: 0}
             ],
             keys_by_leds: %{
               l1: %Key{height: 1, id: :k1, led: :l1, width: 1, x: 0, y: 0},
               l2: %Key{height: 2, id: :k2, led: :l2, width: 1.5, x: 2, y: 1.5}
             },
             leds: [
               %LED{id: :l1, x: 0, y: 0},
               %LED{id: :l2, x: 2, y: 1.5},
               %LED{id: :l3, x: 3, y: 3}
             ],
             leds_by_keys: %{
               k1: %LED{id: :l1, x: 0, y: 0},
               k2: %LED{id: :l2, x: 2, y: 1.5}
             }
           }
  end

  defp add_layout(_context) do
    [layout: Layout.load_from_config()]
  end

  defp add_keys(%{layout: layout}) do
    [keys: layout.keys]
  end

  defp add_leds(%{layout: layout}) do
    [leds: layout.leds]
  end

  setup [:add_layout, :add_keys, :add_leds]

  test "new/1 takes only a list of keys and returns a %Layout{} struct" do
    keys = [Key.new(:k, 0, 0)]

    assert Layout.new(keys) == %Layout{
             keys: [%Key{height: 1, id: :k, led: nil, width: 1, x: 0, y: 0}],
             keys_by_leds: %{},
             leds: [],
             leds_by_keys: %{}
           }
  end

  test "new/2 takes a list of keys and a list of LEDs and returns a %Layout{} struct" do
    keys = [Key.new(:k1, 0, 0), Key.new(:k2, 1, 0, led: :l2)]
    leds = [LED.new(:l1, 0, 0), LED.new(:l2, 1, 0)]

    assert Layout.new(keys, leds) == %Layout{
             keys: [
               %Layout.Key{height: 1, id: :k1, led: nil, width: 1, x: 0, y: 0},
               %Layout.Key{height: 1, id: :k2, led: :l2, width: 1, x: 1, y: 0}
             ],
             keys_by_leds: %{
               l2: %Layout.Key{height: 1, id: :k2, led: :l2, width: 1, x: 1, y: 0}
             },
             leds: [
               %Layout.LED{id: :l1, x: 0, y: 0},
               %Layout.LED{id: :l2, x: 1, y: 0}
             ],
             leds_by_keys: %{
               k2: %Layout.LED{id: :l2, x: 1, y: 0}
             }
           }
  end

  test "keys/1 takes a layout and returns its list of keys",
       %{keys: keys, layout: layout} do
    assert Layout.keys(layout) == keys
    assert Layout.keys(layout) == layout.keys
  end

  test "leds/1 takes a layout and returns its list of LEDs",
       %{layout: layout, leds: leds} do
    assert Layout.leds(layout) == leds
    assert Layout.leds(layout) == layout.leds
  end

  test "led_for_key/2 takes a layout and a key id and returns the corresponding LED or nil",
       %{layout: layout, leds: leds} do
    led_for_k1 = Enum.find(leds, fn %{id: id} -> id == :l1 end)
    led_for_k3 = nil
    assert Layout.led_for_key(layout, :k1) == led_for_k1
    assert Layout.led_for_key(layout, :k3) == led_for_k3
  end

  test "key_for_led/2 takes a layout and a LED id and returns the corresponding key or nil",
       %{keys: keys, layout: layout} do
    key_for_l1 = Enum.find(keys, fn %{led: led} -> led == :l1 end)
    key_for_l3 = nil
    assert Layout.key_for_led(layout, :l1) == key_for_l1
    assert Layout.key_for_led(layout, :l3) == key_for_l3
  end
end
