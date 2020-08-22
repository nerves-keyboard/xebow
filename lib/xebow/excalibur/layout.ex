defmodule Xebow.Excalibur.Layout do
  @moduledoc """
  Defines the physical layout of the Excalibur keyboard.
  """

  alias Layout.Key

  @keys [
    Key.new(:k001, 0, 0),
    Key.new(:k002, 1, 0),
    Key.new(:k003, 2, 0),
    Key.new(:k004, 3, 0),
    Key.new(:k005, 4, 0),
    Key.new(:k006, 5, 0),
    Key.new(:k007, 6, 0),
    Key.new(:k008, 7, 0),
    Key.new(:k009, 8, 0),
    Key.new(:k010, 9, 0),
    Key.new(:k011, 10, 0),
    Key.new(:k012, 11, 0),
    Key.new(:k013, 12, 0),
    Key.new(:k014, 13.5, 0, width: 2),
    Key.new(:k015, 15.25, 0),
    Key.new(:k016, 16.25, 0),
    #
    Key.new(:k017, 0.25, 1, width: 1.5),
    Key.new(:k018, 1.5, 1),
    Key.new(:k019, 2.5, 1),
    Key.new(:k020, 3.5, 1),
    Key.new(:k021, 4.5, 1),
    Key.new(:k022, 5.5, 1),
    Key.new(:k023, 6.5, 1),
    Key.new(:k024, 7.5, 1),
    Key.new(:k025, 8.5, 1),
    Key.new(:k026, 9.5, 1),
    Key.new(:k027, 10.5, 1),
    Key.new(:k028, 11.5, 1),
    Key.new(:k029, 12.5, 1),
    Key.new(:k030, 13.75, 1, width: 1.5),
    Key.new(:k031, 15.25, 1),
    Key.new(:k032, 16.25, 1),
    #
    Key.new(:k033, 0.375, 2, width: 1.75),
    Key.new(:k034, 1.75, 2),
    Key.new(:k035, 2.75, 2),
    Key.new(:k036, 3.75, 2),
    Key.new(:k037, 4.75, 2),
    Key.new(:k038, 5.75, 2),
    Key.new(:k039, 6.75, 2),
    Key.new(:k040, 7.75, 2),
    Key.new(:k041, 8.75, 2),
    Key.new(:k042, 9.75, 2),
    Key.new(:k043, 10.75, 2),
    Key.new(:k044, 11.75, 2),
    Key.new(:k045, 13.375, 2, width: 2.25),
    #
    Key.new(:k046, 0.625, 3, width: 2.25),
    Key.new(:k047, 2.25, 3),
    Key.new(:k048, 3.25, 3),
    Key.new(:k049, 4.25, 3),
    Key.new(:k050, 5.25, 3),
    Key.new(:k051, 6.25, 3),
    Key.new(:k052, 7.25, 3),
    Key.new(:k053, 8.25, 3),
    Key.new(:k054, 9.25, 3),
    Key.new(:k055, 10.25, 3),
    Key.new(:k056, 11.25, 3),
    Key.new(:k057, 13.125, 3, width: 2.75),
    Key.new(:k058, 15.25, 3),
    #
    Key.new(:k059, 0.125, 4, width: 1.25),
    Key.new(:k060, 1.375, 4, width: 1.25),
    Key.new(:k061, 2.625, 4, width: 1.25),
    Key.new(:k062, 6.375, 4, width: 6.25),
    Key.new(:k063, 10.125, 4, width: 1.25),
    Key.new(:k064, 11.375, 4, width: 1.25),
    Key.new(:k065, 12.625, 4, width: 1.25),
    Key.new(:k066, 14.25, 4),
    Key.new(:k067, 15.25, 4),
    Key.new(:k068, 16.25, 4)
  ]

  @layout Layout.new(@keys)

  @spec layout() :: Layout.t()
  def layout, do: @layout
end
