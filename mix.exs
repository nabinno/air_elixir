defmodule AirElixir.MixProject do
  use Mix.Project

  def project do
    [
      app: :air_elixir,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  def application do
    [
      mod: {
        AirElixir.Application,
        [
          Default,
          %{
            dht11: [24],
            sds021: ["/dev/ttyAMA0"],
            ccs811: [0x5A]
          }
        ]
      },
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:cachex, "~> 3.1"},
      {:circuits_gpio, git: "https://github.com/elixir-circuits/circuits_gpio.git"},
      {:circuits_i2c, git: "https://github.com/elixir-circuits/circuits_i2c.git"},
      {:circuits_spi, git: "https://github.com/elixir-circuits/circuits_spi.git"},
      {:deps_ghq_get, "~> 0.1.2", only: :dev},
      {:erlport, "~> 0.9"},
      {:httpoison, "~> 1.4"},
      {:poison, "~> 3.1"},
      {:timex, "~> 3.1"}
    ]
  end

  defp aliases do
    [
      "c.clean": ["cmd make clean", "cmd echo Cleaning C files \\(.so\\)"],
      "c.compile": ["cmd mkdir -p _build/c", "cmd make", "cmd echo Compiling C files \\(.c\\)"],
      "deps.get": ["deps.get", "deps.ghq_get --async", "python.deps.get"],
      "python.deps.get": [
        "cmd pip install --user \
          pyserial==2.7 \
          Adafruit_CCS811==0.2.1"
      ]
    ]
  end
end
