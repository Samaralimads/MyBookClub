// supabase/functions/notify-meeting-updated/index.ts
//
// Webhook: meetings table → UPDATE
// Notifies members only when the date or address actually changed.

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
    const oldRecord = payload.old_record;
    const newRecord = payload.record;

    // Only notify if date or address changed — ignore minor edits
    const dateChanged = oldRecord.scheduled_at !== newRecord.scheduled_at;
    const addressChanged = oldRecord.address !== newRecord.address;

    if (!dateChanged && !addressChanged) {
      return new Response("no relevant change", { status: 200 });
    }

    const clubId = newRecord.club_id;
    const meetingId = newRecord.id;

    // Fetch club
    const { data: club } = await supabase
      .from("clubs")
      .select("name, organiser_id")
      .eq("id", clubId)
      .single();

    if (!club) return new Response("club not found", { status: 200 });

    // Build message
    const changes: string[] = [];
    if (dateChanged) {
      const date = new Date(newRecord.scheduled_at);
      const dateStr = date.toLocaleDateString("en-GB", {
        weekday: "short",
        day: "numeric",
        month: "short",
      });
      changes.push(`new date: ${dateStr}`);
    }
    if (addressChanged) changes.push("location updated");
    const body = `Meeting updated — ${changes.join(", ")}`;

    // Fetch all active members except organiser
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
            body,
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
