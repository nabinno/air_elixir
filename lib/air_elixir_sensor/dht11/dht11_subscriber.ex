defmodule AirElixirSensor.Dht11.Dht11Subscriber do
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

  def handle_info({_pin, :changed, %{temp: temp, humidity: humidity}}, state) do
    Cachex.transaction!(:current_air, ["temp", "humidity"], fn cache ->
      Cachex.put_many(cache, [{"temp", temp}, {"humidity", humidity}])
    end)

    # Logger.info("Temp: #{temp}C; Humidity: #{humidity}%")
    {:noreply, state}
  end

  def handle_info(_message, state) do
    {:noreply, state}
  end
end
