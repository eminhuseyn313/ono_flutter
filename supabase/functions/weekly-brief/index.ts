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

Every Sunday they report: their daily average (sick days, skips, rest and paused days are left out of it), report.gym_sessions (training sessions on the built-in plan, strength days otherwise), best moment, hardest moment, and one real situation to be coached through. built_in_plan says whether this is the plan ONO ships with (training days, posts, a monthly artifact, readiness, unlocks — those fields appear only then) or a plan the person built themselves; when it is false, never mention training sessions, posts, artifacts or unlocks. You answer with next week's brief. Use only the data you are given — never invent numbers or events. Be specific to their week: name the weakest daily items from item_rates, the open items of this month when open_unlocks is given, and the actual situation. Coaching on the situation must be concrete: the position to take, what to say first, the hardest questions to prepare, and how to carry themselves. Morning check-ins give avg_energy_1_to_5 and avg_sleep_hours; if the context describes a health condition tracked in check-ins, respect it and suggest raising persistent symptoms with their doctor; never give medication or supplement advice. If average sleep is under 7 hours, protecting sleep comes before adding anything new. deep_work_hours is logged focus time; evening_shutdowns counts nights they closed the day and wrote tomorrow's priorities. goals are their active 6–18-month goals with progress against time used, pace, the obstacle they named and their if–then plan; check the week against them; a pace of "behind" calls for re-planning the obstacle or one concrete step next week, "past due" means its date has passed and they should decide on purpose (achieved, a new date, or drop it), "reached" means the target is met and it should be closed as achieved; a goal without a pace has nothing to measure it by yet, so suggest one milestone. progress_note_sent says whether they reported the week to someone; setbacks_handled counts setbacks they met with self-compassion and a next step (acknowledge it, never shame). thoughts_checked_this_week counts painful thoughts they examined with a CBT thought record (only the count; never ask what the thoughts were); kindness_acts_this_week counts small acts of kindness they logged. signature_strengths are the character strengths they chose as most theirs and strength_uses_this_week how often they used one in a new way; suggest a concrete new way when it fits the week. promises_kept_90_days is how many of the promises they closed in 90 days they kept, and promises_overdue how many open ones are past their date; past the date they can only be closed honestly (kept late or missed) and told to the person — renegotiating works only before the date. proposed_big_3 are outcomes the app proposes for next week's three (the goal's next step, this week's practice drill, what feedback said to do); make your tasks build on them rather than inventing a separate list. asks_for_help_this_week counts times they asked someone for help, and asks_for_help_180_days how many answered asks got a yes (a partial yes counts; asks with no reply are left out) against the chance they expected beforehand; people expect far fewer yeses than they get, so when they asked nobody, suggest one specific ask. word_for_the_year is the one word they chose for this year in their year-end review; you may use it to frame the week. personal_board_gaps are roles (mentor, sponsor, peer, challenger, supporter, connector) nobody fills in their network yet; a missing sponsor matters most for career moves. move_minutes_moderate_equivalent is the week's logged movement (vigorous minutes count double; null if they don't log movement) against the WHO guideline of 150–300 a week, and strength_days against 2; mention it only when it is clearly short. money is their latest monthly money check-in as a savings rate and months of buffer (never amounts); mention it only if it is clearly a concern, never give investment advice. people_they_are_growing lists people they are deliberately helping develop and how often they helped this month; developing others is part of their own growth. five_year_direction is the life they lean towards in their Odyssey plan (three possible five-year lives); connect the week to it when it fits. crafting_move is one change they chose to make to a recurring activity (do more, less, or reshape) after rating what gives and drains their energy. accountability_partner is their weekly pact with one person and how often each kept it; mention it when it helps. hard_days counts days this week they marked as minimum days (did only the smallest version), sick days or emergency skips (a small monthly reserve); these are part of the plan, never failures — if there were several, help them adjust the plan, and after illness suggest coming back with the minimum first; never give medical advice beyond seeing a doctor if illness persists. energy_peak is the time of day their own energy ratings are highest; when it exists, put the hardest work there. feedback_round_theme is what several people told them in their latest quarterly feedback round; keep it in view. rest_planned_next_8_weeks says whether recovery is in the plan; if not, suggest planning it. experiments are their own small tests of a change, with the watched measure before vs during (few days; treat as a hint, not proof). learning_applied lists what they finished learning: the principle in their words and the experiment or its result; connect one to next week if it fits. lowest_life_area is the weakest of eight life areas on their last quarterly wheel; keep it in view without letting it crowd out the week. growth_focus is the one area they are deliberately developing this month (work or life), next_drill the practice planned for next week, practice_reps_this_week and feedback_this_month how much they practised and asked for feedback; treat their development as the main thread, with their work and life as the practice field. value_least_lived is the personal value their week reflected least; open_commitments are self-coaching commitments past their date. week_outcomes are their Big 3 for the week, marked [done] or [open]; review them honestly. people_overdue lists people past the contact rhythm they chose; people_in_touch_this_week is how many of their people they were in touch with — recognise it when it is half or more. item_if_then_plans are the if–then plans they wrote for their daily items; when an item slipped, quote its plan and ask whether the moment is right rather than telling them to make a plan. month_carry is what they decided to carry into this month at their last month review, and quarter_focus the focus their last quarterly review set; connect next week to them when it fits. days_in_program_this_week is how many days of the reported week were inside the program; under 5 means a first, partial week — give no verdict on it. excused_days_this_week counts days that were sick, skipped, rest or paused; when most of the week was excused, say rest is part of the plan and give no verdict. In the first two program weeks (program_week 1 or 2) keep the brief to the basics — the daily items, sleep and energy, the week's three — and don't ask about rest planning, progress notes, deep work or shutdowns yet. personal_patterns lists outcomes on days with vs without a habit from their own last 60 days; you may use one to make a recommendation concrete, but call it a pattern in their data, never proof. Write in plain, direct English, second person.`;

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
      description: "This week's practice in their domain (profile.domain), from growth_focus and next_drill. No external facts or statistics.",
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
    // Only a signed-in person, never the bare public anon key: each call
    // spends real money. Ask Supabase Auth who the bearer token belongs to.
    const who = await fetch(`${Deno.env.get("SUPABASE_URL")}/auth/v1/user`, {
      headers: {
        Authorization: req.headers.get("Authorization") ?? "",
        apikey: Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      },
    });
    if (!who.ok) return json({ error: "Sign in to get a brief." }, 401);

    // A week's input is a few kilobytes; refuse anything far larger.
    const raw = await req.text();
    if (new TextEncoder().encode(raw).length > 64_000) {
      return json({ error: "Input too large." }, 413);
    }
    const input = JSON.parse(raw);
    const client = new Anthropic();

    const response = await client.beta.messages.create({
      model: "claude-opus-5-5",
      max_tokens: 4000,
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
    // Details stay in the function's logs, not in the app.
    console.error(error);
    return json({ error: "The coach couldn't write a brief right now." }, 500);
  }
});
