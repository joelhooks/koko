defmodule Koko.MixProject do
  use Mix.Project

  def project do
    [
      app: :koko,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Koko.Application, []}
    ]
  end

  defp deps do
    [
      # Redis
      {:redix, "~> 1.5"},
      # LLM client
      {:req, "~> 0.5"},
      {:req_llm, "~> 1.6"},
      # JSON
      {:jason, "~> 1.4"},
      # Job processing (Inngest equivalent)
      {:oban, "~> 2.19"},
      # Postgres for Oban
      {:ecto_sql, "~> 3.12"},
      {:postgrex, "~> 0.19"},
      # Telemetry
      {:telemetry, "~> 1.3"},
    ]
  end
end
