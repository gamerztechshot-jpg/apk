// Main Edge Function Handler

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { corsHeaders, OPENAI_API_KEY } from "./config.ts";
import type { RequestBody } from "./types.ts";
import { callOpenAI } from "./ai_service.ts";

// =====================
// MAIN SERVER HANDLER
// =====================

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    console.log("🔵 [Main] Request received");

    // Validate OpenAI API key
    if (!OPENAI_API_KEY) {
      console.error("❌ [Main] OpenAI API key not configured");
      return new Response(
        JSON.stringify({ error: "OpenAI API key not configured" }),
        { status: 500, headers: corsHeaders }
      );
    }

    // Parse request body
    const body: RequestBody = await req.json();
    console.log("🔵 [Main] Request body:", JSON.stringify(body));

    // Validate input
    if (!body.text || typeof body.text !== "string") {
      return new Response(
        JSON.stringify({ error: "Text is required" }),
        { status: 400, headers: corsHeaders }
      );
    }

    if (body.text.length > 300) {
      return new Response(
        JSON.stringify({ error: "Text too long" }),
        { status: 400, headers: corsHeaders }
      );
    }

    const language: "hi" | "en" = body.language ?? "hi";

    // Call OpenAI API
    const reply = await callOpenAI(body.text, language, body.chatHistory);

    const responseBody = { reply, mantra: reply };
    console.log("✅ [Main] Final response:", JSON.stringify(responseBody));

    return new Response(JSON.stringify(responseBody), {
      status: 200,
      headers: {
        "Content-Type": "application/json",
        ...corsHeaders,
      },
    });
  } catch (error: any) {
    console.error("Error:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error", details: error.message }),
      { status: 500, headers: corsHeaders }
    );
  }
});
