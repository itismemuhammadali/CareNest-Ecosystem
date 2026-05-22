"use client";

import React, { Suspense, useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { ArrowLeft, Search } from "lucide-react";
import {
  fetchAdminCoursesWithStats,
  fetchDisputes,
  fetchFamilies,
  fetchJobs,
  fetchSitters,
  type AdminCourseWithStats,
  type DisputeRow,
  type FamilyRow,
  type JobRow,
  type SitterRow,
} from "@/lib/supabase/admin";
import { formatSupabaseError } from "@/lib/supabase/errors";

function matches(q: string, ...parts: (string | null | undefined)[]) {
  const s = q.trim().toLowerCase();
  if (!s) return true;
  return parts.some((p) => (p ?? "").toLowerCase().includes(s));
}

function SearchInner() {
  const params = useSearchParams();
  const rawQ = params.get("q") ?? "";
  const q = rawQ.trim();

  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [families, setFamilies] = useState<FamilyRow[]>([]);
  const [sitters, setSitters] = useState<SitterRow[]>([]);
  const [jobs, setJobs] = useState<JobRow[]>([]);
  const [courses, setCourses] = useState<AdminCourseWithStats[]>([]);
  const [disputes, setDisputes] = useState<DisputeRow[]>([]);

  useEffect(() => {
    let cancelled = false;
    void (async () => {
      setLoading(true);
      setError(null);
      try {
        const [fam, sit, jobRows, crs, dsp] = await Promise.all([
          fetchFamilies(),
          fetchSitters(),
          fetchJobs("all", q, 1, 80),
          fetchAdminCoursesWithStats(),
          fetchDisputes(),
        ]);
        if (cancelled) return;
        setFamilies(fam);
        setSitters(sit);
        setJobs(jobRows);
        setCourses(crs);
        setDisputes(dsp);
      } catch (e) {
        if (!cancelled) setError(formatSupabaseError(e));
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [q]);

  const famHits = useMemo(() => {
    if (!q) return families.slice(0, 15);
    return families
      .filter((r) =>
        matches(q, r.full_name, r.email, r.user_id, r.home_address ?? undefined),
      )
      .slice(0, 15);
  }, [families, q]);

  const sitHits = useMemo(() => {
    if (!q) return sitters.slice(0, 15);
    return sitters
      .filter((r) => matches(q, r.full_name, r.email, r.user_id))
      .slice(0, 15);
  }, [sitters, q]);

  const courseHits = useMemo(() => {
    if (!q) return courses.slice(0, 12);
    return courses
      .filter((c) => matches(q, c.name, c.category, c.description ?? undefined))
      .slice(0, 12);
  }, [courses, q]);

  const disputeHits = useMemo(() => {
    if (!q) return disputes.slice(0, 12);
    return disputes
      .filter((d) =>
        matches(
          q,
          d.id,
          d.job_id,
          d.issue_type,
          d.description ?? undefined,
          d.reporter_email ?? undefined,
          d.reporter_name ?? undefined,
        ),
      )
      .slice(0, 12);
  }, [disputes, q]);

  const jobCountLabel = q ? `${jobs.length} (server-filtered)` : `${jobs.length} shown`;

  return (
    <div className="space-y-8">
      <div>
        <Link
          href="/dashboard"
          className="inline-flex items-center gap-2 text-[14px] text-[#94a3b8] hover:text-white mb-4"
        >
          <ArrowLeft className="w-4 h-4" />
          Back to dashboard
        </Link>
        <h1 className="text-[28px] font-bold text-white flex items-center gap-2">
          <Search className="w-7 h-7 text-[#b8e0f0]" strokeWidth={2} />
          Search
        </h1>
        <p className="mt-1 text-[15px] text-[#94a3b8]">
          {q ? (
            <>
              Results for <span className="text-white font-medium">&quot;{q}&quot;</span>
            </>
          ) : (
            "Enter a term in the header search and press Enter."
          )}
        </p>
      </div>

      {error ? (
        <p
          role="alert"
          className="rounded-lg border border-red-500/40 bg-red-950/40 px-3 py-2 text-sm text-red-200"
        >
          {error}
        </p>
      ) : null}

      {loading ? (
        <p className="text-[#94a3b8]">Loading directory…</p>
      ) : (
        <div className="grid gap-6 lg:grid-cols-2">
          <ResultCard
            title="Families"
            subtitle={
              <Link
                className="text-[#b8e0f0] hover:underline"
                href={q ? `/families?q=${encodeURIComponent(q)}` : "/families"}
              >
                Open list →
              </Link>
            }
            empty={famHits.length === 0}
          >
            {famHits.map((r) => (
              <li key={r.user_id} className="text-[14px] text-white border-b border-white/5 pb-2 mb-2 last:border-0">
                <span className="font-medium">{r.full_name?.trim() || r.email}</span>
                <span className="text-[#94a3b8] text-[13px] block">{r.email}</span>
              </li>
            ))}
          </ResultCard>

          <ResultCard
            title="Babysitters"
            subtitle={
              <Link
                className="text-[#b8e0f0] hover:underline"
                href={q ? `/babysitters?q=${encodeURIComponent(q)}` : "/babysitters"}
              >
                Open list →
              </Link>
            }
            empty={sitHits.length === 0}
          >
            {sitHits.map((r) => (
              <li key={r.user_id} className="text-[14px] text-white border-b border-white/5 pb-2 mb-2 last:border-0">
                <span className="font-medium">{r.full_name?.trim() || r.email}</span>
                <span className="text-[#94a3b8] text-[13px] block">{r.email}</span>
              </li>
            ))}
          </ResultCard>

          <ResultCard
            title="Jobs"
            subtitle={
              <span className="text-[#94a3b8]">
                {jobCountLabel}
                <Link
                  className="ml-2 text-[#b8e0f0] hover:underline"
                  href={q ? `/jobs?q=${encodeURIComponent(q)}` : "/jobs"}
                >
                  Open jobs →
                </Link>
              </span>
            }
            empty={jobs.length === 0}
          >
            {jobs.slice(0, 20).map((r) => (
              <li key={r.job_id} className="text-[14px] text-white border-b border-white/5 pb-2 mb-2 last:border-0">
                <span className="font-medium">{r.family_name ?? "—"}</span>
                <span className="text-[#94a3b8] text-[13px] block">
                  {r.sitter_name ?? "No sitter"} · {String(r.status)} · {r.job_date ?? ""}
                </span>
              </li>
            ))}
          </ResultCard>

          <ResultCard
            title="Courses"
            subtitle={<Link className="text-[#b8e0f0] hover:underline" href="/certifications">Certifications →</Link>}
            empty={courseHits.length === 0}
          >
            {courseHits.map((c) => (
              <li key={c.id} className="text-[14px] text-white border-b border-white/5 pb-2 mb-2 last:border-0">
                <span className="font-medium">{c.name}</span>
                <span className="text-[#94a3b8] text-[13px] block">{c.category}</span>
              </li>
            ))}
          </ResultCard>

          <ResultCard
            title="Disputes"
            subtitle={<Link className="text-[#b8e0f0] hover:underline" href="/disputes">Open disputes →</Link>}
            empty={disputeHits.length === 0}
          >
            {disputeHits.map((d) => (
              <li key={d.id} className="text-[14px] text-white border-b border-white/5 pb-2 mb-2 last:border-0">
                <span className="font-medium">{d.issue_type}</span>
                <span className="text-[#94a3b8] text-[13px] block">
                  {d.status} · job {d.job_id.slice(0, 8)}…
                </span>
              </li>
            ))}
          </ResultCard>
        </div>
      )}
    </div>
  );
}

function ResultCard({
  title,
  subtitle,
  empty,
  children,
}: {
  title: string;
  subtitle: React.ReactNode;
  empty: boolean;
  children: React.ReactNode;
}) {
  return (
    <section className="bg-[#1e293b]/60 backdrop-blur-md border border-white/10 rounded-2xl p-5">
      <div className="flex items-start justify-between gap-3 mb-3">
        <h2 className="text-[16px] font-semibold text-white">{title}</h2>
        <div className="text-[12px] text-right">{subtitle}</div>
      </div>
      {empty ? (
        <p className="text-[14px] text-[#64748b]">No matches.</p>
      ) : (
        <ul className="list-none p-0 m-0 max-h-[280px] overflow-y-auto">{children}</ul>
      )}
    </section>
  );
}

export default function SearchPage() {
  return (
    <Suspense
      fallback={
        <div className="text-[#94a3b8] py-12 text-center">Loading search…</div>
      }
    >
      <SearchInner />
    </Suspense>
  );
}
