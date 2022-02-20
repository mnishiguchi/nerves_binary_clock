defmodule NervesBinaryClock.BinaryClock.Dev do
  @moduledoc """
  The `NervesBinaryClock.BinaryClock.Dev` adapter is a mock convenient for IEx.
  """

  @behaviour NervesBinaryClock.BinaryClock

  require Logger

  defstruct [:time]

  @impl true
  def open(_bus_name \\ nil) do
    # The service layer will respond to this message.
    :timer.send_interval(1_000, :tick_binary_clock)

    %__MODULE__{}
  end

  @impl true
  def show(adapter, time) do
    adapter
    |> struct!(time: time)
    |> log
  end

  defp log(adapter) do
    face =
      adapter.time
      |> NervesBinaryClock.BinaryTime.new()
      |> NervesBinaryClock.BinaryTime.to_leds(:pretty)

    Logger.debug("Clock face: #{face}")

    adapter
  end
end
