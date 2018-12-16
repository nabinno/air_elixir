defmodule AirElixir.Application do
  use Application
  import Supervisor.Spec

  def start(
        _type,
        [
          prefix,
          %{
            dht11: [dht11_pin],
            sds021: [sds021_port],
            ccs811: [ccs811_address]
          } = sensors
        ]
      ) do
    Supervisor.start_link(
      [
        supervisor(AirElixirSensor.Subscriber, [prefix]),
        supervisor(AirElixirSensor.Registry, [prefix]),
        supervisor(AirElixirSensor.PythonErlport, [sensors, prefix]),
        supervisor(Cachex, [:current_air, []]),
        worker(AirElixir.GoogleSpreadsheets, [
          :current_air,
          [prefix: prefix, poll_interval: 1_200_000]
        ]),

        # DHT11
        worker(AirElixirSensor.Dht11.Dht11Publisher, [
          dht11_pin,
          [prefix: prefix, poll_interval: 3_000]
        ]),
        worker(AirElixirSensor.Dht11.Dht11Subscriber, [dht11_pin, prefix]),

        # SDS021
        worker(AirElixirSensor.Sds021.Sds021Publisher, [
          sds021_port,
          [prefix: prefix, poll_interval: 3_000]
        ]),
        worker(AirElixirSensor.Sds021.Sds021Subscriber, [sds021_port, prefix]),

        # CCS811
        worker(AirElixirSensor.Ccs811.Ccs811Publisher, [
          ccs811_address,
          [prefix: prefix, poll_interval: 3_000]
        ]),
        worker(AirElixirSensor.Ccs811.Ccs811Subscriber, [ccs811_address, prefix])
      ],
      strategy: :one_for_one,
      name: name(prefix)
    )
  end

  defp name(prefix) do
    String.to_atom("#{prefix}.#{__MODULE__}")
  end
end
