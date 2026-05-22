"use client";

import type { SupabaseClient } from "@supabase/supabase-js";
import type { OnboardingDetails } from "@/components/ui/OnboardingDetailsModal";
import { createClient } from "./client";

const BATCH_IN = 120;

function uniqueIds(ids: string[]): string[] {
  return [...new Set(ids.filter(Boolean))];
}

type UserRow = {
  id: string;
  full_name: string | null;
  email: string;
  created_at?: string;
  role?: string;
};

async function fetchUsersByIds(
  supabase: SupabaseClient,
  ids: string[],
): Promise<Map<string, UserRow>> {
  const map = new Map<string, UserRow>();
  const list = uniqueIds(ids);
  for (let i = 0; i < list.length; i += BATCH_IN) {
    const chunk = list.slice(i, i + BATCH_IN);
    const { data, error } = await supabase
      .from("users")
      .select("id, full_name, email, created_at, role")
      .in("id", chunk);
    if (error) throw error;
    for (const u of (data ?? []) as UserRow[]) {
      map.set(u.id, u);
    }
  }
  return map;
}

async function fetchCoursesByIds(
  supabase: SupabaseClient,
  ids: string[],
): Promise<Map<string, { id: string; name: string }>> {
  const map = new Map<string, { id: string; name: string }>();
  const list = uniqueIds(ids);
  for (let i = 0; i < list.length; i += BATCH_IN) {
    const chunk = list.slice(i, i + BATCH_IN);
    const { data, error } = await supabase.from("courses").select("id, name").in("id", chunk);
    if (error) throw error;
    for (const c of (data ?? []) as { id: string; name: string }[]) {
      map.set(c.id, c);
    }
  }
  return map;
}

export type DashboardStats = {
  families_total: number;
  families_pending_bg: number;
  families_approved_bg: number;
  sitters_total: number;
  sitters_active: number;
  sitters_pending_consent: number;
  certs_pending: number;
  jobs_open: number;
  jobs_active: number;
  jobs_completed_30d: number;
  disputes_open: number;
  withdrawals_pending: number;
};

export type FamilyRow = {
  user_id: string;
  full_name: string | null;
  email: string;
  registered_at: string;
  bg_check_status: "not_submitted" | "pending" | "approved" | "rejected";
  rejection_reason: string | null;
  home_address: string | null;
  active_jobs: number;
};

export type SitterRow = {
  user_id: string;
  full_name: string | null;
  email: string;
  date_of_birth: string;
  age: number;
  registered_at: string;
  is_active: boolean;
  guardian_consent_status: string;
  suspension_reason: string | null;
  total_minutes_worked: number;
  total_earnings: number;
  guardian_name: string | null;
  guardian_email: string | null;
  guardian_phone: string | null;
};

export type JobRow = {
  job_id: string;
  family_name: string | null;
  sitter_name: string | null;
  job_date: string | null;
  status: string;
  computed_minutes: number | null;
  computed_wage: number | null;
  timeline: { event_type: string; title: string | null; created_at: string }[];
  location_address?: unknown;
  location_lat?: number | null;
  location_lng?: number | null;
};

export type DisputeRow = {
  id: string;
  job_id: string;
  reported_by_user_id: string;
  reported_by_role: "family" | "sitter";
  issue_type: string;
  description: string | null;
  priority: "low" | "medium" | "high";
  status: "open" | "investigating" | "resolved";
  resolution_notes: string | null;
  resolved_at: string | null;
  created_at: string;
  reporter_name: string | null;
  reporter_email: string | null;
  clock_in_at: string | null;
  clock_out_at: string | null;
  time_computed_minutes: number | null;
  time_computed_wage: number | null;
};

function ageFromDob(dob: string): number {
  const d = new Date(dob);
  const now = new Date();
  let age = now.getFullYear() - d.getFullYear();
  const m = now.getMonth() - d.getMonth();
  if (m < 0 || (m === 0 && now.getDate() < d.getDate())) age -= 1;
  return age;
}

export async function fetchDashboardStats(): Promise<DashboardStats> {
  const supabase = createClient();
  const { data, error } = await supabase.rpc("admin_dashboard_stats");
  if (error) throw error;
  return data as DashboardStats;
}

