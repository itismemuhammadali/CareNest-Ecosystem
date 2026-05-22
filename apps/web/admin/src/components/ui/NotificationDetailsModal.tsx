"use client";

import React from "react";
import { X } from "lucide-react";

interface NotificationDetailsModalProps {
  isOpen: boolean;
  onClose: () => void;
  notification: {
    title: string;
    targetAudience: string;
    sentDate: string;
    recipients: string;
  } | null;
}

export function NotificationDetailsModal({ isOpen, onClose, notification }: NotificationDetailsModalProps) {
  if (!isOpen || !notification) return null;

  return (
    <div className="fixed inset-0 z-[110] flex items-center justify-center bg-black/60 backdrop-blur-sm p-4 animate-in fade-in duration-300">
      <div 
        className="bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] shadow-[0px_25px_50px_-12px_rgba(0,0,0,0.25)] flex flex-col animate-in zoom-in-95 duration-300 overflow-hidden"
        style={{ width: '670px', maxHeight: '90%' }}
      >
        {/* Header */}
        <div className="flex justify-between items-center px-[24px] py-[20px] border-b border-[#2A2A2A]">
          <h2 className="text-white text-[20px] font-semibold font-inter leading-[28px]">
            Notification Details
          </h2>
          <button 
            onClick={onClose}
            className="w-[36px] h-[36px] flex items-center justify-center border border-white rounded-[8px] hover:bg-white/10 transition-all"
          >
            <X size={19} className="text-white" strokeWidth={2.5} />
          </button>
        </div>

        {/* Content */}
        <div className="flex-1 flex flex-col gap-[16px] px-[32px] py-[32px]">
          {/* Notification Title */}
          <div className="flex flex-col gap-[8px]">
            <label className="text-white text-[14px] font-medium font-inter leading-[20px]">
              Notification Title
            </label>
            <div className="w-full h-[48px] bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] px-[16px] flex items-center">
              <span className="text-white text-[16px] font-normal font-inter leading-[24px]">
                {notification.title}
              </span>
            </div>
          </div>

          {/* Target Audience */}
          <div className="flex flex-col gap-[8px]">
            <label className="text-white text-[14px] font-medium font-inter leading-[20px]">
              Target Audience
            </label>
            <div className="w-full h-[48px] bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] px-[16px] flex items-center">
              <span className="text-white text-[16px] font-normal font-inter leading-[24px]">
                {notification.targetAudience}
              </span>
            </div>
          </div>

          {/* Sent Date */}
          <div className="flex flex-col gap-[8px]">
            <label className="text-white text-[14px] font-medium font-inter leading-[20px]">
              Sent Date
            </label>
            <div className="w-full h-[48px] bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] px-[16px] flex items-center">
              <span className="text-white text-[16px] font-normal font-inter leading-[24px]">
                {notification.sentDate}
              </span>
            </div>
          </div>

          {/* Recipients */}
          <div className="flex flex-col gap-[8px]">
            <label className="text-white text-[14px] font-medium font-inter leading-[20px]">
              Recipients
            </label>
            <div className="w-full h-[48px] bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] px-[16px] flex items-center">
              <span className="text-white text-[16px] font-normal font-inter leading-[24px]">
                {notification.recipients}
              </span>
            </div>
          </div>

          {/* Footer Action */}
          <div className="flex justify-end mt-[8px]">
            <button 
              onClick={onClose}
              className="w-[92px] h-[40px] bg-[#333333] hover:bg-[#404040] rounded-[8px] text-[#999999] text-[16px] font-medium font-inter transition-all flex items-center justify-center"
            >
              Close
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
