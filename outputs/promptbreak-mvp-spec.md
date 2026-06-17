# PromptBreak — MVP Spec

**Version:** 0.1 (MVP)
**Date:** 2026-06-16
**Distribution:** Outside Mac App Store (`.dmg`, signed + notarized with Developer ID)

---

## Product

**PromptBreak** is a native macOS menu-bar app for power users of AI/dev tools (Cursor, Claude, Codex, Warp, Terminal, Xcode). It enforces regular movement breaks: after a configurable work interval the app blocks selected apps and opens a camera overlay. The user must complete a target number of squats — detected via the laptop camera — to unlock their tools.

### Target user
Developers and AI power users who spend 4–12 h/day in front of a screen, want to add movement to their workflow, but don't trust themselves to self-enforce breaks.

---

## Core loop

```
Work interval ends
        ↓
Apps blocked (soft nudge via NSWorkspace / Accessibility)
        ↓
Camera overlay opens (fullscreen floating window, all Spaces)
        ↓
User completes squat goal (counted by Vision body pose + fallback)
        ↓
Apps unblocked, timer resets
```

---

## Screens

### Today
- Next break countdown (HH:MM:SS)
- Daily rep counter (e.g. "42 squats today")
- Current streak (days with ≥ 1 completed break)
- "Start break now" button (manual trigger)
- Status: trial remaining / plan badge

### Rules
- Break interval (slider: 15 / 20 / 30 / 45 / 60 min)
- Squat goal per break (5 / 10 / 15 / 20)
- Active hours (start time – end time, defaults 09:00–18:00)
- Blocked apps (multi-select picker of running + installed apps)
- Block intensity:
  - **Soft** — overlay appears, no force-hide (honours user override)
  - **Hard** — repeating `hide()` calls until break is done (requires Accessibility)

### Account
- Plan name (Trial / Monthly / Annual / Lifetime)
- Trial days remaining or subscription renewal date
- License key field (paste to activate)
- "Activate in app" deep link hint
- "Manage billing" button → Stripe Customer Portal URL
- Permissions status:
  - Camera (AVFoundation)
  - Accessibility (AXIsProcessTrusted)
  - Notifications (UNUserNotificationCenter)
  - "Grant" button per missing permission

### Camera Overlay
- No sidebar, no settings, no close button
- Full-body camera preview (AVCaptureVideoPreviewLayer)
- Skeleton overlay (Vision joint dots, colour-coded by confidence)
- Rep counter (large, centre-screen): e.g. "3 / 10"
- Status line:
  - "Full body visible — keep going"
  - "Step back — need to see full body" (fallback mode)
  - "Squat detected" flash on each rep
- Escape / Cmd+Q disabled during active break

---

## Squat detection

### Primary path (full-body visible)
1. `VNDetectHumanBodyPoseRequest` per frame.
2. Extract `leftHip`, `rightHip`, `leftKnee`, `rightKnee` joints (confidence > 0.4).
3. Normalise hip Y against shoulder Y to get a `hipRatio` in [0, 1].
4. State machine: `standing` (hipRatio > 0.75) → `descending` → `bottom` (hipRatio < 0.45) → `ascending` → `standing` = **+1 rep**.
5. Hysteresis bands prevent noise from triggering false reps.

### Fallback path (lower body not visible — laptop camera at desk)
1. If `leftKnee` / `rightKnee` confidence < 0.4 for > 30 consecutive frames → enter fallback.
2. Track vertical displacement of shoulders/head (`leftShoulder` Y vs baseline).
3. Count rep when shoulder dips > threshold and returns to baseline (same state machine, looser thresholds).
4. Show "Step back — need to see full body" prompt.
5. Switching from fallback → primary resets the state machine (no double-count).

---

## App blocking

**Mechanism:** `NSWorkspace.shared.notificationCenter` + `didActivateApplicationNotification`. When a blocked app becomes frontmost during an active break:
- **Soft:** send `UNUserNotification` nag ("Complete your squats first").
- **Hard:** call `NSRunningApplication.hide()` and re-activate the overlay window.

**Limitations (acknowledged):**
- macOS does not allow inviolable app blocking without a System Extension.
- A determined user can kill PromptBreak or use Mission Control to bypass.
- The goal is a _strong nudge_, not a prison.

**Accessibility requirement:** `AXIsProcessTrusted()` must return true for Hard mode. If absent, the app falls back to Soft mode and prompts the user to grant permission.

---

## Monetisation

### Model
- **Free download** — 3-day full-feature trial (no nag during trial).
- **Monthly plan** — $4.99/mo (Stripe subscription, `price_monthly`).
- **Annual plan** — $34.99/yr (Stripe subscription, `price_annual`).
- **Lifetime** — $79 one-time (Stripe payment, `price_lifetime`).
- Paywall shown on trial expiry: choose plan → opens Stripe Payment Link in default browser.

### License activation flow
```
User pays via Payment Link
        ↓
Stripe webhook → stripe-webhook Edge Function
        ↓
Creates row in `licenses` table, generates unique license_key
        ↓
Redirects to license-page Edge Function (success_url)
        ↓
Page shows license key + "Activate in PromptBreak" button
        ↓
Button fires deep link: promptbreak://activate?key=<key>
        ↓
App validates key with validate-license Edge Function
        ↓
Caches response in Keychain with 72h offline grace
```

### Tela Account — pós-ativação
- Plan badge atualiza imediatamente.
- "Manage billing" abre Stripe Customer Portal (salvo no Info.plist ou via Edge Function).
- Lifetime: status = active, `valid_until` = null (sem expiração).