export async function fetchFamilies(): Promise<FamilyRow[]> {
  const supabase = createClient();
  const { data: profiles, error } = await supabase
    .from("family_profiles")
    .select("user_id, bg_check_status, rejection_reason, home_address");
  if (error) throw error;
  const rows = (profiles ?? []) as {
    user_id: string;
    bg_check_status: FamilyRow["bg_check_status"];
    rejection_reason: string | null;
    home_address: unknown;
  }[];
  if (rows.length === 0) return [];

  const userMap = await fetchUsersByIds(supabase, rows.map((r) => r.user_id));

  const familyIds = rows.map((r) => r.user_id);
  const activeJobsByFamily: Record<string, number> = {};
  for (let i = 0; i < familyIds.length; i += BATCH_IN) {
    const chunk = familyIds.slice(i, i + BATCH_IN);
    const { data: jobs, error: jerr } = await supabase
      .from("jobs")
      .select("family_id, status")
      .in("family_id", chunk);
    if (jerr) throw jerr;
    for (const j of (jobs ?? []) as { family_id: string; status: string }[]) {
      const isActive = j.status === "open" || j.status === "hired" || j.status === "active";
      if (isActive) activeJobsByFamily[j.family_id] = (activeJobsByFamily[j.family_id] ?? 0) + 1;
    }
  }

  const result = rows.map((r) => {
    const u = userMap.get(r.user_id);
    let addressText: string | null = null;
    const addr = r.home_address;
    if (addr && typeof addr === "object" && !Array.isArray(addr)) {
      const a = addr as Record<string, unknown>;
      addressText =
        (a.line1 as string) ||
        (a.formatted as string) ||
        (a.address as string) ||
        JSON.stringify(addr);
    } else if (typeof addr === "string") {
      addressText = addr;
    }
    return {
      user_id: r.user_id,
      full_name: u?.full_name ?? null,
      email: u?.email ?? "",
      registered_at: u?.created_at ?? "",
      bg_check_status: r.bg_check_status,
      rejection_reason: r.rejection_reason,
      home_address: addressText,
      active_jobs: activeJobsByFamily[r.user_id] ?? 0,
    };
  });
  result.sort((a, b) => {
    const dateA = a.registered_at ? new Date(a.registered_at).getTime() : 0;
    const dateB = b.registered_at ? new Date(b.registered_at).getTime() : 0;
    return dateB - dateA;
  });
  return result;
}

export async function fetchSitters(): Promise<SitterRow[]> {
  const supabase = createClient();
  const { data: profiles, error } = await supabase
    .from("sitter_profiles")
    .select(
      "user_id, date_of_birth, is_active, guardian_consent_status, suspension_reason, total_minutes_worked, total_earnings",
    );
  if (error) throw error;
  const rows = (profiles ?? []) as {
    user_id: string;
    date_of_birth: string;
    is_active: boolean;
    guardian_consent_status: string;
    suspension_reason: string | null;
    total_minutes_worked: number;
    total_earnings: number | string;
  }[];
  if (rows.length === 0) return [];

  const userMap = await fetchUsersByIds(supabase, rows.map((r) => r.user_id));

  const guardianMap = new Map<string, { guardian_name: string; guardian_email: string; guardian_phone: string | null }>();
  const sitterIds = rows.map((r) => r.user_id);
  for (let i = 0; i < sitterIds.length; i += BATCH_IN) {
    const chunk = sitterIds.slice(i, i + BATCH_IN);
    const { data: consents } = await supabase
      .from("guardian_consents")
      .select("sitter_id, guardian_name, guardian_email, guardian_phone")
      .in("sitter_id", chunk);
    for (const c of (consents ?? []) as { sitter_id: string; guardian_name: string; guardian_email: string; guardian_phone: string | null }[]) {
      guardianMap.set(c.sitter_id, { guardian_name: c.guardian_name, guardian_email: c.guardian_email, guardian_phone: c.guardian_phone });
    }
  }

  const sitterResult = rows.map((r) => {
    const u = userMap.get(r.user_id);
    const g = guardianMap.get(r.user_id);
    return {
      user_id: r.user_id,
      full_name: u?.full_name ?? null,
      email: u?.email ?? "",
      date_of_birth: r.date_of_birth,
      age: ageFromDob(r.date_of_birth),
      registered_at: u?.created_at ?? "",
      is_active: r.is_active,
      guardian_consent_status: r.guardian_consent_status,
      suspension_reason: r.suspension_reason,
      total_minutes_worked: r.total_minutes_worked,
      total_earnings: Number(r.total_earnings ?? 0),
      guardian_name: g?.guardian_name ?? null,
      guardian_email: g?.guardian_email ?? null,
      guardian_phone: g?.guardian_phone ?? null,
    };
  });
  sitterResult.sort((a, b) => {
    const dateA = a.registered_at ? new Date(a.registered_at).getTime() : 0;
    const dateB = b.registered_at ? new Date(b.registered_at).getTime() : 0;
    return dateB - dateA;
  });
  return sitterResult;
}

