"use client";

import React, { useCallback, useEffect, useState } from "react";
import {
  adminUpdateSystemConfig,
  fetchAuditLogs,
  fetchOwnAdminMembership,
  fetchSystemConfigRows,
  type AdminMembershipRow,
  type AuditLogAdminRow,
  type SystemConfigRow,
} from "@/lib/supabase/admin";
import { createClient } from "@/lib/supabase/client";
import { formatSupabaseError } from "@/lib/supabase/errors";
import {
  Settings as SettingsIcon,
  Users,
  Shield,
  Database,
  History,
  ChevronDown,
  Save,
} from "lucide-react";

type SettingsTab = "platform" | "security" | "data" | "audit";

function cfgBool(rows: SystemConfigRow[], key: string, fallback: boolean) {
  const v = rows.find((r) => r.key === key)?.value;
  if (typeof v === "boolean") return v;
  if (v === "true" || v === true) return true;
  if (v === "false" || v === false) return false;
  return fallback;
}

function cfgNum(rows: SystemConfigRow[], key: string, fallback: number) {
  const v = rows.find((r) => r.key === key)?.value;
  if (typeof v === "number" && !Number.isNaN(v)) return v;
  const n = Number(v);
  return Number.isNaN(n) ? fallback : n;
}

function cfgText(rows: SystemConfigRow[], key: string, fallback: string) {
  const v = rows.find((r) => r.key === key)?.value;
  if (typeof v === "string") return v;
  if (v != null && typeof v === "object") return JSON.stringify(v);
  return fallback;
}

