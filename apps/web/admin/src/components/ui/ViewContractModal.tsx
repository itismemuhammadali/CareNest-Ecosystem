"use client";

import React from "react";
import { X, Download, FileText } from "lucide-react";

interface ViewContractModalProps {
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
  onDownload?: (contractId: string) => void;
}

export function ViewContractModal({ isOpen, onClose, contract, onDownload }: ViewContractModalProps) {
  if (!isOpen || !contract) return null;

  const handleDownload = () => {
    // BACKEND DEVELOPER: Trigger actual file download logic here.
    // Ensure your endpoint returns 'application/pdf' and appropriate content-disposition.
    if (onDownload) {
      onDownload(contract.id);
    }
  };

  return (
    <div className="fixed inset-0 z-[100] flex items-center justify-center bg-black/60 backdrop-blur-sm p-4">
      <div 
        className="bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] shadow-[0px_25px_50px_-12px_rgba(0,0,0,0.25)] flex flex-col overflow-hidden animate-in fade-in zoom-in duration-300"
        style={{ width: '896px', height: 'auto', maxHeight: '90vh' }}
      >
        {/* Header */}
        <div className="h-[85.09px] px-6 border-b border-[#2A2A2A] flex items-center justify-between shrink-0">
          <h2 className="text-white text-[20px] font-semibold leading-[28px]">View Contract</h2>
          <button 
            onClick={onClose}
            className="w-9 h-9 border border-white rounded-[8px] flex items-center justify-center hover:bg-white/10 transition-all"
          >
            <X className="w-[19px] h-[20px] text-white" />
          </button>
        </div>

        {/* Content */}
        <div className="flex-1 overflow-y-auto p-8 flex flex-col gap-6">
          <div className="bg-[#333333]/30 border border-[#2A2A2A] rounded-[8px] p-8 flex flex-col items-center">
            {/* Document Header */}
            <div className="text-center mb-10">
              <h3 className="text-white text-[18px] font-semibold leading-[28px] mb-2 uppercase tracking-wide">
                GIG SERVICE AGREEMENT
              </h3>
              <p className="text-[#999999] text-[14px] leading-[20px]">Contract ID: {contract.id}</p>
            </div>

            {/* Document Details Grid */}
            <div className="w-full grid grid-cols-2 gap-y-10 gap-x-16 mb-10">
              {/* Left Column */}
              <div className="space-y-6">
                <div>
                  <p className="text-[#999999] text-[14px] leading-[20px] mb-1">Gig Reference:</p>
                  <p className="text-white text-[14px] font-medium leading-[20px]">{contract.gigReference}</p>
                </div>
                <div>
                  <p className="text-[#999999] text-[14px] leading-[20px] mb-1">Organizer:</p>
                  <p className="text-white text-[14px] font-medium leading-[20px]">{contract.organizer}</p>
                </div>
                <div>
                  <p className="text-[#999999] text-[14px] leading-[20px] mb-1">Signatures:</p>
                  <p className="text-white text-[14px] font-medium leading-[20px]">{contract.signatures}</p>
                </div>
              </div>

              {/* Right Column */}
              <div className="space-y-6">
                <div>
                  <p className="text-[#999999] text-[14px] leading-[20px] mb-1">Contract Date:</p>
                  <p className="text-white text-[14px] font-medium leading-[20px]">{contract.date}</p>
                </div>
                <div>
                  <p className="text-[#999999] text-[14px] leading-[20px] mb-1">Musician:</p>
                  <p className="text-white text-[14px] font-medium leading-[20px]">{contract.musician}</p>
                </div>
                <div>
                  <p className="text-[#999999] text-[14px] leading-[20px] mb-1">Status:</p>
                  <div className={`inline-flex items-center px-2 py-0.5 rounded-full text-[12px] font-medium lowercase ${
                    contract.status === "signed" 
                      ? "bg-[#10B981]/10 text-[#10B981]" 
                      : "bg-[#F59E0B]/10 text-[#F59E0B]"
                  }`}>
                    {contract.status}
                  </div>
                </div>
              </div>
            </div>

            {/* Contract Terms Box */}
            <div className="w-full bg-[#0A0A0A]/50 border border-[#2A2A2A] rounded-[4px] p-4">
              <p className="text-[#999999] text-[12px] leading-[16px] mb-2">Contract Terms:</p>
              <p className="text-white text-[14px] leading-[23px]">
                This agreement is made between {contract.organizer} (Organizer) and {contract.musician} (Artist) for the performance "{contract.gigReference}" scheduled on {contract.date}. Both parties agree to the terms outlined in this document including payment terms, cancellation policy, and performance requirements.
              </p>
            </div>
          </div>
        </div>

        {/* Footer */}
        <div className="px-8 pb-8 flex justify-end gap-4 shrink-0">
          <button 
            onClick={onClose}
            className="h-10 bg-[#333333] hover:bg-[#404040] text-[#999999] px-6 rounded-[8px] text-[16px] font-medium transition-all"
          >
            Close
          </button>
          <button 
            onClick={handleDownload}
            className="h-10 bg-[#A2F301] hover:bg-[#b3ff00] text-black px-6 rounded-[8px] text-[16px] font-medium flex items-center gap-2 transition-all"
          >
            <Download className="w-4 h-4" />
            Download PDF
          </button>
        </div>
      </div>
    </div>
  );
}