export async function fetchJobs(
  status: string = "all",
  search = "",
  page = 1,
  pageSize = 50,
): Promise<JobRow[]> {
  const supabase = createClient();
  const { data, error } = await supabase.rpc("admin_list_jobs", {
    p_status_filter: status,
    p_search: search,
    p_page: page,
    p_page_size: pageSize,
  });
  if (error) throw error;
  return (data ?? []) as JobRow[];
}

export async function fetchDisputes(): Promise<DisputeRow[]> {
  const supabase = createClient();
  const { data, error } = await supabase
    .from("disputes")
    .select(
      "id, job_id, reported_by_user_id, reported_by_role, issue_type, description, priority, status, resolution_notes, resolved_at, created_at",
    )
    .order("created_at", { ascending: false })
    .limit(100);
  if (error) throw error;

  type DisputeRowRaw = {
    id: string;
    job_id: string;
    reported_by_user_id: string;
    reported_by_role: "family" | "sitter";
    issue_type: string;
    description: string | null;
    priority: "low" | "medium" | "high";
    status: "open" | "investigating" | "resolved";
    resolution_notes: string | null;
    resolved_at: string | null;
    created_at: string;
  };
  const rows = ((data ?? []) as unknown) as DisputeRowRaw[];
  if (rows.length === 0) return [];

  const userMap = await fetchUsersByIds(
    supabase,
    rows.map((d) => d.reported_by_user_id),
  );

  const jobIds = uniqueIds(rows.map((d) => d.job_id));
  const hireMap = new Map<string, string>();
  for (let i = 0; i < jobIds.length; i += BATCH_IN) {
    const chunk = jobIds.slice(i, i + BATCH_IN);
    const { data: hires } = await supabase
      .from("hires")
      .select("id, job_id")
      .in("job_id", chunk);
    for (const h of (hires ?? []) as { id: string; job_id: string }[]) {
      hireMap.set(h.job_id, h.id);
    }
  }

  const hireIds = uniqueIds([...hireMap.values()]);
  const timeEntryMap = new Map<string, { clock_in_at: string | null; clock_out_at: string | null; computed_minutes: number | null; computed_wage: number | null }>();
  for (let i = 0; i < hireIds.length; i += BATCH_IN) {
    const chunk = hireIds.slice(i, i + BATCH_IN);
    const { data: entries } = await supabase
      .from("time_entries")
      .select("hire_id, clock_in_at, clock_out_at, computed_minutes, computed_wage")
      .in("hire_id", chunk)
      .order("clock_in_at", { ascending: false });
    for (const e of (entries ?? []) as { hire_id: string; clock_in_at: string | null; clock_out_at: string | null; computed_minutes: number | null; computed_wage: number | null }[]) {
      if (!timeEntryMap.has(e.hire_id)) {
        timeEntryMap.set(e.hire_id, { clock_in_at: e.clock_in_at, clock_out_at: e.clock_out_at, computed_minutes: e.computed_minutes, computed_wage: e.computed_wage });
      }
    }
  }

  return rows.map((d) => {
    const rep = userMap.get(d.reported_by_user_id);
    const hireId = hireMap.get(d.job_id);
    const te = hireId ? timeEntryMap.get(hireId) : null;
    return {
      id: d.id,
      job_id: d.job_id,
      reported_by_user_id: d.reported_by_user_id,
      reported_by_role: d.reported_by_role,
      issue_type: d.issue_type,
      description: d.description,
      priority: d.priority,
      status: d.status,
      resolution_notes: d.resolution_notes,
      resolved_at: d.resolved_at,
      created_at: d.created_at,
      reporter_name: rep?.full_name ?? null,
      reporter_email: rep?.email ?? null,
      clock_in_at: te?.clock_in_at ?? null,
      clock_out_at: te?.clock_out_at ?? null,
      time_computed_minutes: te?.computed_minutes ?? null,
      time_computed_wage: te?.computed_wage ?? null,
    };
  });
}

export async function approveFamily(userId: string) {
  const supabase = createClient();
  const { error } = await supabase.rpc("admin_approve_family", { p_user_id: userId });
  if (error) throw error;
}

export async function rejectFamily(userId: string, reason: string) {
  const supabase = createClient();
  const { error } = await supabase.rpc("admin_reject_family", {
    p_user_id: userId,
    p_reason: reason,
  });
  if (error) throw error;
}

export async function suspendSitter(
  userId: string,
  reason: string,
  until: string | null = null,
) {
  const supabase = createClient();
  const { error } = await supabase.rpc("admin_suspend_sitter", {
    p_user_id: userId,
    p_reason: reason,
    p_until: until,
  });
  if (error) throw error;
}

