# FedaPay integration skill

A Claude Code / agent **skill** for integrating [FedaPay](https://fedapay.com) payments (mobile money & card, Bénin & West Africa) into a **webapp/SaaS** or a **mobile app** — the right way, with server-side verification baked in.

Built from the official FedaPay documentation. The skill teaches the agent the one spine that matters — **create → token → pay → verify** — and its cardinal rule: **`approved` server-side, or it didn't happen.**

## What it covers

- **Checkout.js** — drop-in button & embedded form (vanilla, React `fedapay-reactjs`, Angular)
- **API token/URL flow** — server creates a transaction, customer pays on the hosted page (web redirect or mobile WebView)
- **No-redirect mobile money** — trigger MTN/Moov directly (BJ, TG, CI)
- **Mobile apps** — Flutter / React Native / native via WebView on `token.url` (no official native SDK)
- **Server SDKs** — Node.js, PHP, Ruby: create, `generateToken`, `retrieve`/verify, `merchant_reference`
- **Webhooks** — `X-FEDAPAY-SIGNATURE` verification, events, retries, idempotency, replay protection
- **Sandbox → live** — test numbers, statuses, go-live checklist

## Install

The skill is a folder named `fedapay` containing `SKILL.md` + `references/`. Put it where your agent looks for skills.

**Claude Code (personal skills):**

```bash
git clone https://github.com/Perempty/fedapay-skill.git /tmp/fedapay-skill
mkdir -p ~/.claude/skills/fedapay
cp /tmp/fedapay-skill/SKILL.md ~/.claude/skills/fedapay/
cp -r /tmp/fedapay-skill/references ~/.claude/skills/fedapay/
```

**Project skills** (share with a repo): copy the same into `.claude/skills/fedapay/` inside your project.

One-liner (clone + install personal):

```bash
bash <(curl -sSL https://raw.githubusercontent.com/Perempty/fedapay-skill/main/install.sh)
```

## Use

Once installed, just ask your agent:

> "Intègre FedaPay dans mon app Next.js / mon backend Node / mon app Flutter"

The agent invokes the skill and follows the 6 integration steps, pulling the right reference file for your stack.

## Layout

```
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

MIT © Perempty
