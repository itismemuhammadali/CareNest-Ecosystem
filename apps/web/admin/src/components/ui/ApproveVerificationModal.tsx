"use client";

import React, { useEffect } from "react";
import Image from "next/image";

interface Props {
  isOpen: boolean;
  onClose: () => void;
  onConfirm: () => void;
}

export function ApproveVerificationModal({ isOpen, onClose, onConfirm }: Props) {
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
        className="relative w-full max-w-[520px] overflow-hidden border border-white/10 rounded-2xl shadow-[0_24px_60px_-20px_rgba(0,0,0,0.6)] animate-in zoom-in-95 duration-200"
      >
        {/* Card's own starry background */}
        <div className="absolute inset-0 -z-10">
          <Image
            src="/login-bg.png"
            alt=""
            fill
            sizes="520px"
            className="object-cover"
          />
          <div className="absolute inset-0 bg-[#1e293b]/85" />
        </div>

        <div className="relative px-7 py-7">
          <h2 className="text-[22px] leading-[28px] font-bold text-white mb-3">
            Approve Verification
          </h2>
          <p className="text-[15px] leading-[24px] text-[#94a3b8] mb-7">
            Are you sure you want to approve the verification for this family?
          </p>

          <div className="flex justify-end gap-3">
            <button
              onClick={onClose}
              className="px-6 h-[42px] bg-[#ef4444] hover:bg-[#dc2626] text-white text-[15px] font-semibold rounded-[10px] transition-all"
            >
              Cancel
            </button>
            <button
              onClick={() => {
                onConfirm();
                onClose();
              }}
              className="px-6 h-[42px] bg-[#10b981]/25 hover:bg-[#10b981]/40 border border-[#10b981]/30 text-[#34d399] text-[15px] font-semibold rounded-[10px] transition-all"
            >
              Approve
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
