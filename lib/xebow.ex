defmodule Xebow do
  @moduledoc false

  alias Layout.{Key, LED}

  @leds [
    LED.new(:l001, 0, 0),
    LED.new(:l002, 1, 0),
    LED.new(:l003, 2, 0),
    LED.new(:l004, 0, 1),
    LED.new(:l005, 1, 1),
    LED.new(:l006, 2, 1),
    LED.new(:l007, 0, 2),
    LED.new(:l008, 1, 2),
    LED.new(:l009, 2, 2),
    LED.new(:l010, 0, 3),
    LED.new(:l011, 1, 3),
    LED.new(:l012, 2, 3)
  ]

  @keys [
    Key.new(:k001, 0, 0, led: :l001),
    Key.new(:k002, 1, 0, led: :l002),
    Key.new(:k003, 2, 0, led: :l003),
    Key.new(:k004, 0, 1, led: :l004),
    Key.new(:k005, 1, 1, led: :l005),
    Key.new(:k006, 2, 1, led: :l006),
    Key.new(:k007, 0, 2, led: :l007),
    Key.new(:k008, 1, 2, led: :l008),
    Key.new(:k009, 2, 2, led: :l009),
    Key.new(:k010, 0, 3, led: :l010),
    Key.new(:k011, 1, 3, led: :l011),
    Key.new(:k012, 2, 3, led: :l012)
  ]

  @layout Layout.new(@keys, @leds)

  @spec layout() :: Layout.t()
  def layout, do: @layout
end
