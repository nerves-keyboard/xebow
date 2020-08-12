defmodule RGBMatrix.Animation.Config.FieldType do
  @moduledoc """
  Provides a behaviour for defining animation configuration field types.
  """

  @type t ::
          __MODULE__.Integer.t()
          | __MODULE__.Option.t()

  @typedoc """
  `field` is a union of all the `FieldType.<field_type>` modules
  """
  @type field ::
          __MODULE__.Integer
          | __MODULE__.Option

  @typedoc """
  `value` is a union of all valid field value types
  """
  @type value ::
          __MODULE__.Integer.value()
          | __MODULE__.Option.value()

  @callback validate(t, value) :: :ok | :validation_error
  @callback cast(t, any) :: {:ok, value} | :cast_error | :validation_error
end
