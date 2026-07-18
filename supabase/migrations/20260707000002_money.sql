-- =============================================================================
-- 02 · MONEY (the v1 core)
-- Transactions, no-spend days, goals, wishlist. CHECK constraints from day one
-- (the lesson of the old schema). RLS: own-row everywhere.
--
-- Sync contract with the Flutter client (drift outbox):
--   * The client generates a uuid v4 per transaction and sends it as client_id.
--   * UNIQUE(user_id, client_id) makes the outbox upsert idempotent — replaying
--     the same op after a network failure can never duplicate a transaction.
-- =============================================================================

-- --- transactions ------------------------------------------------------------

create table public.transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null
    references auth.users (id) on delete cascade,
  -- Client-generated uuid; THE idempotency key for offline sync.
  client_id text not null,
  amount numeric not null check (amount > 0),
  -- The 14 canonical category keys (see lib/domain/models/categories.dart —
  -- keep both lists in lockstep).
  category text not null check (category in (
    -- expense
    'mancare', 'transport', 'distractie', 'educatie',
    'haine', 'sanatate', 'chirie', 'altele',
    -- saving
    'fond_urgenta', 'obiectiv', 'investitii', 'pensie',
    'depozit', 'altele_economii'
  )),
  type text not null default 'expense' check (type in ('expense', 'saving')),
  merchant text,
  note text,
  transaction_date timestamptz not null,
  source text not null default 'manual'
    check (source in ('manual', 'receipt', 'voice', 'recurring')),
  deleted boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  unique (user_id, client_id)
);

-- The two agreed indexes — and ONLY these two (no duplicates; the unique
-- constraint above already indexes (user_id, client_id)).
create index transactions_user_date_idx
  on public.transactions (user_id, transaction_date desc);
create index transactions_user_category_idx
  on public.transactions (user_id, category);

create trigger trg_transactions_updated_at
  before update on public.transactions
  for each row execute function public.set_updated_at();

-- --- no_spend_days -----------------------------------------------------------

-- "Azi n-am cheltuit nimic" is information, not an absence of data.
create table public.no_spend_days (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null
    references auth.users (id) on delete cascade,
  date date not null,
  created_at timestamptz not null default now(),

  unique (user_id, date)
);

-- --- transaction_items -------------------------------------------------------

-- Line items extracted from receipts (OCR); refined async after the optimistic
-- total+merchant insert.
create table public.transaction_items (
  id uuid primary key default gen_random_uuid(),
  transaction_id uuid not null
    references public.transactions (id) on delete cascade,
  user_id uuid not null
    references auth.users (id) on delete cascade,
  name text not null,
  quantity numeric not null default 1 check (quantity > 0),
  unit_price numeric check (unit_price >= 0),
  total numeric check (total >= 0),
  created_at timestamptz not null default now()
);

create index transaction_items_transaction_idx
  on public.transaction_items (transaction_id);

-- --- recurring_transactions --------------------------------------------------

-- Templates for recurring expenses (subscriptions, rent). Materialization into
-- `transactions` happens SERVER-SIDE via pg_cron in a later phase — never on
-- the client.
create table public.recurring_transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null
    references auth.users (id) on delete cascade,
  amount numeric not null check (amount > 0),
  category text not null,
  type text not null default 'expense' check (type in ('expense', 'saving')),
  merchant text,
  note text,
  frequency text not null
    check (frequency in ('daily', 'weekly', 'monthly', 'yearly')),
  next_run_date date not null,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index recurring_transactions_user_idx
  on public.recurring_transactions (user_id);

create trigger trg_recurring_transactions_updated_at
  before update on public.recurring_transactions
  for each row execute function public.set_updated_at();

-- --- financial_goals + goal_contributions (ledger) ----------------------------

create table public.financial_goals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null
    references auth.users (id) on delete cascade,
  name text not null,
  target_amount numeric not null check (target_amount > 0),
  deadline date,
  achieved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index financial_goals_user_idx
  on public.financial_goals (user_id);

create trigger trg_financial_goals_updated_at
  before update on public.financial_goals
  for each row execute function public.set_updated_at();

