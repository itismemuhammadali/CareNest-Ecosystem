/**
 * Star Sitters — send_guardian_consent_email (BACKEND.md §8.2)
 */
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SRK = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const WEBHOOK_SECRET = Deno.env.get("WEBHOOK_SECRET")!;
const APP_BASE_URL = Deno.env.get("APP_BASE_URL") ?? "https://example.invalid";
const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY") ?? "";

interface GuardianConsentRecord {
  id: string;
  sitter_id: string;
  guardian_name: string;
  guardian_email: string;
  consent_token: string;
}

async function withRetry<T>(fn: () => Promise<T>, attempts = 3): Promise<T> {
  let lastErr: unknown;
  for (let i = 0; i < attempts; i++) {
    try {
      return await fn();
    } catch (e) {
      lastErr = e;
      await new Promise((r) => setTimeout(r, 200 * Math.pow(4, i)));
    }
  }
  throw lastErr;
}

serve(async (req) => {
  const secret = req.headers.get("x-webhook-secret");
  if (!secret || secret !== WEBHOOK_SECRET) {
    return new Response("Unauthorized", { status: 401 });
  }

  try {
  const payload = await req.json();
  const record = payload.record as GuardianConsentRecord;
  if (!record?.id) return new Response("bad payload", { status: 400 });

  const admin = createClient(SUPABASE_URL, SUPABASE_SRK, { auth: { persistSession: false } });

  const { data: providerRaw, error: providerErr } = await admin.rpc("cfg_text", {
    p_key: "email_provider",
    p_default: "mock",
  });
  if (providerErr) {
    console.error(JSON.stringify({ lvl: "error", fn: "send_guardian_consent_email", err: String(providerErr) }));
    return new Response(JSON.stringify({ error: "cfg_text email_provider failed" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
  const { data: fromRaw, error: fromErr } = await admin.rpc("cfg_text", {
    p_key: "email_from",
    p_default: "StarSitters <noreply@starsitters.app>",
  });
  if (fromErr) {
    console.error(JSON.stringify({ lvl: "error", fn: "send_guardian_consent_email", err: String(fromErr) }));
    return new Response(JSON.stringify({ error: "cfg_text email_from failed" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
  const provider = String(providerRaw ?? "mock").trim().toLowerCase();
  const fromAddr = String(fromRaw ?? "StarSitters <noreply@starsitters.app>").trim();

  const { data: user } = await admin.from("users").select("full_name").eq("id", record.sitter_id).maybeSingle();
  const sitterName = user?.full_name ?? "your child";

  const consentLink = `${APP_BASE_URL}/consent?token=${record.consent_token}`;
  const subject = `Guardian consent for ${sitterName} — Star Sitters`;
  const html = `
    <h2>Guardian Consent Required — Star Sitters</h2>
    <p>Hi ${record.guardian_name},</p>
    <p>${sitterName} has registered on Star Sitters, a teen babysitting marketplace.</p>
    <p>To activate their account, click the button below within 24 hours:</p>
    <p><a href="${consentLink}" style="background:#2B7FFF;color:white;padding:12px 24px;border-radius:8px;text-decoration:none;display:inline-block;">Give Consent</a></p>
    <p>This link is one-time use and expires in 24 hours.</p>
    <p>If you did not expect this email, you can safely ignore it.</p>
  `;
  const text =
    `Guardian consent for ${sitterName}\n\nClick to consent (valid 24h): ${consentLink}\n\nIgnore if unexpected.`;

  if (provider === "mock") {
    console.log(JSON.stringify({
      lvl: "info",
      fn: "send_guardian_consent_email",
      mode: "mock",
      to: record.guardian_email,
      link: consentLink,
    }));
    return new Response("mock-ok", { status: 200 });
  }

  if (provider === "resend") {
    if (!RESEND_API_KEY) {
      console.error(JSON.stringify({
        lvl: "error",
        fn: "send_guardian_consent_email",
        err: "email_provider=resend but RESEND_API_KEY missing",
      }));
      return new Response("config missing", { status: 500 });
    }
    await withRetry(async () => {
      const r = await fetch("https://api.resend.com/emails", {
        method: "POST",
        headers: {
          Authorization: `Bearer ${RESEND_API_KEY}`,
          "Content-Type": "application/json",
          "Idempotency-Key": `consent:${record.id}`,
        },
        body: JSON.stringify({
          from: fromAddr,
          to: [record.guardian_email],
          subject,
          html,
          text,
          tags: [{ name: "type", value: "guardian_consent" }],
        }),
      });
      if (!r.ok) throw new Error(`resend ${r.status}: ${await r.text()}`);
    });
    console.log(JSON.stringify({
      lvl: "info",
      fn: "send_guardian_consent_email",
      provider: "resend",
      consent_id: record.id,
      to: record.guardian_email,
    }));
    return new Response("ok", { status: 200 });
  }

  console.error(JSON.stringify({
    lvl: "error",
    fn: "send_guardian_consent_email",
    err: `unknown email_provider=${provider}`,
  }));
  return new Response("unknown provider", { status: 500 });
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    console.error(JSON.stringify({ lvl: "error", fn: "send_guardian_consent_email", err: msg }));
    return new Response(JSON.stringify({ error: msg }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
