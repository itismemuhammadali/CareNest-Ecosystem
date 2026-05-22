"use client";

import React, { useEffect } from "react";
import Image from "next/image";
import { X } from "lucide-react";

type CertificationStatus = "Certified" | "Pending";
type AccountStatus = "Active" | "Pending" | "Suspended";

export interface BabysitterCertification {
  name: string;
  status: "Expires" | "Completed";
  date: string;
}

export interface BabysitterProfile {
  babysitterId: string;
  fullName: string;
  age: number;
  email: string;
  certificationStatus: CertificationStatus;
  accountStatus: AccountStatus;
  guardian: {
    name: string;
    relation: string;
    email: string;
    phone: string;
    consentVerified: boolean;
  };
  certifications: BabysitterCertification[];
  totalHoursWorked: number;
  totalEarnings: number;
}

interface Props {
  isOpen: boolean;
  onClose: () => void;
  data: BabysitterProfile | null;
}

export function BabysitterDetailsModal({ isOpen, onClose, data }: Props) {
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
                Babysitter Details
              </h2>
              <p className="mt-1 text-[14px] text-[#94a3b8]">
                Complete profile and compliance information
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
            <Field label="Babysitter ID" value={data.babysitterId} />
            <Field label="Full Name" value={data.fullName} />
            <Field label="Age" value={`${data.age} years`} />
            <Field label="Email" value={data.email} />
          </div>

          {/* Status pills */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-x-6 gap-y-6 mb-7">
            <div>
              <p className="text-[14px] text-[#94a3b8] mb-2">Certification Status</p>
              <CertificationPill status={data.certificationStatus} />
            </div>
            <div>
              <p className="text-[14px] text-[#94a3b8] mb-2">Account Status</p>
              <AccountPill status={data.accountStatus} />
            </div>
          </div>

          {/* Guardian Information */}
          <h3 className="text-[15px] leading-[22px] font-medium text-[#94a3b8] mb-3">
            Guardian Information
          </h3>
          <div className="bg-[#0f172a]/60 border border-white/10 rounded-[12px] px-5 py-4 mb-7">
            <p className="text-[16px] font-semibold text-white">
              {data.guardian.name} ({data.guardian.relation})
            </p>
            <p className="mt-1 text-[14px] text-[#94a3b8]">
              {data.guardian.email} <span className="mx-1.5">•</span> {data.guardian.phone}
            </p>
            {data.guardian.consentVerified && (
              <span className="inline-flex items-center mt-3 px-3 py-1 rounded-md bg-[#22c55e] text-white text-[12px] font-semibold">
                Consent Verified
              </span>
            )}
          </div>

          {/* Certifications */}
          <h3 className="text-[15px] leading-[22px] font-medium text-[#94a3b8] mb-3">
            Certifications
          </h3>
          <div className="space-y-3 mb-7">
            {data.certifications.map((cert) => (
              <div
                key={cert.name}
                className="bg-[#0f172a]/60 border border-white/10 rounded-[12px] px-5 py-4"
              >
                <p className="text-[16px] font-semibold text-white">{cert.name}</p>
                <p className="mt-1 text-[13px] text-[#94a3b8]">
                  {cert.status}: {cert.date}
                </p>
              </div>
            ))}
          </div>

          {/* Totals */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-x-6 gap-y-6">
            <div>
              <p className="text-[14px] text-[#94a3b8] mb-1.5">Total Hours Worked</p>
              <p className="text-[24px] leading-[32px] font-bold text-white">
                {data.totalHoursWorked} hours
              </p>
            </div>
            <div>
              <p className="text-[14px] text-[#94a3b8] mb-1.5">Total Earnings</p>
              <p className="text-[24px] leading-[32px] font-bold text-white">
                ${data.totalEarnings.toLocaleString()}
              </p>
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

function CertificationPill({ status }: { status: CertificationStatus }) {
  if (status === "Certified") {
    return (
      <span className="inline-flex items-center px-3 py-1.5 rounded-md bg-[#a78bfa]/40 border border-[#a78bfa]/50 text-white text-[13px] font-medium">
        Certified
      </span>
    );
  }
  return (
    <span className="inline-flex items-center px-3 py-1.5 rounded-md bg-[#a78bfa]/15 border border-[#a78bfa]/25 text-[#c4b5fd] text-[13px] font-medium">
      Pending
    </span>
  );
}

function AccountPill({ status }: { status: AccountStatus }) {
  if (status === "Active") {
    return (
      <span className="inline-flex items-center px-3 py-1.5 rounded-md bg-[#22c55e] text-white text-[13px] font-semibold">
        Active
      </span>
    );
  }
  if (status === "Suspended") {
    return (
      <span className="inline-flex items-center px-3 py-1.5 rounded-md bg-[#ef4444] text-white text-[13px] font-semibold">
        Suspended
      </span>
    );
  }
  return (
    <span className="inline-flex items-center px-3 py-1.5 rounded-md bg-[#a78bfa]/15 border border-[#a78bfa]/25 text-[#c4b5fd] text-[13px] font-medium">
      Pending
    </span>
  );
}