export async function unsuspendSitter(userId: string) {
  const supabase = createClient();
  const { error } = await supabase.rpc("admin_unsuspend_sitter", { p_user_id: userId });
  if (error) throw error;
}

export async function resolveDispute(disputeId: string, notes: string) {
  const supabase = createClient();
  const { error } = await supabase.rpc("admin_resolve_dispute", {
    p_dispute_id: disputeId,
    p_notes: notes,
  });
  if (error) throw error;
}

export async function setDisputeStatus(disputeId: string, status: string) {
  const supabase = createClient();
  const { error } = await supabase.rpc("admin_update_dispute_status", {
    p_dispute_id: disputeId,
    p_status: status,
  });
  if (error) throw error;
}

export async function fetchWageTiers() {
  const supabase = createClient();
  const { data, error } = await supabase
    .from("age_wage_tiers")
    .select("*")
    .order("min_age", { ascending: true });
  if (error) throw error;
  return data ?? [];
}

export async function updateWageTiers(
  tiers: { min_age: number; max_age: number; hourly_rate: number }[],
) {
  const supabase = createClient();
  const { error } = await supabase.rpc("admin_update_wage_tiers", { p_tiers: tiers });
  if (error) throw error;
}

export async function signOut() {
  const supabase = createClient();
  await supabase.auth.signOut();
}

export type RegistrationTrendRow = {
  d: string;
  role: string;
  cnt: number;
};

export async function fetchRegistrationTrend(): Promise<RegistrationTrendRow[]> {
  const supabase = createClient();
  const { data, error } = await supabase.rpc("admin_registration_trend");
  if (error) throw error;
  const rows = (data ?? []) as { d: string; role: string; cnt: number | string }[];
  return rows.map((r) => ({
    d: typeof r.d === "string" ? r.d : String(r.d),
    role: r.role,
    cnt: typeof r.cnt === "string" ? parseInt(r.cnt, 10) : Number(r.cnt),
  }));
}

/** Monthly sum of sitter `earning` ledger rows (matches Reports revenue window logic). */
export async function fetchReportRevenuePerMonth(
  pMonths: number,
): Promise<{ month: string; revenue: number }[]> {
  const supabase = createClient();
  const { data, error } = await supabase.rpc("admin_report_revenue_per_month", {
    p_months: pMonths,
  });
  if (error) throw error;
  const rows = (data ?? []) as {
    month_label?: string;
    revenue?: number | string;
  }[];
  return rows.map((r) => ({
    month: String(r.month_label ?? ""),
    revenue: typeof r.revenue === "string" ? parseFloat(r.revenue) : Number(r.revenue ?? 0),
  }));
}

function unwrapRpcJsonbRow(raw: unknown): Record<string, unknown> {
  let v: unknown = raw;
  if (typeof v === "string") {
    try {
      v = JSON.parse(v) as unknown;
    } catch {
      return {};
    }
  }
  if (!v || typeof v !== "object") return {};
  const r = v as Record<string, unknown>;
  const vals = Object.values(r);
  if (
    vals.length === 1 &&
    vals[0] &&
    typeof vals[0] === "object" &&
    !Array.isArray(vals[0])
  ) {
    return vals[0] as Record<string, unknown>;
  }
  return r;
}

export type RecentOnboardingRow = {
  type: "Family" | "Babysitter";
  name: string;
  email: string;
  date: string;
  status: "Verified" | "Pending";
  details: OnboardingDetails;
};

