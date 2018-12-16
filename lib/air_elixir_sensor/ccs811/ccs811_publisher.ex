defmodule AirElixirSensor.Ccs811.Ccs811Publisher do
  @moduledoc """
  Conveniences for reading from a DHT sensor.

  ## Examples

      iex> {:ok, dht} = AirElixirSensor.Ccs811.start_link(7)
      :ok
      iex> AirElixirSensor.Ccs811.subscribe(7, :changed)
      :ok
  """

  use AirElixirSensor.Publisher,
    default_trigger: AirElixirSensor.Ccs811.Ccs811PublisherTrigger,
    read_type: 0 | 1

  use AirElixirSensor.Ccs811, :publisher_by_python
end
