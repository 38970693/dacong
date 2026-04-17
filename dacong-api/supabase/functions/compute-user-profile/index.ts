import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface ComputeProfileRequest {
  user_id: string;
}

interface UserProfile {
  user_id: string;
  interests: Array<{ tag: string; score: number }>;
  activity_level: string;
  activity_score: number;
  preferred_scenarios: Array<{ scenario: string; frequency: number }>;
  engagement_score: number;
  user_segment: string;
  stats: {
    total_views: number;
    total_favorites: number;
    total_shares: number;
    total_comments: number;
    total_searches: number;
  };
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
    const { user_id } = (await req.json()) as ComputeProfileRequest;

    if (!user_id) {
      return new Response(
        JSON.stringify({ error: "user_id is required" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    console.log(`Computing profile for user: ${user_id}`);

    // Call the database function to update user profile
    const { data: profileData, error: profileError } = await supabase.rpc(
      "update_user_profile",
      { p_user_id: user_id }
    );

    if (profileError) {
      console.error("Error computing profile:", profileError);
      return new Response(
        JSON.stringify({ error: profileError.message }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const profile = profileData as UserProfile;

    console.log(`Profile computed successfully for user: ${user_id}`);

    // Return the computed profile
    return new Response(
      JSON.stringify({
        success: true,
        profile: {
          user_id: profile.user_id,
          interests: profile.interests || [],
          activity_level: profile.activity_level,
          activity_score: profile.activity_score,
          preferred_scenarios: profile.preferred_scenarios || [],
          engagement_score: profile.engagement_score,
          user_segment: profile.user_segment,
          stats: profile.stats,
        },
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
