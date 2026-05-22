"use client";

import React, { useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { Eye, EyeOff, Loader2, ShieldCheck } from "lucide-react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { formatSupabaseError } from "@/lib/supabase/errors";

export default function AdminRegisterPage() {
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirm, setShowConfirm] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [bootstrapCode, setBootstrapCode] = useState("");
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);
  const router = useRouter();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMessage(null);

    if (password.length < 8) {
      setErrorMessage("Password must be at least 8 characters.");
      return;
    }
    if (password !== confirmPassword) {
      setErrorMessage("Passwords do not match.");
      return;
    }
    if (!bootstrapCode.trim()) {
      setErrorMessage("Bootstrap secret code is required.");
      return;
    }

    setIsLoading(true);
    try {
      const supabase = createClient();

      // 1. Create the auth user
      const { data: signUpData, error: signUpError } = await supabase.auth.signUp({
        email: email.trim(),
        password,
        options: {
          data: { role: "admin" },
        },
      });

      if (signUpError) {
        setErrorMessage(formatSupabaseError(signUpError));
        return;
      }

      if (!signUpData.user) {
        setErrorMessage("Sign-up did not return a user. Please try again.");
        return;
      }

      // 2. Grant admin access via bootstrap function
      const { error: rpcError } = await supabase.rpc("admin_register_self", {
        p_bootstrap_code: bootstrapCode.trim(),
      });

      if (rpcError) {
        setErrorMessage(formatSupabaseError(rpcError));
        // Sign out on failure so the partial account doesn't linger
        await supabase.auth.signOut();
        return;
      }

      setSuccess(true);
      setTimeout(() => router.push("/"), 3000);
    } catch (e) {
      setErrorMessage(formatSupabaseError(e));
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <main className="relative min-h-screen flex flex-col items-center justify-center px-6 py-12 antialiased overflow-hidden">
      {/* Background */}
      <div className="absolute inset-0 -z-10">
        <Image src="/login-bg.png" alt="" fill priority sizes="100vw" className="object-cover" />
        <div
          className="absolute inset-0"
          style={{
            background:
              "linear-gradient(0deg, rgba(30, 41, 59, 0.3), rgba(30, 41, 59, 0.3)), linear-gradient(180deg, rgba(15, 23, 42, 0.35) 0%, rgba(15, 23, 42, 0.7) 100%)",
          }}
        />
      </div>

      {/* Logo + Title */}
      <div className="flex flex-col items-center text-center mb-8">
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
        <h1 className="text-[40px] leading-[48px] font-bold text-[#b8e0f0] tracking-tight">
          Admin Portal
        </h1>
        <p className="mt-3 text-[16px] leading-[24px] text-[#94a3b8]">
          Create Admin Account
        </p>
      </div>

      {/* Card */}
      <div className="w-full max-w-[480px] bg-[#1e293b]/60 border border-[#334155]/60 rounded-2xl px-8 py-10 sm:px-10 shadow-[0_24px_60px_-20px_rgba(0,0,0,0.6)]">
        {success ? (
          <div className="text-center space-y-4">
            <div className="flex justify-center">
              <ShieldCheck className="w-14 h-14 text-emerald-400" />
            </div>
            <h2 className="text-[22px] font-semibold text-white">Account Created</h2>
            <p className="text-[14px] text-[#94a3b8]">
              Your admin account is ready. Redirecting to sign in…
            </p>
            <Link
              href="/"
              className="inline-block mt-2 text-[14px] font-semibold text-[#b8e0f0] hover:text-[#c8e8f5] transition-colors"
            >
              Sign in now →
            </Link>
          </div>
        ) : (
          <>
            <div className="text-center mb-8">
              <h2 className="text-[24px] leading-[32px] font-semibold text-white">
                Create Admin Account
              </h2>
              <p className="mt-2 text-[13px] leading-[20px] text-[#94a3b8]">
                Requires the admin bootstrap secret code
              </p>
            </div>

            <form onSubmit={handleSubmit} className="space-y-5">
              {errorMessage ? (
                <p
                  role="alert"
                  className="rounded-lg border border-red-500/40 bg-red-950/40 px-3 py-2 text-sm text-red-200"
                >
                  {errorMessage}
                </p>
              ) : null}

              {/* Email */}
              <div className="space-y-1.5">
                <label htmlFor="reg-email" className="block text-[14px] font-medium text-white">
                  Email Address
                </label>
                <input
                  id="reg-email"
                  required
                  type="email"
                  autoComplete="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="admin@example.com"
                  className="w-full h-[48px] bg-[#0f172a]/60 border border-[#334155]/50 rounded-[10px] px-4 text-[15px] text-white placeholder:text-[#64748b] focus:outline-none focus:border-[#b8e0f0]/60 focus:ring-2 focus:ring-[#b8e0f0]/15 transition-all"
                />
              </div>

              {/* Password */}
              <div className="space-y-1.5">
                <label htmlFor="reg-password" className="block text-[14px] font-medium text-white">
                  Password
                </label>
                <div className="relative">
                  <input
                    id="reg-password"
                    required
                    type={showPassword ? "text" : "password"}
                    autoComplete="new-password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="At least 8 characters"
                    className="w-full h-[48px] bg-[#0f172a]/60 border border-[#334155]/50 rounded-[10px] pl-4 pr-12 text-[15px] text-white placeholder:text-[#64748b] focus:outline-none focus:border-[#b8e0f0]/60 focus:ring-2 focus:ring-[#b8e0f0]/15 transition-all"
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    aria-label={showPassword ? "Hide password" : "Show password"}
                    className="absolute right-3 top-1/2 -translate-y-1/2 p-1.5 text-[#94a3b8] hover:text-white transition-colors"
                  >
                    {showPassword ? <EyeOff className="w-[18px] h-[18px]" /> : <Eye className="w-[18px] h-[18px]" />}
                  </button>
                </div>
              </div>

              {/* Confirm Password */}
              <div className="space-y-1.5">
                <label htmlFor="reg-confirm" className="block text-[14px] font-medium text-white">
                  Confirm Password
                </label>
                <div className="relative">
                  <input
                    id="reg-confirm"
                    required
                    type={showConfirm ? "text" : "password"}
                    autoComplete="new-password"
                    value={confirmPassword}
                    onChange={(e) => setConfirmPassword(e.target.value)}
                    placeholder="Repeat password"
                    className="w-full h-[48px] bg-[#0f172a]/60 border border-[#334155]/50 rounded-[10px] pl-4 pr-12 text-[15px] text-white placeholder:text-[#64748b] focus:outline-none focus:border-[#b8e0f0]/60 focus:ring-2 focus:ring-[#b8e0f0]/15 transition-all"
                  />
                  <button
                    type="button"
                    onClick={() => setShowConfirm(!showConfirm)}
                    aria-label={showConfirm ? "Hide" : "Show"}
                    className="absolute right-3 top-1/2 -translate-y-1/2 p-1.5 text-[#94a3b8] hover:text-white transition-colors"
                  >
                    {showConfirm ? <EyeOff className="w-[18px] h-[18px]" /> : <Eye className="w-[18px] h-[18px]" />}
                  </button>
                </div>
              </div>

              {/* Bootstrap Code */}
              <div className="space-y-1.5">
                <label htmlFor="reg-code" className="block text-[14px] font-medium text-white">
                  Bootstrap Secret Code
                </label>
                <input
                  id="reg-code"
                  required
                  type="password"
                  autoComplete="off"
                  value={bootstrapCode}
                  onChange={(e) => setBootstrapCode(e.target.value)}
                  placeholder="Enter admin bootstrap code"
                  className="w-full h-[48px] bg-[#0f172a]/60 border border-[#334155]/50 rounded-[10px] px-4 text-[15px] text-white placeholder:text-[#64748b] focus:outline-none focus:border-[#b8e0f0]/60 focus:ring-2 focus:ring-[#b8e0f0]/15 transition-all"
                />
              </div>

              <button
                type="submit"
                disabled={isLoading}
                className="w-full h-[48px] bg-[#b8e0f0] hover:bg-[#c8e8f5] active:scale-[0.99] text-[#0a0f24] text-[16px] font-semibold rounded-[10px] transition-all flex items-center justify-center disabled:opacity-70 disabled:cursor-not-allowed mt-2"
              >
                {isLoading ? <Loader2 className="w-5 h-5 animate-spin" /> : "Create Admin Account"}
              </button>
            </form>

            <p className="mt-6 text-center text-[13px] text-[#64748b]">
              Already have an account?{" "}
              <Link href="/" className="text-[#b8e0f0] hover:text-[#c8e8f5] font-medium transition-colors">
                Sign in
              </Link>
            </p>
          </>
        )}
      </div>

      <footer className="mt-10 text-center text-[#94a3b8] text-[13px] leading-[20px]">
        <p>© {new Date().getFullYear()} StarSitters</p>
        <p className="mt-1">Secure Admin Access Only</p>
      </footer>
    </main>
  );
}
