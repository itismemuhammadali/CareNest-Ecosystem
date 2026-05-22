"use client";

import React, { useCallback, useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { Eye, EyeOff, Loader2 } from "lucide-react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";

export default function LoginPage() {
  const [showPassword, setShowPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const router = useRouter();

  // Click logo to navigate to signup
  const handleLogoClick = useCallback(() => {
    router.push("/register");
  }, [router]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMessage(null);
    setIsLoading(true);
    try {
      const supabase = createClient();
      const { error } = await supabase.auth.signInWithPassword({
        email: email.trim(),
        password,
      });
      if (error) {
        setErrorMessage(error.message);
        return;
      }
      router.push("/dashboard");
      router.refresh();
    } finally {
      setIsLoading(false);
    }
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

      {/* Logo + Title */}
      <div className="flex flex-col items-center text-center mb-8">
        <div
          role="button"
          tabIndex={-1}
          onClick={handleLogoClick}
          className="relative w-[88px] h-[88px] mb-6 rounded-full overflow-hidden cursor-pointer select-none"
          title=""
        >
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
          Teen Babysitting Marketplace
        </p>
      </div>

      {/* Sign In Card */}
      <div className="w-full max-w-[480px] bg-[#1e293b]/60  border border-[#334155]/60 rounded-2xl px-8 py-10 sm:px-10 shadow-[0_24px_60px_-20px_rgba(0,0,0,0.6)]">
        <div className="text-center mb-8">
          <h2 className="text-[24px] leading-[32px] font-semibold text-white">
            Sign In
          </h2>
          <p className="mt-2 text-[14px] leading-[20px] text-[#94a3b8]">
            Enter your credentials to access the
            <br />
            admin dashboard
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
          {/* Email */}
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
              autoComplete="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="admin@babysit.com"
              className="w-full h-[48px] bg-[#0f172a]/60 border border-[#334155]/50 rounded-[10px] px-4 text-[15px] text-white placeholder:text-[#64748b] focus:outline-none focus:border-[#b8e0f0]/60 focus:ring-2 focus:ring-[#b8e0f0]/15 transition-all"
            />
          </div>

          {/* Password */}
          <div className="space-y-2">
            <label
              htmlFor="password"
              className="block text-[14px] leading-[20px] font-medium text-white"
            >
              Password
            </label>
            <div className="relative">
              <input
                id="password"
                required
                type={showPassword ? "text" : "password"}
                autoComplete="current-password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="Enter your password"
                className="w-full h-[48px] bg-[#0f172a]/60 border border-[#334155]/50 rounded-[10px] pl-4 pr-12 text-[15px] text-white placeholder:text-[#64748b] focus:outline-none focus:border-[#b8e0f0]/60 focus:ring-2 focus:ring-[#b8e0f0]/15 transition-all"
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                aria-label={showPassword ? "Hide password" : "Show password"}
                className="absolute right-3 top-1/2 -translate-y-1/2 p-1.5 text-[#94a3b8] hover:text-white transition-colors"
              >
                {showPassword ? (
                  <EyeOff className="w-[18px] h-[18px]" />
                ) : (
                  <Eye className="w-[18px] h-[18px]" />
                )}
              </button>
            </div>
          </div>

          {/* Forgot password */}
          <div className="flex justify-end">
            <Link
              href="/forgot-password"
              className="text-[14px] font-semibold text-[#b8e0f0] hover:text-[#c8e8f5] transition-colors"
            >
              Forgot password?
            </Link>
          </div>

          {/* Submit */}
          <button
            type="submit"
            disabled={isLoading}
            className="w-full h-[48px] bg-[#b8e0f0] hover:bg-[#c8e8f5] active:scale-[0.99] text-[#0a0f24] text-[16px] font-semibold rounded-[10px] transition-all flex items-center justify-center disabled:opacity-70 disabled:cursor-not-allowed"
          >
            {isLoading ? (
              <Loader2 className="w-5 h-5 animate-spin" />
            ) : (
              "Sign In"
            )}
          </button>
        </form>
      </div>

      {/* Footer */}
      <footer className="mt-10 text-center text-[#94a3b8] text-[13px] leading-[20px]">
        <p>© {new Date().getFullYear()} StarSitters</p>
        <p className="mt-1">Secure Admin Access Only</p>
      </footer>
    </main>
  );
}
