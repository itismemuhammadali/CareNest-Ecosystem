"use client";

import React, { useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { ArrowLeft, Mail, CheckCircle2, Loader2 } from "lucide-react";
import { createClient } from "@/lib/supabase/client";

export default function ForgotPasswordPage() {
  const [email, setEmail] = useState("");
  const [isSubmitted, setIsSubmitted] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const sendReset = async () => {
    setErrorMessage(null);
    setIsLoading(true);
    try {
      const supabase = createClient();
      const redirectTo = `${window.location.origin}/reset-password`;
      const { error } = await supabase.auth.resetPasswordForEmail(email.trim(), {
        redirectTo,
      });
      if (error) {
        setErrorMessage(error.message);
        return;
      }
      setIsSubmitted(true);
    } finally {
      setIsLoading(false);
    }
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    void sendReset();
  };

  return (
    <main className="relative min-h-screen flex flex-col items-center justify-center px-6 py-12 antialiased overflow-hidden">
      {/* Background image */}
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

      {/* Centered column */}
      <div className="w-full max-w-[480px] flex flex-col items-center">
        {/* Back to Sign In — only on form state */}
        {!isSubmitted && (
          <div className="w-full mb-6">
            <Link
              href="/"
              className="inline-flex items-center gap-2 text-[14px] text-[#94a3b8] hover:text-white transition-colors group"
            >
              <ArrowLeft className="w-4 h-4 transition-transform group-hover:-translate-x-0.5" />
              Back to Sign In
            </Link>
          </div>
        )}

        {/* Logo */}
        <div className="relative w-[88px] h-[88px] mb-8 rounded-full overflow-hidden">
          <Image
            src="/images/star-sitters-logo.jpeg"
            alt="Star Sitters"
            fill
            sizes="88px"
            className="object-cover"
            priority
          />
        </div>

        {/* Card */}
        <div className="w-full bg-[#1e293b]/60 backdrop-blur-md border border-[#334155]/60 rounded-2xl px-8 py-10 sm:px-10 shadow-[0_24px_60px_-20px_rgba(0,0,0,0.6)]">
          {!isSubmitted ? (
            <>
              {/* Mail icon circle */}
              <div className="flex justify-center mb-5">
                <div className="w-12 h-12 rounded-full bg-[#475569]/40 border border-[#475569]/40 flex items-center justify-center">
                  <Mail className="w-5 h-5 text-[#cbd5e1]" />
                </div>
              </div>

              <div className="text-center mb-8">
                <h2 className="text-[20px] leading-[28px] font-semibold text-white">
                  Forgot Password?
                </h2>
                <p className="mt-2 text-[14px] leading-[22px] text-[#94a3b8]">
                  Enter your email address and we&apos;ll send you instructions
                  to reset your password
                </p>
              </div>

              <form onSubmit={handleSubmit} className="space-y-6">
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
                    htmlFor="email"
                    className="block text-[14px] leading-[20px] font-medium text-white"
                  >
                    Email Address
                  </label>
                  <input
                    id="email"
                    required
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="admin@babysit.com"
                    className="w-full h-[48px] bg-[#0f172a]/60 border border-[#334155]/50 rounded-[10px] px-4 text-[15px] text-white placeholder:text-[#64748b] focus:outline-none focus:border-[#b8e0f0]/60 focus:ring-2 focus:ring-[#b8e0f0]/15 transition-all"
                  />
                </div>

                <button
                  type="submit"
                  disabled={isLoading}
                  className="w-full h-[48px] bg-[#b8e0f0] hover:bg-[#c8e8f5] active:scale-[0.99] text-[#0a0f24] text-[16px] font-semibold rounded-[10px] transition-all flex items-center justify-center disabled:opacity-70 disabled:cursor-not-allowed"
                >
                  {isLoading ? (
                    <Loader2 className="w-5 h-5 animate-spin" />
                  ) : (
                    "Send Reset Instructions"
                  )}
                </button>
              </form>
            </>
          ) : (
            <div className="text-center">
              {/* Teal-green checkmark badge */}
              <div className="flex justify-center mb-5">
                <div className="w-16 h-16 rounded-full bg-[#34d399]/15 flex items-center justify-center">
                  <CheckCircle2 className="w-9 h-9 text-[#34d399]" strokeWidth={1.5} />
                </div>
              </div>

              <h2 className="text-[20px] leading-[28px] font-semibold text-white">
                Check Your Email
              </h2>

              <p className="mt-3 text-[14px] leading-[22px] text-[#94a3b8]">
                We&apos;ve sent password reset instructions to
              </p>

              <p className="mt-4 text-[16px] font-medium text-[#b8e0f0] break-all">
                {email}
              </p>

              <p className="mt-4 text-[14px] leading-[22px] text-[#94a3b8]">
                Click the link in the email to reset your password. If you don&apos;t see the email, check your spam folder.
              </p>

              <button
                type="button"
                disabled={isLoading}
                onClick={() => void sendReset()}
                className="w-full mt-8 h-[48px] bg-[#0f172a]/70 border border-[#334155]/80 text-white text-[15px] font-medium rounded-[12px] shadow-[inset_0_1px_0_rgba(255,255,255,0.05),0_1px_2px_rgba(0,0,0,0.2)] hover:bg-[#0f172a]/90 transition-all disabled:opacity-60 disabled:cursor-not-allowed"
              >
                {isLoading ? (
                  <span className="inline-flex items-center justify-center gap-2">
                    <Loader2 className="w-5 h-5 animate-spin" />
                    Sending…
                  </span>
                ) : (
                  "Resend Email"
                )}
              </button>

              <Link
                href="/"
                className="mt-4 inline-flex items-center justify-center gap-2 text-[15px] text-white hover:text-[#b8e0f0] transition-colors group"
              >
                <ArrowLeft className="w-4 h-4 transition-transform group-hover:-translate-x-0.5" />
                Back to Sign In
              </Link>
            </div>
          )}
        </div>

        {/* Footer link — only on form state */}
        {!isSubmitted && (
          <div className="mt-6 text-center text-[14px] leading-[22px]">
            <p className="text-[#94a3b8]">Remember your password?</p>
            <Link
              href="/"
              className="text-[#b8e0f0] hover:text-[#c8e8f5] font-medium transition-colors"
            >
              Sign in here
            </Link>
          </div>
        )}
      </div>
    </main>
  );
}