export default function SettingsPage() {
  const [activeTab, setActiveTab] = useState<SettingsTab>("platform");
  const [configLoading, setConfigLoading] = useState(true);
  const [configError, setConfigError] = useState<string | null>(null);
  const [saveBusy, setSaveBusy] = useState<string | null>(null);
  const [saveOkMessage, setSaveOkMessage] = useState<string | null>(null);
  const [auditRows, setAuditRows] = useState<AuditLogAdminRow[]>([]);
  const [auditLoading, setAuditLoading] = useState(false);
  const [auditError, setAuditError] = useState<string | null>(null);
  const [adminMembership, setAdminMembership] = useState<AdminMembershipRow | null>(null);
  const [adminDisplayName, setAdminDisplayName] = useState<string>("");
  const [adminMembershipLoading, setAdminMembershipLoading] = useState(true);
  const [adminMembershipError, setAdminMembershipError] = useState<string | null>(null);

  // Platform tab state
  const [systemNotifications, setSystemNotifications] = useState(true);
  const [autoVerification, setAutoVerification] = useState(false);
  const [minAge, setMinAge] = useState("11 years");
  const [maxDuration, setMaxDuration] = useState("8 hours");
  const [gpsTracking, setGpsTracking] = useState("Required");

  // Security tab state
  const [twoFactor, setTwoFactor] = useState(true);
  const [sessionTimeout, setSessionTimeout] = useState("30");
  const [loginAttempts, setLoginAttempts] = useState("5 attempts");

  // Data tab state
  const [retentionMonths, setRetentionMonths] = useState("24");
  const [autoCleanup, setAutoCleanup] = useState("Enabled");
  const [backupFrequency, setBackupFrequency] = useState("Daily");

  const applyConfigRows = useCallback((rows: SystemConfigRow[]) => {
    setSystemNotifications(cfgBool(rows, "system_notifications_enabled", true));
    setAutoVerification(cfgBool(rows, "auto_verification_enabled", false));
    const minY = cfgNum(rows, "min_sitter_age", 13);
    setMinAge(`${minY} years`);
    const maxH = cfgNum(rows, "max_job_duration_hours", 8);
    setMaxDuration(`${maxH} hours`);
    const gps = cfgText(rows, "gps_tracking_mode", "required").toLowerCase();
    if (gps === "optional") setGpsTracking("Optional");
    else if (gps === "disabled") setGpsTracking("Disabled");
    else setGpsTracking("Required");

    setTwoFactor(cfgBool(rows, "admin_two_factor_ui_enabled", true));
    setSessionTimeout(String(cfgNum(rows, "session_timeout_minutes", 30)));
    const attempts = cfgNum(rows, "max_login_attempts", 5);
    setLoginAttempts(`${attempts} attempts`);

    setRetentionMonths(String(cfgNum(rows, "data_retention_months", 24)));
    setAutoCleanup(cfgBool(rows, "data_auto_cleanup_enabled", false) ? "Enabled" : "Disabled");
    const bf = cfgText(rows, "backup_frequency", "Daily").replace(/^"|"$/g, "");
    setBackupFrequency(["Hourly", "Daily", "Weekly", "Monthly"].includes(bf) ? bf : "Daily");
  }, []);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      setConfigLoading(true);
      setConfigError(null);
      try {
        const rows = await fetchSystemConfigRows();
        if (!cancelled) applyConfigRows(rows);
      } catch (e) {
        if (!cancelled) setConfigError(formatSupabaseError(e));
      } finally {
        if (!cancelled) setConfigLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [applyConfigRows]);

  useEffect(() => {
    setSaveOkMessage(null);
  }, [activeTab]);

  useEffect(() => {
    let cancelled = false;
    void (async () => {
      setAdminMembershipLoading(true);
      setAdminMembershipError(null);
      try {
        const supabase = createClient();
        const { data: auth } = await supabase.auth.getUser();
        const uid = auth.user?.id;
        if (!uid) {
          if (!cancelled) {
            setAdminMembership(null);
            setAdminDisplayName("");
          }
          return;
        }
        const [mem, profile] = await Promise.all([
          fetchOwnAdminMembership(),
          supabase.from("users").select("full_name,email").eq("id", uid).maybeSingle(),
        ]);
        if (cancelled) return;
        setAdminMembership(mem);
        const row = profile.data;
        const name =
          row?.full_name?.trim() ||
          (typeof auth.user?.user_metadata?.full_name === "string"
            ? auth.user.user_metadata.full_name.trim()
            : "") ||
          row?.email ||
          auth.user?.email ||
          "Admin";
        setAdminDisplayName(name);
      } catch (e) {
        if (!cancelled) setAdminMembershipError(formatSupabaseError(e));
      } finally {
        if (!cancelled) setAdminMembershipLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  useEffect(() => {
    if (activeTab !== "audit") return;
    let cancelled = false;
    (async () => {
      setAuditLoading(true);
      setAuditError(null);
      try {
        const rows = await fetchAuditLogs(100);
        if (!cancelled) setAuditRows(rows);
      } catch (e) {
        if (!cancelled) {
          setAuditRows([]);
          setAuditError(formatSupabaseError(e));
        }
      } finally {
        if (!cancelled) setAuditLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [activeTab]);

  const savePlatform = async () => {
    setSaveBusy("platform");
    setConfigError(null);
    setSaveOkMessage(null);
    try {
      const minY = parseInt(minAge, 10);
      const maxH = parseInt(maxDuration, 10);
      const gps =
        gpsTracking === "Optional"
          ? "optional"
          : gpsTracking === "Disabled"
            ? "disabled"
            : "required";
      await adminUpdateSystemConfig({
        system_notifications_enabled: systemNotifications,
        auto_verification_enabled: autoVerification,
        min_sitter_age: Number.isFinite(minY) ? minY : 13,
        max_job_duration_hours: Number.isFinite(maxH) ? maxH : 8,
        gps_tracking_mode: gps,
      });
      const rows = await fetchSystemConfigRows();
      applyConfigRows(rows);
      setSaveOkMessage("Platform settings saved.");
    } catch (e) {
      setConfigError(formatSupabaseError(e));
    } finally {
      setSaveBusy(null);
    }
  };

  const saveSecurity = async () => {
    setSaveBusy("security");
    setConfigError(null);
    setSaveOkMessage(null);
    try {
      const attempts = parseInt(loginAttempts, 10);
      await adminUpdateSystemConfig({
        admin_two_factor_ui_enabled: twoFactor,
        session_timeout_minutes: parseInt(sessionTimeout, 10) || 30,
        max_login_attempts: Number.isFinite(attempts) ? attempts : 5,
      });
      const rows = await fetchSystemConfigRows();
      applyConfigRows(rows);
      setSaveOkMessage("Security settings saved.");
    } catch (e) {
      setConfigError(formatSupabaseError(e));
    } finally {
      setSaveBusy(null);
    }
  };

  const saveData = async () => {
    setSaveBusy("data");
    setConfigError(null);
    setSaveOkMessage(null);
    try {
      const months = parseInt(retentionMonths, 10) || 24;
      await adminUpdateSystemConfig({
        data_retention_months: months,
        data_auto_cleanup_enabled: autoCleanup === "Enabled",
        backup_frequency: backupFrequency,
      });
      const rows = await fetchSystemConfigRows();
      applyConfigRows(rows);
      setSaveOkMessage("Data settings saved.");
    } catch (e) {
      setConfigError(formatSupabaseError(e));
    } finally {
      setSaveBusy(null);
    }
  };

  return (
    <div className="space-y-6">
      {/* Page header */}
      <div>
        <h1 className="text-[32px] leading-[40px] font-bold text-white">
          System Settings
        </h1>
        <p className="mt-1 text-[15px] text-[#94a3b8]">
          Configure platform rules, security, and administrative controls
        </p>
        {configLoading && (
          <p className="mt-2 text-[13px] text-[#94a3b8]">Loading configuration…</p>
        )}
        {configError && (
          <p className="mt-2 text-[13px] text-red-400" role="alert">
            {configError}
          </p>
        )}
        {saveOkMessage && !configError && (
          <p className="mt-2 text-[13px] text-[#86efac]" role="status">
            {saveOkMessage}
          </p>
        )}
      </div>

      {/* Tabs */}
      <div className="inline-flex gap-2 bg-[#0f172a]/60 border border-[#334155]/50 rounded-full p-1.5">
        <TabButton
          label="Platform"
          active={activeTab === "platform"}
          onClick={() => setActiveTab("platform")}
        />
        <TabButton
          label="Security"
          active={activeTab === "security"}
          onClick={() => setActiveTab("security")}
        />
        <TabButton
          label="Data"
          active={activeTab === "data"}
          onClick={() => setActiveTab("data")}
        />
        <TabButton
          label="Audit Log"
          active={activeTab === "audit"}
          onClick={() => setActiveTab("audit")}
        />
      </div>

      {/* Platform tab */}
      {activeTab === "platform" && (
        <div className="space-y-6">
          <SectionCard
            iconColor="cyan"
            icon={SettingsIcon}
            title="Platform Rules"
            description="Configure general platform behavior and rules"
          >
            <div className="space-y-3">
              <ToggleSetting
                title="System Notifications"
                description="Enable automated notifications for platform events"
                checked={systemNotifications}
                onChange={setSystemNotifications}
              />
              <ToggleSetting
                title="Auto-Verification"
                description="Automatically approve low-risk verifications"
                checked={autoVerification}
                onChange={setAutoVerification}
              />
              <SelectSetting
                title="Minimum Babysitter Age"
                description="Minimum age required to register as a babysitter"
                value={minAge}
                onChange={setMinAge}
                options={["11 years", "12 years", "13 years", "14 years", "15 years"]}
              />
              <SelectSetting
                title="Maximum Job Duration"
                description="Maximum allowed duration for a single job"
                value={maxDuration}
                onChange={setMaxDuration}
                options={["4 hours", "6 hours", "8 hours", "10 hours", "12 hours"]}
              />
              <SelectSetting
                title="GPS Tracking"
                description="GPS location verification for clock in/out"
                value={gpsTracking}
                onChange={setGpsTracking}
                options={["Required", "Optional", "Disabled"]}
              />
            </div>
            <SaveButton
              label="Save Platform Settings"
              busy={saveBusy === "platform"}
              onClick={savePlatform}
            />
          </SectionCard>

          <SectionCard
            iconColor="purple"
            icon={Users}
            title="Role-Based Access Control"
            description="Your admin membership (from admin_users)"
          >
            <div className="space-y-3">
              {adminMembershipLoading ? (
                <p className="text-[14px] text-[#94a3b8]">Loading…</p>
              ) : adminMembershipError ? (
                <p role="alert" className="text-[14px] text-red-300">
                  {adminMembershipError}
                </p>
              ) : adminMembership ? (
                <RoleRow
                  name={adminDisplayName || "Admin"}
                  description="Platform administrator"
                  permissions={
                    adminMembership.permissions.length > 0
                      ? adminMembership.permissions.join(", ")
                      : "Default access (empty permissions array — full admin via membership)"
                  }
                  activeCount={1}
                />
              ) : (
                <p className="text-[14px] text-amber-200">
                  No admin_users row for this account. Ask a DBA to insert your user id into
                  admin_users.
                </p>
              )}
            </div>
          </SectionCard>
        </div>
      )}

      {/* Security tab */}
      {activeTab === "security" && (
        <div className="space-y-6">
          <SectionCard
            iconColor="green"
            icon={Shield}
            title="Security Settings"
            description="Configure security policies and authentication"
          >
            <div className="space-y-3">
              <ToggleSetting
                title="Two-Factor Authentication"
                description="Require 2FA for all admin accounts"
                checked={twoFactor}
                onChange={setTwoFactor}
              />
              <NumberWithSuffixSetting
                title="Session Timeout"
                value={sessionTimeout}
                onChange={setSessionTimeout}
                suffix="minutes of inactivity"
                description="Auto-logout after specified time"
              />
              <PasswordPolicySetting
                items={[
                  "Minimum 8 characters",
                  "Require uppercase and lowercase",
                  "Require numbers and special characters",
                  "Password expiry: 90 days",
                ]}
              />
              <SelectSetting
                title="Login Attempt Limits"
                description="Lock account after failed attempts"
                value={loginAttempts}
                onChange={setLoginAttempts}
                options={["3 attempts", "5 attempts", "10 attempts"]}
              />
            </div>
            <SaveButton
              label="Save Security Settings"
              busy={saveBusy === "security"}
              onClick={saveSecurity}
            />
          </SectionCard>
        </div>
      )}

      {/* Data tab */}
      {activeTab === "data" && (
        <div className="space-y-6">
          <SectionCard
            iconColor="purple"
            icon={Database}
            title="Data Management"
            description="Configure data retention and privacy policies"
          >
            <div className="space-y-3">
              <NumberWithSuffixSetting
                title="Data Retention Period"
                value={retentionMonths}
                onChange={setRetentionMonths}
                suffix="months"
                description="How long to retain user data after account deletion"
              />
              <SelectSetting
                title="Automated Data Cleanup"
                description="Automatically delete data after retention period"
                value={autoCleanup}
                onChange={setAutoCleanup}
                options={["Enabled", "Disabled"]}
              />
              <SelectSetting
                title="Backup Frequency"
                description="Automated database backup schedule"
                value={backupFrequency}
                onChange={setBackupFrequency}
                options={["Hourly", "Daily", "Weekly", "Monthly"]}
              />
              <EncryptionStatusBlock
                rows={[
                  { label: "Data at Rest", status: "Encrypted" },
                  { label: "Data in Transit", status: "SSL/TLS" },
                  { label: "Payment Data", status: "PCI Compliant" },
                ]}
              />
            </div>
            <SaveButton
              label="Save Data Settings"
              busy={saveBusy === "data"}
              onClick={saveData}
            />
          </SectionCard>
        </div>
      )}

      {/* Audit Log tab */}
      {activeTab === "audit" && (
        <div className="space-y-6">
          <SectionCard
            iconColor="blue"
            icon={History}
            title="Audit Log"
            description="Complete history of administrative actions"
          >
            {auditError ? (
              <p className="text-[14px] text-red-400" role="alert">
                {auditError}
              </p>
            ) : auditLoading ? (
              <p className="text-[14px] text-[#94a3b8]">Loading audit log…</p>
            ) : (
              <AuditLogTable rows={auditRows} />
            )}
          </SectionCard>
        </div>
      )}
    </div>
  );
}

function TabButton({
  label,
  active,
  onClick,
}: {
  label: string;
  active: boolean;
  onClick: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`h-[40px] px-7 rounded-full text-[14px] font-medium transition-all ${
        active
          ? "bg-[#1e293b]/80 border border-white/10 text-white"
          : "bg-transparent border border-transparent text-[#94a3b8] hover:text-white hover:bg-white/5"
      }`}
    >
      {label}
    </button>
  );
}

type IconAccent = "cyan" | "purple" | "green" | "blue";

const accentMap: Record<
  IconAccent,
  { bg: string; border: string; text: string }
> = {
  cyan: {
    bg: "bg-[#b8e0f0]/10",
    border: "border-[#b8e0f0]/20",
    text: "text-[#b8e0f0]",
  },
  purple: {
    bg: "bg-[#a78bfa]/10",
    border: "border-[#a78bfa]/20",
    text: "text-[#c4b5fd]",
  },
  green: {
    bg: "bg-[#86efac]/10",
    border: "border-[#86efac]/20",
    text: "text-[#86efac]",
  },
  blue: {
    bg: "bg-[#3b82f6]/10",
    border: "border-[#3b82f6]/20",
    text: "text-[#60a5fa]",
  },
};

function SectionCard({
  icon: Icon,
  iconColor,
  title,
  description,
  children,
}: {
  icon: React.ComponentType<{ className?: string; strokeWidth?: number }>;
  iconColor: IconAccent;
  title: string;
  description: string;
  children: React.ReactNode;
}) {
  const accent = accentMap[iconColor];
  return (
    <section className="bg-[#1e293b]/60 backdrop-blur-md border border-white/10 rounded-2xl p-6 shadow-[0_24px_60px_-30px_rgba(0,0,0,0.6)]">
      <div className="flex items-start gap-3 mb-6">
        <div
          className={`flex-shrink-0 w-10 h-10 rounded-[10px] ${accent.bg} border ${accent.border} flex items-center justify-center`}
        >
          <Icon className={`w-[18px] h-[18px] ${accent.text}`} strokeWidth={1.75} />
        </div>
        <div>
          <h2 className="text-[18px] leading-[26px] font-semibold text-white">
            {title}
          </h2>
          <p className="mt-0.5 text-[14px] text-[#94a3b8]">{description}</p>
        </div>
      </div>
      {children}
    </section>
  );
}

function SaveButton({
  label,
  onClick,
  busy,
}: {
  label: string;
  onClick?: () => void | Promise<void>;
  busy?: boolean;
}) {
  return (
    <div className="mt-6">
      <button
        type="button"
        disabled={busy || !onClick}
        onClick={() => void onClick?.()}
        className="inline-flex items-center gap-2 h-[44px] px-5 bg-[#86efac] hover:bg-[#6ee7b7] disabled:opacity-50 text-[#064e3b] text-[14px] font-semibold rounded-[10px] transition-all"
      >
        <Save className="w-[16px] h-[16px]" strokeWidth={2.25} />
        {busy ? "Saving…" : label}
      </button>
    </div>
  );
}

function ToggleSetting({
  title,
  description,
  checked,
  onChange,
}: {
  title: string;
  description: string;
  checked: boolean;
  onChange: (next: boolean) => void;
}) {
  return (
    <div className="bg-[#0f172a]/60 border border-white/10 rounded-[12px] px-5 py-4 flex items-center justify-between gap-4">
      <div className="min-w-0">
        <p className="text-[15px] font-medium text-white">{title}</p>
        <p className="mt-0.5 text-[13px] text-[#94a3b8]">{description}</p>
      </div>
      <button
        type="button"
        role="switch"
        aria-checked={checked}
        onClick={() => onChange(!checked)}
        className={`relative flex-shrink-0 w-[44px] h-[24px] rounded-full transition-colors ${
          checked ? "bg-[#b8e0f0]" : "bg-[#334155]"
        }`}
      >
        <span
          className={`absolute top-[2px] w-5 h-5 bg-white rounded-full shadow-sm transition-all ${
            checked ? "left-[22px]" : "left-[2px]"
          }`}
        />
      </button>
    </div>
  );
}

function SelectSetting({
  title,
  description,
  value,
  onChange,
  options,
}: {
  title: string;
  description: string;
  value: string;
  onChange: (next: string) => void;
  options: string[];
}) {
  return (
    <div className="bg-[#0f172a]/60 border border-white/10 rounded-[12px] px-5 py-4">
      <p className="text-[15px] font-medium text-white mb-3">{title}</p>
      <div className="relative">
        <select
          value={value}
          onChange={(e) => onChange(e.target.value)}
          className="appearance-none w-full h-[44px] bg-[#0f172a]/80 border border-[#334155]/60 rounded-[10px] pl-4 pr-10 text-[14px] text-white focus:outline-none focus:border-[#b8e0f0]/60 focus:ring-2 focus:ring-[#b8e0f0]/15 transition-all"
        >
          {options.map((opt) => (
            <option key={opt} value={opt}>
              {opt}
            </option>
          ))}
        </select>
        <ChevronDown className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-[#64748b] pointer-events-none" />
      </div>
      <p className="mt-2 text-[13px] text-[#94a3b8]">{description}</p>
    </div>
  );
}

function NumberWithSuffixSetting({
  title,
  value,
  onChange,
  suffix,
  description,
}: {
  title: string;
  value: string;
  onChange: (next: string) => void;
  suffix: string;
  description: string;
}) {
  return (
    <div className="bg-[#0f172a]/60 border border-white/10 rounded-[12px] px-5 py-4">
      <p className="text-[15px] font-medium text-white mb-3">{title}</p>
      <div className="flex items-center gap-3">
        <input
          type="number"
          value={value}
          onChange={(e) => onChange(e.target.value)}
          className="w-[120px] h-[44px] bg-[#0f172a]/80 border border-[#334155]/60 rounded-[10px] px-4 text-[14px] text-white focus:outline-none focus:border-[#b8e0f0]/60 focus:ring-2 focus:ring-[#b8e0f0]/15 transition-all"
        />
        <span className="text-[14px] text-[#cbd5e1]">{suffix}</span>
      </div>
      <p className="mt-3 text-[13px] text-[#94a3b8]">{description}</p>
    </div>
  );
}

function PasswordPolicySetting({ items }: { items: string[] }) {
  return (
    <div className="bg-[#0f172a]/60 border border-white/10 rounded-[12px] px-5 py-4">
      <p className="text-[15px] font-medium text-white mb-3">Password Policy</p>
      <ul className="space-y-2">
        {items.map((item) => (
          <li key={item} className="flex items-center gap-2.5">
            <span className="w-1.5 h-1.5 rounded-full bg-[#86efac] flex-shrink-0" />
            <span className="text-[14px] text-[#cbd5e1]">{item}</span>
          </li>
        ))}
      </ul>
    </div>
  );
}

function EncryptionStatusBlock({
  rows,
}: {
  rows: { label: string; status: string }[];
}) {
  return (
    <div className="bg-[#0f172a]/60 border border-white/10 rounded-[12px] px-5 py-4">
      <p className="text-[15px] font-medium text-white mb-3">Encryption Status</p>
      <div className="space-y-2.5">
        {rows.map((row) => (
          <div
            key={row.label}
            className="flex items-center justify-between gap-4"
          >
            <span className="text-[14px] text-[#cbd5e1]">{row.label}</span>
            <span className="inline-flex items-center px-2.5 py-1 rounded-md bg-[#86efac]/15 border border-[#86efac]/30 text-[#86efac] text-[12px] font-medium">
              {row.status}
            </span>
          </div>
        ))}
      </div>
    </div>
  );
}

function RoleRow({
  name,
  description,
  permissions,
  activeCount,
}: {
  name: string;
  description: string;
  permissions: string;
  activeCount: number;
}) {
  return (
    <div className="bg-[#0f172a]/60 border border-white/10 rounded-[12px] px-5 py-4 flex items-start justify-between gap-4">
      <div className="min-w-0">
        <p className="text-[15px] font-semibold text-white">{name}</p>
        <p className="mt-0.5 text-[13px] text-[#94a3b8]">{description}</p>
        <p className="mt-1 text-[13px] text-[#94a3b8]">{permissions}</p>
      </div>
      <span className="flex-shrink-0 inline-flex items-center px-2.5 py-1 rounded-md bg-[#86efac]/15 border border-[#86efac]/30 text-[#86efac] text-[12px] font-medium">
        {activeCount} Active
      </span>
    </div>
  );
}

function actorEmail(
  actor: AuditLogAdminRow["actor"],
): { email: string; full_name: string | null } | null {
  if (!actor) return null;
  if (Array.isArray(actor)) return actor[0] ?? null;
  return actor;
}

function AuditLogTable({ rows }: { rows: AuditLogAdminRow[] }) {
  if (rows.length === 0) {
    return (
      <p className="text-[14px] text-[#94a3b8] py-6 text-center border border-white/10 rounded-[12px]">
        No audit entries yet.
      </p>
    );
  }
  return (
    <div className="bg-[#0f172a]/60 border border-white/10 rounded-[12px] overflow-hidden">
      <div className="overflow-x-auto custom-scrollbar">
        <table className="w-full min-w-[760px]">
          <thead>
            <tr className="border-b border-[#334155]/50">
              <th className="text-[13px] font-medium text-[#94a3b8] py-3 px-5 text-left">
                Timestamp
              </th>
              <th className="text-[13px] font-medium text-[#94a3b8] py-3 px-5 text-left">
                Admin
              </th>
              <th className="text-[13px] font-medium text-[#94a3b8] py-3 px-5 text-left">
                Action
              </th>
              <th className="text-[13px] font-medium text-[#94a3b8] py-3 px-5 text-left">
                Entity
              </th>
            </tr>
          </thead>
          <tbody>
            {rows.map((row) => {
              const a = actorEmail(row.actor);
              const adminLabel = a?.full_name?.trim() || a?.email || "—";
              const category = row.entity_type ?? "—";
              return (
                <tr key={row.id} className="border-b border-[#334155]/30 last:border-0">
                  <td className="py-4 px-5 text-[14px] text-white whitespace-nowrap">
                    {new Date(row.created_at).toLocaleString()}
                  </td>
                  <td className="py-4 px-5 text-[14px] text-white whitespace-nowrap">
                    {adminLabel}
                  </td>
                  <td className="py-4 px-5 text-[14px] text-[#cbd5e1]">{row.action}</td>
                  <td className="py-4 px-5">
                    <span className="inline-flex items-center px-2.5 py-1 rounded-md bg-white/5 border border-white/10 text-[#cbd5e1] text-[12px] font-medium">
                      {category}
                    </span>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
}
