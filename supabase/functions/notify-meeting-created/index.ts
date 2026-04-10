// supabase/functions/notify-meeting-created/index.ts
//
// Webhook: meetings table → INSERT
// Notifies all active club members that a new meeting has been scheduled.

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
    const meeting = payload.record;

    const clubId = meeting.club_id;
    const meetingId = meeting.id;

    // Fetch club name
    const { data: club } = await supabase
      .from("clubs")
      .select("name, organiser_id")
      .eq("id", clubId)
      .single();

    if (!club) return new Response("club not found", { status: 200 });

    // Format the meeting date nicely
    const date = new Date(meeting.scheduled_at);
    const dateStr = date.toLocaleDateString("en-GB", {
      weekday: "short",
      day: "numeric",
      month: "short",
    });

    // Fetch all active members except the organiser (who created it)
    const { data: members } = await supabase
      .from("club_members")
      .select("users(apns_token)")
      .eq("club_id", clubId)
      .eq("status", "active")
      .neq("user_id", club.organiser_id);

    if (!members?.length) return new Response("no members", { status: 200 });

    // Send to all members who have a token
    await Promise.all(
      members
        .map((m: any) => m.users?.apns_token)
        .filter(Boolean)
        .map((token: string) =>
          sendPush(
            token,
            club.name,
            `New meeting scheduled for ${dateStr}`,
            { club_id: clubId, meeting_id: meetingId },
          )
        ),
    );

    return new Response("ok", { status: 200 });
  } catch (err) {
    console.error(err);
    return new Response("error", { status: 500 });
  }
});
