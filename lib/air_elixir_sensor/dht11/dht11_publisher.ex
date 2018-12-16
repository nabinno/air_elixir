defmodule AirElixirSensor.Dht11.Dht11Publisher do
  @moduledoc """
  Conveniences for reading from a DHT sensor.

  ## Examples

      iex> {:ok, dht} = AirElixirSensor.Dht11.start_link(7)
      :ok
      iex> AirElixirSensor.Dht11.subscribe(7, :changed)
      :ok
  """

  use AirElixirSensor.Publisher,
    default_trigger: AirElixirSensor.Dht11.Dht11PublisherTrigger,
    read_type: 0 | 1

  use AirElixirSensor.Dht11, :publisher_by_python
end
