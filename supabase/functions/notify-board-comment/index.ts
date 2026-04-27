// supabase/functions/notify-board-comment/index.ts
//
// Webhook: posts table → INSERT
// - Organiser posts announcement → notify all members
// - Member comments on a post → notify the organiser

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

    const posterId = record.user_id;
    const clubId = record.club_id;

    // Fetch the club
    const { data: club, error: clubErr } = await supabase
      .from("clubs")
      .select("name, organiser_id")
      .eq("id", clubId)
      .single();

    if (clubErr || !club) {
      console.error("Club fetch error:", JSON.stringify(clubErr));
      return new Response("club not found", { status: 200 });
    }

    // Fetch the poster's display name
    const { data: poster, error: posterErr } = await supabase
      .from("users")
      .select("display_name")
      .eq("id", posterId)
      .single();

    if (posterErr || !poster) {
      console.error("Poster fetch error:", JSON.stringify(posterErr));
      return new Response("poster not found", { status: 200 });
    }

    // CASE 1: Organiser posted an announcement → notify all active members
    if (record.post_type === "announcement" && posterId === club.organiser_id) {
      const { data: members, error: membersErr } = await supabase
        .from("club_members")
        .select("user_id, users(apns_token)")
        .eq("club_id", clubId)
        .eq("status", "active")
        .neq("user_id", posterId);

      if (membersErr || !members) {
        console.error("Members fetch error:", JSON.stringify(membersErr));
        return new Response("members not found", { status: 200 });
      }

      for (const member of members) {
        const token = (member.users as any)?.apns_token;
        if (token) {
          await sendPush(
            token,
            club.name,
            `New announcement from ${poster.display_name}`,
            { club_id: clubId, post_id: record.id },
          );
        }
      }

      return new Response("ok", { status: 200 });
    }

    // CASE 2: Member commented → notify the organiser
    if (record.post_type === "comment" && posterId !== club.organiser_id) {
      const { data: organiser, error: orgErr } = await supabase
        .from("users")
        .select("apns_token")
        .eq("id", club.organiser_id)
        .single();

      if (orgErr || !organiser?.apns_token) {
        console.error("Organiser fetch error:", JSON.stringify(orgErr));
        return new Response("organiser has no push token", { status: 200 });
      }

      await sendPush(
        organiser.apns_token,
        club.name,
        `${poster.display_name} commented on your announcement`,
        { club_id: clubId, post_id: record.parent_post_id },
      );

      return new Response("ok", { status: 200 });
    }

    return new Response("no action needed", { status: 200 });
  } catch (err) {
    console.error("Unexpected error:", err);
    return new Response("error", { status: 500 });
  }
});
