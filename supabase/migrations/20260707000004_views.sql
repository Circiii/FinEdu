-- =============================================================================
-- 04 · VIEWS (analytics groundwork)
-- Read models over daily_activity for retention metrics. No RLS on views —
-- they are queried by dashboards / service role, not by the app client.
-- (If they are ever exposed to clients, wrap them in SECURITY INVOKER views
-- over RLS-protected tables — the default in Postgres 15+ — or move them
-- behind an edge function.)
-- =============================================================================

-- v_daily_cohorts: one row per (user, day) with everything needed to compute
-- CURR / D1 / D7 / D30 downstream:
--
--   * signup_date    — the user's cohort (from auth.users.created_at)
--   * activity_date  — a day the user was active (any kind)
--   * day_n          — days since signup (0 = signup day)
--   * was_active_yesterday / was_active_7d — inputs for CURR-style
--     "given recent activity, did they return today?" queries.
--
-- Examples (run downstream, e.g. in a dashboard):
--   D1  retention of a cohort: share of users with a row at day_n = 1.
--   D7  retention: share with a row at day_n = 7.
--   CURR(day): among users with was_active_yesterday, share active that day.
create view public.v_daily_cohorts as
select
  da.user_id,
  u.created_at::date                              as signup_date,
  da.date                                         as activity_date,
  (da.date - u.created_at::date)                  as day_n,
  da.kinds,
  exists (
    select 1
    from public.daily_activity prev
    where prev.user_id = da.user_id
      and prev.date = da.date - 1
  )                                               as was_active_yesterday,
  exists (
    select 1
    from public.daily_activity prev
    where prev.user_id = da.user_id
      and prev.date >= da.date - 7
      and prev.date <  da.date
  )                                               as was_active_7d
from public.daily_activity da
join auth.users u on u.id = da.user_id;

comment on view public.v_daily_cohorts is
  'Per-(user, day) activity joined to signup cohort. Base for CURR/D1/D7/D30.';

-- ---------------------------------------------------------------------------
-- TODO (F5 — churn & risk):
--   * v_user_risk — RFM-style view (recency: days since last activity;
--     frequency: active days in last 14/30; monetary→"engagement depth":
--     distinct kinds per active day). Buckets feed the notification
--     escalation rules (1/3/7/21 days inactive) from PLAN2 §2.2.
--   * Consider materializing v_daily_cohorts (pg_cron refresh) once
--     daily_activity grows past ~1M rows.
-- ---------------------------------------------------------------------------
