"use client";

import React, { Suspense, useEffect, useMemo, useState } from "react";
import { useSearchParams } from "next/navigation";
import {
  Search,
  Filter,
  ChevronDown,
  Eye,
} from "lucide-react";
import {
  JobDetailsModal,
  type JobDetail,
  type JobStatus,
  type TimelineEvent,
  type TimelineEventKind,
} from "@/components/ui/JobDetailsModal";
import { fetchJobs, type JobRow } from "@/lib/supabase/admin";
import { formatSupabaseError } from "@/lib/supabase/errors";
import { createClient } from "@/lib/supabase/client";

interface Job {
  id: string;
  familyName: string;
  babysitterName: string | null;
  date: string;
  status: JobStatus;
  totalHours: number | null;
  totalWage: number | null;
  detail: JobDetail;
}

function jobStatusFromDb(s: string): JobStatus {
  switch (s) {
    case "open":
      return "Open";
    case "hired":
      return "Hired";
    case "active":
      return "In Progress";
    case "completed":
      return "Completed";
    case "cancelled":
      return "Cancelled";
    default:
      return "Open";
  }
}

function timelineKindFromEvent(eventType: string): TimelineEventKind | null {
  switch (eventType) {
    case "posted":
      return "posted";
    case "hired":
      return "accepted";
    case "clock_in":
      return "clockIn";
    case "clock_out":
    case "completed":
      return "clockOut";
    case "cancelled":
      return "cancelled";
    default:
      return null;
  }
}

function rowToJob(r: JobRow): Job {
  const status = jobStatusFromDb(r.status);
  const totalHours =
    r.computed_minutes != null ? Number((r.computed_minutes / 60).toFixed(2)) : null;
  const totalWage = r.computed_wage != null ? Number(r.computed_wage) : null;
  const timeline: TimelineEvent[] = (r.timeline ?? [])
    .map((t) => {
      const kind = timelineKindFromEvent(t.event_type);
      if (!kind) return null;
      return {
        kind,
        title: t.title ?? t.event_type,
        timestamp: t.created_at?.replace("T", " ").slice(0, 16) ?? "",
      } as TimelineEvent;
    })
    .filter((x): x is TimelineEvent => x !== null);

  return {
    id: r.job_id,
    familyName: r.family_name ?? "—",
    babysitterName: r.sitter_name ?? null,
    date: r.job_date ?? "",
    status,
    totalHours,
    totalWage,
    detail: {
      id: r.job_id,
      familyName: r.family_name ?? "—",
      babysitterName: r.sitter_name ?? null,
      date: r.job_date ?? "",
      status,
      totalHoursLabel:
        totalHours != null
          ? `${totalHours} hours`
          : status === "Completed"
            ? "Pending"
            : "Not completed",
      location: (() => {
        const a = r.location_address;
        if (!a) return "—";
        if (typeof a === "string") return a;
        if (typeof a === "object" && !Array.isArray(a)) {
          const o = a as Record<string, unknown>;
          return (o.formatted as string) || (o.line1 as string) || (o.address as string) || "—";
        }
        return "—";
      })(),
      locationVerified: false,
      hoursWorked: totalHours ?? undefined,
      totalWage: totalWage ?? undefined,
      timeline,
    },
  };
}


const STATUS_TO_DB: Record<JobStatus | "all", string> = {
  all: "all",
  Open: "open",
  Hired: "hired",
  "In Progress": "active",
  Completed: "completed",
  Cancelled: "cancelled",
};

