# Pedagogia din spatele Lecțiilor 3.0

Cercetare pe metodele dovedite științific pentru lecții digitale la 14-25 de ani,
aplicată în player-ul de lecții FinEdu. Fiecare decizie de design de mai jos are
sursa ei, lista completă la final.

## Metodele, ordonate după impactul dovedit

1. **Retrieval practice / testing effect**, a răspunde activ bate recitirea
   (~1,5× retenție la o săptămână; g = 0,61 în meta-analiza Adesope 2017 pe 272
   de studii, cu efectul cel mai mare exact la liceeni). Mixul de formate
   (grilă + completare + scenariu) dă efectul maxim.
2. **Spaced repetition**, perechea obligatorie a retrieval-ului; Duolingo a
   măsurat +9,5% retenție cu modelul half-life regression. FinEdu folosește
   FSRS-6 pe cardurile de concept.
3. **Feedback imediat și explicativ**, d = 0,79 (Hattie & Timperley 2007);
   efect mult mai mare când feedback-ul explică „de ce", inclusiv la răspunsuri
   corecte. Feedback informațional, nu evaluativ, protejează motivația
   intrinsecă (Deci 1999).
4. **Worked examples (Sweller)**, novicii învață mai mult dintr-o rezolvare pas
   cu pas decât aruncați direct în problemă; se estompează treptat la avansați.
5. **Pretesting effect**, a ghici ÎNAINTE de conținut (chiar greșind) pregătește
   encodarea; bate și post-testarea (Journal of Cognition 2025).
6. **Predicție + violarea așteptării (Brod 2021)**, surpriza amplifică memoria;
   ideală în finanțe, unde intuițiile naive sunt sistematic greșite.
7. **Generation effect**, informația generată de elev (completare, ordonare) e
   reținută cu d = 0,40 față de aceeași informație citită (Bertsch 2007).
