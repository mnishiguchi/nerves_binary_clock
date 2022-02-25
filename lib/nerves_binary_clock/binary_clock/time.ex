defmodule NervesBinaryClock.BinaryClock.Time do
  @moduledoc """
  The clock time core logic that translates an Elixir time to LEDs upon request.
  """

  defstruct ~w[ampm hour minute second]a

  alias NervesBinaryClock.Utils

  @type t :: %__MODULE__{
          ampm: 0 | 1,
          hour: non_neg_integer(),
          minute: non_neg_integer(),
          second: non_neg_integer()
        }

  @doc """
  Takes an Elixir time and converts that time to the accumulator struct.

  ## Examples

      iex> BinaryClock.Time.new(%{hour: 13,  minute: 34, second: 38})
      %BinaryClock.Time{ampm: 1, hour: 1, minute: 34, second: 38}

      iex> BinaryClock.Time.new(%{hour: 13,  minute: 34, second: 38})
      ...> |> BinaryClock.Time.to_leds(:none)
      [0, 1, 1, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 0]

      iex> BinaryClock.Time.new(%{hour: 13,  minute: 34, second: 38})
      ...> |> BinaryClock.Time.to_leds(:bytes)
      <<0::12, 96::12, 0::12, 0::12, 0::12, 96::12, 96::12, 0::12, 0::12, 0::12, 0::12, 0::12, 0::12, 0::12, 0::12, 0::12, 0::12, 96::12, 96::12, 0::12, 0::12, 96::12, 96::12, 0::12>>

      iex> BinaryClock.Time.new(%{hour: 13,  minute: 34, second: 38})
      ...> |> BinaryClock.Time.to_leds(:pretty)
      "-**--**----------**---*-"

  """
  @spec new(Time.t()) :: t()
  def new(%{hour: hour, minute: minute, second: second}) do
    %__MODULE__{
      ampm: hour |> div(12),
      hour: hour |> rem(12),
      minute: minute,
      second: second
    }
  end

  @doc """
  Takes a clock struct and converts it to a list of bits for the presentation.
  """
  def to_leds(%__MODULE__{} = time, format_type, opts \\ []) do
    [
      time.second |> Utils.padded_bits() |> Enum.reverse(),
      time.hour |> Utils.padded_bits() |> Enum.reverse(),
      time.ampm |> Utils.padded_bits(),
      time.minute |> Utils.padded_bits()
    ]
    |> List.flatten()
    |> Utils.formatter(format_type, opts)
  end
end
