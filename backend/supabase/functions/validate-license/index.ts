import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

Deno.serve(async (req) => {
  if (req.method !== "POST") return new Response("Method Not Allowed", { status: 405 });

  let body: { license_key?: string; device_id?: string };
  try {
    body = await req.json();
  } catch {
    return json({ valid: false, error: "Invalid JSON" }, 400);
  }

  const { license_key, device_id } = body;
  if (!license_key || !device_id) {
    return json({ valid: false, error: "license_key and device_id are required" }, 400);
  }

  const { data: row, error } = await supabase
    .from("licenses")
    .select("*")
    .eq("license_key", license_key)
    .single();

  if (error || !row) {
    return json({ valid: false, error: "License not found" }, 200);
  }

  // Device binding — bind on first use
  if (!row.device_id) {
    await supabase.from("licenses").update({ device_id }).eq("license_key", license_key);
  } else if (row.device_id !== device_id) {
    return json({ valid: false, error: "Device mismatch" }, 200);
  }

  // Lifetime licenses never expire
  if (row.plan === "lifetime") {
    const valid = row.status === "active";
    return json({ valid, plan: row.plan, status: row.status, valid_until: null });
  }

  // Subscription — check period end
  const periodEnd = row.current_period_end ? new Date(row.current_period_end) : null;
  const expired = periodEnd ? periodEnd < new Date() : true;

  if (expired && row.status === "active") {
    await supabase.from("licenses").update({ status: "expired" }).eq("license_key", license_key);
    return json({ valid: false, plan: row.plan, status: "expired", valid_until: periodEnd?.toISOString() ?? null });
  }

  const valid = row.status === "active" && !expired;
  return json({ valid, plan: row.plan, status: row.status, valid_until: row.current_period_end });
});

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
