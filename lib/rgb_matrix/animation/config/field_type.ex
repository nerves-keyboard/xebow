defmodule RGBMatrix.Animation.Config.FieldType do
  @moduledoc """
  Provides a behaviour for defining animation configuration field types.
  """

  @type t :: __MODULE__.Integer.t() | __MODULE__.Option.t()

  @callback validate(t, any) :: :ok | :error
  @callback cast(t, any) :: {:ok, any} | :error

  defmacro __using__(_) do
    quote do
      @behaviour RGBMatrix.Animation.Config.FieldType
    end
  end
end
