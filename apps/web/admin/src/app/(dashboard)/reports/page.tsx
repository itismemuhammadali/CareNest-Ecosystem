"use client";

import React, { useCallback, useEffect, useMemo, useState } from "react";
import {
  Calendar,
  ChevronDown,
  Download,
  TrendingUp,
} from "lucide-react";
import {
  ResponsiveContainer,
  BarChart,
  Bar,
  LineChart,
  Line,
  PieChart,
  Pie,
  Cell,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
} from "recharts";
import {
  fetchReportCertStats,
  fetchReportHoursPerMonth,
  fetchReportJobStatusDistribution,
  fetchReportJobsPerMonth,
  fetchReportSummary,
  fetchReportUserGrowth,
  fetchReportWageDistribution,
  type ReportCertStats,
  type ReportSummary,
} from "@/lib/supabase/admin";
import { formatSupabaseError } from "@/lib/supabase/errors";
import { downloadReportsPdf } from "@/lib/reportsPdf";

const PIE_COLORS = ["#a5d8eb", "#c4b5fd", "#86efac", "#fca5a5", "#fcd34d", "#a78bfa"];

function periodToMonths(period: string): number {
  if (period === "Last 30 Days") return 1;
  if (period === "Last 12 Months") return 12;
  if (period === "All Time") return 24;
  return 6;
}

function niceDomainMax(values: number[], floor = 5): number {
  const m = values.length > 0 ? Math.max(...values) : 0;
  return Math.max(floor, Math.ceil(Math.max(m, 1) * 1.15));
}

