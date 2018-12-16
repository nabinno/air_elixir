defmodule AirElixirSensor.Subscriber do
  @moduledoc false

  @type event :: atom
  @type package :: any
  @type registration :: {AirElixir.pin() | AirElixir.port_path(), event}
  @type message :: {AirElixir.pin() | AirElixir.port_path(), event, package}

  @spec start_link(Registry.registry()) :: Supervisor.on_start()
  def start_link(prefix, opts \\ []) do
    opts
    |> Keyword.put(:id, :subscriber_registry)
    |> Keyword.put(:keys, :duplicate)
    |> Keyword.put(:name, registry(prefix))
    |> Registry.start_link()
  end

  @spec dispatch_change(atom, message) :: :ok
  def dispatch_change(prefix, {pin_or_port, event, _} = message) do
    Registry.dispatch(registry(prefix), {pin_or_port, event}, fn listeners ->
      for {pid, :ok} <- listeners, do: send(pid, message)
    end)
  end

  @spec subscribe(atom, registration) :: :ok | {:error, {:already_registered, pid}}
  def subscribe(prefix, message) do
    Registry.register(registry(prefix), message, :ok)
  end

  defp registry(prefix) do
    String.to_atom("#{prefix}.#{__MODULE__}")
  end
end
