// Simple HTTP server for Docker deployment
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const PORT = parseInt(Deno.env.get("PORT") || "8000");

console.log(`🚀 Supabase Edge Functions server starting on port ${PORT}`);

serve(
  async (req: Request) => {
    const url = new URL(req.url);

    // Health check endpoint
    if (url.pathname === "/health") {
      return new Response(JSON.stringify({ status: "ok" }), {
        headers: { "Content-Type": "application/json" },
      });
    }

    // Route to appropriate function
    const functionName = url.pathname.split("/")[1];

    if (!functionName) {
      return new Response(
        JSON.stringify({ error: "Function name required" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    try {
      // Dynamic import of the function
      const functionPath = `./supabase/functions/${functionName}/index.ts`;
      const module = await import(functionPath);

      if (module.default) {
        return await module.default(req);
      }

      return new Response(
        JSON.stringify({ error: "Function not found" }),
        { status: 404, headers: { "Content-Type": "application/json" } }
      );
    } catch (error) {
      console.error(`Error loading function ${functionName}:`, error);
      return new Response(
        JSON.stringify({ error: "Internal server error" }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }
  },
  { port: PORT }
);
