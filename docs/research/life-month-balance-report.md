# Raport de echilibrare „30 de Zile" (Monte Carlo)

> Generat determinist de tool/life_sim_monte_carlo.dart, N=10000 run-uri, 9 roluri × 2 moduri × 4 politici, contentVersion 2.0.0.

## Sinteză

- Run-uri terminate fără excepții: 10000/10000 (100.00%)
- Run-uri cu cash negativ la un moment dat: 3101 (31.0%)
- Dintre ele, recuperate (scor final >50): 2821 (91.0%)

## Scor pe politici (media / p10 / p90 total)

- **random**: medie 61.5 · p10 53 · p90 70 (control 93 / rezil 57 / obiect 28 / echilib 55)
- **avar**: medie 61.8 · p10 55 · p90 70 (control 96 / rezil 59 / obiect 27 / echilib 49)
- **echilibrat**: medie 70.5 · p10 60 · p90 82 (control 92 / rezil 69 / obiect 48 / echilib 63)
- **generos**: medie 66.9 · p10 55 · p90 81 (control 85 / rezil 67 / obiect 46 / echilib 60)

## Dificultate pe roluri (media scorului total + cash final p50)

- **asistent_medical**: scor mediu 72.8 · cash final p10/p50/p90: -415/720/2540 lei
- **curier**: scor mediu 58.7 · cash final p10/p50/p90: -1182/68/1435 lei
- **freelancer_creativ**: scor mediu 71.0 · cash final p10/p50/p90: 512/2165/4353 lei
- **lucrator_comercial**: scor mediu 61.2 · cash final p10/p50/p90: -545/555/2135 lei
- **ospatar**: scor mediu 61.9 · cash final p10/p50/p90: -1127/94/1803 lei
- **profesor_debutant**: scor mediu 66.9 · cash final p10/p50/p90: -550/564/1890 lei
- **programator_junior**: scor mediu 64.7 · cash final p10/p50/p90: 1327/2544/4570 lei
- **sofer_ridesharing**: scor mediu 68.4 · cash final p10/p50/p90: -1010/320/2340 lei
- **student_partime**: scor mediu 61.0 · cash final p10/p50/p90: -546/655/1860 lei

- Media globală: 65.2
- Datorie finală p50: 450 lei · Fond final p50: 947 lei

## Top 20 evenimente (frecvență globală)

- seasonal_mall_marketing: 4761 apariții · în 47.6% din run-uri
- seasonal_1iunie_festival: 3951 apariții · în 39.5% din run-uri
- pranz_colegi: 3938 apariții · în 34.5% din run-uri
- supermarket_marca: 2891 apariții · în 26.2% din run-uri
- friends_seara_jocuri: 2753 apariții · în 27.5% din run-uri
- friends_zi_nastere: 2683 apariții · în 26.8% din run-uri
- borcan_marunt: 2579 apariții · în 25.8% din run-uri
- bec_ars: 2560 apariții · în 25.6% din run-uri
- vecin_zgomot: 2544 apariții · în 25.4% din run-uri
- seasonal_canicula: 2517 apariții · în 25.2% din run-uri
- social_cadou_sef: 2400 apariții · în 24.0% din run-uri
- internet_instabil: 2375 apariții · în 23.8% din run-uri
- robinet_picura: 2341 apariții · în 23.4% din run-uri
- tech_date_depasire: 2313 apariții · în 23.1% din run-uri
- friends_iesire_colegi: 2280 apariții · în 22.8% din run-uri
- tech_telefon_baterie: 2255 apariții · în 22.6% din run-uri
- friends_meci_bar: 2237 apariții · în 22.4% din run-uri
- abonament_fantoma: 2146 apariții · în 21.5% din run-uri
- prelungitor_scantei: 2063 apariții · în 20.6% din run-uri
- farmacie_generic: 2041 apariții · în 20.4% din run-uri

## Semnale

- Niciun eveniment nu domină >80% din run-uri. ✔
- Zero run-uri imposibile (excepții). ✔
