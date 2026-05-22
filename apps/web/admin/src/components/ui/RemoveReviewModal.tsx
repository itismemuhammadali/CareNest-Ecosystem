"use client";

import React from "react";
import { X } from "lucide-react";

interface RemoveReviewModalProps {
  isOpen: boolean;
  onClose: () => void;
  // BACKEND DEVELOPER: This function should trigger the actual API call for deletion.
  onConfirm: () => void;
  itemName?: string;
}

export function RemoveReviewModal({ isOpen, onClose, onConfirm, itemName }: RemoveReviewModalProps) {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-[110] flex items-center justify-center bg-black/60 backdrop-blur-sm p-4 animate-in fade-in duration-300">
      <div 
        className="bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] shadow-[0px_25px_50px_-12px_rgba(0,0,0,0.25)] flex flex-col p-6 animate-in zoom-in-95 duration-300"
        style={{ width: '450px', height: '271.98px' }}
      >
        <div className="flex flex-col items-center flex-1">
          {/* Icon Section */}
          <div className="w-[47.98px] h-[47.98px] rounded-full border-[3.99859px] border-[#EF4444] flex items-center justify-center mb-4">
            <X className="w-6 h-6 text-[#EF4444] stroke-[3px]" />
          </div>

          {/* Text Section */}
          <h2 className="text-white text-[20px] font-semibold leading-[28px] text-center mb-4">
            Remove Review?
          </h2>
          <p className="text-[#999999] text-[16px] leading-[24px] text-center px-4">
            Are you sure you want to remove this review? This action cannot be undone.
          </p>
        </div>

        {/* Button Section */}
        <div className="flex gap-[10px] mt-6">
          <button
            onClick={onClose}
            className="flex-1 h-11 bg-[#2A2A2A] hover:bg-[#333333] rounded-[8px] text-white text-[16px] font-medium transition-all"
          >
            Cancel
          </button>
          <button
            onClick={onConfirm}
            className="flex-1 h-11 bg-[#EF4444] hover:bg-[#dc2626] rounded-[8px] text-white text-[16px] font-medium transition-all"
          >
            Remove
          </button>
        </div>
      </div>
    </div>
  );
}
