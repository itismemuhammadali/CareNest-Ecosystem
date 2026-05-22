-- Star Sitters — RLS (BACKEND.md §6)
-- 20260501000012_rls_policies.sql

-- ============================================================
-- Enable RLS on all tables
-- ============================================================
alter table public.users enable row level security;
alter table public.family_profiles enable row level security;
alter table public.children enable row level security;
alter table public.background_checks enable row level security;
alter table public.sitter_profiles enable row level security;
alter table public.guardian_consents enable row level security;
alter table public.certifications enable row level security;
alter table public.jobs enable row level security;
alter table public.applications enable row level security;
alter table public.hires enable row level security;
alter table public.age_wage_tiers enable row level security;
alter table public.time_entries enable row level security;
alter table public.system_config enable row level security;
alter table public.conversations enable row level security;
alter table public.messages enable row level security;
alter table public.wallets enable row level security;
alter table public.ledger_entries enable row level security;
alter table public.withdrawal_requests enable row level security;
alter table public.devices enable row level security;
alter table public.notifications enable row level security;
alter table public.admin_users enable row level security;
alter table public.audit_logs enable row level security;

-- ============================================================
-- Helper functions used by RLS policies below.
--
-- current_user_role() — pulls the row from public.users for the current JWT.
-- is_admin()          — alias for admin_only_bool() defined in Migration 12;
--                       kept for backward-compatibility because the rest of
--                       this file's RLS policies were written before the
--                       admin_only() consolidation. Both helpers query the
--                       same table (public.admin_users) so they always agree.
--                       New code should call admin_only_bool() directly.
-- ============================================================
create or replace function public.current_user_role()
returns public.user_role language sql stable security definer
set search_path = public as $$
  select role from public.users where id = auth.uid();
$$;

create or replace function public.is_admin()
returns boolean language sql stable security definer
set search_path = public as $$
  -- Single source of truth: admin_users membership.
  -- Equivalent to public.admin_only_bool().
  select exists (
    select 1 from public.admin_users where id = auth.uid()
  );
$$;

-- ============================================================
-- USERS
-- ============================================================
-- Anyone can read their own row
create policy "users: select own"
  on public.users for select
  using (id = auth.uid());

-- Admins can read all users
create policy "users: admin select all"
  on public.users for select
  using (public.is_admin());

-- Users may update their own row, but the role column is locked at the
-- trigger level (Migration 13: trg_users_role_immutable) and the email
-- column is owned by Supabase Auth — clients should call auth.updateUser()
-- to change email, never write directly to public.users.email.
--
-- Defense in depth: even though the trigger blocks role escalation, we keep
-- the RLS policy narrow by requiring id = auth.uid() (no row hijack) and
-- documenting the safe-write columns here.
--
-- Safe to write from a client: full_name, phone, avatar_url
-- Locked at DB level: role (trigger), email (managed by Auth), updated_at (trigger)
create policy "users: update own"
  on public.users for update
  using (id = auth.uid())
  with check (id = auth.uid());

-- ============================================================
-- FAMILY PROFILES
-- ============================================================
create policy "family_profiles: select own"
  on public.family_profiles for select
  using (user_id = auth.uid());

-- Sitters can see limited family info for jobs they applied to
create policy "family_profiles: sitter sees relevant families"
  on public.family_profiles for select
  using (
    public.current_user_role() = 'sitter'
    and exists (
      select 1 from public.jobs j
      join public.applications a on a.job_id = j.id
      where j.family_id = family_profiles.user_id
        and a.sitter_id = auth.uid()
    )
  );

create policy "family_profiles: admin select all"
  on public.family_profiles for select
  using (public.is_admin());

create policy "family_profiles: insert own"
  on public.family_profiles for insert
  with check (user_id = auth.uid());

-- Families may update their own profile row. The bg_check_status column
-- (added in §31.6) is locked at the trigger level by trg_family_lock_admin_fields
-- (Migration 13) — only admin RPCs may flip it.
--
-- Safe for a family to write: address fields, contact fields.
-- Admin-only: bg_check_status.
create policy "family_profiles: update own"
  on public.family_profiles for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- ============================================================
-- CHILDREN
-- ============================================================
create policy "children: family select own"
  on public.children for select
  using (
    family_id = auth.uid()
  );

create policy "children: admin select all"
  on public.children for select
  using (public.is_admin());

create policy "children: family insert"
  on public.children for insert
  with check (family_id = auth.uid());

create policy "children: family update own"
  on public.children for update
  using (family_id = auth.uid())
  with check (family_id = auth.uid());

create policy "children: family delete own"
  on public.children for delete
  using (family_id = auth.uid());

-- ============================================================
-- BACKGROUND CHECKS
-- ============================================================
create policy "bg_checks: family select own"
  on public.background_checks for select
  using (family_id = auth.uid());

create policy "bg_checks: admin select all"
  on public.background_checks for select
  using (public.is_admin());

create policy "bg_checks: family insert own"
  on public.background_checks for insert
  with check (family_id = auth.uid());

