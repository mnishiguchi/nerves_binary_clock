defmodule NervesBinaryClock.BinaryClock.Dev do
  @moduledoc """
  This adapter is a mock convenient for IEx.

  ## Examples

      BinaryClock.Dev.new
      |> BinaryClock.open
      |> BinaryClock.show(~T[13:35:35.926971])

  """

  defstruct [:bus_name, :time]

  def new(bus_name \\ nil) do
    %__MODULE__{bus_name: bus_name}
  end

  defimpl NervesBinaryClock.BinaryClock do
    require Logger

    @impl true
    def open(adapter) do
      # The service layer will respond to this message.
      :timer.send_interval(1_000, :tick_binary_clock)

      adapter
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
end
