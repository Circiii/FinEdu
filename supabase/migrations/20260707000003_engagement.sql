-- =============================================================================
-- 03 · ACTIVITATE
-- Activitatea zilnică, streak-uri, economia de ghinde, misiuni.
--
-- Regula de bază: SERVERUL decide economia. Aplicația propune, o funcție de pe
-- server validează. Aici sunt doar tabelele; funcțiile (claim_quest,
-- claim_chest) vin odată cu ecranele lor.
-- =============================================================================

-- --- daily_activity ------------------------------------------------------------

-- Un rând per utilizator pe zi. `kinds` spune ce s-a făcut în ziua aceea
-- (log, lesson, game, quest, review). De aici mănâncă motorul de streak și
-- vederile de retenție din migrația 04.
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

-- Starea streak-ului. O ține la zi cron-ul care trece ziua și se împacă cu
-- oglinda locală din aplicație.
create table public.streaks (
  user_id uuid primary key
    references auth.users (id) on delete cascade,
  current integer not null default 0,
  longest integer not null default 0,
  freezes_available integer not null default 2, -- "Ghinde de Gheață"
  earnback_until date,                          -- finalul ferestrei de recuperare de 48h
  last_activity_date date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger trg_streaks_updated_at
  before update on public.streaks
  for each row execute function public.set_updated_at();

-- --- acorn_ledger ----------------------------------------------------------------

-- Registru de mișcări de ghinde, la care doar se adaugă. Soldul e suma
-- deltelor, iar profiles.acorns e doar o copie ținută la zi de trigger-ul de jos.
create table public.acorn_ledger (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null
    references auth.users (id) on delete cascade,
  delta integer not null,          -- plus = câștigate, minus = cheltuite
  reason text not null,            -- ex. 'quest_claim', 'chest', 'purchase_item'
  ref uuid,                        -- referință opțională (id de misiune, de obiect)
  created_at timestamptz not null default now()
);

create index acorn_ledger_user_idx
  on public.acorn_ledger (user_id, created_at desc);

-- Ține profiles.acorns la zi cu suma din registru. SECURITY DEFINER pentru că
-- aplicația n-are deloc drept de scriere în registru (vezi RLS mai jos).
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

-- Definițiile misiunilor zilnice, 3 pe zi, împărțite de cron. Sunt date de
-- conținut: oricine autentificat le citește, dar scrie doar serverul, deci nu
-- există reguli RLS de scriere.
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

-- Cele 3 misiuni ale unei zile și progresul lor. Progresul e verificat pe
-- server la revendicare, nu se ia pe încredere de la aplicație.
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

-- daily_activity: fiecare își scrie zilele lui, serverul le adună
create policy "daily_activity_select_own" on public.daily_activity
  for select to authenticated using (user_id = auth.uid());
create policy "daily_activity_insert_own" on public.daily_activity
  for insert to authenticated with check (user_id = auth.uid());
create policy "daily_activity_update_own" on public.daily_activity
  for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "daily_activity_delete_own" on public.daily_activity
  for delete to authenticated using (user_id = auth.uid());

-- streaks: citire pe rândul propriu. Scrierile vin de la cron, plus de la
-- aplicație cât timp își împacă starea locală.
create policy "streaks_select_own" on public.streaks
  for select to authenticated using (user_id = auth.uid());
create policy "streaks_insert_own" on public.streaks
  for insert to authenticated with check (user_id = auth.uid());
create policy "streaks_update_own" on public.streaks
  for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "streaks_delete_own" on public.streaks
  for delete to authenticated using (user_id = auth.uid());

-- acorn_ledger: DOAR citire pe rândul propriu. Nu există intenționat reguli de
-- scriere: cu RLS pornit și fără nicio regulă, scrierile sunt refuzate. În
-- registru scriu numai funcțiile SECURITY DEFINER de pe server.
-- Așa nu se pot fabrica ghinde din aplicație.
create policy "acorn_ledger_select_own" on public.acorn_ledger
  for select to authenticated using (user_id = auth.uid());

-- quest_templates: le citește oricine autentificat, sunt conținut, nu date
-- personale. Scrie doar serverul.
create policy "quest_templates_select_all" on public.quest_templates
  for select to authenticated using (true);

-- user_quests: rândul propriu. Revendicarea trece printr-o funcție validată pe
-- server, actualizarea directă rămâne doar pentru progres.
create policy "user_quests_select_own" on public.user_quests
  for select to authenticated using (user_id = auth.uid());
create policy "user_quests_insert_own" on public.user_quests
  for insert to authenticated with check (user_id = auth.uid());
create policy "user_quests_update_own" on public.user_quests
  for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "user_quests_delete_own" on public.user_quests
  for delete to authenticated using (user_id = auth.uid());
