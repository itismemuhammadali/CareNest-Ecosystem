"use client";

import React, { useEffect, useState } from "react";
import { createClient } from "@/lib/supabase/client";

interface Notification {
  id: string;
  title: string | null;
  body: string | null;
  created_at: string;
  read_at: string | null;
}

interface NotificationPanelProps {
  isOpen: boolean;
  onClose: () => void;
}

function timeAgo(iso: string): string {
  const diff = Math.floor((Date.now() - new Date(iso).getTime()) / 1000);
  if (diff < 60) return `${diff}s ago`;
  if (diff < 3600) return `${Math.floor(diff / 60)} min ago`;
  if (diff < 86400) return `${Math.floor(diff / 3600)} hour${Math.floor(diff / 3600) === 1 ? "" : "s"} ago`;
  return `${Math.floor(diff / 86400)} day${Math.floor(diff / 86400) === 1 ? "" : "s"} ago`;
}

export function NotificationPanel({ isOpen, onClose }: NotificationPanelProps) {
  const [notifications, setNotifications] = useState<Notification[]>([]);

  useEffect(() => {
    const supabase = createClient();

    // Initial fetch
    supabase
      .from("notifications")
      .select("id, title, body, created_at, read_at")
      .order("created_at", { ascending: false })
      .limit(50)
      .then(({ data }) => {
        if (data) setNotifications(data as Notification[]);
      });

    // Realtime: prepend new notifications as they arrive
    const channel = supabase
      .channel("admin-notifications-panel")
      .on(
        "postgres_changes",
        { event: "INSERT", schema: "public", table: "notifications" },
        (payload) => {
          setNotifications((prev) => [payload.new as Notification, ...prev].slice(0, 50));
        }
      )
      .on(
        "postgres_changes",
        { event: "UPDATE", schema: "public", table: "notifications" },
        (payload) => {
          setNotifications((prev) =>
            prev.map((n) => (n.id === (payload.new as Notification).id ? (payload.new as Notification) : n))
          );
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, []);

  if (!isOpen) return null;

  const unreadCount = notifications.filter((n) => !n.read_at).length;

  return (
    <>
      <div
        className="fixed inset-0 z-40 bg-transparent"
        onClick={onClose}
      />

      <div className="absolute top-[70px] right-0 w-[380px] bg-[#1A1A1A] border border-[#2A2A2A] rounded-[8px] shadow-[0_20px_50px_rgba(0,0,0,0.5)] z-50 overflow-hidden animate-in fade-in slide-in-from-top-2 duration-200">
        {/* Header */}
        <div className="flex items-center justify-between p-6 border-b border-[#2A2A2A]">
          <h2 className="text-[18px] font-bold text-white">Notifications</h2>
          {unreadCount > 0 && (
            <span className="px-2.5 py-1 bg-[#A2F301] text-black text-[11px] font-bold rounded-full">
              {unreadCount} new
            </span>
          )}
        </div>

        {/* List */}
        <div className="max-h-[480px] overflow-y-auto custom-scrollbar">
          {notifications.length === 0 ? (
            <div className="p-6 text-center text-[#666666] text-[13px]">No notifications yet.</div>
          ) : (
            notifications.map((notif) => (
              <div
                key={notif.id}
                className={`p-6 border-b border-[#2A2A2A] last:border-0 hover:bg-white/[0.02] cursor-pointer transition-colors relative ${
                  !notif.read_at ? "bg-[#A2F301]/[0.03]" : ""
                }`}
              >
                <div className="flex gap-4">
                  {!notif.read_at && (
                    <div className="w-2 h-2 rounded-full bg-[#A2F301] mt-2 flex-shrink-0" />
                  )}
                  <div className={!notif.read_at ? "" : "pl-6"}>
                    <h3 className="text-white font-bold text-[15px] mb-1">
                      {notif.title ?? "Notification"}
                    </h3>
                    {notif.body && (
                      <p className="text-[#999999] text-[13px] mb-2">{notif.body}</p>
                    )}
                    <span className="text-[#666666] text-[11px] uppercase tracking-wider font-medium">
                      {timeAgo(notif.created_at)}
                    </span>
                  </div>
                </div>
              </div>
            ))
          )}
        </div>
      </div>
    </>
  );
}
