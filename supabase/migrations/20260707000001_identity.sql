-- =============================================================================
-- 01 · IDENTITATE
-- Profiluri, setări și acordul părintelui. RLS: fiecare vede doar rândul lui.
--
-- Reguli ținute de la început:
--   * o singură funcție set_updated_at(), refolosită de toate tabelele
--   * handle_new_user() e SECURITY DEFINER cu ON CONFLICT DO NOTHING, deci
--     poate rula de două ori fără să strice nimic
--   * constrângerile CHECK sunt puse din prima, nu adăugate mai târziu
-- =============================================================================

-- --- Funcții comune ----------------------------------------------------------

-- Singura funcție care ține updated_at la zi, folosită de toate tabelele de mai
-- jos și de migrațiile următoare. Nu o redefini în altă parte.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- --- profiles ----------------------------------------------------------------

create table public.profiles (
  user_id uuid primary key
    references auth.users (id) on delete cascade,
  display_name text,
  cashy_name text,
  cashy_color text,
  age_band text check (age_band in ('14_15', '16_17', '18_25')),
  track text check (track in ('A', 'B')),
  onboarded boolean not null default false,
  monthly_budget numeric not null default 1500,
  timezone text not null default 'Europe/Bucharest',
  locale text not null default 'ro',
  acorns integer not null default 0,          -- copie a sumei din acorn_ledger
  xp integer not null default 0,
  consents jsonb not null default '{}'::jsonb, -- analytics, personalizare, notificări
  parental_consent_status text not null default 'not_required'
    check (parental_consent_status in ('not_required', 'pending', 'confirmed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger trg_profiles_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- --- user_settings -----------------------------------------------------------

create table public.user_settings (
  user_id uuid primary key
    references auth.users (id) on delete cascade,
  quiet_hours jsonb not null default '{}'::jsonb, -- {"school":[8,15],"night":[21,8]}
  league_visible boolean not null default true,
  roast_mode boolean not null default false,      -- ton jucăuș în FinBot, pornit manual, 16+
  reduced_motion boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger trg_user_settings_updated_at
  before update on public.user_settings
  for each row execute function public.set_updated_at();

-- --- parental_consents -------------------------------------------------------

create table public.parental_consents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null
    references auth.users (id) on delete cascade,
  parent_email text not null,
  token text not null,
  status text not null default 'pending'
    check (status in ('pending', 'confirmed', 'rejected')),
  confirmed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index parental_consents_user_id_idx
  on public.parental_consents (user_id);

create trigger trg_parental_consents_updated_at
  before update on public.parental_consents
  for each row execute function public.set_updated_at();

-- --- Pornirea unui cont nou --------------------------------------------------

-- Creează profilul și setările când apare un cont nou, inclusiv la intrarea
-- anonimă. SECURITY DEFINER ca să ruleze indiferent de RLS-ul apelantului, iar
-- ON CONFLICT o face sigură dacă se repetă.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (user_id)
  values (new.id)
  on conflict (user_id) do nothing;

  insert into public.user_settings (user_id)
  values (new.id)
  on conflict (user_id) do nothing;

  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- --- RLS: fiecare vede doar rândul lui (4 reguli per tabel) ------------------

alter table public.profiles           enable row level security;
alter table public.user_settings      enable row level security;
alter table public.parental_consents  enable row level security;

-- profiles
create policy "profiles_select_own" on public.profiles
  for select to authenticated using (user_id = auth.uid());
create policy "profiles_insert_own" on public.profiles
  for insert to authenticated with check (user_id = auth.uid());
create policy "profiles_update_own" on public.profiles
  for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "profiles_delete_own" on public.profiles
  for delete to authenticated using (user_id = auth.uid());

-- user_settings
create policy "user_settings_select_own" on public.user_settings
  for select to authenticated using (user_id = auth.uid());
create policy "user_settings_insert_own" on public.user_settings
  for insert to authenticated with check (user_id = auth.uid());
create policy "user_settings_update_own" on public.user_settings
  for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "user_settings_delete_own" on public.user_settings
  for delete to authenticated using (user_id = auth.uid());

-- parental_consents
create policy "parental_consents_select_own" on public.parental_consents
  for select to authenticated using (user_id = auth.uid());
create policy "parental_consents_insert_own" on public.parental_consents
  for insert to authenticated with check (user_id = auth.uid());
create policy "parental_consents_update_own" on public.parental_consents
  for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "parental_consents_delete_own" on public.parental_consents
  for delete to authenticated using (user_id = auth.uid());
