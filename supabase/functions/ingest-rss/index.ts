import "https://deno.land/x/xhr@0.1.0/mod.ts";
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-cron-secret",
};

interface RssItem {
  title: string;
  link: string;
  guid: string;
  description: string;
  pubDate: string;
  imageUrl: string | null;
}

interface LlmResponse {
  allow: boolean;
  reason: string;
  category: "pojazd" | "czesc";
  model_tag: string | null;
  variant_tag: string | null;
  year_from: number | null;
  year_to: number | null;
  price: number | null;
  currency: "PLN" | "EUR" | "USD" | null;
  confidence: number;
}

// [Poprzedni kod parseRss, filterWithLlm, getImageUrl - bez zmian]
${(await (async () => {
  const content = await fetch("file:///tmp/old-repo/supabase/functions/ingest-rss/index.ts").then(r => r.text());
  const startIdx = content.indexOf("function parseRss");
  const endIdx = content.indexOf("serve(async (req)");
  return content.slice(startIdx, endIdx);
})())}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const openaiApiKey = Deno.env.get("OPENAI_API_KEY");
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");

    if (!openaiApiKey) throw new Error("OPENAI_API_KEY not configured");
    if (!supabaseUrl || !supabaseServiceKey || !supabaseAnonKey) {
      throw new Error("Backend credentials not configured");
    }

    // --- AuthZ: allow CRON secret OR admin user token ---
    const CRON_SECRET = Deno.env.get("CRON_SECRET");
    const cronHeader = req.headers.get("x-cron-secret");
    const authHeader = req.headers.get("Authorization");

    // Use service role client for DB operations + role checks
    const supabaseService = createClient(supabaseUrl, supabaseServiceKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    const cronAuthed = !!(cronHeader && CRON_SECRET && cronHeader === CRON_SECRET);

    if (cronAuthed) {
      console.log("CRON request authenticated");
    } else {
      if (!authHeader?.startsWith("Bearer ")) {
        return new Response(
          JSON.stringify({ error: "Unauthorized - CRON secret or admin token required" }),
          { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      // Validate JWT and extract user id from claims
      const token = authHeader.slice("Bearer ".length);
      const supabaseAuth = createClient(supabaseUrl, supabaseAnonKey, {
        auth: { persistSession: false, autoRefreshToken: false },
      });

      const { data: claimsData, error: claimsError } = await supabaseAuth.auth.getClaims(token);
      if (claimsError || !claimsData?.claims?.sub) {
        console.log("Invalid token claims:", claimsError?.message);
        return new Response(JSON.stringify({ error: "Unauthorized" }), {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      const userId = claimsData.claims.sub;

      // Check admin role via service role (bypasses RLS safely)
      const { data: roleRow, error: roleError } = await supabaseService
        .from("user_roles")
        .select("id")
        .eq("user_id", userId)
        .eq("role", "admin")
        .maybeSingle();

      if (roleError || !roleRow) {
        console.log("User is not admin:", userId);
        return new Response(JSON.stringify({ error: "Forbidden - Admin access required" }), {
          status: 403,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      console.log("Admin access verified:", userId);
    }

    // --- Main logic ---

    // Get enabled RSS sources
    const { data: rssSources, error: rssError } = await supabaseService
      .from("rss_sources")
      .select("*")
      .eq("enabled", true);

    if (rssError) {
      throw new Error(`Failed to fetch RSS sources: ${rssError.message}`);
    }

    console.log(`Found ${rssSources?.length || 0} enabled RSS sources`);

    // Backwards-compat alias (rest of the function expects `supabase`)
    const supabase = supabaseService;

    const results = {
      processed: 0,
      allowed: 0,
      rejected: 0,
      errors: 0,
      duplicates: 0,
    };

    for (const source of rssSources || []) {
      // Support both url (production) and feed_url (local dev)
      const feedUrl = (source as any).url || (source as any).feed_url;

      console.log(`Processing RSS source: ${source.name} (${feedUrl})`);

      try {
        if (!feedUrl) {
          console.error(`Missing feed URL for source: ${source.name}`);
          results.errors++;
          continue;
        }

        console.log(`Fetching RSS feed: ${feedUrl}`);
        const feedResponse = await fetch(feedUrl, {
          headers: {
            "User-Agent": "Mozilla/5.0 (compatible; R107GarageBot/1.0)",
          },
        });
        console.log(`Feed response status: ${feedResponse.status}`);

        if (!feedResponse.ok) {
          const errorText = await feedResponse.text();
          console.error(`Failed to fetch feed ${source.name}: ${feedResponse.status} - ${errorText.substring(0, 200)}`);
          results.errors++;
          continue;
        }

        const feedXml = await feedResponse.text();
        console.log(`Received ${feedXml.length} bytes from ${source.name}`);
        const items = parseRss(feedXml);
        console.log(`Parsed ${items.length} items from ${source.name}`);

        for (const item of items) {
          results.processed++;

          // Check for duplicates
          const { data: existing } = await supabase
            .from("listings")
            .select("id")
            .eq("rss_source_id", source.id)
            .eq("rss_guid", item.guid)
            .maybeSingle();

          if (existing) {
            console.log(`Duplicate found: ${item.guid}`);
            results.duplicates++;
            continue;
          }

          // Also check by URL
          const { data: existingUrl } = await supabase
            .from("listings")
            .select("id")
            .eq("url", item.link)
            .maybeSingle();

          if (existingUrl) {
            console.log(`Duplicate URL found: ${item.link}`);
            results.duplicates++;
            continue;
          }

          // Filter with LLM
          const llmResult = await filterWithLlm(item, openaiApiKey);

          if (!llmResult) {
            console.log(`LLM filter failed for: ${item.title}`);
            results.errors++;
            continue;
          }

          if (!llmResult.allow) {
            console.log(`Rejected: ${item.title} - ${llmResult.reason}`);
            results.rejected++;
            continue;
          }

          console.log(`Allowed: ${item.title} - ${llmResult.reason} | Price: ${llmResult.price} ${llmResult.currency}`);
          results.allowed++;

          // Get image URL
          const imageUrl = await getImageUrl(item);

          // Parse publication date
          let publishedAt: string | null = null;
          if (item.pubDate) {
            try {
              const parsed = new Date(item.pubDate);
              if (!isNaN(parsed.getTime())) {
                publishedAt = parsed.toISOString();
              }
            } catch {
              console.log(`Could not parse date: ${item.pubDate}`);
            }
          }

          // Determine currency - use LLM result or default based on country
          const finalCurrency = llmResult.currency || (source.country_default === 'US' ? 'USD' : source.country_default === 'PL' ? 'PLN' : 'EUR');

          // Insert listing with original currency
          const { error: insertError } = await supabase.from("listings").insert({
            source_type: "rss",
            status: "approved", // Auto-approve RSS listings
            title: item.title,
            description: item.description?.replace(/<[^>]*>/g, "").substring(0, 2000) || null,
            url: item.link,
            image_url: imageUrl,
            country: (source as any).country_default || (source as any).country || 'US',
            category: llmResult.category,
            rss_source_id: source.id,
            rss_guid: item.guid,
            llm_ok: true,
            llm_reason: llmResult.reason,
            model_tag: llmResult.model_tag,
            variant_tag: llmResult.variant_tag,
            year_from: llmResult.year_from,
            year_to: llmResult.year_to,
            price: llmResult.price,
            currency: finalCurrency,
            published_at: publishedAt,
          });

          if (insertError) {
            console.error(`Insert error: ${insertError.message}`);
            results.errors++;
          }
        }
      } catch (sourceError) {
        console.error(`Error processing source ${source.name}:`, sourceError);
        results.errors++;
      }
    }

    console.log("Ingest completed:", results);

    return new Response(JSON.stringify({ success: true, results }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("Ingest error:", error);
    const errorMessage = error instanceof Error ? error.message : "Unknown error";
    return new Response(
      JSON.stringify({ success: false, error: errorMessage }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});