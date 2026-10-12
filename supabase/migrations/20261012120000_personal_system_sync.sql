-- Sync between devices (the iPhone and the web app): every write bumps
-- `version`, and a device only writes over the version it merged with, so
-- two devices saving at once can't overwrite each other.

alter table public.personal_system
  add column if not exists version bigint not null default 0;