-- Admin updates via admin_approve_bg_check() RPC only — direct update denied
-- No update policy for non-admins
create policy "bg_checks: admin update"
  on public.background_checks for update
  using (public.is_admin());

-- ============================================================
-- SITTER PROFILES
-- ============================================================
create policy "sitter_profiles: select own"
  on public.sitter_profiles for select
  using (user_id = auth.uid());

-- Families can see public sitter data for active sitters
create policy "sitter_profiles: family sees active sitters"
  on public.sitter_profiles for select
  using (
    public.current_user_role() = 'family'
    and is_active = true
  );

create policy "sitter_profiles: admin select all"
  on public.sitter_profiles for select
  using (public.is_admin());

create policy "sitter_profiles: insert own"
  on public.sitter_profiles for insert
  with check (user_id = auth.uid());

-- Sitters may update their own profile row, BUT the privileged columns
-- (is_active, guardian_consent_status, total_minutes_worked, total_earnings)
-- are locked at the trigger level by trg_sitter_lock_admin_fields (Migration 13).
-- That trigger calls admin_only_bool() and raises 42501 if any of those
-- columns change for a non-admin caller. So this RLS policy can stay broad —
-- the trigger is the column-level gate.
--
-- Safe for a sitter to write: bio, date_of_birth (within age constraint).
-- Admin-only (via admin_*  RPCs that bypass the trigger because they run
-- with admin_only_bool() = true): is_active, guardian_consent_status,
-- total_minutes_worked, total_earnings (the last two are also written by
-- the fn_update_sitter_totals trigger, which is SECURITY DEFINER).
create policy "sitter_profiles: update own"
  on public.sitter_profiles for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "sitter_profiles: admin update"
  on public.sitter_profiles for update
  using (public.is_admin());

-- ============================================================
-- GUARDIAN CONSENTS
-- ============================================================
-- Sitter can see their own consent record but NOT the consent_token
-- (token is in the row but we never SELECT it in the Flutter query — rely on column-level)
create policy "guardian_consents: sitter select own"
  on public.guardian_consents for select
  using (sitter_id = auth.uid());

create policy "guardian_consents: admin select all"
  on public.guardian_consents for select
  using (public.is_admin());

create policy "guardian_consents: sitter insert own"
  on public.guardian_consents for insert
  with check (sitter_id = auth.uid());

-- Consent update happens via Edge Function with service_role key (bypasses RLS)
-- No client update policy

-- ============================================================
-- CERTIFICATIONS
-- ============================================================
create policy "certifications: sitter select own"
  on public.certifications for select
  using (sitter_id = auth.uid());

-- Families can see approved certs of sitters who applied to their jobs
create policy "certifications: family sees approved certs"
  on public.certifications for select
  using (
    public.current_user_role() = 'family'
    and status = 'approved'
    and exists (
      select 1 from public.applications a
      join public.jobs j on j.id = a.job_id
      where a.sitter_id = certifications.sitter_id
        and j.family_id = auth.uid()
    )
  );

create policy "certifications: admin select all"
  on public.certifications for select
  using (public.is_admin());

create policy "certifications: sitter insert own"
  on public.certifications for insert
  with check (sitter_id = auth.uid());

create policy "certifications: admin update"
  on public.certifications for update
  using (public.is_admin());

-- ============================================================
-- JOBS
-- ============================================================
create policy "jobs: family select own"
  on public.jobs for select
  using (family_id = auth.uid());

-- Sitters see open jobs from approved families only
create policy "jobs: sitter sees open jobs"
  on public.jobs for select
  using (
    public.current_user_role() = 'sitter'
    and status = 'open'
    and exists (
      select 1 from public.family_profiles fp
      where fp.user_id = jobs.family_id
        and fp.bg_check_status = 'approved'
    )
  );

create policy "jobs: admin select all"
  on public.jobs for select
  using (public.is_admin());

-- Family creates jobs only when bg_check is approved
create policy "jobs: family insert"
  on public.jobs for insert
  with check (
    family_id = auth.uid()
    and exists (
      select 1 from public.family_profiles fp
      where fp.user_id = auth.uid()
        and fp.bg_check_status = 'approved'
    )
  );

create policy "jobs: family update own"
  on public.jobs for update
  using (family_id = auth.uid())
  with check (family_id = auth.uid());

-- ============================================================
-- APPLICATIONS
-- ============================================================
create policy "applications: sitter select own"
  on public.applications for select
  using (sitter_id = auth.uid());

create policy "applications: family sees own job applications"
  on public.applications for select
  using (
    exists (
      select 1 from public.jobs j
      where j.id = applications.job_id
        and j.family_id = auth.uid()
    )
  );

create policy "applications: admin select all"
  on public.applications for select
  using (public.is_admin());

-- Applications are created only via create_application() RPC — direct insert denied
-- (The RPC runs SECURITY DEFINER and validates sitter is_active)

-- ============================================================
-- HIRES
-- ============================================================
create policy "hires: family sees own job hires"
  on public.hires for select
  using (
    exists (
      select 1 from public.jobs j
      where j.id = hires.job_id
        and j.family_id = auth.uid()
    )
  );

