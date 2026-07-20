# Componente care nu au fost realizate de autor

Fișier explicativ cerut de regulamentul Olimpiadei de Inovare și Creație
Digitală InfoEducație (Art. 8): listează toate componentele proiectului care
nu au fost realizate de autor, plus proveniența lor.

Proiect individual. Autor: Circiumaru Alexandru Radu. Tot ce nu apare în
lista de mai jos (codul aplicației, arhitectura, motoarele de calcul,
conținutul educațional în JSON, testele, documentația) a fost realizat de
autor în cadrul proiectului.

## 1. Biblioteci externe (pub.dev)

Declarate în `pubspec.yaml`, instalate prin `flutter pub get`, nescrise de
autor:

| Pachet | La ce e folosit |
|--------|-----------------|
| flutter, flutter_localizations | framework-ul UI și localizarea (Google) |
| flutter_riverpod, riverpod_annotation | starea reactivă și injecția de dependențe |
| go_router | navigarea |
| drift, drift_flutter | baza de date SQLite tipizată |
| supabase_flutter | clientul de backend (pregătit, neactivat) |
| flutter_local_notifications, timezone | memento-ul local zilnic |
| connectivity_plus | starea conexiunii |
| path_provider | căile de stocare locală |
| intl | formatare de numere și date |
| uuid | identificatori unici pentru tranzacții |
| flutter_inset_shadow | umbre interioare pentru stilul claymorphism |
| freezed_annotation, json_annotation | modele imutabile și serializare |
| cupertino_icons | set de iconițe standard |
| build_runner, freezed, json_serializable, riverpod_generator, drift_dev | generare de cod la dezvoltare |
| flutter_test, flutter_lints, custom_lint, riverpod_lint | teste și lint |

## 2. Fonturi

Incluse local în `assets/fonts/`, create de terți, sub licența SIL Open Font
License:

- Baloo 2 (titluri)
- Plus Jakarta Sans (text curent)

## 3. Algoritmi publici

Implementările din proiect sunt scrise de autor în Dart, dar algoritmii și,
unde e cazul, parametrii provin din surse publice:

- FSRS-6 (repetiție spațiată): formulele sunt publice, iar cei 21 de
  parametri impliciți sunt copiați identic din proiectul open-source py-fsrs
  (licență MIT). Declarat și în comentariile din
  `lib/domain/engine/fsrs.dart`.
- SplitMix64 (generator de numere pseudo-aleatoare determinist): algoritm
  public, implementare proprie în
  `lib/domain/engine/life_sim/life_sim_rng.dart`.
- Elo (rating-ul mesajelor din Scam Dojo): formulă publică, implementare și
  adaptare proprie în `lib/domain/engine/dojo_elo.dart`.
- Thompson Sampling Beta-Bernoulli (personalizarea opt-in): metodă publică,
  implementare proprie în `lib/domain/engine/bandit.dart`.
- Regula 50/30/20 și formula dobânzii compuse: cunoștințe financiare
  publice, implementate de autor.

## 4. Imagini

- Imaginile mascotei Cashy (`assets/mascot/`), imaginea ghindei
  (`assets/icons/acorn.png`) și iconițele desenate ale categoriilor de
  cheltuieli (`assets/icons/cat_*.png`) sunt fișiere grafice externe, nu au
  fost desenate în cod de autor. Au fost create cu unelte de generare de
  imagini pe baza descrierilor autorului, pentru identitatea vizuală FinEdu,
  apoi procesate în proiect (decupare, transparență, redimensionare).
- Iconițele de interfață sunt desenate de autor ca path-uri SVG în
  `lib/core/ui/svg_icon.dart`.

## 5. Unelte de asistență la scriere

La scrierea codului și a conținutului au fost folosite unelte de asistență
bazate pe modele de limbaj, pe baza specificațiilor autorului. Arhitectura,
deciziile de produs, regulile pedagogice, validarea pe emulator și verificarea
finală a fiecărei etape aparțin autorului.

## 6. Date și cifre din conținut

Cifrele financiare românești din lecții și din simulare (salariul minim,
contribuții, prețuri) sunt preluate din surse publice, notate în
`docs/research/`. Salariile rolurilor din simulare sunt estimări pe baza
datelor publice de piață și poartă explicit eticheta `needs_expert_review`
în `content/life_sim/roles.json`, până la validarea de către un specialist.
