defmodule AirElixirSensor.Sds021.Sds021Subscriber do
  @moduledoc false

  use GenServer
  alias AirElixirSensor.Subscriber
  require Logger

  def start_link(pin, prefix) do
    GenServer.start_link(__MODULE__, [pin, prefix])
  end

  def init([pin, prefix]) do
    Subscriber.subscribe(prefix, {pin, :changed})
    {:ok, %{pin: pin}}
  end

  def handle_info({_pin, :changed, %{pm25: pm25, pm10: pm10}}, state) do
    Cachex.transaction!(:current_air, ["pm25", "pm10"], fn cache ->
      Cachex.put_many(cache, [{"pm25", pm25}, {"pm10", pm10}])
    end)

    # Logger.info("PM2.5: #{pm25}; PM10: #{pm10}")
    {:noreply, state}
  end

  def handle_info(_message, state) do
    {:noreply, state}
  end
end
