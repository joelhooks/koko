defmodule Koko.EventListener do
  @moduledoc """
  Subscribes to joelclaw's Redis pub/sub channel and logs events.
  This is the bridge between the existing TypeScript event bus and Koko.

  The gateway extension publishes to "joelclaw:gateway:events" via PUBLISH.
  Inngest functions push to "joelclaw:gateway:events" via LPUSH.
  """
  use GenServer
  require Logger

  @channel "joelclaw:gateway:events"

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    {:ok, ref} = Redix.PubSub.subscribe(:redix_pubsub, @channel, self())
    Logger.info("[koko] subscribed to #{@channel}")
    {:ok, %{ref: ref, events_seen: 0}}
  end

  @impl true
  def handle_info({:redix_pubsub, _pubsub, _ref, :subscribed, %{channel: channel}}, state) do
    Logger.info("[koko] confirmed subscription to #{channel}")
    {:noreply, state}
  end

  @impl true
  def handle_info({:redix_pubsub, _pubsub, _ref, :message, %{channel: _channel, payload: payload}}, state) do
    count = state.events_seen + 1

    case Jason.decode(payload) do
      {:ok, event} ->
        type = Map.get(event, "type", Map.get(event, "name", "unknown"))
        Logger.info("[koko] event ##{count}: #{type}")
        handle_event(type, event)

      {:error, _} ->
        Logger.debug("[koko] non-JSON message: #{String.slice(payload, 0, 100)}")
    end

    {:noreply, %{state | events_seen: count}}
  end

  @impl true
  def handle_info(_msg, state), do: {:noreply, state}

  # --- Event handlers ---

  defp handle_event("heartbeat", _event) do
    Logger.info("[koko] 💚 heartbeat received")
  end

  defp handle_event("system/health.checked", event) do
    status = get_in(event, ["data", "status"]) || "unknown"
    Logger.info("[koko] 🏥 health check: #{status}")
  end

  defp handle_event(type, _event) do
    Logger.debug("[koko] unhandled event type: #{type}")
  end
end
