-- One row per user holding the whole personal-system state (checks, logs,
-- briefs…) as JSON. The app writes locally first and mirrors here, so the
-- program survives a lost or replaced phone.

create table if not exists public.personal_system (
  user_id    uuid primary key references auth.users (id) on delete cascade,
  state      jsonb not null,
  updated_at timestamptz not null default now()
);

alter table public.personal_system enable row level security;

create policy "personal_system: owner reads"
  on public.personal_system for select
  using (auth.uid() = user_id);

create policy "personal_system: owner inserts"
  on public.personal_system for insert
  with check (auth.uid() = user_id);

create policy "personal_system: owner updates"
  on public.personal_system for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "personal_system: owner deletes"
  on public.personal_system for delete
  using (auth.uid() = user_id);
