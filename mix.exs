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
          :unmatched_returns,
          :overspecs,
          :specdiffs,
          :error_handling
        ]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {
        :credo,
        "~> 0.10.0",
        only: [:dev, :test],
        runtime: false
      },
      {
        :dialyxir,
        # git: "https://github.com/aleph-naught2tog/dialyxir.git",
        path: "../dialyxir",
        only: [:dev],
        runtime: false
      }
    ]
  end
end
