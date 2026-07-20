# FinEdu: Documentație tehnică completă

## Aplicație mobilă de educație financiară pentru adolescenți și tineri

### Flutter și Dart · Ultima actualizare: 18 iulie 2026

---

> **Tip proiect:** proiect individual
> **Secțiune:** Software cu caracter educațional
> **Platformă testată:** Android (emulator, API 37)
> **Tehnologii principale:** Flutter, Dart, Riverpod, Drift (SQLite), go_router
> **Funcționare:** 100% offline, fără cont, fără chei, fără server

FinEdu este o aplicație mobilă prin care adolescenții învață să își
gestioneze banii făcând, nu doar citind: își notează cheltuielile reale,
parcurg lecții în care fiecare pagină cere o decizie, joacă jocuri care le
testează instinctele financiare și trăiesc o lună simulată pe un salariu
real românesc, cu facturi, datorii, țepe și consecințe întârziate.

Fiecare afirmație tehnică din acest document a fost verificată direct în
repository: în cod, în fișierele de conținut sau în teste.
Afirmațiile care provin din materialele de prezentare și nu pot fi verificate
în cod sunt izolate în [capitolul 22](#22-afirmații-provenite-din-materialele-de-prezentare-neverificabile-direct-în-repository).

---

## Cuprins

1. [Descriere generală](#1-descriere-generală)
2. [Problema rezolvată și publicul țintă](#2-problema-rezolvată-și-publicul-țintă)
3. [Experiența completă a utilizatorului](#3-experiența-completă-a-utilizatorului)
4. [Tehnologii și versiuni](#4-tehnologii-și-versiuni)
5. [Arhitectura aplicației](#5-arhitectura-aplicației)
6. [Structura repository-ului](#6-structura-repository-ului)
7. [Baza de date locală](#7-baza-de-date-locală)
8. [Offline-first și backend-ul opțional](#8-offline-first-și-backend-ul-opțional)
9. [Onboarding-ul](#9-onboarding-ul)
10. [Banii reali: tranzacții, buget, obiective](#10-banii-reali-tranzacții-buget-obiective)
11. [Gamificarea: streak, misiuni, economia cu două monede](#11-gamificarea-streak-misiuni-economia-cu-două-monede)
12. [Lecțiile interactive](#12-lecțiile-interactive)
13. [Recapitularea și algoritmul FSRS-6](#13-recapitularea-și-algoritmul-fsrs-6)
14. [Scorul FinEdu](#14-scorul-finedu)
15. [Jocurile Arcade](#15-jocurile-arcade)
16. [Simularea „30 de Zile: Pe Cont Propriu"](#16-simularea-30-de-zile-pe-cont-propriu)
17. [Sfaturile personalizate](#17-sfaturile-personalizate)
18. [Mascota Cashy: evoluție, garderobă, expediții](#18-mascota-cashy-evoluție-garderobă-expediții)
19. [FinBot, notificările și analytics](#19-finbot-notificările-și-analytics)
20. [Interfața: design, animații, accesibilitate, localizare](#20-interfața-design-animații-accesibilitate-localizare)
21. [Securitate și confidențialitate](#21-securitate-și-confidențialitate)
22. [Afirmații provenite din materialele de prezentare, neverificabile direct în repository](#22-afirmații-provenite-din-materialele-de-prezentare-neverificabile-direct-în-repository)
23. [Testarea automată](#23-testarea-automată)
24. [Instalare, rulare, build](#24-instalare-rulare-build)
25. [Capturi de ecran](#25-capturi-de-ecran)
26. [Limitări cunoscute](#26-limitări-cunoscute)
27. [Dezvoltări viitoare pregătite în arhitectură](#27-dezvoltări-viitoare-pregătite-în-arhitectură)
28. [Componente externe și contribuția autorului](#28-componente-externe-și-contribuția-autorului)
29. [Statistici verificate ale repository-ului](#29-statistici-verificate-ale-repository-ului)
30. [Concluzie tehnică](#30-concluzie-tehnică)

---

## 1. Descriere generală

FinEdu pornește de la o observație simplă: un adolescent nu învață ce e un
buget citind definiția bugetului. Învață când vede că banii lui de buzunar
s-au terminat pe 20 ale lunii și înțelege de ce. Aplicația construiește
exact acest tip de învățare, pe patru straturi care se hrănesc reciproc:

1. **Bani reali.** Utilizatorul își înregistrează cheltuielile și economiile,
   își setează un buget lunar și vede în timp real unde se duc banii.
2. **Lecții interactive.** 35 de lecții în 7 unități, în care nu există
   pagină pasivă: estimezi înainte să afli, alegi înainte să vezi urmarea,
   iar conceptele se dezvăluie bloc cu bloc, la atingere.
3. **Jocuri.** Decizii rapide contra cronometru, un antrenament zilnic și un
   joc de recunoaștere a țepelor online construit pe mesaje realiste
   românești.
4. **Simulare.** „30 de Zile: Pe Cont Propriu": o lună de viață financiară pe
   un rol real (curier, ospătar, programator junior și altele), cu salariu,
   facturi, datorii cu dobândă și evenimente neprevăzute, în care fiecare
   decizie are consecințe, unele imediat, altele peste o săptămână.

Ce leagă straturile: aceeași economie de recompense, aceeași mascotă care
reacționează la ce faci și un scor unic ce reflectă obiceiuri reale, nu doar
activitate în aplicație.

Cifrele aplicației, numărate direct în repository (comenzile de numărare sunt
în [capitolul 29](#29-statistici-verificate-ale-repository-ului)):

| Componentă | Valoare verificată |
|-----------|-------------------:|
| Lecții interactive | 35 |
| Unități educaționale | 7 |
| Carduri de recapitulare | 105 (3 per lecție) |
| Tipuri de exerciții interactive | 9 |
| Evenimente în simularea „30 de Zile" | 163 |
| Roluri jucabile în simulare | 9 |
| Finaluri ale simulării | 12 |
| Mesaje în Scam Dojo | 60 |
| Iteme cosmetice în garderobă | 23 |
| Teste automate | 331 |
| Fișiere Dart în `lib/` | 110 (din care 6 generate) |
| Linii de cod Dart în `lib/` | aproximativ 28.500 scrise în proiect, plus 14.700 generate |
| Linii de cod în `test/` | aproximativ 6.700 |
| Fișiere de conținut JSON | 25 |
| Versiunea schemei bazei de date | 14 (13 migrații incrementale) |
| Limbi | 2 (română și engleză, complet) |

---

## 2. Problema rezolvată și publicul țintă

Publicul țintă sunt adolescenții și tinerii din România (14-25 de ani), care
gestionează primii lor bani: alocație, bursă, bani de buzunar, primul job.
Aplicațiile de banking le arată soldul, dar nu îi învață nimic; manualele de
educație financiară sunt teoretice și departe de viața lor.

FinEdu diferă de o aplicație obișnuită de buget prin trei decizii de produs:

- **Educația e legată de banii reali ai utilizatorului.** Sfaturile din
  aplicație se calculează din propriile tranzacții, iar lecțiile folosesc
  sume și situații de adolescent român (alocația, meditațiile, abonamentul
  de transport, primul contract de muncă).
- **Greșeala e material de învățare, nu pedeapsă.** În simulare poți lua
  decizii proaste și vezi exact ce lanț de consecințe declanșează, fără să
  riști bani reali. Tonul aplicației interzice mesajele de vinovăție, iar
  interdicția e verificată automat de teste (detalii în capitolul 12.4).
- **Totul funcționează offline.** Un elev fără abonament de date sau fără
  card poate folosi absolut tot. Nu există cont, nu există paywall pe
  conținutul educațional.

---

## 3. Experiența completă a utilizatorului

Fluxul de mai jos este cel real, verificat în `lib/core/router/app_router.dart`
și în `lib/features/onboarding/`:

```text
Prima deschidere
      |
Onboarding: oul din care iese mascota
      |
Botezul si culoarea mascotei (Cashy)
      |
Mini-chestionar financiar (nu se noteaza, calibreaza)
      |
Varsta (interval, nu data nasterii)
      |
[doar 14-15 ani] email-ul unui parinte
      |
Bugetul lunar
      |
Prima cheltuiala inregistrata
      |
Soft-ask notificari (se poate refuza)
      |
Ecranul principal, 4 taburi: Acasa · Invata · Arcade · Profil
```

### 3.1 Prima pornire

Onboarding-ul durează câteva minute și fiecare pas se salvează imediat în
baza locală. Dacă utilizatorul închide aplicația la jumătate, la următoarea
pornire reia exact de la pasul incomplet (`OnboardingService.resumeStep()`).

### 3.2 O zi obișnuită

Utilizatorul deschide aplicația, vede bugetul lunii și cele 3 misiuni ale
zilei (de exemplu: loghează o cheltuială, joacă un joc, o zi fără cheltuieli
pe distracție). Adaugă o cheltuială cu butonul central, primește 2 ghinde și
un mesaj de confirmare fără judecăți. Dacă termină toate misiunile, câștigă
un cufăr care se deschide abia a doua zi și poate trimite mascota în
expediție. Cardurile de lecție scadente azi îl așteaptă în recapitulare.

### 3.3 Finalizarea unei lecții

O lecție înseamnă 5-6 pagini active (capitolul 12). La final, utilizatorul
primește XP și 5 ghinde, vede recapitularea în 3 idei și „pasul de azi", o
acțiune concretă de aplicat în viața reală. Cele 3 carduri ale lecției intră
în coada de recapitulare, programate pentru a doua zi.

### 3.4 Pornirea unei simulări

Din Arcade, utilizatorul alege modul (ghidat sau realist), alege un rol din
9, vede cardul de identitate al rolului (salariu, facturi, datorii, obiectiv)
și pornește luna. Fiecare zi avansează la apăsarea unui buton; fiecare
avans salvează un snapshot complet, deci simularea se poate relua oricând,
chiar după închiderea aplicației.

### 3.5 Cumpărarea unui item

În garderobă, fiecare item cosmetic afișează prețul în ghinde și, înainte de
confirmare, costul de oportunitate: câte ghinde rămân după cumpărare. Unele
iteme nu se pot cumpăra deloc: se câștigă doar prin merit (de exemplu,
streak de 30 de zile).

### 3.6 Schimbarea limbii

Din Profil. Interfața și tot conținutul educațional există complet în română
și engleză; schimbarea e instantă, fără restart.

---

## 4. Tehnologii și versiuni

Sursa: `pubspec.yaml` (SDK Dart `^3.12.2`).

### 4.1 Tehnologii principale

| Tehnologie | Rol | Motivul alegerii |
|-----------|-----|------------------|
| Flutter + Dart | framework-ul întregii aplicații | O singură bază de cod care desenează integral interfața: designul propriu (capitolul 20) nu depinde de componentele native ale platformei. Alternativa React Native ar fi cerut punți JavaScript pentru SQLite și animații. |
| Riverpod 2 | starea reactivă și injecția de dependențe | Providerii se pot suprascrie în teste (testele de widget injectează o bază de date în memorie), iar ecranele ascultă doar datele de care au nevoie. |
| Drift 2.28 (SQLite) | baza de date locală | Aplicația e offline-first, deci baza locală e sursa de adevăr, nu un cache. Drift oferă interogări tipizate verificate la compilare și migrații explicite. |
| go_router 14 | navigarea | Rute declarative, un shell cu 4 taburi persistente și rute fullscreen deasupra (jocuri, lecții, onboarding). |
| Supabase (pregătit, neactivat) | backend opțional | Ales pentru viitorul cont și sincronizare multi-dispozitiv. Migrațiile SQL există în `supabase/migrations/`, dar aplicația nu depinde de ele. |

### 4.2 Dependențe runtime

| Pachet | Versiune | Rol în proiect |
|--------|----------|----------------|
| flutter_riverpod | ^2.6.1 | stare și DI |
| go_router | ^14.8.1 | navigare |
| drift + drift_flutter | 2.28.0 / 0.2.5 | baza de date |
| supabase_flutter | ^2.11.1 | client backend (inactiv fără chei) |
| flutter_local_notifications + timezone | ^18.0.1 / ^0.10.0 | memento-ul zilnic local |
| intl | ^0.20.2 | formatare numere și date |
| uuid | ^4.5.1 | id-uri unice pentru tranzacții |
| connectivity_plus | ^6.1.5 | starea conexiunii |
| path_provider | ^2.1.5 | căile de stocare |
| flutter_inset_shadow | ^2.0.3 | umbrele interioare ale stilului vizual |
| freezed_annotation, json_annotation | ^3.0.0 / ^4.9.0 | modele imutabile și serializare |
| cupertino_icons | ^1.0.8 | iconițe standard |

### 4.3 Dependențe de dezvoltare

| Pachet | Rol |
|--------|-----|
| flutter_test | testare |
| flutter_lints ^6.0.0, riverpod_lint, custom_lint | analiză statică strictă |
| build_runner, drift_dev, freezed, json_serializable, riverpod_generator | generare de cod |

> Observație de onestitate: pachetul `supabase_flutter` este inclus, dar
> codul de rețea nu rulează în configurația actuală (capitolul 8).

---

## 5. Arhitectura aplicației

### 5.1 Straturile

```text
+---------------------------------------------------+
|                   Presentation                    |
|   ecrane si widget-uri Flutter (features/*/       |
|   presentation/) + provideri Riverpod             |
+------------------------+--------------------------+
                         |
+------------------------v--------------------------+
|                  Repositories                     |
|   features/*/data/: traduc actiunile UI in        |
|   operatii pe baza de date si apeluri de motoare  |
+------------------------+--------------------------+
                         |
+------------------------v--------------------------+
|              Domain (logica pura)                 |
|   lib/domain/engine/: motoare Dart fara Flutter,  |
|   stare imutabila, functii deterministe           |
+------------------------+--------------------------+
                         |
+------------------------v--------------------------+
|              Drift / SQLite local                 |
|   sursa de adevar + coada outbox pentru sync      |
+------------------------+--------------------------+
                         | optional (azi inactiv)
+------------------------v--------------------------+
|                 Supabase (sync)                   |
+---------------------------------------------------+
```

### 5.2 Regula centrală: motoarele nu știu de Flutter

Toată logica de business trăiește în `lib/domain/engine/`: 25 de fișiere de
Dart pur care nu importă nimic din Flutter. Un motor primește stare și
întoarce stare nouă. Exemplul cel mai clar este avansarea unei zile în
simulare:

```dart
/// Procesează o zi. Ordinea e contractuală (testată), nu o schimba fără să
/// actualizezi golden-testul de determinism.
DayResult advanceDay(LifeSimState s, LifeSimContent c) { ... }
```

Funcția nu citește fișiere, nu afișează nimic, nu depinde de oră sau de
telefon. De aceea un test poate rula o lună întreagă de joc în câteva
milisecunde, iar aceleași motoare ar putea fi refolosite pe un alt UI fără
nicio modificare.

### 5.3 Stare imutabilă și clase sealed

Starea simulării (`LifeSimState`, în
`lib/domain/engine/life_sim/life_sim_state.dart`) are peste 25 de câmpuri și
este imutabilă: orice tranziție creează un obiect nou prin `copyWith`. Asta
elimină bug-urile de modificare accidentală și face salvarea snapshot-urilor
trivială (starea se serializează integral în JSON și se restaurează identic,
lucru verificat printr-un test dus-întors).

Ierarhiile închise folosesc clase `sealed`. De exemplu, efectele simulării:

```dart
sealed class LifeEffect {
  const LifeEffect();
  LifeSimState apply(LifeSimState s, {required int today, String? sourceEventId});
}
```

Cele 12 subtipuri (bani, fond, stat, creare de datorie, plată, programare de
efect viitor și altele) sunt singurele posibile: compilatorul refuză un
`switch` care uită un caz. Aceeași tehnică e folosită la blocurile de lecție
și la condițiile de eligibilitate ale evenimentelor.

### 5.4 Fluxul unei operații de scriere

Adăugarea unei cheltuieli, pas cu pas:

1. Ecranul (`add_expense_screen.dart`) validează input-ul și apelează
   repository-ul.
2. `TransactionsRepository` scrie tranzacția în tabelul `local_transactions`
   (cu id uuid generat pe client) și, în aceeași operație, adaugă un rând în
   coada `outbox_entries`.
3. Baza de date emite stream-uri: toate ecranele care ascultă tranzacțiile
   (Home, bugetul, insight-urile) se actualizează singure.
4. Motorul de sincronizare ar consuma outbox-ul dacă ar exista backend; azi
   intrarea rămâne local, fără nicio consecință pentru utilizator.

### 5.5 Determinismul, decizie de arhitectură

Tot ce pare aleator în aplicație este de fapt derivat determinist dintr-un
seed sau din dată: evenimentele simulării, provocarea zilei, vitrina
garderobei, recompensa expediției. Beneficii concrete: aceeași lună de joc se
poate rejuca identic pentru comparație, testele reproduc exact orice
scenariu, iar doi utilizatori au aceeași provocare a zilei fără niciun
server.

---

## 6. Structura repository-ului

```text
finedu_flutter/
├── lib/
│   ├── core/            infrastructura comuna
│   │   ├── ui/          design system: tokens, componente, animatii, iconite
│   │   ├── db/          schema Drift + repository de profil
│   │   ├── router/      navigarea (shell cu 4 taburi)
│   │   ├── sync/        motorul de sincronizare (outbox)
│   │   ├── analytics/   evenimente canonice tipizate
│   │   ├── notifications/  memento-ul local
│   │   ├── config/      configurarea backend-ului prin dart-define
│   │   └── l10n exista in lib/l10n/ (fisiere generate + .arb sursa)
│   ├── domain/
│   │   ├── engine/      motoarele pure: fsrs, streak, scor, elo, bandit,
│   │   │                dobanda compusa, insight-uri, life_sim/ (11 fisiere)
│   │   ├── models/      modele de date
│   │   └── util/        utilitare pure (chei de zi)
│   └── features/        feature-first, fiecare cu data/ si presentation/
│       ├── onboarding/  tracking/  home/  learning/  arcade/
│       ├── gamification/  goals/  insights/  streak/  profile/
│       ├── wardrobe/  expeditions/  recurring/  finbot/
├── content/             continutul educational, editabil fara recompilare
│   ├── lessons/         7 unitati JSON
│   ├── life_sim/        roluri, facturi, obiective, finaluri + events/
│   ├── arcade/          provocari, mesaje dojo, iteme turbo
│   ├── cashy/           garderoba
│   └── insights.json, notifications.json, onboarding_quiz.json ...
├── assets/              fonturi (Baloo 2, Plus Jakarta Sans) + mascota
├── test/                31 de fisiere, 331 de teste
├── tool/                life_sim_monte_carlo.dart (echilibrul simularii)
├── supabase/            migratii SQL pregatite (backend inactiv)
└── docs/                arhitectura si research-ul cu surse
```

Convenția feature-first: tot ce ține de o funcționalitate stă împreună.
Cine vrea să înțeleagă garderoba deschide `lib/features/wardrobe/` și găsește
acolo și datele, și ecranele.

---

## 7. Baza de date locală

Schema este definită în `lib/core/db/app_db.dart` (Drift), versiunea 14,
cu 13 migrații incrementale scrise de mână în `onUpgrade`: un utilizator
care a instalat aplicația la schema 2 ajunge la 14 fără să piardă nimic.

### 7.1 Tabelele, grupate pe roluri

**Bani reali**

| Tabel | Scop |
|-------|------|
| `local_transactions` | cheltuieli și economii; id uuid client; sume validate pozitive la nivel de tabel; ștergere soft prin flag `deleted`; flag `pending_sync` |
| `local_recurring` | șabloane de tranzacții recurente; materializate automat la scadență |
| `local_goals` | obiective de economisire; progresul NU e stocat, ci derivat din suma tranzacțiilor de tip saving legate de obiectiv |
| `no_spend_days` | zilele fără cheltuieli, marcate explicit (informație, nu absență) |

**Profil și confidențialitate**

| Tabel | Scop |
|-------|------|
| `local_profiles` | un singur rând: numele și culoarea mascotei, bugetul, XP, ghinde, intervalul de vârstă (`age_band`, niciodată anul nașterii), email-ul părintelui și statusul consimțământului, flag-ul de personalizare (implicit oprit) |

Exemplu direct din schemă, cu motivarea în comentariu:

```dart
/// Personalizare inteligentă: opt-in explicit, DEFAULT OFF (AADC/GDPR,
/// profilarea minorilor nu e niciodată default). Fără ea, totul cade pe
/// regulile statice.
BoolColumn get personalizationOn =>
    boolean().withDefault(const Constant(false))();
```

**Progres educațional**

| Tabel | Scop |
|-------|------|
| `lesson_progress_rows` | lecțiile terminate (idempotent: a doua terminare nu dublează recompensa) |
| `review_cards` | cardurile de recapitulare cu starea FSRS (stabilitate, dificultate, scadență) |

**Gamificare**

| Tabel | Scop |
|-------|------|
| `daily_activity_rows` | activitatea pe zile (alimentează streak-ul) |
| `streak_states` | înghețuri, earn-back, borne revendicate |
| `acorn_entries` | ledger-ul ghindelor: fiecare credit/debit cu motiv, pentru audit |
| `quest_claims`, `chest_states` | misiunile revendicate și cufărul zilnic |
| `arcade_rounds` | rundele de joc (economia primei runde a zilei) |
| `dojo_states`, `dojo_item_stats` | rating-ul Elo al jucătorului și al fiecărui mesaj |
| `wardrobe_items` | itemele cosmetice deținute |
| `expedition_rows` | expedițiile mascotei |

**Simulare**

| Tabel | Scop |
|-------|------|
| `life_sim_runs` | rundele „30 de Zile": seed, rol, mod, versiunea de conținut, snapshot-ul JSON complet al stării, scorul final |
| `life_sim_decisions` | fiecare decizie luată (ziua, evenimentul, alegerea) |

**Sincronizare**

| Tabel | Scop |
|-------|------|
| `outbox_entries` | coada durabilă de operații pentru server: tip, payload JSON, contor de încercări, ultima eroare |

### 7.2 Relațiile esențiale

```text
local_profiles (1 rand)
     |
     +-- acorn_entries (ledger, motiv per intrare)
     +-- streak_states (1 rand)
     |
local_goals <--- local_transactions.goal_id   (progres derivat, nu stocat)
     |
review_cards <--- create de lesson_progress_rows la finalul lectiei
     |
life_sim_runs ---> life_sim_decisions (mai multe decizii per runda)
     |
orice scriere ---> outbox_entries (pentru sincronizarea viitoare)
```

Două decizii de proiectare merită subliniate pentru juriu:

- **O singură sursă de adevăr.** Progresul unui obiectiv de economisire nu
  este un contor care poate rămâne desincronizat: este suma tranzacțiilor.
  Balanța de ghinde are un ledger complet alături de snapshot.
- **Idempotență peste tot.** Terminarea unei lecții, revendicarea unei borne
  și deschiderea cufărului verifică întâi dacă operația s-a făcut deja.
  Testele apasă butoanele de două ori și verifică că recompensa nu se
  dublează.

---

## 8. Offline-first și backend-ul opțional

Aplicația este completă fără internet. Configurarea backend-ului este
explicită, la compilare, în `lib/core/config/app_config.dart`:

```dart
/// Adevărat doar dacă ambele valori sunt setate. Orice cod de rețea
/// (Supabase, sync) trebuie să verifice acest flag și să degradeze la offline.
static bool get hasBackend =>
    supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
```

Fără `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
la build, `hasBackend` este fals și niciun cod de rețea nu rulează. În
repository nu există nicio cheie.

Sincronizarea (`lib/core/sync/sync_engine.dart`) funcționează pe modelul
outbox: fiecare scriere locală lasă o operație în coadă; motorul o consumă
FIFO când există backend și sesiune. La eșec, intrarea primește un contor de
încercări (maximum 5, constanta `kMaxSyncAttempts`) și drenarea se oprește
până la următorul declanșator, cu un debounce de 3 secunde după fiecare
scriere. Deoarece backend-ul nu este activat, în versiunea curentă coada
rămâne locală: aplicația este single-device, iar afirmația corectă este că
sincronizarea este proiectată și testată la nivel de mecanism, nu operată
în producție.

Despre platforme, exact: proiectul include doar platforma Android, singura
pe care s-au făcut dezvoltarea și testarea. Codul Dart este independent de
platformă, iar Flutter poate genera oricând suportul pentru iOS, Windows,
macOS, Linux sau web cu o comandă (`flutter create --platforms=... .`);
acele platforme rămân posibile arhitectural, nu verificate.

---

## 9. Onboarding-ul

Implementat în `lib/features/onboarding/` ca un șir de pași persistați
individual prin `OnboardingService`. Ordinea reală (din
`onboarding_screen.dart`): oul, ceremonia de botez a mascotei,
mini-chestionarul, vârsta, pasul de părinte (doar la 14-15 ani), bugetul,
prima cheltuială, recapitularea săptămânii, soft-ask-ul de notificări.

| Pas | Date colectate | Unde se salvează | Observații |
|-----|----------------|------------------|------------|
| Oul și ceremonia | numele și culoarea mascotei | `local_profiles` | numele trece printr-un filtru de cuvinte |
| Mini-chestionar | răspunsurile (JSON) | `local_profiles.quiz_seed` | nu se notează; servește drept punct de pornire pentru dificultatea din Dojo |
| Vârsta | doar intervalul: `14_15`, `16_17`, `18_25` | `local_profiles.age_band` | anul nașterii nu se stochează nicăieri |
| Părinte (doar sub 16) | email-ul unui părinte | `local_profiles.parent_email` + `parental_status` | în versiunea actuală email-ul este doar stocat local: nu se trimite și nu se verifică nimic, pentru că nu există backend; statusul are ciclul `not_required`, `pending`, `confirmed` |
| Buget | suma lunară | `local_profiles.monthly_budget` | |
| Prima cheltuială | o tranzacție reală | `local_transactions` | |
| Notificări | alegerea utilizatorului | `local_profiles.notif_choice` | refuzul („mai târziu") este o opțiune de prim rang |

Dacă aplicația se închide în mijlocul onboarding-ului, `resumeStep()` găsește
primul pas incomplet și continuă de acolo; există un test dedicat
(`test/onboarding_resume_test.dart`).

---

## 10. Banii reali: tranzacții, buget, obiective

### 10.1 Ce vede utilizatorul

Butonul central „+" deschide ecranul de adăugare
(`lib/features/tracking/presentation/add_expense_screen.dart`): alegi
cheltuială sau economie, suma pe un numpad mare, categoria dintr-o grilă cu
8 categorii de cheltuieli (sau 6 destinații de economisire), opțional
obiectivul alimentat. Ecranul Acasă arată bugetul lunar cu procentul
folosit, banii rămași și împărțirea pe categorii.

### 10.2 Ce se întâmplă în spate

Sumele sunt validate la două niveluri: în UI și în schema bazei de date
(`amount.check(amount.isBiggerThanValue(0))`). Ștergerea e soft (flag), ca
o sincronizare viitoare să poată propaga operația. Tranzacțiile recurente
(abonamente) se definesc o dată și se materializează automat la scadență,
la pornirea aplicației.

### 10.3 Obiectivele de economisire

Un obiectiv are nume, țintă și emoji. Progresul lui este derivat: suma
tranzacțiilor de tip saving nedeletate legate de obiectiv. Nu există un
contor separat care să poată minți.

Limitare declarată: butoanele „Foto bon" și „Voce" din ecranul de adăugare
sunt prezente în interfață, dar neimplementate funcțional (capitolul 26).

Teste: `test/goals_test.dart`, `test/recurring_test.dart`,
`test/data_layer_test.dart`, `test/widget_test.dart`.

---

## 11. Gamificarea: streak, misiuni, economia cu două monede

### 11.1 Streak-ul blând

Motorul (`lib/domain/engine/streak_engine.dart` + `streak_rules.dart`)
numără zilele consecutive cu cel puțin o acțiune. Două mecanisme scot
anxietatea din formulă:

- **Ghinde de Gheață**: maximum 2 deținute, 200 de ghinde bucata; una se
  consumă automat pentru o zi ratată.
- **Earn-back**: un streak rupt se poate recupera printr-o serie scurtă de
  zile active imediat după.

Bornele de 7, 30, 100 și 365 de zile plătesc ghinde o singură dată
(revendicările sunt persistate ca să nu se dubleze).

### 11.2 Misiunile și cufărul

3 misiuni pe zi, revendicate manual (apasă tu butonul, nu ți se varsă
automat). Toate 3 terminate înseamnă un cufăr care se deschide abia a doua
zi: un motiv natural de revenire, fără nicio notificare agresivă.

### 11.3 Două monede cu roluri diferite

| Monedă | Ce măsoară | De unde vine | Pe ce se duce |
|--------|-----------|--------------|---------------|
| XP | progresul de învățare | lecții (15 XP nivel începător, 20 intermediar), recapitulări | nivelul (300 XP per nivel); nu se cheltuie |
| Ghinde | activitatea consecventă | lecții (5), recapitulare (3), misiuni, cufăr, borne, expediții, jocuri (prima rundă a zilei) | garderoba cosmetică și Ghindele de Gheață |

Fiecare mișcare de ghinde trece prin ledger-ul `acorn_entries` cu un motiv
(`lesson_u1-banii-tai`, `chest_3`, `wardrobe_fundal_toamna`), ceea ce face
economia auditabilă până la ultima ghindă. Anti-farm: doar prima rundă de
joc a zilei plătește; restul rundelor rămân pentru plăcere și scor.

---

## 12. Lecțiile interactive

### 12.1 Cele 7 unități

Sursa: `content/lessons/unit1.json` ... `unit7.json`, câte 5 lecții fiecare.

| Unitate | Titlu | Tema |
|---------|-------|------|
| 1 | Primii tăi bani | sursele și ritmul banilor, primul buget mental |
| 2 | Bugetul de licean | bugetarea reală pe o lună de liceu |
| 3 | Arta de a NU cumpăra | marketing, ancore de preț, cumpărături impulsive |
| 4 | Banii din gaming & net | microtranzacții, skin-uri, banii din online |
| 5 | Scutul Anti-Țeapă | phishing, oferte false, money mule |
| 6 | Economisirea = superputere | fondul de urgență și dobânda compusă |
| 7 | Primul tău venit | primul job legal, brut și net, contract vs la negru |

### 12.2 Anatomia unei lecții

```text
Hook cu estimare (blochezi raspunsul INAINTE sa afli)
        |
Concept pe blocuri dezvaluite prin atingere
  (text cu marcaje, statistici animate, comparatii
   pe 2 coloane, pasi numerotati, citate ale mascotei)
        |
Micro-verificare (fiecare raspuns gresit are explicatia lui)
        |
Scenariu decizional (nu exista raspuns unic corect,
  exista consecinte)
        |
Exercitiu interactiv (unul din 9 tipuri)
        |
Recapitulare in 3 idei + pasul de azi + teaser
```

### 12.3 Cele 9 tipuri de exerciții

Numărate din conținut (fiecare lecție folosește exact unul, iar regula de
rotație interzice două lecții consecutive cu același tip):

| Tip | Ce face | Câte lecții îl folosesc |
|-----|---------|------------------------:|
| mcq | alegere multiplă cu explicație per variantă | 6 |
| swipe | sortare de carduri în două categorii | 5 |
| pairs | potrivire de perechi | 5 |
| reveal | carduri mit sau realitate, cu întoarcere 3D | 5 |
| cloze | propoziție cu gol de completat | 4 |
| order | pași de pus în ordinea corectă | 4 |
| param_sim | simulator de dobândă compusă cu slidere | 3 |
| checklist | listă de bifat | 2 |
| poll | sondaj cu comentariu per opțiune | 1 |

Simulatorul de dobândă merită o mențiune: utilizatorul trage de slidere
(suma lunară, anii, rata) și vede curba creșterii, inclusiv comparația
dintre două personaje care încep economisirea la vârste diferite. Ratele
permise sunt plafonate la 8%, valoare realistă pentru România, iar plafonul
este impus printr-un test, nu doar prin bune intenții.

### 12.4 Reguli pedagogice impuse de teste

`test/learning_test.dart` parcurge tot conținutul la fiecare rulare și pică
dacă: o lecție are mai puțin de 2 interacțiuni dintre estimare, verificare
și scenariu; un distractor nu are explicație; două lecții consecutive
repetă tipul de exercițiu; un bloc de concept are marcaje de formatare
neînchise; o lecție nu are exact 3 carduri de recapitulare și 3 idei de
recap. Alegerile de format se sprijină pe cercetare documentată cu surse în
`docs/research/lectii-pedagogie.md`.

### 12.5 Conținut editabil fără recompilare

Tot conținutul lecțiilor este JSON bilingv. O corectură de cifră sau o
lecție nouă înseamnă editarea unui fișier de conținut, nu cod nou. Testele
de conținut validează automat structura la fiecare rulare, deci o greșeală
de editare este prinsă înainte să ajungă în aplicație.

---

## 13. Recapitularea și algoritmul FSRS-6

### 13.1 Problema

Fără repetiție, conceptele se uită. Recapitularea clasică („recitește tot")
nu funcționează pentru adolescenți. FinEdu programează fiecare card de
recapitulare exact când e pe cale să fie uitat.

### 13.2 Cum funcționează

Fiecare lecție terminată creează 3 carduri întrebare-răspuns, scadente a
doua zi. La recenzie, utilizatorul răspunde doar „Știu" sau „Nu știu";
interfața rămâne binară intenționat. Algoritmul FSRS-6
(`lib/domain/engine/fsrs.dart`) ține pentru fiecare card două variabile:
stabilitatea (peste câte zile probabilitatea de reamintire scade la 90%) și
dificultatea (1-10, per utilizator), apoi calculează următoarea scadență.

Două constante spun filozofia întregului sistem:

```dart
/// Retenția-țintă pentru următoarea recapitulare. NU 0,90 (cramming), la
/// R=0,90 intervalul == stabilitatea; la R=0,83 intervalul e mai LUNG, deci
/// mai puține carduri pe zi (coadă prietenoasă, educație relaxată, nu examen).
const desiredRetention = 0.83;

/// Plafon de siguranță: chiar și un concept foarte stabil revine cel puțin o
/// dată la ~6 luni (nimic nu dispare complet din coadă).
const maxIntervalDays = 180;
```

### 13.3 Ce e public și ce e propriu

Distincția, spusă exact: algoritmul FSRS-6 și cei 21 de parametri impliciți
sunt publici (parametrii sunt copiați identic din proiectul open-source
py-fsrs, licență MIT, lucru declarat în comentariile din cod și în
`COMPONENTE_EXTERNE.md`). Implementarea în Dart, simplificarea interfeței la
două butoane și integrarea cu restul aplicației aparțin proiectului.
Migrarea de la sistemul anterior (cutii Leitner) păstrează progresul:
fiecare cutie veche primește o stabilitate echivalentă prin
`fsrsSeedFromBox`.

Testele (`test/fsrs_test.dart`) verifică formulele contra valorilor de
referință ale implementării publice.

---

## 14. Scorul FinEdu

Un număr de la 1 la 100 care măsoară obiceiuri, nu activitate. Implementat
în `lib/domain/engine/score_engine.dart`, cu 6 factori:

| Factor | Pondere | Cum se calculează | Limită |
|--------|--------:|-------------------|--------|
| Respectarea bugetului | 25 | raportul dintre cheltuit și buget; scade abia peste 100% și ajunge 0 la 140% | plafonat |
| Economisirea lunii | 25 | economiile lunii față de ținta de 20% din buget | plafonat la țintă |
| Streak | 15 | zilele curente, plafonate la 21 | maximum 21 de zile contează |
| Consecvența logării | 15 | tranzacțiile lunii, plafonate la 10 | maximum 10 contează |
| Lecții terminate | 10 | proporția din totalul lecțiilor | plafonat |
| Diversitatea categoriilor | 10 | câte categorii diferite folosești, maximum 6 | plafonat |

Fiecare factor este plafonat, deci niciun comportament unic nu poate domina
scorul: nu poți compensa lipsa economisirii cu un streak uriaș. Profilul
afișează descompunerea completă, factor cu factor, ca cifra să fie
explicabilă, nu magică. Pragurile de nivel: sub 30, 30-59, 60-79, 80 și
peste.

Teste: `test/score_engine_test.dart`.

---

## 15. Jocurile Arcade

### 15.1 Provocarea Zilei

Un exercițiu pe zi, identic pentru toți utilizatorii, fără server: formatul
și conținutul se derivă determinist din data calendaristică
(`lib/domain/engine/daily_challenge.dart`). Trei formate rotative, definite
în cod:

```dart
enum DailyFormat { price, myth, dilemma }
```

adică ghicește prețul corect, adevărat sau fals, și dilemă de decizie. La
final, un card de share cu rezultatul.

### 15.2 Turbo Buget

45 de secunde (`const turboSeconds = 45` în `turbo_rules.dart`) de decizii
rapide: nevoie sau dorință, cu combo pentru serii corecte, 3 viețe și record
personal persistat. Itemele vin din `content/arcade/turbo_items.json`.

### 15.3 Scam Dojo

Jocul de recunoaștere a țepelor: 60 de mesaje bilingve (39 de țepe, 21
legitime) construite pe tipare reale românești: SMS-uri false de curierat,
conturi „verificate" care vând bilete, oferte de investiții, phishing pe
carduri, money mule. Utilizatorul decide „țeapă" sau „sigur" și primește
explicația tiparului.

### 15.4 Rating-ul Elo din Dojo

Fiecare mesaj are propriul rating Elo care se autocalibrează
(`lib/domain/engine/dojo_elo.dart`): un mesaj ghicit ușor de mulți scade în
rating, unul care păcălește crește. Servirea alege mesaje potrivite
nivelului jucătorului, cu o țintă explicită în cod:

```dart
/// rating care se auto-calibrează din răspunsuri; rundele țintesc p(succes) ≈ 0.75.
const dojoTargetSuccess = 0.75;
```

Trei sferturi șanse de reușită înseamnă mereu provocator, rar frustrant:
zona optimă de învățare. Progresul se afișează în 7 centuri (6 praguri de
rating, de la 1050 la 1550), ca la artele marțiale.

Fluxul unei runde: pornești runda, primești mesaje servite după rating,
decizi pentru fiecare, vezi explicația, iar la final sumarul rundei și
progresul centurii. Prima rundă a zilei plătește ghinde; următoarele nu
(anti-farm), dar contează în rating.

Teste: `test/dojo_elo_test.dart` (formulele Elo), `test/arcade_data_test.dart`
și `test/arcade_rules_test.dart` (conținutul și economia).

---

## 16. Simularea „30 de Zile: Pe Cont Propriu"

Cea mai complexă componentă a proiectului: un motor de simulare determinist
de aproximativ 2.900 de linii de Dart pur
(`lib/domain/engine/life_sim/`, 11 fișiere), plus conținut JSON dedicat și
propriul instrument de verificare statistică.

### 16.1 Scopul educațional

Un adolescent nu poate exersa fără risc gestionarea unui salariu. Simularea
îi dă exact asta: o lună completă, comprimată în 15-20 de minute de joc, în
care deciziile lui produc consecințe mecanice, nu morală. Jocul nu spune
niciodată „ai greșit"; arată ce s-a întâmplat și, în raportul final, lanțul
cauzal complet.

### 16.2 Modurile și rolurile

Două moduri: ghidat (prima lună: facturile viitoare vizibile, șocuri mai
rare) și realist (informație incompletă, șocuri la intensitate normală).
Nouă roluri, fiecare cu date financiare proprii, citite din
`content/life_sim/roles.json`:

| Rol | Salariu net (interval, lei) | Scenariu | Ziua plății | Variabilitate |
|-----|------------------------------|---------:|------------:|--------------:|
| Curier | 3.200 - 4.600 | 3.800 | 5 | 12% |
| Lucrător comercial | 2.800 - 3.800 | 3.200 | 1 | 5% |
| Programator junior | 5.500 - 8.500 | 6.800 | 10 | 0% |
| Asistent medical | 4.200 - 6.000 | 5.000 | 5 | 8% |
| Profesor debutant | 3.800 - 4.800 | 4.300 | 12 | 0% |
| Freelancer creativ | 3.000 - 7.000 | 4.500 | 1 | 25% |
| Ospătar | 2.900 - 4.200 | 3.400 | 3 | 18% |
| Student cu job part-time | 1.800 - 2.600 | 2.200 | 7 | 10% |
| Șofer ride-sharing | 3.500 - 6.500 | 4.800 | 1 | 22% |

Variabilitatea este o lecție în sine: bacșișul ospătarului face venitul
imprevizibil, leafa profesorului e fixă, iar jucătorul simte diferența
dintre a-ți planifica luna pe venit sigur și pe venit variabil.

> Toate salariile poartă în JSON eticheta `needs_expert_review: true`, plus
> sursa și data estimării. Aplicația nu pretinde precizie pe care nu o are,
> iar testele verifică prezența acestor etichete.

Fiecare rol are facturi recurente proprii (chirie, utilități, abonamente,
combustibil: 18 tipuri definite în `recurring.json`), datorii de start cu
rate lunare și un obiectiv de economisire din cele 8 disponibile.

### 16.3 Banii: tipul `Money`

Toate sumele simulării sunt un tip dedicat
(`lib/domain/engine/life_sim/money.dart`): un întreg de bani, unde 1250
înseamnă 12,50 lei. Niciodată virgulă mobilă pe bani: erorile de rotunjire
ale tipului `double` ar strica determinismul și ar produce sume greșite.
Operatorii aritmetici și de comparație sunt definiți pe tip, deci
amestecarea accidentală a leilor cu banii nici nu compilează.

### 16.4 Generatorul pseudo-aleator determinist

Tot hazardul vine din `LifeSimRng` (`life_sim_rng.dart`), o implementare
proprie a algoritmului public SplitMix64. Generatorul se ramifică pe zi și
pe sub-flux (salariul are fluxul lui, directorul de evenimente pe al lui),
astfel încât o decizie diferită într-o zi nu deplasează hazardul altor zile.
Consecința: același seed plus aceleași decizii produc exact aceeași lună, pe
orice telefon. Pe această garanție stau funcția „Reia aceeași lună" (aceeași
lună, alte decizii, comparație directă) și testele de reproducere exactă.

### 16.5 Ordinea exactă a unei zile

Ordinea este contractuală, adică schimbarea ei pică un test dedicat. Din
`advanceDay` (`life_sim_engine.dart`):

```text
Ziua incepe
   |
1. Salariul (daca e ziua de plata; variabilitatea se aplica determinist)
   |
2. Facturile scadente azi
   |    platite daca ai bani, altfel intra in RESTANTE
   |
3. Ratele de datorie scadente azi
   |    dupa perioada de gratie curge dobanda de 1,5% pe luna
   |    rata ratata umfla principalul cu 2% (minimum 20 lei)
   |
4. Restantele se platesc automat cand exista bani (cele mai vechi primele);
   |    in scor raman ratari, iar cat timp exista, stresul creste zilnic
   |
5. Efectele programate scadente azi se declanseaza
   |    (consecintele intarziate ale deciziilor vechi)
   |
6. Drift de stare: energia scade natural; stres > 70 consuma energie,
   |    energie < 25 consuma sanatate, sanatate < 35 urca stresul
   |
7. Directorul alege cel mult un eveniment eligibil
   |
Decizia utilizatorului (2-4 optiuni, fiecare cu efecte)
   |
Snapshot complet salvat in baza de date
```

### 16.6 Evenimentele și directorul

163 de evenimente în 4 fișiere JSON, pe categorii: muncă și viață socială,
costuri, datorii și economisire, sănătate, transport și locuire, țepe,
tehnologie și evenimente rare. Fiecare eveniment declară fereastra de zile,
greutatea, dificultatea (1-3), condițiile de eligibilitate (de exemplu,
doar dacă ai mașină, doar dacă stresul e peste un prag), excluderile,
cooldown-ul și rolurile țintite.

Directorul (`life_sim_director.dart`) alege evenimentul zilei cu reguli de
regie explicite în cod:

```dart
// Echilibru: penalizează categoria de ieri și categoriile deja „grele".
if (e.category == s.lastEventCategory) w *= 0.4;
if ((s.categoryCounts[e.category] ?? 0) >= 3) w *= 0.5;

// Anti-hammer: dacă ieri a lovit un negativ (dificultate ≥2), negativele de
// azi devin mult mai improbabile.
```

Adică: jocul nu te lovește cu două șocuri consecutive și nu te îneacă în
aceeași categorie de probleme. Există și zile liniștite garantate
probabilistic (15% șansă de bază pe modul realist, 32% pe ghidat), pentru că
o lună reală are și zile în care nu se întâmplă nimic.

### 16.7 Consecințele întârziate

Mecanica pedagogică centrală. O alegere poate programa efecte viitoare:

```text
Ziua 6: parbrizul crapat. Alegi "aman reparatia" (+0 lei azi)
   |
   +--> ScheduleEffect(delay 7 zile, cost mai mare, nota explicativa)
   |
Ziua 13: efectul se declanseaza: -1.100 lei, cu nota
   "Amanarea a costat mai mult decat reparatia la timp."
   |
Raportul final leaga cele doua momente in acelasi lant cauzal.
```

Fiecare efect declanșat păstrează legătura cu decizia-sursă
(`sourceEventId`), astfel încât raportul final poate reconstitui exact
lanțul: ce ai decis, când te-a ajuns din urmă, cât te-a costat.

### 16.8 Scorul final și finalurile

Patru dimensiuni cu ponderi 30/30/20/20 (`life_sim_scoring.dart`): control
financiar (facturi plătite la timp, zile fără descoperit, penalizări),
reziliență (fondul de urgență, datoria rămasă, tamponul final), obiective
(progresul țintei, reducerea datoriilor) și echilibru de viață (media celor
4 indicatori de stare, cu stresul inversat). Anti-avariție prin construcție:

```dart
/// Praguri de referință (bani). Peste ele, „mai mult cash" nu mai adaugă scor,
/// exact ce rupe monotonia pe cash.
```

Fiecare factor de bani este plafonat, deci strategia „nu cheltui nimic, nu
trăi deloc" pierde în fața uneia echilibrate: exact lecția pe care jocul
vrea să o predea. La final, unul din 12 finaluri cu titluri de respect
(praguri pe dimensiuni, definite în `endings.json`), apoi debrief-ul:
întâi o întrebare de reflecție, apoi cronologia deciziilor majore,
consecințele întârziate materializate și un contrafactual („dacă ai fi
plătit factura la timp, ai fi terminat cu X lei în plus").

### 16.9 Verificarea statistică Monte Carlo

Echilibrul unui joc cu 163 de evenimente nu se poate verifica manual.
Instrumentul `tool/life_sim_monte_carlo.dart` rulează mii de luni complete
cu politici sintetice de decizie (random, avar, echilibrat, generos) pe
toate rolurile și ambele moduri, apoi scrie raportul în
`docs/research/life-month-balance-report.md`. Raportul curent, pe 3.000 de
rulări: 100% din rulări se termină fără erori, politica echilibrată bate
avariția (validare matematică a designului anti-avariție), niciun rol nu
este imposibil (cel mai greu: curierul), niciun eveniment nu domină.

### 16.10 Persistență și versiuni de conținut

Fiecare zi salvează snapshot-ul JSON complet al stării în `life_sim_runs`,
deci o rundă se reia perfect după închiderea aplicației. Rundele sunt legate
de versiunea de conținut la care au pornit: dacă conținutul se schimbă
(evenimente noi, valori modificate), runda veche se închide curat în loc să
continue pe date care i-ar strica determinismul.

Teste: `test/life_sim_engine_test.dart` (cel mai amplu fișier de test al
proiectului: ordinea zilei, restanțe, dobânzi, plăți anticipate, golden-test
de determinism, serializare dus-întors), `test/life_sim_content_test.dart`
(validatorul întregului conținut), `test/life_sim_money_test.dart` (banii și
generatorul, cu vectori de referință), `test/life_month_ui_test.dart`
(fluxul pe ecran), `test/life_sim_commentary_test.dart`.

---

## 17. Sfaturile personalizate

Secțiunea „Pentru tine" de pe ecranul principal
(`lib/domain/engine/insight_rules.dart` + `lib/features/insights/`).

Denumirea exactă a sistemului: motor de reguli deterministe pe datele
locale, plus un algoritm statistic de tip bandit pentru ordonare, pornit
doar prin opt-in. Nu este un sistem AI și nu este prezentat ca atare.

Ce calculează regulile: ritmul cheltuielilor față de buget (cu bugetul
zilnic recalculat pe zilele rămase), anomalii față de propria medie (nu față
de alți utilizatori), borne pozitive, recapitulare săptămânală. Disciplina
anti-zgomot este parte din motor: maximum 2 carduri pe zi, raport 2:1 între
mesaje pozitive și corective, cooldown per tip de card, iar cardurile
respinse primesc pauze mai lungi.

Diferențiatorul educațional: fiecare card are butonul „Cum am calculat?",
care afișează formula cu cifrele reale ale utilizatorului. Exemplu real din
`content/insights.json`:

```json
"how": { "ro": "Cheltuit {spent} lei; la ziua de azi, ritmul bugetului tău ar fi {expected} lei." }
```

Personalizarea suplimentară (ce categorie de sugestie apare prima) folosește
Thompson Sampling Beta-Bernoulli (`lib/domain/engine/bandit.dart`),
determinist la seed fixat, cu semnal de succes definit ca învățare (tap plus
acțiune), nu ca engagement brut. Este oprită implicit și pornește doar prin
opt-in explicit, decizie motivată în schemă: profilarea minorilor nu are ce
căuta activă din oficiu.

Teste: `test/insight_rules_test.dart`, `test/insights_provider_test.dart`,
`test/bandit_test.dart`, `test/money_intel_test.dart`.

---

## 18. Mascota Cashy: evoluție, garderobă, expediții

### 18.1 De ce o veveriță

Metafora e economisirea: veverița strânge ghinde pentru iarnă, puțin câte
puțin. Moneda aplicației e ghinda, iar mascota apare în fiecare moment
important: predă în lecții, comentează deciziile din simulare, sărbătorește
reușitele.

### 18.2 Evoluția

Șase stadii (`lib/domain/engine/cashy_evolution.dart`), de la „Oul norocos"
la „Înțeleptul Pădurii", deblocate prin „puncte de grijă" derivate integral
din activitatea existentă: zile active, lecții, streak, jocuri (plafonate
anti-farm), cadouri din garderobă. Zero grind separat, zero cumpărare de
progres: evoluția reflectă grija reală, nu banii cheltuiți.

### 18.3 Garderoba

23 de iteme cosmetice (fundaluri și accesorii) în
`content/cashy/wardrobe.json`: unele cu preț fix în ghinde, altele
exclusiv prin merit (streak 30, centura neagră la Dojo, scor 80), câteva
sezoniere. Vitrina zilei alege determinist din dată 3 iteme cu reducere de
20%. Itemele sunt pur cosmetice: niciun avantaj funcțional, deci economia
nu vinde progres.

### 18.4 Expedițiile

A doua sesiune a zilei, construită fără nicio notificare: după terminarea
misiunilor, mascota poate pleca 6 ore și se întoarce cu ghinde și o carte
poștală cu o micro-idee financiară. Recompensa este deterministă, cu formula
direct în cod:

```dart
/// Domeniu efectiv: 16 + 2·min(streak,7) + hash%5 = 16..34.
```

Ziua ratată nu costă nimic, iar recompensa nerevendicată se creditează
automat: nu se pierde niciodată nimic, nu există countdown care să preseze.

Teste: `test/cashy_evolution_test.dart`, `test/wardrobe_test.dart`,
`test/expeditions_test.dart`.

---

## 19. FinBot, notificările și analytics

### 19.1 FinBot, spus exact

`lib/features/finbot/presentation/finbot_screen.dart` este un ecran de chat
cu mascota, cu răspunsuri scriptate (un dicționar de replici predefinite) și
trei carduri vizuale: distribuția cheltuielilor, regula 50/30/20 și un
mini-simulator de economisire. Datele graficului sunt statice, de
demonstrație, nu tranzacțiile reale ale utilizatorului. Nu este un asistent
AI funcțional și nu este prezentat ca atare nicăieri în aplicație.
Integrarea unui model real există doar ca plan documentat în
`supabase/README.md` (o funcție server cu reguli de siguranță), neactivată.
Aplicația este completă fără FinBot.

### 19.2 Notificările

Un singur memento local pe zi, programat pentru a doua zi la 19:00, oră
aleasă explicit ca să evite orele de școală și de somn (comentariul din
`lib/core/notifications/notifications_service.dart` citează regulile de
design pentru minori). Permisiunea se cere printr-un soft-ask cu opțiunea
„mai târziu" la vedere. Implementare doar pentru Android. Textele
notificărilor sunt validate de un test care interzice limbajul de urgență și
de vinovăție (`test/notification_planner_test.dart`).

### 19.3 Analytics

`lib/core/analytics/` definește evenimente canonice tipizate (de exemplu
`life_sim_completed {score, ending}`). În versiunea curentă, evenimentele se
loghează doar local, în consolă, printr-o implementare de debug;
integrarea unui serviciu real este marcată ca TODO în cod. Prin construcție,
evenimentele nu conțin date financiare brute: se raportează bucket-uri și
contoare, nu sume exacte.

---

## 20. Interfața: design, animații, accesibilitate, localizare

### 20.1 Design system propriu

Stilul vizual (claymorphism: forme moi, umbre duble, aspect de plastilină)
este definit o singură dată în `lib/core/ui/tokens.dart`: paleta de culori,
tipografia (Baloo 2 pentru titluri, Plus Jakarta Sans pentru text, ambele
incluse local cu suport pentru diacritice), razele de colț, duratele de
animație și umbrele. Componentele comune (`clay.dart`: card, buton, iconiță
pe fundal colorat) și iconițele desenate ca path-uri SVG
(`svg_icon.dart`) se refolosesc în toată aplicația. Ecranele nu au voie să
improvizeze culori sau dimensiuni: totul vine din tokens.

### 20.2 Animații cu buget

`lib/core/ui/juice.dart` definește limbajul de mișcare: numărători animate,
săltături la valori noi, scuturare orizontală la greșeală, confetti pictat
manual (36 de particule, fără niciun pachet extern), intrări în cascadă.
Feedback-ul tactil are patru niveluri, alocate o singură dată per moment:

```dart
class Juice {
  static void tick() => HapticFeedback.selectionClick();
  static void correct() => HapticFeedback.lightImpact();
  static void major() => HapticFeedback.mediumImpact();
  static void epic() => HapticFeedback.heavyImpact();
}
```

Detaliu de ton: greșeala nu primește niciodată vibrație, doar o scuturare
vizuală blândă. Doar reușitele se simt în palmă.

### 20.3 Accesibilitate

Fiecare animație verifică setarea de sistem pentru reducerea mișcării
(`MediaQuery.disableAnimations`): cu ea activă, conținutul apare direct, în
starea finală. Textele lungi au ellipsis, listele derulează, iar testele de
widget rulează pe dimensiuni de ecran mici pentru a prinde depășirile.

### 20.4 Localizare

Româna este limba implicită, engleza este completă: interfața prin sistemul
standard Flutter (`lib/l10n/app_ro.arb`, `app_en.arb`, cod generat cu
`flutter gen-l10n`), conținutul prin câmpuri `{"ro": ..., "en": ...}` în
fiecare fișier JSON. Un test dedicat detectează diacriticele sparte
(mojibake) în tot conținutul, pentru că o țeapă cu „È™" în loc de „ș" ar
strica exact lecția despre încredere.

---

## 21. Securitate și confidențialitate

Aplicația este construită pentru minori, deci pragul este ridicat deliberat:

- **Toate datele stau local**, în SQLite, în sandbox-ul aplicației Android.
  În configurația actuală nu pleacă nimic de pe telefon. Baza de date nu
  este criptată suplimentar (limitare declarată: sandbox-ul sistemului este
  singura barieră).
- **Zero secrete în repository.** Credențialele backend-ului vin exclusiv
  din `--dart-define` la build; fără ele, codul de rețea nu rulează deloc.
- **Minimizarea datelor.** Vârsta se stochează doar ca interval
  (`14_15`, `16_17`, `18_25`); anul nașterii nu este cerut și nu este
  stocat nicăieri. Nu se cere nume real, telefon sau adresă.
- **Consimțământ parental.** Sub 16 ani se colectează email-ul unui părinte,
  stocat local, cu status explicit; trimiterea și verificarea lui devin
  posibile abia când va exista backend.
- **Personalizarea este oprită implicit** și pornește doar prin opt-in, cu
  motivarea scrisă în schema bazei de date.
- **Validare de intrare**: sumele sunt verificate și în UI, și în baza de
  date; textele au limite de lungime.
- **Fără judecăți.** Politica de conținut stă într-un document separat în
  repository (`CONTENT_POLICY.md`), iar regulile de ton sunt impuse prin
  teste.

Ce se schimbă dacă backend-ul va fi activat: datele vor părăsi telefonul
prin sincronizare, moment în care devin necesare autentificarea, criptarea
în tranzit și politicile de server; migrațiile SQL pregătite includ reguli
de acces pe rânduri (row-level security).

---

## 22. Afirmații provenite din materialele de prezentare, neverificabile direct în repository

Următoarele afirmații apar în materialele de prezentare ale proiectului și
NU pot fi verificate în acest repository. Sunt listate separat pentru
onestitate și nu sunt folosite drept fapte în restul documentului:

- Statisticile despre nivelul educației financiare din România și sursele
  lor externe.
- Chestionarul propriu cu 380 de respondenți și procentele derivate din el.
- Existența unui prototip web anterior și numărul lui de utilizatori.
- Premiile obținute la competiții anterioare cu acel prototip.
- Orice cifră despre utilizatori reali ai aplicației mobile.

Separat, salariile și costurile din simulare sunt estimări pe baza datelor
publice de piață: sunt marcate `needs_expert_review: true` chiar în
fișierele de conținut și cer validarea unui specialist înainte de o lansare
publică.

---

## 23. Testarea automată

331 de teste în 31 de fișiere, rulate integral cu `flutter test`.
Verificate prin rulare completă la data de 18 iulie 2026, împreună cu
`flutter analyze` (nicio problemă raportată). Rezultatele sunt reproducibile
de oricine cu comenzile din capitolul 24.

| Categorie | Fișiere reprezentative | Ce verifică |
|-----------|------------------------|-------------|
| Motoare pure | `domain_engines_test.dart`, `streak_rules_test.dart`, `compound_test.dart`, `score_engine_test.dart` | streak cu îngheț și earn-back, XP și niveluri, dobânda compusă, ponderile scorului |
| FSRS | `fsrs_test.dart` | formulele contra valorilor de referință ale implementării publice |
| Elo și bandit | `dojo_elo_test.dart`, `bandit_test.dart` | actualizarea rating-ului, determinismul Thompson Sampling pe 100 de seed-uri |
| Simulare | `life_sim_engine_test.dart`, `life_sim_money_test.dart` | ordinea contractuală a zilei, restanțe, dobânzi, plăți anticipate, golden-test de determinism (același seed, aceeași lună), serializare dus-întors, vectori de referință pentru generatorul SplitMix64 |
| Validatoare de conținut | `life_sim_content_test.dart`, `learning_test.dart`, `arcade_data_test.dart` | fiecare fișier JSON: id-uri unice, referințe rezolvate, reguli pedagogice, lungimi de text, ton fără vinovăție, diacritice corecte, sume exclusiv întregi |
| Widget și fluxuri | `widget_test.dart`, `lesson_player_test.dart`, `life_month_ui_test.dart`, `onboarding_resume_test.dart` | fluxuri complete pe bază de date în memorie, gate-uri care țin până răspunzi, dublu-tap care nu dublează recompense, reluarea progresului |
| Conținut vizual | `juice_test.dart`, `lesson_blocks_test.dart`, `param_sim_test.dart` | animațiile respectă reduce-motion, blocurile de lecție, simulatorul de dobândă |
| Notificări și insight-uri | `notification_planner_test.dart`, `insight_rules_test.dart` | interdicția limbajului de urgență, disciplina anti-zgomot |

Câteva teste care spun ceva despre cultura proiectului:

- **Golden-test de determinism**: aceeași lună de simulare, rulată de două
  ori cu același seed și aceleași decizii, trebuie să producă stări identice
  câmp cu câmp.
- **Testul de dublu-tap**: apăsarea rapidă de două ori pe „Vezi raportul" nu
  are voie să plătească recompensa de două ori.
- **Lint de ton**: expresiile de vinovăție sunt căutate automat în tot
  conținutul; la fel caracterele tipografice interzise și diacriticele
  sparte.
- **Verificare statistică separată**: echilibrul simulării nu e testat cu
  „pare ok", ci cu Monte Carlo pe mii de rulări (capitolul 16.9).

Complementar testelor: analiză statică strictă (flutter_lints plus
riverpod_lint și custom_lint), dezvoltare versionată cu Git și integrare
continuă pe GitHub Actions.

---

## 24. Instalare, rulare, build

Cerințe: Flutter SDK stabil (Dart `^3.12.2`). Aplicația rulează din același cod
pe Android, pe Windows și în browser.

```bash
# dependentele
flutter pub get

# ce dispozitive sunt disponibile
flutter devices

# rulare (alege automat dispozitivul sau specifica-l cu -d)
flutter run

# testele (351)
flutter test

# analiza statica
flutter analyze

# build de instalare pe Android
flutter build apk --release
# rezultatul: build/app/outputs/flutter-apk/app-release.apk
```

Nu este nevoie de nicio configurare: aplicația pornește direct, offline.

### Versiunea de browser

```bash
flutter build web --release --no-web-resources-cdn
dart run tool/serve_web.dart      # http://localhost:8080
```

`--no-web-resources-cdn` face ca motorul grafic să fie servit din folderul
aplicației, nu de pe un CDN, deci build-ul merge și fără internet.

Serverul din `tool/serve_web.dart` trimite antetele
`Cross-Origin-Opener-Policy` și `Cross-Origin-Embedder-Policy`. Fără ele
browserul nu acordă bazei de date acces la OPFS, stocarea persistentă, iar
progresul s-ar pierde la reîncărcarea paginii. Orice găzduire folosită în
producție trebuie să trimită aceleași două antete.

Pe web, SQLite rulează ca WebAssembly: fișierele `web/sqlite3.wasm` și
`web/drift_worker.js` sunt livrate în repo fiindcă `flutter pub get` nu le aduce.

### Versiunea de Windows

Necesită, o singură dată: Visual Studio 2022 cu pachetul „Desktop development
with C++" și modul dezvoltator din Windows pornit (`ms-settings:developers`).

```bash
flutter run -d windows
flutter build windows --release
```

Prima compilare descarcă și compilează SQLite, deci cere internet o dată.

Regenerarea codului generat (doar dacă modifici sursele respective):

```bash
dart run build_runner build --delete-conflicting-outputs   # drift, freezed
flutter gen-l10n                                           # localizarea
```

Activarea backend-ului opțional (necesită un proiect Supabase real și
aplicarea migrațiilor din `supabase/migrations/`, pași descriși în
`supabase/README.md`):

```bash
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

---

## 25. Capturi de ecran

Repository-ul nu conține în prezent un director de capturi de ecran.
Secțiunea este pregătită pentru completare:

### Onboarding
<!-- De adaugat: docs/screenshots/onboarding.png -->

### Ecranul principal
<!-- De adaugat: docs/screenshots/home.png -->

### Lecție interactivă
<!-- De adaugat: docs/screenshots/lesson.png -->

### Scam Dojo
<!-- De adaugat: docs/screenshots/scam-dojo.png -->

### 30 de Zile: Pe Cont Propriu
<!-- De adaugat: docs/screenshots/life-sim.png -->

### Raportul final al simulării
<!-- De adaugat: docs/screenshots/life-sim-report.png -->

---

## 26. Limitări cunoscute

Spuse direct, cu impact și stadiu:

| Limitare | Impact | Stadiu |
|----------|--------|--------|
| Backend neactivat | aplicația este single-device; fără cont, fără sincronizare, fără clasamente | schema SQL și mecanismul outbox există; lipsește proiectul de server |
| iOS și desktop netestate | funcționarea e doar teoretic posibilă prin Flutter | testat exclusiv pe Android |
| Notificări doar pe Android | pe alte platforme, memento-ul nu există | implementare Android-only, declarată în cod |
| FinBot scriptat | chat demonstrativ cu date statice | planul de integrare reală există în `supabase/README.md` |
| Scanarea bonurilor și vocea | butoanele există în UI, funcționalitatea nu | neimplementate |
| Salarii estimate | datele simulării cer validare de specialist | marcate `needs_expert_review` în conținut |
| Analytics local | evenimentele nu ajung la niciun serviciu | TODO explicit în `lib/core/analytics/analytics.dart` |
| Baza de date necriptată | protecția datelor stă în sandbox-ul Android | criptarea ar deveni necesară la sync |
| Acoperirea testelor UI | fluxurile principale sunt testate, nu fiecare ecran secundar | 331 de teste, concentrate pe motoare și conținut |

---

## 27. Dezvoltări viitoare pregătite în arhitectură

Nu promisiuni, ci puncte de extensie care există deja în cod:

- **Cont și sincronizare**: outbox-ul, flag-ul `hasBackend` și migrațiile
  SQL cu reguli de acces pe rânduri așteaptă doar proiectul de server.
- **Provocarea lunii cu clasament**: schema rundelor de simulare stochează
  seed-ul și scorul, exact ce ar cere un leaderboard pe seed comun.
- **Conținut nou fără release**: o unitate de lecții sau un pachet de
  evenimente nou înseamnă fișiere JSON noi; validatoarele de conținut le
  verifică automat.
- **FinBot real**: planul de server cu reguli de siguranță este documentat;
  aplicația funcționează identic fără el.
- **Verificare de specialitate a datelor**: etichetele `needs_expert_review`
  marchează exact ce trebuie validat de un expert înainte de lansare.

---

## 28. Componente externe și contribuția autorului

Detaliile complete, cerute de regulament, sunt în fișierul dedicat
[`COMPONENTE_EXTERNE.md`](COMPONENTE_EXTERNE.md). Pe scurt:

- **Biblioteci**: pachetele pub.dev listate în capitolul 4 (framework,
  bază de date, navigare, stare).
- **Fonturi**: Baloo 2 și Plus Jakarta Sans (licență SIL OFL, incluse
  local).
- **Algoritmi publici**: FSRS-6 (cu parametrii publici din py-fsrs, MIT),
  SplitMix64, Elo, Thompson Sampling; implementările în Dart sunt scrise în
  proiect.
- **Imagini**: sprite-urile mascotei și imaginea ghindei sunt fișiere
  grafice create cu instrumente de generare de imagini, pe baza
  descrierilor autorului.
- **Cifre din surse publice**: datele financiare românești din conținut,
  cu sursele notate în `docs/research/`.
- **Unelte de asistență la scriere**: la implementare au fost folosite unelte
  bazate pe modele de limbaj, pe baza specificațiilor autorului.

Contribuția autorului, formulată exact: autorul a definit produsul,
arhitectura, regulile de business și cele pedagogice, experiența
utilizatorului, a coordonat și verificat fiecare etapă de implementare
(inclusiv verificarea vizuală pe emulator și validarea testelor) și a
integrat toate componentele într-un produs coerent.

---

## 29. Statistici verificate ale repository-ului

Toate valorile de mai jos au fost obținute prin numărare directă la data de
18 iulie 2026:

| Statistică | Valoare |
|-----------|--------:|
| Fișiere Dart în `lib/` | 110 (104 scrise în proiect + 6 generate) |
| Linii Dart scrise în proiect (`lib/`, fără generat) | ~28.500 |
| Linii Dart generate (drift, freezed, localizare) | ~14.700 |
| Linii în `test/` | ~6.700 |
| Fișiere de test | 31 |
| Teste individuale | 331 |
| Fișiere JSON de conținut | 25 |
| Lecții / unități | 35 / 7 |
| Evenimente de simulare | 163 |
| Roluri / facturi recurente / obiective / finaluri | 9 / 18 / 8 / 12 |
| Mesaje Scam Dojo | 60 (39 țepe, 21 legitime) |
| Iteme cosmetice | 23 |
| Versiune schemă DB / migrații | 14 / 13 |
| Limbi | 2 |

Anexă: comenzile de numărare folosite (rulate din rădăcina proiectului):

```bash
# teste
flutter test                       # numarul din ultima linie a rularii

# fisiere si linii Dart
find lib -name "*.dart" | wc -l
find lib -name "*.dart" ! -name "*.g.dart" ! -name "*.freezed.dart" \
  ! -name "app_localizations*" -exec wc -l {} + | tail -1

# continut
grep -c '"category":' content/life_sim/events/*.json     # evenimente
grep -o '"kind": "[a-z_]*"' content/lessons/*.json | sort | uniq -c
grep -c '"due_day"' content/life_sim/recurring.json      # facturi

# schema
grep -n "schemaVersion" lib/core/db/app_db.dart
grep -c "if (from <" lib/core/db/app_db.dart             # migratii
```

---

## 30. Concluzie tehnică

FinEdu nu este o colecție de ecrane, ci un sistem: motoare de business pure
și deterministe, o bază de date locală care este singura sursă de adevăr,
conținut educațional separat de cod și validat automat, o economie de joc
auditabilă și un strat vizual construit dintr-un singur set de reguli.

Trei lucruri definesc calitatea inginerească a proiectului:

1. **Verificabilitate.** 331 de teste acoperă de la formulele FSRS până la
   tonul mesajelor; echilibrul simulării este demonstrat statistic, nu
   estimat; fiecare cifră din acest document se poate reproduce cu o
   comandă.
2. **Onestitate.** Limitările sunt documentate în cod și aici, datele
   nesigure sunt etichetate, componentele externe și asistența AI sunt
   declarate, iar prototipurile (FinBot) sunt numite prototipuri.
3. **Respect pentru utilizator.** Offline complet, date minime, profilare
   oprită implicit, zero mesaje de vinovăție, economie care nu vinde
   progres: decizii de design verificate prin teste, nu doar declarate.

Aplicația rulează cap-coadă pe Android, se instalează dintr-o comandă și
poate fi evaluată integral offline.
