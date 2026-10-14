-- 0001: base schema for the warranty vault.
--
-- Every user table is owned by auth.uid() and closed by RLS. GRANT and RLS
-- are separate gates; both are written for every table. The rights engine
-- does NOT live in SQL: deadlines are computed from assets/rules/rules.json
-- on the client (and later in the reminder edge function from the same file),
-- so the database stores facts (dates, region, channel), never conclusions.

create table public.profiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  -- Default region for new purchases (ISO 3166-1 alpha-2); a purchase can override.
  home_region text not null default 'DE' check (home_region ~ '^[A-Z]{2}$'),
  locale      text not null default 'en',
  created_at  timestamptz not null default now()
);

create table public.items (
  id                    uuid primary key default gen_random_uuid(),
  user_id               uuid not null default auth.uid() references auth.users (id) on delete cascade,
  name                  text not null check (length(name) between 1 and 200),
  store                 text not null default '',
  serial                text,
  category              text not null default 'other',
  price                 numeric(14, 2),
  currency              char(3),
  purchased_on          date not null,
  region                text not null check (region ~ '^[A-Z]{2}$'),
  channel               text not null default 'store' check (channel in ('store', 'online')),
  manufacturer_months   int check (manufacturer_months between 0 and 600),
  manufacturer_lifetime boolean not null default false,
  extended_until        date,
  -- Store's own goodwill return window, if printed on the receipt.
  store_return_days     int check (store_return_days between 0 and 365),
  archived_at           timestamptz,
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now()
);
create index items_user_idx on public.items (user_id) where archived_at is null;

-- Receipts, invoices, warranty cards, photos. The file itself lives in the
-- private `documents` storage bucket under <user_id>/...
create table public.documents (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null default auth.uid() references auth.users (id) on delete cascade,
  item_id      uuid references public.items (id) on delete cascade,
  kind         text not null check (kind in ('receipt', 'invoice', 'warranty_card', 'photo', 'other')),
  storage_path text not null,
  -- Raw reader output kept for re-checks; never shown as-is.
  extracted    jsonb,
  created_at   timestamptz not null default now()
);
create index documents_item_idx on public.documents (item_id);

-- Repairs and claims: repairs can extend the legal right where a verified
-- rule says so; claims are the "Bir sorun var" history.
create table public.events (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid() references auth.users (id) on delete cascade,
  item_id     uuid not null references public.items (id) on delete cascade,
  kind        text not null check (kind in ('repair', 'claim_opened', 'claim_closed', 'note')),
  happened_on date not null,
  note        text,
  created_at  timestamptz not null default now()
);
create index events_item_idx on public.events (item_id);

-- One row per scheduled reminder, so a push is sent once even if the cron
-- runs twice (unique key), and the client can show what is coming.
create table public.reminders (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid() references auth.users (id) on delete cascade,
  item_id     uuid not null references public.items (id) on delete cascade,
  protection  text not null check (protection in ('returnWindow', 'shortTermReject', 'manufacturer', 'extended', 'legal')),
  ends_on     date not null,
  remind_on   date not null,
  sent_at     timestamptz,
  unique (item_id, protection, remind_on)
);
create index reminders_due_idx on public.reminders (remind_on) where sent_at is null;

-- updated_at trigger. SECURITY INVOKER is enough; search_path pinned anyway.
create function public.touch_updated_at() returns trigger
language plpgsql set search_path = '' as $$
begin
  new.updated_at := now();
  return new;
end $$;
create trigger items_touch before update on public.items
  for each row execute function public.touch_updated_at();

-- Profile row on sign-up. SECURITY DEFINER (auth schema trigger) → search_path pinned.
create function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id) values (new.id) on conflict do nothing;
  return new;
end $$;
revoke all on function public.handle_new_user() from public, anon, authenticated;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- RLS: owner-only on every table.
alter table public.profiles  enable row level security;
alter table public.items     enable row level security;
alter table public.documents enable row level security;
alter table public.events    enable row level security;
alter table public.reminders enable row level security;

create policy profiles_own on public.profiles
  for all to authenticated using (id = auth.uid()) with check (id = auth.uid());
create policy items_own on public.items
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy documents_own on public.documents
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy events_own on public.events
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
-- Reminders are written by the server (service_role); users only read them.
create policy reminders_read on public.reminders
  for select to authenticated using (user_id = auth.uid());

-- GRANT: anon gets nothing; authenticated gets exactly what RLS then narrows.
revoke all on public.profiles, public.items, public.documents, public.events, public.reminders from anon;
grant select, insert, update on public.profiles to authenticated;
grant select, insert, update, delete on public.items, public.documents, public.events to authenticated;
grant select on public.reminders to authenticated;

-- Private storage bucket; path prefix = owner id.
insert into storage.buckets (id, name, public) values ('documents', 'documents', false)
  on conflict (id) do nothing;
create policy documents_bucket_own on storage.objects
  for all to authenticated
  using (bucket_id = 'documents' and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'documents' and (storage.foldername(name))[1] = auth.uid()::text);

-- Fail loudly if a table was left open (pattern from sandikapp 0036/0042).
do $$
declare t text;
begin
  foreach t in array array['profiles', 'items', 'documents', 'events', 'reminders'] loop
    if not (select relrowsecurity from pg_class where oid = ('public.' || t)::regclass) then
      raise exception 'RLS is off on %', t;
    end if;
    if has_table_privilege('anon', 'public.' || t, 'select') then
      raise exception 'anon can read %', t;
    end if;
  end loop;
end $$;
