# 🦍 Koko

Elixir agent that lives alongside [joelclaw](https://github.com/joelhooks/joelclaw). Listens, learns, does work. Signs back.

## What

An OTP application running on Overlook (Mac Mini M4 Pro) that connects to joelclaw's Redis event bus and gradually picks up real work. Not a migration — a co-resident proving ground for BEAM patterns.

## Stack

- Erlang/OTP 27 + Elixir 1.18.4
- Redix (Redis pub/sub + commands)
- req_llm (multi-provider LLM client)
- Oban (job processing, when needed)

## Status

Phase 1: Passive observer. Subscribed to `joelclaw:gateway:events`, logging what it sees.

## ADRs

- [ADR-0115](https://joelclaw.com/adrs/0115-koko-project-charter) — Project charter
- [ADR-0116](https://joelclaw.com/adrs/0116-koko-redis-bridge-protocol) — Redis bridge protocol
- [ADR-0117](https://joelclaw.com/adrs/0117-koko-first-workloads) — First workloads

## Run

```bash
mix deps.get
mix run --no-halt
```

## Name

After [Koko the gorilla](https://en.wikipedia.org/wiki/Koko_(gorilla)) who learned sign language. She listened, she learned, she communicated back.
