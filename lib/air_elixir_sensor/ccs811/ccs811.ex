defmodule AirElixirSensor.Ccs811 do
  @moduledoc """
  CCS811 sensor reader module for Raspberry.

  ## Examples

      defmodule AirElixirSensor.Ccs811.Ccs811Publisher do
        use AirElixirSensor.Ccs811, :publisher_by_python
      end
  """

  def publisher_by_python do
    quote do
      alias AirElixirSensor.PythonErlport

      def read_value(prefix, address) do
        case PythonErlport.call(prefix, {:ccs811, :read, []}) do
          {:ok, {65535, _} = result} -> result
          {:ok, {_, 65535} = result} -> read_value(prefix, address)
          {:ok, {_, _} = result} -> result
          {:error, _result} -> read_value(prefix, address)
        end
      end
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
