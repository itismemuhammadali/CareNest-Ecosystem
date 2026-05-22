"use client";

import React, { useEffect } from "react";
import Image from "next/image";
import { X } from "lucide-react";

type VerificationStatus = "Approved" | "Pending" | "Rejected";
type BackgroundCheckStatus = "Completed" | "Pending" | "Failed";

export interface UploadedDocument {
  name: string;
  uploadedDate: string;
}

export interface FamilyProfile {
  familyId: string;
  familyName: string;
  email: string;
  registrationDate: string;
  verificationStatus: VerificationStatus;
  backgroundCheck: BackgroundCheckStatus;
  homeAddress: string;
  uploadedDocuments: UploadedDocument[];
}

interface Props {
  isOpen: boolean;
  onClose: () => void;
  data: FamilyProfile | null;
}

export function FamilyDetailsModal({ isOpen, onClose, data }: Props) {
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
                Family Details
              </h2>
              <p className="mt-1 text-[14px] text-[#94a3b8]">
                Complete profile and verification information
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
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-x-6 gap-y-6 mb-6">
            <Field label="Family ID" value={data.familyId} />
            <Field label="Family Name" value={data.familyName} />
            <Field label="Email" value={data.email} />
            <Field label="Registration Date" value={data.registrationDate} />
          </div>

          {/* Status badges grid */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-x-6 gap-y-6 mb-6">
            <div>
              <p className="text-[14px] text-[#94a3b8] mb-2">Verification Status</p>
              <VerificationBadge status={data.verificationStatus} />
            </div>
            <div>
              <p className="text-[14px] text-[#94a3b8] mb-2">Background Check</p>
              <BackgroundBadge status={data.backgroundCheck} />
            </div>
          </div>

          {/* Address */}
          <div className="mb-7">
            <p className="text-[14px] text-[#94a3b8] mb-2">Home Address</p>
            <p className="text-[16px] text-white font-medium">
              {data.homeAddress}
            </p>
          </div>

          {/* Uploaded Documents */}
          <div>
            <h3 className="text-[15px] leading-[22px] font-medium text-[#94a3b8] mb-3">
              Uploaded Documents
            </h3>
            <div className="space-y-3">
              {data.uploadedDocuments.map((doc) => (
                <div
                  key={doc.name}
                  className="bg-[#0f172a]/60 border border-white/10 rounded-[12px] px-5 py-4"
                >
                  <p className="text-[15px] font-semibold text-white">
                    {doc.name}
                  </p>
                  <p className="mt-1 text-[13px] text-[#94a3b8]">
                    Uploaded: {doc.uploadedDate}
                  </p>
                </div>
              ))}
            </div>
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

function VerificationBadge({ status }: { status: VerificationStatus }) {
  const styles =
    status === "Approved"
      ? "bg-[#34d399]/15 border-[#34d399]/25 text-[#34d399]"
      : status === "Rejected"
      ? "bg-[#ef4444]/15 border-[#ef4444]/25 text-[#ef4444]"
      : "bg-[#a78bfa]/15 border-[#a78bfa]/25 text-[#c4b5fd]";
  return (
    <span
      className={`inline-flex items-center px-3 py-1.5 rounded-md border text-[13px] font-medium ${styles}`}
    >
      {status}
    </span>
  );
}

function BackgroundBadge({ status }: { status: BackgroundCheckStatus }) {
  const styles =
    status === "Completed"
      ? "bg-[#34d399]/15 border-[#34d399]/25 text-[#34d399]"
      : status === "Failed"
      ? "bg-[#ef4444]/15 border-[#ef4444]/25 text-[#ef4444]"
      : "bg-[#a78bfa]/15 border-[#a78bfa]/25 text-[#c4b5fd]";
  return (
    <span
      className={`inline-flex items-center px-3 py-1.5 rounded-md border text-[13px] font-medium ${styles}`}
    >
      {status}
    </span>
  );
}
