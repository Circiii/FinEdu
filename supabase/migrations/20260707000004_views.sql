-- =============================================================================
-- 04 · VEDERI (baza pentru statistici)
-- Vederi de citire peste daily_activity, pentru retenție. Nu au RLS: le
-- interoghează serverul, nu aplicația.
-- (Dacă ajung vreodată la clienți, se împachetează în vederi SECURITY INVOKER
-- peste tabele cu RLS, sau se mută în spatele unei funcții edge.)
-- =============================================================================

-- v_daily_cohorts: un rând per (utilizator, zi), cu tot ce trebuie ca să
-- calculezi retenția:
--
--   * signup_date    ziua înscrierii (din auth.users.created_at)
--   * activity_date  o zi în care utilizatorul a fost activ
--   * day_n          câte zile au trecut de la înscriere (0 = ziua înscrierii)
--   * was_active_yesterday și was_active_7d răspund la întrebarea „a revenit
--     azi cineva care a fost activ recent?"
--
-- Exemple de folosire:
--   retenție D1: câți utilizatori au un rând la day_n = 1
--   retenție D7: câți au un rând la day_n = 7
--   revenire zilnică: dintre cei activi ieri, câți au fost activi și azi
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
  'Activitatea pe zi, legată de ziua înscrierii. Baza pentru retenție.';

-- ---------------------------------------------------------------------------
-- De adăugat mai târziu:
--   * v_user_risk: cât de aproape e cineva de abandon (de câte zile n-a mai
--     intrat, câte zile active a avut în ultimele 14 sau 30, câte feluri de
--     activitate face într-o zi). Rezultatul hrănește escaladarea
--     notificărilor la 1, 3, 7 și 21 de zile de absență.
--   * v_daily_cohorts se poate materializa, cu refresh din cron, dacă
--     daily_activity trece de vreun milion de rânduri.
-- ---------------------------------------------------------------------------
