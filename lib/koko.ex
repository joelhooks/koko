defmodule Koko do
  @moduledoc """
  Koko — Elixir agent living alongside joelclaw.

  Named after the gorilla who learned sign language.
  Listens, learns, does work.
  """

  @doc "How many events has Koko seen?"
  def events_seen do
    GenServer.call(Koko.EventListener, :events_seen)
  rescue
    _ -> 0
  end
end
