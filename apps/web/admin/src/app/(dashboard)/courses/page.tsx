"use client";

import React, { useCallback, useEffect, useState } from "react";
import Link from "next/link";
import {
  Search,
  Filter,
  ChevronDown,
  Plus,
  BookOpen,
  CheckCircle2,
  AlertCircle,
  Users,
  Clock,
  Pencil,
  Trash2,
} from "lucide-react";
import {
  adminDeleteCourse,
  adminUpdateCourse,
  courseDbStatusFromUi,
  courseUiStatusFromDb,
  fetchAdminCoursesWithStats,
  type AdminCourseWithStats,
} from "@/lib/supabase/admin";
import { formatSupabaseError } from "@/lib/supabase/errors";
import {
  ViewCourseModal,
  type ViewCourseData,
} from "@/components/ui/ViewCourseModal";
import {
  EditCourseModal,
  type EditCourseData,
} from "@/components/ui/EditCourseModal";
import { DeleteCourseModal } from "@/components/ui/DeleteCourseModal";

type CourseStatus = "Active" | "Draft" | "Archived";
type Level = "Beginner" | "Intermediate" | "Advanced";

interface Course {
  id: string;
  title: string;
  category: string;
  instructor: string;
  durationHours: number;
  level: Level;
  enrolled: number;
  status: CourseStatus;
  createdDate: string;
  description: string;
  modulesList: string[];
  modulesCount: number;
  price: number;
  requirements: string;
  learningObjectives: string;
  providesCertificate: boolean;
  completion: number;
}

function mapRowToCourse(c: AdminCourseWithStats): Course {
  const mods = Array.isArray(c.modules) ? c.modules : [];
  const st = courseUiStatusFromDb(c.status);
  const completion = Math.min(100, Math.round(c.completion_avg));
  return {
    id: c.id,
    title: c.name,
    category: c.category,
    instructor: c.instructor?.trim() ? c.instructor : "—",
    durationHours: Number(c.duration_hours ?? 0),
    level: (c.level as Level) ?? "Beginner",
    enrolled: c.submissions_count,
    status: st,
    createdDate: (c.created_at ?? "").slice(0, 10),
    description: c.description ?? "",
    modulesList: mods.length ? [...mods] : [],
    modulesCount: mods.length || 0,
    price: Number(c.price ?? 0),
    requirements: c.requirements ?? "",
    learningObjectives: c.learning_objectives ?? "",
    providesCertificate: c.provides_certificate,
    completion,
  };
}

function adjustModulesList(existing: string[], count: number): string[] {
  const out = [...existing];
  while (out.length < count) {
    out.push(`Module ${out.length + 1}`);
  }
  return out.slice(0, Math.max(0, count));
}

/** Parse "4", "4 hours", "12.5 h" → hours number */
function parseDurationHours(raw: string, fallback: number): number {
  const m = String(raw).trim().match(/(\d+(\.\d+)?)/);
  if (!m) return fallback;
  const n = parseFloat(m[1]);
  return Number.isFinite(n) && n > 0 ? n : fallback;
}

function toViewData(c: Course): ViewCourseData {
  return {
    id: c.id,
    title: c.title,
    createdDate: c.createdDate,
    status: c.status,
    providesCertificate: c.providesCertificate,
    description: c.description,
    category: c.category,
    level: c.level,
    durationHours: c.durationHours,
    modulesCount: c.modulesCount,
    instructor: c.instructor,
    price: c.price,
    enrolled: c.enrolled,
    requirements: c.requirements,
    learningObjectives: c.learningObjectives,
  };
}

function toEditData(c: Course): EditCourseData {
  return {
    title: c.title,
    description: c.description,
    category: c.category,
    level: c.level,
    instructor: c.instructor === "—" ? "" : c.instructor,
    duration: `${c.durationHours} hours`,
    modulesCount: c.modulesCount,
    price: c.price,
    requirements: c.requirements,
    learningObjectives: c.learningObjectives,
    providesCertificate: c.providesCertificate,
    status: c.status,
  };
}

