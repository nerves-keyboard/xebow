defmodule Layout.LED do
  @moduledoc """
  Describes a physical LED location.
  """

  @type t :: %__MODULE__{
          id: atom,
          x: float,
          y: float
        }
  defstruct [:id, :x, :y]

  def new(id, x, y) do
    struct!(__MODULE__,
      id: id,
      x: x,
      y: y
    )
  end
end