8. **Principiile multimedia Mayer**, pe mobil contează cel mai mult:
   *segmenting* (bucăți mici, elevul controlează ritmul cu tap), *coherence*
   (zero decor irelevant, „seductive details" SCAD învățarea), *signaling*
   (UN singur element evidențiat per ecran), *personalization* (ton
   conversațional; d = 0,54 pe transfer, maxim la lecții scurte, Ginns 2013).
9. **Curiosity gap (Loewenstein)**, hook-ul deschide un GOL specific de
   cunoaștere, nu anunță un subiect; curiozitatea amplifică memoria pentru toată
   fereastra lecției (Gruber 2014, Neuron).
10. **Storytelling concret (Willingham)**, poveștile sunt „privilegiate
    psihologic" (~50% retenție în plus vs. text expozitiv); personaj → obiectiv
    → obstacol → consecință, cu sume reale în lei. Definiția vine DUPĂ exemplu.
11. **Design emoțional (Um/Plass)**, culori calde, forme rotunde, mascotă cu
    față expresivă integrată în conținut: efect măsurat pe comprehensiune și
    transfer, nu decor.
12. **Gamificare pe Self-Determination Theory**, DA: progres vizibil, streak
    flexibil, feedback de competență; NU: leaderboard-uri forțate (Hanus & Fox
    2015, note mai mici), recompense controlante (overjustification, Deci 1999).
13. **Microlearning**, sesiuni de 3-5 minute cresc retenția (OR = 1,87,
    meta-analiza 2025); metoda Duolingo: learn by doing + personaje + umor.
14. **Specific educației financiare (Kaiser & Menkhoff)**, cunoștințele cresc
    ușor (+0,25 SD), comportamentul greu (+0,05 SD); decalajul se închide prin
    practică activă de decizie (de-asta există „30 de Zile" și scenariile).

## Cum se traduc în player-ul FinEdu

- **Hook = gol de curiozitate** pe primul ecran, apoi **guess** (pretesting cu
  slider, greșeala nu costă nimic, microcopy explicit).
- **Pagina de concept = blocuri dezvăluite prin tap** (segmenting), o idee per
  bloc: paragraf / callout / cifră-vedetă animată / comparație vs / pași
  numerotați / replica lui Cashy (personalization + design emoțional).
- **Signaling**: markup `**bold**` și `==evidențiat==`, o singură evidențiere
  per bloc, cifrele importante mari și izolate (StatBlock).
- **Scenariu narativ** cu consecințe per opțiune în locul definiției; exemplul
  lucrat pas cu pas (StepsBlock) înaintea exercițiului.
- **Generare > citire**: cloze, ordonare de pași (order), potrivire de perechi
  (pairs), sortare swipe; carduri mit→realitate (reveal) pe curiosity gap.
- **Feedback cu „de ce"** la fiecare răspuns, inclusiv corect; distractorii
  numesc neînțelegerea reală; umorul stă în distractori și în replicile lui
  Cashy, nu în decor (coherence).
- **Quiz de retrieval** la final + reîntrebarea itemului ratat în recap +
  cardurile lecției intră în FSRS a doua zi (spacing).

## Surse

Mayer / multimedia:
- Mayer, Applying the Science of Learning: <https://pressbooks.pub/learningenvironmentsdesign/chapter/mayer-applying-the-science-of-learning-evidence-based-principles-for-the-design-of-multimedia-instruction/>
- Mayer, Fiorella & Stull (2021): <https://www.sciencedirect.com/science/article/abs/pii/S2211368121000231>
- Review sistematic principii multimedia (2022): <https://link.springer.com/article/10.1186/s40561-022-00200-2>
- Ginns, Martin & Marsh (2013), ton conversațional: <https://link.springer.com/article/10.1007/s10648-013-9228-0>

Retrieval / pretesting / predicție:
- Roediger & Karpicke (2006): <https://journals.sagepub.com/doi/10.1111/j.1467-9280.2006.01693.x>
- Adesope, Trevisan & Sundararajan (2017): <https://journals.sagepub.com/doi/abs/10.3102/0034654316689306>
- Agarwal et al. (2021): <https://pdf.poojaagarwal.com/Agarwal_etal_2021_EDPR.pdf>
- Kornell, Hays & Bjork (2009): <https://www.researchgate.net/publication/26655655_Unsuccessful_Retrieval_Attempts_Enhance_Subsequent_Learning>
- Pretesting, Journal of Cognition (2025): <https://journalofcognition.org/articles/10.5334/joc.455>
- Pretesting, Memory & Cognition (2025): <https://link.springer.com/article/10.3758/s13421-025-01813-x>
- Brod (2021), predicția ca strategie: <https://link.springer.com/article/10.3758/s13423-021-01904-1>

Curiozitate:
- Golman & Loewenstein: <https://www.cmu.edu/dietrich/sds/docs/golman/golman_loewenstein_curiosity.pdf>
- Gruber, Gelman & Ranganath (2014), Neuron: <https://www.cell.com/neuron/fulltext/S0896-6273(14)00804-6>
- Kidd & Hayden (2015): <https://www.sciencedirect.com/science/article/pii/S0896627315007679>
- Edutopia, hook-uri: <https://www.edutopia.org/article/strategies-capture-students-attention/>

Generare / worked examples / storytelling:
- Bertsch et al. (2007): <https://link.springer.com/article/10.3758/BF03193441>
- Meta generare de text (2023): <https://link.springer.com/article/10.1007/s10648-023-09758-w>
- CESE NSW (2017), Cognitive Load Theory: <https://education.nsw.gov.au/content/dam/main-education/about-us/educational-data/cese/2017-cognitive-load-theory.pdf>
- van Gog et al. (2011): <https://www.sciencedirect.com/science/article/abs/pii/S0361476X1000055X>
- Willingham (2004), Privileged Status of Story: <https://www.aft.org/periodical/american-educator/summer-2004/ask-cognitive-scientist>

Motivație / gamificare:
- Deci, Koestner & Ryan (1999): <https://home.ubalt.edu/tmitch/642/articles%20syllabus/Deci%20Koestner%20Ryan%20meta%20IM%20psy%20bull%2099.pdf>
- Sailer et al. (2017): <https://www.sciencedirect.com/science/article/pii/S074756321630855X>
- Meta gamificare & SDT (2023): <https://link.springer.com/article/10.1007/s11423-023-10337-7>
- Hanus & Fox (2015): <https://www.sciencedirect.com/science/article/abs/pii/S0360131514002000>
- Toda et al. (2018), Dark Side of Gamification: <https://www.researchgate.net/publication/326876949_The_Dark_Side_of_Gamification_An_Overview_of_Negative_Effects_of_Gamification_in_Education>

Duolingo:
- The Duolingo Method (2023): <https://blog.duolingo.com/duolingo-teaching-method/>
- Settles & Meeder (2016), half-life regression: <https://research.duolingo.com/papers/settles.acl16.pdf>
- Streaks & habit: <https://blog.duolingo.com/how-duolingo-streak-builds-habit/>

Design emoțional:
- Plass, Heidig, Hayward, Homer & Um (2014): <https://www.sciencedirect.com/science/article/abs/pii/S0959475213000273>
- Review 2025: <https://pmc.ncbi.nlm.nih.gov/articles/PMC11939454/>

Feedback / microlearning / educație financiară:
- Hattie & Timperley (2007): <https://journals.sagepub.com/doi/abs/10.3102/003465430298487>
- Wisniewski, Zierer & Hattie (2019): <http://www.frontiersin.org/articles/10.3389/fpsyg.2019.03087/full>
- Meta microlearning (2025): <https://www.researchgate.net/publication/394265408_Microlearning_Effectiveness_in_Higher_Education_A_Systematic_Review_and_Meta-Analysis_of_Student_Retention_and_Learning_Outcomes>
- Learning Scientists, Six Strategies: <https://www.learningscientists.org/posters>
- Kaiser & Menkhoff: <https://www.sciencedirect.com/science/article/abs/pii/S0272775718306940>
- GFLEC meta-analiză: <https://gflec.org/metaanalysis/>
