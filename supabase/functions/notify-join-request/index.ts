// supabase/functions/notify-join-request/index.ts

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { sendPush } from "../_shared/apns.ts";

serve(async (req) => {
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  try {
    const payload = await req.json();
    const record = payload.record;

    console.log("Received record:", JSON.stringify(record));

    // Only handle pending requests
    if (record.status !== "pending") {
      console.log("Skipping, status is:", record.status);
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
      console.error(
        "Club fetch error:",
        JSON.stringify(clubErr),
        "clubId:",
        clubId,
      );
      return new Response("club not found", { status: 200 });
    }

    // Fetch the requesting user's display name
    const { data: requestingUser, error: userErr } = await supabase
      .from("users")
      .select("display_name")
      .eq("id", requestingUserId)
      .single();

    if (userErr || !requestingUser) {
      console.error(
        "User fetch error:",
        JSON.stringify(userErr),
        "userId:",
        requestingUserId,
      );
      return new Response("user not found", { status: 200 });
    }

    // Fetch the organiser's APNS token
    const { data: organiser, error: orgErr } = await supabase
      .from("users")
      .select("apns_token")
      .eq("id", club.organiser_id)
      .single();

    if (orgErr || !organiser?.apns_token) {
      console.error(
        "Organiser fetch error:",
        JSON.stringify(orgErr),
        "organiserId:",
        club.organiser_id,
        "token:",
        organiser?.apns_token,
      );
      return new Response("organiser has no push token", { status: 200 });
    }

    console.log("Sending push to organiser:", club.organiser_id);

    await sendPush(
      organiser.apns_token,
      "New Join Request",
      `${requestingUser.display_name} wants to join ${club.name}`,
      { club_id: clubId },
    );

    console.log("Push sent successfully");
    return new Response("ok", { status: 200 });
  } catch (err) {
    console.error("Unexpected error:", err);
    return new Response("error", { status: 500 });
  }
});
