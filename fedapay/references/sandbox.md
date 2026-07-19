# FedaPay sandbox — test data & going live

The sandbox mirrors production without touching a real account. Use the **sandbox** keys (`pk_sandbox_...`, `sk_sandbox_...`) and either `setEnvironment('sandbox')` or the sandbox host. Objects created in sandbox never appear in live and vice-versa.

## Hosts

| Environment | Base URL |
| --- | --- |
| Sandbox | `https://sandbox-api.fedapay.com` |
| Live | `https://api.fedapay.com` |

Every request: `Authorization: Bearer <secret key>` (or let the SDK set it via `setApiKey`). API version prefix is `/v1` (e.g. `POST /v1/transactions`).

## Test mobile money numbers

Sandbox uses a single test mode, **`momo_test`** — no operator-specific test servers anymore.

| Number | Result |
| --- | --- |
| `64000001` | **Success** |
| `66000001` | **Success** |
| any other number | Failure (simulated per your sandbox settings) |

Country `bj`. Card testing is done through the hosted Checkout page in sandbox.

## Currency & amount

- Currency: `{ iso: 'XOF' }` (also NGN/GNF/etc. per your account). Amount is always an **integer** — XOF has no decimal subunit, so `1000` = 1000 FCFA.

## Transaction status lifecycle

`pending` → `approved` (paid) → `transferred` (settled to merchant). Off-path: `declined`, `canceled` (both retryable, **not** terminal), `expired` (a `pending` older than 24h), `refunded`.

Deliver value only on `approved` (or `transferred`). Never treat `declined` / `canceled` as final — the same transaction can still be paid on a retry.

## Going live — checklist

- [ ] Replace `pk_sandbox_*` / `sk_sandbox_*` with the live keys (client **and** server).
- [ ] `setEnvironment('live')` (or point hosts at `api.fedapay.com`).
- [ ] Authorize your production domain in the dashboard (Checkout.js) — see [`checkout.md`](checkout.md).
- [ ] Create a **live** webhook endpoint with its own `wh_live_*` secret — see [`webhooks.md`](webhooks.md).
- [ ] Grep the codebase: no `sandbox` key, host, or environment left anywhere.
- [ ] Re-run a small real transaction end-to-end and confirm the server-side verify path fires.
