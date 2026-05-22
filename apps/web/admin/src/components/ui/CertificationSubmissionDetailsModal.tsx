"use client";

import React, { useEffect } from "react";
import Image from "next/image";
import { X, CheckCircle2, XCircle } from "lucide-react";

type SubmissionStatus = "Pending" | "Approved" | "Rejected";

export interface CertificationSubmissionDetail {
  submissionId: string;
  babysitterName: string;
  courseName: string;
  submissionDate: string;
  score: number;
  status: SubmissionStatus;
  questionsAnswered: string;
  correctAnswers: string;
  timeTaken: string;
}

interface Props {
  isOpen: boolean;
  onClose: () => void;
  data: CertificationSubmissionDetail | null;
  onApprove: () => void;
  onReject: () => void;
}

export function CertificationSubmissionDetailsModal({
  isOpen,
  onClose,
  data,
  onApprove,
  onReject,
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
          <div className="flex items-start justify-between gap-4 mb-7">
            <div>
              <h2 className="text-[24px] leading-[30px] font-bold text-white">
                Certification Submission Details
              </h2>
              <p className="mt-1 text-[14px] text-[#94a3b8]">
                Review babysitter&apos;s certification submission
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
            <Field label="Submission ID" value={data.submissionId} />
            <Field label="Babysitter Name" value={data.babysitterName} />
            <Field label="Course Name" value={data.courseName} />
            <Field label="Submission Date" value={data.submissionDate} />
            <div>
              <p className="text-[14px] text-[#94a3b8] mb-1.5">Score</p>
              <p className="text-[18px] text-white font-bold">{data.score}%</p>
            </div>
            <div>
              <p className="text-[14px] text-[#94a3b8] mb-2">Status</p>
              <StatusPill status={data.status} />
            </div>
          </div>

          {/* Exam Results */}
          <h3 className="text-[15px] leading-[22px] font-medium text-[#94a3b8] mb-3">
            Exam Results
          </h3>
          <div className="bg-[#0f172a]/60 border border-white/10 rounded-[12px] px-5 py-4 mb-7 space-y-3">
            <ResultRow label="Questions Answered:" value={data.questionsAnswered} />
            <ResultRow label="Correct Answers:" value={data.correctAnswers} />
            <ResultRow label="Time Taken:" value={data.timeTaken} />
          </div>

          {/* Action buttons */}
          {data.status === "Pending" && (
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <button
                onClick={onApprove}
                className="inline-flex items-center justify-center gap-2 h-[48px] bg-[#10b981]/20 hover:bg-[#10b981]/30 border border-[#10b981]/40 text-[#34d399] text-[15px] font-semibold rounded-[10px] transition-all"
              >
                <CheckCircle2 className="w-[18px] h-[18px]" strokeWidth={2} />
                Approve Certification
              </button>
              <button
                onClick={onReject}
                className="inline-flex items-center justify-center gap-2 h-[48px] bg-[#ef4444] hover:bg-[#dc2626] text-white text-[15px] font-semibold rounded-[10px] transition-all"
              >
                <XCircle className="w-[18px] h-[18px]" strokeWidth={2} />
                Reject Certification
              </button>
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

function ResultRow({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex items-center justify-between">
      <span className="text-[14px] text-white">{label}</span>
      <span className="text-[14px] text-white font-semibold">{value}</span>
    </div>
  );
}

function StatusPill({ status }: { status: SubmissionStatus }) {
  if (status === "Approved") {
    return (
      <span className="inline-flex items-center px-3 py-1.5 rounded-md bg-[#34d399]/15 border border-[#34d399]/25 text-[#34d399] text-[13px] font-medium">
        Approved
      </span>
    );
  }
  if (status === "Rejected") {
    return (
      <span className="inline-flex items-center px-3 py-1.5 rounded-md bg-[#ef4444]/15 border border-[#ef4444]/25 text-[#ef4444] text-[13px] font-medium">
        Rejected
      </span>
    );
  }
  return (
    <span className="inline-flex items-center px-3 py-1.5 rounded-md bg-[#a78bfa]/40 border border-[#a78bfa]/50 text-white text-[13px] font-medium">
      Pending
    </span>
  );
}
