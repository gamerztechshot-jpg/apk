// Configuration constants

export const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY");
export const OPENAI_API_URL = "https://api.openai.com/v1/chat/completions";

export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
