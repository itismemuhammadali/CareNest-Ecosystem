"use client";

import React from "react";
import { X, AlertTriangle, CheckCircle2 } from "lucide-react";

interface TransactionDetailsModalProps {
  isOpen: boolean;
  onClose: () => void;
  txData: any | null;
  onRelease?: () => void;
  onRefund?: () => void;
}

export function TransactionDetailsModal({ isOpen, onClose, txData, onRelease, onRefund }: TransactionDetailsModalProps) {
  if (!isOpen || !txData) return null;

  const isHeld = txData.escrowStatus === "held";

  return (
    <div className="fixed inset-0 z-[100] flex items-center justify-center px-4">
      {/* Backdrop */}
      <div 
        className="absolute inset-0 bg-black/60 backdrop-blur-sm animate-in fade-in duration-300"
        onClick={onClose}
      />
      
      {/* Modal Content - Width 670px */}
      <div className="bg-[#1A1A1A] w-full max-w-[670px] max-h-[90vh] rounded-[8px] overflow-hidden relative z-10 shadow-2xl animate-in zoom-in-95 duration-300 border border-[#2A2A2A] flex flex-col">
        {/* Header - Height 85.09px */}
        <div className="flex items-center justify-between px-8 h-[85.09px] shrink-0 border-b border-[#2A2A2A]">
          <h2 className="text-white text-[20px] font-semibold leading-[28px]">Transaction Details</h2>
          <button 
            onClick={onClose}
            className="w-9 h-9 rounded-[8px] border border-white flex items-center justify-center text-white hover:bg-white/5 transition-all"
          >
            <X className="w-[19px] h-[20px]" />
          </button>
        </div>

        {/* Content Area */}
        <div className="p-8 space-y-8 overflow-y-auto flex-1 custom-scrollbar">
          {/* General Info Grid */}
          <div className="grid grid-cols-2 gap-y-6 gap-x-12">
            <div className="space-y-1">
              <p className="text-[#999999] text-[14px] font-medium">Transaction ID</p>
              <p className="text-[#A2F301] text-[14px] font-bold uppercase">{txData.id}</p>
            </div>
            <div className="space-y-1">
              <p className="text-[#999999] text-[14px] font-medium">Organizer</p>
              <p className="text-white text-[14px] font-normal">{txData.organizer}</p>
            </div>
            <div className="space-y-1">
              <p className="text-[#999999] text-[14px] font-medium">Musician</p>
              <p className="text-white text-[14px] font-normal">{txData.musician}</p>
            </div>
            <div className="space-y-1">
              <p className="text-[#999999] text-[14px] font-medium">Gig Reference</p>
              <p className="text-[#999999] text-[14px] font-normal">{txData.gig}</p>
            </div>
            <div className="space-y-1">
              <p className="text-[#999999] text-[14px] font-medium">Amount</p>
              <p className="text-white text-[24px] font-bold">{txData.amount}</p>
            </div>
            <div className="space-y-1">
              <p className="text-[#999999] text-[14px] font-medium">Payment Date</p>
              <p className="text-[#999999] text-[14px] font-normal">{txData.date}</p>
            </div>
          </div>

          <div className="h-[1px] bg-[#2A2A2A] w-full" />

          {/* Payment Status Section */}
          <div className="space-y-4">
            <h3 className="text-white text-[14px] font-semibold">Payment Status</h3>
            <div className="grid grid-cols-2 gap-6">
              {/* Escrow Card */}
              <div className="bg-[#333333]/30 border border-[#2A2A2A] p-[17px] rounded-[8px] flex flex-col gap-2">
                <p className="text-[#999999] text-[14px] font-medium">Escrow Status</p>
                <div className="flex">
                  <span className={`px-3 py-1 rounded-full text-[14px] font-medium ${
                    txData.escrowStatus === 'released' ? 'bg-[#10b981]/10 text-[#10b981]' : 'bg-[#f59e0b]/10 text-[#f59e0b]'
                  }`}>
                    {txData.escrowStatus}
                  </span>
                </div>
              </div>
              {/* Payment Card */}
              <div className="bg-[#333333]/30 border border-[#2A2A2A] p-[17px] rounded-[8px] flex flex-col gap-2">
                <p className="text-[#999999] text-[14px] font-medium">Payment Status</p>
                <div className="flex">
                  <span className={`px-3 py-1 rounded-full text-[14px] font-medium ${
                    txData.status === 'completed' ? 'bg-[#10b981]/10 text-[#10b981]' : 'bg-[#f59e0b]/10 text-[#f59e0b]'
                  }`}>
                    {txData.status}
                  </span>
                </div>
              </div>
            </div>
          </div>

          {/* Condition-based Alert Box */}
          {isHeld ? (
            <div className="bg-[#f59e0b]/10 border border-[#f59e0b]/20 p-4 rounded-[8px] flex gap-3">
              <AlertTriangle className="w-5 h-5 text-[#f59e0b] shrink-0" />
              <div className="space-y-1">
                <p className="text-[#f59e0b] text-[14px] font-medium">Funds Held in Escrow</p>
                <p className="text-[#999999] text-[12px] leading-[16px]">
                  The payment of {txData.amount} is currently held in escrow. You can release the funds to the musician once the gig is completed or refund to the organizer if needed.
                </p>
              </div>
            </div>
          ) : (
            <div className="bg-[#10b981]/10 border border-[#10b981]/20 p-4 rounded-[8px] flex gap-3">
              <CheckCircle2 className="w-5 h-5 text-[#10b981] shrink-0" />
              <div className="space-y-1">
                <p className="text-[#10b981] text-[14px] font-medium">Escrow Released</p>
                <p className="text-[#999999] text-[12px] leading-[16px]">
                  The funds have been released to the musician. If there are any issues, you can process a refund to return the payment to the organizer.
                </p>
              </div>
            </div>
          )}

          {/* Transaction Timeline */}
          <div className="space-y-4 pt-4 border-t border-[#2A2A2A]">
            <h3 className="text-white text-[14px] font-semibold">Transaction Timeline</h3>
            <div className="space-y-6">
              {/* Item 1 */}
              <div className="flex gap-4">
                <div className="mt-1.5 w-2 h-2 rounded-full bg-[#10b981] shrink-0" />
                <div className="space-y-1">
                  <p className="text-white text-[14px] font-medium leading-none">Payment Received</p>
                  <p className="text-[#999999] text-[12px]">{txData.date} • From {txData.organizer}</p>
                </div>
              </div>
              {/* Item 2 */}
              <div className="flex gap-4">
                <div className={`mt-1.5 w-2 h-2 rounded-full shrink-0 ${isHeld ? 'bg-[#f59e0b]' : 'bg-[#10b981]'}`} />
                <div className="space-y-1">
                  <p className="text-white text-[14px] font-medium leading-none">
                    {isHeld ? "Held in Escrow" : "Funds Released"}
                  </p>
                  <p className="text-[#999999] text-[12px]">
                    {isHeld ? "Awaiting gig completion" : `Payment sent to ${txData.musician}`}
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Action Footer - Height 76px */}
        <div className="p-4 px-6 h-[76px] shrink-0 flex justify-end items-center gap-4 border-t border-[#2A2A2A] bg-[#1A1A1A]">
          {isHeld ? (
            <button 
              onClick={onRelease}
              className="w-[152px] h-[44px] bg-[#A2F301] text-black rounded-[8px] font-medium text-[16px] hover:bg-[#91da00] transition-all flex items-center justify-center"
            >
              Release Escrow
            </button>
          ) : (
            <button 
              onClick={onRefund}
              className="w-[172px] h-[44px] bg-[#EF4444] text-white rounded-[8px] font-medium text-[16px] hover:bg-[#dc2626] transition-all flex items-center justify-center"
            >
              Refund Transaction
            </button>
          )}
          <button 
            onClick={onClose}
            className="w-[76px] h-[44px] bg-[#333333] text-[#999999] rounded-[8px] font-medium text-[16px] hover:bg-[#404040] transition-all flex items-center justify-center"
          >
            Close
          </button>
        </div>
      </div>
    </div>
  );
}
