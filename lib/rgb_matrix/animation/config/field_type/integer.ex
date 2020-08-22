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
          step: integer,
          doc: keyword(String.t()) | []
        }
  @type value :: integer

  @impl true
  @spec validate(field_type :: t, value) :: :ok | {:error, :invalid_value}
  def validate(field_type, value) do
    if value >= field_type.min &&
         value <= field_type.max &&
         mod(value - field_type.min, field_type.step) == 0 do
      :ok
    else
      {:error, :invalid_value}
    end
  end

  @impl true
  @spec cast(field_type :: t, any) ::
          {:ok, value} | {:error, :wrong_type | :invalid_value}
  def cast(field_type, value) do
    with {:ok, casted_value} <- do_cast(value),
         :ok <- validate(field_type, casted_value) do
      {:ok, casted_value}
    else
      {:error, :invalid_value} = e -> e
      :error -> {:error, :wrong_type}
    end
  end

  defp do_cast(value) when is_integer(value) do
    {:ok, value}
  end

  defp do_cast(value) when is_float(value) do
    :error
  end

  defp do_cast(value) when is_binary(value) do
    case Integer.parse(value) do
      {parsed_value, ""} -> {:ok, parsed_value}
      {_, _} -> :error
      :error -> :error
    end
  end

  defp do_cast(_) do
    :error
  end
end
