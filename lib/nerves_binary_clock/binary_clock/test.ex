defmodule NervesBinaryClock.BinaryClock.Test do
  @moduledoc """
  The `NervesBinaryClock.BinaryClock.Test` adapter is a mock convenient for tests.

  ## Examples

      iex> BinaryClock.Test.open() |> BinaryClock.Test.show(~T[17:06:40.107983])
      %NervesBinaryClock.BinaryClock.Test{
        bits: [
          [0, 0, 0, 1, 0, 1, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 1, 0]
        ],
        time: ~T[17:06:40.107983]
      }

  """

  @behaviour NervesBinaryClock.BinaryClock

  defstruct [:time, bits: []]

  @impl true
  def open(_bus_name \\ nil) do
    # We do not tick in test.

    %__MODULE__{}
  end

  @impl true
  def show(adapter, time) do
    adapter
    |> struct!(time: time)
    |> concat_bits
  end

  defp concat_bits(adapter) do
    bits =
      adapter.time
      |> NervesBinaryClock.BinaryTime.new()
      |> NervesBinaryClock.BinaryTime.to_leds(:none)

    # `:bits` accumulates consecutive clock readings.
    %{adapter | bits: [bits | adapter.bits]}
  end
end
