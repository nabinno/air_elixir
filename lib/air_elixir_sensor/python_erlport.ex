defmodule AirElixirSensor.PythonErlport do
  @moduledoc """
  Low-level interface for sending raw requests and receiving responses from a AirElixir hat. Create one of these first
  and then use one of the other AirElixir modules for interacting with a connected sensor.
  """

  use GenServer
  alias AirElixirSensor.Registry

  @doc false
  @spec start_link(map, atom) :: {:ok, pid} | {:error, any}
  def start_link(sensors, prefix \\ Default) do
    GenServer.start_link(__MODULE__, [sensors], name: Registry.name(prefix, :python))
  end

  def call(prefix, {_mod, _func, _args} = message),
    do: GenServer.call(Registry.name(prefix, :python), [message])

  def call(_prefix, _message), do: nil

  #
  # Server
  #
  def init([sensors]) do
    case pystart() do
      {:ok, pid} ->
        sensors
        |> Enum.each(fn {mod, args} ->
          pycall(pid, mod, :register, [pid] ++ args)
        end)

        {:ok, pid}

      {_, _} ->
        nil
    end
  end

  def handle_call([{mod, func, args} = _message], _from, session) do
    result = pycall(session, mod, func, args)
    {:reply, result, session}
  end

  def handle_info(_message, session) do
    {:noreply, session}
  end

  #
  # Helpers
  #
  def pystart() do
    erlport_path = [:code.priv_dir(:air_elixir), "python"] |> Path.join() |> to_charlist
    :python.start(python_path: erlport_path)
  end

  def pycall(pid, mod, func, args) do
    :python.call(pid, mod, func, args)
  end
end
