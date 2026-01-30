import { serve } from "https://deno.land/std@0.190.0/http/server.ts";
import { Webhook } from "https://esm.sh/standardwebhooks@1.0.0";

const RESEND_API_KEY_R107 = Deno.env.get("RESEND_API_KEY");
const RESEND_API_KEY_TOKACADEMY = Deno.env.get("RESEND_API_KEY_TOKACADEMY");
const HOOK_SECRET = Deno.env.get("SEND_EMAIL_HOOK_SECRET");

// App configurations
interface AppConfig {
  name: string;
  from: string;
  resendApiKey: string;
  brandColor: string;
  supportEmail: string;
}

const APP_CONFIGS: Record<string, AppConfig> = {
  "r107garage.pl": {
    name: "R107 Garage",
    from: "R107 Garage <biuro@r107garage.pl>",
    resendApiKey: RESEND_API_KEY_R107 || "",
    brandColor: "#e53935",
    supportEmail: "biuro@r107garage.pl",
  },
  "tokacademy.pl": {
    name: "TokAcademy",
    from: "TokAcademy <noreply@tokacademy.pl>",
    resendApiKey: RESEND_API_KEY_TOKACADEMY || "",
    brandColor: "#4CAF50",
    supportEmail: "contact@tokacademy.pl",
  },
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface AuthHookPayload {
  user: {
    id: string;
    email: string;
  };
  email_data: {
    token: string;
    token_hash: string;
    redirect_to: string;
    email_action_type: string;
    site_url: string;
  };
}

const handler = async (req: Request): Promise<Response> => {
  console.log("send-confirmation-email function called");
  
  // Handle CORS preflight requests
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  try {
    const payload = await req.text();
    const headers = Object.fromEntries(req.headers);
    
    // Verify webhook signature
    const wh = new Webhook(HOOK_SECRET!);
    let data: AuthHookPayload;
    
    try {
      data = wh.verify(payload, headers) as AuthHookPayload;
    } catch (err) {
      console.error("Webhook verification failed:", err);
      return new Response(
        JSON.stringify({ error: { http_code: 401, message: "Unauthorized" } }),
        { status: 401, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    const { user, email_data } = data;
    const { token_hash, redirect_to, email_action_type, site_url } = email_data;

    // Detect app from redirect_to URL
    let appConfig: AppConfig = APP_CONFIGS["r107garage.pl"]; // default

    for (const [domain, config] of Object.entries(APP_CONFIGS)) {
      if (redirect_to?.includes(domain)) {
        appConfig = config;
        break;
      }
    }

    console.log(`Sending ${email_action_type} email to: ${user.email} for app: ${appConfig.name}`);

    // Build confirmation URL
    const supabaseUrl = Deno.env.get("SUPABASE_URL") || site_url;
    const confirmationUrl = `${supabaseUrl}/auth/v1/verify?token=${token_hash}&type=${email_action_type}&redirect_to=${redirect_to}`;

    const isSignup = email_action_type === "signup" || email_action_type === "email";
    const isRecovery = email_action_type === "recovery";

    const subject = isSignup
      ? `Potwierdź rejestrację w ${appConfig.name}`
      : isRecovery
        ? `Reset hasła - ${appConfig.name}`
        : `${appConfig.name} - Weryfikacja email`;

    const htmlContent = isSignup
      ? `
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: #1a1a1a; color: #fff; padding: 20px; text-align: center; }
            .content { padding: 30px; background: #f9f9f9; }
            .button { display: inline-block; background: ${appConfig.brandColor}; color: #fff; padding: 12px 30px; text-decoration: none; border-radius: 4px; margin: 20px 0; }
            .footer { padding: 20px; text-align: center; color: #666; font-size: 12px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>${appConfig.name}</h1>
            </div>
            <div class="content">
              <h2>Witaj!</h2>
              <p>Dziękujemy za rejestrację w serwisie ${appConfig.name}. Aby aktywować swoje konto, kliknij poniższy przycisk:</p>
              <p style="text-align: center;">
                <a href="${confirmationUrl}" class="button">Potwierdź rejestrację</a>
              </p>
              <p>Jeśli przycisk nie działa, skopiuj i wklej ten link do przeglądarki:</p>
              <p style="word-break: break-all; color: #666;">${confirmationUrl}</p>
              <p>Jeśli nie rejestrowałeś się w naszym serwisie, zignoruj tę wiadomość.</p>
            </div>
            <div class="footer">
              <p>© ${new Date().getFullYear()} ${appConfig.name}. Wszelkie prawa zastrzeżone.</p>
              <p>${appConfig.supportEmail}</p>
            </div>
          </div>
        </body>
        </html>
      `
      : `
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: #1a1a1a; color: #fff; padding: 20px; text-align: center; }
            .content { padding: 30px; background: #f9f9f9; }
            .button { display: inline-block; background: ${appConfig.brandColor}; color: #fff; padding: 12px 30px; text-decoration: none; border-radius: 4px; margin: 20px 0; }
            .footer { padding: 20px; text-align: center; color: #666; font-size: 12px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>${appConfig.name}</h1>
            </div>
            <div class="content">
              <h2>Reset hasła</h2>
              <p>Otrzymaliśmy prośbę o reset hasła do Twojego konta. Kliknij poniższy przycisk, aby ustawić nowe hasło:</p>
              <p style="text-align: center;">
                <a href="${confirmationUrl}" class="button">Resetuj hasło</a>
              </p>
              <p>Jeśli przycisk nie działa, skopiuj i wklej ten link do przeglądarki:</p>
              <p style="word-break: break-all; color: #666;">${confirmationUrl}</p>
              <p>Jeśli nie prosiłeś o reset hasła, zignoruj tę wiadomość.</p>
            </div>
            <div class="footer">
              <p>© ${new Date().getFullYear()} ${appConfig.name}. Wszelkie prawa zastrzeżone.</p>
              <p>${appConfig.supportEmail}</p>
            </div>
          </div>
        </body>
        </html>
      `;

    // Use Resend API directly via fetch
    const emailResponse = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${appConfig.resendApiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: appConfig.from,
        to: [user.email],
        subject: subject,
        html: htmlContent,
      }),
    });

    const emailData = await emailResponse.json();

    if (!emailResponse.ok) {
      console.error("Resend API error:", emailData);
      return new Response(
        JSON.stringify({
          error: {
            http_code: emailResponse.status,
            message: emailData.message || "Failed to send email",
          },
        }),
        {
          status: emailResponse.status,
          headers: { "Content-Type": "application/json", ...corsHeaders },
        }
      );
    }

    console.log("Email sent successfully:", emailData);

    // Return empty object for success (required by Supabase Auth Hook)
    return new Response(JSON.stringify({}), {
      status: 200,
      headers: { "Content-Type": "application/json", ...corsHeaders },
    });
  } catch (error: any) {
    console.error("Error sending email:", error);
    return new Response(
      JSON.stringify({
        error: {
          http_code: 500,
          message: error.message,
        },
      }),
      {
        status: 500,
        headers: { "Content-Type": "application/json", ...corsHeaders },
      }
    );
  }
};

serve(handler);
