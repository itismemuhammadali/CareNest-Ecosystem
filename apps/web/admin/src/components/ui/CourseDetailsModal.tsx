"use client";

import React, { useEffect } from "react";
import Image from "next/image";
import { X } from "lucide-react";

type CourseStatus = "Published" | "Draft" | "Archived";

export interface CourseProfile {
  courseId: string;
  courseName: string;
  category: string;
  createdDate: string;
  status: CourseStatus;
  enrolledStudents: number;
  completionRate: number;
  description: string;
  modules: string[];
}

interface Props {
  isOpen: boolean;
  onClose: () => void;
  data: CourseProfile | null;
}

export function CourseDetailsModal({ isOpen, onClose, data }: Props) {
  useEffect(() => {
    if (!isOpen) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [isOpen, onClose]);

  if (!isOpen || !data) return null;

  return (
    <div
      className="fixed inset-0 z-[100] flex items-center justify-center bg-[#0f172a]/40 p-4 animate-in fade-in duration-200"
      onClick={onClose}
    >
      <div
        role="dialog"
        aria-modal="true"
        onClick={(e) => e.stopPropagation()}
        className="relative w-full max-w-[640px] max-h-[90vh] overflow-hidden border border-white/10 rounded-2xl shadow-[0_24px_60px_-20px_rgba(0,0,0,0.6)] animate-in zoom-in-95 duration-200"
      >
        {/* Card's own starry background */}
        <div className="absolute inset-0 -z-10">
          <Image
            src="/login-bg.png"
            alt=""
            fill
            sizes="640px"
            className="object-cover"
          />
          <div className="absolute inset-0 bg-[#1e293b]/85" />
        </div>

        <div className="relative max-h-[90vh] overflow-y-auto custom-scrollbar px-7 py-7">
          {/* Header */}
          <div className="flex items-start justify-between gap-4 mb-7">
            <div>
              <h2 className="text-[24px] leading-[30px] font-bold text-white">
                Course Details
              </h2>
              <p className="mt-1 text-[14px] text-[#94a3b8]">
                Complete information about this course
              </p>
            </div>
            <button
              onClick={onClose}
              aria-label="Close"
              className="flex-shrink-0 p-1.5 text-[#94a3b8] hover:text-white transition-colors"
            >
              <X className="w-5 h-5" strokeWidth={2} />
            </button>
          </div>

          {/* Basic info */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-x-6 gap-y-6 mb-6">
            <Field label="Course ID" value={data.courseId} />
            <Field label="Course Name" value={data.courseName} />
            <Field label="Category" value={data.category} />
            <Field label="Created Date" value={data.createdDate} />

            <div>
              <p className="text-[14px] text-[#94a3b8] mb-2">Status</p>
              <StatusPill status={data.status} />
            </div>
            <Field label="Enrolled Students" value={String(data.enrolledStudents)} />

            <div className="sm:col-span-2">
              <Field label="Completion Rate" value={`${data.completionRate}%`} />
            </div>
          </div>

          {/* Description */}
          <h3 className="text-[15px] leading-[22px] font-medium text-[#94a3b8] mb-3">
            Course Description
          </h3>
          <div className="bg-[#0f172a]/60 border border-white/10 rounded-[12px] px-5 py-4 mb-7">
            <p className="text-[15px] leading-[24px] text-white">
              {data.description}
            </p>
          </div>

          {/* Modules */}
          <h3 className="text-[15px] leading-[22px] font-medium text-[#94a3b8] mb-3">
            Course Modules
          </h3>
          <div className="space-y-3">
            {data.modules.map((m) => (
              <div
                key={m}
                className="bg-[#0f172a]/60 border border-white/10 rounded-[12px] px-5 py-4"
              >
                <p className="text-[15px] font-medium text-white">{m}</p>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

function Field({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <p className="text-[14px] text-[#94a3b8] mb-1.5">{label}</p>
      <p className="text-[16px] text-white font-medium break-words">{value}</p>
    </div>
  );
}

function StatusPill({ status }: { status: CourseStatus }) {
  if (status === "Published") {
    return (
      <span className="inline-flex items-center px-3 py-1.5 rounded-md bg-[#22c55e]/15 border border-[#22c55e]/30 text-[#22c55e] text-[13px] font-medium">
        Published
      </span>
    );
  }
  if (status === "Draft") {
    return (
      <span className="inline-flex items-center px-3 py-1.5 rounded-md bg-[#7dd3fc]/15 border border-[#7dd3fc]/25 text-[#7dd3fc] text-[13px] font-medium">
        Draft
      </span>
    );
  }
  return (
    <span className="inline-flex items-center px-3 py-1.5 rounded-md bg-[#94a3b8]/15 border border-[#94a3b8]/25 text-[#94a3b8] text-[13px] font-medium">
      Archived
    </span>
  );
}
