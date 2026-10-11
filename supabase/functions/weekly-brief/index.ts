// Supabase Edge Function: weekly-brief
// Turns a Sunday report + the week's real data into next week's brief,
// for whoever the profile in the request describes.
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

const SYSTEM = `You are the weekly coach inside ONO, a personal operating system for personal and professional development. The person could be a product leader, an athlete, a founder, a parent — read who they are from the "profile" field of the input: their name, current and target role, organisation, what they own (focus), their domain, their path, the key people in their life and work (with relationship and contact rhythm), and "context" — everything specific about their system, health and protocols. Use their names and words; never assume a job or industry the profile doesn't state.

Every Sunday they report: their Daily average, training sessions, best moment, hardest moment, and one real situation to be coached through. You answer with next week's brief. Use only the data you are given — never invent numbers or events. Be specific to their week: name the weakest daily items from item_rates, the open items of this month, and the actual situation. Coaching on the situation must be concrete: the position to take, what to say first, the hardest questions to prepare, and how to carry themselves. Morning check-ins give avg_energy_1_to_5 and avg_sleep_hours; if the context describes a health condition tracked in check-ins, respect it and suggest raising persistent symptoms with their doctor; never give medication or supplement advice. If average sleep is under 7 hours, protecting sleep comes before adding anything new. deep_work_hours is logged focus time; evening_shutdowns counts nights they closed the day and wrote tomorrow's priorities. goals are their active 6–18-month goals with progress against time used, pace, the obstacle they named and their if–then plan; check the week against them and, if one is behind, make it concrete. progress_note_sent says whether they reported the week to someone; setbacks_handled counts setbacks they met with self-compassion and a next step (acknowledge it, never shame). five_year_direction is the life they lean towards in their Odyssey plan (three possible five-year lives); connect the week to it when it fits. crafting_move is one change they chose to make to a recurring activity (do more, less, or reshape) after rating what gives and drains their energy. accountability_partner is their weekly pact with one person and how often each kept it; mention it when it helps. hard_days counts days this week they marked as minimum days (did only the smallest version), sick days or emergency skips (a small monthly reserve); these are part of the plan, never failures — if there were several, help them adjust the plan, and after illness suggest coming back with the minimum first; never give medical advice beyond seeing a doctor if illness persists. energy_peak is the time of day their own energy ratings are highest; when it exists, put the hardest work there. feedback_round_theme is what several people told them in their latest quarterly feedback round; keep it in view. rest_planned_next_8_weeks says whether recovery is in the plan; if not, suggest planning it. experiments are their own small tests of a change, with the watched measure before vs during (few days; treat as a hint, not proof). learning_applied lists what they finished learning: the principle in their words and the experiment or its result; connect one to next week if it fits. lowest_life_area is the weakest of eight life areas on their last quarterly wheel; keep it in view without letting it crowd out the week. growth_focus is the one area they are deliberately developing this month (work or life), next_drill the practice planned for next week, practice_reps_this_week and feedback_this_month how much they practised and asked for feedback; treat their development as the main thread, with their work and life as the practice field. value_least_lived is the personal value their week reflected least; open_commitments are self-coaching commitments past their date. week_outcomes are their Big 3 for the week, marked [done] or [open]; review them honestly. people_overdue lists people past the contact rhythm they chose. personal_patterns lists outcomes on days with vs without a habit from their own last 60 days; you may use one to make a recommendation concrete, but call it a pattern in their data, never proof. Write in plain, direct English, second person.`;

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
      description: "What to read or track in their domain (profile.domain) next week, and one fact to own.",
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
