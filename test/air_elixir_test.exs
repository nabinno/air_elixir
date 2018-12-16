defmodule AirElixirTest do
  use ExUnit.Case
  doctest AirElixir

  test "greets the world" do
    assert AirElixir.hello() == :world
  end
end
