// supabase/functions/notify-join-request/index.ts

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

serve(async (req) => {
  try {
    const payload = await req.json();
    const record = payload.record;

    // Only handle pending requests
    if (record.status !== "pending") {
      return new Response("not pending", { status: 200 });
    }

    const clubId = record.club_id;
    const requestingUserId = record.user_id;

    // Fetch the club to get organiser_id and name
    const { data: club, error: clubErr } = await supabase
      .from("clubs")
      .select("name, organiser_id")
      .eq("id", clubId)
      .single();

    if (clubErr || !club) {
      return new Response("club not found", { status: 200 });
    }

    // Fetch the requesting user's display name
    const { data: requestingUser, error: userErr } = await supabase
      .from("users")
      .select("display_name")
      .eq("id", requestingUserId)
      .single();

    if (userErr || !requestingUser) {
      return new Response("user not found", { status: 200 });
    }

    // Fetch the organiser's APNS token
    const { data: organiser, error: orgErr } = await supabase
      .from("users")
      .select("apns_token")
      .eq("id", club.organiser_id)
      .single();

    if (orgErr || !organiser?.apns_token) {
      return new Response("organiser has no push token", { status: 200 });
    }

    // Send APNs push notification
    const apnsToken = organiser.apns_token;
    const bundleId = Deno.env.get("APNS_BUNDLE_ID")!;
    const apnsKey = Deno.env.get("APNS_PRIVATE_KEY")!; // p8 key contents
    const apnsKeyId = Deno.env.get("APNS_KEY_ID")!;
    const apnsTeamId = Deno.env.get("APNS_TEAM_ID")!;
    const apnsEnv = Deno.env.get("APNS_ENV") ?? "production"; // "sandbox" for dev

    const apnsHost =
      apnsEnv === "sandbox"
        ? "api.sandbox.push.apple.com"
        : "api.push.apple.com";

    // Build JWT for APNs auth
    const jwtHeader = btoa(JSON.stringify({ alg: "ES256", kid: apnsKeyId }));
    const now = Math.floor(Date.now() / 1000);
    const jwtPayload = btoa(JSON.stringify({ iss: apnsTeamId, iat: now }));

    // Import the ES256 private key and sign
    const keyData = apnsKey
      .replace("-----BEGIN PRIVATE KEY-----", "")
      .replace("-----END PRIVATE KEY-----", "")
      .replace(/\s/g, "");

    const cryptoKey = await crypto.subtle.importKey(
      "pkcs8",
      Uint8Array.from(atob(keyData), (c) => c.charCodeAt(0)),
      { name: "ECDSA", namedCurve: "P-256" },
      false,
      ["sign"],
    );

    const signingInput = `${jwtHeader}.${jwtPayload}`;
    const signature = await crypto.subtle.sign(
      { name: "ECDSA", hash: "SHA-256" },
      cryptoKey,
      new TextEncoder().encode(signingInput),
    );

    const jwt = `${signingInput}.${btoa(String.fromCharCode(...new Uint8Array(signature)))}`;

    const notification = {
      aps: {
        alert: {
          title: "New Join Request",
          body: `${requestingUser.display_name} wants to join ${club.name}`,
        },
        sound: "default",
        badge: 1,
      },
      club_id: clubId,
    };

    const apnsResp = await fetch(`https://${apnsHost}/3/device/${apnsToken}`, {
      method: "POST",
      headers: {
        "content-type": "application/json",
        authorization: `bearer ${jwt}`,
        "apns-topic": bundleId,
        "apns-push-type": "alert",
        "apns-priority": "10",
      },
      body: JSON.stringify(notification),
    });

    if (!apnsResp.ok) {
      const errBody = await apnsResp.text();
      console.error("APNs error:", apnsResp.status, errBody);
      return new Response("apns error", { status: 200 });
    }

    return new Response("ok", { status: 200 });
  } catch (err) {
    console.error(err);
    return new Response("error", { status: 500 });
  }
});
