"use client";

import React, { useCallback, useEffect, useState } from "react";
import { Eye, Trash2, CheckCircle2, XCircle } from "lucide-react";
import {
  adminDeleteCourse,
  approveCertificationSubmission,
  courseCertTabStatusFromDb,
  fetchAdminCoursesWithStats,
  fetchCertificationSubmissionsAdmin,
  rejectCertificationSubmission,
  type AdminCourseWithStats,
  type CertificationSubmissionRow,
} from "@/lib/supabase/admin";
import { formatSupabaseError } from "@/lib/supabase/errors";
import {
  CourseDetailsModal,
  type CourseProfile,
} from "@/components/ui/CourseDetailsModal";
import { DeleteCourseModal } from "@/components/ui/DeleteCourseModal";
import {
  CertificationSubmissionDetailsModal,
  type CertificationSubmissionDetail,
} from "@/components/ui/CertificationSubmissionDetailsModal";
import { ApproveCertificationModal } from "@/components/ui/ApproveCertificationModal";
import { RejectCertificationModal } from "@/components/ui/RejectCertificationModal";

type CourseStatus = "Published" | "Draft" | "Archived";

interface Course {
  id: string;
  name: string;
  category: string;
  createdDate: string;
  status: CourseStatus;
  enrolled: number;
  completion: number;
  description: string;
  modules: string[];
}

function mapDbCourse(c: AdminCourseWithStats): Course {
  const mods = Array.isArray(c.modules) ? c.modules : [];
  const completion = Math.min(100, Math.round(c.completion_avg));
  return {
    id: c.id,
    name: c.name,
    category: c.category,
    createdDate: (c.created_at ?? "").slice(0, 10),
    status: courseCertTabStatusFromDb(c.status),
    enrolled: c.submissions_count,
    completion,
    description: c.description ?? "",
    modules: mods.length ? mods : ["(No modules listed)"],
  };
}

function toCourseProfile(c: Course): CourseProfile {
  return {
    courseId: c.id,
    courseName: c.name,
    category: c.category,
    createdDate: c.createdDate,
    status: c.status,
    enrolledStudents: c.enrolled,
    completionRate: c.completion,
    description: c.description,
    modules: c.modules,
  };
}

type ApprovalStatus = "Pending" | "Approved" | "Rejected";

interface CertificationSubmission {
  id: string;
  babysitterName: string;
  courseName: string;
  submissionDate: string;
  score: number;
  status: ApprovalStatus;
  questionsAnswered: string;
  correctAnswers: string;
  timeTaken: string;
}

function joinUser(
  u:
    | { full_name: string | null; email: string }
    | { full_name: string | null; email: string }[]
    | null
    | undefined,
): { full_name: string | null; email: string } | null {
  if (!u) return null;
  if (Array.isArray(u)) return u[0] ?? null;
  return u;
}

function joinCourse(
  c: { name: string } | { name: string }[] | null | undefined,
): { name: string } | null {
  if (!c) return null;
  if (Array.isArray(c)) return c[0] ?? null;
  return c;
}

function mapSubRow(r: CertificationSubmissionRow): CertificationSubmission {
  const u = joinUser(r.sitter);
  const co = joinCourse(r.course);
  const name = u?.full_name?.trim() || u?.email || "Unknown";
  const courseName = co?.name ?? "Course";
  const score = r.score != null ? Math.round(Number(r.score)) : 0;
  const qa = r.questions_answered;
  const ca = r.correct_answers;
  const questionsAnswered =
    qa != null && ca != null ? `${ca}/${qa}` : qa != null ? `—/${qa}` : "—";
  const correctAnswers = qa != null && ca != null ? `${ca}/${qa}` : "—";
  const mins =
    r.time_taken_seconds != null ? Math.max(1, Math.round(r.time_taken_seconds / 60)) : null;
  const timeTaken = mins != null ? `${mins} minutes` : "—";
  const st: ApprovalStatus =
    r.status === "approved" ? "Approved" : r.status === "rejected" ? "Rejected" : "Pending";
  return {
    id: r.id,
    babysitterName: name,
    courseName,
    submissionDate: (r.submitted_at ?? "").slice(0, 10),
    score,
    status: st,
    questionsAnswered,
    correctAnswers,
    timeTaken,
  };
}