-- Contributions are a ledger (append-only from the app's perspective); the
-- goal's saved total = sum(amount) — computed, never stored twice.
create table public.goal_contributions (
  id uuid primary key default gen_random_uuid(),
  goal_id uuid not null
    references public.financial_goals (id) on delete cascade,
  user_id uuid not null
    references auth.users (id) on delete cascade,
  amount numeric not null check (amount > 0),
  -- Optional link back to the saving transaction that funded it.
  transaction_id uuid references public.transactions (id) on delete set null,
  created_at timestamptz not null default now()
);

create index goal_contributions_goal_idx
  on public.goal_contributions (goal_id);

-- --- wishlist_items ----------------------------------------------------------

-- The anti-impulse list: park it, apply the 24h rule, buy it consciously later
-- (or discover you no longer want it).
create table public.wishlist_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null
    references auth.users (id) on delete cascade,
  name text not null,
  price numeric not null check (price > 0),
  url text,
  priority integer not null default 2 check (priority between 1 and 3),
  purchased_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index wishlist_items_user_idx
  on public.wishlist_items (user_id);

create trigger trg_wishlist_items_updated_at
  before update on public.wishlist_items
  for each row execute function public.set_updated_at();

-- --- RLS: own-row template on everything --------------------------------------

alter table public.transactions           enable row level security;
alter table public.no_spend_days          enable row level security;
alter table public.transaction_items      enable row level security;
alter table public.recurring_transactions enable row level security;
alter table public.financial_goals        enable row level security;
alter table public.goal_contributions     enable row level security;
alter table public.wishlist_items         enable row level security;

-- transactions
create policy "transactions_select_own" on public.transactions
  for select to authenticated using (user_id = auth.uid());
create policy "transactions_insert_own" on public.transactions
  for insert to authenticated with check (user_id = auth.uid());
create policy "transactions_update_own" on public.transactions
  for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "transactions_delete_own" on public.transactions
  for delete to authenticated using (user_id = auth.uid());

-- no_spend_days
create policy "no_spend_days_select_own" on public.no_spend_days
  for select to authenticated using (user_id = auth.uid());
create policy "no_spend_days_insert_own" on public.no_spend_days
  for insert to authenticated with check (user_id = auth.uid());
create policy "no_spend_days_update_own" on public.no_spend_days
  for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "no_spend_days_delete_own" on public.no_spend_days
  for delete to authenticated using (user_id = auth.uid());

-- transaction_items
create policy "transaction_items_select_own" on public.transaction_items
  for select to authenticated using (user_id = auth.uid());
create policy "transaction_items_insert_own" on public.transaction_items
  for insert to authenticated with check (user_id = auth.uid());
create policy "transaction_items_update_own" on public.transaction_items
  for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "transaction_items_delete_own" on public.transaction_items
  for delete to authenticated using (user_id = auth.uid());

-- recurring_transactions
create policy "recurring_transactions_select_own" on public.recurring_transactions
  for select to authenticated using (user_id = auth.uid());
create policy "recurring_transactions_insert_own" on public.recurring_transactions
  for insert to authenticated with check (user_id = auth.uid());
create policy "recurring_transactions_update_own" on public.recurring_transactions
  for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "recurring_transactions_delete_own" on public.recurring_transactions
  for delete to authenticated using (user_id = auth.uid());

-- financial_goals
create policy "financial_goals_select_own" on public.financial_goals
  for select to authenticated using (user_id = auth.uid());
create policy "financial_goals_insert_own" on public.financial_goals
  for insert to authenticated with check (user_id = auth.uid());
create policy "financial_goals_update_own" on public.financial_goals
  for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "financial_goals_delete_own" on public.financial_goals
  for delete to authenticated using (user_id = auth.uid());

-- goal_contributions
create policy "goal_contributions_select_own" on public.goal_contributions
  for select to authenticated using (user_id = auth.uid());
create policy "goal_contributions_insert_own" on public.goal_contributions
  for insert to authenticated with check (user_id = auth.uid());
create policy "goal_contributions_update_own" on public.goal_contributions
  for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "goal_contributions_delete_own" on public.goal_contributions
  for delete to authenticated using (user_id = auth.uid());

-- wishlist_items
create policy "wishlist_items_select_own" on public.wishlist_items
  for select to authenticated using (user_id = auth.uid());
create policy "wishlist_items_insert_own" on public.wishlist_items
  for insert to authenticated with check (user_id = auth.uid());
create policy "wishlist_items_update_own" on public.wishlist_items
  for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "wishlist_items_delete_own" on public.wishlist_items
  for delete to authenticated using (user_id = auth.uid());
