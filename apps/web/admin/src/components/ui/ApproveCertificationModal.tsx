"use client";

import React, { useEffect } from "react";
import Image from "next/image";
import { CheckCircle2 } from "lucide-react";

interface Props {
  isOpen: boolean;
  onClose: () => void;
  onConfirm: () => void;
  babysitterName: string;
  courseName: string;
  score: number;
}

export function ApproveCertificationModal({
  isOpen,
  onClose,
  onConfirm,
  babysitterName,
  courseName,
  score,
}: Props) {
  useEffect(() => {
    if (!isOpen) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [isOpen, onClose]);

  if (!isOpen) return null;

  return (
    <div
      className="fixed inset-0 z-[100] flex items-center justify-center bg-[#0f172a]/40 p-4 animate-in fade-in duration-200"
      onClick={onClose}
    >
      <div
        role="dialog"
        aria-modal="true"
        onClick={(e) => e.stopPropagation()}
        className="relative w-full max-w-[600px] overflow-hidden border border-white/10 rounded-2xl shadow-[0_24px_60px_-20px_rgba(0,0,0,0.6)] animate-in zoom-in-95 duration-200"
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

        <div className="relative px-7 py-7">
          <h2 className="text-[24px] leading-[30px] font-bold text-white mb-3">
            Approve Certification
          </h2>
          <p className="text-[15px] leading-[24px] text-[#94a3b8] mb-6">
            Confirm that you want to approve this certification submission.
          </p>

          {/* Info inset */}
          <div className="bg-[#0f172a]/60 border border-white/10 rounded-[12px] px-5 py-4 mb-7">
            <div className="flex items-start gap-3">
              <CheckCircle2
                className="w-5 h-5 text-[#34d399] flex-shrink-0 mt-0.5"
                strokeWidth={2}
              />
              <div className="min-w-0">
                <p className="text-[16px] font-semibold text-white">
                  {babysitterName}
                </p>
                <p className="mt-1 text-[14px] text-[#94a3b8]">
                  {courseName} <span className="mx-1">•</span> Score: {score}%
                </p>
                <p className="mt-3 text-[14px] text-white">
                  Certificate will be issued and the babysitter will be notified.
                </p>
              </div>
            </div>
          </div>

          {/* Buttons */}
          <div className="flex justify-end gap-3">
            <button
              onClick={onClose}
              className="px-6 h-[44px] bg-transparent border border-[#334155] text-white text-[15px] font-semibold rounded-[10px] hover:bg-white/5 transition-all"
            >
              Cancel
            </button>
            <button
              onClick={() => {
                onConfirm();
                onClose();
              }}
              className="inline-flex items-center gap-2 px-6 h-[44px] bg-[#10b981]/20 hover:bg-[#10b981]/30 border border-[#10b981]/40 text-[#34d399] text-[15px] font-semibold rounded-[10px] transition-all"
            >
              <CheckCircle2 className="w-[18px] h-[18px]" strokeWidth={2} />
              Approve Certification
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
