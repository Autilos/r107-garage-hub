import "https://deno.land/x/xhr@0.1.0/mod.ts";
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY")!;

const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    // Verify admin authentication
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      console.log("No authorization header provided");
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Create client with user's auth to check admin status
    const supabaseAuth = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: { user }, error: userError } = await supabaseAuth.auth.getUser();
    if (userError || !user) {
      console.log("Invalid user token:", userError?.message);
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Check if user is admin
    const { data: isAdmin, error: adminError } = await supabaseAuth.rpc("is_admin");
    if (adminError || !isAdmin) {
      console.log("User is not admin:", user.email);
      return new Response(JSON.stringify({ error: "Forbidden - Admin access required" }), {
        status: 403,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    console.log("Admin access verified for:", user.email);

    // Use service role client for database operations
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // Fetch all listings that need reprocessing
    const { data: listings, error: fetchError } = await supabase
      .from("listings")
      .select("id, title, description, model_tag, variant_tag")
      .order("created_at", { ascending: false });

    if (fetchError) {
      throw new Error(`Failed to fetch listings: ${fetchError.message}`);
    }

    console.log(`Found ${listings?.length || 0} listings to process`);

    const results: { id: string; title: string; old_model: string | null; new_model: string | null; error?: string }[] = [];

    for (const listing of listings || []) {
      try {
        const prompt = `Przeanalizuj tytuł i opis ogłoszenia Mercedes-Benz i wyciągnij model pojazdu.

TYTUŁ: ${listing.title}
OPIS: ${listing.description || "brak"}

MODELE R107/C107 to: 280SL, 280SLC, 350SL, 350SLC, 380SL, 380SLC, 420SL, 450SL, 450SLC, 500SL, 560SL

Przykłady:
- "1978 Mercedes Benz 450 SL" → model_tag="450SL", variant_tag="R107"
- "Mercedes 560SL 1986" → model_tag="560SL", variant_tag="R107"
- "Mercedes-Benz 380 SLC 1981" → model_tag="380SLC", variant_tag="C107"
- "Mercedes SL 350" → model_tag="350SL", variant_tag="R107"
- Modele SLC (z literą C) → variant_tag="C107"
- Modele SL (bez C) → variant_tag="R107"

Zwróć JSON:
{
  "model_tag": "450SL"|"560SL"|"380SL"|"350SL"|"280SL"|"500SL"|"420SL"|"450SLC"|"380SLC"|"350SLC"|"280SLC"|"SL"|"SLC"|null,
  "variant_tag": "R107"|"C107"|null
}

Zwróć model BEZ SPACJI (np. "450SL" nie "450 SL").
Jeśli nie można ustalić modelu, zwróć null.`;

        const response = await fetch("https://api.openai.com/v1/chat/completions", {
          method: "POST",
          headers: {
            Authorization: `Bearer ${OPENAI_API_KEY}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            model: "gpt-4o-mini",
            messages: [
              { role: "system", content: "Jesteś ekspertem od Mercedes-Benz R107/C107. Odpowiadasz TYLKO w formacie JSON." },
              { role: "user", content: prompt },
            ],
            temperature: 0.1,
            max_tokens: 100,
          }),
        });

        const data = await response.json();
        const content = data.choices?.[0]?.message?.content || "";
        
        // Parse JSON from response
        const jsonMatch = content.match(/\{[\s\S]*\}/);
        if (!jsonMatch) {
          console.log(`No JSON found for listing ${listing.id}`);
          results.push({ id: listing.id, title: listing.title, old_model: listing.model_tag, new_model: null, error: "No JSON in response" });
          continue;
        }

        const parsed = JSON.parse(jsonMatch[0]);
        const newModelTag = parsed.model_tag;
        const newVariantTag = parsed.variant_tag;

        // Update the listing
        const { error: updateError } = await supabase
          .from("listings")
          .update({ 
            model_tag: newModelTag,
            variant_tag: newVariantTag
          })
          .eq("id", listing.id);

        if (updateError) {
          console.error(`Failed to update listing ${listing.id}:`, updateError);
          results.push({ id: listing.id, title: listing.title, old_model: listing.model_tag, new_model: newModelTag, error: updateError.message });
        } else {
          console.log(`Updated listing ${listing.id}: ${listing.model_tag} → ${newModelTag}`);
          results.push({ id: listing.id, title: listing.title, old_model: listing.model_tag, new_model: newModelTag });
        }

        // Small delay to avoid rate limiting
        await new Promise(resolve => setTimeout(resolve, 200));

      } catch (err) {
        console.error(`Error processing listing ${listing.id}:`, err);
        results.push({ id: listing.id, title: listing.title, old_model: listing.model_tag, new_model: null, error: String(err) });
      }
    }

    return new Response(JSON.stringify({ 
      success: true, 
      processed: results.length,
      results 
    }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });

  } catch (error: unknown) {
    console.error("Error in reprocess-listings:", error);
    const errorMessage = error instanceof Error ? error.message : String(error);
    return new Response(JSON.stringify({ error: errorMessage }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