---

## Backend

Hosted on **Supabase** (Postgres + Edge Functions). No auth other than service-role key used by edge functions; the app communicates only via Edge Function endpoints.

### Table: `licenses`

| Column | Type | Notes |
|--------|------|-------|
| `id` | uuid PK | gen_random_uuid() |
| `email` | text | from Stripe checkout |
| `stripe_customer_id` | text | |
| `stripe_subscription_id` | text | null for lifetime |
| `plan` | text | monthly / annual / lifetime |
| `status` | text | active / canceled / expired |
| `license_key` | text unique | random 32-char alphanumeric |
| `current_period_end` | timestamptz | null for lifetime |
| `device_id` | text | set on first validate call |
| `created_at` | timestamptz | now() |
| `updated_at` | timestamptz | now() |

RLS disabled; functions use service role key via env var `SUPABASE_SERVICE_ROLE_KEY`.

### Edge Functions

**`stripe-webhook`**
- Verifies `Stripe-Signature` header against `STRIPE_WEBHOOK_SECRET`.
- `checkout.session.completed` → upsert license row, generate `license_key`.
- `invoice.paid` → update `status=active`, `current_period_end`.
- `customer.subscription.updated` → sync status + period.
- `customer.subscription.deleted` → set `status=canceled`.

**`validate-license`**
- `POST { license_key, device_id }`.
- On first call for a key: write `device_id` (device bind).
- Subsequent calls: reject if `device_id` mismatch.
- Returns `{ valid: bool, plan, status, valid_until }`.
- Lifetime: `valid=true` always while `status=active`.

**`license-page`**
- `GET ?session_id=<stripe_session_id>`.
- Retrieves license row via `stripe_customer_id` from Stripe API.
- Renders simple HTML: license key (monospace, copy button) + "Activate in PromptBreak" (`promptbreak://activate?key=...` link).

---

## Technical stack

| Concern | Choice |
|---------|--------|
| UI | SwiftUI (macOS 13+), AppKit where needed |
| Camera | AVFoundation |
| Body pose | Vision (`VNDetectHumanBodyPoseRequest`) |
| Blocking | NSWorkspace + NSRunningApplication |
| Permissions | AVCaptureDevice, AXIsProcessTrusted, UNUserNotificationCenter |
| Persistence | UserDefaults (rules/stats), Keychain (license key, device_id) |
| Backend | Supabase (Postgres + Edge Functions) |
| Payments | Stripe (Payment Links + Customer Portal + Webhook) |
| Distribution | .dmg, signed Developer ID, notarized |
| Project gen | XcodeGen (`project.yml`) |

---

## Permissions required

| Permission | Purpose | Graceful degradation |
|---|---|---|
| Camera | AVFoundation capture for squat detection | Overlay shows "Camera access required" |
| Accessibility | NSRunningApplication.hide() for Hard mode | Falls back to Soft mode automatically |
| Notifications | Nag notification in Soft mode | Silent (no nag, just overlay) |

---

## Assumptions

- The app will not attempt to block the Mac at OS level (no System/Network Extension in MVP).
- Blocking is soft; a determined user can bypass it.
- The camera needs to see the user's torso/head at minimum (squat fallback); full body preferred.
- Sold outside Mac App Store to avoid review risk on Accessibility usage.
- Notarisation is a pre-release step, not required during dev.
- Device binding is 1 device per license in MVP; multi-device support is post-MVP.
- Stripe Customer Portal handles subscription cancellation, upgrades, invoices.

---

## Test plan

### Permissions
- [ ] Launch with camera denied → overlay shows "Camera access required", no crash.
- [ ] Grant camera mid-session → overlay starts working without restart.
- [ ] Accessibility absent → Rules shows warning; block intensity forces to Soft.

### Break flow
- [ ] Set interval to 1 min in Rules → break triggers after ~1 min.
- [ ] Overlay opens fullscreen, covers other windows, appears in all Spaces.
- [ ] Escape and Cmd+Q do nothing during break.
- [ ] Open a blocked app during break → app hides (Hard mode) or nag notification fires (Soft).

### Squat detection
- [ ] Standing → crouch → standing = 1 rep counted (primary path, full body visible).
- [ ] Knees not visible → fallback activates, status shows "Step back".
- [ ] Fallback still counts reps on torso dip.
- [ ] Reach goal → overlay dismisses, apps unblocked, daily counter increments.
- [ ] Streak increments on second day if ≥ 1 break completed.

### License / monetisation
- [ ] Trial: 3 days full access, paywall shown on day 4 without license.
- [ ] Open Payment Link (test mode) → complete checkout → license-page shows key + deep link.
- [ ] Paste key in Account → app activates (plan badge updates).
- [ ] Deep link `promptbreak://activate?key=...` auto-fills and activates.
- [ ] Second device with same key → validate-license rejects (device_id mismatch).
- [ ] Lifetime key: `valid_until` null, status active, no expiry nag.
- [ ] Cancel subscription in Customer Portal → webhook fires → status=canceled → app shows expired on next revalidation.
- [ ] Offline grace: disable network → app works for 72h using cached Keychain value.

---

## Out of scope (MVP)
- iCloud sync of stats/rules.
- Multi-device licenses.
- Exercise variety (push-ups, jumping jacks).
- iOS/iPadOS companion app.
- Mac App Store distribution.
- Analytics / crash reporting (add Sentry post-MVP).
