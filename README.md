# FinEdu

Aplicație de **educație financiară pentru adolescenți** (14-25 de ani),
construită în Flutter. Îi învață pe tineri să-și gestioneze banii prin lecții
interactive, jocuri și o simulare a vieții pe cont propriu, totul într-un
univers vizual propriu, cu mascota Cashy.

Rulează pe **Android, Windows și în browser**, din același cod.

Aplicația funcționează **complet offline**: toate datele rămân pe dispozitivul
tău, nu pleacă nicăieri.

---

## Descarcă

Nu trebuie să construiești nimic. Ia fișierul potrivit și gata.

| Ai... | Descarcă | Mărime |
|---|---|---|
| **Telefon Android** (din 2016 încoace) | [FinEdu-android-arm64.apk](../../releases/latest) | 25 MB |
| **Telefon Android mai vechi** | [FinEdu-android-arm32.apk](../../releases/latest) | 23 MB |
| **Nu știi ce Android ai** | [FinEdu-android-universal.apk](../../releases/latest) | 68 MB |
| **Windows 10 sau 11** | [FinEdu-windows.zip](../../releases/latest) | ~25 MB |
| **iPhone, iPad, Mac, Linux** | [Deschide în browser](https://circiii.github.io/FinEdu/) | fără instalare |

Toate fișierele sunt în **[Releases](../../releases/latest)**.

**Pe Android**, telefonul o să te întrebe dacă permiți instalarea din afara
magazinului. E normal pentru orice aplicație care nu vine din Play Store.

**Pe Windows**, dezarhivezi folderul și pornești `finedu_flutter.exe` din el.
Executabilul nu merge scos singur din folder, are nevoie de fișierele de lângă
el. Windows poate afișa un avertisment SmartScreen, fiindcă aplicația nu e
semnată digital: apeși „Informații suplimentare", apoi „Executați oricum".

**Pe iPhone nu există fișier de descărcat.** Apple cere ca orice aplicație să
fie semnată cu un cont de dezvoltator plătit ca să se poată instala, așa că
versiunea de browser e calea. Se deschide în Safari, arată la fel, iar progresul
rămâne salvat pe telefon.

---

## Ce conține

- **Bugetare reală**, adaugi cheltuieli și economii, îți setezi un buget lunar,
  urmărești unde se duc banii.
- **Lecții interactive**, 7 unități (35 de lecții) despre bugetare, economisire,
  dobânda compusă, recunoașterea țepelor online și primul venit, cu
  recapitulare prin repetiție spațiată (FSRS-6).
- **Arcade**, jocuri scurte care testează deciziile financiare: Provocarea Zilei,
  Turbo Buget, Scam Dojo (anti-țeapă).
- **30 de Zile: Pe Cont Propriu**, o simulare a unei luni pe salariu real
  românesc: primești un venit, plătești facturi, gestionezi evenimente
  neprevăzute și vezi consecințele deciziilor tale.
- **Gamificare**, streak zilnic, misiuni, obiective de economisire, o mascotă
  care evoluează și o garderobă cosmetică cumpărată cu „ghinde".
- **Sfaturi personalizate**, analiză locală a cheltuielilor care generează
  observații utile, fiecare cu explicația „cum am calculat".

---

## Cum rulezi aplicația

Aplicația nu cere niciun cont, nicio cheie și nicio conexiune la internet. Alege
varianta care ți se potrivește.

| Vrei să... | Mergi la |
|---|---|
| o deschizi cel mai repede, în browser | [Varianta 1](#varianta-1-în-browser-recomandat) |
| o instalezi pe un telefon Android | [Varianta 2](#varianta-2-pe-android) |
| o rulezi ca program pe Windows | [Varianta 3](#varianta-3-pe-windows) |

Pentru toate îți trebuie
[Flutter SDK](https://docs.flutter.dev/get-started/install), versiune stabilă
recentă. Verifici că e gata cu `flutter doctor`.

### Varianta 1: în browser (recomandat)

Cea mai simplă. Merge pe Windows, macOS și Linux, fără emulator și fără telefon.

```bash
flutter pub get

# Baza de date rulează într-un fir separat al browserului. Worker-ul se
# compilează o singură dată, nu e ținut în repo fiindcă e cod generat.
dart compile js -O4 web/drift_worker.dart -o web/drift_worker.js

flutter build web --release --no-web-resources-cdn
dart run tool/serve_web.dart
```

Apoi deschizi **http://localhost:8080**. Prima pornire durează câteva secunde,
cât se încarcă motorul grafic; vezi un ecran de așteptare până atunci.

Trei lămuriri, ca să nu pară ciudat:

- **De ce nu deschizi direct fișierul din `build/web`.** Browserele blochează
  cererile pornite dintr-o pagină `file://`, iar aplicația trebuie să încarce
  fonturi și baza de date. De aceea e nevoie de serverul de mai sus.
- **De ce `--no-web-resources-cdn`.** Fără el, motorul grafic e cerut de pe un
  server Google. Cu el, totul e servit din propriul folder, deci aplicația merge
  și fără internet.
- **De ce se compilează worker-ul separat.** E JavaScript generat din sursa pe
  care o livrează pachetul drift. Fișierul rezultat are peste 13.000 de linii,
  deci stă mai bine construit la nevoie decât ținut în istoric.

Progresul se salvează în browser (în stocarea privată a paginii) și rezistă la
reîncărcare. Ca să pornești de la zero, deschizi fereastra în mod incognito.

### Varianta 2: pe Android

Cu un emulator pornit sau un telefon conectat prin USB:

```bash
flutter pub get
flutter run
```

Pentru un fișier de instalare de sine stătător:

```bash
flutter build apk --release
```

APK-ul rezultat se află în `build/app/outputs/flutter-apk/`.

### Varianta 3: pe Windows

Aici mai e nevoie de două lucruri instalate o singură dată, înainte:

1. **Visual Studio 2022** cu pachetul „Desktop development with C++". Fără el
   nu există compilator de C++ și build-ul nici nu pornește.
2. **Modul dezvoltator** din Windows, pornit din `ms-settings:developers`.
   Flutter are nevoie de el ca să creeze legăturile simbolice pentru
   componentele native.

Apoi:

```bash
flutter pub get
flutter run -d windows
```

Prima compilare durează mai mult: descarcă și compilează SQLite, deci are nevoie
de internet o singură dată.

### Rularea testelor

```bash
flutter test
```

---

## Tehnologii folosite

| Domeniu | Tehnologie |
|---------|-----------|
| Framework | Flutter / Dart |
| Stare | Riverpod |
| Navigare | go_router |
| Bază de date locală | drift (SQLite) |
| Internaționalizare | Română (implicit) + Engleză |
| Backend (opțional) | Supabase, aplicația merge și fără el |

---

## Structura proiectului

Codul e organizat **feature-first**, cu logica de business pură separată de
interfață. Pe scurt:

```
lib/
├── core/        infrastructura comună (UI, bază de date, navigare)
├── domain/      logica pură, testabilă (motoare de calcul, modele)
└── features/    funcționalitățile aplicației, fiecare cu ecranele ei

content/         conținutul (lecții, jocuri) în JSON, editabil separat
assets/          fonturi și imaginile mascotei
test/            teste automate
```

Pentru explicația detaliată a fiecărui folder, vezi
[docs/ARHITECTURA.md](docs/ARHITECTURA.md).

**Documentația tehnică completă a proiectului** (instalare, utilizare,
arhitectură, fiecare componentă, testare, limitări) este în
[DOCUMENTATIE_COMPLETA.md](DOCUMENTATIE_COMPLETA.md). Componentele care nu au
fost realizate de autor sunt declarate în
[COMPONENTE_EXTERNE.md](COMPONENTE_EXTERNE.md).

---

## Notă despre date și confidențialitate

Aplicația e gândită pentru minori, așa că respectă principii stricte:
datele rămân pe telefon, nu se face profilare fără acordul explicit, iar
conținutul e educativ (nu oferă consultanță financiară personalizată).
Detalii în [CONTENT_POLICY.md](CONTENT_POLICY.md).
