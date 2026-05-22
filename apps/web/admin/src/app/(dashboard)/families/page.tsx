"use client";

import React, { Suspense, useEffect, useMemo, useState } from "react";
import { useSearchParams } from "next/navigation";
import { Eye, CheckCircle2, XCircle, Search, ChevronDown } from "lucide-react";
import {
  FamilyDetailsModal,
  type FamilyProfile,
} from "@/components/ui/FamilyDetailsModal";
import { ApproveVerificationModal } from "@/components/ui/ApproveVerificationModal";
import { RejectVerificationModal } from "@/components/ui/RejectVerificationModal";
import {
  approveFamily,
  fetchFamilies,
  rejectFamily,
  type FamilyRow,
} from "@/lib/supabase/admin";
import { formatSupabaseError } from "@/lib/supabase/errors";

type VerificationStatus = "Approved" | "Pending" | "Rejected";
type BackgroundCheck = "Completed" | "Pending" | "Failed";

interface Family {
  id: string;
  name: string;
  email: string;
  registrationDate: string;
  verificationStatus: VerificationStatus;
  backgroundCheck: BackgroundCheck;
  activeJobs: number;
  homeAddress: string;
  uploadedDocuments: { name: string; uploadedDate: string }[];
}

function statusFromBg(s: FamilyRow["bg_check_status"]): VerificationStatus {
  if (s === "approved") return "Approved";
  if (s === "rejected") return "Rejected";
  return "Pending";
}

function bgFromStatus(s: FamilyRow["bg_check_status"]): BackgroundCheck {
  if (s === "approved") return "Completed";
  if (s === "rejected") return "Failed";
  return "Pending";
}

function rowToFamily(r: FamilyRow): Family {
  return {
    id: r.user_id,
    name: r.full_name?.trim() || r.email || r.user_id.slice(0, 8),
    email: r.email,
    registrationDate: r.registered_at ? r.registered_at.slice(0, 10) : "",
    verificationStatus: statusFromBg(r.bg_check_status),
    backgroundCheck: bgFromStatus(r.bg_check_status),
    activeJobs: r.active_jobs,
    homeAddress: r.home_address ?? "—",
    uploadedDocuments: [],
  };
}

function toProfile(f: Family): FamilyProfile {
  return {
    familyId: f.id,
    familyName: f.name,
    email: f.email,
    registrationDate: f.registrationDate,
    verificationStatus: f.verificationStatus,
    backgroundCheck: f.backgroundCheck,
    homeAddress: f.homeAddress,
    uploadedDocuments: f.uploadedDocuments,
  };
}

