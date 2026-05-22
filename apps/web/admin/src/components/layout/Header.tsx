"use client";

import { useEffect, useState } from "react";
import { usePathname, useRouter } from "next/navigation";
import { Search, Bell, ChevronDown, User, Menu } from "lucide-react";
import { ProfileDropdown } from "./ProfileDropdown";
import { createClient } from "@/lib/supabase/client";

interface HeaderProps {
  onMenuClick: () => void;
}

function roleSubtitle(role: string | null | undefined): string {
  if (!role) return "Admin";
  if (role === "admin") return "Admin";
  return role.charAt(0).toUpperCase() + role.slice(1);
}

/** Delivery problems worth surfacing on the bell (not queued / no-device backlog). */
const BADGE_DELIVERY_STATUSES = ["failed", "config_missing", "invalid_sa_json"] as const;

export function Header({ onMenuClick }: HeaderProps) {
  const router = useRouter();
  const pathname = usePathname();
  const [globalSearch, setGlobalSearch] = useState("");
  const [isProfileOpen, setIsProfileOpen] = useState(false);
  const [displayName, setDisplayName] = useState<string>("");
  const [roleLine, setRoleLine] = useState<string>("Admin");
  const [failedDeliveryCount, setFailedDeliveryCount] = useState<number | null>(null);

  useEffect(() => {
    const supabase = createClient();
    let cancelled = false;

    void (async () => {
      const { data: auth } = await supabase.auth.getUser();
      const u = auth.user;
      if (cancelled || !u) return;

      let name =
        (typeof u.user_metadata?.full_name === "string" && u.user_metadata.full_name.trim()) ||
        u.email?.split("@")[0] ||
        "Admin";

      const { data: profile } = await supabase
        .from("users")
        .select("full_name, role")
        .eq("id", u.id)
        .maybeSingle();

      if (cancelled) return;
      if (profile?.full_name?.trim()) name = profile.full_name.trim();
      setDisplayName(name);
      setRoleLine(roleSubtitle(profile?.role));
    })();

    return () => {
      cancelled = true;
    };
  }, []);

  useEffect(() => {
    const supabase = createClient();
    let cancelled = false;

    void (async () => {
      const { count, error } = await supabase
        .from("notifications")
        .select("id", { count: "exact", head: true })
        .in("delivery_status", [...BADGE_DELIVERY_STATUSES]);

      if (!cancelled && !error && count != null) {
        setFailedDeliveryCount(count);
      } else if (!cancelled) {
        setFailedDeliveryCount(0);
      }
    })();

    return () => {
      cancelled = true;
    };
  }, [pathname]);

  return (
    <header className="h-[80px] bg-[#0f172a]/60 backdrop-blur-md border-b border-[#334155]/40 fixed top-0 right-0 left-0 xl:left-[280px] z-40 flex items-center justify-between px-4 sm:px-8">
      {/* Left: hamburger + search */}
      <div className="flex items-center gap-4 flex-1">
        <button
          onClick={onMenuClick}
          className="xl:hidden p-2 text-[#94a3b8] hover:text-white transition-colors"
          aria-label="Open menu"
        >
          <Menu size={22} />
        </button>

        <form
          className="relative w-full max-w-[420px] hidden sm:block"
          onSubmit={(e) => {
            e.preventDefault();
            const t = globalSearch.trim();
            router.push(t ? `/search?q=${encodeURIComponent(t)}` : "/search");
          }}
        >
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-[18px] h-[18px] text-[#64748b] pointer-events-none" />
          <input
            type="search"
            name="q"
            value={globalSearch}
            onChange={(e) => setGlobalSearch(e.target.value)}
            placeholder="Search families, sitters, jobs…"
            autoComplete="off"
            className="w-full h-[44px] bg-[#0f172a]/70 border border-[#334155]/60 rounded-[10px] pl-11 pr-4 text-[14px] text-white placeholder:text-[#64748b] focus:outline-none focus:border-[#b8e0f0]/50 focus:ring-2 focus:ring-[#b8e0f0]/15 transition-all"
          />
        </form>
      </div>

      {/* Right: notifications + user */}
      <div className="flex items-center gap-4 sm:gap-6 relative">
        <button
          onClick={() => router.push("/notifications")}
          aria-label={
            failedDeliveryCount != null && failedDeliveryCount > 0
              ? `Notifications, ${failedDeliveryCount} delivery failed`
              : "Notifications"
          }
          className="relative p-2 text-[#94a3b8] hover:text-white transition-colors"
        >
          <Bell className="w-[22px] h-[22px]" strokeWidth={1.75} />
          {failedDeliveryCount != null && failedDeliveryCount > 0 ? (
            <span className="absolute -top-0.5 -right-0.5 min-w-[18px] h-[18px] px-1 bg-[#b8e0f0] text-[#0a0f24] text-[10px] font-bold flex items-center justify-center rounded-full">
              {failedDeliveryCount > 99 ? "99+" : failedDeliveryCount}
            </span>
          ) : null}
        </button>

        <div
          onClick={() => setIsProfileOpen(!isProfileOpen)}
          className="flex items-center gap-3 cursor-pointer group relative"
        >
          <div className="text-right hidden sm:flex flex-col justify-center min-w-0 max-w-[200px]">
            <p className="text-[14px] font-semibold text-white leading-none mb-1 group-hover:text-[#b8e0f0] transition-colors truncate">
              {displayName || "…"}
            </p>
            <p className="text-[12px] text-[#94a3b8] leading-none truncate">{roleLine}</p>
          </div>
          <div className="w-[40px] h-[40px] rounded-full bg-[#334155]/70 border border-[#475569]/40 flex items-center justify-center">
            <User className="w-5 h-5 text-[#cbd5e1]" strokeWidth={1.75} />
          </div>
          <ChevronDown
            className={`w-4 h-4 text-[#94a3b8] transition-transform ${
              isProfileOpen ? "rotate-180 text-white" : ""
            }`}
          />

          <ProfileDropdown
            isOpen={isProfileOpen}
            onClose={() => setIsProfileOpen(false)}
          />
        </div>
      </div>
    </header>
  );
}
