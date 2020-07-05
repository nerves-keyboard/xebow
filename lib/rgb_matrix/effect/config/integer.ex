defmodule RGBMatrix.Effect.Config.Integer do
  @enforce_keys [:default, :min, :max]
  defstruct [:default, :min, :max, step: 1]

  import RGBMatrix.Utils, only: [mod: 2]

  def validate(integer, value) do
    if value >= integer.min &&
         value <= integer.max &&
         mod(value, integer.step) == 0 do
      :ok
    else
      :error
    end
  end

  def cast(integer, bin_value) when is_binary(bin_value) do
    case Integer.parse(bin_value) do
      {value, ""} ->
        cast(integer, value)

      _else ->
        case Float.parse(bin_value) do
          {value, ""} -> cast(integer, value)
          _else -> :error
        end
    end
  end

  def cast(integer, value) when is_float(value) do
    int_value = trunc(value)

    if int_value == value do
      cast(integer, int_value)
    else
      :error
    end
  end

  def cast(integer, value) when is_integer(value) do
    case validate(integer, value) do
      :ok -> {:ok, value}
      :error -> :error
    end
  end

  def cast(_integer, _value), do: :error
end
