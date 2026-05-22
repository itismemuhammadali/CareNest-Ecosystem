"use client";

import React, { useEffect } from "react";
import Image from "next/image";
import { X, MapPin } from "lucide-react";

export type JobStatus = "Open" | "Hired" | "In Progress" | "Completed" | "Cancelled";

export type TimelineEventKind =
  | "posted"
  | "accepted"
  | "clockIn"
  | "clockOut"
  | "cancelled";

export interface TimelineEvent {
  kind: TimelineEventKind;
  title: string;
  timestamp: string;
}

export interface JobDetail {
  id: string;
  familyName: string;
  babysitterName: string | null;
  date: string;
  status: JobStatus;
  totalHoursLabel: string;
  location: string;
  locationVerified: boolean;
  clockIn?: string;
  clockOut?: string | null;
  hourlyRate?: number;
  hoursWorked?: number;
  totalWage?: number;
  timeline: TimelineEvent[];
}

interface Props {
  isOpen: boolean;
  onClose: () => void;
  data: JobDetail | null;
}

export function JobDetailsModal({ isOpen, onClose, data }: Props) {
  useEffect(() => {
    if (!isOpen) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [isOpen, onClose]);

  if (!isOpen || !data) return null;

  const showTimeTracking =
    (data.status === "In Progress" || data.status === "Completed") &&
    data.clockIn !== undefined;
  const showWage = data.status === "Completed" && data.hourlyRate !== undefined;

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
                Job Details
              </h2>
              <p className="mt-1 text-[14px] text-[#94a3b8]">
                Complete job information and session logs
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

          {/* Basic info grid */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-x-6 gap-y-6 mb-7">
            <Field label="Job ID" value={data.id} />
            <div>
              <p className="text-[14px] text-[#94a3b8] mb-2">Status</p>
              <StatusPill status={data.status} />
            </div>
            <Field label="Family Name" value={data.familyName} />
            <Field label="Babysitter Name" value={data.babysitterName ?? "-"} muted={!data.babysitterName} />
            <Field label="Date" value={data.date} />
            <Field label="Total Hours" value={data.totalHoursLabel} />
          </div>

          {/* Time Tracking — In Progress or Completed */}
          {showTimeTracking && (
            <>
              <h3 className="text-[15px] leading-[22px] font-medium text-white mb-3">
                Time Tracking
              </h3>
              <div className="bg-[#0f172a]/60 border border-white/10 rounded-[12px] px-5 py-4 mb-7">
                <div className="grid grid-cols-2 gap-6">
                  <div>
                    <p className="text-[13px] text-[#94a3b8] mb-1">Clock In</p>
                    <p className="text-[18px] text-white font-bold">{data.clockIn}</p>
                  </div>
                  <div>
                    <p className="text-[13px] text-[#94a3b8] mb-1">Clock Out</p>
                    <p className="text-[18px] text-white font-bold">
                      {data.clockOut ?? "In progress"}
                    </p>
                  </div>
                </div>
              </div>
            </>
          )}

          {/* Wage Calculation — Completed only */}
          {showWage && (
            <>
              <h3 className="text-[15px] leading-[22px] font-medium text-white mb-3">
                Wage Calculation
              </h3>
              <div className="bg-[#0f172a]/60 border border-white/10 rounded-[12px] px-5 py-4 mb-7 space-y-3">
                <WageRow label="Hourly Rate:" value={`$${data.hourlyRate!.toFixed(2)}/hr`} />
                <WageRow label="Hours Worked:" value={`${data.hoursWorked}h`} />
                <div className="flex items-center justify-between pt-1">
                  <span className="text-[15px] font-bold text-white">Total Wage:</span>
                  <span className="text-[18px] font-bold text-[#34d399]">
                    ${data.totalWage}
                  </span>
                </div>
              </div>
            </>
          )}

          {/* GPS Location Logs */}
          <h3 className="text-[15px] leading-[22px] font-medium text-white mb-3">
            GPS Location Logs
          </h3>
          <div className="bg-[#0f172a]/60 border border-white/10 rounded-[12px] px-5 py-4 mb-7">
            <div className="flex items-start gap-3">
              <MapPin className="w-5 h-5 text-[#7dd3fc] flex-shrink-0 mt-0.5" strokeWidth={1.75} />
              <div>
                <p className="text-[15px] font-semibold text-white">{data.location}</p>
                {data.locationVerified && (
                  <p className="mt-0.5 text-[13px] text-[#94a3b8]">Verified location match</p>
                )}
              </div>
            </div>
          </div>

          {/* Session Timeline */}
          <h3 className="text-[15px] leading-[22px] font-medium text-white mb-4">
            Session Timeline
          </h3>
          <div className="space-y-5">
            {data.timeline.map((event, idx) => (
              <div key={idx} className="flex items-start gap-3">
                <span
                  className="w-2.5 h-2.5 rounded-full flex-shrink-0 mt-1.5"
                  style={{ backgroundColor: dotColor(event.kind) }}
                />
                <div>
                  <p className="text-[15px] font-semibold text-white">{event.title}</p>
                  <p className="mt-0.5 text-[13px] text-[#94a3b8]">{event.timestamp}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

function Field({
  label,
  value,
  muted = false,
}: {
  label: string;
  value: string;
  muted?: boolean;
}) {
  return (
    <div>
      <p className="text-[14px] text-[#94a3b8] mb-1.5">{label}</p>
      <p className={`text-[16px] font-medium break-words ${muted ? "text-[#94a3b8]" : "text-white"}`}>
        {value}
      </p>
    </div>
  );
}

function WageRow({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex items-center justify-between">
      <span className="text-[14px] text-white">{label}</span>
      <span className="text-[14px] text-white font-semibold">{value}</span>
    </div>
  );
}

function StatusPill({ status }: { status: JobStatus }) {
  if (status === "Completed") {
    return (
      <span className="inline-flex items-center px-3 py-1.5 rounded-md bg-[#34d399]/15 border border-[#34d399]/25 text-[#34d399] text-[13px] font-medium">
        Completed
      </span>
    );
  }
  if (status === "In Progress") {
    return (
      <span className="inline-flex items-center px-3 py-1.5 rounded-md bg-[#a3e635]/15 border border-[#a3e635]/40 text-[#a3e635] text-[13px] font-medium whitespace-nowrap">
        In Progress
      </span>
    );
  }
  if (status === "Hired") {
    return (
      <span className="inline-flex items-center px-3 py-1.5 rounded-md bg-[#fbbf24]/15 border border-[#fbbf24]/40 text-[#fbbf24] text-[13px] font-medium">
        Hired
      </span>
    );
  }
  if (status === "Cancelled") {
    return (
      <span className="inline-flex items-center px-3 py-1.5 rounded-md bg-[#ef4444]/15 border border-[#ef4444]/30 text-[#ef4444] text-[13px] font-medium">
        Cancelled
      </span>
    );
  }
  return (
    <span className="inline-flex items-center px-3 py-1.5 rounded-md bg-white text-[#0a0f24] text-[13px] font-semibold">
      Open
    </span>
  );
}

function dotColor(kind: TimelineEventKind): string {
  switch (kind) {
    case "posted":
      return "#7dd3fc";
    case "accepted":
      return "#f0abfc";
    case "clockIn":
      return "#34d399";
    case "clockOut":
      return "#34d399";
    case "cancelled":
      return "#ef4444";
  }
}
