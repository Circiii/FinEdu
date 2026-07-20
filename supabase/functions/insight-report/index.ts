// Raportul săptămânal al lui Cashy: narativul personalizat.
//
// Metoda pentru insight-uri care sună profesionist:
// FAPTELE se calculează local, determinist (motorul de insights + money intel
// de pe telefon, auditabile și exacte). Aici urcă DOAR agregate derivate,
// niciodată tranzacții brute (GDPR/AADC: minimizare la sursă), iar modelul
// transformă faptele într-un narativ cald, personalizat, în vocea lui Cashy.
// Modelul NU calculează nimic: primește cifrele gata făcute și are voie doar
// să le POVESTEASCĂ. Orice cifră din output care nu există în input = defect.
//
// Deploy: supabase functions deploy insight-report

const GEMINI_URL =
  "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent";

const SYSTEM_PROMPT = `Ești Cashy, veverița dintr-o aplicație românească de educație
financiară pentru adolescenți (14-25, tratează utilizatorul ca pe un minor).
Primești un JSON cu agregate DERIVATE despre săptămâna lui financiară.

Scrii „Raportul săptămânal al lui Cashy": 3-4 secțiuni scurte, calde, personale.

REGULI ABSOLUTE:
1. Folosești DOAR cifrele din JSON-ul primit. Nu inventezi, nu recalculezi, nu
   estimezi nimic. Dacă o cifră lipsește, nu o menționezi.
2. Educație, nu consultanță: zero recomandări de produse/investiții.
3. Ton: descrie datele, nu judeca persoana. Interzise: „prea mult", „iar ai",
   „trebuie". Corectivele = 1 observație + 1 acțiune mică. Lauzi comportamentul.
4. 2-3 propoziții per secțiune, emoji potrivit per secțiune.
Răspunzi DOAR în JSON cu schema dată.`;

const RESPONSE_SCHEMA = {
  type: "OBJECT",
  properties: {
    sections: {
      type: "ARRAY",
      items: {
        type: "OBJECT",
        properties: {
          emoji: { type: "STRING" },
          title: { type: "STRING" },
          body: { type: "STRING" },
        },
        required: ["emoji", "title", "body"],
      },
    },
  },
  required: ["sections"],
};

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });

  try {
    // aggregates: DOAR derivate. Exemplu de contract (clientul îl garantează):
    // { weekSpent, prevWeekSpent, topCategory, topCategoryLei, savedThisWeek,
    //   goalName, goalPct, streak, lessonsDone, safeToSpend, perDay }
    const { aggregates } = await req.json();
    if (!aggregates || typeof aggregates !== "object") {
      return json({ error: "aggregates lipsă" }, 400);
    }
    // Refuzăm defensiv orice ce seamănă a date brute (listă de tranzacții).
    if (Array.isArray(aggregates) || "transactions" in aggregates) {
      return json({ error: "doar agregate derivate, nu date brute" }, 400);
    }

    const key = Deno.env.get("GEMINI_API_KEY");
    if (!key) return json({ error: "GEMINI_API_KEY lipsește" }, 500);

    const res = await fetch(`${GEMINI_URL}?key=${key}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        system_instruction: { parts: [{ text: SYSTEM_PROMPT }] },
        contents: [
          {
            role: "user",
            parts: [{ text: JSON.stringify(aggregates).slice(0, 4000) }],
          },
        ],
        generationConfig: {
          responseMimeType: "application/json",
          responseSchema: RESPONSE_SCHEMA,
          maxOutputTokens: 600,
          temperature: 0.8,
        },
      }),
    });
    if (!res.ok) return json({ error: `gemini ${res.status}` }, 502);

    const data = await res.json();
    const raw = data?.candidates?.[0]?.content?.parts?.[0]?.text ?? "{}";
    let out;
    try {
      out = JSON.parse(raw);
    } catch {
      out = { sections: [] };
    }
    return json(out, 200);
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});

function json(body: unknown, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS, "Content-Type": "application/json" },
  });
}
