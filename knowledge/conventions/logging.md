# Structured logging conventions

This document owns application event semantics, level and safe field selection. A concrete formatter, processor chain, exporter or error-reporting SDK is a separate integration contract; see [observability](../capabilities/observability.md). The seed has no logging runtime until a consumer needs one.

## Stable events and useful context

Use a stable `lower_snake_case` event name describing the outcome, such as `order_submission_rejected`, instead of a dynamically constructed sentence. Attach a small set of named structured fields that make the event actionable: safe correlation identifiers, outcome/category, bounded counts and durations where relevant.

Do not interpolate whole requests, response bodies or models into messages. Avoid duplicate semantic fields and names reserved by the chosen pipeline, such as event, level, timestamp, logger and exception. With stdlib logging, supply fields through the agreed `extra` mechanism rather than arbitrary keyword arguments; a structured logger may expose named fields directly. The adapter contract determines the API, not this example vocabulary.

A reusable module may obtain a named logger without configuring handlers or loading settings. Process startup configures the pipeline once. Avoid attaching handlers in every module or producing a second copy through propagation.

## Failure ownership and level

One failure is recorded once at the boundary that owns the final handling decision. Do not log the same exception in repo, service and transport merely because it passes through all three. Lower layers translate only when the [error contract](../patterns/errors.md) requires it; the owning boundary chooses the event.

Choose level from outcome, not from the presence of an exception:

- debug: bounded implementation detail useful during diagnosis;
- info: normal meaningful completion or state change;
- warning: expected degraded/rejected behavior needing attention under the operational contract;
- error: a failed operation or unexpected condition requiring investigation;
- critical: inability to continue a process or a similarly severe accepted condition.

Routine validation failures need not all become warning/error events. A retry attempt and eventual failure should be distinguishable without creating duplicate incidents.

Use exception/traceback logging only inside the relevant handler and only when the exception text and stack are safe for the destination. Otherwise emit a stable category and safe fields. The existence of `except` does not make a vendor exception message safe.

## Serialization is not sanitization

Follow [security](security.md) for the confidentiality boundary. Every event owner selects allowable data before serialization. A JSON encoder or sensitive-key blacklist does not establish that a payload is safe.

Do not log credentials, authorization headers, connection URLs with secrets, raw Telegram updates, customer payloads or personal data by default. Hashing an identifier does not automatically anonymize it. Bound strings and collections according to operational use and retention requirements.

A full Pydantic `model_dump` is allowed only for an explicitly reviewed, safe and bounded event contract; usually selecting named fields is clearer. Use JSON-compatible values when the pipeline needs them, not `model_dump_json()` nested as an opaque JSON string. Do not call `get_secret_value()` in or before a logging call to bypass safe representation.

Correlation context must be scoped and cleared per request/task. Test that concurrent work cannot inherit another request's identifiers. Keep secrets and authorization state out of broadly propagated logging context.

## Evidence

Test event identity, meaningful fields, severity and safe failure output at the owning boundary. When a pipeline is introduced, test its actual serialized output and process/framework integration rather than inspecting only an in-memory event dictionary.

A syntax check can enforce literal event names or forbidden direct calls, but cannot prove the absence of PII, safe precomputed values, correct level or duplicate cross-layer logging. Do not introduce a broad AST checker as a substitute for reviewing those semantics.
