defmodule Koko.Application do
  @moduledoc """
  Koko — an Elixir agent that lives alongside joelclaw.
  Connects to the existing Redis event bridge and picks up work.
  """
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Redis connections (one for commands, one for pub/sub)
      {Redix, name: :redix, host: "localhost", port: 6379},
      {Redix.PubSub, name: :redix_pubsub, host: "localhost", port: 6379},
      # Event listener — subscribes to joelclaw gateway events
      Koko.EventListener,
    ]

    opts = [strategy: :one_for_one, name: Koko.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
