defmodule NervesBinaryClock.BinaryClock.Dev do
  @moduledoc """
  This adapter is a mock convenient for IEx.

  ## Examples

      BinaryClock.Dev.new
      |> Clockwork.open
      |> Clockwork.show(~T[13:35:35.926971])

  """

  defstruct [:bus_name, :time]

  alias NervesBinaryClock.BinaryClock

  def new(bus_name \\ nil) do
    %__MODULE__{bus_name: bus_name}
  end

  defimpl NervesBinaryClock.Clockwork do
    require Logger

    @impl true
    def open(adapter) do
      # The service layer will respond to this message.
      :timer.send_interval(1_000, :tick_clockwork)

      adapter
    end

    @impl true
    def show(adapter, time, _opts \\ []) do
      adapter
      |> struct!(time: time)
      |> log
    end

    defp log(adapter) do
      face =
        adapter.time
        |> BinaryClock.Time.new()
        |> BinaryClock.Time.to_leds(:pretty)

      Logger.debug("Clock face: #{face}")

      adapter
    end
  end
end
