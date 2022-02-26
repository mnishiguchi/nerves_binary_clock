defmodule HelloNervesClock.FourDigitSevenSegmentClock.Dev do
  @moduledoc """
  This adapter is a mock convenient for IEx.

  ## Examples

      alias HelloNervesClock.Clockwork
      alias HelloNervesClock.FourDigitSevenSegmentClock

      clock = Clockwork.open(FourDigitSevenSegmentClock.Dev.new)
      clock = Clockwork.show(clock)
      :ok = Clockwork.close(clock)

  """

  defstruct [
    :bus_name,
    :cancel_timer_fn,
    :time
  ]

  alias HelloNervesClock.FourDigitSevenSegmentClock

  def new(bus_name \\ nil) do
    %__MODULE__{bus_name: bus_name}
  end

  defimpl HelloNervesClock.Clockwork do
    require Logger

    @impl true
    def open(adapter) do
      # The service layer will respond to this message.
      {:ok, timer} = :timer.send_interval(1_000, :tick_clockwork)
      cancel_timer_fn = fn -> :timer.cancel(timer) end

      %{adapter | cancel_timer_fn: cancel_timer_fn}
    end

    @impl true
    def show(adapter, opts \\ []) do
      time = opts[:time] || NaiveDateTime.local_now()

      adapter
      |> struct!(time: time)
      |> log(opts)
    end

    defp log(adapter, opts) do
      clock_face = FourDigitSevenSegmentClock.ClockTime.to_leds(adapter.time, :pretty, opts)

      Logger.debug("Clock face: #{clock_face}")

      adapter
    end

    @impl true
    def close(adapter) do
      {:ok, :cancel} = adapter.cancel_timer_fn.()
      :ok
    end
  end
end
