# FedaPay server SDK — create, token, verify

The server SDK uses your **secret** key. Configure once: `setApiKey` + `setEnvironment('sandbox' | 'live')`. Three operations matter — **create** the transaction, **generateToken** for the payment URL, **retrieve** to verify.

Apply the SKILL's cardinal rule on verify: deliver only if `status === "approved"` **and** `amount === expectedAmount`.

Install:

```bash
npm install fedapay          # Node.js
composer require fedapay/fedapay-php   # PHP
gem install fedapay-ruby     # Ruby
```

## Node.js

```javascript
const { FedaPay, Transaction } = require('fedapay');
FedaPay.setApiKey(process.env.FEDAPAY_SECRET_KEY);
FedaPay.setEnvironment('sandbox'); // 'live' in production

// 1. Create
const tx = await Transaction.create({
  description: 'Order #1234',
  amount: 1000,                    // integer, currency's smallest unit expectation is none for XOF
  currency: { iso: 'XOF' },
  callback_url: 'https://your.app/callback',
  merchant_reference: 'CMD-1234',  // unique per order — creation fails if reused
  custom_metadata: { user_id: 'USER-42' }, // non-sensitive only
  customer: {                      // optional; email is the identity key
    firstname: 'John', lastname: 'Doe',
    email: 'john@doe.com',
    phone_number: { number: '+22997000000', country: 'bj' },
  },
  // customer: { id: 1 }           // ...or reference an existing customer
});

// 2. Token → hosted payment page
const token = await tx.generateToken();   // { url, token }
// redirect(token.url)  on web  |  open token.url in a WebView on mobile

// 4. Verify (on callback or webhook)
const fresh = await Transaction.retrieve(tx.id);
if (fresh.status !== 'approved' || fresh.amount !== expectedAmount) {
  return; // reject — do NOT deliver
}
// deliver value, exactly once (idempotent)

// Reconcile by your own id instead of FedaPay's:
const byRef = await Transaction.retrieveByMerchantReference('CMD-1234');
```

## PHP

```php
\FedaPay\FedaPay::setApiKey(getenv('FEDAPAY_SECRET_KEY'));
\FedaPay\FedaPay::setEnvironment('sandbox'); // 'live' in production

$tx = \FedaPay\Transaction::create([
  'description' => 'Order #1234',
  'amount' => 1000,
  'currency' => ['iso' => 'XOF'],
  'callback_url' => 'https://your.app/callback',
  'merchant_reference' => 'CMD-1234',
  'customer' => ['email' => 'john@doe.com'],
]);

$token = $tx->generateToken();          // $token->url, $token->token
header('Location: ' . $token->url);

// Verify
$fresh = \FedaPay\Transaction::retrieve($tx->id);
if ($fresh->status !== 'approved' || $fresh->amount != $expectedAmount) {
    return; // reject
}
// deliver (idempotent)

$byRef = \FedaPay\Transaction::retrieveByMerchantReference('CMD-1234');
```

## Ruby

```ruby
require 'fedapay'
FedaPay.api_key = ENV['FEDAPAY_SECRET_KEY']
FedaPay.environment = 'sandbox' # 'live' in production

tx = FedaPay::Transaction.create(
  description: 'Order #1234',
  amount: 1000,
  currency: { iso: 'XOF' },
  callback_url: 'https://your.app/callback',
  merchant_reference: 'CMD-1234',
  customer: { email: 'john@doe.com' }
)
token = tx.generate_token           # token.url, token.token
# redirect user to token.url

fresh = FedaPay::Transaction.retrieve(tx.id)
return unless fresh.status == 'approved' && fresh.amount == expected_amount
# deliver (idempotent)
```

## No-redirect mobile money (keep the user in-app)

Available for MTN Bénin, Moov Bénin, Moov Togo, MTN Côte d'Ivoire. Create the transaction, then trigger the operator directly — FedaPay pushes a payment prompt to the customer's phone. Confirm via **verify** or **webhook** (the call returns before the customer approves on their handset).

```javascript
const tx = await Transaction.create({
  description: 'Order #5678', amount: 1000, currency: { iso: 'XOF' },
  callback_url: 'https://your.app/callback', customer: { id: 1 },
});
const token = (await tx.generateToken()).token;
const mode = 'mtn';                    // 'mtn' | 'moov' | 'mtn_ci' | 'moov_tg'
const phone = { number: '64000001', country: 'bj' }; // sandbox success number

await tx.sendNowWithToken(mode, token, phone);
// or, in one step:
await tx.sendNow(mode, phone);
// then poll Transaction.retrieve(tx.id) or wait for the webhook → cardinal rule
```

PHP/Ruby expose the same `sendNowWithToken` / `sendNow` (`send_now_with_token` / `send_now` in Ruby). If `phone_number` is omitted, FedaPay uses the number attached to the transaction's customer.

## Notes

- **`amount` is an integer.** XOF has no decimal subunit — `1000` means 1000 FCFA.
- **`merchant_reference` must be unique** — creating a second transaction with the same reference fails. Use it to make retries idempotent.
- **`custom_metadata`**: key-value, non-sensitive data only (never card data, passwords). Stored on the transaction, does not affect processing.
- **Customer identity is the email.** Same email = same customer (FedaPay updates the existing profile with any new name/phone).
- **Verify must be idempotent** — the same transaction can be confirmed by both the callback and the webhook. Mark the order paid exactly once.
