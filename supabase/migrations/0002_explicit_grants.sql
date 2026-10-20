-- Explicit Data API grants for every role that really touches each table.
--
-- From 30 Oct 2026 Supabase no longer grants new public tables to the API
-- roles by default (github.com/orgs/supabase/discussions/45329), and that
-- also applies to a local `supabase db reset` replaying 0001. 0001 already
-- wrote `authenticated` and `anon` explicitly; `service_role` relied on the
-- default, but the reminder cron writes `reminders` as service_role and
-- reads the items it is about. Written once here so the access is the same
-- on an old project, a new one and a fresh local stack.

-- Reminder cron: reads what is owned and when it ends, writes the schedule.
grant select on public.profiles, public.items to service_role;
grant select, insert, update, delete on public.reminders to service_role;

-- Users only read their reminders (0001's policy). On projects created before
-- the change the default still handed `authenticated` every privilege; RLS
-- blocked the writes, but the grant now says the same thing.
revoke insert, update, delete, truncate on public.reminders from authenticated;

-- documents/events are never touched server-side; no grant on purpose.

-- Fail loudly if a role ended up with less (or anon with more) than above.
do $$
declare t text;
begin
  if not has_table_privilege('service_role', 'public.reminders', 'insert')
     or not has_table_privilege('service_role', 'public.reminders', 'update')
     or not has_table_privilege('service_role', 'public.items', 'select') then
    raise exception 'service_role is missing its reminder grants';
  end if;
  if not has_table_privilege('authenticated', 'public.reminders', 'select')
     or has_table_privilege('authenticated', 'public.reminders', 'insert') then
    raise exception 'authenticated must only read reminders';
  end if;
  foreach t in array array['profiles', 'items', 'documents', 'events', 'reminders'] loop
    if has_table_privilege('anon', 'public.' || t, 'select')
       or has_table_privilege('anon', 'public.' || t, 'insert') then
      raise exception 'anon can reach %', t;
    end if;
  end loop;
end $$;
