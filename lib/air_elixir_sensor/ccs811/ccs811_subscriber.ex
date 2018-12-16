defmodule AirElixirSensor.Ccs811.Ccs811Subscriber do
  @moduledoc false

  use GenServer
  alias AirElixirSensor.Subscriber
  require Logger

  def start_link(address, prefix) do
    GenServer.start_link(__MODULE__, [address, prefix])
  end

  def init([address, prefix]) do
    Subscriber.subscribe(prefix, {address, :changed})
    {:ok, %{address: address}}
  end

  def handle_info({_address, :changed, %{co2: co2, tvoc: tvoc}}, state) do
    Cachex.transaction!(:current_air, ["co2", "tvoc"], fn cache ->
      tvoc =
        if tvoc != nil && Cachex.get!(cache, "tvoc") != nil,
          do: (Cachex.get!(cache, "tvoc") + tvoc) / 2,
          else: tvoc

      Cachex.put_many(cache, [{"co2", co2}, {"tvoc", tvoc}])
    end)

    # Logger.info("CO2: #{co2}; TVOC: #{tvoc}")
    {:noreply, state}
  end

  def handle_info(_message, state) do
    {:noreply, state}
  end
end
