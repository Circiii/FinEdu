# Raport de echilibrare „30 de Zile" (Monte Carlo)

> Generat determinist de tool/life_sim_monte_carlo.dart, N=3000 run-uri, 9 roluri × 2 moduri × 4 politici, contentVersion 2.0.0.

## Sinteză

- Run-uri terminate fără excepții: 3000/3000 (100.00%)
- Run-uri cu cash negativ la un moment dat: 978 (32.6%)
- Dintre ele, recuperate (scor final >50): 886 (90.6%)

## Scor pe politici (media / p10 / p90 total)

- **random**: medie 61.6 · p10 53 · p90 72 (control 92 / rezil 57 / obiect 28 / echilib 55)
- **avar**: medie 61.9 · p10 56 · p90 70 (control 96 / rezil 59 / obiect 28 / echilib 49)
- **echilibrat**: medie 70.3 · p10 59 · p90 82 (control 92 / rezil 68 / obiect 47 / echilib 64)
- **generos**: medie 66.6 · p10 55 · p90 81 (control 84 / rezil 67 / obiect 46 / echilib 61)

## Dificultate pe roluri (media scorului total + cash final p50)

- **asistent_medical**: scor mediu 72.9 · cash final p10/p50/p90: -348/615/2435 lei
- **curier**: scor mediu 58.5 · cash final p10/p50/p90: -1333/38/1420 lei
- **freelancer_creativ**: scor mediu 70.9 · cash final p10/p50/p90: 358/2192/4510 lei
- **lucrator_comercial**: scor mediu 61.2 · cash final p10/p50/p90: -673/620/2157 lei
- **ospatar**: scor mediu 61.5 · cash final p10/p50/p90: -1256/19/1815 lei
- **profesor_debutant**: scor mediu 66.8 · cash final p10/p50/p90: -722/515/1895 lei
- **programator_junior**: scor mediu 64.8 · cash final p10/p50/p90: 980/2555/4580 lei
- **sofer_ridesharing**: scor mediu 68.0 · cash final p10/p50/p90: -1238/241/2420 lei
- **student_partime**: scor mediu 61.3 · cash final p10/p50/p90: -559/597/1915 lei

- Media globală: 65.1
- Datorie finală p50: 450 lei · Fond final p50: 957 lei

## Top 20 evenimente (frecvență globală)

- seasonal_mall_marketing: 1468 apariții · în 48.9% din run-uri
- pranz_colegi: 1349 apariții · în 38.3% din run-uri
- seasonal_1iunie_festival: 1213 apariții · în 40.4% din run-uri
- supermarket_marca: 965 apariții · în 29.5% din run-uri
- friends_seara_jocuri: 904 apariții · în 30.1% din run-uri
- friends_zi_nastere: 875 apariții · în 29.2% din run-uri
- vecin_zgomot: 873 apariții · în 29.1% din run-uri
- bec_ars: 835 apariții · în 27.8% din run-uri
- seasonal_canicula: 816 apariții · în 27.2% din run-uri
- tech_date_depasire: 790 apariții · în 26.3% din run-uri
- internet_instabil: 769 apariții · în 25.6% din run-uri
- social_cadou_sef: 765 apariții · în 25.5% din run-uri
- friends_iesire_colegi: 750 apariții · în 25.0% din run-uri
- robinet_picura: 731 apariții · în 24.4% din run-uri
- friends_meci_bar: 723 apariții · în 24.1% din run-uri
- farmacie_generic: 719 apariții · în 24.0% din run-uri
- card_farmacie: 699 apariții · în 23.3% din run-uri
- tech_telefon_baterie: 682 apariții · în 22.7% din run-uri
- relationship_cina_pereche: 653 apariții · în 21.8% din run-uri
- family_familia_cere_bani: 646 apariții · în 21.5% din run-uri

## Semnale

- Niciun eveniment nu domină >80% din run-uri. ✔
- Zero run-uri imposibile (excepții). ✔