/** Latest family + sitter signups (RPC `admin_recent_onboarding`). */
export async function fetchRecentOnboarding(limit = 25): Promise<RecentOnboardingRow[]> {
  const supabase = createClient();
  const { data, error } = await supabase.rpc("admin_recent_onboarding", { p_limit: limit });
  if (error) throw error;
  const list = (data ?? []) as unknown[];
  const out: RecentOnboardingRow[] = [];
  for (const raw of list) {
    const o = unwrapRpcJsonbRow(raw);
    const t = o.type === "Babysitter" ? "Babysitter" : "Family";
    const st = o.status === "Verified" ? "Verified" : "Pending";
    const details = o.details;
    if (!details || typeof details !== "object") continue;
    const d = details as Record<string, unknown>;
    if (t === "Family" && d.type === "Family") {
      out.push({
        type: "Family",
        name: String(o.name ?? ""),
        email: String(o.email ?? ""),
        date: String(o.date ?? ""),
        status: st,
        details: {
          type: "Family",
          name: String(d.name ?? o.name ?? ""),
          registeredOn: String(d.registeredOn ?? o.date ?? ""),
          status: d.status === "Verified" ? "Verified" : "Pending",
          email: String(d.email ?? ""),
          phone: String(d.phone ?? "—"),
          address: String(d.address ?? "—"),
          numberOfChildren: Number(d.numberOfChildren ?? 0),
          childrenAges: String(d.childrenAges ?? "—"),
          backgroundCheck: String(d.backgroundCheck ?? "—"),
          preferredRate: String(d.preferredRate ?? "—"),
        },
      });
    } else if (t === "Babysitter" && d.type === "Babysitter") {
      out.push({
        type: "Babysitter",
        name: String(o.name ?? ""),
        email: String(o.email ?? ""),
        date: String(o.date ?? ""),
        status: st,
        details: {
          type: "Babysitter",
          name: String(d.name ?? o.name ?? ""),
          registeredOn: String(d.registeredOn ?? o.date ?? ""),
          status: d.status === "Verified" ? "Verified" : "Pending",
          email: String(d.email ?? ""),
          phone: String(d.phone ?? "—"),
          address: String(d.address ?? "—"),
          yearsOfExperience: Number(d.yearsOfExperience ?? 0),
          ageGroups: String(d.ageGroups ?? "—"),
          backgroundCheck: String(d.backgroundCheck ?? "—"),
          hourlyRate: String(d.hourlyRate ?? "—"),
        },
      });
    }
  }
  return out;
}

export type NotificationLogRow = {
  id: string;
  user_id: string;
  type: string;
  title: string | null;
  body: string | null;
  created_at: string;
  delivery_status: string | null;
  users?: { email: string; role: string } | { email: string; role: string }[] | null;
};

export async function fetchNotificationLogs(limit = 500): Promise<NotificationLogRow[]> {
  const supabase = createClient();
  const { data, error } = await supabase
    .from("notifications")
    .select("id, user_id, type, title, body, created_at, delivery_status")
    .order("created_at", { ascending: false })
    .limit(limit);
  if (error) throw error;
  const rows = (data ?? []) as Omit<NotificationLogRow, "users">[];
  if (rows.length === 0) return [];

  const userMap = await fetchUsersByIds(supabase, rows.map((r) => r.user_id));

  return rows.map((r) => {
    const u = userMap.get(r.user_id);
    return {
      ...r,
      users:
        u && u.email
          ? { email: u.email, role: String(u.role ?? "family") }
          : null,
    };
  });
}

export async function approveCertificationSubmission(
  submissionId: string,
  notes?: string,
) {
  const supabase = createClient();
  const { error } = await supabase.rpc("admin_approve_certification_submission", {
    p_submission_id: submissionId,
    p_notes: notes ?? null,
  });
  if (error) throw error;
}

export async function rejectCertificationSubmission(submissionId: string, reason: string) {
  const supabase = createClient();
  const { error } = await supabase.rpc("admin_reject_certification_submission", {
    p_submission_id: submissionId,
    p_reason: reason,
  });
  if (error) throw error;
}

export type ReportSummary = {
  total_revenue: number;
  total_jobs: number;
  total_hours: number;
  avg_duration: number;
  window_months: number;
};

export type ReportCertStats = {
  approval_rate: number;
  avg_processing_days: number;
  most_popular_course: string;
  most_popular_enrollments: number;
  decided_submissions: number;
};

export type SystemConfigRow = { key: string; value: unknown };

export async function fetchSystemConfigRows(): Promise<SystemConfigRow[]> {
  const supabase = createClient();
  const { data, error } = await supabase.from("system_config").select("key, value");
  if (error) throw error;
  return (data ?? []) as SystemConfigRow[];
}

export async function adminUpdateSystemConfig(configs: Record<string, unknown>) {
  const supabase = createClient();
  const { error } = await supabase.rpc("admin_update_system_config", {
    p_configs: configs,
  });
  if (error) throw error;
}

/** Current admin’s `admin_users` row (RLS: own membership row only). */
export type AdminMembershipRow = {
  id: string;
  permissions: string[];
  created_at: string | null;
};

export async function fetchOwnAdminMembership(): Promise<AdminMembershipRow | null> {
  const supabase = createClient();
  const { data: auth } = await supabase.auth.getUser();
  const uid = auth.user?.id;
  if (!uid) return null;
  const { data, error } = await supabase
    .from("admin_users")
    .select("id, permissions, created_at")
    .eq("id", uid)
    .maybeSingle();
  if (error) throw error;
  if (!data) return null;
  const perms = Array.isArray(data.permissions) ? (data.permissions as string[]) : [];
  return {
    id: data.id as string,
    permissions: perms,
    created_at: (data as { created_at?: string }).created_at ?? null,
  };
}

