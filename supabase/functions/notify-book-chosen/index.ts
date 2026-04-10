// supabase/functions/notify-book-chosen/index.ts
//
// Webhook: clubs table → UPDATE
// Fires when current_book_id changes (a new book is set after voting).
// Notifies all active members.

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

    // Only fire when current_book_id actually changed to a new value
    if (
      !newRecord.current_book_id ||
      oldRecord.current_book_id === newRecord.current_book_id
    ) {
      return new Response("no book change", { status: 200 });
    }

    const clubId = newRecord.id;
    const bookId = newRecord.current_book_id;

    // Fetch the book title
    const { data: book } = await supabase
      .from("books")
      .select("title, author")
      .eq("id", bookId)
      .single();

    if (!book) return new Response("book not found", { status: 200 });

    // Fetch all active members
    const { data: members } = await supabase
      .from("club_members")
      .select("users(apns_token)")
      .eq("club_id", clubId)
      .eq("status", "active");

    if (!members?.length) return new Response("no members", { status: 200 });

    await Promise.all(
      members
        .map((m: any) => m.users?.apns_token)
        .filter(Boolean)
        .map((token: string) =>
          sendPush(
            token,
            newRecord.name,
            `Your next read is "${book.title}" by ${book.author}`,
            { club_id: clubId, book_id: bookId },
          )
        ),
    );

    return new Response("ok", { status: 200 });
  } catch (err) {
    console.error(err);
    return new Response("error", { status: 500 });
  }
});
