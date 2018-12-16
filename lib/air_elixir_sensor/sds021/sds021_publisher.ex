defmodule AirElixirSensor.Sds021.Sds021Publisher do
  @moduledoc """
  Conveniences for reading from a DHT sensor.

  ## Examples

      iex> {:ok, dht} = AirElixirSensor.Sds021.start_link(7)
      :ok
      iex> AirElixirSensor.Sds021.subscribe(7, :changed)
      :ok
  """

  use AirElixirSensor.Publisher,
    default_trigger: AirElixirSensor.Sds021.Sds021PublisherTrigger,
    read_type: 0 | 1

  use AirElixirSensor.Sds021, :publisher_by_python
end
