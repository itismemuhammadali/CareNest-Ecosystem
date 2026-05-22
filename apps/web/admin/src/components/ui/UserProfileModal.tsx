"use client";

import React from "react";
import { X, Mail, Phone, MapPin, Calendar } from "lucide-react";

interface UserProfileModalProps {
  isOpen: boolean;
  onClose: () => void;
  userData: any | null;
}

export function UserProfileModal({ isOpen, onClose, userData }: UserProfileModalProps) {
  if (!isOpen || !userData) return null;

  return (
    <div className="fixed inset-0 z-[100] flex items-center justify-center px-4">
      {/* Backdrop */}
      <div 
        className="absolute inset-0 bg-black/60 backdrop-blur-sm animate-in fade-in duration-300"
        onClick={onClose}
      />
      
      {/* Modal Content - Width 896px as per CSS */}
      <div className="bg-[#1A1A1A] w-full max-w-[896px] rounded-[8px] overflow-hidden relative z-10 shadow-2xl animate-in zoom-in-95 duration-300 border border-[#2A2A2A]">
        {/* Header - Height ~69px as per CSS */}
        <div className="flex items-center justify-between px-[24px] h-[69px] border-b border-[#2A2A2A]">
          <h2 className="text-white text-[20px] font-semibold leading-[28px]">User Profile</h2>
          <button 
            onClick={onClose}
            className="w-9 h-9 rounded-[8px] border border-white flex items-center justify-center text-white hover:bg-white/5 transition-all"
          >
            <X className="w-[19px] h-[20px]" />
          </button>
        </div>

        {/* Content */}
        <div className="p-[25px] pt-[30px] space-y-10">
          {/* Top Section: Avatar + Name/Status */}
          <div className="flex items-start gap-[24px]">
            {/* Avatar */}
            <div className="w-[80px] h-[80px] rounded-full overflow-hidden bg-[#2A2A2A] flex items-center justify-center border border-white/10 shadow-lg">
              {userData.avatar ? (
                <img src={userData.avatar} alt={userData.name} className="w-full h-full object-cover" />
              ) : (
                <div className="text-white text-2xl font-bold">{userData.name.charAt(0)}</div>
              )}
            </div>

            {/* Name and Status */}
            <div className="pt-2">
              <h3 className="text-white text-[24px] font-semibold leading-[32px] mb-2">{userData.name}</h3>
              <span className="inline-flex items-center px-3 py-1 rounded-full bg-[#10B981]/10 text-[#10B981] text-[12px] font-medium leading-[16px]">
                {userData.status || "active"}
              </span>
            </div>
          </div>

          {/* Info Grid - 2 Columns */}
          <div className="grid grid-cols-2 gap-x-[150px] gap-y-6">
            {/* Left Column */}
            <div className="space-y-6">
              <div className="flex items-center gap-[12px]">
                <Mail className="w-[20px] h-[20px] text-[#A2F301]" />
                <div>
                  <p className="text-[#999999] text-[12px] leading-[16px] mb-0.5">Email</p>
                  <p className="text-white text-[14px] font-medium leading-[20px]">{userData.email}</p>
                </div>
              </div>

              <div className="flex items-center gap-[12px]">
                <Phone className="w-[20px] h-[20px] text-[#A2F301]" />
                <div>
                  <p className="text-[#999999] text-[12px] leading-[16px] mb-0.5">Phone</p>
                  <p className="text-white text-[14px] font-medium leading-[20px]">{userData.phone || "—"}</p>
                </div>
              </div>

              <div className="flex items-center gap-[12px]">
                <MapPin className="w-[20px] h-[20px] text-[#A2F301]" />
                <div>
                  <p className="text-[#999999] text-[12px] leading-[16px] mb-0.5">Location</p>
                  <p className="text-white text-[14px] font-medium leading-[20px]">{userData.location || "—"}</p>
                </div>
              </div>
            </div>

            {/* Right Column */}
            <div className="space-y-6">
              <div className="flex items-center gap-[12px]">
                <Calendar className="w-[20px] h-[20px] text-[#A2F301]" />
                <div>
                  <p className="text-[#999999] text-[12px] leading-[16px] mb-0.5">Joined</p>
                  <p className="text-white text-[14px] font-medium leading-[20px]">{userData.joinedDate || "—"}</p>
                </div>
              </div>

              <div className="pt-2">
                <p className="text-[#999999] text-[12px] leading-[16px] mb-1">Total Bookings</p>
                <p className="text-[#A2F301] text-[24px] font-bold leading-[32px]">{userData.totalBookings ?? "—"}</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
