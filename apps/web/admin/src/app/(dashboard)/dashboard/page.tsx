"use client";

import React, { useEffect, useMemo, useState } from "react";
import {
  Users,
  UserCheck,
  Clock,
  Smile,
  CheckCircle2,
} from "lucide-react";
import {
  ResponsiveContainer,
  LineChart,
  Line,
  CartesianGrid,
  XAxis,
  YAxis,
  Tooltip,
  Legend,
  BarChart,
  Bar,
} from "recharts";
import {
  OnboardingDetailsModal,
  type OnboardingDetails,
} from "@/components/ui/OnboardingDetailsModal";
import {
  fetchDashboardStats,
  fetchRecentOnboarding,
  fetchRegistrationTrend,
  fetchReportRevenuePerMonth,
  type DashboardStats,
  type RecentOnboardingRow,
} from "@/lib/supabase/admin";
import { formatSupabaseError } from "@/lib/supabase/errors";

type OnboardingType = "Family" | "Babysitter";
type OnboardingStatus = "Verified" | "Pending";

export default function DashboardPage() {
  const [mounted, setMounted] = useState(false);
  const [selectedDetails, setSelectedDetails] = useState<OnboardingDetails | null>(null);
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [statsError, setStatsError] = useState<string | null>(null);
  const [registrationData, setRegistrationData] = useState<
    { month: string; families: number; babysitters: number }[]
  >([]);
  const [revenueRows, setRevenueRows] = useState<{ month: string; revenue: number }[]>([]);
  const [revenueError, setRevenueError] = useState<string | null>(null);
  const [onboardingRows, setOnboardingRows] = useState<RecentOnboardingRow[]>([]);
  const [onboardingLoading, setOnboardingLoading] = useState(true);
  const [onboardingError, setOnboardingError] = useState<string | null>(null);

  const revenueYMax = useMemo(() => {
    const m = Math.max(1, ...revenueRows.map((r) => r.revenue), 0);
    return Math.ceil(m * 1.12);
  }, [revenueRows]);

  useEffect(() => setMounted(true), []);
  useEffect(() => {
    let cancelled = false;
    void (async () => {
      try {
        const s = await fetchDashboardStats();
        if (!cancelled) setStats(s);
      } catch (e) {
        if (!cancelled)
          setStatsError(formatSupabaseError(e));
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);
  useEffect(() => {
    let cancelled = false;
    void (async () => {
      try {
        const trend = await fetchRegistrationTrend();
        if (cancelled) return;
        const byDay = new Map<string, { families: number; babysitters: number }>();
        for (const row of trend) {
          const dRaw = typeof row.d === "string" ? row.d : String(row.d ?? "");
          const key = dRaw.slice(0, 10);
          if (!/^\d{4}-\d{2}-\d{2}$/.test(key)) continue;
          if (!byDay.has(key)) byDay.set(key, { families: 0, babysitters: 0 });
          const v = byDay.get(key)!;
          const n = typeof row.cnt === "string" ? parseInt(row.cnt, 10) : Number(row.cnt);
          const role = String(row.role ?? "").toLowerCase();
          if (role === "family") v.families += Number.isFinite(n) ? n : 0;
          if (role === "sitter") v.babysitters += Number.isFinite(n) ? n : 0;
        }
        const chart = [...byDay.entries()]
          .sort((a, b) => a[0].localeCompare(b[0]))
          .slice(-14)
          .map(([d, v]) => ({
            month: d.slice(5),
            families: v.families,
            babysitters: v.babysitters,
          }));
        setRegistrationData(chart);
      } catch {
        if (!cancelled) setRegistrationData([]);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  useEffect(() => {
    let cancelled = false;
    void (async () => {
      setRevenueError(null);
      try {
        const rows = await fetchReportRevenuePerMonth(6);
        if (!cancelled) setRevenueRows(rows);
      } catch (e) {
        if (!cancelled)
          setRevenueError(formatSupabaseError(e));
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  useEffect(() => {
    let cancelled = false;
    void (async () => {
      setOnboardingLoading(true);
      setOnboardingError(null);
      try {
        const rows = await fetchRecentOnboarding(30);
        if (!cancelled) setOnboardingRows(rows);
      } catch (e) {
        if (!cancelled)
          setOnboardingError(formatSupabaseError(e));
      } finally {
        if (!cancelled) setOnboardingLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  const familiesTotal = stats?.families_total ?? 0;
  const familiesApproved = stats?.families_approved_bg ?? 0;
  const familiesPending = stats?.families_pending_bg ?? 0;
  const sittersTotal = stats?.sitters_total ?? 0;
  const verifiedRate =
    familiesTotal > 0
      ? Math.round((familiesApproved / familiesTotal) * 100)
      : 0;

  return (
    <div className="space-y-6">
      {/* Page header */}
      <div>
        <h1 className="text-[32px] leading-[40px] font-bold text-white">
          Dashboard Overview
        </h1>
        <p className="mt-1 text-[15px] text-[#94a3b8]">
          Platform metrics and recent activity
        </p>
      </div>

      {statsError || revenueError || onboardingError ? (
        <div className="space-y-2">
          {statsError ? (
            <p
              role="alert"
              className="rounded-lg border border-red-500/40 bg-red-950/40 px-3 py-2 text-sm text-red-200"
            >
              {statsError}
            </p>
          ) : null}
          {revenueError ? (
            <p
              role="alert"
              className="rounded-lg border border-red-500/40 bg-red-950/40 px-3 py-2 text-sm text-red-200"
            >
              Revenue chart: {revenueError}
            </p>
          ) : null}
          {onboardingError ? (
            <p
              role="alert"
              className="rounded-lg border border-red-500/40 bg-red-950/40 px-3 py-2 text-sm text-red-200"
            >
              Recent onboarding: {onboardingError}
            </p>
          ) : null}
        </div>
      ) : null}

      {/* Stat cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard
          label="Total Registered Families"
          value={familiesTotal.toLocaleString()}
          caption={stats ? "Live from Supabase" : "Loading…"}
          icon={<Users className="w-5 h-5" strokeWidth={1.75} />}
          iconColor="#5eead4"
        />
        <StatCard
          label="Verified Families"
          value={familiesApproved.toLocaleString()}
          caption={stats ? `${verifiedRate}% verification rate` : "Loading…"}
          icon={<UserCheck className="w-5 h-5" strokeWidth={1.75} />}
          iconColor="#34d399"
        />
        <StatCard
          label="Pending Family Verifications"
          value={familiesPending.toLocaleString()}
          caption={stats ? "Requires attention" : "Loading…"}
          icon={<Clock className="w-5 h-5" strokeWidth={1.75} />}
          iconColor="#fbbf24"
        />
        <StatCard
          label="Total Babysitters"
          value={sittersTotal.toLocaleString()}
          caption={stats ? "Live from Supabase" : "Loading…"}
          icon={<Smile className="w-5 h-5" strokeWidth={1.75} />}
          iconColor="#c4b5fd"
        />
      </div>

      {/* Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <ChartCard
          title="User Registration Trends"
          subtitle="Monthly registrations for families and babysitters"
        >
          {mounted && (
            <ResponsiveContainer width="100%" height={300}>
              <LineChart data={registrationData} margin={{ top: 12, right: 12, left: -16, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="#334155" strokeOpacity={0.4} vertical={false} />
                <XAxis dataKey="month" stroke="#64748b" fontSize={12} tickLine={false} axisLine={{ stroke: "#334155", strokeOpacity: 0.4 }} />
                <YAxis stroke="#64748b" fontSize={12} tickLine={false} axisLine={false} domain={[0, 60]} ticks={[0, 15, 30, 45, 60]} />
                <Tooltip
                  contentStyle={{
                    backgroundColor: "#1e293b",
                    border: "1px solid #334155",
                    borderRadius: 10,
                    fontSize: 13,
                  }}
                  labelStyle={{ color: "#fff" }}
                  itemStyle={{ color: "#cbd5e1" }}
                />
                <Legend
                  iconType="circle"
                  iconSize={8}
                  wrapperStyle={{ fontSize: 13, color: "#cbd5e1", paddingTop: 8 }}
                />
                <Line
                  type="monotone"
                  dataKey="families"
                  name="Families"
                  stroke="#7dd3fc"
                  strokeWidth={2}
                  dot={{ r: 4, fill: "#7dd3fc", strokeWidth: 0 }}
                  activeDot={{ r: 5 }}
                />
                <Line
                  type="monotone"
                  dataKey="babysitters"
                  name="Babysitters"
                  stroke="#c4b5fd"
                  strokeWidth={2}
                  dot={{ r: 4, fill: "#c4b5fd", strokeWidth: 0 }}
                  activeDot={{ r: 5 }}
                />
              </LineChart>
            </ResponsiveContainer>
          )}
        </ChartCard>

        <ChartCard
          title="Revenue Trends"
          subtitle="Monthly sitter earnings posted to the ledger (last 6 months)"
        >
          {mounted && revenueRows.length > 0 && (
            <ResponsiveContainer width="100%" height={300}>
              <BarChart data={revenueRows} margin={{ top: 12, right: 12, left: -8, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="#334155" strokeOpacity={0.4} vertical={false} />
                <XAxis dataKey="month" stroke="#64748b" fontSize={12} tickLine={false} axisLine={{ stroke: "#334155", strokeOpacity: 0.4 }} />
                <YAxis
                  stroke="#64748b"
                  fontSize={12}
                  tickLine={false}
                  axisLine={false}
                  domain={[0, revenueYMax]}
                />
                <Tooltip
                  cursor={{ fill: "#334155", fillOpacity: 0.2 }}
                  contentStyle={{
                    backgroundColor: "#1e293b",
                    border: "1px solid #334155",
                    borderRadius: 10,
                    fontSize: 13,
                  }}
                  labelStyle={{ color: "#fff" }}
                  itemStyle={{ color: "#cbd5e1" }}
                  formatter={(v) => [`$${Number(v).toLocaleString()}`, "Revenue"]}
                />
                <Bar dataKey="revenue" fill="#86efac" radius={[6, 6, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          )}
          {mounted && revenueRows.length === 0 && !revenueError && (
            <p className="text-[14px] text-[#94a3b8] py-12 text-center">
              No ledger revenue in the last six months.
            </p>
          )}
        </ChartCard>
      </div>

      {/* Recent Onboarding */}
      <section className="bg-[#1e293b]/60 backdrop-blur-md border border-white/10 rounded-2xl p-6 shadow-[0_24px_60px_-30px_rgba(0,0,0,0.6)]">
        <div className="mb-5">
          <h2 className="text-[18px] leading-[26px] font-semibold text-white">
            Recent Onboarding
          </h2>
          <p className="mt-1 text-[14px] text-[#94a3b8]">
            Latest registered families and babysitters
          </p>
        </div>

        <div className="overflow-x-auto custom-scrollbar">
          <table className="w-full min-w-[820px]">
            <thead>
              <tr className="border-b border-[#334155]/50">
                <th className="text-left text-[13px] font-medium text-[#94a3b8] py-3 pr-4 w-[140px]">Type</th>
                <th className="text-left text-[13px] font-medium text-[#94a3b8] py-3 pr-4">Name</th>
                <th className="text-left text-[13px] font-medium text-[#94a3b8] py-3 pr-4">Email</th>
                <th className="text-left text-[13px] font-medium text-[#94a3b8] py-3 pr-4 w-[160px]">Registration Date</th>
                <th className="text-left text-[13px] font-medium text-[#94a3b8] py-3 pr-4 w-[140px]">Status</th>
                <th className="text-right text-[13px] font-medium text-[#94a3b8] py-3 pl-4 w-[120px]">Actions</th>
              </tr>
            </thead>
            <tbody>
              {onboardingRows.map((row) => (
                <tr
                  key={`${row.type}-${row.email}-${row.date}`}
                  className="border-b border-[#334155]/30 last:border-0"
                >
                  <td className="py-4 pr-4">
                    <TypeBadge type={row.type} />
                  </td>
                  <td className="py-4 pr-4 text-[14px] text-white whitespace-nowrap">{row.name}</td>
                  <td className="py-4 pr-4 text-[14px] text-[#94a3b8] whitespace-nowrap">{row.email}</td>
                  <td className="py-4 pr-4 text-[14px] text-[#94a3b8] whitespace-nowrap">{row.date}</td>
                  <td className="py-4 pr-4">
                    <StatusBadge status={row.status} />
                  </td>
                  <td className="py-4 pl-4 text-right">
                    <button
                      type="button"
                      onClick={() => setSelectedDetails(row.details)}
                      className="text-[14px] text-white hover:text-[#b8e0f0] transition-colors"
                    >
                      View Details
                    </button>
                  </td>
                </tr>
              ))}
              {onboardingRows.length === 0 && (
                <tr>
                  <td colSpan={6} className="py-10 text-center text-[14px] text-[#94a3b8]">
                    {onboardingLoading ? "Loading recent signups…" : "No onboarding records yet."}
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </section>

      <OnboardingDetailsModal
        isOpen={selectedDetails !== null}
        onClose={() => setSelectedDetails(null)}
        data={selectedDetails}
      />
    </div>
  );
}

function StatCard({
  label,
  value,
  caption,
  icon,
  iconColor,
}: {
  label: string;
  value: string;
  caption: string;
  icon: React.ReactNode;
  iconColor: string;
}) {
  return (
    <div className="bg-[#1e293b]/60 backdrop-blur-md border border-white/10 rounded-2xl p-5 shadow-[0_24px_60px_-30px_rgba(0,0,0,0.6)]">
      <div className="flex items-start justify-between gap-3">
        <p className="text-[13px] leading-[18px] font-medium text-[#94a3b8]">
          {label}
        </p>
        <span style={{ color: iconColor }} className="flex-shrink-0">
          {icon}
        </span>
      </div>
      <p className="mt-4 text-[32px] leading-[40px] font-bold text-white">
        {value}
      </p>
      <div className="mt-3 flex items-center gap-1.5 text-[12px] text-[#94a3b8]">
        <CheckCircle2 className="w-3.5 h-3.5 text-[#34d399]" strokeWidth={2} />
        <span>{caption}</span>
      </div>
    </div>
  );
}

function ChartCard({
  title,
  subtitle,
  children,
}: {
  title: string;
  subtitle: string;
  children: React.ReactNode;
}) {
  return (
    <div className="bg-[#1e293b]/60 backdrop-blur-md border border-white/10 rounded-2xl p-6 shadow-[0_24px_60px_-30px_rgba(0,0,0,0.6)]">
      <div className="mb-4">
        <h3 className="text-[16px] leading-[24px] font-semibold text-white">{title}</h3>
        <p className="mt-1 text-[13px] text-[#94a3b8]">{subtitle}</p>
      </div>
      {children}
    </div>
  );
}

function TypeBadge({ type }: { type: OnboardingType }) {
  const styles =
    type === "Family"
      ? "bg-[#334155]/50 text-[#cbd5e1] border-[#475569]/40"
      : "bg-[#a78bfa]/15 text-[#c4b5fd] border-[#a78bfa]/25";
  return (
    <span
      className={`inline-flex items-center px-2.5 py-1 rounded-md border text-[12px] font-medium ${styles}`}
    >
      {type}
    </span>
  );
}

function StatusBadge({ status }: { status: OnboardingStatus }) {
  if (status === "Verified") {
    return (
      <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-md bg-[#34d399]/15 border border-[#34d399]/25 text-[#34d399] text-[12px] font-medium">
        <CheckCircle2 className="w-3.5 h-3.5" strokeWidth={2} />
        Verified
      </span>
    );
  }
  return (
    <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-md bg-[#a78bfa]/15 border border-[#a78bfa]/25 text-[#c4b5fd] text-[12px] font-medium">
      <Clock className="w-3.5 h-3.5" strokeWidth={2} />
      Pending
    </span>
  );
}