export type AuditLogAdminRow = {
  id: string;
  created_at: string;
  action: string;
  entity_type: string | null;
  actor: { email: string; full_name: string | null } | { email: string; full_name: string | null }[] | null;
};

export async function fetchAuditLogs(limit = 100): Promise<AuditLogAdminRow[]> {
  const supabase = createClient();
  const { data, error } = await supabase
    .from("audit_logs")
    .select("id, created_at, action, entity_type, actor_id")
    .order("created_at", { ascending: false })
    .limit(limit);
  if (error) throw error;
  type Raw = {
    id: string;
    created_at: string;
    action: string;
    entity_type: string | null;
    actor_id: string | null;
  };
  const rows = (data ?? []) as Raw[];
  if (rows.length === 0) return [];

  const actorIds = rows.map((r) => r.actor_id).filter((id): id is string => id != null);
  const userMap = await fetchUsersByIds(supabase, actorIds);

  return rows.map((r) => {
    const a = r.actor_id ? userMap.get(r.actor_id) : null;
    return {
      id: r.id,
      created_at: r.created_at,
      action: r.action,
      entity_type: r.entity_type,
      actor: a ? { email: a.email, full_name: a.full_name } : null,
    };
  });
}

function num(v: unknown, fallback = 0): number {
  if (v == null) return fallback;
  if (typeof v === "number" && !Number.isNaN(v)) return v;
  const n = Number(v);
  return Number.isNaN(n) ? fallback : n;
}

export async function fetchReportSummary(pMonths: number): Promise<ReportSummary> {
  const supabase = createClient();
  const { data, error } = await supabase.rpc("admin_report_summary", { p_months: pMonths });
  if (error) throw error;
  const row =
    typeof data === "string"
      ? (JSON.parse(data) as Record<string, unknown>)
      : ((data ?? {}) as Record<string, unknown>);
  return {
    total_revenue: num(row.total_revenue),
    total_jobs: num(row.total_jobs),
    total_hours: num(row.total_hours),
    avg_duration: num(row.avg_duration),
    window_months: num(row.window_months, pMonths),
  };
}

export async function fetchReportJobsPerMonth(
  pMonths: number,
): Promise<{ month: string; jobs: number }[]> {
  const supabase = createClient();
  const { data, error } = await supabase.rpc("admin_report_jobs_per_month", { p_months: pMonths });
  if (error) throw error;
  const rows = (data ?? []) as { month_label: string; jobs: number | string }[];
  return rows.map((r) => ({
    month: r.month_label,
    jobs: typeof r.jobs === "string" ? parseInt(r.jobs, 10) : Number(r.jobs),
  }));
}

export async function fetchReportHoursPerMonth(
  pMonths: number,
): Promise<{ month: string; hours: number }[]> {
  const supabase = createClient();
  const { data, error } = await supabase.rpc("admin_report_hours_per_month", { p_months: pMonths });
  if (error) throw error;
  const rows = (data ?? []) as { month_label: string; hours: number | string }[];
  return rows.map((r) => ({
    month: r.month_label,
    hours: typeof r.hours === "string" ? parseFloat(r.hours) : Number(r.hours),
  }));
}

export async function fetchReportWageDistribution(): Promise<{ name: string; value: number }[]> {
  const supabase = createClient();
  const { data, error } = await supabase.rpc("admin_report_wage_distribution");
  if (error) throw error;
  const rows = (data ?? []) as { name: string; value: number | string }[];
  return rows.map((r) => ({
    name: r.name,
    value: typeof r.value === "string" ? parseFloat(r.value) : Number(r.value),
  }));
}

export async function fetchReportJobStatusDistribution(): Promise<{ name: string; value: number }[]> {
  const supabase = createClient();
  const { data, error } = await supabase.rpc("admin_report_job_status_distribution");
  if (error) throw error;
  const rows = (data ?? []) as { name: string; value: number | string }[];
  return rows.map((r) => ({
    name: r.name,
    value: typeof r.value === "string" ? parseInt(r.value, 10) : Number(r.value),
  }));
}

export async function fetchReportUserGrowth(
  pMonths: number,
): Promise<{ month: string; families: number; babysitters: number }[]> {
  const supabase = createClient();
  const { data, error } = await supabase.rpc("admin_report_user_growth", { p_months: pMonths });
  if (error) throw error;
  const rows = (data ?? []) as {
    month_label: string;
    families: number | string;
    babysitters: number | string;
  }[];
  return rows.map((r) => ({
    month: r.month_label,
    families: typeof r.families === "string" ? parseInt(r.families, 10) : Number(r.families),
    babysitters:
      typeof r.babysitters === "string" ? parseInt(r.babysitters, 10) : Number(r.babysitters),
  }));
}

