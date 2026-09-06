# Error pattern

## Ownership follows meaning

Expected failures belong to the component that defines their semantics. Add an `errors.py` only when that boundary has real error types or translations; multiple related errors are appropriate in the same file.

| Owner | Responsibility |
| --- | --- |
| `app/<feature>/errors.py` | Named domain/application outcomes for that capability |
| `app/infra/<adapter>/errors.py` | Expected adapter failures when a translation contract exists |
| Transport resource `errors.py` | Mapping application outcomes into that protocol |
| Transport-level shared `errors.py` | A mapping actually reused by several resources |

Do not begin with a global exception catalog or mandatory `AppError` base. A shared marker may be introduced when a real consumer needs to recognize application-defined errors, but it does not own the semantics of every feature. Never raise a vague marker instead of a concrete outcome.

## Expected outcome or bug

Use a named application error or explicit result when callers must distinguish a normal rejected/failed scenario, such as an invalid state transition or an unavailable resource under the accepted contract. Decide whether absence or duplication is an error, no-op or result at the owning specification, not inside a catch-all handler.

Builtin `TypeError`, `ValueError` and `RuntimeError` can express immediate Python misuse or an invalid object lifecycle. Do not present these generic programmer errors as a stable business protocol. Conversely, do not wrap every programmer bug in a friendly application error and return a successful-looking response.

A category base can group several errors of one semantic owner when a consumer treats them alike. It must not falsely unite unrelated feature and infrastructure meanings merely because they concern the same external system.

## Translate only at a real boundary

Translate a third-party exception only when the adapter can establish a specific accepted condition. For example, a named uniqueness constraint can map to the feature's duplicate outcome. An arbitrary `IntegrityError` might instead be an unexpected foreign key, check or implementation failure; it must not automatically mean duplicate.

Preserve an internal cause when useful and safe, but do not pass vendor messages, SQL, credentials or user input into public error details. External/library failures propagate to the appropriate outer failure boundary unless a narrower accepted translation exists.

Do not catch blanket exceptions around an entire service to create one generic error. Cleanup belongs to resource scopes; translation belongs to a named failure contract. [Python conventions](../conventions/python.md) owns exception-handling mechanics.

## Transport mapping

Application errors do not import FastAPI, know HTTP status codes or format Telegram replies. A transport mapping chooses status, stable public code/detail and allowed context. Different transports can represent the same application error differently without changing its meaning.

A public error envelope should be introduced with an actual API contract, not in the empty seed. Distinguish client rejection, expected operational failure and unexpected server failure according to that contract. Do not expose tracebacks or raw validation input merely because the framework can serialize it.

Logging ownership follows [logging](../conventions/logging.md): translating and re-raising is not a reason to log again on each layer. A retry decision also requires the [idempotency](idempotency.md) contract; an error category alone does not prove an operation is safe to repeat.

## Evidence

Test concrete application outcomes, exact expected adapter translations and non-translation of unexpected conditions. Transport tests verify status/code/public detail and the absence of confidential data. For persistence translation, exercise the real named database constraint, not only a hand-constructed driver exception.

Test that unexpected failures remain observable as failures and that cleanup does not convert them to success. A complete test of a hierarchy does not prove that every actual exception-producing call is classified correctly; inspect the affected calls and their library behavior.
