# FedaPay Checkout.js — web / SaaS front-end

Checkout.js is the drop-in front-end widget. It uses the **public** key only. Load the CDN script, call `FedaPay.init(...)`, and read the result in `onComplete`. Still verify server-side — `onComplete` is a signal, not proof.

```html
<script src="https://cdn.fedapay.com/checkout.js?v=1.1.7"></script>
```

## Simple button

```html
<button id="pay-btn">Payer 1000 FCFA</button>
<script>
  FedaPay.init('#pay-btn', {
    public_key: 'pk_sandbox_XXXX',
    transaction: { amount: 1000, description: 'Mon produit' },
    currency: { iso: 'XOF' },
    customer: { email: 'john@doe.com', lastname: 'Doe', firstname: 'John' },
    onComplete(resp) {
      if (resp.reason === FedaPay.CHECKOUT_COMPLETED) {
        // resp.transaction.id → send to your server to VERIFY before delivering
      } else if (resp.reason === FedaPay.DIALOG_DISMISSED) {
        // user closed the dialog
      }
    },
  });
</script>
```

## Embedded (no redirect, on your page)

```html
<div id="embed" style="width:500px;height:420px"></div>
<script>
  FedaPay.init({
    public_key: 'pk_sandbox_XXXX',
    transaction: { amount: 1000, description: 'Mon produit' },
    customer: { email: 'john@doe.com' },
    container: '#embed',
  });
</script>
```

## Trigger from your own event

```html
<button id="pay-btn">Payer</button>
<script>
  const widget = FedaPay.init({ public_key: 'pk_sandbox_XXXX' });
  document.getElementById('pay-btn').addEventListener('click', () => widget.open());
</script>
```

## Multiple buttons / data-attributes / form tag

Any option works as a `data-*` attribute — put per-button values on the element and one `FedaPay.init('.pay-btn', { public_key })`:

```html
<button class="pay-btn"
  data-transaction-amount="2000"
  data-transaction-description="Produit"
  data-customer-email="jane@doe.com">Payer 2000 FCFA</button>
```

Form-tag variant (submits your form after payment):

```html
<form action="/confirm" method="POST">
  <script src="https://cdn.fedapay.com/checkout.js?v=1.1.7"
    data-public-key="pk_sandbox_XXXX"
    data-button-text="Payer 1000"
    data-transaction-amount="1000"
    data-transaction-description="Produit"
    data-currency-iso="XOF"></script>
</form>
```

## React (`fedapay-reactjs`)

```bash
npm install fedapay-reactjs --save
```

Include the CDN script once in `public/index.html`, then:

```jsx
import { FedaCheckoutButton, FedaCheckoutContainer } from 'fedapay-reactjs';

const PUBLIC_KEY = 'pk_sandbox_XXXX';
const options = {
  public_key: PUBLIC_KEY,
  transaction: { amount: 100, description: 'Airtime' },
  currency: { iso: 'XOF' },
  button: { class: 'btn btn-primary', text: 'Payer 100 FCFA' },
  onComplete(resp) {
    const FedaPay = window['FedaPay'];
    if (resp.reason !== FedaPay.DIALOG_DISMISSED) {
      // resp.transaction.id → verify server-side
    }
  },
};

// Button OR embedded container:
<FedaCheckoutButton options={options} />
<FedaCheckoutContainer options={options} style={{ height: 500, width: 500 }} />
```

React lifecycle gotcha: guard the global `window.FedaPay` — a component unmounting mid-transaction can throw. Angular has an equivalent package `fedapay-angular`.

## Key options (JS key → `data-*` attribute)

| Option | Attribute | Notes |
| --- | --- | --- |
| `public_key` | `data-public-key` | required |
| `environment` | `data-environment` | `sandbox` \| `live` |
| `transaction.amount` | `data-transaction-amount` | integer, default 100 |
| `transaction.description` | `data-transaction-description` | |
| `transaction.id` | `data-transaction-id` | reuse a transaction you already created server-side |
| `transaction.custom_metadata` | `data-transaction-custom_metadata-<key>` | |
| `currency.iso` | `data-currency-iso` | default `XOF` |
| `customer.email` / `.firstname` / `.lastname` | `data-customer-email` … | |
| `customer.phone_number.number` / `.country` | `data-customer-phone_number-number` … | |
| `button.text` / `button.class` | `data-button-text` / `data-button-class` | |
| `locale` | `data-locale` | default `fr` |

`onComplete(resp)` → `resp.reason` is `FedaPay.CHECKOUT_COMPLETED` or `FedaPay.DIALOG_DISMISSED`; `resp.transaction` is the transaction object.

## Domain authorization (required before live)

Checkout.js only works on domains you've authorized, or customers get redirected to FedaPay's signup page instead of paying:

1. Dashboard → profile photo → **Applications**
2. **Nom de domaine à autoriser** → enter your domain (e.g. `votresite.com`) → **Autoriser**

Revoke under the same tab if you change domains.
