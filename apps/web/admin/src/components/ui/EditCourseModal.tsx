"use client";

import React, { useEffect, useState } from "react";
import Image from "next/image";
import { X, ChevronDown, Check } from "lucide-react";

type CourseStatus = "Active" | "Draft" | "Archived";

export interface EditCourseData {
  title: string;
  description: string;
  category: string;
  level: string;
  instructor: string;
  duration: string;
  modulesCount: number;
  price: number;
  requirements: string;
  learningObjectives: string;
  providesCertificate: boolean;
  status: CourseStatus;
}

interface Props {
  isOpen: boolean;
  onClose: () => void;
  initialData: EditCourseData | null;
  onSubmit: (data: EditCourseData) => void;
}

const CATEGORIES = ["Safety", "Child Care", "Behavioral", "Health", "Education"];
const LEVELS = ["Beginner", "Intermediate", "Advanced"];

export function EditCourseModal({
  isOpen,
  onClose,
  initialData,
  onSubmit,
}: Props) {
  const [form, setForm] = useState<EditCourseData | null>(null);

  useEffect(() => {
    if (isOpen && initialData) {
      setForm(initialData);
    }
  }, [isOpen, initialData]);

  useEffect(() => {
    if (!isOpen) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [isOpen, onClose]);

  if (!isOpen || !form) return null;

  const update = <K extends keyof EditCourseData>(key: K, value: EditCourseData[K]) => {
    setForm({ ...form, [key]: value });
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.title.trim()) return;
    onSubmit(form);
    onClose();
  };

  return (
    <div
      className="fixed inset-0 z-[100] flex items-center justify-center bg-[#0f172a]/40 p-4 animate-in fade-in duration-200"
      onClick={onClose}
    >
      <div
        role="dialog"
        aria-modal="true"
        onClick={(e) => e.stopPropagation()}
        className="relative w-full max-w-[680px] max-h-[92vh] overflow-hidden border border-white/10 rounded-2xl shadow-[0_24px_60px_-20px_rgba(0,0,0,0.6)] animate-in zoom-in-95 duration-200"
      >
        <div className="absolute inset-0 -z-10">
          <Image
            src="/login-bg.png"
            alt=""
            fill
            sizes="680px"
            className="object-cover"
          />
          <div className="absolute inset-0 bg-[#1e293b]/85" />
        </div>

        <form
          onSubmit={handleSubmit}
          className="relative max-h-[92vh] overflow-y-auto custom-scrollbar px-7 py-7"
        >
          {/* Header */}
          <div className="flex items-start justify-between gap-4 mb-2">
            <div>
              <h2 className="text-[24px] leading-[30px] font-bold text-white">
                Edit Course
              </h2>
              <p className="mt-1 text-[14px] text-[#94a3b8]">
                Update course information and details
              </p>
            </div>
            <button
              type="button"
              onClick={onClose}
              aria-label="Close"
              className="flex-shrink-0 p-1.5 text-[#94a3b8] hover:text-white transition-colors"
            >
              <X className="w-5 h-5" strokeWidth={2} />
            </button>
          </div>

          {/* Basic Information */}
          <h3 className="mt-5 text-[15px] font-semibold text-white">Basic Information</h3>

          <div className="mt-3 space-y-4">
            <FormField label="Course Title" required>
              <Input
                value={form.title}
                onChange={(v) => update("title", v)}
                placeholder="CPR & First Aid Certification"
              />
            </FormField>

            <FormField label="Description">
              <Textarea
                value={form.description}
                onChange={(v) => update("description", v)}
                placeholder="Provide a detailed description of the course..."
                rows={3}
              />
            </FormField>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <FormField label="Category" required>
                <Select
                  value={form.category}
                  onChange={(v) => update("category", v)}
                  options={CATEGORIES}
                />
              </FormField>
              <FormField label="Level">
                <Select
                  value={form.level}
                  onChange={(v) => update("level", v)}
                  options={LEVELS}
                />
              </FormField>
              <FormField label="Instructor">
                <Input
                  value={form.instructor}
                  onChange={(v) => update("instructor", v)}
                  placeholder="Dr. Sarah Johnson"
                />
              </FormField>
              <FormField label="Duration" required>
                <Input
                  value={form.duration}
                  onChange={(v) => update("duration", v)}
                  placeholder="4 hours"
                />
              </FormField>
              <FormField label="Number of Modules">
                <Input
                  type="number"
                  value={String(form.modulesCount)}
                  onChange={(v) => update("modulesCount", Number(v) || 0)}
                  placeholder="6"
                />
              </FormField>
              <FormField label="Price ($)">
                <Input
                  type="number"
                  value={String(form.price)}
                  onChange={(v) => update("price", Number(v) || 0)}
                  placeholder="49.99"
                  step="0.01"
                />
              </FormField>
            </div>
          </div>

          {/* Additional Details */}
          <h3 className="mt-7 text-[15px] font-semibold text-white">Additional Details</h3>

          <div className="mt-3 space-y-4">
            <FormField label="Requirements">
              <Textarea
                value={form.requirements}
                onChange={(v) => update("requirements", v)}
                placeholder="Prerequisites or requirements for this course..."
                rows={3}
              />
            </FormField>
            <FormField label="Learning Objectives">
              <Textarea
                value={form.learningObjectives}
                onChange={(v) => update("learningObjectives", v)}
                placeholder="What will students learn from this course..."
                rows={3}
              />
            </FormField>
          </div>

          {/* Cert checkbox + status */}
          <div className="mt-7 flex flex-col sm:flex-row sm:items-end sm:justify-between gap-4">
            <label className="inline-flex items-center gap-2.5 cursor-pointer group">
              <span className="relative inline-flex items-center justify-center w-[18px] h-[18px]">
                <input
                  type="checkbox"
                  checked={form.providesCertificate}
                  onChange={(e) => update("providesCertificate", e.target.checked)}
                  className="peer appearance-none w-full h-full rounded-[4px] border border-white/25 bg-[#0f172a]/60 checked:bg-[#b8e0f0] checked:border-[#b8e0f0] transition-colors cursor-pointer"
                />
                <Check className="absolute w-3 h-3 text-[#0a0f24] opacity-0 peer-checked:opacity-100 pointer-events-none stroke-[3]" />
              </span>
              <span className="text-[14px] text-white">Provides Certificate</span>
            </label>

            <div className="flex flex-col gap-1.5 sm:items-end">
              <label className="text-[13px] text-[#94a3b8]">Status</label>
              <Select
                value={form.status}
                onChange={(v) => update("status", v as CourseStatus)}
                options={["Active", "Draft", "Archived"]}
                className="sm:w-[180px]"
              />
            </div>
          </div>

          {/* Buttons */}
          <div className="mt-7 flex justify-end gap-3">
            <button
              type="button"
              onClick={onClose}
              className="px-6 h-[42px] bg-transparent border border-white/15 text-white text-[14px] font-medium rounded-[10px] hover:bg-white/5 transition-all"
            >
              Cancel
            </button>
            <button
              type="submit"
              className="px-6 h-[42px] bg-[#b8e0f0] hover:bg-[#c8e8f5] text-[#0a0f24] text-[14px] font-semibold rounded-[10px] transition-all"
            >
              Update Course
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

function FormField({
  label,
  required,
  children,
}: {
  label: string;
  required?: boolean;
  children: React.ReactNode;
}) {
  return (
    <div>
      <label className="block text-[13px] text-white mb-1.5">
        {label} {required && <span>*</span>}
      </label>
      {children}
    </div>
  );
}

function Input({
  value,
  onChange,
  placeholder,
  type = "text",
  step,
}: {
  value: string;
  onChange: (v: string) => void;
  placeholder?: string;
  type?: string;
  step?: string;
}) {
  return (
    <input
      type={type}
      step={step}
      value={value}
      onChange={(e) => onChange(e.target.value)}
      placeholder={placeholder}
      className="w-full h-[44px] bg-transparent border border-white rounded-[10px] px-4 text-[14px] text-white placeholder:text-[#64748b] focus:outline-none focus:border-[#b8e0f0]/60 focus:ring-2 focus:ring-[#b8e0f0]/15 transition-all"
    />
  );
}

function Textarea({
  value,
  onChange,
  placeholder,
  rows = 3,
}: {
  value: string;
  onChange: (v: string) => void;
  placeholder?: string;
  rows?: number;
}) {
  return (
    <textarea
      value={value}
      onChange={(e) => onChange(e.target.value)}
      placeholder={placeholder}
      rows={rows}
      className="w-full bg-transparent border border-white rounded-[10px] px-4 py-3 text-[14px] text-white placeholder:text-[#64748b] focus:outline-none focus:border-[#b8e0f0]/60 focus:ring-2 focus:ring-[#b8e0f0]/15 transition-all resize-none"
    />
  );
}

function Select({
  value,
  onChange,
  options,
  className = "",
}: {
  value: string;
  onChange: (v: string) => void;
  options: string[];
  className?: string;
}) {
  return (
    <div className={`relative ${className}`}>
      <select
        value={value}
        onChange={(e) => onChange(e.target.value)}
        className="appearance-none w-full h-[44px] bg-transparent border border-white rounded-[10px] pl-4 pr-10 text-[14px] text-white focus:outline-none focus:border-[#b8e0f0]/60 focus:ring-2 focus:ring-[#b8e0f0]/15 transition-all"
      >
        {options.map((o) => (
          <option key={o} value={o} className="bg-[#1e293b]">
            {o}
          </option>
        ))}
      </select>
      <ChevronDown className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-[#94a3b8] pointer-events-none" />
    </div>
  );
}
