# FedaPay in a mobile app (Flutter / React Native / native)

FedaPay has **no official native mobile SDK** — the SDKs are server-side (PHP, Node, Ruby) and web (React, Angular). So a mobile app integrates through your own backend, and the payment UI is either a **WebView on `token.url`** or **no-redirect mobile money**. The confirmation is identical to every other flow: **verify server-side**.

## Pattern A — WebView on the hosted page (works everywhere, all methods)

1. **Backend** creates the transaction and returns `token.url` to the app (see [`server.md`](server.md)). Never put the secret key in the app.
2. **App** opens `token.url` in a WebView / in-app browser.
3. FedaPay redirects to your `callback_url` (with `?id=...&status=...`) when done. The app detects that redirect and closes the WebView.
4. **App** tells the backend "check order X"; the **backend verifies** (`Transaction.retrieve` → cardinal rule) and returns the real result. Do **not** trust the `status` in the redirect URL.
5. A **webhook** ([`webhooks.md`](webhooks.md)) is your safety net if the user kills the app mid-payment.

Per platform, the WebView + redirect-detection piece:

- **Flutter** — `webview_flutter`; use `NavigationDelegate.onNavigationRequest` to catch the `callback_url` and pop. Or `flutter_custom_tabs` / `url_launcher` for a system browser + deep-link back.
- **React Native** — `react-native-webview`; watch `onNavigationStateChange` for the `callback_url`. Or `react-native-inappbrowser-reborn`.
- **Android (native)** — Chrome Custom Tabs, return via an `intent://` / App Link on `callback_url`.
- **iOS (native)** — `SFSafariViewController` or `ASWebAuthenticationSession`, return via a Universal Link on `callback_url`.

Make `callback_url` a route you control (a deep link / universal link / app link) so the app is brought back to foreground cleanly.

## Pattern B — no-redirect mobile money (no WebView)

For MTN/Moov (BJ, TG) and MTN CI you can skip the WebView entirely: the app collects the phone number, sends it to your backend, and the backend calls `sendNow(mode, phone)` ([`server.md`](server.md)). FedaPay pushes the USSD/OTP prompt to the customer's phone. The app then shows a "confirm on your phone" state and polls your backend (which calls `Transaction.retrieve`) or waits for the webhook.

Best UX for a native-feeling flow, but it only covers the operators that support no-redirect — fall back to Pattern A (WebView) for card and unsupported operators.

## Non-negotiables

- **Secret key stays on the backend.** The app only ever handles the public key (if it renders Checkout.js in a WebView you host) or nothing at all.
- **The app's success screen is optimistic UI, not truth.** Only the backend's server-side verify unlocks value.
- **Webhook is the backstop** for the "app closed before returning" case — mobile networks drop, users background apps.
