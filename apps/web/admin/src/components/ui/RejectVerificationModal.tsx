"use client";

import React, { useEffect, useState } from "react";
import Image from "next/image";
import { X, XCircle } from "lucide-react";

interface Props {
  isOpen: boolean;
  onClose: () => void;
  onConfirm: (reason: string) => void;
  familyName: string;
  email: string;
}

export function RejectVerificationModal({
  isOpen,
  onClose,
  onConfirm,
  familyName,
  email,
}: Props) {
  const [reason, setReason] = useState("");

  useEffect(() => {
    if (!isOpen) {
      setReason("");
      return;
    }
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [isOpen, onClose]);

  if (!isOpen) return null;

  const canSubmit = reason.trim().length > 0;

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
          <div className="flex items-start justify-between gap-4 mb-2">
            <h2 className="text-[22px] leading-[28px] font-bold text-white">
              Reject Family Verification
            </h2>
            <button
              onClick={onClose}
              className="flex-shrink-0 p-1.5 text-[#94a3b8] hover:text-white transition-colors"
              aria-label="Close"
            >
              <X className="w-5 h-5" strokeWidth={2} />
            </button>
          </div>
          <p className="text-[14px] leading-[22px] text-[#94a3b8] mb-6">
            Please provide a reason for rejecting this family&apos;s verification.
            This will be sent to the family.
          </p>

          {/* Family info inset card */}
          <div className="bg-[#0f172a]/60 border border-white/10 rounded-[12px] px-5 py-4 mb-6">
            <p className="text-[16px] font-semibold text-white">{familyName}</p>
            <p className="mt-0.5 text-[14px] text-[#94a3b8]">{email}</p>
          </div>

          <label
            htmlFor="rejection-reason"
            className="block text-[14px] font-medium text-white mb-2"
          >
            Reason for Rejection <span className="text-[#ef4444]">*</span>
          </label>
          <textarea
            id="rejection-reason"
            value={reason}
            onChange={(e) => setReason(e.target.value)}
            placeholder="E.g., Documents are unclear or incomplete, background check issues, etc."
            rows={5}
            className="w-full bg-[#0f172a]/60 border border-[#334155]/50 rounded-[12px] px-4 py-3 text-[15px] text-white placeholder:text-[#64748b] focus:outline-none focus:border-[#b8e0f0]/60 focus:ring-2 focus:ring-[#b8e0f0]/15 transition-all resize-none"
          />
          <p className="mt-2 text-[13px] text-[#94a3b8]">
            This reason will be sent to the family via email notification.
          </p>

          <div className="flex justify-end gap-3 mt-6">
            <button
              onClick={onClose}
              className="px-5 h-[42px] text-[#ef4444] hover:bg-[#ef4444]/10 text-[15px] font-semibold rounded-[10px] transition-all"
            >
              Cancel
            </button>
            <button
              onClick={() => {
                if (!canSubmit) return;
                onConfirm(reason);
                onClose();
              }}
              disabled={!canSubmit}
              className="inline-flex items-center gap-2 px-5 h-[42px] bg-[#ef4444] hover:bg-[#dc2626] text-white text-[15px] font-semibold rounded-[10px] transition-all disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <XCircle className="w-[18px] h-[18px]" strokeWidth={2} />
              Confirm Rejection
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
