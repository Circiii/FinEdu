-- =============================================================================
-- 03 · ENGAGEMENT
-- Daily activity, streaks, acorn economy, quests.
--
-- Design rule (§3.2 PLAN2): the SERVER is the authority on the economy — the
-- client proposes, an RPC validates. In F0 we only lay the tables; the RPCs
-- (claim_quest, claim_chest, ...) come with their features in later phases.
-- =============================================================================

-- --- daily_activity ------------------------------------------------------------

-- One row per user per day; `kinds` lists what was done that day
-- (log | lesson | game | quest | review). Feeds the streak engine and the
-- CURR/D1/D7/D30 cohort views (migration 04).
create table public.daily_activity (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null
    references auth.users (id) on delete cascade,
  date date not null,
  kinds text[] not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  unique (user_id, date)
);

create trigger trg_daily_activity_updated_at
  before update on public.daily_activity
  for each row execute function public.set_updated_at();

-- --- streaks -------------------------------------------------------------------

-- Snapshot of the user's streak state; maintained by the daily rollover cron
-- (later phase) and reconciled with the client's local mirror.
create table public.streaks (
  user_id uuid primary key
    references auth.users (id) on delete cascade,
  current integer not null default 0,
  longest integer not null default 0,
  freezes_available integer not null default 2, -- "Ghinde de Gheață"
  earnback_until date,                          -- 48h earn-back window end
  last_activity_date date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger trg_streaks_updated_at
  before update on public.streaks
  for each row execute function public.set_updated_at();

-- --- acorn_ledger ----------------------------------------------------------------

-- Append-only ledger of acorn (ghinde) movements. Balance = sum(delta);
-- profiles.acorns is only a cached snapshot kept in sync by the trigger below.
create table public.acorn_ledger (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null
    references auth.users (id) on delete cascade,
  delta integer not null,          -- positive = earned, negative = spent
  reason text not null,            -- e.g. 'quest_claim', 'chest', 'purchase_item'
  ref uuid,                        -- optional reference (quest id, item id, ...)
  created_at timestamptz not null default now()
);

create index acorn_ledger_user_idx
  on public.acorn_ledger (user_id, created_at desc);

-- Keep profiles.acorns in sync as a snapshot of the ledger sum.
-- SECURITY DEFINER because clients have no UPDATE right on other users' rows
-- and, more importantly, no write access to the ledger at all (see RLS below).
create or replace function public.apply_acorn_delta()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.profiles
     set acorns = acorns + new.delta
   where user_id = new.user_id;
  return new;
end;
$$;

create trigger trg_acorn_ledger_snapshot
  after insert on public.acorn_ledger
  for each row execute function public.apply_acorn_delta();

-- --- quest_templates -------------------------------------------------------------

-- Definitions of daily quests (3/day assigned by cron in a later phase).
-- Content-like data: readable by every authenticated user, writable only by
-- service role / migrations — hence NO user RLS policies beyond SELECT.
create table public.quest_templates (
  id uuid primary key default gen_random_uuid(),
  slot integer not null check (slot between 1 and 3),
  kind text not null,              -- 'tracking' | 'learning' | 'arcade' | 'social' | 'saving'
  title text not null,
  description text,
  target integer not null default 1 check (target > 0),
  reward_acorns integer not null default 10 check (reward_acorns >= 0),
  active boolean not null default true,
  created_at timestamptz not null default now()
);

-- --- user_quests -----------------------------------------------------------------

-- The 3 quests assigned to a user for a given day + progress. Progress is
-- validated server-side at claim time (anti-cheat), not trusted from the client.
create table public.user_quests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null
    references auth.users (id) on delete cascade,
  quest_template_id uuid not null
    references public.quest_templates (id) on delete cascade,
  date date not null,
  progress integer not null default 0 check (progress >= 0),
  completed_at timestamptz,
  claimed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  unique (user_id, date, quest_template_id)
);

create index user_quests_user_date_idx
  on public.user_quests (user_id, date);

create trigger trg_user_quests_updated_at
  before update on public.user_quests
  for each row execute function public.set_updated_at();

-- --- RLS -------------------------------------------------------------------------

alter table public.daily_activity  enable row level security;
alter table public.streaks         enable row level security;
alter table public.acorn_ledger    enable row level security;
alter table public.quest_templates enable row level security;
alter table public.user_quests     enable row level security;

-- daily_activity: own-row (client writes its day rows; server aggregates)
create policy "daily_activity_select_own" on public.daily_activity
  for select to authenticated using (user_id = auth.uid());
create policy "daily_activity_insert_own" on public.daily_activity
  for insert to authenticated with check (user_id = auth.uid());
create policy "daily_activity_update_own" on public.daily_activity
  for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "daily_activity_delete_own" on public.daily_activity
  for delete to authenticated using (user_id = auth.uid());

-- streaks: own-row read; writes come from the rollover cron (service role) and
-- own-row for the client's local reconciliation in early phases.
create policy "streaks_select_own" on public.streaks
  for select to authenticated using (user_id = auth.uid());
create policy "streaks_insert_own" on public.streaks
  for insert to authenticated with check (user_id = auth.uid());
create policy "streaks_update_own" on public.streaks
  for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "streaks_delete_own" on public.streaks
  for delete to authenticated using (user_id = auth.uid());

-- acorn_ledger: SELECT own-row ONLY. Deliberately NO insert/update/delete
-- policies for any client role: with RLS enabled and no policy, those writes
-- are denied — the ledger can only be written by SECURITY DEFINER functions /
-- service role (claim_quest, purchase_item, ... in later phases).
-- Anti-cheat by design: acorns cannot be minted from the app.
create policy "acorn_ledger_select_own" on public.acorn_ledger
  for select to authenticated using (user_id = auth.uid());

-- quest_templates: read-all for authenticated (content, not user data);
-- no write policies — writes via migrations/service role only.
create policy "quest_templates_select_all" on public.quest_templates
  for select to authenticated using (true);

-- user_quests: own-row; the claim flow will move to an RPC with server-side
-- validation (claim_quest) — direct updates remain possible for progress only.
create policy "user_quests_select_own" on public.user_quests
  for select to authenticated using (user_id = auth.uid());
create policy "user_quests_insert_own" on public.user_quests
  for insert to authenticated with check (user_id = auth.uid());
create policy "user_quests_update_own" on public.user_quests
  for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "user_quests_delete_own" on public.user_quests
  for delete to authenticated using (user_id = auth.uid());
