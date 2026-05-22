"use client";

import React from "react";
import Link from "next/link";
import Image from "next/image";
import { usePathname, useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import {
  LayoutGrid,
  Users,
  Smile,
  GraduationCap,
  BookOpen,
  Briefcase,
  DollarSign,
  BarChart3,
  AlertCircle,
  Bell,
  Settings,
  LogOut,
  X,
  Search,
} from "lucide-react";

const menuItems = [
  { name: "Dashboard", href: "/dashboard", icon: LayoutGrid },
  { name: "Search", href: "/search", icon: Search },
  { name: "Families Management", href: "/families", icon: Users },
  { name: "Babysitters Management", href: "/babysitters", icon: Smile },
  { name: "Certifications", href: "/certifications", icon: GraduationCap },
  { name: "Course Management", href: "/courses", icon: BookOpen },
  { name: "Jobs Monitoring", href: "/jobs", icon: Briefcase },
  { name: "Wage Configuration", href: "/wages", icon: DollarSign },
  { name: "Reports & Analytics", href: "/reports", icon: BarChart3 },
  { name: "Disputes & Issues", href: "/disputes", icon: AlertCircle },
  { name: "Notifications Logs", href: "/notifications", icon: Bell },
  { name: "Settings", href: "/settings", icon: Settings },
];

interface SidebarProps {
  isOpen: boolean;
  onClose: () => void;
}

export function Sidebar({ isOpen, onClose }: SidebarProps) {
  const pathname = usePathname();
  const router = useRouter();
  const [mounted, setMounted] = React.useState(false);

  React.useEffect(() => {
    setMounted(true);
  }, []);

  const handleLogout = async () => {
    onClose();
    const supabase = createClient();
    await supabase.auth.signOut();
    router.push("/");
    router.refresh();
  };

  return (
    <aside
      className={`w-[280px] h-screen fixed left-0 top-0 z-50 flex flex-col border-r border-[#334155]/40 bg-[#0f172a]/60 backdrop-blur-md transition-transform duration-300 transform ${
        isOpen ? "translate-x-0" : "-translate-x-full xl:translate-x-0"
      }`}
    >
      {/* Logo + title */}
      <div className="px-6 py-5 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="relative w-12 h-12 rounded-full overflow-hidden flex-shrink-0">
            <Image
              src="/images/star-sitters-logo.jpeg"
              alt="Star Sitters"
              fill
              sizes="48px"
              className="object-cover"
            />
          </div>
          <div>
            <h2 className="text-white font-semibold text-[15px] leading-tight">
              Admin Dashboard
            </h2>
            <p className="text-[#94a3b8] text-[12px] mt-0.5">Admin Panel</p>
          </div>
        </div>

        {/* Mobile close */}
        <button
          onClick={onClose}
          className="xl:hidden p-2 text-[#94a3b8] hover:text-white transition-colors"
          aria-label="Close menu"
        >
          <X size={18} />
        </button>
      </div>

      {/* Nav */}
      <nav className="flex-1 px-4 pt-2 pb-4 overflow-y-auto custom-scrollbar space-y-2">
        {menuItems.map((item) => {
          const isActive = mounted && pathname === item.href;
          const Icon = item.icon;

          return (
            <Link
              key={item.name}
              href={item.href}
              onClick={() => {
                if (window.innerWidth < 1280) onClose();
              }}
              className={`flex items-center gap-3 px-4 h-[48px] rounded-[10px] border transition-all duration-200 ${
                isActive
                  ? "bg-[#b8e0f0] border-[#b8e0f0] text-[#0a0f24] font-semibold"
                  : "bg-[#1e293b]/40 border-[#334155]/40 text-white hover:bg-[#1e293b]/70 hover:border-[#334155]/70"
              }`}
            >
              <Icon
                className={`w-[18px] h-[18px] flex-shrink-0 ${
                  isActive ? "text-[#0a0f24]" : "text-white"
                }`}
                strokeWidth={1.75}
              />
              <span className="text-[14px] truncate">{item.name}</span>
            </Link>
          );
        })}
      </nav>

      {/* Logout */}
      <div className="px-4 pb-5">
        <button
          onClick={handleLogout}
          className="flex items-center gap-3 px-4 h-[48px] w-full rounded-[10px] text-[#ef4444] hover:bg-[#ef4444]/10 transition-all"
        >
          <LogOut className="w-[18px] h-[18px]" strokeWidth={1.75} />
          <span className="text-[14px] font-semibold">Logout</span>
        </button>
      </div>
    </aside>
  );
}
