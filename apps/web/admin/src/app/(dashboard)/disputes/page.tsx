"use client";

import React, { useEffect, useMemo, useState } from "react";
import { Eye, Search, ChevronDown, AlertTriangle } from "lucide-react";
import {
  DisputeDetailsModal,
  type DisputeDetail,
  type DisputePriority,
  type DisputeStatus,
} from "@/components/ui/DisputeDetailsModal";
import {
  fetchDisputes,
  resolveDispute,
  setDisputeStatus,
  type DisputeRow,
} from "@/lib/supabase/admin";
import { formatSupabaseError } from "@/lib/supabase/errors";

function priorityFromDb(p: DisputeRow["priority"]): DisputePriority {
  if (p === "high") return "High";
  if (p === "medium") return "Medium";
  return "Low";
}

function statusFromDb(s: DisputeRow["status"]): DisputeStatus {
  if (s === "resolved") return "Resolved";
  if (s === "investigating") return "Investigating";
  return "Open";
}

function statusToDb(s: DisputeStatus): "open" | "investigating" | "resolved" {
  if (s === "Resolved") return "resolved";
  if (s === "Investigating") return "investigating";
  return "open";
}

function rowToDispute(r: DisputeRow): Dispute {
  const priority = priorityFromDb(r.priority);
  const status = statusFromDb(r.status);
  const reportedBy =
    r.reporter_name?.trim() || r.reporter_email || `${r.reported_by_role} ${r.reported_by_user_id.slice(0, 6)}`;
  return {
    id: r.id,
    jobId: r.job_id,
    reportedBy,
    issueType: r.issue_type,
    reportedDate: (r.created_at ?? "").replace("T", " ").slice(0, 16),
    priority,
    status,
    detail: {
      id: r.id,
      jobId: r.job_id,
      reportedBy,
      issueType: r.issue_type,
      priority,
      status,
      description: r.description ?? "",
      clockIn: r.clock_in_at ? new Date(r.clock_in_at).toLocaleString() : "—",
      clockOut: r.clock_out_at ? new Date(r.clock_out_at).toLocaleString() : "—",
      calculatedHours: r.time_computed_minutes != null ? `${(r.time_computed_minutes / 60).toFixed(2)}h` : "—",
      calculatedWage: r.time_computed_wage != null ? `$${Number(r.time_computed_wage).toFixed(2)}` : "—",
      messageHistory: [],
      resolutionNotes: r.resolution_notes ?? undefined,
    } satisfies DisputeDetail,
  };
}

interface Dispute {
  id: string;
  jobId: string;
  reportedBy: string;
  issueType: string;
  reportedDate: string;
  priority: DisputePriority;
  status: DisputeStatus;
  detail: DisputeDetail;
}


