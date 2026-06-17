import Stripe from "https://esm.sh/stripe@14?target=deno";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY")!, { apiVersion: "2024-04-10" });
const webhookSecret = Deno.env.get("STRIPE_WEBHOOK_SECRET")!;

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

Deno.serve(async (req) => {
  if (req.method !== "POST") return new Response("Method Not Allowed", { status: 405 });

  const sig = req.headers.get("stripe-signature");
  if (!sig) return new Response("Missing signature", { status: 400 });

  const body = await req.text();
  let event: Stripe.Event;
  try {
    event = stripe.webhooks.constructEvent(body, sig, webhookSecret);
  } catch (err) {
    return new Response(`Webhook signature error: ${err.message}`, { status: 400 });
  }

  try {
    switch (event.type) {
      case "checkout.session.completed":
        await handleCheckoutComplete(event.data.object as Stripe.Checkout.Session);
        break;

      case "invoice.paid":
        await handleInvoicePaid(event.data.object as Stripe.Invoice);
        break;

      case "customer.subscription.updated":
        await handleSubscriptionUpdate(event.data.object as Stripe.Subscription);
        break;

      case "customer.subscription.deleted":
        await handleSubscriptionDeleted(event.data.object as Stripe.Subscription);
        break;

      default:
        // Ignore other events
    }
  } catch (err) {
    console.error("Handler error:", err);
    return new Response("Internal error", { status: 500 });
  }

  return new Response(JSON.stringify({ received: true }), {
    headers: { "Content-Type": "application/json" },
  });
});

async function handleCheckoutComplete(session: Stripe.Checkout.Session) {
  const customerID = typeof session.customer === "string" ? session.customer : session.customer?.id;
  if (!customerID) throw new Error("No customer ID in session");

  const email = session.customer_details?.email ?? "";
  const isLifetime = session.mode === "payment";

  let plan: string;
  let subscriptionID: string | null = null;
  let periodEnd: string | null = null;

  if (isLifetime) {
    plan = "lifetime";
  } else {
    // Retrieve subscription to get plan + period
    const subID = typeof session.subscription === "string" ? session.subscription : session.subscription?.id;
    if (!subID) throw new Error("No subscription in session");
    const sub = await stripe.subscriptions.retrieve(subID);
    plan = determinePlan(sub);
    subscriptionID = sub.id;
    periodEnd = new Date(sub.current_period_end * 1000).toISOString();
  }

  await supabase.from("licenses").upsert(
    {
      email,
      stripe_customer_id: customerID,
      stripe_subscription_id: subscriptionID,
      plan,
      status: "active",
      current_period_end: periodEnd,
    },
    { onConflict: "stripe_customer_id" },
  );
}

async function handleInvoicePaid(invoice: Stripe.Invoice) {
  const customerID = typeof invoice.customer === "string" ? invoice.customer : invoice.customer?.id;
  if (!customerID) return;

  const subID = typeof invoice.subscription === "string"
    ? invoice.subscription
    : invoice.subscription?.id;
  if (!subID) return;

  const sub = await stripe.subscriptions.retrieve(subID);
  await supabase.from("licenses").update({
    status: "active",
    current_period_end: new Date(sub.current_period_end * 1000).toISOString(),
  }).eq("stripe_customer_id", customerID);
}

async function handleSubscriptionUpdate(sub: Stripe.Subscription) {
  const customerID = typeof sub.customer === "string" ? sub.customer : sub.customer?.id;
  if (!customerID) return;

  await supabase.from("licenses").update({
    plan: determinePlan(sub),
    status: sub.status === "active" ? "active" : sub.status === "canceled" ? "canceled" : "expired",
    current_period_end: new Date(sub.current_period_end * 1000).toISOString(),
  }).eq("stripe_customer_id", customerID);
}

async function handleSubscriptionDeleted(sub: Stripe.Subscription) {
  const customerID = typeof sub.customer === "string" ? sub.customer : sub.customer?.id;
  if (!customerID) return;
  await supabase.from("licenses").update({ status: "canceled" }).eq("stripe_customer_id", customerID);
}

function determinePlan(sub: Stripe.Subscription): string {
  const interval = sub.items.data[0]?.price?.recurring?.interval;
  return interval === "year" ? "annual" : "monthly";
}
