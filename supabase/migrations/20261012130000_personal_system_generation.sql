-- A new row (first program, or after Delete everything) gets a new
-- generation. A device whose last agreed copy has another generation knows
-- the program was deleted elsewhere, even if the row was recreated since.

alter table public.personal_system
  add column if not exists generation uuid not null default gen_random_uuid();
