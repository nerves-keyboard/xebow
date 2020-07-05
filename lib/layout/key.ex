defmodule Layout.Key do
  @moduledoc """
  Describes a physical key and its location.
  """

  @type t :: %__MODULE__{
          id: atom,
          x: float,
          y: float,
          width: float,
          height: float,
          led: atom
        }
  defstruct [:id, :x, :y, :width, :height, :led]

  def new(id, x, y, opts \\ []) do
    struct!(__MODULE__,
      id: id,
      x: x,
      y: y,
      width: Keyword.get(opts, :width, 1),
      height: Keyword.get(opts, :height, 1),
      led: Keyword.get(opts, :led)
    )
  end
end
