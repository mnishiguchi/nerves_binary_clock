defmodule NervesBinaryClock.Server do
  @moduledoc """
  The service layer that processes periodic requests for time and delegates the task of showing the
  local time to configurable adapter layers.
  """

  use GenServer

  defstruct [:clockwork, :brightness]

  @default_brightness 0x060

  @type clockwork_mod ::
          NervesBinaryClock.BinaryClock.Dev
          | NervesBinaryClock.BinaryClock.Target
          | NervesBinaryClock.BinaryClock.Test

  @type option ::
          {:spi_bus_name, String.t()}
          | {:clockwork_mod, clockwork_mod}
          | {:brightness, 0x000..0xFFF}

  @spec start_link([option]) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec brightness :: 0x000..0xFFF
  def brightness(), do: GenServer.call(__MODULE__, :brightness)

  @spec set_brightness(0x000..0xFFF) :: :ok
  def set_brightness(value), do: GenServer.cast(__MODULE__, {:set_brightness, value})

  @impl true
  def init(opts) do
    bus_name = opts[:spi_bus_name]
    clockwork_mod = opts[:clockwork_mod] || NervesBinaryClock.BinaryClock.Dev
    brightness = opts[:brightness] || @default_brightness

    clockwork = init_wall_clock(clockwork_mod, bus_name)

    state = %__MODULE__{
      clockwork: clockwork,
      brightness: brightness
    }

    {:ok, state}
  end

  @impl true
  def handle_info(:tick_clockwork, state) do
    clockwork = advance_time(state.clockwork, state.brightness)

    {:noreply, %{state | clockwork: clockwork}}
  end

  @impl true
  def handle_cast({:set_brightness, value}, state) do
    {:noreply, %{state | brightness: value}}
  end

  @impl true
  def handle_call(:brightness, _from, state) do
    {:reply, state.brightness, state}
  end

  defp init_wall_clock(clockwork_mod, bus_name) do
    clockwork = clockwork_mod.new(bus_name) |> NervesBinaryClock.Clockwork.open()
    %{__struct__: ^clockwork_mod} = clockwork
  end

  defp advance_time(clockwork, brightness) do
    NervesBinaryClock.Clockwork.show(clockwork, local_time(), brightness: brightness)
  end

  defp local_time() do
    NaiveDateTime.local_now()
  end
end
