"use client";

import React, { useEffect, useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { Eye, EyeOff, Loader2, CheckCircle2 } from "lucide-react";
import { createClient } from "@/lib/supabase/client";

type LinkState = "checking" | "ready" | "invalid";

function hasRecoveryUrlSignal(): boolean {
  if (typeof window === "undefined") return false;
  const hash = new URLSearchParams(window.location.hash.replace(/^#/, ""));
  if (hash.get("type") === "recovery") return true;
  if (new URLSearchParams(window.location.search).has("code")) return true;
  return false;
}

export default function ResetPasswordPage() {
  const router = useRouter();
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [showNewPassword, setShowNewPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [isSuccess, setIsSuccess] = useState(false);
  const [linkState, setLinkState] = useState<LinkState>("checking");
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const canSubmit =
    newPassword.length >= 8 &&
    newPassword === confirmPassword &&
    confirmPassword !== "";

  useEffect(() => {
    const supabase = createClient();
    let settled = false;
    let timeoutId: ReturnType<typeof setTimeout> | undefined;

    const ready = () => {
      if (settled) return;
      settled = true;
      if (timeoutId) clearTimeout(timeoutId);
      setLinkState("ready");
    };

    const invalid = () => {
      if (settled) return;
      settled = true;
      if (timeoutId) clearTimeout(timeoutId);
      setLinkState("invalid");
    };

    const maxWaitMs = hasRecoveryUrlSignal() ? 12_000 : 600;

    const { data: sub } = supabase.auth.onAuthStateChange((event) => {
      if (event === "PASSWORD_RECOVERY") ready();
    });

    void supabase.auth.getSession().then(({ data }) => {
      if (data.session) ready();
    });

    timeoutId = setTimeout(() => {
      if (settled) return;
      void supabase.auth.getSession().then(({ data }) => {
        if (settled) return;
        if (data.session) ready();
        else invalid();
      });
    }, maxWaitMs);

    return () => {
      if (timeoutId) clearTimeout(timeoutId);
      sub.subscription.unsubscribe();
    };
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!canSubmit || linkState !== "ready") return;
    setErrorMessage(null);
    setIsLoading(true);
    try {
      const supabase = createClient();
      const { error } = await supabase.auth.updateUser({ password: newPassword });
      if (error) {
        setErrorMessage(error.message);
        return;
      }
      setIsSuccess(true);
      router.refresh();
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <main className="relative min-h-screen flex flex-col items-center justify-center px-6 py-12 antialiased overflow-hidden">
      <div className="absolute inset-0 -z-10">
        <Image
          src="/login-bg.png"
          alt=""
          fill
          priority
          sizes="100vw"
          className="object-cover"
        />
        <div
          className="absolute inset-0"
          style={{
            background:
              "linear-gradient(0deg, rgba(30, 41, 59, 0.3), rgba(30, 41, 59, 0.3)), linear-gradient(180deg, rgba(15, 23, 42, 0.35) 0%, rgba(15, 23, 42, 0.7) 100%)",
          }}
        />
      </div>

      <div className="w-full max-w-[480px] flex flex-col items-center">
        <div className="relative w-[88px] h-[88px] mb-6 rounded-full overflow-hidden">
          <Image
            src="/images/star-sitters-logo.jpeg"
            alt="Star Sitters"
            fill
            sizes="88px"
            className="object-cover"
            priority
          />
        </div>

        <div className="w-full bg-[#1e293b]/60 backdrop-blur-md border border-[#334155]/60 rounded-2xl px-8 py-10 sm:px-10 shadow-[0_24px_60px_-20px_rgba(0,0,0,0.6)]">
          {linkState === "checking" ? (
            <div className="flex flex-col items-center justify-center py-12 gap-4 text-center">
              <Loader2 className="w-10 h-10 animate-spin text-[#b8e0f0]" />
              <p className="text-[15px] text-[#94a3b8]">Verifying reset link…</p>
            </div>
          ) : linkState === "invalid" ? (
            <div className="text-center py-4">
              <h2 className="text-[20px] font-semibold text-white mb-3">Link invalid or expired</h2>
              <p className="text-[14px] text-[#94a3b8] mb-6">
                Open the link from your latest reset email, or request a new one.
              </p>
              <Link
                href="/forgot-password"
                className="inline-flex w-full h-[48px] items-center justify-center bg-[#b8e0f0] hover:bg-[#c8e8f5] text-[#0a0f24] text-[15px] font-semibold rounded-[10px] transition-colors"
              >
                Request new link
              </Link>
              <Link
                href="/"
                className="mt-4 inline-block text-[15px] text-[#b8e0f0] hover:text-[#c8e8f5] font-medium"
              >
                Back to Sign In
              </Link>
            </div>
          ) : !isSuccess ? (
            <>
              <div className="text-center mb-8">
                <h2 className="text-[20px] leading-[28px] font-semibold text-white">
                  Create New Password
                </h2>
                <p className="mt-2 text-[14px] leading-[22px] text-[#94a3b8]">
                  Your new password must be at least 8 characters
                </p>
              </div>

              <form onSubmit={(e) => void handleSubmit(e)} className="space-y-6">
                {errorMessage ? (
                  <p
                    role="alert"
                    className="rounded-lg border border-red-500/40 bg-red-950/40 px-3 py-2 text-sm text-red-200"
                  >
                    {errorMessage}
                  </p>
                ) : null}

                <div className="space-y-2">
                  <label
                    htmlFor="new-password"
                    className="block text-[14px] leading-[20px] font-medium text-white"
                  >
                    New Password
                  </label>
                  <div className="relative">
                    <button
                      type="button"
                      onClick={() => setShowNewPassword(!showNewPassword)}
                      aria-label={showNewPassword ? "Hide password" : "Show password"}
                      className="absolute left-3 top-1/2 -translate-y-1/2 p-1.5 text-[#94a3b8] hover:text-white transition-colors"
                    >
                      {showNewPassword ? (
                        <EyeOff className="w-[18px] h-[18px]" />
                      ) : (
                        <Eye className="w-[18px] h-[18px]" />
                      )}
                    </button>
                    <input
                      id="new-password"
                      required
                      type={showNewPassword ? "text" : "password"}
                      autoComplete="new-password"
                      value={newPassword}
                      onChange={(e) => setNewPassword(e.target.value)}
                      placeholder="Enter new password"
                      className="w-full h-[48px] bg-[#0f172a]/60 border border-[#334155]/50 rounded-[10px] pl-11 pr-4 text-[15px] text-white placeholder:text-[#64748b] focus:outline-none focus:border-[#b8e0f0]/60 focus:ring-2 focus:ring-[#b8e0f0]/15 transition-all"
                    />
                  </div>
                </div>

                <div className="space-y-2">
                  <label
                    htmlFor="confirm-password"
                    className="block text-[14px] leading-[20px] font-medium text-white"
                  >
                    Confirm New Password
                  </label>
                  <div className="relative">
                    <button
                      type="button"
                      onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                      aria-label={showConfirmPassword ? "Hide password" : "Show password"}
                      className="absolute left-3 top-1/2 -translate-y-1/2 p-1.5 text-[#94a3b8] hover:text-white transition-colors"
                    >
                      {showConfirmPassword ? (
                        <EyeOff className="w-[18px] h-[18px]" />
                      ) : (
                        <Eye className="w-[18px] h-[18px]" />
                      )}
                    </button>
                    <input
                      id="confirm-password"
                      required
                      type={showConfirmPassword ? "text" : "password"}
                      autoComplete="new-password"
                      value={confirmPassword}
                      onChange={(e) => setConfirmPassword(e.target.value)}
                      placeholder="Confirm new password"
                      className="w-full h-[48px] bg-[#0f172a]/60 border border-[#334155]/50 rounded-[10px] pl-11 pr-4 text-[15px] text-white placeholder:text-[#64748b] focus:outline-none focus:border-[#b8e0f0]/60 focus:ring-2 focus:ring-[#b8e0f0]/15 transition-all"
                    />
                  </div>
                </div>

                <button
                  type="submit"
                  disabled={isLoading || !canSubmit}
                  className="w-full h-[48px] bg-[#b8e0f0] hover:bg-[#c8e8f5] active:scale-[0.99] text-[#0a0f24] text-[16px] font-semibold rounded-[10px] transition-all flex items-center justify-center disabled:bg-[#b8e0f0]/50 disabled:text-[#0a0f24]/70 disabled:cursor-not-allowed disabled:hover:bg-[#b8e0f0]/50"
                >
                  {isLoading ? (
                    <Loader2 className="w-5 h-5 animate-spin" />
                  ) : (
                    "Reset Password"
                  )}
                </button>
              </form>
            </>
          ) : (
            <div className="text-center">
              <div className="flex justify-center mb-5">
                <div className="w-16 h-16 rounded-full bg-[#34d399]/15 flex items-center justify-center">
                  <CheckCircle2 className="w-9 h-9 text-[#34d399]" strokeWidth={1.5} />
                </div>
              </div>

              <h2 className="text-[20px] leading-[28px] font-semibold text-white">Password Reset!</h2>
              <p className="mt-3 text-[14px] leading-[22px] text-[#94a3b8]">
                Your password has been successfully reset. You can now sign in with your new password.
              </p>

              <Link
                href="/"
                className="w-full mt-8 h-[48px] bg-[#b8e0f0] hover:bg-[#c8e8f5] text-[#0a0f24] text-[15px] font-semibold rounded-[10px] flex items-center justify-center transition-all"
              >
                Back to Sign In
              </Link>
            </div>
          )}
        </div>

        {!isSuccess && linkState === "ready" && (
          <div className="mt-6 text-center text-[14px] leading-[22px]">
            <p className="text-[#94a3b8]">Remember your password?</p>
            <Link
              href="/"
              className="text-[#b8e0f0] hover:text-[#c8e8f5] font-medium transition-colors"
            >
              Back to Sign In
            </Link>
          </div>
        )}
      </div>
    </main>
  );
}
