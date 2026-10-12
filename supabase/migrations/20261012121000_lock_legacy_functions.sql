-- Functions from the first ONO schema were callable by anyone through the
-- API. The app doesn't call them; only their triggers do.
revoke execute on function public.recalculate_lane_scores(uuid) from anon, authenticated, public;
revoke execute on function public.trigger_recalculate_lanes() from anon, authenticated, public;
revoke execute on function public.update_streak_on_completion() from anon, authenticated, public;
revoke execute on function public.rls_auto_enable() from anon, authenticated, public;
alter function public.recalculate_lane_scores(uuid) set search_path = public;
alter function public.trigger_recalculate_lanes() set search_path = public;
alter function public.update_streak_on_completion() set search_path = public;
