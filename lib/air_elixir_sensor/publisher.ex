defmodule AirElixirSensor.Publisher do
  @moduledoc """
  A behaviour module for implementing polling on a pin.

  The AirElixirSensor.Publisher behavior abstracts polling on a pin.  Developers are responsible for implementing
  `c:read_value/2` and a module using the `AirElixirSensor.PublisherTrigger` behaviour.

  ## Example
  This example shows implementation of `AirElixirSensor.Dht11`.  The module should `use AirElixirSensor.Publisher`,
  specifiying the `:default_trigger` and `:read_type`.  It should have a `c:read_value/2` callback which reads the
  desired sensor.

      defmodule AirElixirSensor.Dht11 do
        use AirElixirSensor.Publisher,
          default_trigger: AirElixirSensor.Dht11.Dht11PublisherTrigger,
          read_type: 0 | 1

        use AirElixirSensor.Dht11, :publisher_by_python
      end

  The requirements for creating the `:default_trigger` are described in `AirElixirSensor.Trigger`.
  """

  @callback read_value(atom, AirElixir.pin() | AirElixir.port_path()) :: any

  defmacro __using__(default_trigger: default_trigger, read_type: read_type) do
    quote location: :keep do
      use GenServer
      alias AirElixirSensor.Registry
      alias AirElixirSensor.Subscriber

      @behaviour AirElixirSensor.Publisher

      defmodule State do
        @moduledoc false
        defstruct [
          :pin_or_port,
          :trigger_state,
          :poll_interval,
          :prefix,
          :trigger,
          :poll_reference
        ]

        def poll(%State{poll_interval: 0} = state, pid) do
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

      @doc """
      Starts a process linked to the current process. This is often used to start the process as part of a supervision tree.

      ## Options
      - `:poll_interval` - The time in ms between polling for state.i If set to 0 polling will be turned off. Default: `100`
      - `:trigger` - This is used to pass in a trigger to use for triggering events. See specific poller for defaults
      - `:trigger_opts` - This is used to pass options to a trigger `init\1`. The default is `[]`
      """
      @spec start_link(AirElixir.pin() | AirElixir.port_path()) :: Supervisor.on_start()
      def start_link(pin_or_port, opts \\ []) do
        poll_interval = Keyword.get(opts, :poll_interval, 100)
        trigger = Keyword.get(opts, :trigger, unquote(default_trigger))
        trigger_opts = Keyword.get(opts, :trigger_opts, [])
        prefix = Keyword.get(opts, :prefix, Default)
        opts = Keyword.put(opts, :name, Registry.name(prefix, pin_or_port))

        GenServer.start_link(
          __MODULE__,
          [pin_or_port, poll_interval, prefix, trigger, trigger_opts],
          opts
        )
      end

      @doc "Stops polling immediately"
      @spec stop_polling(AirElixir.pin() | AirElixir.port_path(), atom) :: :ok
      def stop_polling(pin_or_port, prefix \\ Default) do
        GenServer.cast(Registry.name(prefix, pin_or_port), {:change_polling, 0})
      end

      @doc "Stops the current scheduled polling event and starts a new one with the new interval"
      @spec change_polling(AirElixir.pin() | AirElixir.port_path(), integer, atom) :: :ok
      def change_polling(pin_or_port, interval, prefix \\ Default) do
        GenServer.cast(Registry.name(prefix, pin_or_port), {:change_polling, interval})
      end

      @doc "Read the value from the specified pin"
      @spec read(AirElixir.pin() | AirElixir.port_path(), atom) :: unquote(read_type)
      def read(pin_or_port, prefix \\ Default) do
        GenServer.call(Registry.name(prefix, pin_or_port), :read)
      end

      #
      # Server
      #
      def init([pin_or_port, poll_interval, prefix, trigger, trigger_opts]) do
        {:ok, trigger_state} = trigger.init(trigger_opts)

        state_with_poll_reference =
          schedule_poll(%State{
            pin_or_port: pin_or_port,
            poll_interval: poll_interval,
            prefix: prefix,
            trigger: trigger,
            trigger_state: trigger_state
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

      def handle_call(:read, _from, state) do
        {value, new_state} = update_value(state)
        {:reply, value, new_state}
      end

      def handle_info(:poll_updating, state) do
        {_, new_state} = update_value(state)
        schedule_poll(state)
        {:noreply, new_state}
      end

      #
      # Helpers
      #
      @spec update_value(State) :: State
      defp update_value(state) do
        with value <- read_value(state.prefix, state.pin_or_port),
             trigger = {_, trigger_state} <- state.trigger.update(value, state.trigger_state),
             :ok <- dispatch(trigger, state.prefix, state.pin_or_port) do
          {value, %{state | trigger_state: trigger_state}}
        end
      end

      defp dispatch({:ok, _}, _, _) do
        :ok
      end

      defp dispatch({event, trigger_state}, prefix, pin) do
        Subscriber.dispatch_change(prefix, {pin, event, trigger_state})
      end

      defp schedule_poll(state) do
        State.poll(state, self())
      end
    end
  end
end