export async function fetchReportCertStats(): Promise<ReportCertStats> {
  const supabase = createClient();
  const { data, error } = await supabase.rpc("admin_report_cert_stats");
  if (error) throw error;
  const row =
    typeof data === "string"
      ? (JSON.parse(data) as Record<string, unknown>)
      : ((data ?? {}) as Record<string, unknown>);
  return {
    approval_rate: num(row.approval_rate),
    avg_processing_days: num(row.avg_processing_days),
    most_popular_course: String(row.most_popular_course ?? "—"),
    most_popular_enrollments: num(row.most_popular_enrollments),
    decided_submissions: num(row.decided_submissions),
  };
}

/** Sitter ledger rows (earnings, withdrawals, adjustments) — RPC `admin_list_ledger_entries`. */
export type AdminLedgerRow = {
  id: string;
  sitter_id: string;
  sitter_name: string;
  sitter_email: string;
  entry_type: string;
  amount: number;
  reference_type: string | null;
  reference_id: string | null;
  balance_after: number;
  created_at: string;
};

export async function fetchAdminLedgerEntries(limit = 200): Promise<AdminLedgerRow[]> {
  const supabase = createClient();
  const { data, error } = await supabase.rpc("admin_list_ledger_entries", { p_limit: limit });
  if (error) throw error;
  const rows = (data ?? []) as {
    id: string;
    sitter_id: string;
    sitter_name: string;
    sitter_email: string;
    entry_type: string;
    amount: number | string;
    reference_type: string | null;
    reference_id: string | null;
    balance_after: number | string;
    created_at: string;
  }[];
  return rows.map((r) => ({
    id: r.id,
    sitter_id: r.sitter_id,
    sitter_name: r.sitter_name,
    sitter_email: r.sitter_email,
    entry_type: r.entry_type,
    amount: typeof r.amount === "string" ? parseFloat(r.amount) : Number(r.amount),
    reference_type: r.reference_type,
    reference_id: r.reference_id,
    balance_after:
      typeof r.balance_after === "string" ? parseFloat(r.balance_after) : Number(r.balance_after),
    created_at: r.created_at,
  }));
}

// --- Courses (RLS: admin write on public.courses) ---

export type CourseDbStatus = "published" | "draft" | "archived";

export type AdminCourseRow = {
  id: string;
  name: string;
  category: string;
  status: CourseDbStatus;
  description: string | null;
  modules: string[] | null;
  instructor: string | null;
  duration_hours: number | string | null;
  level: string | null;
  price: number | string;
  requirements: string | null;
  learning_objectives: string | null;
  provides_certificate: boolean;
  created_at: string;
  updated_at: string;
};

export type AdminCourseWithStats = AdminCourseRow & {
  submissions_count: number;
  completion_avg: number;
};

type SubAgg = { count: number; approved: number; sumScore: number };

function aggregateSubs(
  rows: { course_id: string; status: string; score: number | string | null }[],
): Record<string, SubAgg> {
  const m: Record<string, SubAgg> = {};
  for (const r of rows) {
    if (!m[r.course_id]) m[r.course_id] = { count: 0, approved: 0, sumScore: 0 };
    m[r.course_id].count += 1;
    if (r.status === "approved" && r.score != null) {
      const sc = typeof r.score === "string" ? parseFloat(r.score) : Number(r.score);
      if (!Number.isNaN(sc)) {
        m[r.course_id].approved += 1;
        m[r.course_id].sumScore += sc;
      }
    }
  }
  return m;
}

export async function fetchAdminCoursesWithStats(): Promise<AdminCourseWithStats[]> {
  const supabase = createClient();
  const { data: courses, error } = await supabase
    .from("courses")
    .select("*")
    .order("created_at", { ascending: false });
  if (error) throw error;

  const { data: subs, error: e2 } = await supabase
    .from("certification_submissions")
    .select("course_id, status, score");
  if (e2) throw e2;

  const agg = aggregateSubs((subs ?? []) as { course_id: string; status: string; score: number | null }[]);

  return ((courses ?? []) as AdminCourseRow[]).map((c) => {
    const a = agg[c.id] ?? { count: 0, approved: 0, sumScore: 0 };
    const completion_avg =
      a.approved > 0 ? Math.round((a.sumScore / a.approved) * 10) / 10 : 0;
    return {
      ...c,
      submissions_count: a.count,
      completion_avg,
    };
  });
}

export function courseUiStatusFromDb(s: string): "Active" | "Draft" | "Archived" {
  if (s === "published") return "Active";
  if (s === "archived") return "Archived";
  return "Draft";
}

