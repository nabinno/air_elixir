defmodule AirElixirSensor.Sds021 do
  @moduledoc """
  SDS021 sensor reader module for Raspberry by Python.

  ## Examples

      defmodule AirElixirSensor.Sds021.Sds021Publisher do
        use AirElixirSensor.Sds021, :publisher_by_python
      end
  """

  def publisher_by_python do
    quote do
      alias AirElixirSensor.PythonErlport

      def read_value(prefix, pin) do
        case PythonErlport.call(prefix, {:sds021, :read, []}) do
          {:ok, result} -> result
          {:error, _result} -> read_value(prefix, pin)
        end
      end
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
