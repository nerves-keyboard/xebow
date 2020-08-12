defmodule RGBMatrix.Animation.Config.FieldType.Integer do
  @moduledoc """
  An integer field type for use in animation configuration.

  Supports defining a minimum and a maximum, as well as a step value.

  To define an integer field in an animation, specify `:integer` as the field
  type.

  Example:
      field :speed, :integer,
        default: 4,
        min: 0,
        max: 32,
        doc: [
          name: "Speed",
          description: \"""
          Controls the speed at which the wave moves across the matrix.
          \"""
        ]
  """

  @behaviour RGBMatrix.Animation.Config.FieldType

  import RGBMatrix.Utils, only: [mod: 2]

  @enforce_keys [:default, :min, :max]
  @optional_keys [step: 1, doc: []]
  defstruct @enforce_keys ++ @optional_keys

  @type t :: %__MODULE__{
          default: integer,
          min: integer,
          max: integer,
          doc: keyword(String.t()) | []
        }
  @type value :: integer

  @impl true
  @spec validate(field_type :: t, value) :: :ok | :validation_error
  def validate(field_type, value) do
    if value >= field_type.min &&
         value <= field_type.max &&
         mod(value - field_type.min, field_type.step) == 0 do
      :ok
    else
      :validation_error
    end
  end

  @impl true
  @spec cast(field_type :: t, any) ::
          {:ok, value} | :cast_error | :validation_error
  def cast(field_type, value) do
    with {:ok, casted_value} <- do_cast(value),
         :ok <- validate(field_type, casted_value) do
      {:ok, casted_value}
    else
      :validation_error = e -> e
      :error -> :cast_error
    end
  end

  defp do_cast(value) when is_integer(value) do
    {:ok, value}
  end

  defp do_cast(value) when is_float(value) do
    {:ok, trunc(value)}
  end

  defp do_cast(value) when is_binary(value) do
    case Integer.parse(value) do
      {parsed_value, _remaining_string} -> {:ok, parsed_value}
      :error -> :error
    end
  end

  defp do_cast(_) do
    :error
  end
end
