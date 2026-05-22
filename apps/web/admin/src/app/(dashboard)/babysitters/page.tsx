"use client";

import React, { Suspense, useEffect, useMemo, useState } from "react";
import { useSearchParams } from "next/navigation";
import { Eye, Search, ChevronDown, ShieldOff, ShieldCheck } from "lucide-react";
import {
  BabysitterDetailsModal,
  type BabysitterProfile,
} from "@/components/ui/BabysitterDetailsModal";
import {
  fetchSitters,
  suspendSitter,
  unsuspendSitter,
  type SitterRow,
} from "@/lib/supabase/admin";
import { formatSupabaseError } from "@/lib/supabase/errors";

type CertificationStatus = "Certified" | "Pending";
type AccountStatus = "Active" | "Pending" | "Suspended";

interface Babysitter {
  id: string;
  name: string;
  age: number;
  registrationDate: string;
  certification: CertificationStatus;
  accountStatus: AccountStatus;
  totalHours: number;
  totalEarnings: number;
  profile: BabysitterProfile;
}

function rowToBabysitter(r: SitterRow): Babysitter {
  const cert: CertificationStatus =
    r.guardian_consent_status === "approved" ? "Certified" : "Pending";
  let status: AccountStatus = "Pending";
  if (r.is_active) status = "Active";
  else if (r.suspension_reason) status = "Suspended";
  return {
    id: r.user_id,
    name: r.full_name?.trim() || r.email || r.user_id.slice(0, 8),
    age: r.age,
    registrationDate: r.registered_at ? r.registered_at.slice(0, 10) : "",
    certification: cert,
    accountStatus: status,
    totalHours: Math.round((r.total_minutes_worked ?? 0) / 60),
    totalEarnings: Number(r.total_earnings ?? 0),
    profile: {
      babysitterId: r.user_id,
      fullName: r.full_name?.trim() || r.email,
      age: r.age,
      email: r.email,
      certificationStatus: cert,
      accountStatus: status,
      guardian: {
        name: r.guardian_name ?? "—",
        relation: "—",
        email: r.guardian_email ?? "—",
        phone: r.guardian_phone ?? "—",
        consentVerified: r.guardian_consent_status === "approved",
      },
      certifications: [],
      totalHoursWorked: Math.round((r.total_minutes_worked ?? 0) / 60),
      totalEarnings: Number(r.total_earnings ?? 0),
    },
  };
}

