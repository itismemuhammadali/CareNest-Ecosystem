"use client";

import React, { useEffect } from "react";
import Image from "next/image";
import { X, CheckCircle2, Clock } from "lucide-react";

type Status = "Verified" | "Pending";

export interface FamilyDetails {
  type: "Family";
  name: string;
  registeredOn: string;
  status: Status;
  email: string;
  phone: string;
  address: string;
  numberOfChildren: number;
  childrenAges: string;
  backgroundCheck: string;
  preferredRate: string;
}

export interface BabysitterDetails {
  type: "Babysitter";
  name: string;
  registeredOn: string;
  status: Status;
  email: string;
  phone: string;
  address: string;
  yearsOfExperience: number;
  ageGroups: string;
  backgroundCheck: string;
  hourlyRate: string;
}

export type OnboardingDetails = FamilyDetails | BabysitterDetails;

interface Props {
  isOpen: boolean;
  onClose: () => void;
  data: OnboardingDetails | null;
}

export function OnboardingDetailsModal({ isOpen, onClose, data }: Props) {
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
        className="relative w-full max-w-[600px] max-h-[90vh] overflow-hidden border border-white/10 rounded-2xl shadow-[0_24px_60px_-20px_rgba(0,0,0,0.6)] animate-in zoom-in-95 duration-200"
      >
        {/* Card's own starry background */}
        <div className="absolute inset-0 -z-10">
          <Image
            src="/login-bg.png"
            alt=""
            fill
            sizes="600px"
            className="object-cover"
          />
          <div className="absolute inset-0 bg-[#1e293b]/85" />
        </div>

        <div className="relative max-h-[90vh] overflow-y-auto custom-scrollbar px-7 py-7">

        {/* Header */}
        <div className="flex items-start justify-between gap-4 mb-6">
          <div className="min-w-0">
            <div className="flex items-center gap-3">
              <span className="inline-flex items-center px-2.5 py-1 rounded-md bg-[#22c55e]/15 border border-[#22c55e]/25 text-[#22c55e] text-[12px] font-medium">
                {data.type}
              </span>
              <h2 className="text-[26px] leading-[32px] font-bold text-white truncate">
                {data.name}
              </h2>
            </div>
            <p className="mt-1.5 text-[14px] text-[#94a3b8]">
              Registered on {data.registeredOn}
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

        {/* Verification Status */}
        <Section title="Verification Status">
          {data.status === "Verified" ? (
            <span className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-md bg-[#22c55e]/15 border border-[#22c55e]/25 text-[#22c55e] text-[13px] font-medium">
              <CheckCircle2 className="w-4 h-4" strokeWidth={2} />
              Verified
            </span>
          ) : (
            <span className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-md bg-[#a78bfa]/15 border border-[#a78bfa]/25 text-[#c4b5fd] text-[13px] font-medium">
              <Clock className="w-4 h-4" strokeWidth={2} />
              Pending
            </span>
          )}
        </Section>

        {/* Contact Information */}
        <Section title="Contact Information">
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-x-6 gap-y-5">
            <Field label="Email" value={data.email} />
            <Field label="Phone" value={data.phone} />
            <div className="sm:col-span-2">
              <Field label="Address" value={data.address} />
            </div>
          </div>
        </Section>

        {/* Type-specific details */}
        {data.type === "Family" ? (
          <Section title="Family Details">
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-x-6 gap-y-5">
              <Field label="Number of Children" value={String(data.numberOfChildren)} />
              <Field label="Children Ages" value={data.childrenAges} />
              <div className="sm:col-span-2">
                <Field label="Background Check" value={data.backgroundCheck} />
              </div>
              <div className="sm:col-span-2">
                <Field label="Preferred Rate" value={data.preferredRate} />
              </div>
            </div>
          </Section>
        ) : (
          <Section title="Babysitter Details">
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-x-6 gap-y-5">
              <Field label="Years of Experience" value={String(data.yearsOfExperience)} />
              <Field label="Age Groups" value={data.ageGroups} />
              <div className="sm:col-span-2">
                <Field label="Background Check" value={data.backgroundCheck} />
              </div>
              <div className="sm:col-span-2">
                <Field label="Hourly Rate" value={data.hourlyRate} />
              </div>
            </div>
          </Section>
        )}
        </div>
      </div>
    </div>
  );
}

function Section({
  title,
  children,
}: {
  title: string;
  children: React.ReactNode;
}) {
  return (
    <div className="mb-7 last:mb-0">
      <h3 className="text-[15px] leading-[22px] font-semibold text-white mb-3">
        {title}
      </h3>
      {children}
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
