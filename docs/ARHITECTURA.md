# Arhitectura FinEdu, ghid pe foldere

Documentul explică unde se află fiecare parte din cod și conținut. Proiectul
folosește o organizare **feature-first**: logica de business pură stă separat
de interfață, iar fiecare funcționalitate a aplicației își are propriul modul.

Regula de bază: `domain/` nu știe nimic despre Flutter (e Dart pur, testabil),
`core/` conține infrastructura comună, iar `features/` leagă totul de ecrane.

```
finedu_flutter/
├── lib/            codul sursă Dart
├── content/        conținutul aplicației (JSON), lecții, jocuri, simulare
├── assets/         fonturi și imaginile mascotei Cashy
├── test/           teste automate
├── tool/           unelte de dezvoltare (nu ajung în aplicație)
├── supabase/       backend-ul (migrații SQL + funcții edge)
├── docs/           documentație de proiect (arhitectură, research)
├── android/        platforma Android (singura inclusă)
└── (fișiere de configurare la rădăcină)
```

---

## `lib/`, codul sursă

Împărțit în trei straturi: `core`, `domain`, `features`.

### `lib/core/`, infrastructura comună

Cod folosit de toată aplicația, indiferent de funcționalitate.

| Folder | Ce conține |
|--------|-----------|
| `core/ui/` | Design system-ul claymorphism: culori, tipografie și umbre (`tokens.dart`), componente reutilizabile (`clay.dart`), iconițe (`svg_icon.dart`), animațiile și feedback-ul tactil (`juice.dart`), stările mascotei (`cashy_mood.dart`). |
| `core/db/` | Baza de date locală pe [drift](https://drift.simonbinder.eu/) (SQLite): definiția tabelelor (`app_db.dart`), migrațiile de la o versiune la alta, și repository-urile de profil. Aici e **sursa de adevăr offline**. |
| `core/router/` | Navigarea între ecrane cu `go_router`: cele 4 taburi, poarta de onboarding, rutele jocurilor. |
| `core/analytics/` | Un strat abstract peste evenimentele de analiză, ca aplicația să nu depindă direct de un furnizor anume. |
| `core/notifications/` | Notificările locale (memento-uri zilnice), fără dependență de server. |
| `core/sync/` | Sincronizarea oportunistă cu backend-ul (funcționează în gol până există cheile Supabase). |
| `core/supabase/` | Inițializarea condiționată a clientului Supabase. |
| `core/config/` | Citirea configurării (URL-uri, chei) din variabilele de build. |
| `core/utils/` | Utilitare mici (ex. încărcarea fișierelor din assets). |

### `lib/domain/`, logica pură (fără Flutter)

Inima aplicației. Tot ce ține de reguli, calcule și algoritmi stă aici, în Dart
curat, ca să poată fi testat riguros și izolat de interfață.

**`domain/engine/`**, motoarele de calcul:

| Fișier | Ce face |
|--------|---------|
| `score_engine.dart` | Calculează scorul FinEdu al utilizatorului din datele reale. |
| `streak_engine.dart` / `streak_rules.dart` | Streak-ul (zilele consecutive), cu înghețuri și borne. |
| `quest_engine.dart` | Misiunile zilnice și cufărul. |
| `fsrs.dart` | Programarea repetiției spațiate a cardurilor de recapitulare (algoritmul FSRS). |
| `leitner.dart` | Varianta clasică Leitner (păstrată ca referință). |
| `bandit.dart` | Personalizarea insight-urilor prin bandiți (Thompson Sampling). |
| `insight_rules.dart` | Regulile deterministe care generează sfaturile „Pentru tine". |
| `money_intel.dart` | Analiza banilor: categorii, anomalii, „liber de cheltuit", abonamente. |
| `compound.dart` | Matematica dobânzii compuse (pentru simulatorul din lecții). |
| `dojo_elo.dart` | Sistemul de rating Elo pentru jocul anti-țeapă. |
| `turbo_rules.dart` / `daily_challenge.dart` | Regulile jocurilor din Arcade. |
| `expedition_rules.dart` | Expedițiile mascotei Cashy. |
| `cashy_evolution.dart` / `cashy_state.dart` | Evoluția și starea emoțională a mascotei. |
| `notification_planner.dart` | Când și cum se programează notificările. |
| `recurring_materializer.dart` | Materializarea plăților recurente la scadență. |

**`domain/engine/life_sim/`**, motorul jocului „30 de Zile: Pe Cont Propriu":

| Fișier | Ce face |
|--------|---------|
| `money.dart` | Tipul `Money` (bani în valori întregi, niciodată virgulă mobilă). |
| `life_sim_rng.dart` | Generatorul de numere pseudo-aleatoare determinist (SplitMix64). |
| `life_sim_state.dart` | Starea imutabilă a unei luni de joc. |
| `life_sim_conditions.dart` / `life_sim_effects.dart` | Condițiile și efectele evenimentelor (sistem tipizat). |
| `life_sim_director.dart` | „Regizorul" care alege ce eveniment apare în fiecare zi. |
| `life_sim_engine.dart` | Bucla de joc: avans de zi, aplicare de decizie, salariu. |
| `life_sim_scoring.dart` | Scorul final pe 4 dimensiuni. |
| `life_sim_debrief.dart` | Analiza deciziilor la final. |
| `life_sim_commentary.dart` | Replicile mascotei Cashy despre deciziile tale. |
| `life_sim_content.dart` | Citirea conținutului jocului din JSON. |

**`domain/models/`**, modelele de date (tranzacții, categorii).
**`domain/util/`**, utilitare de domeniu (ex. formatarea datelor calendaristice).

### `lib/features/`, funcționalitățile

Fiecare folder e o funcționalitate de sine stătătoare. Convenția internă:
`data/` (accesul la date + providerii) și `presentation/` (ecranele și widget-urile).

| Funcționalitate | Ce e |
|-----------------|------|
| `onboarding/` | Primul contact: eclozarea mascotei, quiz de calibrare, setarea bugetului. |
| `home/` | Ecranul principal: buget, scor, misiuni, obiective, insight-uri. |
| `tracking/` | Adăugarea cheltuielilor și economiilor. |
| `learning/` | Lecțiile interactive, player-ul, recapitularea. |
| `arcade/` | Jocurile: Provocarea Zilei, Turbo Buget, Scam Dojo și `life_month/` (jocul „30 de Zile"). |
| `gamification/` | Serviciul central de gamificare (scor, evoluție). |
| `goals/` | Obiectivele de economisire. |
| `recurring/` | Abonamentele și plățile recurente. |
| `streak/` | Ecranul streak-ului („Focul lui Cashy"). |
| `insights/` | Sfaturile personalizate. |
| `wardrobe/` | Garderoba mascotei (cosmetice cumpărate cu ghinde). |
| `expeditions/` | Expedițiile mascotei. |
| `profile/` | Profilul: scor, statistici, setări. |
| `finbot/` | Chat-ul cu Cashy (pregătit pentru partea de AF cloud). |
| `notifications/` | Reprogramarea notificărilor. |

### `lib/l10n/`
Traducerile interfeței (română + engleză), generate din fișiere ARB.

---

## `content/`, conținutul aplicației (JSON)

Conținutul e separat de cod, ca să poată fi editat fără a modifica aplicația.

| Folder | Ce conține |
|--------|-----------|
| `content/lessons/` | Cele 6 unități de lecții (`unit1.json` … `unit6.json`), bilingve. |
| `content/arcade/` | Mesajele și întrebările jocurilor din Arcade. |
| `content/cashy/` | Catalogul Garderobei (fundaluri, accesorii). |
| `content/life_sim/` | Conținutul jocului „30 de Zile": roluri, orașe, facturi, obiective, finaluri, plus `events/` (cele ~100 de evenimente). |
| `content/*.json` (rădăcină) | Insight-uri, notificări, expediții. |

---

## `assets/`
Fonturile aplicației (Baloo 2, Plus Jakarta Sans) și imaginile mascotei Cashy
în diferitele ei stări (fericit, îngrijorat, studiază, sărbătorește).

## `test/`
Testele automate (~30 de fișiere). Acoperă motoarele de calcul (scor, streak,
FSRS, simulare), conținutul (validare de structură) și interfața (widget tests).
Se rulează cu `flutter test`.

## `tool/`
Unelte de dezvoltare care **nu** ajung în aplicația finală. `life_sim_monte_carlo.dart`
rulează zeci de mii de partide simulate ca să verifice echilibrul jocului „30 de Zile".

## `supabase/`
Backend-ul: migrațiile SQL ale bazei de date (`migrations/`) și funcțiile edge
(`functions/`) pentru partea de AI. Aplicația merge complet offline fără el.

## `docs/`
Documentația de proiect: acest fișier și notele de research cu surse
(`docs/research/`). Documentația tehnică completă este la rădăcină, în
`DOCUMENTATIE_COMPLETA.md`.

## Folderul de platformă
`android/` este singura platformă inclusă: aplicația e dezvoltată și testată
pe **Android**. Suportul pentru alte platforme se poate genera oricând cu
`flutter create --platforms=... .`, codul Dart fiind independent de platformă.

---

## Fișiere de configurare (rădăcină)

| Fișier | Rol |
|--------|-----|
| `pubspec.yaml` | Dependențele și lista de assets. |
| `analysis_options.yaml` | Regulile de analiză statică a codului. |
| `l10n.yaml` | Configurarea traducerilor. |
| `README.md` | Prezentarea proiectului (vezi rădăcina). |
