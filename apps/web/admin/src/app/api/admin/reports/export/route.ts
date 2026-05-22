import { NextResponse } from "next/server";
import { createClient } from "@supabase/supabase-js";
import { createServerSupabaseClient } from "@/lib/supabase/server";

/** BACKEND.md §31 Day 10 — CSV export (notifications). Requires SUPABASE_SERVICE_ROLE_KEY server-side. */
export async function GET() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const srk = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!url || !srk) {
    return NextResponse.json(
      { error: "Missing NEXT_PUBLIC_SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY" },
      { status: 500 },
    );
  }

  const userClient = await createServerSupabaseClient();
  const {
    data: { user },
  } = await userClient.auth.getUser();
  if (!user) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const { data: adminRow } = await userClient
    .from("admin_users")
    .select("id")
    .eq("id", user.id)
    .maybeSingle();
  if (!adminRow) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  const admin = createClient(url, srk, { auth: { persistSession: false } });
  const { data, error } = await admin
    .from("notifications")
    .select("id, user_id, type, title, body, delivery_status, created_at")
    .order("created_at", { ascending: false })
    .limit(5000);

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  const header = ["id", "user_id", "type", "title", "body", "delivery_status", "created_at"];
  const lines = [header.join(",")];
  for (const row of data ?? []) {
    const r = row as Record<string, unknown>;
    const esc = (v: unknown) => {
      const s = v == null ? "" : String(v);
      if (/[",\n]/.test(s)) return `"${s.replace(/"/g, '""')}"`;
      return s;
    };
    lines.push(
      [
        esc(r.id),
        esc(r.user_id),
        esc(r.type),
        esc(r.title),
        esc(r.body),
        esc(r.delivery_status),
        esc(r.created_at),
      ].join(","),
    );
  }

  return new NextResponse(lines.join("\n"), {
    status: 200,
    headers: {
      "Content-Type": "text/csv; charset=utf-8",
      "Content-Disposition": 'attachment; filename="notifications-export.csv"',
    },
  });
}
