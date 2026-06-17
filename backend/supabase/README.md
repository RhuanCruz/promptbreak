# PromptBreak — Backend Setup

## Prerequisites
- [Supabase CLI](https://supabase.com/docs/guides/cli): `brew install supabase/tap/supabase`
- [Stripe CLI](https://stripe.com/docs/stripe-cli): `brew install stripe/stripe-cli/stripe`
- Stripe account (test mode for dev, live mode for production)
- Supabase project (create at supabase.com)

---

## 1. Supabase project

### Local development
```bash
supabase init        # if not done already
supabase start       # starts local Postgres + API
supabase db push     # applies migrations/0001_licenses.sql
```

### Deploy to remote project
```bash
# Link to your remote project
supabase link --project-ref <your-project-ref>

# Push migration
supabase db push

# Or via Claude Code MCP (apply_migration tool), paste content of 0001_licenses.sql
```

### Set environment secrets for edge functions
```bash
supabase secrets set STRIPE_SECRET_KEY=sk_test_...
supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_...
```
`SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are injected automatically by the Supabase runtime.

### Deploy edge functions
```bash
supabase functions deploy stripe-webhook
supabase functions deploy validate-license
supabase functions deploy license-page
```

Function URLs will be:
- `https://<project>.supabase.co/functions/v1/stripe-webhook`
- `https://<project>.supabase.co/functions/v1/validate-license`
- `https://<project>.supabase.co/functions/v1/license-page`

---

## 2. Stripe setup (test mode)

### Products & prices

Create 3 products in [Stripe Dashboard](https://dashboard.stripe.com) → Products:

| Product | Price | Type | `price_id` |
|---------|-------|------|------------|
| PromptBreak Monthly | $4.99 | Recurring (monthly) | `price_monthly_...` |
| PromptBreak Annual | $34.99 | Recurring (yearly) | `price_annual_...` |
| PromptBreak Lifetime | $79 | One-time | `price_lifetime_...` |

### Payment Links

For each product create a **Payment Link** (Dashboard → Payment Links → New):
- Add the relevant price.
- Set **Success URL**: `https://<project>.supabase.co/functions/v1/license-page?session_id={CHECKOUT_SESSION_ID}`
  - The `{CHECKOUT_SESSION_ID}` placeholder is filled by Stripe automatically.
- Enable "Collect customer email".

Copy the payment link URLs and update in `PromptBreak/Services/LicenseService.swift`:
```swift
let stripeMonthlyURL  = URL(string: "https://buy.stripe.com/...")!
let stripeAnnualURL   = URL(string: "https://buy.stripe.com/...")!
let stripeLifetimeURL = URL(string: "https://buy.stripe.com/...")!
```

### Webhook endpoint

Dashboard → Developers → Webhooks → Add endpoint:
- URL: `https://<project>.supabase.co/functions/v1/stripe-webhook`
- Events to listen for:
  - `checkout.session.completed`
  - `invoice.paid`
  - `customer.subscription.updated`
  - `customer.subscription.deleted`

Copy the **Signing secret** (`whsec_...`) and set it:
```bash
supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_...
```

### Customer Portal

Dashboard → Settings → Billing → Customer Portal: enable and configure.
The portal URL is your Stripe account link — it's typically:
`https://billing.stripe.com/p/login/<your-account-id>`

Update in `AccountView.swift`:
```swift
URL(string: "https://billing.stripe.com/p/login/<your-account-id>")
```

---

## 3. Local webhook testing

```bash
stripe listen --forward-to localhost:54321/functions/v1/stripe-webhook
```

Trigger test events:
```bash
stripe trigger checkout.session.completed
stripe trigger invoice.paid
stripe trigger customer.subscription.deleted
```

---

## 4. App configuration

Update `PromptBreak/Services/LicenseService.swift`:
```swift
private let edgeFunctionBase = "https://<your-project>.supabase.co/functions/v1"
```

---

## 5. Pre-release: signing & notarisation

Not required for local dev. Required to distribute the `.dmg`:

1. Enroll in [Apple Developer Program](https://developer.apple.com/programs/) ($99/yr).
2. Create a **Developer ID Application** certificate in Xcode → Settings → Accounts.
3. In `project.yml`, set `DEVELOPMENT_TEAM` and `CODE_SIGN_IDENTITY: "Developer ID Application"`.
4. Build archive: Xcode → Product → Archive.
5. Distribute → Developer ID → Notarise.
6. Export `.dmg` or wrap with [create-dmg](https://github.com/create-dmg/create-dmg).
