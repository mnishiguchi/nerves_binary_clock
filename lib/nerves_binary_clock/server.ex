defmodule NervesBinaryClock.Server do
  @moduledoc """
  The service layer that processes periodic requests for time and delegates the task of showing the
  local time to configurable adapter layers.
  """

  use GenServer

  defstruct [:binary_clock, :brightness]

  @default_spi_bus_name "spidev0.0"
  @default_brightness 0x060

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def brightness(), do: GenServer.call(__MODULE__, :brightness)

  def set_brightness(value), do: GenServer.cast(__MODULE__, {:set_brightness, value})

  @impl true
  def init(opts) do
    bus_name = opts[:spi_bus_name] || @default_spi_bus_name
    binary_clock_mod = opts[:binary_clock_mod] || NervesBinaryClock.BinaryClock.Dev
    brightness = opts[:brightness] || @default_brightness

    binary_clock = init_binary_clock(binary_clock_mod, bus_name)

    state = %__MODULE__{
      binary_clock: binary_clock,
      brightness: brightness
    }

    {:ok, state}
  end

  @impl true
  def handle_info(:tick_binary_clock, state) do
    binary_clock = advence_binary_clock(state.binary_clock, state.brightness)

    {:noreply, %{state | binary_clock: binary_clock}}
  end

  @impl true
  def handle_cast({:set_brightness, value}, state) do
    {:noreply, %{state | brightness: value}}
  end

  @impl true
  def handle_call(:brightness, _from, state) do
    {:reply, state.brightness, state}
  end

  defp init_binary_clock(binary_clock_mod, bus_name) do
    binary_clock = binary_clock_mod.new(bus_name) |> NervesBinaryClock.BinaryClock.open()
    %{__struct__: ^binary_clock_mod} = binary_clock
  end

  defp advence_binary_clock(binary_clock, brightness) do
    NervesBinaryClock.BinaryClock.show(binary_clock, local_time(), brightness: brightness)
  end

  defp local_time() do
    NaiveDateTime.local_now()
  end
end