export default function CoursesPage() {
  const [courses, setCourses] = useState<Course[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [search, setSearch] = useState("");
  const [filter, setFilter] = useState<"all" | CourseStatus>("all");
  const [viewTarget, setViewTarget] = useState<Course | null>(null);
  const [editTarget, setEditTarget] = useState<Course | null>(null);
  const [deleteTarget, setDeleteTarget] = useState<Course | null>(null);

  const refresh = useCallback(async () => {
    setLoading(true);
    setLoadError(null);
    try {
      const rows = await fetchAdminCoursesWithStats();
      setCourses(rows.map(mapRowToCourse));
    } catch (e) {
      setLoadError(formatSupabaseError(e));
      setCourses([]);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void refresh();
  }, [refresh]);

  const updateCourse = async (id: string, patch: Partial<Course>) => {
    const prev = courses.find((c) => c.id === id);
    if (!prev) return;
    const next: Course = { ...prev, ...patch };
    const modules = adjustModulesList(next.modulesList, next.modulesCount);
    const merged: Course = { ...next, modulesList: modules, modulesCount: modules.length };
    try {
      await adminUpdateCourse(id, {
        name: merged.title,
        category: merged.category,
        status: courseDbStatusFromUi(merged.status),
        description: merged.description || null,
        modules,
        instructor: merged.instructor && merged.instructor !== "—" ? merged.instructor : null,
        duration_hours: merged.durationHours,
        level: merged.level,
        price: merged.price,
        requirements: merged.requirements || null,
        learning_objectives: merged.learningObjectives || null,
        provides_certificate: merged.providesCertificate,
      });
      await refresh();
      setViewTarget((vt) => (vt && vt.id === id ? merged : vt));
      setEditTarget((et) => (et && et.id === id ? merged : et));
    } catch (e) {
      setLoadError(formatSupabaseError(e));
    }
  };

  const filtered = courses.filter((c) => {
    const q = search.toLowerCase();
    const matchesSearch =
      !q ||
      c.title.toLowerCase().includes(q) ||
      c.instructor.toLowerCase().includes(q) ||
      c.category.toLowerCase().includes(q);
    const matchesFilter = filter === "all" || c.status === filter;
    return matchesSearch && matchesFilter;
  });

  const totalCourses = courses.length;
  const activeCourses = courses.filter((c) => c.status === "Active").length;
  const draftCourses = courses.filter((c) => c.status === "Draft").length;
  const totalEnrolled = courses.reduce((sum, c) => sum + c.enrolled, 0);

  const handleDelete = async (id: string) => {
    try {
      await adminDeleteCourse(id);
      await refresh();
    } catch (e) {
      setLoadError(formatSupabaseError(e));
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-4">
        <div>
          <h1 className="text-[32px] leading-[40px] font-bold text-white">
            Course Management
          </h1>
          <p className="mt-1 text-[15px] text-[#94a3b8]">
            Manage training courses and certifications for babysitters
          </p>
          {loadError && (
            <p className="mt-2 text-[13px] text-red-400" role="alert">
              {loadError}
            </p>
          )}
          {loading && (
            <p className="mt-2 text-[13px] text-[#94a3b8]">Loading courses…</p>
          )}
        </div>
        <Link
          href="/courses/create"
          className="inline-flex items-center gap-2 px-5 h-[44px] bg-[#b8e0f0] hover:bg-[#c8e8f5] text-[#0a0f24] text-[14px] font-semibold rounded-[10px] transition-all"
        >
          <Plus className="w-4 h-4" strokeWidth={2.5} />
          Create New Course
        </Link>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard
          label="Total Courses"
          value={String(totalCourses)}
          caption="All courses"
          icon={<BookOpen className="w-5 h-5" strokeWidth={1.75} />}
          iconColor="#cbd5e1"
        />
        <StatCard
          label="Active Courses"
          value={String(activeCourses)}
          caption="Currently available"
          icon={<CheckCircle2 className="w-5 h-5" strokeWidth={1.75} />}
          iconColor="#34d399"
        />
        <StatCard
          label="Draft Courses"
          value={String(draftCourses)}
          caption="In development"
          icon={<AlertCircle className="w-5 h-5" strokeWidth={1.75} />}
          iconColor="#c4b5fd"
        />
        <StatCard
          label="Total Enrolled"
          value={String(totalEnrolled)}
          caption="Certification submissions (all statuses)"
          icon={<Users className="w-5 h-5" strokeWidth={1.75} />}
          iconColor="#cbd5e1"
        />
      </div>

      <section className="bg-[#1e293b]/60 backdrop-blur-md border border-white/10 rounded-2xl p-5 shadow-[0_24px_60px_-30px_rgba(0,0,0,0.6)]">
        <div className="flex flex-col sm:flex-row gap-3">
          <div className="relative flex-1">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-[18px] h-[18px] text-[#64748b]" />
            <input
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search courses by title, instructor, or category..."
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
              value={filter}
              onChange={(e) => setFilter(e.target.value as "all" | CourseStatus)}
              className="appearance-none w-full sm:w-[180px] h-[48px] bg-[#0f172a]/60 border border-[#334155]/50 rounded-[10px] pl-4 pr-10 text-[14px] text-white focus:outline-none focus:border-[#b8e0f0]/60 focus:ring-2 focus:ring-[#b8e0f0]/15 transition-all"
            >
              <option value="all">All Courses</option>
              <option value="Active">Active</option>
              <option value="Draft">Draft</option>
              <option value="Archived">Archived</option>
            </select>
            <ChevronDown className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-[#64748b] pointer-events-none" />
          </div>
        </div>
      </section>

      <section className="bg-[#1e293b]/60 backdrop-blur-md border border-white/10 rounded-2xl p-6 shadow-[0_24px_60px_-30px_rgba(0,0,0,0.6)]">
        <h2 className="text-[18px] leading-[26px] font-semibold text-white mb-5">
          Courses ({filtered.length})
        </h2>

        <div className="overflow-x-auto custom-scrollbar">
          <table className="w-full min-w-[1020px]">
            <thead>
              <tr className="border-b border-[#334155]/50">
                <Th>Course Title</Th>
                <Th>Category</Th>
                <Th>Instructor</Th>
                <Th>Duration</Th>
                <Th>Level</Th>
                <Th>Enrolled</Th>
                <Th>Status</Th>
                <Th align="right">Actions</Th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((c) => (
                <tr
                  key={c.id}
                  className="border-b border-[#334155]/30 last:border-0"
                >
                  <td className="py-4 pr-4 whitespace-nowrap">
                    <span className="inline-flex items-center gap-2 text-[14px] text-white">
                      <BookOpen className="w-4 h-4 text-[#94a3b8]" strokeWidth={1.75} />
                      {c.title}
                    </span>
                  </td>
                  <td className="py-4 pr-4">
                    <CategoryBadge label={c.category} />
                  </td>
                  <td className="py-4 pr-4 text-[14px] text-[#94a3b8] whitespace-nowrap">
                    {c.instructor}
                  </td>
                  <td className="py-4 pr-4 whitespace-nowrap">
                    <span className="inline-flex items-center gap-1.5 text-[14px] text-[#94a3b8]">
                      <Clock className="w-3.5 h-3.5" strokeWidth={1.75} />
                      {c.durationHours} hours
                    </span>
                  </td>
                  <td className="py-4 pr-4">
                    <LevelBadge level={c.level} />
                  </td>
                  <td className="py-4 pr-4 whitespace-nowrap">
                    <span className="inline-flex items-center gap-1.5 text-[14px] text-white">
                      <Users className="w-3.5 h-3.5 text-[#94a3b8]" strokeWidth={1.75} />
                      {c.enrolled}
                    </span>
                  </td>
                  <td className="py-4 pr-4">
                    <StatusBadge status={c.status} />
                  </td>
                  <td className="py-4 pl-4">
                    <div className="flex items-center justify-end gap-3">
                      <button
                        type="button"
                        onClick={() => setViewTarget(c)}
                        className="text-[14px] text-white hover:text-[#b8e0f0] transition-colors"
                      >
                        View
                      </button>
                      <button
                        type="button"
                        onClick={() => setEditTarget(c)}
                        aria-label="Edit course"
                        className="p-1 text-[#94a3b8] hover:text-white transition-colors"
                      >
                        <Pencil className="w-[16px] h-[16px]" strokeWidth={1.75} />
                      </button>
                      <button
                        type="button"
                        onClick={() => setDeleteTarget(c)}
                        aria-label="Delete course"
                        className="p-1 text-[#ef4444] hover:text-[#dc2626] transition-colors"
                      >
                        <Trash2 className="w-[16px] h-[16px]" strokeWidth={1.75} />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
              {!loading && filtered.length === 0 && (
                <tr>
                  <td colSpan={8} className="py-10 text-center text-[14px] text-[#94a3b8]">
                    No courses match your filters.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </section>

      <ViewCourseModal
        isOpen={viewTarget !== null}
        onClose={() => setViewTarget(null)}
        data={viewTarget ? toViewData(viewTarget) : null}
        onStatusChange={(status) => {
          if (viewTarget) void updateCourse(viewTarget.id, { status });
        }}
        onEdit={() => {
          if (viewTarget) {
            const target = viewTarget;
            setViewTarget(null);
            setEditTarget(target);
          }
        }}
      />

      <EditCourseModal
        isOpen={editTarget !== null}
        onClose={() => setEditTarget(null)}
        initialData={editTarget ? toEditData(editTarget) : null}
        onSubmit={(data) => {
          if (!editTarget) return;
          const hours = parseDurationHours(data.duration, editTarget.durationHours);
          const modulesList = adjustModulesList(editTarget.modulesList, data.modulesCount);
          void updateCourse(editTarget.id, {
            title: data.title,
            description: data.description,
            category: data.category,
            level: data.level as Level,
            instructor: data.instructor.trim() || "—",
            durationHours: hours,
            modulesCount: data.modulesCount,
            modulesList,
            price: data.price,
            requirements: data.requirements,
            learningObjectives: data.learningObjectives,
            providesCertificate: data.providesCertificate,
            status: data.status,
          });
          setEditTarget(null);
        }}
      />

      <DeleteCourseModal
        isOpen={deleteTarget !== null}
        onClose={() => setDeleteTarget(null)}
        onConfirm={() => {
          if (deleteTarget) void handleDelete(deleteTarget.id);
          setDeleteTarget(null);
        }}
        courseName={deleteTarget?.title ?? ""}
        category={deleteTarget?.category ?? ""}
        enrolled={deleteTarget?.enrolled ?? 0}
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
      <p className="mt-3 text-[28px] leading-[36px] font-bold text-white">
        {value}
      </p>
      <p className="mt-1 text-[12px] text-[#94a3b8]">{caption}</p>
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

function CategoryBadge({ label }: { label: string }) {
  return (
    <span className="inline-flex items-center px-2.5 py-1 rounded-md bg-[#334155]/50 border border-white/10 text-[#cbd5e1] text-[12px] font-medium whitespace-nowrap">
      {label}
    </span>
  );
}

function LevelBadge({ level }: { level: Level }) {
  const styles =
    level === "Beginner"
      ? "bg-[#34d399]/15 border-[#34d399]/25 text-[#34d399]"
      : level === "Intermediate"
        ? "bg-[#7dd3fc]/15 border-[#7dd3fc]/30 text-[#7dd3fc]"
        : "bg-[#a78bfa]/15 border-[#a78bfa]/30 text-[#c4b5fd]";
  return (
    <span
      className={`inline-flex items-center px-2.5 py-1 rounded-md border text-[12px] font-medium ${styles}`}
    >
      {level}
    </span>
  );
}

function StatusBadge({ status }: { status: CourseStatus }) {
  if (status === "Active") {
    return (
      <span className="inline-flex items-center px-2.5 py-1 rounded-md bg-[#34d399]/15 border border-[#34d399]/25 text-[#34d399] text-[12px] font-medium">
        Active
      </span>
    );
  }
  if (status === "Draft") {
    return (
      <span className="inline-flex items-center px-2.5 py-1 rounded-md bg-[#a78bfa]/15 border border-[#a78bfa]/25 text-[#c4b5fd] text-[12px] font-medium">
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
