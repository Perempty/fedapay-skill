---
name: fedapay
description: Integrate FedaPay payments (mobile money & card, Bénin/West Africa) into a webapp/SaaS or a mobile app. Use when integrating fedapay / une collecte, creating a transaction and its payment token/link, embedding Checkout.js, confirming a transaction server-side, handling a fedapay webhook, or going from sandbox to live.
version: 1.0.0
license: MIT
author: Perempty <ckindji@gmail.com>
homepage: https://github.com/Perempty/fedapay-skill
tags: [payments, fedapay, mobile-money, card, benin, west-africa, xof, fintech, webhook, checkout, saas, mobile, nodejs, php, ruby, react, angular]
---

A FedaPay payment is always the same spine: **create → token → pay → verify**. Your server creates a **transaction** with the secret key, turns it into a payment **token/URL**, the customer pays (hosted page, embedded Checkout.js, or no-redirect mobile money), and your server **verifies** by re-reading the transaction status.

## Cardinal rule: `approved` server-side, or it didn't happen

The client can lie. The `callback_url` status (`?status=approved`) and the Checkout.js `onComplete` result are **signals**, not proof — the docs say so explicitly. Never credit, ship, or unlock anything before retrieving the transaction **server-side** with your secret key and confirming both:

- `transaction.status === "approved"`, **and**
- `transaction.amount` matches the amount you expected for that order.

Reconcile with your own order using `merchant_reference` (your order id, passed at creation, read back on verify).

## Transaction statuses

| Status | Meaning | Final? |
| --- | --- | --- |
| `pending` | created, not yet paid (default) | no — auto-expires after 24h |
| `approved` | payment succeeded | **yes — deliver here** |
| `transferred` | funds moved to merchant account | yes |
| `declined` | client interrupted / refused | no — retry possible |
| `canceled` | insufficient balance / payment problem | no — retry possible |
| `expired` | not finalized in time | yes |
| `refunded` | amount returned to client | yes |

Only `approved` (or `transferred`) means deliver value. `canceled`/`declined` are **not** terminal — a new attempt on the same transaction can still succeed, so never mark an order failed on those alone.

## Quickstart (Node, hosted-page happy path)

Server — the only place a payment becomes real:

```javascript
const { FedaPay, Transaction } = require('fedapay');
FedaPay.setApiKey(process.env.FEDAPAY_SECRET_KEY); // sk_sandbox_... / sk_live_...
FedaPay.setEnvironment('sandbox');                  // 'sandbox' | 'live'

// 1. create + 2. token
const tx = await Transaction.create({
  description: 'Order #1234',
  amount: 1000,                    // integer, no decimals
  currency: { iso: 'XOF' },
  callback_url: 'https://your.app/callback',
  merchant_reference: 'CMD-1234',  // your order id
  customer: { email: 'john@doe.com' },
});
const token = await tx.generateToken();
// 3. pay → send the customer to token.url (redirect on web, WebView on mobile)
return redirect(token.url);
```

Later, on callback or webhook — **verify before delivering**:

```javascript
const tx = await Transaction.retrieve(id);
if (tx.status !== 'approved' || tx.amount !== expectedAmount) return; // reject
// deliver value here, exactly once (idempotent)
```

Full per-language and per-flow code lives in [`references/server.md`](references/server.md).

## Keys & environment

Two **modes** (sandbox / live), each with two **types** of key. Never mix modes — objects created in test are invisible in live.

| Key | Where | Exposure |
| --- | --- | --- |
| Public (`pk_...`) | Client — Checkout.js, front-end | Public — fine in the browser |
| Secret (`sk_...`) | Server only | **Secret** — never in client code or Git |

Get both from the dashboard. Set the environment on every call: `FedaPay.setEnvironment('sandbox' | 'live')`, or hit the right host directly with `Authorization: Bearer <secret>`:

- Sandbox: `https://sandbox-api.fedapay.com`
- Live: `https://api.fedapay.com`

Sandbox test numbers, currencies, and the go-live checklist: [`references/sandbox.md`](references/sandbox.md).

## Pick your flow

| Flow | When | Read |
| --- | --- | --- |
| **Checkout.js** | Web/SaaS, you want a drop-in button or embedded form, minimal backend | [`references/checkout.md`](references/checkout.md) |
| **API token/URL** | You control the backend; works for web **and** mobile — create the transaction, open `token.url` | [`references/server.md`](references/server.md) |
| **No-redirect mobile money** | Keep the user in-app; trigger MTN/Moov directly (BJ, TG, CI) | [`references/server.md`](references/server.md) |
| **Mobile app** | Flutter / React Native / native — no official mobile SDK; use `token.url` in a WebView or no-redirect | [`references/mobile.md`](references/mobile.md) |

All flows end at the same place: **server-side verify**.

## Integration steps

1. **Keys** — get the sandbox public + secret keys from the dashboard. Put the **secret** key in a server environment variable; the public key is the only one allowed near client code. Done when the secret key loads server-side and appears nowhere in the client bundle or Git.

2. **Create transaction + token** — server-side with the secret key, create the transaction (`amount` integer, `currency.iso: 'XOF'`, `description`, `callback_url`, `merchant_reference`, optional `customer`) and call `generateToken()` for `token.url` + `token.token`. Code per language in [`references/server.md`](references/server.md). Done when a create returns a transaction id and a token whose `url` opens the FedaPay payment page.

3. **Collect the payment** — send the customer to `token.url` (web redirect or mobile WebView), or embed **Checkout.js** ([`references/checkout.md`](references/checkout.md)), or trigger **no-redirect** mobile money server-side ([`references/server.md`](references/server.md)). Mobile specifics in [`references/mobile.md`](references/mobile.md). Done when a customer can complete a sandbox payment and lands back on your `callback_url`.

4. **Verify server-side** — receive the transaction id (from `callback_url` params or the webhook), call `Transaction.retrieve(id)`, apply the **cardinal rule**, then deliver value idempotently. Done when value is delivered only on `status === "approved"` **and** matching amount, with an amount-tampered or non-approved transaction rejected.

5. **Webhook (recommended)** — the reliable path for no-redirect and for customers who close the tab before step 4. Create the endpoint + secret on the dashboard, verify the `X-FEDAPAY-SIGNATURE` header with `Webhook.constructEvent`, respond `2xx` fast, then re-verify and fulfill. Payloads, events, retries, replay protection in [`references/webhooks.md`](references/webhooks.md). Done when a signed `transaction.approved` triggers an idempotent, verified delivery.

6. **Go to production** — swap sandbox keys for live keys (client **and** server), set `setEnvironment('live')`, point hosts at `api.fedapay.com`, and **authorize your domain** in the dashboard if you use Checkout.js (`references/checkout.md`). Done when no sandbox key and no `sandbox` environment remains, confirmed by searching the code.

## Out of scope

- **PCI / raw card data** — FedaPay hosts the card and mobile-money form; this skill never stores or transmits raw card data yourself.
- **Account & key provisioning** — creating and activating a merchant account and obtaining keys are dashboard actions, not code.
- **Payouts / dépôts accounting** — sending funds to a customer's mobile money (`Payout`) and reconciling your FedaPay balance to your books are separate flows; this skill covers collecting payments (collectes), not settlement.
- **CMS plugins** — WooCommerce, Prestashop, Odoo, OpenCart, WHMCS configuration is dashboard/plugin setup, not an API integration.
- **API version** — written against FedaPay **v1** and Checkout.js `v1.1.7`. Verify package versions (npm/composer/gem) and the CDN version before shipping.
