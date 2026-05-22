"use client";

import React, { useEffect, useState } from "react";
import { User, LogOut, Settings } from "lucide-react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";

interface ProfileDropdownProps {
  isOpen: boolean;
  onClose: () => void;
}

export function ProfileDropdown({ isOpen, onClose }: ProfileDropdownProps) {
  const router = useRouter();
  const [name, setName] = useState<string>("Admin");
  const [email, setEmail] = useState<string>("");

  useEffect(() => {
    if (!isOpen) return;
    const supabase = createClient();
    void (async () => {
      const { data } = await supabase.auth.getUser();
      const u = data.user;
      if (!u) return;
      setEmail(u.email ?? "");
      const meta = (u.user_metadata ?? {}) as Record<string, unknown>;
      const metaName = typeof meta.full_name === "string" ? meta.full_name : null;
      if (metaName) {
        setName(metaName);
        return;
      }
      const { data: profile } = await supabase
        .from("users")
        .select("full_name")
        .eq("id", u.id)
        .maybeSingle();
      if (profile?.full_name) setName(profile.full_name);
    })();
  }, [isOpen]);

  if (!isOpen) return null;

  const handleLogout = async () => {
    onClose();
    const supabase = createClient();
    await supabase.auth.signOut();
    router.push("/");
    router.refresh();
  };

  return (
    <>
      {/* Click-outside overlay */}
      <div className="fixed inset-0 z-40 bg-transparent" onClick={onClose} />

      <div className="absolute top-[60px] right-0 w-[280px] bg-[#1e293b]/95 backdrop-blur-md border border-white/10 rounded-2xl shadow-[0_24px_60px_-20px_rgba(0,0,0,0.6)] z-50 overflow-hidden animate-in fade-in slide-in-from-top-2 duration-200">
        {/* User info */}
        <div className="px-5 py-5 flex items-center gap-3.5 border-b border-[#334155]/40">
          <div className="w-[48px] h-[48px] rounded-full bg-[#b8e0f0] flex items-center justify-center flex-shrink-0">
            <User className="w-5 h-5 text-[#0a0f24]" strokeWidth={2} />
          </div>
          <div className="overflow-hidden">
            <h3 className="text-white font-semibold text-[15px] truncate">
              {name}
            </h3>
            <p className="text-[#94a3b8] text-[13px] truncate">{email}</p>
          </div>
        </div>

        {/* Menu */}
        <div className="p-2">
          <Link
            href="/settings"
            onClick={onClose}
            className="flex items-center gap-3 px-3 py-2.5 rounded-[10px] text-[#cbd5e1] hover:bg-white/5 hover:text-white transition-all group"
          >
            <div className="w-8 h-8 rounded-full bg-[#0f172a]/60 border border-white/10 flex items-center justify-center group-hover:bg-[#b8e0f0]/10 group-hover:border-[#b8e0f0]/30 transition-colors">
              <Settings
                className="w-[16px] h-[16px] group-hover:text-[#b8e0f0] transition-colors"
                strokeWidth={1.75}
              />
            </div>
            <span className="text-[14px] font-medium">Settings</span>
          </Link>

          <button
            onClick={handleLogout}
            className="w-full flex items-center gap-3 px-3 py-2.5 rounded-[10px] text-[#ef4444] hover:bg-[#ef4444]/10 transition-all group mt-1"
          >
            <div className="w-8 h-8 rounded-full bg-[#ef4444]/10 border border-[#ef4444]/20 flex items-center justify-center group-hover:bg-[#ef4444]/20 transition-colors">
              <LogOut className="w-[16px] h-[16px]" strokeWidth={1.75} />
            </div>
            <span className="text-[14px] font-medium">Logout</span>
          </button>
        </div>
      </div>
    </>
  );
}
