// supabase/functions/notify-vote-opened/index.ts
//
// Webhook: vote_sessions table → INSERT
// Notifies all active club members that voting is open.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { sendPush } from "../_shared/apns.ts";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

serve(async (req) => {
  try {
    const payload = await req.json();
    const session = payload.record;

    const clubId = session.club_id;
    const sessionId = session.id;

    // Fetch club name and organiser
    const { data: club } = await supabase
      .from("clubs")
      .select("name, organiser_id")
      .eq("id", clubId)
      .single();

    if (!club) return new Response("club not found", { status: 200 });

    // Fetch all active members except the organiser (who opened the vote)
    const { data: members } = await supabase
      .from("club_members")
      .select("users(apns_token)")
      .eq("club_id", clubId)
      .eq("status", "active")
      .neq("user_id", club.organiser_id);

    if (!members?.length) return new Response("no members", { status: 200 });

    await Promise.all(
      members
        .map((m: any) => m.users?.apns_token)
        .filter(Boolean)
        .map((token: string) =>
          sendPush(
            token,
            club.name,
            "Voting is open! Suggest and vote for your next book 📚",
            { club_id: clubId, session_id: sessionId },
          )
        ),
    );

    return new Response("ok", { status: 200 });
  } catch (err) {
    console.error(err);
    return new Response("error", { status: 500 });
  }
});
