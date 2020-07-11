defmodule Layout.LED do
  @moduledoc """
  Describes a physical LED location.
  """

  @type id :: atom

  @type t :: %__MODULE__{
          id: id,
          x: float,
          y: float
        }
  defstruct [:id, :x, :y]

  def new(id, x, y) do
    %__MODULE__{
      id: id,
      x: x,
      y: y
    }
  end
end
