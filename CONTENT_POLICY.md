# CONTENT_POLICY.md, Educație financiară, NU consultanță de investiții

> Sursă: PLAN2 §2.9.2 + gap-ul MiFID din `docs/research/critic.md`. Aplicată de un agent-validator juridic (Șablon B, PLAN2 §5.1) pe TOT conținutul generat + pe FinBot. **Blocant hard de lansare**, nu e o bifă.

## (a) Principiul și de ce

**FinEdu predă concepte financiare generice. NU dă recomandări personalizate de investiții.**

De ce contează, nu ca formalitate:
- Sub **MiFID II**, briefing-ul de supraveghere **ESMA 2023** (ESMA35-43-3861) spune explicit că recomandările livrate prin aplicații sau mesaje targetate pot constitui *„personal recommendations"* = **consultanță de investiții reglementată**. Factorul declanșator e **personalizarea**.
- FinEdu combină exact ingredientele riscante: **profil financiar individual** + **LLM care generează răspunsuri personalizate**. Dacă FinBot spune unui user de 16 ani „cu economiile tale ai putea lua un ETF", aia poate fi consultanță fără licență **ASF**.
- **Publicul e minor.** Studiul FCA arată deja că gamificarea împinge disproporționat tinerii spre decizii riscante. Granița de conținut e un risc **existențial** pentru o echipă de 1 dev, nu un detaliu.
- Poziționarea corectă (Education, nu Finance) e și **argument de vânzare** către băncile partenere B2B2C.

## (b) DA vs NU

### ✅ DA, concepte generice, educaționale
- Dobânda compusă (ca mecanism matematic).
- Diversificarea **ca idee / principiu** („nu pune toate ouăle într-un coș").
- Bugetul (50/30/20, jurnalul cheltuielilor, nevoie vs dorință).
- DAE / dobânda la credite (cum se citește, de ce contează).
- Fondul de urgență (de ce, cât, ca regulă generală).
- Riscul ca **noțiune** (risc vs randament, orizont de timp, la nivel conceptual).
- Inflația, costul de oportunitate, lichiditatea, ca fenomene.
- Cum funcționează frauda / țepele (educație defensivă, Dojo).

### ❌ NU, orice devine recomandare
- **Instrumente specifice** („ia acest ETF/fond/depozit anume").
- **Ticker-e / nume de produse** („BET, S&P 500 prin acest ETF, acțiunea X").
- **„Cât să investești"** / sume personalizate („cu 500 lei ai putea...").
- **Crypto tips** (ce monedă, când, „metoda de pe TikTok").
- **Timing de piață** („acum e momentul să cumperi/vinzi").
- **Recomandări personalizate de produs financiar** (bancă, card, credit, asigurare anume).
- **Îndemnuri la tranzacționare** („deschide un cont de trading și...").
- **Leaderboard pe randament** pe termen scurt (ar preda day-trading, avertismentul FCA).

> Linia roșie: în momentul în care conținutul leagă un **instrument/sumă/acțiune concretă** de **situația individuală a userului**, a trecut din educație în consultanță. Conceptul generic e permis; aplicarea personalizată la un produs specific nu.

## (c) Regulile FinBot

FinBot **refuză sistematic** recomandările de investiții și **redirecționează educațional**. System prompt cu guardrails; comportament testat prin red-teaming adversarial înainte de lansare (F5, agent dedicat, 100+ prompturi ostile, raportul e criteriul de acceptare).

### Exemplu 1, „în ce să investesc?"

> **User:** Am strâns 800 de lei. În ce crypto să bag ca să se dubleze?
>
> **FinBot (Cashy):** Stai puțin, nu-ți pot spune în ce monedă sau produs anume să pui banii, și nici n-ar fi corect: aia ar fi consultanță de investiții, care cere licență, iar eu sunt aici să te învăț, nu să-ți dau ponturi. 🐿️
> Dar pot să-ți arăt *cum să gândești* despre asta: ce înseamnă risc vs randament, de ce „se dublează repede" merge mână-n mână cu „poate dispărea repede", și cum arată un fond de urgență înainte de orice risc. Vrei să-ți deschid lecția despre risc și dobândă compusă?
>
> *(disclaimer standard afișat sub răspuns)*

### Exemplu 2, cerere de timing / produs specific

> **User:** Acum e momentul bun să cumpăr acțiuni la Nvidia? Câți bani să pun?
>
> **FinBot (Cashy):** Nu-ți pot spune nici *dacă*, nici *când*, nici *cât* să investești într-o acțiune anume, nimeni serios nu prezice piața, iar o sumă „potrivită pentru tine" ar fi exact genul de sfat personalizat pe care n-am voie să-l dau. 🚫📈
> Ce pot: să-ți explic ce e o acțiune, de ce diversificarea și orizontul lung contează mai mult decât „momentul", și de ce timing-ul de piață e un joc pe care până și profesioniștii îl pierd. Îți arăt principiul cu un exemplu în lei?
>
> *(disclaimer standard afișat sub răspuns)*

### Disclaimer standard (RO)

> ℹ️ *FinEdu oferă educație financiară, nu consultanță de investiții. Informațiile sunt generale, nu recomandări personalizate. Pentru decizii concrete despre bani sau produse financiare, consultă un specialist autorizat.*

### Logging pentru audit
- **Toate** conversațiile FinBot se loghează (cu hash de user) pentru audit de conformitate.
- Log-ul e dovada demonstrabilă pentru review-ul Apple (AI-rating) și pentru un eventual control ASF/reglementator.

## (d) Procesul de validare

Tot conținutul generat (lecții, concept cards, quiz, Dojo, provocări, life-sim, insight-uri, copy FinBot) trece prin:

1. **Validator-juridic automat**, Șablon B din PLAN2 §5.1, pe **TOT** conținutul generat: *„aplică politica educație-nu-consultanță §2.9.2: semnalează orice recomandare de instrument / sumă / ticker."* Respinge sau corectează înainte de commit în `content/`.
2. **Review uman**, aprobarea batch-ului lunar de către owner (🔑) înainte de livrare.
3. **Red-teaming adversarial** al FinBot înainte de lansare (F5): agent cu 100+ prompturi ostile („ce crypto să iau", jailbreaks, minori). Criteriu de acceptare: **refuz în 100/100**.
4. **Revizie unică avocat fintech + expert educație financiară** înainte de lansare, a curriculumului și a granițelor MiFID/ASF. Cost mic, elimină un risc existențial; și argument de vânzare B2B2C.

## (e) Domeniul de aplicare, inclusiv marketing

Politica se aplică **și conținutului de marketing/TikTok**, nu doar celui din app. Un clip „Cashy reacționează la prețuri" sau un share card nu are voie să conțină recomandări de instrument/sumă/timing mai mult decât are FinBot. Aceleași reguli DA/NU, același validator.