export function courseDbStatusFromUi(s: "Active" | "Draft" | "Archived"): CourseDbStatus {
  if (s === "Active") return "published";
  if (s === "Archived") return "archived";
  return "draft";
}

export function courseCertTabStatusFromDb(s: string): "Published" | "Draft" | "Archived" {
  if (s === "published") return "Published";
  if (s === "archived") return "Archived";
  return "Draft";
}

export type AdminCourseInsert = {
  name: string;
  category: string;
  status: CourseDbStatus;
  description?: string | null;
  modules?: string[];
  instructor?: string | null;
  duration_hours?: number | null;
  level?: "Beginner" | "Intermediate" | "Advanced" | null;
  price?: number;
  requirements?: string | null;
  learning_objectives?: string | null;
  provides_certificate?: boolean;
  material_paths?: string[];
};

export async function adminInsertCourse(payload: AdminCourseInsert): Promise<string> {
  const supabase = createClient();
  const row = {
    name: payload.name,
    category: payload.category,
    status: payload.status,
    description: payload.description ?? null,
    modules: payload.modules ?? [],
    instructor: payload.instructor ?? null,
    duration_hours: payload.duration_hours ?? null,
    level: payload.level ?? null,
    price: payload.price ?? 0,
    requirements: payload.requirements ?? null,
    learning_objectives: payload.learning_objectives ?? null,
    provides_certificate: payload.provides_certificate ?? true,
    material_paths: payload.material_paths ?? [],
  };
  const { data, error } = await supabase.from("courses").insert(row).select("id").single();
  if (error) throw error;
  return (data as { id: string }).id;
}

export async function adminUploadCourseMaterial(
  courseId: string,
  file: File,
): Promise<string> {
  const supabase = createClient();
  const safeName = file.name.replace(/[^a-zA-Z0-9._-]/g, "_");
  const path = `${courseId}/${Date.now()}_${safeName}`;
  const { error } = await supabase.storage
    .from("course-materials")
    .upload(path, file, { upsert: false, contentType: file.type });
  if (error) throw error;
  return path;
}

export async function adminUpdateCourse(
  id: string,
  patch: Partial<AdminCourseInsert> & { status?: CourseDbStatus },
) {
  const supabase = createClient();
  const { error } = await supabase.from("courses").update(patch).eq("id", id);
  if (error) throw error;
}

export async function adminDeleteCourse(id: string) {
  const supabase = createClient();
  const { error } = await supabase.from("courses").delete().eq("id", id);
  if (error) throw error;
}

// --- Certification submissions (admin read via RLS) ---

export type CertificationSubmissionRow = {
  id: string;
  course_id: string;
  sitter_id: string;
  score: number | null;
  questions_answered: number | null;
  correct_answers: number | null;
  time_taken_seconds: number | null;
  status: "pending" | "approved" | "rejected";
  submitted_at: string;
  sitter:
    | { full_name: string | null; email: string }
    | { full_name: string | null; email: string }[]
    | null;
  course: { name: string } | { name: string }[] | null;
};

export async function fetchCertificationSubmissionsAdmin(): Promise<CertificationSubmissionRow[]> {
  const supabase = createClient();
  const { data, error } = await supabase
    .from("certification_submissions")
    .select(
      "id, course_id, sitter_id, score, questions_answered, correct_answers, time_taken_seconds, status, submitted_at",
    )
    .order("submitted_at", { ascending: false })
    .limit(200);
  if (error) throw error;

  type RawRow = {
    id: string;
    course_id: string;
    sitter_id: string;
    score: number | null;
    questions_answered: number | null;
    correct_answers: number | null;
    time_taken_seconds: number | null;
    status: CertificationSubmissionRow["status"];
    submitted_at: string;
  };

  const rows = (data ?? []) as unknown as RawRow[];
  if (rows.length === 0) return [];

  const userMap = await fetchUsersByIds(supabase, rows.map((r) => r.sitter_id));
  const courseMap = await fetchCoursesByIds(supabase, rows.map((r) => r.course_id));

  return rows.map((r) => {
    const u = userMap.get(r.sitter_id);
    const sitter: CertificationSubmissionRow["sitter"] = u
      ? { full_name: u.full_name, email: u.email }
      : null;
    const c = courseMap.get(r.course_id);
    const course: CertificationSubmissionRow["course"] = c ? { name: c.name } : null;
    return {
      id: r.id,
      course_id: r.course_id,
      sitter_id: r.sitter_id,
      score: r.score,
      questions_answered: r.questions_answered,
      correct_answers: r.correct_answers,
      time_taken_seconds: r.time_taken_seconds,
      status: r.status,
      submitted_at: r.submitted_at,
      sitter,
      course,
    };
  });
}
