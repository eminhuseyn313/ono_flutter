// Supabase Edge Function: generate-blueprint
// Wraps the Claude API to generate a personalised transformation blueprint.
//
// Environment variables required:
//   ANTHROPIC_API_KEY — your Claude API key
//
// Request body: { archetypeId: string, assessmentAnswers: Record<string, number> }
// Response: Blueprint JSON matching the Flutter BlueprintGateway domain model.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const ANTHROPIC_API_KEY = Deno.env.get("ANTHROPIC_API_KEY");

const ARCHETYPE_NAMES: Record<string, string> = {
  executive: "The Executive",
  athlete: "The Athlete",
  creative: "The Creative",
  builder: "The Builder",
  gentleman: "The Gentleman",
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    if (!ANTHROPIC_API_KEY) {
      throw new Error("ANTHROPIC_API_KEY is not configured");
    }

    const { archetypeId, assessmentAnswers } = await req.json();

    const archetypeName = ARCHETYPE_NAMES[archetypeId] ?? "The Aspirant";

    const prompt = `You are Ono, an AI personal transformation coach for young men aged 18-30.

Generate a personalised 90-day transformation blueprint for a user who chose the "${archetypeName}" archetype.

Their assessment answers (question index → option index): ${JSON.stringify(assessmentAnswers)}

Create a blueprint with exactly 4 lanes:
- mind (Mental growth — reading, journaling, mindfulness)
- body (Physical growth — exercise, nutrition, sleep)
- social (Social presence — conversation, networking, confidence)
- skill (Skill building — career, learning, side projects)

For each lane provide:
- A short name (e.g. "Mind", "Body")
- A one-sentence description
- 1-2 specific daily actions with title, optional subtitle, and estimated duration in minutes

Make the actions specific, actionable, and calibrated to a beginner-to-intermediate level.
The blueprint title should be inspiring and specific to the archetype (e.g. "The Executive Edge", "Peak Performance Protocol").
Include a 1-2 sentence summary of the overall plan.

Respond with ONLY valid JSON in this exact format:
{
  "archetypeId": "${archetypeId}",
  "title": "...",
  "summary": "...",
  "lanes": [
    {
      "id": "mind",
      "name": "Mind",
      "description": "...",
      "actions": [
        {
          "id": "mind_1",
          "title": "...",
          "subtitle": "...",
          "laneId": "mind",
          "durationMinutes": 15,
          "orderIndex": 0
        }
      ]
    }
  ],
  "generated_at": "${new Date().toISOString()}"
}`;

    const response = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": ANTHROPIC_API_KEY,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: "claude-sonnet-4-20250514",
        max_tokens: 2048,
        messages: [{ role: "user", content: prompt }],
      }),
    });

    if (!response.ok) {
      const error = await response.text();
      throw new Error(`Claude API error: ${response.status} — ${error}`);
    }

    const result = await response.json();
    const text = result.content[0]?.text ?? "";

    // Extract JSON from the response (Claude may wrap it in markdown)
    const jsonMatch = text.match(/\{[\s\S]*\}/);
    if (!jsonMatch) {
      throw new Error("Failed to parse blueprint JSON from Claude response");
    }

    const blueprint = JSON.parse(jsonMatch[0]);

    return new Response(JSON.stringify(blueprint), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
