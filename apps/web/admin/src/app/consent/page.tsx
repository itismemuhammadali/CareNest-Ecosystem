"use client";

import { useEffect, useState } from "react";
import { createBrowserClient } from "@supabase/ssr";

type State = "loading" | "success" | "expired" | "error";

export default function ConsentPage() {
  const [state, setState] = useState<State>("loading");
  const [message, setMessage] = useState("");

  useEffect(() => {
    const params = new URLSearchParams(window.location.search);
    const token = params.get("token");
    if (!token) {
      setState("error");
      setMessage("No consent token provided.");
      return;
    }

    const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
    const anon = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
    if (!url || !anon) {
      setState("error");
      setMessage("Server configuration error.");
      return;
    }

    const supabase = createBrowserClient(url, anon);

    (async () => {
      try {
        const { data, error } = await supabase.rpc("confirm_guardian_consent", {
          p_token: token,
        });
        if (error) {
          if (
            error.message?.toLowerCase().includes("expired") ||
            error.message?.toLowerCase().includes("not found")
          ) {
            setState("expired");
            setMessage("This consent link has expired or is invalid.");
          } else {
            setState("error");
            setMessage(error.message ?? "An error occurred.");
          }
          return;
        }
        if (data === false) {
          setState("expired");
          setMessage("This consent link has expired or already been used.");
          return;
        }
        setState("success");
        setMessage("Guardian consent confirmed. Thank you!");
      } catch (e) {
        setState("error");
        setMessage(e instanceof Error ? e.message : "Unexpected error.");
      }
    })();
  }, []);

  return (
    <div className="min-h-screen flex items-center justify-center bg-[#0f172a] px-4">
      <div className="w-full max-w-md bg-[#1e293b]/80 border border-white/10 rounded-2xl p-8 shadow-2xl text-center">
        <div className="mb-6">
          <div className="w-16 h-16 rounded-full mx-auto flex items-center justify-center mb-4"
            style={{
              backgroundColor:
                state === "success"
                  ? "rgba(5,223,114,0.15)"
                  : state === "loading"
                  ? "rgba(168,216,234,0.1)"
                  : "rgba(239,68,68,0.15)",
            }}
          >
            {state === "loading" && (
              <svg className="w-8 h-8 animate-spin text-[#a8d8ea]" fill="none" viewBox="0 0 24 24">
                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8z" />
              </svg>
            )}
            {state === "success" && (
              <svg className="w-8 h-8 text-[#05df72]" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
              </svg>
            )}
            {(state === "expired" || state === "error") && (
              <svg className="w-8 h-8 text-[#ef4444]" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
              </svg>
            )}
          </div>

          <h1 className="text-2xl font-bold text-white mb-2">
            {state === "loading" && "Verifying…"}
            {state === "success" && "Consent Confirmed"}
            {state === "expired" && "Link Expired"}
            {state === "error" && "Error"}
          </h1>

          <p className="text-[#94a3b8] text-[15px] leading-relaxed">
            {state === "loading"
              ? "Please wait while we confirm your guardian consent."
              : message}
          </p>
        </div>

        {state === "success" && (
          <div className="bg-[#05df72]/10 border border-[#05df72]/25 rounded-xl p-4 text-left">
            <p className="text-[#05df72] text-[13px] leading-relaxed">
              Your consent has been recorded. The babysitter&apos;s profile is now
              pending admin review.
            </p>
          </div>
        )}

        {state === "expired" && (
          <div className="bg-[#ef4444]/10 border border-[#ef4444]/25 rounded-xl p-4 text-left">
            <p className="text-[#ef4444] text-[13px] leading-relaxed">
              Please ask the babysitter to re-submit their onboarding to receive
              a new consent link.
            </p>
          </div>
        )}
      </div>
    </div>
  );
}
