defmodule RGBMatrix.Animation.Config.FieldType.Option do
  @moduledoc """
  An option field type for use in animation configuration.

  Supports defining a list of pre-defined options as atoms.
  """

  @behaviour RGBMatrix.Animation.Config.FieldType

  @enforce_keys [:default, :options]
  @optional_keys [doc: []]
  defstruct @enforce_keys ++ @optional_keys

  @type t :: %__MODULE__{
          default: atom,
          options: [atom],
          doc: keyword(String.t()) | []
        }

  @impl true
  @spec validate(field_type :: t, value :: atom) :: :ok | :error
  def validate(%__MODULE__{options: options}, value) do
    if value in options do
      :ok
    else
      :error
    end
  end

  @impl true
  @spec cast(field_type :: t, value :: any) :: {:ok, atom} | :error
  def cast(field_type, value) do
    with {:ok, casted_value} <- do_cast(value),
         :ok <- validate(field_type, casted_value) do
      {:ok, casted_value}
    else
      :error -> :error
    end
  end

  defp do_cast(binary_value) when is_binary(binary_value) do
    try do
      {:ok, String.to_existing_atom(binary_value)}
    rescue
      ArgumentError -> :error
    end
  end

  defp do_cast(value) when is_atom(value), do: {:ok, value}

  defp do_cast(_value), do: :error
end
