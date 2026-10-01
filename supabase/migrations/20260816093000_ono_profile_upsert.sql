-- Permit authenticated users to create only their own profile when a legacy
-- account predates the auth-user profile trigger.

grant insert on public.profiles to authenticated;

create policy "Users create own profile"
  on public.profiles for insert to authenticated
  with check ((select auth.uid()) = user_id);
