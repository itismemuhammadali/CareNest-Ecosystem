"use client";

import React, { useEffect } from "react";
import { Check } from "lucide-react";

interface ToastProps {
  show: boolean;
  message: string;
  description?: string;
  onClose: () => void;
  duration?: number;
}

export function Toast({
  show,
  message,
  description,
  onClose,
  duration = 3000,
}: ToastProps) {
  useEffect(() => {
    if (show) {
      const timer = setTimeout(() => {
        onClose();
      }, duration);
      return () => clearTimeout(timer);
    }
  }, [show, duration, onClose]);

  if (!show) return null;

  return (
    <div className="fixed top-[96px] right-10 z-[100] animate-in fade-in slide-in-from-top-5 duration-300">
      <div className="bg-[#0a0a0a] border border-white/[0.06] rounded-2xl px-6 py-4 shadow-[0_8px_30px_rgba(0,0,0,0.5)] flex items-start gap-3.5 min-w-[360px] max-w-[440px]">
        <div className="w-7 h-7 rounded-full bg-white flex items-center justify-center flex-shrink-0 mt-0.5">
          <Check className="w-4 h-4 text-black stroke-[3px]" />
        </div>
        <div className="min-w-0">
          <p className="text-white text-[16px] font-semibold tracking-tight">
            {message}
          </p>
          {description && (
            <p className="mt-0.5 text-white/80 text-[14px]">{description}</p>
          )}
        </div>
      </div>
    </div>
  );
}