function BabysittersPageInner() {
  const searchParams = useSearchParams();
  const [babysitters, setBabysitters] = useState<Babysitter[]>([]);
  const [loading, setLoading] = useState(true);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState<"all" | AccountStatus>("all");
  const [selected, setSelected] = useState<BabysitterProfile | null>(null);

  const reload = async () => {
    setLoading(true);
    setErrorMessage(null);
    try {
      const rows = await fetchSitters();
      setBabysitters(rows.map(rowToBabysitter));
    } catch (e) {
      setErrorMessage(formatSupabaseError(e));
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void reload();
    const interval = setInterval(() => { void reload(); }, 30000);
    return () => clearInterval(interval);
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  useEffect(() => {
    const q = searchParams.get("q");
    if (q) setSearch(q);
  }, [searchParams]);

  const summary = useMemo(() => {
    const total = babysitters.length;
    const certified = babysitters.filter((b) => b.certification === "Certified").length;
    const active = babysitters.filter((b) => b.accountStatus === "Active").length;
    const pending = babysitters.filter((b) => b.accountStatus === "Pending").length;
    return { total, certified, active, pending };
  }, [babysitters]);

  const handleSuspend = async (id: string) => {
    const reason = window.prompt("Reason for suspension (min 5 chars)");
    if (!reason || reason.trim().length < 5) return;
    try {
      await suspendSitter(id, reason.trim(), null);
      await reload();
    } catch (e) {
      setErrorMessage(formatSupabaseError(e));
    }
  };

  const handleUnsuspend = async (id: string) => {
    try {
      await unsuspendSitter(id);
      await reload();
    } catch (e) {
      setErrorMessage(formatSupabaseError(e));
    }
  };

  const filtered = babysitters.filter((b) => {
    const q = search.toLowerCase();
    const matchesSearch =
      !q ||
      b.name.toLowerCase().includes(q) ||
      b.id.toLowerCase().includes(q);
    const matchesStatus =
      statusFilter === "all" || b.accountStatus === statusFilter;
    return matchesSearch && matchesStatus;
  });

  return (
    <div className="space-y-6">
      {/* Page header */}
      <div>
        <h1 className="text-[32px] leading-[40px] font-bold text-white">
          Babysitters Management
        </h1>
        <p className="mt-1 text-[15px] text-[#94a3b8]">
          Minor protection, compliance, and certification management
        </p>
      </div>

      {errorMessage ? (
        <p
          role="alert"
          className="rounded-lg border border-red-500/40 bg-red-950/40 px-3 py-2 text-sm text-red-200"
        >
          {errorMessage}
        </p>
      ) : null}

      {/* Stat cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <SimpleStatCard
          label="Total Babysitters"
          value={summary.total.toLocaleString()}
          valueColor="text-white"
        />
        <SimpleStatCard
          label="Certified"
          value={summary.certified.toLocaleString()}
          valueColor="text-[#34d399]"
        />
        <SimpleStatCard
          label="Active"
          value={summary.active.toLocaleString()}
          valueColor="text-[#c4b5fd]"
        />
        <SimpleStatCard
          label="Pending Approval"
          value={summary.pending.toLocaleString()}
          valueColor="text-[#ef4444]"
        />
      </div>

      {/* Table card */}
      <section className="bg-[#1e293b]/60 backdrop-blur-md border border-white/10 rounded-2xl p-6 shadow-[0_24px_60px_-30px_rgba(0,0,0,0.6)]">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-5">
          <h2 className="text-[18px] leading-[26px] font-semibold text-white">
            All Babysitters
          </h2>
          <div className="flex flex-col sm:flex-row gap-3">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-[#64748b]" />
              <input
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                placeholder="Search babysitters..."
                className="w-full sm:w-[280px] h-[40px] bg-[#0f172a]/60 border border-[#334155]/50 rounded-[10px] pl-9 pr-4 text-[14px] text-white placeholder:text-[#64748b] focus:outline-none focus:border-[#b8e0f0]/60 focus:ring-2 focus:ring-[#b8e0f0]/15 transition-all"
              />
            </div>
            <div className="relative">
              <select
                value={statusFilter}
                onChange={(e) =>
                  setStatusFilter(e.target.value as "all" | AccountStatus)
                }
                className="appearance-none w-full sm:w-[160px] h-[40px] bg-[#0f172a]/60 border border-[#334155]/50 rounded-[10px] pl-3 pr-9 text-[14px] text-white focus:outline-none focus:border-[#b8e0f0]/60 focus:ring-2 focus:ring-[#b8e0f0]/15 transition-all"
              >
                <option value="all">All Status</option>
                <option value="Active">Active</option>
                <option value="Pending">Pending</option>
                <option value="Suspended">Suspended</option>
              </select>
              <ChevronDown className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-[#64748b] pointer-events-none" />
            </div>
          </div>
        </div>

        <div className="overflow-x-auto custom-scrollbar">
          <table className="w-full min-w-[940px]">
            <thead>
              <tr className="border-b border-[#334155]/50">
                <Th>ID</Th>
                <Th>Name</Th>
                <Th>Age</Th>
                <Th>Registration Date</Th>
                <Th>Certification</Th>
                <Th>Account Status</Th>
                <Th>Total Hours</Th>
                <Th>Total Earnings</Th>
                <Th align="right">Actions</Th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((b) => (
                <tr
                  key={b.id}
                  className="border-b border-[#334155]/30 last:border-0"
                >
                  <td className="py-4 pr-4 text-[14px] text-white whitespace-nowrap">{b.id}</td>
                  <td className="py-4 pr-4 text-[14px] text-white whitespace-nowrap">{b.name}</td>
                  <td className="py-4 pr-4 text-[14px] text-[#94a3b8]">{b.age}</td>
                  <td className="py-4 pr-4 text-[14px] text-[#94a3b8] whitespace-nowrap">{b.registrationDate}</td>
                  <td className="py-4 pr-4">
                    <Badge variant={b.certification} />
                  </td>
                  <td className="py-4 pr-4">
                    <Badge variant={b.accountStatus} />
                  </td>
                  <td className="py-4 pr-4 text-[14px] text-white whitespace-nowrap">{b.totalHours}h</td>
                  <td className="py-4 pr-4 text-[14px] text-white whitespace-nowrap">${b.totalEarnings.toLocaleString()}</td>
                  <td className="py-4 pl-4">
                    <div className="flex items-center justify-end gap-1">
                      <button
                        onClick={() => setSelected(b.profile)}
                        aria-label="View details"
                        className="p-1.5 text-[#94a3b8] hover:text-white transition-colors"
                      >
                        <Eye className="w-[18px] h-[18px]" strokeWidth={1.75} />
                      </button>
                      {b.accountStatus === "Active" ? (
                        <button
                          onClick={() => void handleSuspend(b.id)}
                          aria-label="Suspend"
                          className="p-1.5 text-[#ef4444] hover:text-[#dc2626] transition-colors"
                        >
                          <ShieldOff className="w-[18px] h-[18px]" strokeWidth={1.75} />
                        </button>
                      ) : b.accountStatus === "Suspended" ? (
                        <button
                          onClick={() => void handleUnsuspend(b.id)}
                          aria-label="Unsuspend"
                          className="p-1.5 text-[#34d399] hover:text-[#22c55e] transition-colors"
                        >
                          <ShieldCheck className="w-[18px] h-[18px]" strokeWidth={1.75} />
                        </button>
                      ) : b.accountStatus === "Pending" ? (
                        <button
                          onClick={() => void handleUnsuspend(b.id)}
                          aria-label="Activate account"
                          title="Activates the sitter account (same as restore after suspension)."
                          className="p-1.5 text-[#34d399] hover:text-[#22c55e] transition-colors"
                        >
                          <ShieldCheck className="w-[18px] h-[18px]" strokeWidth={1.75} />
                        </button>
                      ) : null}
                    </div>
                  </td>
                </tr>
              ))}
              {filtered.length === 0 && (
                <tr>
                  <td colSpan={9} className="py-10 text-center text-[14px] text-[#94a3b8]">
                    {loading ? "Loading babysitters…" : "No babysitters match your filters."}
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </section>

      <BabysitterDetailsModal
        isOpen={selected !== null}
        onClose={() => setSelected(null)}
        data={selected}
      />
    </div>
  );
}

function SimpleStatCard({
  label,
  value,
  valueColor,
}: {
  label: string;
  value: string;
  valueColor: string;
}) {
  return (
    <div className="bg-[#1e293b]/60 backdrop-blur-md border border-white/10 rounded-2xl p-5 shadow-[0_24px_60px_-30px_rgba(0,0,0,0.6)]">
      <p className="text-[13px] leading-[18px] font-medium text-[#94a3b8]">
        {label}
      </p>
      <p className={`mt-3 text-[32px] leading-[40px] font-bold ${valueColor}`}>
        {value}
      </p>
    </div>
  );
}

function Th({
  children,
  align = "left",
}: {
  children: React.ReactNode;
  align?: "left" | "right";
}) {
  return (
    <th
      className={`text-[13px] font-medium text-[#94a3b8] py-3 ${
        align === "right" ? "text-right pl-4" : "text-left pr-4"
      }`}
    >
      {children}
    </th>
  );
}

type BadgeVariant =
  | "Certified"
  | "Active"
  | "Pending"
  | "Suspended";

function Badge({ variant }: { variant: BadgeVariant }) {
  const isGreen = variant === "Certified" || variant === "Active";
  const isRed = variant === "Suspended";
  const styles = isGreen
    ? "bg-[#34d399]/15 border-[#34d399]/25 text-[#34d399]"
    : isRed
    ? "bg-[#ef4444]/15 border-[#ef4444]/25 text-[#ef4444]"
    : "bg-[#a78bfa]/15 border-[#a78bfa]/25 text-[#c4b5fd]";
  return (
    <span
      className={`inline-flex items-center px-2.5 py-1 rounded-md border text-[12px] font-medium ${styles}`}
    >
      {variant}
    </span>
  );
}

export default function BabysittersPage() {
  return (
    <Suspense fallback={<div className="text-[#94a3b8] py-16 text-center">Loading…</div>}>
      <BabysittersPageInner />
    </Suspense>
  );
}
