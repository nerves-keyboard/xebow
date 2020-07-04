defmodule RGBMatrix.Utils do
  @moduledoc """
  Shared utility functions that are generally useful.
  """

  @doc """
  Modulo operation that supports negative numbers.

  This is effectively `mod` as it exists in most other languages. Elixir's `rem`
  doesn't act the same as other languages for negative numbers.
  """
  @spec mod(integer, integer) :: non_neg_integer
  def mod(number, modulus) when is_integer(number) and is_integer(modulus) do
    case rem(number, modulus) do
      remainder when (remainder > 0 and modulus < 0) or (remainder < 0 and modulus > 0) ->
        remainder + modulus

      remainder ->
        remainder
    end
  end
end
