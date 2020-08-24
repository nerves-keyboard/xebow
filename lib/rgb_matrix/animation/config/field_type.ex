defmodule RGBMatrix.Animation.Config.FieldType do
  @moduledoc """
  Provides a behaviour for defining animation configuration field types.
  """

  @typedoc """
  A field struct, containing all defined config information for that specific
  field.
  """
  @type t :: __MODULE__.Integer.t() | __MODULE__.Option.t()

  @typedoc """
  The possible error atoms during validation and update of configs
  """
  @type error ::
          :invalid_value
          | :undefined_field
          | :wrong_type

  @typedoc """
  Module names for defined field types
  """
  @type submodule :: __MODULE__.Integer | __MODULE__.Option

  @typedoc """
  A value which is appropriate for a defined field and does not require casting
  to be used for config creation or update.
  """
  @type value :: __MODULE__.Integer.value() | __MODULE__.Option.value()

  @callback validate(t, value) :: :ok | {:error, :invalid_value}
  @callback cast(t, any) :: {:ok, value} | {:error, :wrong_type | :invalid_value}
end
