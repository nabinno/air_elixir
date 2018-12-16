defmodule AirElixirSensor.Dht11 do
  @moduledoc """
  DHT11 sensor reader module for Raspberry.

  ## Examples

      defmodule AirElixirSensor.Dht11.Dht11Publisher do
        use AirElixirSensor.Dht11, :publisher_by_python
      end
  """

  def publisher_by_python do
    quote do
      alias AirElixirSensor.PythonErlport

      def read_value(prefix, pin) do
        case PythonErlport.call(prefix, {:dht11, :read, []}) do
          {:ok, result} -> result
          {:error, _result} -> read_value(prefix, pin)
        end
      end
    end
  end

  # @todo WIP
  def publisher_by_clang do
    quote do
      @on_load :load_nif
      @nif_path "./_build/c/libdht11"

      def read_value(prefix, pin) do
        case read(pin) do
          {:ok, result} -> result
          {:error, result} -> read_value(prefix, pin)
        end
      end

      @doc "Reads data from the sensor"
      def read(_pin) do
        raise Code.LoadError, file: @nif_path
      end

      @doc "Loads and initializes the `libdht11.so` NIF library"
      def load_nif do
        case :erlang.load_nif(@nif_path, 0) do
          :ok -> setup()
          {:error, {:load_failed, error}} -> Logger.warn(error)
        end
      end

      def setup do
        raise Code.LoadError, file: @nif_path
      end
    end
  end

  # @todo WIP
  def publisher_by_circuits do
    quote do
      use Bitwise
      alias Circuits.GPIO

      def read_value(prefix, pin) do
        case read(pin) do
          {:ok, result} -> result
          {:error, _result} -> read_value(prefix, pin)
        end
      end

      def read(pin) do
        {:ok, gpo} = GPIO.open(pin, :output)
        send_and_sleep(gpo, 1, 50)
        send_and_sleep(gpo, 0, 20)

        {:ok, gpi} = GPIO.open(pin, :input)
        GPIO.set_pull_mode(gpi, :pullup)

        pullup_lengths = gpi |> collect_input |> parse_data_pullup_lengths
        bytes = pullup_lengths |> calculate_bits |> bits_to_bytes

        cond do
          length(pullup_lengths) != 40 -> {:error, {0, 0}}
          Enum.at(bytes, 4) != calculate_checksum(bytes) -> {:error, {0, 0}}
          true -> {:ok, {Enum.at(bytes, 2), Enum.at(bytes, 0)}}
        end
      end

      defp send_and_sleep(gpo, output, sleep) do
        GPIO.write(gpo, output)
        :timer.sleep(sleep)
      end

      defp collect_input(gpi), do: rec_collect_input(gpi, 0, -1, [])

      defp rec_collect_input(gpi, unchanged_count, last, data) do
        current = GPIO.read(gpi)
        data = data ++ [current]

        cond do
          last != current ->
            rec_collect_input(gpi, 0, current, data)

          last == current && unchanged_count <= 100 ->
            rec_collect_input(gpi, unchanged_count + 1, last, data)

          true ->
            data
        end
      end

      defp parse_data_pullup_lengths(data) do
        state = %{
          init_pulldown: 1,
          init_pullup: 2,
          firstpulldown: 3,
          pullup: 4,
          pulldown: 5
        }

        {_, _, rc_lengths} =
          data
          |> Enum.reduce(
            {state[:init_pulldown], 0, []},
            fn datum, {current_state, current_length, lengths} ->
              current_length = current_length + 1

              cond do
                current_state == state[:init_pulldown] && datum == 0 ->
                  {state[:init_pullup], current_length, lengths}

                current_state == state[:init_pullup] && datum == 1 ->
                  {state[:firstpulldown], current_length, lengths}

                current_state == state[:firstpulldown] && datum == 0 ->
                  {state[:pullup], current_length, lengths}

                current_state == state[:pullup] && datum == 1 ->
                  {state[:pulldown], 0, lengths}

                current_state == state[:pulldown] && datum == 0 ->
                  {state[:pullup], current_length, lengths ++ [current_length]}

                true ->
                  {current_state, current_length, lengths}
              end
            end
          )

        rc_lengths
      end

      defp calculate_bits(pullup_lengths) do
        {shortest_pullup, longest_pullup} =
          pullup_lengths
          |> Enum.reduce({1000, 0}, fn length, {shortest_pullup, longest_pullup} ->
            cond do
              length < shortest_pullup -> {length, longest_pullup}
              length > longest_pullup -> {shortest_pullup, length}
              true -> {shortest_pullup, longest_pullup}
            end
          end)

        halfway = shortest_pullup + (longest_pullup - shortest_pullup) / 2

        pullup_lengths
        |> Enum.reduce([], fn length, bits ->
          if length > halfway, do: bits ++ [true], else: bits ++ [false]
        end)
      end

      defp bits_to_bytes(bits) do
        {_, rc_bytes} =
          bits
          |> Enum.with_index()
          |> Enum.reduce({0, []}, fn {bit, i}, {byte, bytes} ->
            byte = byte <<< 1
            byte = if bit == true, do: byte ||| 1, else: byte ||| 0

            if rem(i + 1, 8) == 0 do
              {0, bytes ++ [byte]}
            else
              {byte, bytes}
            end
          end)

        rc_bytes
      end

      defp calculate_checksum(bytes) do
        bytes
        |> Enum.with_index()
        |> Enum.reduce(0, fn {byte, index}, acc -> if index < 4, do: acc + byte end)
        |> Bitwise.&&&(255)
      end
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