function JobsMonitoringPageInner() {
  const searchParams = useSearchParams();
  const [jobs, setJobs] = useState<Job[]>([]);
  const [loading, setLoading] = useState(true);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [topSearch, setTopSearch] = useState("");
  const [topFilter, setTopFilter] = useState<"all" | JobStatus>("all");
  const [tableSearch, setTableSearch] = useState("");
  const [tableFilter, setTableFilter] = useState<"all" | JobStatus>("all");
  const [selected, setSelected] = useState<JobDetail | null>(null);
  const [refreshTick, setRefreshTick] = useState(0);

  const search = (tableSearch || topSearch).toLowerCase();
  const statusFilter = tableFilter !== "all" ? tableFilter : topFilter;

  useEffect(() => {
    const q = searchParams.get("q");
    if (q) {
      setTopSearch(q);
      setTableSearch(q);
    }
  }, [searchParams]);

  useEffect(() => {
    let cancelled = false;
    void (async () => {
      setLoading(true);
      setErrorMessage(null);
      try {
        const rows = await fetchJobs(STATUS_TO_DB[statusFilter] ?? "all", search);
        if (!cancelled) setJobs(rows.map(rowToJob));
      } catch (e) {
        if (!cancelled)
          setErrorMessage(formatSupabaseError(e));
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [statusFilter, search, refreshTick]);

  useEffect(() => {
    const interval = setInterval(() => setRefreshTick((t) => t + 1), 30000);
    return () => clearInterval(interval);
  }, []);

  // Realtime: refresh immediately when any job row changes
  useEffect(() => {
    const supabase = createClient();
    const channel = supabase
      .channel("admin-jobs-realtime")
      .on("postgres_changes", { event: "*", schema: "public", table: "jobs" }, () => {
        setRefreshTick((t) => t + 1);
      })
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, []);

  const summary = useMemo(() => {
    const open = jobs.filter((j) => j.status === "Open").length;
    const inProgress = jobs.filter((j) => j.status === "In Progress").length;
    const completed = jobs.filter((j) => j.status === "Completed").length;
    return { open, inProgress, completed, total: jobs.length };
  }, [jobs]);

  const filtered = jobs;

  return (
    <div className="space-y-6">
      {/* Page header */}
      <div>
        <h1 className="text-[32px] leading-[40px] font-bold text-white">
          Jobs Monitoring
        </h1>
        <p className="mt-1 text-[15px] text-[#94a3b8]">
          Platform transparency and job activity tracking
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
          label="Open Jobs"
          value={summary.open.toLocaleString()}
          valueColor="text-white"
        />
        <SimpleStatCard
          label="In Progress"
          value={summary.inProgress.toLocaleString()}
          valueColor="text-[#7dd3fc]"
        />
        <SimpleStatCard
          label="Completed"
          value={summary.completed.toLocaleString()}
          valueColor="text-[#34d399]"
        />
        <SimpleStatCard
          label="Total Jobs"
          value={summary.total.toLocaleString()}
          valueColor="text-[#c4b5fd]"
        />
      </div>

      {/* Top search card */}
      <section className="bg-[#1e293b]/60 backdrop-blur-md border border-white/10 rounded-2xl p-5 shadow-[0_24px_60px_-30px_rgba(0,0,0,0.6)]">
        <div className="flex flex-col sm:flex-row gap-3">
          <div className="relative flex-1">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-[18px] h-[18px] text-[#64748b]" />
            <input
              value={topSearch}
              onChange={(e) => setTopSearch(e.target.value)}
              placeholder="Search jobs by family, babysitter, or ID..."
              className="w-full h-[48px] bg-[#0f172a]/60 border border-[#334155]/50 rounded-[10px] pl-11 pr-4 text-[14px] text-white placeholder:text-[#64748b] focus:outline-none focus:border-[#b8e0f0]/60 focus:ring-2 focus:ring-[#b8e0f0]/15 transition-all"
            />
          </div>
          <button
            type="button"
            aria-label="Filter"
            className="hidden sm:flex w-[48px] h-[48px] items-center justify-center bg-[#0f172a]/60 border border-[#334155]/50 rounded-[10px] text-[#94a3b8] hover:text-white transition-colors"
          >
            <Filter className="w-[18px] h-[18px]" strokeWidth={1.75} />
          </button>
          <div className="relative">
            <select
              value={topFilter}
              onChange={(e) => setTopFilter(e.target.value as "all" | JobStatus)}
              className="appearance-none w-full sm:w-[180px] h-[48px] bg-[#0f172a]/60 border border-[#334155]/50 rounded-[10px] pl-4 pr-10 text-[14px] text-white focus:outline-none focus:border-[#b8e0f0]/60 focus:ring-2 focus:ring-[#b8e0f0]/15 transition-all"
            >
              <option value="all">All Jobs</option>
              <option value="Open">Open</option>
              <option value="Hired">Hired</option>
              <option value="In Progress">In Progress</option>
              <option value="Completed">Completed</option>
              <option value="Cancelled">Cancelled</option>
            </select>
            <ChevronDown className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-[#64748b] pointer-events-none" />
          </div>
        </div>
      </section>

      {/* Jobs table */}
      <section className="bg-[#1e293b]/60 backdrop-blur-md border border-white/10 rounded-2xl p-6 shadow-[0_24px_60px_-30px_rgba(0,0,0,0.6)]">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-5">
          <h2 className="text-[18px] leading-[26px] font-semibold text-white">
            All Jobs
          </h2>
          <div className="flex flex-col sm:flex-row gap-3">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-[#64748b]" />
              <input
                value={tableSearch}
                onChange={(e) => setTableSearch(e.target.value)}
                placeholder="Search jobs..."
                className="w-full sm:w-[280px] h-[40px] bg-[#0f172a]/60 border border-[#334155]/50 rounded-[10px] pl-9 pr-4 text-[14px] text-white placeholder:text-[#64748b] focus:outline-none focus:border-[#b8e0f0]/60 focus:ring-2 focus:ring-[#b8e0f0]/15 transition-all"
              />
            </div>
            <div className="relative">
              <select
                value={tableFilter}
                onChange={(e) => setTableFilter(e.target.value as "all" | JobStatus)}
                className="appearance-none w-full sm:w-[170px] h-[40px] bg-[#0f172a]/60 border border-[#334155]/50 rounded-[10px] pl-3 pr-9 text-[14px] text-white focus:outline-none focus:border-[#b8e0f0]/60 focus:ring-2 focus:ring-[#b8e0f0]/15 transition-all"
              >
                <option value="all">All Statuses</option>
                <option value="Open">Open</option>
                <option value="Hired">Hired</option>
                <option value="In Progress">In Progress</option>
                <option value="Completed">Completed</option>
                <option value="Cancelled">Cancelled</option>
              </select>
              <ChevronDown className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-[#64748b] pointer-events-none" />
            </div>
          </div>
        </div>

        <div className="overflow-x-auto custom-scrollbar">
          <table className="w-full min-w-[940px]">
            <thead>
              <tr className="border-b border-[#334155]/50">
                <Th>Job ID</Th>
                <Th>Family Name</Th>
                <Th>Babysitter Name</Th>
                <Th>Date</Th>
                <Th>Status</Th>
                <Th>Total Hours</Th>
                <Th>Total Wage</Th>
                <Th align="right">Actions</Th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((j) => (
                <tr
                  key={j.id}
                  className="border-b border-[#334155]/30 last:border-0"
                >
                  <td className="py-4 pr-4 text-[14px] text-white whitespace-nowrap">{j.id}</td>
                  <td className="py-4 pr-4 text-[14px] text-white whitespace-nowrap">{j.familyName}</td>
                  <td className="py-4 pr-4 text-[14px] whitespace-nowrap">
                    {j.babysitterName ? (
                      <span className="text-white">{j.babysitterName}</span>
                    ) : (
                      <span className="text-[#94a3b8]">-</span>
                    )}
                  </td>
                  <td className="py-4 pr-4 text-[14px] text-[#94a3b8] whitespace-nowrap">{j.date}</td>
                  <td className="py-4 pr-4">
                    <StatusBadge status={j.status} />
                  </td>
                  <td className="py-4 pr-4 text-[14px] whitespace-nowrap">
                    {j.totalHours !== null ? (
                      <span className="text-white">{j.totalHours}h</span>
                    ) : (
                      <span className="text-[#94a3b8]">-</span>
                    )}
                  </td>
                  <td className="py-4 pr-4 text-[14px] whitespace-nowrap">
                    {j.totalWage !== null ? (
                      <span className="text-white">${j.totalWage}</span>
                    ) : (
                      <span className="text-[#94a3b8]">-</span>
                    )}
                  </td>
                  <td className="py-4 pl-4">
                    <div className="flex items-center justify-end">
                      <button
                        onClick={() => setSelected(j.detail)}
                        aria-label="View job"
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
                    {loading ? "Loading jobs…" : "No jobs match your filters."}
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </section>

      <JobDetailsModal
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

function StatusBadge({ status }: { status: JobStatus }) {
  if (status === "Completed") {
    return (
      <span className="inline-flex items-center px-2.5 py-1 rounded-md bg-[#34d399]/15 border border-[#34d399]/25 text-[#34d399] text-[12px] font-medium">
        Completed
      </span>
    );
  }
  if (status === "In Progress") {
    return (
      <span className="inline-flex items-center px-2.5 py-1 rounded-md bg-[#7dd3fc]/15 border border-[#7dd3fc]/25 text-[#7dd3fc] text-[12px] font-medium whitespace-nowrap">
        In Progress
      </span>
    );
  }
  if (status === "Hired") {
    return (
      <span className="inline-flex items-center px-2.5 py-1 rounded-md bg-[#a78bfa]/15 border border-[#a78bfa]/25 text-[#c4b5fd] text-[12px] font-medium">
        Hired
      </span>
    );
  }
  if (status === "Cancelled") {
    return (
      <span className="inline-flex items-center px-2.5 py-1 rounded-md bg-[#ef4444]/15 border border-[#ef4444]/25 text-[#ef4444] text-[12px] font-medium">
        Cancelled
      </span>
    );
  }
  return (
    <span className="inline-flex items-center px-2.5 py-1 rounded-md bg-[#475569]/40 border border-[#475569]/50 text-[#cbd5e1] text-[12px] font-medium">
      Open
    </span>
  );
}

export default function JobsMonitoringPage() {
  return (
    <Suspense fallback={<div className="text-[#94a3b8] py-16 text-center">Loading…</div>}>
      <JobsMonitoringPageInner />
    </Suspense>
  );
}
