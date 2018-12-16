defmodule AirElixirSensor.Ccs811.Ccs811PublisherTrigger do
  @behaviour AirElixirSensor.PublisherTrigger

  @moduledoc """
  This is the default triggering mechanism for CCS811 events. The
  event is `:changed` and includes the trigger state. The trigger state
  for the default trigger is a struct containing `co2` and `tvoc`
  properties.

  ## Examples

      iex> AirElixirSensor.Ccs811.PublisherTrigger.init([])
      {:ok, %AirElixirSensor.Ccs811.Ccs811PublisherTrigger.State{co2: 0, tvoc: 0}}
      iex> AirElixirSensor.Ccs811.Ccs811PublisherTrigger.update({0, 0}, %{co2: 0, tvoc: 0})
      {:ok, %{co2: 0, tvoc: 0}}
      iex> AirElixirSensor.Ccs811.Ccs811PublisherTrigger.update({11.3, 45.5}, %{co2: 0, tvoc: 0})
      {:changed, %{co2: 11.3, tvoc: 45.5}}
      iex> AirElixirSensor.Ccs811.Ccs811PublisherTrigger.update({11.3, 45.5}, %{co2: 11.3, tvoc: 45.5})
      {:ok, %{co2: 11.3, tvoc: 45.5}}
      iex> AirElixirSensor.Ccs811.Ccs811PublisherTrigger.update({22.5, 34.5}, %{co2: 11.3, tvoc: 45.5})
      {:changed, %{co2: 22.5, tvoc: 34.5}}
  """

  defmodule State do
    @moduledoc false
    defstruct co2: 0, tvoc: 0
  end

  def init(_) do
    {:ok, %State{}}
  end

  def update({co2, tvoc}, %{co2: co2, tvoc: tvoc} = state) do
    {:ok, state}
  end

  def update({new_co2, new_tvoc}, state) do
    {:changed, %{state | co2: new_co2, tvoc: new_tvoc}}
  end
end
