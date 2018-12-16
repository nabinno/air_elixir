defmodule AirElixir.GoogleSpreadsheets do
  @moduledoc false

  use GenServer
  alias AirElixirSensor.Registry
  import HTTPoison
  import Poison

  defmodule State do
    @moduledoc false
    defstruct [
      :cache_name,
      :poll_interval,
      :prefix,
      :poll_reference
    ]

    def poll(%State{poll_interval: 0} = state, _pid) do
      state
    end

    def poll(%State{poll_interval: poll_interval} = state, pid) do
      reference = Process.send_after(pid, :poll_updating, poll_interval)
      %{state | poll_reference: reference}
    end

    def cancel_polling(%State{poll_reference: reference} = state) do
      Process.cancel_timer(reference)
      %{state | poll_reference: nil}
    end

    def change_interval(state, interval) do
      %{state | poll_interval: interval}
    end
  end

  def start_link(cache_name, opts \\ []) do
    poll_interval = Keyword.get(opts, :poll_interval, 100)
    prefix = Keyword.get(opts, :prefix, Default)
    opts = Keyword.put(opts, :name, Registry.name(prefix, cache_name))

    GenServer.start_link(
      __MODULE__,
      [cache_name, poll_interval, prefix],
      opts
    )
  end

  def stop_polling(cache_name, prefix \\ Default) do
    GenServer.cast(Registry.name(prefix, cache_name), {:change_polling, 0})
  end

  def change_polling(cache_name, interval, prefix \\ Default) do
    GenServer.cast(Registry.name(prefix, cache_name), {:change_polling, interval})
  end

  #
  # Server
  #
  def init([cache_name, poll_interval, prefix]) do
    state_with_poll_reference =
      schedule_poll(%State{
        cache_name: cache_name,
        poll_interval: poll_interval,
        prefix: prefix
      })

    {:ok, state_with_poll_reference}
  end

  def handle_cast({:change_polling, interval}, state) do
    new_state =
      state
      |> State.cancel_polling()
      |> State.change_interval(interval)
      |> State.poll(self())

    {:noreply, new_state}
  end

  def handle_info(:poll_updating, state) do
    append_values_to_gss(state)
    schedule_poll(state)
    {:noreply, state}
  end

  #
  # Helpers
  #
  defp append_values_to_gss(%State{cache_name: cache_name} = _state) do
    body =
      Cachex.export!(cache_name)
      |> Enum.map(fn {_, key, _, _, value} = _ ->
        case Integer.parse(to_string(value)) do
          {int, ""} -> {String.to_atom(key), int}
          {int, rem} -> {String.to_atom(key), String.to_float("#{int}#{rem}")}
        end
      end)

    do_append_values_to_gss(body)
  end

  defp append_values_to_gss(_), do: nil

  defp do_append_values_to_gss([co2: _, pm25: _, temp: _, pm10: _, humidity: _, tvoc: _] = body) do
    post(
      System.get_env("GSS_VALUES_APPEND_WEBHOOK"),
      encode!(
        body
        |> Enum.into(%{created_at: Timex.now("Asia/Tokyo") |> Timex.format!("%F %T", :strftime)})
      ),
      [{"Content-Type", "application/json"}]
    )
  end

  defp do_append_values_to_gss(_), do: nil

  defp schedule_poll(state) do
    State.poll(state, self())
  end
end