export default function ReportsPage() {
  const [mounted, setMounted] = useState(false);
  const [period, setPeriod] = useState("Last 6 Months");
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [summary, setSummary] = useState<ReportSummary | null>(null);
  const [jobsPerMonth, setJobsPerMonth] = useState<{ month: string; jobs: number }[]>([]);
  const [hoursPerMonth, setHoursPerMonth] = useState<{ month: string; hours: number }[]>([]);
  const [wageDistribution, setWageDistribution] = useState<
    { name: string; value: number; color: string }[]
  >([]);
  const [jobStatusDistribution, setJobStatusDistribution] = useState<
    { name: string; value: number; color: string }[]
  >([]);
  const [userGrowth, setUserGrowth] = useState<
    { month: string; families: number; babysitters: number }[]
  >([]);
  const [certStats, setCertStats] = useState<ReportCertStats | null>(null);
  const [pdfBusy, setPdfBusy] = useState(false);

  const months = useMemo(() => periodToMonths(period), [period]);

  const load = useCallback(async () => {
    setLoading(true);
    setLoadError(null);
    try {
      const [
        s,
        jobs,
        hours,
        wages,
        statuses,
        growth,
        certs,
      ] = await Promise.all([
        fetchReportSummary(months),
        fetchReportJobsPerMonth(months),
        fetchReportHoursPerMonth(months),
        fetchReportWageDistribution(),
        fetchReportJobStatusDistribution(),
        fetchReportUserGrowth(months),
        fetchReportCertStats(),
      ]);
      setSummary(s);
      setJobsPerMonth(jobs);
      setHoursPerMonth(hours);
      setWageDistribution(
        wages.map((w, i) => ({ ...w, color: PIE_COLORS[i % PIE_COLORS.length] })),
      );
      setJobStatusDistribution(
        statuses.map((w, i) => ({ ...w, color: PIE_COLORS[i % PIE_COLORS.length] })),
      );
      setUserGrowth(growth);
      setCertStats(certs);
    } catch (e) {
      setLoadError(formatSupabaseError(e));
    } finally {
      setLoading(false);
    }
  }, [months]);

  useEffect(() => setMounted(true), []);
  useEffect(() => {
    void load();
  }, [load]);

  const jobsYMax = useMemo(
    () => niceDomainMax(jobsPerMonth.map((d) => d.jobs)),
    [jobsPerMonth],
  );
  const hoursYMax = useMemo(
    () => niceDomainMax(hoursPerMonth.map((d) => d.hours)),
    [hoursPerMonth],
  );
  const growthYMax = useMemo(
    () =>
      niceDomainMax(
        userGrowth.flatMap((d) => [d.families, d.babysitters]),
        10,
      ),
    [userGrowth],
  );

  const revenueLabel = summary
    ? `$${summary.total_revenue.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`
    : "—";
  const jobsLabel = summary ? String(summary.total_jobs) : "—";
  const hoursLabel = summary ? String(summary.total_hours) : "—";
  const avgDurLabel = summary ? `${summary.avg_duration}h` : "—";

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-[32px] leading-[40px] font-bold text-white">
          Reports &amp; Analytics
        </h1>
        <p className="mt-1 text-[15px] text-[#94a3b8]">
          Platform performance metrics and data insights
        </p>
        {loadError && (
          <p className="mt-2 text-[13px] text-red-400" role="alert">
            {loadError}
          </p>
        )}
        {loading && (
          <p className="mt-2 text-[13px] text-[#94a3b8]">Loading report data…</p>
        )}
      </div>

      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
        <div className="relative inline-block">
          <Calendar className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-[#94a3b8] pointer-events-none" />
          <select
            value={period}
            onChange={(e) => setPeriod(e.target.value)}
            className="appearance-none h-[44px] bg-[#1e293b]/60 backdrop-blur-md border border-white/10 rounded-[10px] pl-9 pr-10 text-[14px] text-white focus:outline-none focus:border-[#b8e0f0]/60 transition-all"
          >
            <option className="bg-[#1e293b]">Last 6 Months</option>
            <option className="bg-[#1e293b]">Last 30 Days</option>
            <option className="bg-[#1e293b]">Last 12 Months</option>
            <option className="bg-[#1e293b]">All Time</option>
          </select>
          <ChevronDown className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-[#94a3b8] pointer-events-none" />
        </div>

        <div className="flex gap-3">
          <ExportButton
            label="Export CSV"
            onClick={() => {
              window.open("/api/admin/reports/export", "_blank", "noopener,noreferrer");
            }}
          />
          <ExportButton
            label={pdfBusy ? "Building PDF…" : "Export PDF"}
            disabled={loading || !!loadError || pdfBusy}
            onClick={() => {
              setPdfBusy(true);
              window.setTimeout(() => {
                try {
                  downloadReportsPdf({
                    periodLabel: period,
                    summary,
                    certStats,
                    jobsPerMonth,
                    hoursPerMonth,
                    wageDistribution: wageDistribution.map(({ name, value }) => ({ name, value })),
                    jobStatusDistribution: jobStatusDistribution.map(({ name, value }) => ({
                      name,
                      value,
                    })),
                    userGrowth,
                  });
                } catch (e) {
                  window.alert(formatSupabaseError(e));
                } finally {
                  setPdfBusy(false);
                }
              }, 0);
            }}
          />
        </div>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <DeltaStatCard
          label="Total Revenue (ledger)"
          value={revenueLabel}
          caption={`Window: ${months} month(s)`}
        />
        <DeltaStatCard label="Completed Jobs" value={jobsLabel} caption="In selected window" />
        <DeltaStatCard label="Total Hours" value={hoursLabel} caption="Clocked time (window)" />
        <DeltaStatCard label="Avg Job Duration" value={avgDurLabel} caption="Hours per completed job" />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <ChartCard title="Jobs Per Month">
          {mounted && jobsPerMonth.length > 0 && (
            <ResponsiveContainer width="100%" height={300}>
              <BarChart data={jobsPerMonth} margin={{ top: 12, right: 12, left: -16, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="#334155" strokeOpacity={0.4} vertical={false} />
                <XAxis dataKey="month" stroke="#64748b" fontSize={12} tickLine={false} axisLine={{ stroke: "#334155", strokeOpacity: 0.4 }} />
                <YAxis stroke="#64748b" fontSize={12} tickLine={false} axisLine={false} domain={[0, jobsYMax]} />
                <Tooltip
                  cursor={{ fill: "#334155", fillOpacity: 0.2 }}
                  contentStyle={{ backgroundColor: "#1e293b", border: "1px solid #334155", borderRadius: 10, fontSize: 13 }}
                  labelStyle={{ color: "#fff" }}
                  itemStyle={{ color: "#cbd5e1" }}
                />
                <Bar dataKey="jobs" fill="#bae6fd" radius={[6, 6, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          )}
          {mounted && !loading && jobsPerMonth.length === 0 && (
            <p className="text-[14px] text-[#94a3b8] py-12 text-center">No job data in this range.</p>
          )}
        </ChartCard>

        <ChartCard title="Hours Worked Per Month">
          {mounted && hoursPerMonth.length > 0 && (
            <ResponsiveContainer width="100%" height={300}>
              <LineChart data={hoursPerMonth} margin={{ top: 12, right: 12, left: -16, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="#334155" strokeOpacity={0.4} vertical={false} />
                <XAxis dataKey="month" stroke="#64748b" fontSize={12} tickLine={false} axisLine={{ stroke: "#334155", strokeOpacity: 0.4 }} />
                <YAxis
                  stroke="#64748b"
                  fontSize={12}
                  tickLine={false}
                  axisLine={false}
                  domain={[0, hoursYMax]}
                />
                <Tooltip
                  contentStyle={{ backgroundColor: "#1e293b", border: "1px solid #334155", borderRadius: 10, fontSize: 13 }}
                  labelStyle={{ color: "#fff" }}
                  itemStyle={{ color: "#cbd5e1" }}
                />
                <Line type="monotone" dataKey="hours" stroke="#86efac" strokeWidth={2} dot={{ r: 4, fill: "#86efac", strokeWidth: 0 }} activeDot={{ r: 5 }} />
              </LineChart>
            </ResponsiveContainer>
          )}
          {mounted && !loading && hoursPerMonth.length === 0 && (
            <p className="text-[14px] text-[#94a3b8] py-12 text-center">No hours in this range.</p>
          )}
        </ChartCard>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <ChartCard title="Wage Distribution by Age Group (12 mo earnings)">
          {mounted && wageDistribution.length > 0 && (
            <ResponsiveContainer width="100%" height={320}>
              <PieChart>
                <Pie
                  data={wageDistribution}
                  dataKey="value"
                  nameKey="name"
                  cx="50%"
                  cy="50%"
                  outerRadius={110}
                  stroke="none"
                  label={(entry: { name?: string; value?: number }) =>
                    `${entry.name}: $${(entry.value ?? 0).toLocaleString()}`
                  }
                  labelLine={{ stroke: "#94a3b8", strokeWidth: 1 }}
                >
                  {wageDistribution.map((entry) => (
                    <Cell key={entry.name} fill={entry.color} />
                  ))}
                </Pie>
                <Tooltip
                  contentStyle={{ backgroundColor: "#1e293b", border: "1px solid #334155", borderRadius: 10, fontSize: 13 }}
                  itemStyle={{ color: "#cbd5e1" }}
                  formatter={(v) => `$${Number(v).toLocaleString()}`}
                />
              </PieChart>
            </ResponsiveContainer>
          )}
          {mounted && !loading && wageDistribution.length === 0 && (
            <p className="text-[14px] text-[#94a3b8] py-12 text-center">No wage tier earnings yet.</p>
          )}
        </ChartCard>

        <ChartCard title="Job Status Distribution">
          {mounted && jobStatusDistribution.length > 0 && (
            <ResponsiveContainer width="100%" height={320}>
              <PieChart>
                <Pie
                  data={jobStatusDistribution}
                  dataKey="value"
                  nameKey="name"
                  cx="50%"
                  cy="50%"
                  outerRadius={110}
                  stroke="none"
                  label={(entry: { name?: string; value?: number }) =>
                    `${entry.name}: ${entry.value}`
                  }
                  labelLine={{ stroke: "#94a3b8", strokeWidth: 1 }}
                >
                  {jobStatusDistribution.map((entry) => (
                    <Cell key={entry.name} fill={entry.color} />
                  ))}
                </Pie>
                <Tooltip
                  contentStyle={{ backgroundColor: "#1e293b", border: "1px solid #334155", borderRadius: 10, fontSize: 13 }}
                  itemStyle={{ color: "#cbd5e1" }}
                />
              </PieChart>
            </ResponsiveContainer>
          )}
          {mounted && !loading && jobStatusDistribution.length === 0 && (
            <p className="text-[14px] text-[#94a3b8] py-12 text-center">No jobs yet.</p>
          )}
        </ChartCard>
      </div>

      <ChartCard title="User Growth (Families vs Babysitters)">
        {mounted && userGrowth.length > 0 && (
          <ResponsiveContainer width="100%" height={360}>
            <LineChart data={userGrowth} margin={{ top: 12, right: 12, left: -16, bottom: 8 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="#334155" strokeOpacity={0.4} vertical={false} />
              <XAxis dataKey="month" stroke="#64748b" fontSize={12} tickLine={false} axisLine={{ stroke: "#334155", strokeOpacity: 0.4 }} />
              <YAxis stroke="#64748b" fontSize={12} tickLine={false} axisLine={false} domain={[0, growthYMax]} />
              <Tooltip
                contentStyle={{ backgroundColor: "#1e293b", border: "1px solid #334155", borderRadius: 10, fontSize: 13 }}
                labelStyle={{ color: "#fff" }}
                itemStyle={{ color: "#cbd5e1" }}
              />
              <Legend
                iconType="circle"
                iconSize={8}
                wrapperStyle={{ fontSize: 13, color: "#cbd5e1", paddingTop: 12 }}
              />
              <Line type="monotone" dataKey="families" name="Families" stroke="#7dd3fc" strokeWidth={2} dot={{ r: 4, fill: "#7dd3fc", strokeWidth: 0 }} activeDot={{ r: 5 }} />
              <Line type="monotone" dataKey="babysitters" name="Babysitters" stroke="#c4b5fd" strokeWidth={2} dot={{ r: 4, fill: "#c4b5fd", strokeWidth: 0 }} activeDot={{ r: 5 }} />
            </LineChart>
          </ResponsiveContainer>
        )}
        {mounted && !loading && userGrowth.length === 0 && (
          <p className="text-[14px] text-[#94a3b8] py-12 text-center">No registrations in this range.</p>
        )}
      </ChartCard>

      <section className="bg-[#1e293b]/60 backdrop-blur-md border border-white/10 rounded-2xl p-6 shadow-[0_24px_60px_-30px_rgba(0,0,0,0.6)]">
        <h2 className="text-[18px] leading-[26px] font-semibold text-white mb-5">
          Certification Statistics
        </h2>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          <CertStatCard
            label="Approval Rate"
            value={certStats ? `${certStats.approval_rate}%` : "—"}
            valueColor="text-[#34d399]"
            caption={
              certStats && certStats.decided_submissions > 0
                ? `${certStats.decided_submissions} decided submission(s)`
                : "No decided submissions yet"
            }
          />
          <CertStatCard
            label="Avg Processing Time"
            value={certStats ? `${certStats.avg_processing_days} days` : "—"}
            valueColor="text-white"
            caption="From submission to review (decided rows)"
          />
          <CertStatCard
            label="Most Popular Course"
            value={certStats?.most_popular_course ?? "—"}
            valueColor="text-[#c4b5fd]"
            caption={
              certStats
                ? `${certStats.most_popular_enrollments} submission(s)`
                : "—"
            }
          />
        </div>
      </section>
    </div>
  );
}

function ExportButton({ label, onClick, disabled }: { label: string; onClick?: () => void; disabled?: boolean }) {
  return (
    <button
      type="button"
      disabled={disabled}
      onClick={onClick}
      className="inline-flex items-center gap-2 px-4 h-[44px] bg-[#1e293b]/60 backdrop-blur-md border border-white/10 hover:border-white/25 disabled:opacity-40 disabled:pointer-events-none text-white text-[14px] font-medium rounded-[10px] transition-all"
    >
      <Download className="w-4 h-4" strokeWidth={1.75} />
      {label}
    </button>
  );
}

function DeltaStatCard({
  label,
  value,
  delta,
  caption,
}: {
  label: string;
  value: string;
  delta?: string;
  caption?: string;
}) {
  return (
    <div className="bg-[#1e293b]/60 backdrop-blur-md border border-white/10 rounded-2xl p-5 shadow-[0_24px_60px_-30px_rgba(0,0,0,0.6)]">
      <p className="text-[13px] leading-[18px] font-medium text-[#94a3b8]">{label}</p>
      <p className="mt-3 text-[28px] leading-[36px] font-bold text-white">{value}</p>
      {delta && (
        <div className="mt-2 flex items-center gap-1.5 text-[12px] text-[#34d399]">
          <TrendingUp className="w-3.5 h-3.5" strokeWidth={2} />
          <span>{delta}</span>
        </div>
      )}
      {caption && !delta && (
        <p className="mt-2 text-[12px] text-[#94a3b8]">{caption}</p>
      )}
    </div>
  );
}

function ChartCard({
  title,
  children,
}: {
  title: string;
  children: React.ReactNode;
}) {
  return (
    <div className="bg-[#1e293b]/60 backdrop-blur-md border border-white/10 rounded-2xl p-6 shadow-[0_24px_60px_-30px_rgba(0,0,0,0.6)]">
      <h3 className="text-[16px] leading-[24px] font-semibold text-white mb-4">
        {title}
      </h3>
      {children}
    </div>
  );
}

function CertStatCard({
  label,
  value,
  valueColor,
  caption,
}: {
  label: string;
  value: string;
  valueColor: string;
  caption: string;
}) {
  return (
    <div className="bg-[#0f172a]/60 border border-white/10 rounded-[12px] p-5">
      <p className="text-[13px] text-[#94a3b8]">{label}</p>
      <p className={`mt-2 text-[28px] leading-[36px] font-bold ${valueColor}`}>
        {value}
      </p>
      <p className="mt-2 text-[12px] text-[#94a3b8]">{caption}</p>
    </div>
  );
}
