"use client";

import React from "react";
import { AlertCircle } from "lucide-react";

interface RevokePlacementModalProps {
  isOpen: boolean;
  onClose: () => void;
  // BACKEND DEVELOPER: This function should trigger the actual API call for revocation.
  onConfirm: () => void;
}

export function RevokePlacementModal({ isOpen, onClose, onConfirm }: RevokePlacementModalProps) {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-[110] flex items-center justify-center bg-black/60 backdrop-blur-sm p-4 animate-in fade-in duration-300">
      <div 
        className="bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] shadow-[0px_25px_50px_-12px_rgba(0,0,0,0.25)] flex flex-col p-6 animate-in zoom-in-95 duration-300"
        style={{ width: '447.99px', height: '262.11px' }}
      >
        <div className="flex flex-col items-center flex-1">
          {/* Icon Section */}
          <div 
            className="w-[48px] h-[48px] rounded-full flex items-center justify-center mb-4 border-[4px] relative border-[#F59E0B]"
            style={{ borderColor: '#F59E0B' }}
          >
            <div className="flex flex-col items-center justify-center gap-0.5">
              <div className="w-[3px] h-[16px] bg-[#F59E0B] rounded-full" />
              <div className="w-[3px] h-[3px] bg-[#F59E0B] rounded-full" />
            </div>
          </div>

          {/* Text Section */}
          <h2 className="text-white text-[20px] font-semibold leading-[28px] text-center mb-4">
            Revoke Featured Placement?
          </h2>
          <p className="text-[#999999] text-[16px] leading-[24px] text-center px-4">
            This will immediately remove the featured status. The artist will not receive a refund.
          </p>
        </div>

        {/* Button Section */}
        <div className="flex gap-[11.99px] mt-6">
          <button
            onClick={onClose}
            className="flex-1 h-[39.98px] bg-[#2A2A2A] hover:bg-[#333333] rounded-[8px] text-white text-[16px] font-medium transition-all"
          >
            Cancel
          </button>
          <button
            onClick={onConfirm}
            className="flex-1 h-[39.98px] bg-[#F59E0B] hover:bg-[#d97706] rounded-[8px] text-white text-[16px] font-medium transition-all shadow-lg shadow-[#F59E0B]/20"
          >
            Revoke
          </button>
        </div>
      </div>
    </div>
  );
}
