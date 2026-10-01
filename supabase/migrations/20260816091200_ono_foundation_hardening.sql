-- Follow-up hardening after upgrading the legacy schema.

alter table public.blueprints
  alter column user_id set not null;

alter table public.blueprints
  add constraint blueprints_source_check
  check (source in ('static', 'ai'));

alter table public.daily_actions
  add constraint daily_actions_title_not_blank
  check (btrim(title) <> '');
