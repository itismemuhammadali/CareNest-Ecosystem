"use client";

import React, { useEffect, useState } from "react";
import Image from "next/image";
import { X, AlertTriangle, CheckCircle2 } from "lucide-react";

export type DisputePriority = "High" | "Medium" | "Low";
export type DisputeStatus = "Open" | "Investigating" | "Resolved";

export interface DisputeMessage {
  author: string;
  body: string;
  timestamp: string;
}

export interface DisputeDetail {
  id: string;
  jobId: string;
  reportedBy: string;
  issueType: string;
  priority: DisputePriority;
  status: DisputeStatus;
  description: string;
  clockIn: string;
  clockOut: string;
  calculatedHours: string;
  calculatedWage: string;
  messageHistory: DisputeMessage[];
  resolutionNotes?: string;
}

interface Props {
  isOpen: boolean;
  onClose: () => void;
  data: DisputeDetail | null;
  onResolve?: (notes: string) => void;
  onUpdateStatus?: (status: DisputeStatus) => void;
}

export function DisputeDetailsModal({
  isOpen,
  onClose,
  data,
  onResolve,
  onUpdateStatus,
}: Props) {
  const [notes, setNotes] = useState("");

  useEffect(() => {
    if (!isOpen) {
      setNotes("");
      return;
    }
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [isOpen, onClose]);

  if (!isOpen || !data) return null;

  const isResolved = data.status === "Resolved";

  return (
    <div
      className="fixed inset-0 z-[100] flex items-center justify-center bg-[#0f172a]/40 p-4 animate-in fade-in duration-200"
      onClick={onClose}
    >
      <div
        role="dialog"
        aria-modal="true"
        onClick={(e) => e.stopPropagation()}
        className="relative w-full max-w-[640px] max-h-[92vh] overflow-hidden border border-white/10 rounded-2xl shadow-[0_24px_60px_-20px_rgba(0,0,0,0.6)] animate-in zoom-in-95 duration-200"
      >
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

        <div className="relative max-h-[92vh] overflow-y-auto custom-scrollbar px-7 py-7">
          {/* Header */}
          <div className="flex items-start justify-between gap-4 mb-7">
            <div>
              <h2 className="text-[24px] leading-[30px] font-bold text-white">
                Dispute Details
              </h2>
              <p className="mt-1 text-[14px] text-[#94a3b8]">
                Review and resolve the reported issue
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
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-x-6 gap-y-6 mb-7">
            <Field label="Dispute ID" value={data.id} />
            <Field label="Job ID" value={data.jobId} />
            <Field label="Reported By" value={data.reportedBy} />
            <Field label="Issue Type" value={data.issueType} />
            <div>
              <p className="text-[14px] text-[#94a3b8] mb-2">Priority</p>
              <PriorityPill priority={data.priority} />
            </div>
            <div>
              <p className="text-[14px] text-[#94a3b8] mb-2">Status</p>
              <StatusPill status={data.status} />
            </div>
          </div>

          {/* Issue Description */}
          <h3 className="text-[15px] leading-[22px] font-medium text-white mb-3">
            Issue Description
          </h3>
          <div className="bg-[#0f172a]/60 border border-white/10 rounded-[12px] px-5 py-4 mb-7">
            <p className="text-[15px] text-white">{data.description}</p>
          </div>

          {/* Session Information */}
          <h3 className="text-[15px] leading-[22px] font-medium text-white mb-3">
            Session Information
          </h3>
          <div className="bg-[#0f172a]/60 border border-white/10 rounded-[12px] px-5 py-4 mb-7 space-y-3">
            <SessionRow label="Clock In:" value={data.clockIn} />
            <SessionRow label="Clock Out:" value={data.clockOut} />
            <SessionRow label="Calculated Hours:" value={data.calculatedHours} />
            <SessionRow label="Calculated Wage:" value={data.calculatedWage} />
          </div>

          {/* Message History */}
          <h3 className="text-[15px] leading-[22px] font-medium text-white mb-3">
            Message History
          </h3>
          <div className="space-y-3 mb-7">
            {data.messageHistory.map((msg, idx) => (
              <div
                key={idx}
                className="bg-[#0f172a]/60 border border-white/10 rounded-[12px] px-5 py-4"
              >
                <p className="text-[15px] font-semibold text-white">{msg.author}</p>
                <p className="mt-1 text-[14px] text-[#cbd5e1]">&ldquo;{msg.body}&rdquo;</p>
                <p className="mt-1 text-[12px] text-[#94a3b8]">{msg.timestamp}</p>
              </div>
            ))}
          </div>

          {/* Resolution Notes (Open / Investigating only) */}
          {!isResolved && (
            <>
              <h3 className="text-[15px] leading-[22px] font-medium text-white mb-3">
                Resolution Notes
              </h3>
              <textarea
                value={notes}
                onChange={(e) => setNotes(e.target.value)}
                placeholder="Enter resolution details and actions taken..."
                rows={4}
                className="w-full bg-[#0f172a]/60 border border-white/10 rounded-[12px] px-4 py-3 text-[15px] text-white placeholder:text-[#64748b] focus:outline-none focus:border-[#b8e0f0]/60 focus:ring-2 focus:ring-[#b8e0f0]/15 transition-all resize-none mb-7"
              />

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <button
                  onClick={() => {
                    onResolve?.(notes);
                    onClose();
                  }}
                  className="inline-flex items-center justify-center gap-2 h-[48px] bg-[#10b981] hover:bg-[#059669] text-white text-[15px] font-semibold rounded-[12px] transition-all"
                >
                  <CheckCircle2 className="w-[18px] h-[18px]" strokeWidth={2} />
                  Mark as Resolved
                </button>
                <button
                  onClick={() => {
                    onUpdateStatus?.(data.status === "Open" ? "Investigating" : "Open");
                  }}
                  className="inline-flex items-center justify-center h-[48px] bg-transparent border border-white/15 hover:bg-white/5 text-white text-[15px] font-semibold rounded-[12px] transition-all"
                >
                  Update Status
                </button>
              </div>
            </>
          )}

          {/* Resolved notice */}
          {isResolved && (
            <div className="bg-[#10b981]/10 border border-[#10b981]/40 rounded-[12px] px-5 py-4">
              <div className="flex items-start gap-2.5">
                <CheckCircle2
                  className="w-5 h-5 text-[#10b981] flex-shrink-0 mt-0.5"
                  strokeWidth={2}
                />
                <div>
                  <p className="text-[15px] font-semibold text-white">
                    This dispute has been resolved
                  </p>
                  {data.resolutionNotes && (
                    <p className="mt-2 text-[13px] text-[#94a3b8]">
                      Resolution notes: {data.resolutionNotes}
                    </p>
                  )}
                </div>
              </div>
            </div>
          )}
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

function SessionRow({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex items-center justify-between gap-3">
      <span className="text-[14px] text-[#94a3b8]">{label}</span>
      <span className="text-[14px] text-white font-medium text-right">{value}</span>
    </div>
  );
}

function PriorityPill({ priority }: { priority: DisputePriority }) {
  if (priority === "High") {
    return (
      <span className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-md bg-[#ef4444] text-white text-[13px] font-semibold">
        <AlertTriangle className="w-3.5 h-3.5" strokeWidth={2.5} />
        High
      </span>
    );
  }
  if (priority === "Medium") {
    return (
      <span className="inline-flex items-center px-3 py-1.5 rounded-md bg-[#a78bfa]/40 border border-[#a78bfa]/50 text-white text-[13px] font-semibold">
        Medium
      </span>
    );
  }
  return (
    <span className="inline-flex items-center px-3 py-1.5 rounded-md bg-[#fbbf24]/30 border border-[#fbbf24]/40 text-[#fbbf24] text-[13px] font-semibold">
      Low
    </span>
  );
}

function StatusPill({ status }: { status: DisputeStatus }) {
  if (status === "Open") {
    return (
      <span className="inline-flex items-center px-3 py-1.5 rounded-md bg-[#10b981]/15 border border-[#10b981]/40 text-[#10b981] text-[13px] font-semibold">
        Open
      </span>
    );
  }
  if (status === "Investigating") {
    return (
      <span className="inline-flex items-center px-3 py-1.5 rounded-md bg-[#f59e0b] text-white text-[13px] font-semibold">
        Investigating
      </span>
    );
  }
  return (
    <span className="inline-flex items-center px-3 py-1.5 rounded-md bg-[#3b82f6]/15 border border-[#3b82f6]/40 text-[#60a5fa] text-[13px] font-semibold">
      Resolved
    </span>
  );
}
