// Supabase Edge Function: weekly-brief
// Turns Emin's Sunday report + the week's real data into next week's brief.
//
// Secret required:  supabase secrets set ANTHROPIC_API_KEY=sk-ant-...
// Deploy:           supabase functions deploy weekly-brief
//
// Request body: BriefInput.toJson() from lib/services/brief_generator.dart
// Response:     { headline, tasks[], domain_brief, coaching, adjustments[] }

import Anthropic from "npm:@anthropic-ai/sdk";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const SYSTEM = `You are the weekly coach inside ONO, the personal operating system of Emin Huseynzade — Senior Product Owner for Business ID at Bir Ecosystem (PASHA Financial Holding), Baku. Archetype: The Product Architect. Path over 18 months: Senior PO → Head of Product → CPO / Tribe Lead → global manager.

His system: a Daily 10 (manifesto, domain scan, physiological sigh, BLUF, deliberate pause, lunch read, Feynman write, no caffeine after 13:00, protein 150 g, bed 22:30); gym Mon Push / Wed Pull / Thu Legs, RA-safe (no overhead barbell, upright rows, behind-neck press or back squat; face pulls every session; Zone 2 cooldown); beta thalassemia; impostor pattern Expert + Soloist; protocols: physiological sigh, "I am excited", BLUF, six questions deep before meetings with Ali, Feynman, Evidence Archive, still body, deliberate pause; LinkedIn 2 posts/week from month 2; one artifact per month. Domain thesis: "The next interface of a super-app is an agent. Ecosystems that turn existing identity and payment trust into agent permissions will win. Business ID is Bir's answer."

Every Sunday he reports: Daily 10 average, gym sessions, best moment, hardest moment, and one real work situation. You answer with next week's brief. Use only the data you are given — never invent numbers or events. Be specific to his week: name the weakest Daily 10 items from item_rates, the open items of this month, and the actual work situation. Coaching on the work situation must be concrete: the position he should take, the BLUF he could send, the hardest questions to prepare, and how to carry himself in the room. His week also includes morning check-ins (avg_energy_1_to_5, avg_sleep_hours, shoulder_flag_mornings — mornings with shoulder pain ≥ 5/10 or stiffness ≥ 30 min, from RA). If shoulder_flag_mornings is 3 or more, keep training shoulder-sparing and suggest he mentions the log to his rheumatologist; never give medication or supplement advice. If average sleep is under 7 hours, protecting sleep comes before adding anything new. deep_work_hours is logged focus time (aim for 3+ h a week on the artifact); evening_shutdowns counts nights he closed the day and wrote tomorrow's priorities. personal_patterns lists outcomes on days with vs without a habit from his own last 60 days; you may use one to make a recommendation concrete, but call it a pattern in his data, never proof. Write in plain, direct English, second person.`;

const SCHEMA = {
  type: "object",
  properties: {
    headline: {
      type: "string",
      description: "One sentence verdict on the week and the focus for next week.",
    },
    tasks: {
      type: "array",
      items: { type: "string" },
      description: "4–6 concrete tasks for next week, each doable and checkable.",
    },
    domain_brief: {
      type: "string",
      description: "What to read/track in identity, payments and agentic commerce next week and one fact to own.",
    },
    coaching: {
      type: "string",
      description: "Coaching on the reported work situation (or the most important meeting if none).",
    },
    adjustments: {
      type: "array",
      items: { type: "string" },
      description: "0–4 changes to the plan based on this week's data.",
    },
  },
  required: ["headline", "tasks", "domain_brief", "coaching", "adjustments"],
  additionalProperties: false,
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  const json = (body: unknown, status = 200) =>
    new Response(JSON.stringify(body), {
      status,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });

  try {
    if (!Deno.env.get("ANTHROPIC_API_KEY")) {
      return json({ error: "ANTHROPIC_API_KEY is not configured" }, 500);
    }
    const input = await req.json();
    const client = new Anthropic();

    const response = await client.beta.messages.create({
      model: "claude-opus-5-5",
      max_tokens: 16000,
      betas: ["server-side-fallback-2026-07-01"],
      fallbacks: "default",
      output_config: {
        effort: "medium",
        format: { type: "json_schema", schema: SCHEMA },
      },
      system: SYSTEM,
      messages: [
        {
          role: "user",
          content:
            "Here is this week's Sunday report and data (JSON). Write next week's brief.\n\n" +
            JSON.stringify(input, null, 2),
        },
      ],
    });

    if (response.stop_reason === "refusal") {
      return json({ error: "The coach declined this request." }, 422);
    }
    const text = response.content
      .filter((b) => b.type === "text")
      .map((b) => (b as { text: string }).text)
      .join("");
    return json(JSON.parse(text));
  } catch (error) {
    if (error instanceof Anthropic.RateLimitError) {
      return json({ error: "Rate limited — try again in a minute." }, 429);
    }
    if (error instanceof Anthropic.APIError) {
      return json({ error: `Claude API error ${error.status}` }, 502);
    }
    return json({ error: String(error) }, 500);
  }
});
