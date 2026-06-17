import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

Deno.serve(async (req) => {
  const url = new URL(req.url);
  const email = url.searchParams.get("email")?.toLowerCase().trim();

  // POST: email lookup (form submission)
  if (req.method === "POST") {
    let body: { email?: string };
    try { body = await req.json(); } catch { body = {}; }
    const lookupEmail = body.email?.toLowerCase().trim();
    if (!lookupEmail) return json({ error: "Email required" }, 400);

    const { data: row } = await supabase
      .from("licenses")
      .select("license_key, plan, status")
      .eq("email", lookupEmail)
      .eq("status", "active")
      .order("created_at", { ascending: false })
      .limit(1)
      .single();

    if (!row) return json({ error: "No active license found for this email." }, 404);

    const deepLink = `promptbreak://activate?key=${encodeURIComponent(row.license_key)}`;
    return json({ license_key: row.license_key, plan: row.plan, deep_link: deepLink });
  }

  // GET: show the page (success redirect from Stripe, or direct access)
  return html(`<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>PromptBreak — Get Your License</title>
<style>
* { box-sizing: border-box; margin: 0; padding: 0; }
body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; background: #0a0a0a; color: #f0f0f0; min-height: 100vh; display: flex; align-items: center; justify-content: center; }
.card { background: #1a1a1a; border: 1px solid #333; border-radius: 16px; padding: 40px; max-width: 480px; width: 90%; text-align: center; }
h1 { font-size: 28px; margin-bottom: 8px; }
.sub { color: #999; margin-bottom: 32px; font-size: 15px; }
input[type=email] { width: 100%; padding: 12px 16px; border-radius: 8px; border: 1px solid #444; background: #0a0a0a; color: #f0f0f0; font-size: 16px; margin-bottom: 12px; outline: none; }
input[type=email]:focus { border-color: #2563eb; }
button { width: 100%; background: #2563eb; color: white; padding: 13px; border: none; border-radius: 8px; font-size: 16px; font-weight: 600; cursor: pointer; }
button:hover { background: #1d4ed8; }
button:disabled { opacity: 0.5; cursor: default; }
.result { margin-top: 28px; display: none; }
.key-box { background: #0a0a0a; border: 1px solid #444; border-radius: 8px; padding: 14px; font-family: monospace; font-size: 17px; letter-spacing: 1px; word-break: break-all; margin-bottom: 12px; }
.copy-btn { background: #333; border: none; color: #f0f0f0; padding: 8px 20px; border-radius: 6px; cursor: pointer; font-size: 14px; margin-bottom: 20px; }
.activate-btn { display: inline-block; background: #16a34a; color: white; padding: 13px 28px; border-radius: 10px; text-decoration: none; font-size: 15px; font-weight: 600; }
.error { color: #f87171; margin-top: 12px; font-size: 14px; display: none; }
.manual { color: #555; font-size: 12px; margin-top: 14px; }
</style>
</head>
<body>
<div class="card">
  <h1>Payment confirmed!</h1>
  <p class="sub">Enter the email you used to pay and get your license key.</p>

  <input type="email" id="email" placeholder="you@example.com" autocomplete="email">
  <button id="btn" onclick="lookup()">Get my license key</button>
  <p class="error" id="err"></p>

  <div class="result" id="result">
    <p style="color:#4ade80;margin-bottom:16px;font-weight:600">Your license key:</p>
    <div class="key-box" id="key"></div>
    <button class="copy-btn" id="copyBtn" onclick="copyKey()">Copy key</button><br>
    <a class="activate-btn" id="activateBtn" href="#">Activate in PromptBreak →</a>
    <p class="manual">Or: PromptBreak → Account → paste key manually.</p>
  </div>
</div>

<script>
async function lookup() {
  const email = document.getElementById('email').value.trim();
  const btn = document.getElementById('btn');
  const errEl = document.getElementById('err');
  errEl.style.display = 'none';
  if (!email) return;
  btn.disabled = true;
  btn.textContent = 'Looking up…';

  try {
    const res = await fetch(window.location.pathname, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email })
    });
    const data = await res.json();
    if (!res.ok || data.error) {
      errEl.textContent = data.error || 'Something went wrong. Try again.';
      errEl.style.display = 'block';
      btn.disabled = false;
      btn.textContent = 'Get my license key';
      return;
    }
    document.getElementById('key').textContent = data.license_key;
    document.getElementById('activateBtn').href = data.deep_link;
    document.getElementById('result').style.display = 'block';
    btn.style.display = 'none';
    document.getElementById('email').style.display = 'none';
  } catch {
    errEl.textContent = 'Network error. Please try again.';
    errEl.style.display = 'block';
    btn.disabled = false;
    btn.textContent = 'Get my license key';
  }
}

function copyKey() {
  const key = document.getElementById('key').textContent;
  navigator.clipboard.writeText(key);
  document.getElementById('copyBtn').textContent = 'Copied!';
}

document.getElementById('email').addEventListener('keydown', e => {
  if (e.key === 'Enter') lookup();
});
</script>
</body>
</html>`);
});

function html(body: string, status = 200): Response {
  return new Response(body, { status, headers: { "Content-Type": "text/html; charset=utf-8" } });
}

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), { status, headers: { "Content-Type": "application/json" } });
}