function FamiliesPageInner() {
  const searchParams = useSearchParams();
  const [families, setFamilies] = useState<Family[]>([]);
  const [loading, setLoading] = useState(true);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState<"all" | VerificationStatus>("all");
  const [selected, setSelected] = useState<FamilyProfile | null>(null);
  const [approveTarget, setApproveTarget] = useState<Family | null>(null);
  const [rejectTarget, setRejectTarget] = useState<Family | null>(null);

  const reload = async () => {
    setLoading(true);
    setErrorMessage(null);
    try {
      const rows = await fetchFamilies();
      setFamilies(rows.map(rowToFamily));
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
    const total = families.length;
    const verified = families.filter((f) => f.verificationStatus === "Approved").length;
    const pending = families.filter((f) => f.verificationStatus === "Pending").length;
    const rejected = families.filter((f) => f.verificationStatus === "Rejected").length;
    return { total, verified, pending, rejected };
  }, [families]);

  const filtered = families.filter((f) => {
    const q = search.toLowerCase();
    const matchesSearch =
      !q ||
      f.name.toLowerCase().includes(q) ||
      f.email.toLowerCase().includes(q) ||
      f.id.toLowerCase().includes(q);
    const matchesStatus =
      statusFilter === "all" || f.verificationStatus === statusFilter;
    return matchesSearch && matchesStatus;
  });

  const handleApprove = async (id: string) => {
    try {
      await approveFamily(id);
      await reload();
    } catch (e) {
      setErrorMessage(formatSupabaseError(e));
    }
  };

  const handleReject = async (id: string, reason: string) => {
    try {
      await rejectFamily(id, reason || "Rejected by admin");
      await reload();
    } catch (e) {
      setErrorMessage(formatSupabaseError(e));
    }
  };

  return (
    <div className="space-y-6">
      {/* Page header */}
      <div>
        <h1 className="text-[32px] leading-[40px] font-bold text-white">
          Families Management
        </h1>
        <p className="mt-1 text-[15px] text-[#94a3b8]">
          Background verification and family account control
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
          label="Total Families"
          value={summary.total.toLocaleString()}
          valueColor="text-white"
        />
        <SimpleStatCard
          label="Verified"
          value={summary.verified.toLocaleString()}
          valueColor="text-[#34d399]"
        />
        <SimpleStatCard
          label="Pending"
          value={summary.pending.toLocaleString()}
          valueColor="text-[#c4b5fd]"
        />
        <SimpleStatCard
          label="Rejected"
          value={summary.rejected.toLocaleString()}
          valueColor="text-[#ef4444]"
        />
      </div>

      {/* Table card */}
      <section className="bg-[#1e293b]/60 backdrop-blur-md border border-white/10 rounded-2xl p-6 shadow-[0_24px_60px_-30px_rgba(0,0,0,0.6)]">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-5">
          <h2 className="text-[18px] leading-[26px] font-semibold text-white">
            All Families
          </h2>
          <div className="flex flex-col sm:flex-row gap-3">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-[#64748b]" />
              <input
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                placeholder="Search families..."
                className="w-full sm:w-[280px] h-[40px] bg-[#0f172a]/60 border border-[#334155]/50 rounded-[10px] pl-9 pr-4 text-[14px] text-white placeholder:text-[#64748b] focus:outline-none focus:border-[#b8e0f0]/60 focus:ring-2 focus:ring-[#b8e0f0]/15 transition-all"
              />
            </div>
            <div className="relative">
              <select
                value={statusFilter}
                onChange={(e) =>
                  setStatusFilter(e.target.value as "all" | VerificationStatus)
                }
                className="appearance-none w-full sm:w-[160px] h-[40px] bg-[#0f172a]/60 border border-[#334155]/50 rounded-[10px] pl-3 pr-9 text-[14px] text-white focus:outline-none focus:border-[#b8e0f0]/60 focus:ring-2 focus:ring-[#b8e0f0]/15 transition-all"
              >
                <option value="all">All Status</option>
                <option value="Approved">Approved</option>
                <option value="Pending">Pending</option>
                <option value="Rejected">Rejected</option>
              </select>
              <ChevronDown className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-[#64748b] pointer-events-none" />
            </div>
          </div>
        </div>

        <div className="overflow-x-auto custom-scrollbar">
          <table className="w-full min-w-[920px]">
            <thead>
              <tr className="border-b border-[#334155]/50">
                <Th>Family ID</Th>
                <Th>Name</Th>
                <Th>Email</Th>
                <Th>Registration Date</Th>
                <Th>Verification Status</Th>
                <Th>Background Check</Th>
                <Th>Active Jobs</Th>
                <Th align="right">Actions</Th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((f) => (
                <tr
                  key={f.id}
                  className="border-b border-[#334155]/30 last:border-0"
                >
                  <td className="py-4 pr-4 text-[14px] text-white whitespace-nowrap">{f.id}</td>
                  <td className="py-4 pr-4 text-[14px] text-white whitespace-nowrap">{f.name}</td>
                  <td className="py-4 pr-4 text-[14px] text-[#94a3b8] whitespace-nowrap">{f.email}</td>
                  <td className="py-4 pr-4 text-[14px] text-[#94a3b8] whitespace-nowrap">{f.registrationDate}</td>
                  <td className="py-4 pr-4">
                    <Badge variant={f.verificationStatus} />
                  </td>
                  <td className="py-4 pr-4">
                    <Badge variant={f.backgroundCheck} />
                  </td>
                  <td className="py-4 pr-4 text-[14px] text-white">{f.activeJobs}</td>
                  <td className="py-4 pl-4">
                    <div className="flex items-center justify-end gap-1">
                      <button
                        onClick={() => setSelected(toProfile(f))}
                        aria-label="View details"
                        className="p-1.5 text-[#94a3b8] hover:text-white transition-colors"
                      >
                        <Eye className="w-[18px] h-[18px]" strokeWidth={1.75} />
                      </button>
                      {f.verificationStatus === "Pending" && (
                        <>
                          <button
                            onClick={() => setApproveTarget(f)}
                            aria-label="Approve"
                            className="p-1.5 text-[#34d399] hover:text-[#22c55e] transition-colors"
                          >
                            <CheckCircle2 className="w-[18px] h-[18px]" strokeWidth={1.75} />
                          </button>
                          <button
                            onClick={() => setRejectTarget(f)}
                            aria-label="Reject"
                            className="p-1.5 text-[#ef4444] hover:text-[#dc2626] transition-colors"
                          >
                            <XCircle className="w-[18px] h-[18px]" strokeWidth={1.75} />
                          </button>
                        </>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
              {filtered.length === 0 && (
                <tr>
                  <td colSpan={8} className="py-10 text-center text-[14px] text-[#94a3b8]">
                    {loading ? "Loading families…" : "No families match your filters."}
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </section>

      <FamilyDetailsModal
        isOpen={selected !== null}
        onClose={() => setSelected(null)}
        data={selected}
      />

      <ApproveVerificationModal
        isOpen={approveTarget !== null}
        onClose={() => setApproveTarget(null)}
        onConfirm={() => {
          if (approveTarget) {
            const id = approveTarget.id;
            setApproveTarget(null);
            void handleApprove(id);
          }
        }}
      />

      <RejectVerificationModal
        isOpen={rejectTarget !== null}
        onClose={() => setRejectTarget(null)}
        onConfirm={() => {
          if (rejectTarget) {
            const id = rejectTarget.id;
            setRejectTarget(null);
            void handleReject(id, "Background check rejected by admin");
          }
        }}
        familyName={rejectTarget?.name ?? ""}
        email={rejectTarget?.email ?? ""}
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
  | "Approved"
  | "Pending"
  | "Rejected"
  | "Completed"
  | "Failed";

function Badge({ variant }: { variant: BadgeVariant }) {
  const isGreen = variant === "Approved" || variant === "Completed";
  const isRed = variant === "Rejected" || variant === "Failed";
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

export default function FamiliesPage() {
  return (
    <Suspense fallback={<div className="text-[#94a3b8] py-16 text-center">Loading…</div>}>
      <FamiliesPageInner />
    </Suspense>
  );
}