export default function DisputesPage() {
  const [disputes, setDisputes] = useState<Dispute[]>([]);
  const [loading, setLoading] = useState(true);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState<"all" | DisputeStatus>("all");
  const [selectedId, setSelectedId] = useState<string | null>(null);

  const selected = disputes.find((d) => d.id === selectedId) ?? null;

  const reload = async () => {
    setLoading(true);
    setErrorMessage(null);
    try {
      const rows = await fetchDisputes();
      setDisputes(rows.map(rowToDispute));
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

  const summary = useMemo(() => {
    const open = disputes.filter((d) => d.status === "Open").length;
    const investigating = disputes.filter((d) => d.status === "Investigating").length;
    const resolved = disputes.filter((d) => d.status === "Resolved").length;
    return { open, investigating, resolved, total: disputes.length };
  }, [disputes]);

  const handleResolve = async (notes: string) => {
    if (!selectedId) return;
    try {
      await resolveDispute(selectedId, notes);
      setSelectedId(null);
      await reload();
    } catch (e) {
      setErrorMessage(formatSupabaseError(e));
    }
  };

  const handleUpdateStatus = async (status: DisputeStatus) => {
    if (!selectedId) return;
    try {
      await setDisputeStatus(selectedId, statusToDb(status));
      await reload();
    } catch (e) {
      setErrorMessage(formatSupabaseError(e));
    }
  };

  const filtered = disputes.filter((d) => {
    const q = search.toLowerCase();
    const matchesSearch =
      !q ||
      d.id.toLowerCase().includes(q) ||
      d.jobId.toLowerCase().includes(q) ||
      d.reportedBy.toLowerCase().includes(q) ||
      d.issueType.toLowerCase().includes(q);
    const matchesStatus = statusFilter === "all" || d.status === statusFilter;
    return matchesSearch && matchesStatus;
  });

  return (
    <div className="space-y-6">
      {/* Page header */}
      <div>
        <h1 className="text-[32px] leading-[40px] font-bold text-white">
          Disputes &amp; Issues
        </h1>
        <p className="mt-1 text-[15px] text-[#94a3b8]">
          Manage reported issues and dispute resolution
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
          label="Open Disputes"
          value={summary.open.toLocaleString()}
          valueColor="text-white"
        />
        <SimpleStatCard
          label="Investigating"
          value={summary.investigating.toLocaleString()}
          valueColor="text-[#3b82f6]"
        />
        <SimpleStatCard
          label="Resolved"
          value={summary.resolved.toLocaleString()}
          valueColor="text-[#34d399]"
        />
        <SimpleStatCard
          label="Total"
          value={summary.total.toLocaleString()}
          valueColor="text-[#c4b5fd]"
        />
      </div>

      {/* Table card */}
      <section className="bg-[#1e293b]/60 backdrop-blur-md border border-white/10 rounded-2xl p-6 shadow-[0_24px_60px_-30px_rgba(0,0,0,0.6)]">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-5">
          <h2 className="text-[18px] leading-[26px] font-semibold text-white">
            All Disputes
          </h2>
          <div className="flex flex-col sm:flex-row gap-3">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-[#64748b]" />
              <input
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                placeholder="Search disputes..."
                className="w-full sm:w-[280px] h-[40px] bg-[#0f172a]/60 border border-[#334155]/50 rounded-[10px] pl-9 pr-4 text-[14px] text-white placeholder:text-[#64748b] focus:outline-none focus:border-[#b8e0f0]/60 focus:ring-2 focus:ring-[#b8e0f0]/15 transition-all"
              />
            </div>
            <div className="relative">
              <select
                value={statusFilter}
                onChange={(e) =>
                  setStatusFilter(e.target.value as "all" | DisputeStatus)
                }
                className="appearance-none w-full sm:w-[170px] h-[40px] bg-[#0f172a]/60 border border-[#334155]/50 rounded-[10px] pl-3 pr-9 text-[14px] text-white focus:outline-none focus:border-[#b8e0f0]/60 focus:ring-2 focus:ring-[#b8e0f0]/15 transition-all"
              >
                <option value="all">All Statuses</option>
                <option value="Open">Open</option>
                <option value="Investigating">Investigating</option>
                <option value="Resolved">Resolved</option>
              </select>
              <ChevronDown className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-[#64748b] pointer-events-none" />
            </div>
          </div>
        </div>

        <div className="overflow-x-auto custom-scrollbar">
          <table className="w-full min-w-[940px]">
            <thead>
              <tr className="border-b border-[#334155]/50">
                <Th>Dispute ID</Th>
                <Th>Job ID</Th>
                <Th>Reported By</Th>
                <Th>Issue Type</Th>
                <Th>Reported Date</Th>
                <Th>Priority</Th>
                <Th>Status</Th>
                <Th align="right">Actions</Th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((d) => (
                <tr
                  key={d.id}
                  className="border-b border-[#334155]/30 last:border-0"
                >
                  <td className="py-4 pr-4 text-[14px] text-white whitespace-nowrap">{d.id}</td>
                  <td className="py-4 pr-4 text-[14px] text-white whitespace-nowrap">{d.jobId}</td>
                  <td className="py-4 pr-4 text-[14px] text-white whitespace-nowrap">{d.reportedBy}</td>
                  <td className="py-4 pr-4 text-[14px] text-white whitespace-nowrap">{d.issueType}</td>
                  <td className="py-4 pr-4 text-[14px] text-[#94a3b8] whitespace-nowrap">{d.reportedDate}</td>
                  <td className="py-4 pr-4">
                    <PriorityBadge priority={d.priority} />
                  </td>
                  <td className="py-4 pr-4">
                    <StatusBadge status={d.status} />
                  </td>
                  <td className="py-4 pl-4">
                    <div className="flex items-center justify-end">
                      <button
                        onClick={() => setSelectedId(d.id)}
                        aria-label="View dispute"
                        className="p-1.5 text-[#94a3b8] hover:text-white transition-colors"
                      >
                        <Eye className="w-[18px] h-[18px]" strokeWidth={1.75} />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
              {filtered.length === 0 && (
                <tr>
                  <td colSpan={8} className="py-10 text-center text-[14px] text-[#94a3b8]">
                    {loading ? "Loading disputes…" : "No disputes match your filters."}
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </section>

      <DisputeDetailsModal
        isOpen={selected !== null}
        onClose={() => setSelectedId(null)}
        data={selected?.detail ?? null}
        onResolve={handleResolve}
        onUpdateStatus={handleUpdateStatus}
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

function PriorityBadge({ priority }: { priority: DisputePriority }) {
  if (priority === "High") {
    return (
      <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-md bg-[#ef4444]/15 border border-[#ef4444]/30 text-[#ef4444] text-[12px] font-medium">
        <AlertTriangle className="w-3 h-3" strokeWidth={2.5} />
        High
      </span>
    );
  }
  if (priority === "Medium") {
    return (
      <span className="inline-flex items-center px-2.5 py-1 rounded-md bg-[#a78bfa]/15 border border-[#a78bfa]/25 text-[#c4b5fd] text-[12px] font-medium">
        Medium
      </span>
    );
  }
  return (
    <span className="inline-flex items-center px-2.5 py-1 rounded-md bg-[#fbbf24]/15 border border-[#fbbf24]/25 text-[#fbbf24] text-[12px] font-medium">
      Low
    </span>
  );
}

function StatusBadge({ status }: { status: DisputeStatus }) {
  if (status === "Open") {
    return (
      <span className="inline-flex items-center px-2.5 py-1 rounded-md bg-[#a78bfa]/15 border border-[#a78bfa]/25 text-[#c4b5fd] text-[12px] font-medium">
        Open
      </span>
    );
  }
  if (status === "Investigating") {
    return (
      <span className="inline-flex items-center px-2.5 py-1 rounded-md bg-[#3b82f6]/15 border border-[#3b82f6]/30 text-[#60a5fa] text-[12px] font-medium">
        Investigating
      </span>
    );
  }
  return (
    <span className="inline-flex items-center px-2.5 py-1 rounded-md bg-[#34d399]/15 border border-[#34d399]/25 text-[#34d399] text-[12px] font-medium">
      Resolved
    </span>
  );
}
