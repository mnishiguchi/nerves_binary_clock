defmodule HelloNervesClock.FourDigitSevenSegmentClock.Target do
  @moduledoc """
  This adapter physically opens the bus and sends the bytes representing the clock face.
  """

  defstruct [
    :bus_name,
    :cancel_timer_fn,
    :spi,
    :time
  ]

  alias HelloNervesClock.FourDigitSevenSegmentClock

  def new(bus_name \\ nil) do
    %__MODULE__{bus_name: bus_name}
  end

  defimpl HelloNervesClock.Clockwork do
    @impl true
    def open(adapter) do
      # The service layer will respond to this message.
      {:ok, timer} = :timer.send_interval(1_000, :tick_clockwork)
      cancel_timer_fn = fn -> :timer.cancel(timer) end

      bus_name = adapter.bus_name || hd(Circuits.SPI.bus_names())
      {:ok, spi} = Circuits.SPI.open(bus_name)

      %{adapter | bus_name: bus_name, cancel_timer_fn: cancel_timer_fn, spi: spi}
    end

    @impl true
    def show(adapter, opts \\ []) do
      time = opts[:time] || NaiveDateTime.local_now()

      adapter
      |> struct!(time: time)
      |> transfer(opts)
    end

    defp transfer(adapter, opts) do
      bytes = FourDigitSevenSegmentClock.ClockTime.to_leds(adapter.time, :pretty, opts)

      Circuits.SPI.transfer!(adapter.spi, bytes)

      adapter
    end

    @impl true
    def close(adapter) do
      {:ok, :cancel} = adapter.cancel_timer_fn.()
      :ok
    end
  end
end
