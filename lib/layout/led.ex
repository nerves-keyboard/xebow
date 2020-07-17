defmodule Layout.LED do
  @moduledoc """
  Describes a physical LED location.
  """

  @type id :: atom

  @type t :: %__MODULE__{
          id: id,
          x: number,
          y: number
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
