# fedapay-skill

A portable agent skill for integrating **FedaPay** payments (mobile money & card, Bénin & West Africa) into a **webapp/SaaS** or a **mobile app** — usable by any AI coding agent.

It encodes the one spine that keeps a FedaPay integration safe: **create → token → pay → verify**, with its cardinal rule — **`approved` server-side, or it didn't happen.** The `callback_url` status and the Checkout.js `onComplete` result are signals, not proof.

## What it covers

- **Checkout.js** — drop-in button & embedded form (vanilla, React `fedapay-reactjs`, Angular)
- **API token/URL flow** — server creates a transaction, customer pays on the hosted page (web redirect or mobile WebView)
- **No-redirect mobile money** — trigger MTN/Moov directly (BJ, TG, CI)
- **Mobile apps** — Flutter / React Native / native via WebView on `token.url` (no official native SDK)
- **Server SDKs** — Node.js, PHP, Ruby: create, `generateToken`, `retrieve`/verify, `merchant_reference`
- **Webhooks** — `X-FEDAPAY-SIGNATURE` verification, events, retries, idempotency, replay protection
- **Sandbox → live** — test numbers, statuses, go-live checklist

Written against the FedaPay **API v1** and **Checkout.js v1.1.7**. Verify package/CDN versions (npm/composer/gem) before shipping.

## Install

**With [skillkit](https://github.com/skillkit) (adapts to your agent automatically):**

```bash
skillkit install Perempty/fedapay-skill --skill=fedapay
```

**Manual copy (any agent that reads a skills folder):**

```bash
git clone https://github.com/Perempty/fedapay-skill
cp -r fedapay-skill/fedapay ~/.claude/skills/   # or your agent's skills dir
```

The skill is a single `fedapay/SKILL.md` plus `fedapay/references/*.md` in plain Markdown — copy the folder anywhere an agent can read it.

## Use

Once installed, just ask your agent:

> "Intègre FedaPay dans mon app Next.js / mon backend Node / mon app Flutter"

The agent invokes the skill and follows the 6 integration steps, pulling the right reference file for your stack.

## Layout

```
fedapay/
  SKILL.md              # the spine: cardinal rule, statuses, keys, quickstart, 6 steps
  references/
    server.md           # Node/PHP/Ruby: create, token, verify, no-redirect
    checkout.md         # Checkout.js: button, embed, React/Angular, data-attrs, domain auth
    webhooks.md         # signature verification, events, retries, idempotency
    mobile.md           # Flutter/RN/native WebView patterns
    sandbox.md          # test numbers, statuses, go-live checklist
```

## Source

Written against **FedaPay API v1** and **Checkout.js v1.1.7**. Verify package/CDN versions before shipping. Official docs: <https://docs.fedapay.com>.

## License

MIT © Perempty — see [LICENSE](LICENSE).
