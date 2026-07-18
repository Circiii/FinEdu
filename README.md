# FinEdu

Aplicație mobilă de **educație financiară pentru adolescenți** (14-25 de ani),
construită în Flutter. Îi învață pe tineri să-și gestioneze banii prin lecții
interactive, jocuri și o simulare a vieții pe cont propriu, totul într-un
univers vizual propriu, cu mascota Cashy.

Aplicația funcționează **complet offline**: toate datele stau local, pe telefon.

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

## Cum rulezi proiectul

**Ai nevoie de:** [Flutter SDK](https://docs.flutter.dev/get-started/install)
(versiune stabilă recentă) și un emulator Android sau un telefon conectat.

```bash
# 1. Instalezi dependențele
flutter pub get

# 2. Rulezi aplicația
flutter run
```

Aplicația pornește direct, fără configurare suplimentară, nu are nevoie de chei
sau de conexiune la internet.

### Build pentru instalare

```bash
flutter build apk --release
```

APK-ul rezultat se află în `build/app/outputs/flutter-apk/`.

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
[DOCUMENTATIE_COMPLETA.md](DOCUMENTATIE_COMPLETA.md).

---

## Notă despre date și confidențialitate

Aplicația e gândită pentru minori, așa că respectă principii stricte:
datele rămân pe telefon, nu se face profilare fără acordul explicit, iar
conținutul e educativ (nu oferă consultanță financiară personalizată).
Detalii în [CONTENT_POLICY.md](CONTENT_POLICY.md).
