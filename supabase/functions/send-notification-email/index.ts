import { serve } from "https://deno.land/std@0.190.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const resend_api_key = Deno.env.get("RESEND_API_KEY");
const supabase_url = Deno.env.get("SUPABASE_URL");
const supabase_service_role_key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface NotificationRequest {
  type: "new_listing" | "new_comment" | "listing_approved";
  listing_id?: string;
  listingId?: string;
  repair_id?: string;
  comment_id?: string;
}

const handler = async (req: Request): Promise<Response> => {
  console.log("send-notification-email function called");

  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    if (!resend_api_key) {
      throw new Error("RESEND_API_KEY is not configured");
    }

    if (!supabase_url || !supabase_service_role_key) {
      throw new Error("Supabase credentials are not configured");
    }

    const supabase = createClient(supabase_url, supabase_service_role_key);
    const { type, listing_id, listingId, repair_id, comment_id }: NotificationRequest = await req.json();

    console.log(`Processing notification: type=${type}, listing_id=${listing_id}, repair_id=${repair_id}`);

    if (type === "new_listing" && listing_id) {
      // Get the listing details
      const { data: listing, error: listingError } = await supabase
        .from("listings")
        .select("*")
        .eq("id", listing_id)
        .single();

      if (listingError || !listing) {
        console.error("Listing not found:", listingError);
        throw new Error("Listing not found");
      }

      console.log(`Listing found: ${listing.title}, category: ${listing.category}`);

      // Get all users subscribed to this category
      const { data: subscriptions, error: subError } = await supabase
        .from("category_subscriptions")
        .select("user_id")
        .eq("category", listing.category);

      if (subError) {
        console.error("Error fetching subscriptions:", subError);
        throw new Error("Error fetching subscriptions");
      }

      console.log(`Found ${subscriptions?.length || 0} subscriptions for category ${listing.category}`);

      if (!subscriptions || subscriptions.length === 0) {
        return new Response(JSON.stringify({ message: "No subscribers for this category" }), {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      // Get user emails and notification preferences
      const userIds = subscriptions.map((s) => s.user_id);
      
      const { data: profiles, error: profilesError } = await supabase
        .from("profiles")
        .select("id, email, display_name")
        .in("id", userIds);

      if (profilesError) {
        console.error("Error fetching profiles:", profilesError);
        throw new Error("Error fetching profiles");
      }

      const { data: settings, error: settingsError } = await supabase
        .from("notification_settings")
        .select("user_id, email_new_listings")
        .in("user_id", userIds)
        .eq("email_new_listings", true);

      if (settingsError) {
        console.error("Error fetching notification settings:", settingsError);
      }

      const enabledUserIds = settings?.map((s) => s.user_id) || userIds;
      const recipientProfiles = profiles?.filter((p) => enabledUserIds.includes(p.id)) || [];

      console.log(`Sending to ${recipientProfiles.length} recipients`);

      // Send emails to each subscriber
      let sentCount = 0;
      for (const profile of recipientProfiles) {
        // Don't send to the listing owner
        if (profile.id === listing.user_id) continue;

        const categoryName = listing.category === "pojazd" ? "Pojazdy" : "Części";
        const priceText = listing.price ? `${listing.price} ${listing.currency || "EUR"}` : "Cena do uzgodnienia";

        const emailHtml = `
          <!DOCTYPE html>
          <html>
          <head>
            <meta charset="utf-8">
            <style>
              body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
              .container { max-width: 600px; margin: 0 auto; padding: 20px; }
              .header { background: #1a1a2e; color: #fbbf24; padding: 20px; text-align: center; }
              .content { padding: 20px; background: #f9f9f9; }
              .listing-card { background: white; padding: 15px; border-radius: 8px; margin: 15px 0; }
              .price { font-size: 24px; color: #16a34a; font-weight: bold; }
              .button { display: inline-block; background: #fbbf24; color: #1a1a2e; padding: 12px 24px; text-decoration: none; border-radius: 6px; font-weight: bold; }
              .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
            </style>
          </head>
          <body>
            <div class="container">
              <div class="header">
                <h1>🚗 R107 Garage</h1>
              </div>
              <div class="content">
                <p>Cześć ${profile.display_name || ""}!</p>
                <p>Nowe ogłoszenie w kategorii <strong>${categoryName}</strong>:</p>
                <div class="listing-card">
                  <h2>${listing.title}</h2>
                  <p class="price">${priceText}</p>
                  ${listing.description ? `<p>${listing.description.substring(0, 200)}${listing.description.length > 200 ? "..." : ""}</p>` : ""}
                </div>
                <p style="text-align: center;">
                  <a href="https://r107garage.pl/ogloszenia" class="button">Zobacz ogłoszenie</a>
                </p>
              </div>
              <div class="footer">
                <p>Otrzymujesz ten email, ponieważ subskrybujesz kategorię ${categoryName} na R107 Garage.</p>
                <p>Aby zrezygnować z powiadomień, zmień ustawienia w swoim profilu.</p>
              </div>
            </div>
          </body>
          </html>
        `;

        try {
          const res = await fetch("https://api.resend.com/emails", {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
              Authorization: `Bearer ${resend_api_key}`,
            },
            body: JSON.stringify({
              from: "R107 Garage <biuro@r107garage.pl>",
              to: [profile.email],
              subject: `Nowe ogłoszenie: ${listing.title}`,
              html: emailHtml,
            }),
          });

          if (res.ok) {
            sentCount++;
            console.log(`Email sent to ${profile.email}`);
          } else {
            const errorText = await res.text();
            console.error(`Failed to send email to ${profile.email}:`, errorText);
          }
        } catch (emailError) {
          console.error(`Error sending email to ${profile.email}:`, emailError);
        }
      }

      return new Response(JSON.stringify({ message: `Sent ${sentCount} notification emails` }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (type === "new_comment" && repair_id && comment_id) {
      // Get the comment details
      const { data: comment, error: commentError } = await supabase
        .from("comments")
        .select("*, profiles:user_id(display_name, email)")
        .eq("id", comment_id)
        .single();

      if (commentError || !comment) {
        console.error("Comment not found:", commentError);
        throw new Error("Comment not found");
      }

      // Get the repair details
      const { data: repair, error: repairError } = await supabase
        .from("repairs")
        .select("*")
        .eq("id", repair_id)
        .single();

      if (repairError || !repair) {
        console.error("Repair not found:", repairError);
        throw new Error("Repair not found");
      }

      console.log(`New comment on repair: ${repair.title}`);

      // Get all users subscribed to this repair
      const { data: subscriptions, error: subError } = await supabase
        .from("repair_subscriptions")
        .select("user_id")
        .eq("repair_id", repair_id);

      if (subError) {
        console.error("Error fetching repair subscriptions:", subError);
        throw new Error("Error fetching repair subscriptions");
      }

      if (!subscriptions || subscriptions.length === 0) {
        return new Response(JSON.stringify({ message: "No subscribers for this repair" }), {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      // Get user emails and notification preferences
      const userIds = subscriptions.map((s) => s.user_id);
      
      const { data: profiles, error: profilesError } = await supabase
        .from("profiles")
        .select("id, email, display_name")
        .in("id", userIds);

      if (profilesError) {
        console.error("Error fetching profiles:", profilesError);
        throw new Error("Error fetching profiles");
      }

      const { data: settings } = await supabase
        .from("notification_settings")
        .select("user_id, email_new_comments")
        .in("user_id", userIds)
        .eq("email_new_comments", true);

      const enabledUserIds = settings?.map((s) => s.user_id) || userIds;
      const recipientProfiles = profiles?.filter((p) => enabledUserIds.includes(p.id)) || [];

      console.log(`Sending comment notifications to ${recipientProfiles.length} recipients`);

      let sentCount = 0;
      for (const profile of recipientProfiles) {
        // Don't send to the comment author
        if (profile.id === comment.user_id) continue;

        const authorName = (comment.profiles as any)?.display_name || "Użytkownik";

        const emailHtml = `
          <!DOCTYPE html>
          <html>
          <head>
            <meta charset="utf-8">
            <style>
              body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
              .container { max-width: 600px; margin: 0 auto; padding: 20px; }
              .header { background: #1a1a2e; color: #fbbf24; padding: 20px; text-align: center; }
              .content { padding: 20px; background: #f9f9f9; }
              .comment-card { background: white; padding: 15px; border-radius: 8px; margin: 15px 0; border-left: 4px solid #fbbf24; }
              .author { font-weight: bold; color: #1a1a2e; }
              .button { display: inline-block; background: #fbbf24; color: #1a1a2e; padding: 12px 24px; text-decoration: none; border-radius: 6px; font-weight: bold; }
              .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
            </style>
          </head>
          <body>
            <div class="container">
              <div class="header">
                <h1>🔧 R107 Garage</h1>
              </div>
              <div class="content">
                <p>Cześć ${profile.display_name || ""}!</p>
                <p>Nowy komentarz w artykule <strong>"${repair.title}"</strong>:</p>
                <div class="comment-card">
                  <p class="author">${authorName} napisał(a):</p>
                  <p>${comment.content}</p>
                </div>
                <p style="text-align: center;">
                  <a href="https://r107garage.pl/naprawy/${repair.slug}" class="button">Zobacz dyskusję</a>
                </p>
              </div>
              <div class="footer">
                <p>Otrzymujesz ten email, ponieważ obserwujesz ten artykuł.</p>
                <p>Aby zrezygnować z powiadomień, zmień ustawienia w swoim profilu.</p>
              </div>
            </div>
          </body>
          </html>
        `;

        try {
          const res = await fetch("https://api.resend.com/emails", {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
              Authorization: `Bearer ${resend_api_key}`,
            },
            body: JSON.stringify({
              from: "R107 Garage <biuro@r107garage.pl>",
              to: [profile.email],
              subject: `Nowy komentarz: ${repair.title}`,
              html: emailHtml,
            }),
          });

          if (res.ok) {
            sentCount++;
            console.log(`Comment notification sent to ${profile.email}`);
          } else {
            const errorText = await res.text();
            console.error(`Failed to send email to ${profile.email}:`, errorText);
          }
        } catch (emailError) {
          console.error(`Error sending email to ${profile.email}:`, emailError);
        }
      }

      return new Response(JSON.stringify({ message: `Sent ${sentCount} comment notification emails` }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Handle listing approved notification
    if (type === "listing_approved") {
      const lid = listing_id || listingId;
      if (!lid) {
        return new Response(JSON.stringify({ error: "Missing listingId" }), {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      const { data: listing, error: listingError } = await supabase
        .from("listings")
        .select("*, profiles:user_id(email, display_name)")
        .eq("id", lid)
        .single();

      if (listingError || !listing) {
        console.error("Listing not found:", listingError);
        throw new Error("Listing not found");
      }

      const profile = listing.profiles as any;
      if (!profile?.email) {
        return new Response(JSON.stringify({ message: "No email for listing owner" }), {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      const priceText = listing.price ? `${listing.price} ${listing.currency || "PLN"}` : "Cena do uzgodnienia";
      const listingUrl = `https://r107garage.pl/ogloszenia`;

      const emailHtml = `
        <!DOCTYPE html>
        <html>
        <head><meta charset="utf-8"></head>
        <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
          <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
            <div style="background: #1a1a2e; color: #fbbf24; padding: 20px; text-align: center;">
              <h1>🚗 R107 Garage</h1>
            </div>
            <div style="padding: 20px; background: #f9f9f9;">
              <p>Cześć ${profile.display_name || ""}!</p>
              <p>Twoje ogłoszenie zostało <strong style="color: #16a34a;">zatwierdzone</strong> i jest teraz widoczne publicznie:</p>
              <div style="background: white; padding: 15px; border-radius: 8px; margin: 15px 0;">
                <h2>${listing.title}</h2>
                <p style="font-size: 24px; color: #16a34a; font-weight: bold;">${priceText}</p>
              </div>
              <p style="text-align: center;">
                <a href="${listingUrl}" style="display: inline-block; background: #fbbf24; color: #1a1a2e; padding: 12px 24px; text-decoration: none; border-radius: 6px; font-weight: bold;">Zobacz ogłoszenie</a>
              </p>
            </div>
          </div>
        </body>
        </html>
      `;

      const res = await fetch("https://api.resend.com/emails", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${resend_api_key}`,
        },
        body: JSON.stringify({
          from: "R107 Garage <biuro@r107garage.pl>",
          to: [profile.email],
          subject: `Ogłoszenie zatwierdzone: ${listing.title}`,
          html: emailHtml,
        }),
      });

      if (res.ok) {
        console.log(`Approval email sent to ${profile.email}`);
        return new Response(JSON.stringify({ message: "Approval email sent" }), {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      } else {
        const errorText = await res.text();
        console.error("Failed to send approval email:", errorText);
        throw new Error("Failed to send email");
      }
    }

    return new Response(JSON.stringify({ error: "Invalid notification type or missing parameters" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });

  } catch (error: any) {
    console.error("Error in send-notification-email:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
};

serve(handler);
