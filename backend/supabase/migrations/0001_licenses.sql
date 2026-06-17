-- PromptBreak license table
-- Run via: supabase db push (local) or apply_migration MCP tool (remote)

create extension if not exists "pgcrypto";

create table public.licenses (
  id                     uuid primary key default gen_random_uuid(),
  email                  text not null,
  stripe_customer_id     text unique not null,
  stripe_subscription_id text unique,           -- null for lifetime (one-time payment)
  plan                   text not null check (plan in ('monthly', 'annual', 'lifetime')),
  status                 text not null default 'active' check (status in ('active', 'canceled', 'expired')),
  license_key            text unique not null default encode(gen_random_bytes(16), 'hex'),
  current_period_end     timestamptz,           -- null for lifetime
  device_id              text,                  -- bound on first validate-license call
  created_at             timestamptz not null default now(),
  updated_at             timestamptz not null default now()
);

-- Auto-update updated_at
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger licenses_updated_at
  before update on public.licenses
  for each row execute procedure public.set_updated_at();

-- No RLS — edge functions use service role key
alter table public.licenses disable row level security;

-- Indexes
create index on public.licenses (license_key);
create index on public.licenses (stripe_customer_id);
create index on public.licenses (stripe_subscription_id);
