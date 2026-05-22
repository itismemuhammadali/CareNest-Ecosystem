"use client";

import React from "react";
import { X, AlertCircle } from "lucide-react";

interface PaymentActionModalProps {
  isOpen: boolean;
  onClose: () => void;
  onConfirm: () => void;
  type: "release" | "refund";
}

export function PaymentActionModal({ isOpen, onClose, onConfirm, type }: PaymentActionModalProps) {
  if (!isOpen) return null;

  const isRelease = type === "release";

  return (
    <div className="fixed inset-0 z-[110] flex items-center justify-center px-4">
      {/* Backdrop */}
      <div 
        className="absolute inset-0 bg-black/60 backdrop-blur-sm animate-in fade-in duration-300"
        onClick={onClose}
      />
      
      {/* Modal Content - Width 450px, Height 312px */}
      <div className="bg-[#1A1A1A] w-[450px] h-[312px] rounded-[8px] overflow-hidden relative z-10 shadow-2xl animate-in zoom-in-95 duration-300 border border-[#2A2A2A] flex flex-col items-center justify-center p-6 gap-6">
        
        {/* Icon & Text Container */}
        <div className="flex flex-col items-center gap-4 text-center">
          {/* Icon */}
          <div className={`w-[48px] h-[48px] rounded-full border-[4px] flex items-center justify-center ${
            isRelease ? 'border-[#f59e0b] text-[#f59e0b]' : 'border-[#EF4444] text-[#EF4444]'
          }`}>
            {isRelease ? (
              <AlertCircle className="w-[28px] h-[28px]" />
            ) : (
              <X className="w-[28px] h-[28px]" />
            )}
          </div>

          {/* Title */}
          <h3 className="text-white text-[20px] font-semibold leading-[28px]">
            {isRelease ? "Release Escrow" : "Refund Transaction"}
          </h3>

          {/* Description */}
          <p className="text-[#999999] text-[16px] leading-[24px] max-w-[372px]">
            {isRelease 
              ? "Are you sure you want to release the escrow for this transaction? This action will transfer the funds to the musician."
              : "Are you sure you want to refund this transaction? This action will return the funds to the organizer."
            }
          </p>
        </div>

        {/* Action Buttons */}
        <div className="flex gap-4 w-full mt-2">
          <button 
            onClick={onClose}
            className="flex-1 h-[44px] bg-[#2A2A2A] text-white rounded-[8px] font-medium text-[16px] hover:bg-[#333333] transition-all"
          >
            Cancel
          </button>
          <button 
            onClick={onConfirm}
            className={`flex-1 h-[44px] rounded-[8px] font-medium text-[16px] transition-all ${
              isRelease 
                ? 'bg-[#A2F301] text-[#0F0F0F] hover:bg-[#91da00]' 
                : 'bg-[#EF4444] text-white hover:bg-[#dc2626]'
            }`}
          >
            {isRelease ? "Release Escrow" : "Process Refund"}
          </button>
        </div>
      </div>
    </div>
  );
}
