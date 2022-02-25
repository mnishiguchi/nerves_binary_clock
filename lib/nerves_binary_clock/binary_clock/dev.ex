defmodule NervesBinaryClock.BinaryClock.Dev do
  @moduledoc """
  This adapter is a mock convenient for IEx.

  ## Examples

      alias NervesBinaryClock.Clockwork
      alias NervesBinaryClock.BinaryClock

      clock = Clockwork.open(BinaryClock.Dev.new)
      clock = Clockwork.show(clock, time: ~T[13:35:35.926971])
      Clockwork.close(clock)

  """

  defstruct [:bus_name, :cancel_timer_fn, :time]

  alias NervesBinaryClock.BinaryClock

  def new(bus_name \\ nil) do
    %__MODULE__{bus_name: bus_name}
  end

  defimpl NervesBinaryClock.Clockwork do
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
      |> log
    end

    defp log(adapter) do
      face =
        adapter.time
        |> BinaryClock.ClockTime.new()
        |> BinaryClock.ClockTime.to_leds(:pretty)

      Logger.debug("Clock face: #{face}")

      adapter
    end

    @impl true
    def close(adapter) do
      {:ok, :cancel} = adapter.cancel_timer_fn.()
      :ok
    end
  end
end
