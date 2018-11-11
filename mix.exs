defmodule Painter.MixProject do
  use Mix.Project

  def project do
    [
      app: :painter,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: [
        flags: [
          :race_conditions,
          :underspecs,
          :unknown,
          :unmatched_returns,
          :error_handling
        ],
        ignore_warnings: ".dialyzer_ignore.exs"
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Painter, []},
      env: [ansi_enabled: IO.ANSI.enabled?()]
    ]
  end

  defp deps do
    [
      {
        :credo,
        "~> 0.10.0",
        only: [:dev, :test], runtime: false
      },
      {:dialyxir, "~> 1.0.0-rc.3", only: [:dev], runtime: false}
    ]
  end
end

