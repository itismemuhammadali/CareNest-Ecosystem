"use client";

import React from "react";
import { X, AlertCircle } from "lucide-react";

interface ConfirmationModalProps {
  isOpen: boolean;
  onClose: () => void;
  onConfirm: () => void;
  title: string;
  description: string;
  confirmLabel: string;
  cancelLabel: string;
  confirmVariant?: "danger" | "primary" | "warning";
}

export function ConfirmationModal({
  isOpen,
  onClose,
  onConfirm,
  title,
  description,
  confirmLabel,
  cancelLabel,
  confirmVariant = "danger"
}: ConfirmationModalProps) {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-[100] flex items-center justify-center bg-black/60 backdrop-blur-sm p-4 animate-in fade-in duration-300">
      <div 
        className="bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] shadow-[0px_25px_50px_-12px_rgba(0,0,0,0.25)] flex flex-col p-6 animate-in zoom-in-95 duration-300 w-full max-w-[448px] h-auto"
      >
        <div className="flex flex-col items-center flex-1">
          {/* Icon */}
          <div 
            className={`w-[48px] h-[48px] rounded-full flex items-center justify-center mb-4 border-[4px] relative ${
              confirmVariant === "warning" ? "" : 
              confirmVariant === "danger" ? "border-[#EF4444]" : "border-[#b3ff00]"
            }`}
            style={confirmVariant === "warning" ? { borderColor: '#F59E0B' } : {}}
          >
            {confirmVariant === "warning" ? (
              <div className="flex flex-col items-center justify-center gap-0.5">
                <div className="w-[3px] h-[16px] bg-[#F59E0B] rounded-full" />
                <div className="w-[3px] h-[3px] bg-[#F59E0B] rounded-full" />
              </div>
            ) : confirmVariant === "danger" ? (
              <X className="w-6 h-6 text-[#EF4444] stroke-[3px]" />
            ) : (
              <div className="w-5 h-2.5 border-b-3 border-r-3 border-[#b3ff00] rotate-45 mb-0.5" />
            )}
          </div>

          {/* Title */}
          <h2 className="text-white text-[20px] font-semibold leading-[28px] text-center mb-4">
            {title}
          </h2>
          
          {/* Description */}
          <p className="text-[#999999] text-[16px] leading-[24px] text-center px-4">
            {description}
          </p>
        </div>

        {/* Buttons */}
        <div className="flex gap-[11.99px] mt-6">
          <button 
            onClick={onClose}
            className="flex-1 h-[39.98px] bg-[#2A2A2A] hover:bg-[#333333] rounded-[8px] text-white text-[16px] font-medium transition-all"
          >
            {cancelLabel}
          </button>
          <button 
            onClick={onConfirm}
            className={`flex-1 h-[39.98px] rounded-[8px] text-white text-[16px] font-medium transition-all shadow-lg text-center ${
              confirmVariant === "danger" 
                ? "bg-[#EF4444] hover:bg-[#D92D20] shadow-[#EF4444]/20" 
                : confirmVariant === "warning"
                ? "bg-[#F59E0B] hover:bg-[#D97706] shadow-[#F59E0B]/20"
                : "bg-[#b3ff00] text-black hover:bg-[#a2e600] shadow-[#b3ff00]/20"
            }`}
          >
            {confirmLabel}
          </button>
        </div>
      </div>
    </div>
  );
}
