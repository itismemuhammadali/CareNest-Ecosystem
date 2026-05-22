"use client";

import React from "react";
import { X, Check } from "lucide-react";

interface ContractHistoryModalProps {
  isOpen: boolean;
  onClose: () => void;
  contract: {
    id: string;
    gigReference: string;
    organizer: string;
    musician: string;
    date: string;
    signatures: string;
    status: string;
  } | null;
}

export function ContractHistoryModal({ isOpen, onClose, contract }: ContractHistoryModalProps) {
  if (!isOpen || !contract) return null;

  const isSigned = contract.status === "signed";
  const signatures = [
    { name: contract.organizer, role: "Family", isSigned: true },
    { name: contract.musician, role: "Babysitter", isSigned },
  ];

  return (
    <div className="fixed inset-0 z-[100] flex items-center justify-center bg-black/60 backdrop-blur-sm p-4">
      <div 
        className="bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] shadow-[0px_25px_50px_-12px_rgba(0,0,0,0.25)] flex flex-col overflow-hidden animate-in fade-in zoom-in duration-300"
        style={{ width: '896px', height: 'auto', maxHeight: '90vh' }}
      >
        {/* Header */}
        <div className="h-[85.09px] px-8 border-b border-[#2A2A2A] flex items-center justify-between shrink-0">
          <h2 className="text-white text-[20px] font-semibold leading-[28px]">Contract Details & History</h2>
          <button 
            onClick={onClose}
            className="w-9 h-9 border border-white rounded-[8px] flex items-center justify-center hover:bg-white/10 transition-all"
          >
            <X className="w-[19px] h-[20px] text-white" />
          </button>
        </div>

        {/* Content */}
        <div className="flex-1 overflow-y-auto p-8 flex flex-col gap-10">
          {/* Details Grid */}
          <div className="grid grid-cols-2 gap-y-6 gap-x-16">
            {/* Row 1 */}
            <div className="space-y-1">
              <p className="text-[#999999] text-[14px] leading-[20px]">Contract ID</p>
              <p className="text-[#A2F301] text-[14px] font-medium leading-[20px]">{contract.id}</p>
            </div>
            <div className="space-y-1">
              <p className="text-[#999999] text-[14px] leading-[20px]">Status</p>
              <div className={`inline-flex items-center px-2 py-0.5 rounded-full text-[12px] font-medium lowercase ${
                contract.status === "signed" 
                  ? "bg-[#10B981]/10 text-[#10B981]" 
                  : "bg-[#F59E0B]/10 text-[#F59E0B]"
              }`}>
                {contract.status}
              </div>
            </div>

            {/* Row 2 */}
            <div className="space-y-1">
              <p className="text-[#999999] text-[14px] leading-[20px]">Gig Reference</p>
              <p className="text-white text-[14px] font-medium leading-[20px]">{contract.gigReference}</p>
            </div>
            <div className="space-y-1">
              <p className="text-[#999999] text-[14px] leading-[20px]">Contract Date</p>
              <p className="text-white text-[14px] font-medium leading-[20px]">{contract.date}</p>
            </div>

            {/* Row 3 */}
            <div className="space-y-1">
              <p className="text-[#999999] text-[14px] leading-[20px]">Organizer</p>
              <p className="text-white text-[14px] font-medium leading-[20px]">{contract.organizer}</p>
            </div>
            <div className="space-y-1">
              <p className="text-[#999999] text-[14px] leading-[20px]">Musician</p>
              <p className="text-white text-[14px] font-medium leading-[20px]">{contract.musician}</p>
            </div>
          </div>

          {/* Signature Status Section */}
          <div className="border-t border-[#2A2A2A] pt-6 flex flex-col gap-4">
            <h3 className="text-white text-[14px] font-semibold leading-[20px]">Signature Status</h3>
            
            <div className="flex flex-col gap-3">
              {signatures.map((sig, idx) => (
                <div 
                  key={idx}
                  className={`flex items-center justify-between p-4 rounded-[8px] border transition-all ${
                    sig.isSigned 
                      ? "bg-[#10B981]/10 border-[#10B981]/20" 
                      : "bg-[#F59E0B]/5 border-[#F59E0B]/20"
                  }`}
                >
                  <div className="flex flex-col">
                    <p className="text-white text-[14px] font-medium leading-[20px]">{sig.name}</p>
                    <p className="text-[#999999] text-[12px] leading-[16px]">{sig.role}</p>
                  </div>
                  <div className="flex items-center gap-1.5">
                    {sig.isSigned ? (
                      <>
                        <Check className="w-4 h-4 text-[#10B981]" />
                        <span className="text-[#10B981] text-[12px] font-medium">Signed</span>
                      </>
                    ) : (
                      <span className="text-[#F59E0B] text-[12px] font-medium">Pending</span>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Footer */}
        <div className="px-8 pb-8 flex justify-end shrink-0">
          <button 
            onClick={onClose}
            className="h-10 bg-[#333333] hover:bg-[#404040] text-white/80 px-8 rounded-[8px] text-[16px] font-medium transition-all"
          >
            Close
          </button>
        </div>
      </div>
    </div>
  );
}
