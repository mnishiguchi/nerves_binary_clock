defmodule NervesBinaryClock.BinaryClock.Test do
  @moduledoc """
  This adapter is a mock convenient for tests.

  ## Examples

      BinaryClock.Test.new
      |> Clockwork.open
      |> Clockwork.show(~T[13:35:35.926971])

  """

  defstruct [:bus_name, :time, bits: []]

  def new(bus_name \\ nil) do
    %__MODULE__{bus_name: bus_name}
  end

  defimpl NervesBinaryClock.Clockwork do
    @impl true
    def open(adapter) do
      # We do not tick in test.

      adapter
    end

    @impl true
    def show(adapter, time, _opts \\ []) do
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
end
