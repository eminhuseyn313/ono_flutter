-- ONO Foundation: authenticated journey persistence and streak read model.
-- This migration is intentionally unapplied. Review it before deploying.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  user_id uuid primary key references auth.users (id) on delete cascade,
  archetype text,
  onboarding_state jsonb not null default '{}'::jsonb,
  timezone text not null default 'UTC',
  journey_start_date date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_timezone_not_blank check (btrim(timezone) <> '')
);

create table if not exists public.assessments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  version integer not null default 1 check (version > 0),
  answers jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.blueprints (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  assessment_id uuid references public.assessments (id) on delete set null,
  version integer not null default 1 check (version > 0),
  source text not null default 'static' check (source in ('static', 'ai')),
  is_active boolean not null default true,
  lanes jsonb not null default '[]'::jsonb,
  milestones jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.daily_actions (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  blueprint_id uuid references public.blueprints (id) on delete set null,
  action_date date not null,
  lane text not null,
  title text not null check (btrim(title) <> ''),
  description text,
  completed_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.streaks (
  user_id uuid primary key references auth.users (id) on delete cascade,
  current_streak integer not null default 0 check (current_streak >= 0),
  longest_streak integer not null default 0 check (longest_streak >= 0),
  last_completed_date date,
  updated_at timestamptz not null default now()
);

-- Evolve legacy tables in place. Legacy columns remain intact so existing
-- clients keep working during the Flutter rollout.
alter table public.profiles
  add column if not exists archetype text,
  add column if not exists onboarding_state jsonb not null default '{}'::jsonb,
  add column if not exists timezone text not null default 'UTC',
  add column if not exists journey_start_date date,
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now();

alter table public.assessments
  add column if not exists version integer not null default 1,
  add column if not exists answers jsonb not null default '{}'::jsonb,
  add column if not exists created_at timestamptz not null default now();

alter table public.blueprints
  add column if not exists assessment_id uuid references public.assessments (id) on delete set null,
  add column if not exists version integer not null default 1,
  add column if not exists source text not null default 'static',
  add column if not exists is_active boolean not null default true,
  add column if not exists lanes jsonb not null default '[]'::jsonb,
  add column if not exists milestones jsonb not null default '[]'::jsonb;

do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'daily_actions' and column_name = 'date'
  ) and not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'daily_actions' and column_name = 'action_date'
  ) then
    alter table public.daily_actions rename column date to action_date;
  end if;
end;
$$;

alter table public.daily_actions
  add column if not exists action_date date,
  add column if not exists lane text,
  add column if not exists title text,
  add column if not exists description text,
  add column if not exists completed_at timestamptz,
  add column if not exists created_at timestamptz not null default now();

-- Backfill legacy values before Foundation columns become required.
update public.daily_actions
set lane = coalesce(lane, to_jsonb(daily_actions) ->> 'domain', 'Wildcard'),
    title = coalesce(title, to_jsonb(daily_actions) ->> 'action', 'Daily action'),
    completed_at = case
      when coalesce((to_jsonb(daily_actions) ->> 'completed')::boolean, false)
        and completed_at is null then action_date::timestamptz
      else completed_at
    end
where lane is null or title is null
  or (coalesce((to_jsonb(daily_actions) ->> 'completed')::boolean, false) and completed_at is null);

alter table public.daily_actions
  alter column user_id set not null,
  alter column action_date set not null,
  alter column lane set not null,
  alter column title set not null;

alter table public.streaks
  add column if not exists last_completed_date date,
  add column if not exists updated_at timestamptz not null default now();

do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'streaks' and column_name = 'last_active'
  ) then
    execute 'update public.streaks set last_completed_date = coalesce(last_completed_date, last_active)';
  end if;

  if exists (
    select 1 from public.streaks group by user_id having count(*) > 1
  ) then
    raise exception 'Cannot upgrade streaks: duplicate user_id rows require manual reconciliation';
  end if;

  alter table public.streaks alter column user_id set not null;
  if exists (
    select 1 from pg_constraint
    where conrelid = 'public.streaks'::regclass and contype = 'p'
  ) then
    alter table public.streaks drop constraint streaks_pkey;
  end if;
  alter table public.streaks add primary key (user_id);
end;
$$;

create unique index if not exists blueprints_one_active_per_user_idx
  on public.blueprints (user_id) where is_active;
create index assessments_user_created_idx
  on public.assessments (user_id, created_at desc);
create index daily_actions_user_date_idx
  on public.daily_actions (user_id, action_date);

alter table public.profiles enable row level security;
alter table public.assessments enable row level security;
alter table public.blueprints enable row level security;
alter table public.daily_actions enable row level security;
alter table public.streaks enable row level security;

