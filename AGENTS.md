# Koko — Agent Instructions

## What This Is

Koko is an Elixir/OTP application that lives alongside [joelclaw](https://github.com/joelhooks/joelclaw) on Overlook (Mac Mini M4 Pro). It connects to the existing Redis event bus and gradually picks up real work. **Not a migration — a co-resident proving ground for BEAM patterns.**

Named after [Koko the gorilla](https://en.wikipedia.org/wiki/Koko_(gorilla)) who learned sign language. She listened, she learned, she communicated back.

## Stack

- Erlang/OTP 27 + Elixir 1.18.4
- Redix (Redis pub/sub + commands)
- req_llm (multi-provider LLM client)
- Oban (job processing — Inngest equivalent for Elixir)
- Ecto + Postgrex (Postgres for Oban)
- Telemetry (BEAM observability)

## Architecture

```
joelclaw TypeScript stack (primary)
    │
    ├─ PUBLISH joelclaw:gateway:events ─→ Redis ─→ Koko (observes)
    │                                            ─→ Gateway (observes + drains)
    │
    └─ LPUSH joelclaw:gateway:events ─→ Redis ─→ Gateway (drains)
                                                   Koko does NOT drain this
```

Koko is a **read-only observer** (Phase 1). It subscribes via Redix.PubSub, receives the same PUBLISH notifications the gateway gets, and logs events. It does NOT consume from the LPUSH list — that's the gateway's job.

### Process Tree

```
Koko.Supervisor (one_for_one)
├── Redix (:redix) — command connection
├── Redix.PubSub (:redix_pubsub) — subscription connection
└── Koko.EventListener — GenServer, subscribes to joelclaw:gateway:events
```

## Current Status: Phase 1 — Passive Observer

Koko subscribes to Redis events and logs what it sees. No mutations, no side effects.

## Development

### Local (on Overlook / joel@panda)

```bash
cd ~/Code/joelhooks/koko
mix deps.get
mix run --no-halt
```

Redis must be running (k8s NodePort 6379 on localhost).

### Remote (SSH)

```bash
ssh joel@panda
cd ~/Code/joelhooks/koko
mix run --no-halt
```

### Tests

```bash
mix test
```

### IEx (interactive)

```bash
iex -S mix
Koko.events_seen()
```

## Constraints

- **Koko MUST NOT write to authoritative state.** No Typesense upserts, no Todoist mutations, no gateway notifications. Shadow results only.
- **Koko MUST NOT consume from the LPUSH list.** That's the gateway's drain. Koko observes via PubSub only.
- **If Koko crashes, nothing breaks.** The TypeScript stack doesn't depend on it.
- **Redis is at localhost:6379** — exposed via k8s NodePort + Docker port mapping on Overlook.

## ADRs (Architecture Decision Records)

All ADRs are published at [joelclaw.com/adrs](https://joelclaw.com/adrs).

### Core ADRs

- [ADR-0114: Elixir/BEAM/Jido Migration — Full Architecture Evaluation](https://joelclaw.com/adrs/0114-elixir-beam-jido-migration) — `proposed`
  The parent evaluation. Assesses full BEAM migration for joelclaw — process supervision, hot reload, fault tolerance, GenServer patterns. Koko exists to validate this thesis incrementally.

- [ADR-0115: Koko — Project Charter](https://joelclaw.com/adrs/0115-koko-project-charter) — `proposed`
  What Koko is and isn't. Graduation criteria: Koko moves from toy to real component when it handles a workload more reliably than TypeScript, survives 30 days without manual intervention, and the DX is enjoyable.

### Protocol & Integration

- [ADR-0116: Koko Redis Bridge Protocol](https://joelclaw.com/adrs/0116-koko-redis-bridge-protocol) — `proposed`
  How Koko talks to joelclaw. Phase 1: passive PubSub observer. Phase 2: dedicated `joelclaw:koko:events` channel for claimed work. Phase 3: bidirectional — Koko can emit events back.

### Workloads

- [ADR-0117: Koko First Workloads](https://joelclaw.com/adrs/0117-koko-first-workloads) — `proposed`
  Three starter workloads: (1) Health pulse — GenServer pinging Redis/Typesense/Inngest every 60s with supervisor restarts. (2) Event digest — process-per-window hourly summaries via req_llm. (3) File watcher — Vault change detection with hot reload.

- [ADR-0118: Koko Shadow Executor](https://joelclaw.com/adrs/0118-koko-shadow-executor) — `proposed`
  Sean Grove's insight: shadow execution. Koko runs the same workloads as TypeScript in parallel, same inputs, compare results. Eliminates "apples to oranges" — the question becomes "is BEAM better/faster/more reliable for this specific workload?" Shadow results write to `joelclaw:koko:shadow:<function>` in Redis, never to authoritative state.

### Historical

- [ADR-0064: Evaluate Elixir/BEAM as joelclaw Backbone](https://joelclaw.com/adrs/0064-elixir-beam-evaluation) — `superseded` by ADR-0114

## joelclaw System Context

Koko operates within the joelclaw ecosystem:

- **Event bus**: Redis pub/sub + LPUSH queues, consumed by gateway and Inngest functions
- **Workflow engine**: Inngest (self-hosted in k8s) — durable functions, cron, fan-out
- **Inference**: `@joelclaw/inference-router` — catalog-based model selection, Langfuse tracing
- **Observability**: OTEL events → Typesense (`otel_events` collection)
- **State**: Redis (ephemeral), Typesense (search), Convex (persistent), Vault (knowledge)
- **Channels**: Telegram, Discord, Slack, iMessage — all via gateway daemon
- **Infrastructure**: k8s (Talos Linux on Colima), Mac Mini M4 Pro (Overlook/panda)

## Code Style

- Follow standard Elixir conventions (mix format)
- Use `Logger` for structured logging with `[koko]` prefix
- GenServer for stateful processes, Supervisor for fault tolerance
- Pattern match on event types in handle_info/handle_event
- Keep modules focused — one GenServer per concern
