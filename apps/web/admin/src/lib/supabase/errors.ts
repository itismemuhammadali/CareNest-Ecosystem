/** Format PostgREST / Supabase client errors for UI banners */
export function formatSupabaseError(err: unknown): string {
  if (err == null) return "Unknown error";
  if (typeof err === "string") return err;
  if (err instanceof Error && err.message) return err.message;
  if (typeof err === "object") {
    const o = err as Record<string, unknown>;
    const msg = typeof o.message === "string" ? o.message : "";
    const details = typeof o.details === "string" ? o.details : "";
    const hint = typeof o.hint === "string" ? o.hint : "";
    const code = typeof o.code === "string" ? o.code : "";
    const parts = [msg, details, hint].filter((s) => s.trim().length > 0);
    if (parts.length) return parts.join(" — ") + (code ? ` (${code})` : "");
    if (code) return code;
  }
  return "Request failed";
}
