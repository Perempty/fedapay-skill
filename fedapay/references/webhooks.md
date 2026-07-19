# FedaPay webhooks — the reliable confirmation path

A webhook is FedaPay POSTing an **event** to your endpoint when something happens (`transaction.approved`, `transaction.declined`, …). It's the dependable way to catch payments the customer never redirects back from — especially no-redirect mobile money. Treat the event as a **trigger to verify**, not as proof by itself.

## Setup (dashboard)

1. Dashboard → **Webhooks** → **Créer un Webhook**.
2. Enter your HTTPS endpoint URL (must be HTTPS, valid SSL, TLS 1.2/1.3).
3. Choose events — listen to **only** what you need (e.g. `transaction.approved`), not all.
4. Reveal the endpoint's **secret** (`wh_sandbox...` / `wh_live...`) — unique per endpoint, different per mode. Store it server-side.

## Verify the signature — Node.js

The signature is in the `X-FEDAPAY-SIGNATURE` header. `Webhook.constructEvent` validates it and the embedded timestamp (replay protection). **You need the raw request body** — parse it as a buffer, not JSON.

```javascript
const { Webhook } = require('fedapay');
const express = require('express');
const app = express();
const endpointSecret = process.env.FEDAPAY_WEBHOOK_SECRET; // wh_sandbox...

app.post('/webhook', express.raw({ type: 'application/json' }), async (req, res) => {
  const sig = req.headers['x-fedapay-signature'];
  let event;
  try {
    event = Webhook.constructEvent(req.body, sig, endpointSecret);
  } catch (err) {
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  // Respond FAST, before heavy work
  res.json({ received: true });

  // Dedup: skip if this event id was already processed
  switch (event.name) {
    case 'transaction.approved': {
      // re-verify server-side (cardinal rule) then fulfill idempotently
      const { Transaction } = require('fedapay');
      const tx = await Transaction.retrieve(event.entity.id);
      if (tx.status === 'approved' /* && tx.amount === expected */) {
        // deliver value, exactly once
      }
      break;
    }
    case 'transaction.declined':
    case 'transaction.canceled':
      break;
    default:
      break;
  }
});
```

## Verify the signature — PHP

```php
$endpoint_secret = getenv('FEDAPAY_WEBHOOK_SECRET'); // wh_...
$payload    = @file_get_contents('php://input');     // raw body
$sig_header = $_SERVER['HTTP_X_FEDAPAY_SIGNATURE'];

try {
    $event = \FedaPay\Webhook::constructEvent($payload, $sig_header, $endpoint_secret);
} catch (\UnexpectedValueException $e) {
    http_response_code(400); exit();               // invalid payload
} catch (\FedaPay\Error\SignatureVerification $e) {
    http_response_code(400); exit();               // invalid signature
}

http_response_code(200); // ack fast

switch ($event->name) {
    case 'transaction.approved':
        // re-verify + fulfill idempotently
        break;
}
```

## Events you'll care about

Transaction lifecycle: `transaction.created`, `transaction.approved`, `transaction.declined`, `transaction.canceled`, `transaction.transferred`, `transaction.updated`. Customer: `customer.created`, `customer.updated`, `customer.deleted`.

## Rules that keep it reliable

- **Ack with `2xx` immediately**, then do the heavy work. Any non-2xx counts as a failure.
- **Retries**: on failure FedaPay retries up to **9 more times** at exponential intervals (max ~2 min apart). After 10 total failures the webhook is **auto-disabled** — uncheck "Désactiver le webhook lorsque l'application génère des erreurs" to prevent that.
- **Idempotency**: the same event can arrive more than once. Dedup on the event id (+ `name`); fulfill exactly once.
- **Process async**: push heavy handling onto a queue; don't block the response.
- **Replay protection**: the timestamp inside `X-FEDAPAY-SIGNATURE` is signed — reject events whose timestamp is too old. Each retry carries a fresh signature + timestamp.
- **Trust source**: FedaPay sends from a defined IP list; combine signature verification with IP allow-listing if you can.
- Manual re-fire: webhook page → **Logs** → **Re-déclencher**.
