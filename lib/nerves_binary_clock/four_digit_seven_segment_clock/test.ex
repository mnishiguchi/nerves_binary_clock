defmodule NervesBinaryClock.FourDigitSevenSegmentClock.Test do
  @moduledoc """
  This adapter is a mock convenient for tests.
  """

  defstruct [
    :bus_name,
    :time,
    bits: []
  ]

  alias NervesBinaryClock.FourDigitSevenSegmentClock

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
    def show(adapter, opts \\ []) do
      time = opts[:time] || NaiveDateTime.local_now()

      adapter
      |> struct!(time: time)
      |> concat_bits(opts)
    end

    defp concat_bits(adapter, opts) do
      bits = FourDigitSevenSegmentClock.ClockTime.to_leds(adapter.time, :none, opts)

      # `:bits` accumulates consecutive clock readings.
      %{adapter | bits: [bits | adapter.bits]}
    end

    @impl true
    def close(adapter) do
      adapter.cancel_timer_fn.()
      :ok
    end
  end
end
