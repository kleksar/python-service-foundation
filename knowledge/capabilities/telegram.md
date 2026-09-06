# Telegram

## Applicability and decisions

Apply this recipe when Telegram is an actual interface to a feature. Do not add a bot framework, HTTP server, Redis, or persistent conversation state to the seed preemptively.

This document owns the Telegram transport integration. Reuse [service](../patterns/service.md), [schemas](../patterns/schemas.md), [errors](../patterns/errors.md), [settings](../conventions/settings.md), [security](../conventions/security.md), and [idempotency](../patterns/idempotency.md) rather than giving the bot a separate application architecture.

Before implementation, decide:

- Long polling or webhooks, based on hosting and delivery requirements; they are not simultaneously active for the same bot token.
- Which commands, messages, callback queries, and update types are accepted.
- Who may invoke each operation and access each resource. Telegram user/chat identifiers are inputs to application authorization, not substitutes for it.
- Whether interactions are stateless, process-local and disposable, or must survive restarts.
- How duplicate updates and ambiguous send outcomes affect business behavior.
- Expected Bot API rate limits, payload limits, and user-visible failure behavior.

Default recommendation for a new async Python bot: aiogram 3. This is a recommended technology choice, not a verified Vitok integration or a claim that aiogram is already installed.

## Minimal implementation

Add the framework only when choosing this transport:

```sh
uv add 'aiogram>=3,<4'
```

Lock the resolved release and check it with the project's supported Python version. Add a settings dependency only if needed for actual environment configuration. Redis FSM storage is not a default dependency; introduce it only after a persistent/shared state contract exists.

Place the code by responsibility:

- `src/app/bot/entrypoint.py`: one process/event-loop owner, framework assembly, startup and shutdown.
- `src/app/bot/<feature>/router.py`: filters and handlers for one feature.
- `src/app/bot/<feature>/schemas.py`: transport-specific input/output mapping, when needed.
- `src/app/bot/errors.py`: safe user-facing mapping of expected application failures.
- `src/app/<feature>/service.py`: use cases independent of aiogram update and message objects.

Construct the bot client and dispatcher in the executable composition boundary. Own their sessions and any storage connections explicitly, including cleanup after partial startup. Avoid a module-level network client shared through imports. Importing a feature service must not require a token.

A handler extracts a bounded application input, establishes the actor context, invokes the service, and presents the result. It does not run SQL, contain business policy, or hand framework objects into the service. Put reusable business errors in the feature's `errors.py`, not inside bot exception handlers.

## Delivery, state, and safety

### Polling

Use one coordinated polling owner per bot token unless the selected framework explicitly supports the chosen topology. Do not start polling in every API worker. Configure accepted update types deliberately. Treat offset advancement and crash behavior as part of delivery semantics; do not assume the framework guarantees exactly-once business processing.

### Webhooks

Use HTTPS at the ingress and validate Telegram's configured webhook secret header before accepting the update. Do not use a token embedded in a public URL as the only control. Apply body-size and request-time limits.

Define when the endpoint acknowledges receipt. Returning success before durable acceptance can lose work if the process crashes; performing all business work before returning can time out and provoke redelivery. Choose a bounded synchronous operation or durable handoff according to the feature contract. Do not add a queue merely because webhooks exist.

Registering or deleting a webhook changes the live bot and requires explicit deployment authorization. Tests must not reconfigure a production bot or send unsolicited messages.

### Conversations and outbound messages

Treat FSM state as interaction state, not the authoritative store for money, ownership, or completed business actions. If restart loss is acceptable, process-local state can be sufficient. If shared or durable state is necessary, define expiry, concurrent updates, and cleanup before selecting storage.

Handle callback queries promptly even when the business result follows later. Bound and validate callback data; do not trust a serialized action or resource identifier from the user. Escape untrusted values for the selected Telegram parse mode, and decide how to split messages larger than the accepted payload size.

A send timeout may occur after Telegram accepted a message. Blindly retrying a business operation or outbound notification can duplicate effects. Decide which notifications tolerate duplicates and which need an application delivery record; do not claim that local deduplication makes a remote send exactly once.

Honor rate-limit responses with a bounded retry budget and cancellation-aware waits. Keep retry behavior separate from business authorization and transaction ownership. Redact bot tokens, update contents containing personal data, and token-bearing request URLs from logs.

## Acceptance checks

1. Test handler-to-service mapping with representative commands, callbacks, unsupported update types, invalid inputs, and unauthorized actors. Test domain behavior without aiogram objects.
2. Feed an update through the configured dispatcher/router pipeline with a controlled Bot API session. Verify filters, actor mapping, error presentation, callback acknowledgement, and safe formatting. A direct call to a handler alone does not validate dispatch.
3. Verify duplicate update delivery does not repeat protected business effects when deduplication is promised; exercise concurrent duplicates where storage enforces uniqueness.
4. For webhook mode, exercise the real HTTP handler with missing/wrong secrets, malformed/oversized bodies, duplicate updates, and downstream failure. Check the acknowledgement contract.
5. For polling/process lifecycle claims, run the actual entrypoint against a controlled transport or explicitly authorized test bot, then terminate it and verify resource cleanup.
6. If conversation state is persistent, verify expiry, restart behavior, and concurrent updates against the chosen real storage.
7. An authorized sandbox Bot API round trip is separate evidence for Telegram compatibility. Use a dedicated bot and chat, never production credentials; report the test as skipped if authorization or credentials are unavailable.

Record exact process commands in the consuming project after choosing polling or webhook mode. There is intentionally no universal bot process in this seed.

## Sources and limits

The inspected Vitok revision did not provide a Telegram implementation to transplant. This recipe is a portable design recommendation; aiogram API details and Python compatibility must be verified against the locked release during implementation.

Upstream references: [aiogram documentation](https://docs.aiogram.dev/) and [Telegram Bot API](https://core.telegram.org/bots/api). These references were not fetched during this transfer. The seed's tests do not prove Bot API connectivity, webhook delivery, or aiogram behavior.
