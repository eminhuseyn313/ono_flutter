-- =============================================================================
-- Ono – Schema (reflects the actual production state)
-- =============================================================================
-- Pre-existing tables: users, archetypes, blueprints, daily_actions,
--                      streaks, profiles, assessments, waitlist
-- Added by Ono Flutter migration: lane_scores, weekly_snapshots,
--   plus columns on profiles, blueprints, daily_actions
-- All tables use RLS.
-- =============================================================================

-- ── Lane Scores (added for progress tracking) ──────────────────────────────

create table if not exists public.lane_scores (
  user_id uuid not null references auth.users(id) on delete cascade,
  lane text not null check (lane in ('mind', 'body', 'social', 'skill')),
  score double precision not null default 0.0 check (score >= 0 and score <= 1),
  updated_at timestamptz not null default now(),

  primary key (user_id, lane)
);

alter table public.lane_scores enable row level security;

create policy "Users can read own scores"
  on public.lane_scores for select using (auth.uid() = user_id);

create policy "Users can upsert own scores"
  on public.lane_scores for insert with check (auth.uid() = user_id);

create policy "Users can update own scores"
  on public.lane_scores for update using (auth.uid() = user_id);

-- ── Weekly Snapshots (added for progress tracking) ─────────────────────────

create table if not exists public.weekly_snapshots (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  week_start date not null,
  lane_scores jsonb not null default '{}',
  overall_score double precision not null default 0.0,
  actions_completed integer not null default 0,
  actions_total integer not null default 0,
  created_at timestamptz not null default now(),

  unique (user_id, week_start)
);

create index if not exists idx_snapshots_user
  on public.weekly_snapshots(user_id, week_start);

alter table public.weekly_snapshots enable row level security;

create policy "Users can read own snapshots"
  on public.weekly_snapshots for select using (auth.uid() = user_id);

create policy "Users can insert own snapshots"
  on public.weekly_snapshots for insert with check (auth.uid() = user_id);

-- ── Added columns on existing tables ───────────────────────────────────────

-- profiles: assessment_answers, onboarding_complete, display_name, notification_settings
alter table public.profiles add column if not exists assessment_answers jsonb not null default '{}';
alter table public.profiles add column if not exists onboarding_complete boolean not null default false;
alter table public.profiles add column if not exists display_name text;
alter table public.profiles add column if not exists notification_settings jsonb not null default '{"dailyNudge": true}';

-- blueprints: title, summary
alter table public.blueprints add column if not exists title text not null default '';
alter table public.blueprints add column if not exists summary text not null default '';

-- daily_actions: subtitle, order_index
alter table public.daily_actions add column if not exists subtitle text;
alter table public.daily_actions add column if not exists order_index integer not null default 0;

-- ── Streak Calculation Function ────────────────────────────────────────────

create or replace function public.calculate_streak(p_user_id uuid)
returns integer as $$
declare
  streak integer := 0;
  check_date date := current_date;
  total_actions integer;
  completed integer;
begin
  select count(*) into total_actions
  from public.daily_actions
  where user_id = p_user_id
    and action_date = check_date;

  if total_actions = 0 then
    return 0;
  end if;

  loop
    select count(*) into completed
    from public.daily_actions
    where user_id = p_user_id
      and action_date = check_date
      and completed = true;

    if completed >= total_actions then
      streak := streak + 1;
      check_date := check_date - interval '1 day';

      -- Re-check total for previous day
      select count(*) into total_actions
      from public.daily_actions
      where user_id = p_user_id
        and action_date = check_date;

      if total_actions = 0 then
        exit;
      end if;
    else
      exit;
    end if;
  end loop;

  return streak;
end;
$$ language plpgsql security definer;
