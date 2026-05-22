/**
 * Star Sitters — send_push (BACKEND.md §8.1)
 * DB webhook → validates secret → mock or FCM HTTP v1 OAuth.
 */
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { create as createJwt, getNumericDate } from "https://deno.land/x/djwt@v3.0.2/mod.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SRK = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const FCM_PROJECT_ID = Deno.env.get("FCM_PROJECT_ID") ?? "";
const WEBHOOK_SECRET = Deno.env.get("WEBHOOK_SECRET")!;

function loadFcmServiceAccountJson(): string {
  const inline = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON")?.trim() ?? "";
  if (inline.length > 0) return inline;
  const path = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON_FILE")?.trim();
  if (path) {
    try {
      return Deno.readTextFileSync(path).trim();
    } catch (e) {
      console.error(JSON.stringify({ lvl: "error", fn: "send_push", err: String(e), path }));
      return "";
    }
  }
  return "";
}

const FCM_SCOPE = "https://www.googleapis.com/auth/firebase.messaging";
const TOKEN_URL = "https://oauth2.googleapis.com/token";

interface NotificationRecord {
  id: string;
  user_id: string;
  type: string;
  title: string | null;
  body: string | null;
  data: Record<string, unknown>;
}

interface ServiceAccount {
  client_email: string;
  private_key: string;
  project_id: string;
}

let cachedToken: { token: string; expiresAt: number } | null = null;

async function importPrivateKey(pem: string): Promise<CryptoKey> {
  const cleaned = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s+/g, "");
  const der = Uint8Array.from(atob(cleaned), (c) => c.charCodeAt(0));
  return crypto.subtle.importKey(
    "pkcs8",
    der,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
}

async function getAccessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedToken && cachedToken.expiresAt > now + 60) return cachedToken.token;

  const key = await importPrivateKey(sa.private_key);
  const jwt = await createJwt(
    { alg: "RS256", typ: "JWT" },
    {
      iss: sa.client_email,
      scope: FCM_SCOPE,
      aud: TOKEN_URL,
      iat: getNumericDate(0),
      exp: getNumericDate(60 * 60),
    },
    key,
  );

  const resp = await fetch(TOKEN_URL, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  if (!resp.ok) throw new Error(`token exchange failed: ${resp.status} ${await resp.text()}`);
  const json = await resp.json();
  cachedToken = { token: json.access_token, expiresAt: now + (json.expires_in ?? 3600) };
  return cachedToken.token;
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

  const payload = await req.json();
  const record = payload.record as NotificationRecord;
  if (!record?.id) return new Response("bad payload", { status: 400 });

  const admin = createClient(SUPABASE_URL, SUPABASE_SRK, { auth: { persistSession: false } });

  async function markDelivery(
    status: string,
  ): Promise<void> {
    try {
      await admin.from("notifications").update({ delivery_status: status }).eq("id", record.id);
    } catch {
      // column may be missing on very old DBs; ignore
    }
  }

  const { data: providerRaw } = await admin.rpc("cfg_text", {
    p_key: "fcm_provider",
    p_default: "mock",
  });
  const provider = (providerRaw as string) ?? "mock";

  if (provider !== "live") {
    console.log(JSON.stringify({
      lvl: "info",
      fn: "send_push",
      mode: "mock",
      notif_id: record.id,
      user_id: record.user_id,
      type: record.type,
    }));
    await markDelivery("mock_ok");
    return new Response("mock-ok", { status: 200 });
  }

  const FCM_SA_JSON = loadFcmServiceAccountJson();
  if (!FCM_PROJECT_ID || !FCM_SA_JSON) {
    console.error(JSON.stringify({
      lvl: "error",
      fn: "send_push",
      err: "fcm_provider=live but secrets missing",
      notif_id: record.id,
    }));
    await markDelivery("config_missing");
    return new Response("config missing", { status: 500 });
  }

  const fcmUrl = `https://fcm.googleapis.com/v1/projects/${FCM_PROJECT_ID}/messages:send`;

  const { data: devices, error } = await admin.from("devices").select("fcm_token, platform").eq(
    "user_id",
    record.user_id,
  );

  if (error || !devices?.length) {
    console.log(JSON.stringify({ lvl: "info", fn: "send_push", notif_id: record.id, devices: 0 }));
    await markDelivery("no_devices");
    return new Response("no devices", { status: 200 });
  }

  let sa: ServiceAccount;
  try {
    sa = JSON.parse(FCM_SA_JSON);
  } catch {
    await markDelivery("invalid_sa_json");
    return new Response("invalid service account json", { status: 500 });
  }
  const accessToken = await getAccessToken(sa);

  const sends = devices.map((device: { fcm_token: string }) =>
    withRetry(async () => {
      const fcmPayload = {
        message: {
          token: device.fcm_token,
          notification: {
            title: record.title ?? "Star Sitters",
            body: record.body ?? "",
          },
          data: {
            notification_id: record.id,
            type: record.type,
            ...Object.fromEntries(
              Object.entries(record.data ?? {}).map(([k, v]) => [k, String(v)]),
            ),
          },
          android: { priority: "high" },
          apns: { headers: { "apns-priority": "10" } },
          fcm_options: { analytics_label: record.type },
        },
      };
      const resp = await fetch(fcmUrl, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(fcmPayload),
      });
      if (!resp.ok) {
        const errText = await resp.text();
        if (
          resp.status === 404 || resp.status === 410 ||
          errText.includes("UNREGISTERED") || errText.includes("NOT_FOUND")
        ) {
          await admin.from("devices").delete().eq("user_id", record.user_id).eq(
            "fcm_token",
            device.fcm_token,
          );
          return;
        }
        throw new Error(`fcm ${resp.status}: ${errText}`);
      }
    })
  );

  const results = await Promise.allSettled(sends);
  const ok = results.filter((r) => r.status === "fulfilled").length;
  console.log(JSON.stringify({
    lvl: "info",
    fn: "send_push",
    notif_id: record.id,
    devices: results.length,
    ok,
    fail: results.length - ok,
  }));
  const delivery = ok === 0 ? "failed" : ok === results.length ? "sent" : "partial";
  await markDelivery(delivery);
  return new Response("ok", { status: 200 });
});
