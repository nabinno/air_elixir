defmodule AirElixirSensor.Sds021.Sds021PublisherTrigger do
  @behaviour AirElixirSensor.PublisherTrigger

  @moduledoc """
  This is the default triggering mechanism for SDS021 events. The
  event is `:changed` and includes the trigger state. The trigger state
  for the default trigger is a struct containing `pm25` and `pm10`
  properties.

  ## Examples

      iex> AirElixirSensor.Sds021.PublisherTrigger.init([])
      {:ok, %AirElixirSensor.Sds021.Sds021PublisherTrigger.State{pm25: 0, pm10: 0}}
      iex> AirElixirSensor.Sds021.Sds021PublisherTrigger.update({0, 0}, %{pm25: 0, pm10: 0})
      {:ok, %{pm25: 0, pm10: 0}}
      iex> AirElixirSensor.Sds021.Sds021PublisherTrigger.update({11.3, 45.5}, %{pm25: 0, pm10: 0})
      {:changed, %{pm25: 11.3, pm10: 45.5}}
      iex> AirElixirSensor.Sds021.Sds021PublisherTrigger.update({11.3, 45.5}, %{pm25: 11.3, pm10: 45.5})
      {:ok, %{pm25: 11.3, pm10: 45.5}}
      iex> AirElixirSensor.Sds021.Sds021PublisherTrigger.update({22.5, 34.5}, %{pm25: 11.3, pm10: 45.5})
      {:changed, %{pm25: 22.5, pm10: 34.5}}
  """

  defmodule State do
    @moduledoc false
    defstruct pm25: 0, pm10: 0
  end

  def init(_) do
    {:ok, %State{}}
  end

  def update({pm25, pm10}, %{pm25: pm25, pm10: pm10} = state) do
    {:ok, state}
  end

  def update({new_pm25, new_pm10}, state) do
    {:changed, %{state | pm25: new_pm25, pm10: new_pm10}}
  end
end
