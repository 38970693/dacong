import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface BatchUpdateRequest {
  limit?: number;
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Initialize Supabase client
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Parse request body
    const body = await req.json().catch(() => ({})) as BatchUpdateRequest;
    const limit = body.limit || 100;

    console.log(`Starting batch update for up to ${limit} users`);

    // Call the database function to batch update user profiles
    const { data: results, error: batchError } = await supabase.rpc(
      "batch_update_user_profiles",
      { p_limit: limit }
    );

    if (batchError) {
      console.error("Error in batch update:", batchError);
      return new Response(
        JSON.stringify({ error: batchError.message }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Count successes and failures
    const successCount = results?.filter((r: any) => r.success).length || 0;
    const failureCount = results?.filter((r: any) => !r.success).length || 0;
    const failures = results?.filter((r: any) => !r.success) || [];

    console.log(`Batch update completed: ${successCount} succeeded, ${failureCount} failed`);

    // Return the results
    return new Response(
      JSON.stringify({
        success: true,
        summary: {
          total: results?.length || 0,
          succeeded: successCount,
          failed: failureCount,
        },
        failures: failures.map((f: any) => ({
          user_id: f.user_id,
          error: f.error,
        })),
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("Unexpected error:", error);
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