create policy "hires: sitter sees own hires"
  on public.hires for select
  using (sitter_id = auth.uid());

create policy "hires: admin select all"
  on public.hires for select
  using (public.is_admin());

-- Hires created only via create_hire() RPC — direct insert denied

-- ============================================================
-- AGE WAGE TIERS
-- ============================================================
-- All authenticated users can read wage tiers (used for wage preview)
create policy "age_wage_tiers: authenticated read"
  on public.age_wage_tiers for select
  using (auth.uid() is not null);

-- Only admins can insert/update
create policy "age_wage_tiers: admin write"
  on public.age_wage_tiers for all
  using (public.is_admin())
  with check (public.is_admin());

-- ============================================================
-- TIME ENTRIES
-- ============================================================
create policy "time_entries: sitter select own"
  on public.time_entries for select
  using (sitter_id = auth.uid());

create policy "time_entries: family sees entries for their hires"
  on public.time_entries for select
  using (
    exists (
      select 1 from public.hires h
      join public.jobs j on j.id = h.job_id
      where h.id = time_entries.hire_id
        and j.family_id = auth.uid()
    )
  );

create policy "time_entries: admin select all"
  on public.time_entries for select
  using (public.is_admin());

-- No direct inserts/updates by clients — all via clock_in / clock_out RPCs

-- ============================================================
-- SYSTEM CONFIG
-- ============================================================
-- All authenticated users can read config (some values like min wage rate are public)
create policy "system_config: authenticated read"
  on public.system_config for select
  using (auth.uid() is not null);

-- Only admins can write
create policy "system_config: admin write"
  on public.system_config for all
  using (public.is_admin())
  with check (public.is_admin());

-- ============================================================
-- CONVERSATIONS
-- ============================================================
create policy "conversations: participants select"
  on public.conversations for select
  using (
    family_id = auth.uid()
    or sitter_id = auth.uid()
  );

create policy "conversations: admin select all"
  on public.conversations for select
  using (public.is_admin());

-- Conversations created only via create_hire() RPC — direct insert denied

-- ============================================================
-- MESSAGES
-- ============================================================
create policy "messages: participants select"
  on public.messages for select
  using (
    exists (
      select 1 from public.conversations c
      where c.id = messages.conversation_id
        and (c.family_id = auth.uid() or c.sitter_id = auth.uid())
    )
  );

create policy "messages: participants insert"
  on public.messages for insert
  with check (
    sender_id = auth.uid()
    and exists (
      select 1 from public.conversations c
      where c.id = messages.conversation_id
        and (c.family_id = auth.uid() or c.sitter_id = auth.uid())
    )
  );

-- Messages are never updated or deleted (immutable)

-- ============================================================
-- WALLETS
-- ============================================================
create policy "wallets: sitter select own"
  on public.wallets for select
  using (sitter_id = auth.uid());

create policy "wallets: admin select all"
  on public.wallets for select
  using (public.is_admin());

-- No client writes to wallets — updated only by clock_out and admin_pay_withdrawal RPCs

-- ============================================================
-- LEDGER ENTRIES
-- ============================================================
create policy "ledger_entries: sitter select own"
  on public.ledger_entries for select
  using (sitter_id = auth.uid());

create policy "ledger_entries: admin select all"
  on public.ledger_entries for select
  using (public.is_admin());

-- Ledger entries are append-only, written only by server RPCs

-- ============================================================
-- WITHDRAWAL REQUESTS
-- ============================================================
create policy "withdrawal_requests: sitter select own"
  on public.withdrawal_requests for select
  using (sitter_id = auth.uid());

create policy "withdrawal_requests: admin select all"
  on public.withdrawal_requests for select
  using (public.is_admin());

-- Sitter creates request via request_withdrawal() RPC
-- Admin marks paid via admin_pay_withdrawal() RPC

-- ============================================================
-- DEVICES (FCM tokens)
-- ============================================================
create policy "devices: user select own"
  on public.devices for select
  using (user_id = auth.uid());

create policy "devices: user upsert own"
  on public.devices for insert
  with check (user_id = auth.uid());

create policy "devices: user update own"
  on public.devices for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "devices: user delete own"
  on public.devices for delete
  using (user_id = auth.uid());

-- ============================================================
-- NOTIFICATIONS
-- ============================================================
create policy "notifications: user select own"
  on public.notifications for select
  using (user_id = auth.uid());

-- Mark as read — users can update read_at on their own notifications only
create policy "notifications: user update own read_at"
  on public.notifications for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- Notifications are created only by server (Edge Functions with service_role)

-- ============================================================
-- ADMIN USERS
-- ============================================================
create policy "admin_users: admin select all"
  on public.admin_users for select
  using (public.is_admin());

-- ============================================================
-- AUDIT LOGS
-- ============================================================
create policy "audit_logs: admin select all"
  on public.audit_logs for select
  using (public.is_admin());

-- audit_logs: no update, no delete for anyone (append-only enforced by no policies)
