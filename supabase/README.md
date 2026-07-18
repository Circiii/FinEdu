# FinEdu, backend Supabase

Migrațiile din `migrations/` definesc schema serverului. **Proiectul Supabase
real nu există încă**, aplicația rulează 100% offline până atunci (vezi
`lib/core/config/app_config.dart`). Acest ghid e checklist-ul de aplicare
pentru momentul în care proiectul e creat.

> **F10-f (AI cloud)**: `functions/finbot` (chat Cashy cu guardrails pe 4
> straturi) și `functions/insight-report` (raportul săptămânal narativ) sunt
> scrise și gata de deploy, vezi §4. Cheia Gemini stă DOAR în secretele
> Supabase; niciodată în client. Contractul de siguranță: clientul urcă doar
> agregate derivate, iar output-ul se randează doar dacă `advice_flag=false`.

## 1. Creare proiect (o dată, ~30 min)

1. Proiect Supabase nou, **region EU (Frankfurt)**, datele minorilor rămân în UE.
2. Notează `Project URL` + `anon/publishable key` (Dashboard → Settings → API).
   Ele NU intră în cod: se dau aplicației prin `--dart-define`:

   ```
   flutter run --dart-define=SUPABASE_URL=https://<ref>.supabase.co \
               --dart-define=SUPABASE_ANON_KEY=<anon-key>
   ```

3. Activează **Anonymous sign-in**: Dashboard → Authentication → Providers →
   Anonymous (bootstrap-ul clientului face `signInAnonymously()` la primul start).

## 2. Aplicarea migrațiilor

Varianta A, CLI (recomandat):

```
supabase link --project-ref <ref>
supabase db push
```

Varianta B, SQL Editor: rulează fișierele **în ordine**:

1. `20260707000001_identity.sql`, profiles, user_settings, parental_consents,
   `set_updated_at()` (funcția UNICĂ de updated_at), trigger `handle_new_user`.
2. `20260707000002_money.sql`, transactions (cu `UNIQUE(user_id, client_id)`, idempotența sync-ului!), no_spend_days, transaction_items,
   recurring_transactions, financial_goals + goal_contributions, wishlist_items.
3. `20260707000003_engagement.sql`, daily_activity, streaks, acorn_ledger
   (+ trigger snapshot pe profiles.acorns), quest_templates, user_quests.
4. `20260707000004_views.sql`, v_daily_cohorts (baza CURR/D1/D7/D30).

## 3. Extensii

Nu se activează acum, se activează prin migrațiile fazelor care le folosesc:

| Extensie   | Faza / folosință                                   |
|------------|----------------------------------------------------|
| `pgvector` | RAG pe lecții, category embeddings (F4+)           |
| `pg_cron`  | rollover zilnic, reset ligi, sezon nou (F3+)       |
| `pgmq`     | cozi server-side (notificări batch)                |
| `pg_net`   | apeluri HTTP din Postgres (FCM, edge triggers)     |

## 4. Secrete (Dashboard → Edge Functions → Secrets)

- `GEMINI_API_KEY`, chat/categorize/insights/receipt/voice (F4+).
- Opțional: cheia unui al doilea furnizor de model, pentru FinBot premium.
- NU pune service key-ul în aplicație sau în repo. Anon key-ul e singura cheie
  care ajunge în client.

## 5. Verificarea RLS (OBLIGATORIE înainte de orice date reale)

Checklist cu **2 useri de test** (A și B, creați prin anonymous sign-in sau
email):

- [ ] A inserează o tranzacție → A o vede în `select * from transactions`.
- [ ] B rulează același select → **NU** vede tranzacția lui A (0 rânduri).
- [ ] B încearcă `update`/`delete` pe rândul lui A (prin id) → 0 rânduri afectate.
- [ ] Repetă pentru: `no_spend_days`, `daily_activity`, `profiles`,
      `financial_goals`, `wishlist_items`.
- [ ] `acorn_ledger`: A **poate** citi propriile rânduri, dar `insert` direct
      din client e REFUZAT (nu există politică de INSERT, ghindele se scriu
      doar prin funcțiile server, anti-cheat).
- [ ] `quest_templates`: ambii useri pot citi; `insert`/`update` din client
      e refuzat.
- [ ] Sync end-to-end: pornește aplicația cu dart-define-urile setate, loghează
      o cheltuială offline (airplane mode), revino online → rândul apare în
      `transactions` cu `client_id`-ul generat de client; repetarea sync-ului
      NU duplică rândul (grație `UNIQUE(user_id, client_id)`).

## 4bis. Funcțiile AI (F10-f), deploy în 5 minute

Precondiție: CLI-ul Supabase (`npm i -g supabase`) + `supabase login` +
`supabase link --project-ref <ref>` (o singură dată).

1. **Cheia Gemini**: [aistudio.google.com](https://aistudio.google.com) →
   „Get API key" → copiezi cheia. Apoi:

   ```
   supabase secrets set GEMINI_API_KEY=<cheia-ta>
   ```

2. **Deploy** (din rădăcina repo-ului):

   ```
   supabase functions deploy finbot
   supabase functions deploy insight-report
   ```

3. **Test rapid** (din PowerShell, cu anon key-ul tău):

   ```
   curl -X POST https://<ref>.supabase.co/functions/v1/finbot `
     -H "Authorization: Bearer <anon-key>" -H "Content-Type: application/json" `
     -d '{"message":"Ce e dobanda compusa?"}'
   ```

   Răspunsul corect e JSON cu `answer` + `advice_flag:false`. Întreabă „în ce
   să investesc?" și trebuie să primești `refusal:true` (guardrail-ul MiFID).

Costuri (Flash-Lite): ~0,12 $/utilizator activ/lună la 20 mesaje/zi; raportul
săptămânal ≈ 0,001 $/utilizator/săptămână. La scara beta: neglijabil.

## 6. Ce urmează (fazele următoare, nu acum)

- RPC-uri economice `SECURITY DEFINER` cu validare: `claim_quest`,
  `claim_chest`, `open_expedition`, `purchase_item`; `reset_my_account_data`.
- `daily_activity` va primi un RPC de merge pe `kinds` (acum sync-ul face
  upsert direct pe tabel, suficient pentru F0/F1).
- Cron-uri pg_cron (rollover 00:05 Europe/Bucharest, ligi, sezoane).
- `v_user_risk` + restul viewurilor de analytics.