function toSubmissionDetail(s: CertificationSubmission): CertificationSubmissionDetail {
  return {
    submissionId: s.id,
    babysitterName: s.babysitterName,
    courseName: s.courseName,
    submissionDate: s.submissionDate,
    score: s.score,
    status: s.status,
    questionsAnswered: s.questionsAnswered,
    correctAnswers: s.correctAnswers,
    timeTaken: s.timeTaken,
  };
}

type Tab = "courses" | "approvals";

export default function CertificationsPage() {
  const [activeTab, setActiveTab] = useState<Tab>("courses");
  const [courses, setCourses] = useState<Course[]>([]);
  const [approvals, setApprovals] = useState<CertificationSubmission[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedCourse, setSelectedCourse] = useState<CourseProfile | null>(null);
  const [deleteTarget, setDeleteTarget] = useState<Course | null>(null);

  const [activeSub, setActiveSub] = useState<CertificationSubmission | null>(null);
  const [activeSubModal, setActiveSubModal] = useState<"details" | "approve" | "reject" | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const [crows, subs] = await Promise.all([
        fetchAdminCoursesWithStats(),
        fetchCertificationSubmissionsAdmin(),
      ]);
      setCourses(crows.map(mapDbCourse));
      setApprovals(subs.map(mapSubRow));
    } catch (e) {
      setError(formatSupabaseError(e));
      setCourses([]);
      setApprovals([]);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  const openSubModal = (sub: CertificationSubmission, modal: "details" | "approve" | "reject") => {
    setActiveSub(sub);
    setActiveSubModal(modal);
  };

  const closeSubModal = () => {
    setActiveSubModal(null);
    setActiveSub(null);
  };

  const handleDeleteCourse = async (id: string) => {
    try {
      await adminDeleteCourse(id);
      await load();
    } catch (e) {
      setError(formatSupabaseError(e));
    }
  };

  const pendingCount = approvals.filter((a) => a.status === "Pending").length;
  const totalEnrolled = courses.reduce((s, c) => s + c.enrolled, 0);
  const activeCourses = courses.filter((c) => c.status === "Published").length;
  const withSubs = courses.filter((c) => c.enrolled > 0);
  const avgCompletion =
    withSubs.length > 0
      ? Math.round(withSubs.reduce((s, c) => s + c.completion, 0) / withSubs.length)
      : 0;

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-[32px] leading-[40px] font-bold text-white">
          Certifications &amp; Training Management
        </h1>
        <p className="mt-1 text-[15px] text-[#94a3b8]">
          Manage courses, training materials, and certification approvals
        </p>
        {error && (
          <p className="mt-2 text-[13px] text-red-400" role="alert">
            {error}
          </p>
        )}
        {loading && <p className="mt-2 text-[13px] text-[#94a3b8]">Loading…</p>}
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <SimpleStatCard label="Active Courses" value={String(activeCourses)} valueColor="text-white" />
        <SimpleStatCard label="Total Enrollments" value={String(totalEnrolled)} valueColor="text-[#34d399]" />
        <SimpleStatCard label="Pending Approvals" value={String(pendingCount)} valueColor="text-[#c4b5fd]" />
        <SimpleStatCard
          label="Avg Completion Rate"
          value={loading ? "—" : `${avgCompletion}%`}
          valueColor="text-[#34d399]"
        />
      </div>

      <div className="inline-flex items-center gap-2 bg-[#0f172a]/60 border border-white/10 rounded-full p-1.5">
        <TabButton active={activeTab === "courses"} onClick={() => setActiveTab("courses")}>
          Course Management
        </TabButton>
        <TabButton active={activeTab === "approvals"} onClick={() => setActiveTab("approvals")}>
          Certification Approvals
        </TabButton>
      </div>

      {activeTab === "courses" ? (
        <section className="bg-[#1e293b]/60 backdrop-blur-md border border-white/10 rounded-2xl p-6 shadow-[0_24px_60px_-30px_rgba(0,0,0,0.6)]">
          <h2 className="text-[18px] leading-[26px] font-semibold text-white mb-5">
            All Courses
          </h2>

          <div className="overflow-x-auto custom-scrollbar">
            <table className="w-full min-w-[860px]">
              <thead>
                <tr className="border-b border-[#334155]/50">
                  <Th>Course Name</Th>
                  <Th>Category</Th>
                  <Th>Created Date</Th>
                  <Th>Status</Th>
                  <Th>Enrolled</Th>
                  <Th>Completion</Th>
                  <Th align="right">Actions</Th>
                </tr>
              </thead>
              <tbody>
                {courses.map((c) => (
                  <tr
                    key={c.id}
                    className="border-b border-[#334155]/30 last:border-0"
                  >
                    <td className="py-4 pr-4 text-[14px] text-white whitespace-nowrap">{c.name}</td>
                    <td className="py-4 pr-4 text-[14px] text-[#94a3b8]">{c.category}</td>
                    <td className="py-4 pr-4 text-[14px] text-[#94a3b8] whitespace-nowrap">{c.createdDate}</td>
                    <td className="py-4 pr-4">
                      <CourseStatusBadge status={c.status} />
                    </td>
                    <td className="py-4 pr-4 text-[14px] text-white">{c.enrolled}</td>
                    <td className="py-4 pr-4 text-[14px] text-white">{c.completion}%</td>
                    <td className="py-4 pl-4">
                      <div className="flex items-center justify-end gap-1">
                        <button
                          type="button"
                          onClick={() => setSelectedCourse(toCourseProfile(c))}
                          aria-label="View course"
                          className="p-1.5 text-[#94a3b8] hover:text-white transition-colors"
                        >
                          <Eye className="w-[18px] h-[18px]" strokeWidth={1.75} />
                        </button>
                        <button
                          type="button"
                          onClick={() => setDeleteTarget(c)}
                          aria-label="Delete course"
                          className="p-1.5 text-[#ef4444] hover:text-[#dc2626] transition-colors"
                        >
                          <Trash2 className="w-[18px] h-[18px]" strokeWidth={1.75} />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
                {courses.length === 0 && !loading && (
                  <tr>
                    <td colSpan={7} className="py-10 text-center text-[14px] text-[#94a3b8]">
                      No courses yet.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </section>
      ) : (
        <section className="bg-[#1e293b]/60 backdrop-blur-md border border-white/10 rounded-2xl p-6 shadow-[0_24px_60px_-30px_rgba(0,0,0,0.6)]">
          <h2 className="text-[18px] leading-[26px] font-semibold text-white mb-5">
            Certification Submissions
          </h2>

          <div className="overflow-x-auto custom-scrollbar">
            <table className="w-full min-w-[820px]">
              <thead>
                <tr className="border-b border-[#334155]/50">
                  <Th>Babysitter Name</Th>
                  <Th>Course Name</Th>
                  <Th>Submission Date</Th>
                  <Th>Score</Th>
                  <Th>Status</Th>
                  <Th align="right">Actions</Th>
                </tr>
              </thead>
              <tbody>
                {approvals.map((a) => (
                  <tr
                    key={a.id}
                    className="border-b border-[#334155]/30 last:border-0"
                  >
                    <td className="py-4 pr-4 text-[14px] text-white whitespace-nowrap">{a.babysitterName}</td>
                    <td className="py-4 pr-4 text-[14px] text-white">{a.courseName}</td>
                    <td className="py-4 pr-4 text-[14px] text-[#94a3b8] whitespace-nowrap">{a.submissionDate}</td>
                    <td className="py-4 pr-4 text-[14px] font-bold text-white">{a.score}%</td>
                    <td className="py-4 pr-4">
                      <ApprovalBadge status={a.status} />
                    </td>
                    <td className="py-4 pl-4">
                      <div className="flex items-center justify-end gap-1">
                        <button
                          type="button"
                          onClick={() => openSubModal(a, "details")}
                          aria-label="View submission"
                          className="p-1.5 text-[#94a3b8] hover:text-white transition-colors"
                        >
                          <Eye className="w-[18px] h-[18px]" strokeWidth={1.75} />
                        </button>
                        {a.status === "Pending" && (
                          <>
                            <button
                              type="button"
                              onClick={() => openSubModal(a, "approve")}
                              aria-label="Approve"
                              className="p-1.5 text-[#34d399] hover:text-[#22c55e] transition-colors"
                            >
                              <CheckCircle2 className="w-[18px] h-[18px]" strokeWidth={1.75} />
                            </button>
                            <button
                              type="button"
                              onClick={() => openSubModal(a, "reject")}
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
                {approvals.length === 0 && !loading && (
                  <tr>
                    <td colSpan={6} className="py-10 text-center text-[14px] text-[#94a3b8]">
                      No certification submissions.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </section>
      )}

      <CourseDetailsModal
        isOpen={selectedCourse !== null}
        onClose={() => setSelectedCourse(null)}
        data={selectedCourse}
      />

      <DeleteCourseModal
        isOpen={deleteTarget !== null}
        onClose={() => setDeleteTarget(null)}
        onConfirm={() => {
          if (deleteTarget) void handleDeleteCourse(deleteTarget.id);
          setDeleteTarget(null);
        }}
        courseName={deleteTarget?.name ?? ""}
        category={deleteTarget?.category ?? ""}
        enrolled={deleteTarget?.enrolled ?? 0}
      />

      <CertificationSubmissionDetailsModal
        isOpen={activeSubModal === "details" && activeSub !== null}
        onClose={closeSubModal}
        data={activeSub ? toSubmissionDetail(activeSub) : null}
        onApprove={() => setActiveSubModal("approve")}
        onReject={() => setActiveSubModal("reject")}
      />

      <ApproveCertificationModal
        isOpen={activeSubModal === "approve" && activeSub !== null}
        onClose={closeSubModal}
        onConfirm={() => {
          if (!activeSub) return;
          void (async () => {
            try {
              await approveCertificationSubmission(activeSub.id);
              closeSubModal();
              await load();
            } catch (e) {
              setError(formatSupabaseError(e));
            }
          })();
        }}
        babysitterName={activeSub?.babysitterName ?? ""}
        courseName={activeSub?.courseName ?? ""}
        score={activeSub?.score ?? 0}
      />

      <RejectCertificationModal
        isOpen={activeSubModal === "reject" && activeSub !== null}
        onClose={closeSubModal}
        onConfirm={(reason) => {
          if (!activeSub) return;
          void (async () => {
            try {
              await rejectCertificationSubmission(activeSub.id, reason);
              closeSubModal();
              await load();
            } catch (e) {
              setError(formatSupabaseError(e));
            }
          })();
        }}
        babysitterName={activeSub?.babysitterName ?? ""}
        courseName={activeSub?.courseName ?? ""}
        score={activeSub?.score ?? 0}
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

function TabButton({
  active,
  onClick,
  children,
}: {
  active: boolean;
  onClick: () => void;
  children: React.ReactNode;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`px-6 h-[40px] rounded-full text-[14px] font-medium transition-all ${
        active
          ? "bg-[#1e293b]/90 border border-white/20 text-white"
          : "border border-transparent text-[#94a3b8] hover:text-white"
      }`}
    >
      {children}
    </button>
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

function ApprovalBadge({ status }: { status: ApprovalStatus }) {
  if (status === "Approved") {
    return (
      <span className="inline-flex items-center px-2.5 py-1 rounded-md bg-[#34d399]/15 border border-[#34d399]/25 text-[#34d399] text-[12px] font-medium">
        Approved
      </span>
    );
  }
  if (status === "Rejected") {
    return (
      <span className="inline-flex items-center px-2.5 py-1 rounded-md bg-[#ef4444]/15 border border-[#ef4444]/25 text-[#ef4444] text-[12px] font-medium">
        Rejected
      </span>
    );
  }
  return (
    <span className="inline-flex items-center px-2.5 py-1 rounded-md bg-[#a78bfa]/15 border border-[#a78bfa]/25 text-[#c4b5fd] text-[12px] font-medium">
      Pending
    </span>
  );
}

function CourseStatusBadge({ status }: { status: CourseStatus }) {
  if (status === "Published") {
    return (
      <span className="inline-flex items-center px-2.5 py-1 rounded-md bg-[#34d399]/15 border border-[#34d399]/25 text-[#34d399] text-[12px] font-medium">
        Published
      </span>
    );
  }
  if (status === "Draft") {
    return (
      <span className="inline-flex items-center px-2.5 py-1 rounded-md bg-[#7dd3fc]/15 border border-[#7dd3fc]/25 text-[#7dd3fc] text-[12px] font-medium">
        Draft
      </span>
    );
  }
  return (
    <span className="inline-flex items-center px-2.5 py-1 rounded-md bg-[#94a3b8]/15 border border-[#94a3b8]/25 text-[#94a3b8] text-[12px] font-medium">
      Archived
    </span>
  );
}
