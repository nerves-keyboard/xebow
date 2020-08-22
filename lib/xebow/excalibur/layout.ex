defmodule Xebow.Excalibur.Layout do
  @moduledoc """
  Defines the physical layout of the Excalibur keyboard.
  """

  alias Layout.Key

  @keys [
    Key.new(:k001, 0, 0),
    Key.new(:k002, 1, 0),
    Key.new(:k003, 2, 0),
    Key.new(:k004, 0, 1),
    Key.new(:k005, 1, 1),
    Key.new(:k006, 2, 1),
    Key.new(:k007, 0, 2),
    Key.new(:k008, 1, 2),
    Key.new(:k009, 2, 2),
    Key.new(:k010, 0, 3)
  ]

  @layout Layout.new(@keys)

  @spec layout() :: Layout.t()
  def layout, do: @layout
end
