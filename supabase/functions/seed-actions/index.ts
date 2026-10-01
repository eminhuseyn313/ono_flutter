// Supabase Edge Function: seed-actions
// Creates daily_actions rows from a blueprint's lanes/actions for a given user.
//
// Called after blueprint generation to populate the user's daily action list.
//
// Request body:
//   { userId: string, blueprintId: string, lanes: Lane[] }
//
// Each Lane: { id: string, actions: Action[] }
// Each Action: { id: string, title: string, subtitle?: string, laneId: string, orderIndex: number }
//
// Creates one daily_actions row per action, dated today.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const { userId, blueprintId, lanes } = await req.json();

    if (!userId || !lanes || !Array.isArray(lanes)) {
      throw new Error("Missing required fields: userId, lanes");
    }

    const today = new Date().toISOString().substring(0, 10);

    // Build rows for all actions across all lanes
    const rows: Array<Record<string, unknown>> = [];
    let globalOrder = 0;

    for (const lane of lanes) {
      const actions = lane.actions ?? [];
      for (const action of actions) {
        rows.push({
          user_id: userId,
          blueprint_id: blueprintId || null,
          action_date: today,
          lane: action.laneId ?? lane.id,
          domain: action.laneId ?? lane.id,
          title: action.title,
          subtitle: action.subtitle ?? null,
          description: action.subtitle ?? null,
          action: action.title,
          order_index: action.orderIndex ?? globalOrder,
          completed: false,
        });
        globalOrder++;
      }
    }

    if (rows.length === 0) {
      return new Response(
        JSON.stringify({ seeded: 0, message: "No actions to seed" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Delete any existing actions for this user on today's date
    // (avoids duplicates on re-generation)
    await supabase
      .from("daily_actions")
      .delete()
      .eq("user_id", userId)
      .eq("action_date", today);

    // Insert new actions
    const { error } = await supabase.from("daily_actions").insert(rows);

    if (error) {
      throw new Error(`Failed to insert daily actions: ${error.message}`);
    }

    return new Response(
      JSON.stringify({ seeded: rows.length, date: today }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
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