grant select, update on public.profiles to authenticated;
grant select, insert, update, delete on public.assessments to authenticated;
grant select, insert, update, delete on public.blueprints to authenticated;
grant select, insert, update, delete on public.daily_actions to authenticated;
grant select on public.streaks to authenticated;
revoke insert, update, delete on public.streaks from anon, authenticated;

drop policy if exists "Users read own profile" on public.profiles;
drop policy if exists "Users update own profile" on public.profiles;
drop policy if exists "Users manage own assessments" on public.assessments;
drop policy if exists "Users manage own blueprints" on public.blueprints;
drop policy if exists "Users manage own daily actions" on public.daily_actions;
drop policy if exists "Users read own streak" on public.streaks;

create policy "Users read own profile" on public.profiles for select to authenticated
  using ((select auth.uid()) = user_id);
create policy "Users update own profile" on public.profiles for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
create policy "System creates own profile" on public.profiles for insert to authenticated
  with check ((select auth.uid()) = user_id);

create policy "Users manage own assessments" on public.assessments for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
create policy "Users manage own blueprints" on public.blueprints for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
create policy "Users manage own daily actions" on public.daily_actions for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
create policy "Users read own streak" on public.streaks for select to authenticated
  using ((select auth.uid()) = user_id);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (user_id, timezone)
  values (new.id, 'UTC')
  on conflict (user_id) do nothing;

  insert into public.streaks (user_id, current_streak, longest_streak)
  values (new.id, 0, 0)
  on conflict (user_id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

create or replace function public.recalculate_user_streak(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_timezone text;
  v_local_today date;
  v_dates date[];
  v_current_streak integer := 0;
  v_longest_streak integer := 0;
  v_running_streak integer := 0;
  v_previous_date date;
  v_date date;
  v_last_completed date;
  v_array_len integer;
begin
  select p.timezone into v_timezone from public.profiles p where p.user_id = p_user_id;
  if v_timezone is null or not exists (
    select 1 from pg_catalog.pg_timezone_names t where t.name = v_timezone
  ) then
    v_timezone := 'UTC';
  end if;
  v_local_today := pg_catalog.timezone(v_timezone, pg_catalog.now())::date;

  select pg_catalog.array_agg(d.action_date order by d.action_date)
    into v_dates
    from (
      select da.action_date
      from public.daily_actions da
      where da.user_id = p_user_id and da.completed_at is not null
      group by da.action_date
      having pg_catalog.count(*) >= 3
    ) d;
  v_array_len := pg_catalog.array_length(v_dates, 1);

  if v_array_len is null then
    insert into public.streaks (user_id, current_streak, longest_streak, last_completed_date, updated_at)
    values (p_user_id, 0, 0, null, pg_catalog.now())
    on conflict (user_id) do update set
      current_streak = 0, longest_streak = 0, last_completed_date = null, updated_at = excluded.updated_at;
    return;
  end if;

  foreach v_date in array v_dates loop
    if v_previous_date is null or v_date <> v_previous_date + 1 then
      v_running_streak := 1;
    else
      v_running_streak := v_running_streak + 1;
    end if;
    if v_running_streak > v_longest_streak then
      v_longest_streak := v_running_streak;
    end if;
    v_previous_date := v_date;
  end loop;

  v_last_completed := v_dates[v_array_len];
  if v_last_completed between v_local_today - 1 and v_local_today then
    for i in reverse v_array_len..1 loop
      if i = v_array_len or v_dates[i + 1] = v_dates[i] + 1 then
        v_current_streak := v_current_streak + 1;
      else
        exit;
      end if;
    end loop;
  end if;

  insert into public.streaks (user_id, current_streak, longest_streak, last_completed_date, updated_at)
  values (p_user_id, v_current_streak, v_longest_streak, v_last_completed, pg_catalog.now())
  on conflict (user_id) do update set
    current_streak = excluded.current_streak,
    longest_streak = excluded.longest_streak,
    last_completed_date = excluded.last_completed_date,
    updated_at = excluded.updated_at;
end;
$$;

create or replace function public.trigger_recalculate_streak()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.recalculate_user_streak(case when tg_op = 'DELETE' then old.user_id else new.user_id end);
  if tg_op = 'UPDATE' and old.user_id is distinct from new.user_id then
    perform public.recalculate_user_streak(old.user_id);
  end if;
  return case when tg_op = 'DELETE' then old else new end;
end;
$$;

create trigger tr_daily_actions_streak_recalc
  after insert or update of action_date, completed_at or delete on public.daily_actions
  for each row execute function public.trigger_recalculate_streak();

revoke all on function public.handle_new_user() from public, anon, authenticated;
revoke all on function public.recalculate_user_streak(uuid) from public, anon, authenticated;
revoke all on function public.trigger_recalculate_streak() from public, anon, authenticated;
