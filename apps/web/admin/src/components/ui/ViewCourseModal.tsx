"use client";

import React, { useEffect } from "react";
import Image from "next/image";
import { X, BookOpen, Award, Pencil, ChevronDown } from "lucide-react";

type CourseStatus = "Active" | "Draft" | "Archived";

export interface ViewCourseData {
  id: string;
  title: string;
  createdDate: string;
  status: CourseStatus;
  providesCertificate: boolean;
  description: string;
  category: string;
  level: string;
  durationHours: number;
  modulesCount: number;
  instructor: string;
  price: number;
  enrolled: number;
  requirements: string;
  learningObjectives: string;
}

interface Props {
  isOpen: boolean;
  onClose: () => void;
  data: ViewCourseData | null;
  onStatusChange: (status: CourseStatus) => void;
  onEdit: () => void;
}

export function ViewCourseModal({
  isOpen,
  onClose,
  data,
  onStatusChange,
  onEdit,
}: Props) {
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
          <div className="flex items-start justify-between gap-4 mb-3">
            <div className="min-w-0">
              <div className="flex items-center gap-2.5">
                <BookOpen className="w-6 h-6 text-white flex-shrink-0" strokeWidth={1.75} />
                <h2 className="text-[22px] leading-[28px] font-bold text-white truncate">
                  {data.title}
                </h2>
              </div>
              <p className="mt-1.5 text-[14px] text-[#94a3b8]">
                Created on {data.createdDate}
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

          {/* Pills + status select row */}
          <div className="flex items-center justify-between gap-3 mb-7 flex-wrap">
            <div className="flex items-center gap-2">
              <StatusPill status={data.status} />
              {data.providesCertificate && (
                <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-md border border-[#22c55e]/40 text-[#22c55e] text-[12px] font-medium">
                  <Award className="w-3.5 h-3.5" strokeWidth={1.75} />
                  Certificate
                </span>
              )}
            </div>
            <div className="relative">
              <select
                value={data.status}
                onChange={(e) => onStatusChange(e.target.value as CourseStatus)}
                className="appearance-none h-[36px] bg-transparent border border-white/15 rounded-[8px] pl-4 pr-9 text-[13px] text-white focus:outline-none focus:border-[#b8e0f0]/60 transition-all"
              >
                <option value="Active">Set to Active</option>
                <option value="Draft">Set to Draft</option>
                <option value="Archived">Set to Archived</option>
              </select>
              <ChevronDown className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-[#94a3b8] pointer-events-none" />
            </div>
          </div>

          {/* Description */}
          <h3 className="text-[15px] leading-[22px] font-medium text-white mb-3">
            Description
          </h3>
          <div className="bg-[#0f172a]/60 border border-white/10 rounded-[12px] px-5 py-4 mb-7">
            <p className="text-[15px] leading-[24px] text-[#94a3b8]">
              {data.description}
            </p>
          </div>

          {/* Course Details */}
          <h3 className="text-[15px] leading-[22px] font-medium text-white mb-4">
            Course Details
          </h3>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-x-6 gap-y-5 mb-7">
            <Field label="Category" value={data.category} />
            <Field label="Level" value={data.level} />
            <Field label="Duration" value={`${data.durationHours} hours`} />
            <Field label="Modules" value={`${data.modulesCount} modules`} />
            <Field label="Instructor" value={data.instructor} />
            <Field label="Price" value={`$${data.price.toFixed(2)}`} />
            <Field label="Enrolled Students" value={`${data.enrolled} students`} />
            <Field label="Created Date" value={data.createdDate} />
          </div>

          {/* Requirements */}
          <h3 className="text-[15px] leading-[22px] font-medium text-white mb-3">
            Requirements
          </h3>
          <div className="bg-[#0f172a]/60 border border-white/10 rounded-[12px] px-5 py-4 mb-6">
            <p className="text-[14px] leading-[22px] text-[#cbd5e1]">
              {data.requirements}
            </p>
          </div>

          {/* Learning Objectives */}
          <h3 className="text-[15px] leading-[22px] font-medium text-white mb-3">
            Learning Objectives
          </h3>
          <div className="bg-[#0f172a]/60 border border-white/10 rounded-[12px] px-5 py-4 mb-7">
            <p className="text-[14px] leading-[22px] text-[#cbd5e1]">
              {data.learningObjectives}
            </p>
          </div>

          {/* Edit Course button */}
          <button
            onClick={onEdit}
            className="w-full inline-flex items-center justify-center gap-2 h-[48px] bg-[#0f172a]/70 border border-white/10 hover:bg-[#0f172a]/90 text-white text-[15px] font-semibold rounded-[12px] transition-all"
          >
            <Pencil className="w-[18px] h-[18px]" strokeWidth={1.75} />
            Edit Course
          </button>
        </div>
      </div>
    </div>
  );
}

function Field({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <p className="text-[13px] text-[#94a3b8] mb-1">{label}</p>
      <p className="text-[15px] text-white font-medium break-words">{value}</p>
    </div>
  );
}

function StatusPill({ status }: { status: CourseStatus }) {
  if (status === "Active") {
    return (
      <span className="inline-flex items-center px-3 py-1 rounded-md bg-[#22c55e] text-white text-[12px] font-semibold">
        Active
      </span>
    );
  }
  if (status === "Draft") {
    return (
      <span className="inline-flex items-center px-3 py-1 rounded-md bg-[#a78bfa]/40 border border-[#a78bfa]/50 text-white text-[12px] font-semibold">
        Draft
      </span>
    );
  }
  return (
    <span className="inline-flex items-center px-3 py-1 rounded-md bg-[#94a3b8]/30 text-white text-[12px] font-semibold">
      Archived
    </span>
  );
}
