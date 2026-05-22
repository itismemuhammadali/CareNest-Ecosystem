"use client";

import React, { useEffect, useState } from "react";
import { DollarSign, Clock, ChevronDown, Save } from "lucide-react";
import {
  adminUpdateSystemConfig,
  fetchSystemConfigRows,
  fetchWageTiers,
  updateWageTiers,
} from "@/lib/supabase/admin";
import { formatSupabaseError } from "@/lib/supabase/errors";

type TimeRounding = "exact" | "round-up" | "round-15" | "round-30";
type Overtime = "disabled" | "1.5x" | "2x";

interface Rates {
  age11_12: number;
  age13_14: number;
  age15_17: number;
}

const DEFAULT_RATES: Rates = {
  age11_12: 10,
  age13_14: 12,
  age15_17: 15,
};

const ROUNDING_LABELS: Record<TimeRounding, string> = {
  exact: "Exact Minutes (Most Accurate)",
  "round-up": "Round Up to Next Hour",
  "round-15": "Round to Nearest 15 Minutes",
  "round-30": "Round to Nearest 30 Minutes",
};

const OVERTIME_LABELS: Record<Overtime, string> = {
  disabled: "Disabled",
  "1.5x": "1.5× after 8 hours",
  "2x": "2× after 8 hours",
};

const ROUNDING_VALUES: TimeRounding[] = ["exact", "round-up", "round-15", "round-30"];
const OVERTIME_VALUES: Overtime[] = ["disabled", "1.5x", "2x"];

function configString(v: unknown): string | null {
  if (typeof v === "string") return v;
  if (v == null) return null;
  if (typeof v === "object") return JSON.stringify(v).replace(/^"|"$/g, "");
  return String(v);
}

function parseRounding(rows: { key: string; value: unknown }[]): TimeRounding {
  const s = configString(rows.find((r) => r.key === "time_rounding_mode")?.value);
  if (s && ROUNDING_VALUES.includes(s as TimeRounding)) return s as TimeRounding;
  return "exact";
}

function parseOvertime(rows: { key: string; value: unknown }[]): Overtime {
  const s = configString(rows.find((r) => r.key === "overtime_mode")?.value);
  if (s && OVERTIME_VALUES.includes(s as Overtime)) return s as Overtime;
  return "disabled";
}

function rateForAge(age: number, rates: Rates): number {
  if (age <= 12) return rates.age11_12;
  if (age <= 14) return rates.age13_14;
  return rates.age15_17;
}

interface Example {
  age: number;
  hours: number;
}

const EXAMPLES: Example[] = [
  { age: 16, hours: 4 },
  { age: 13, hours: 3.5 },
  { age: 12, hours: 2 },
];

export default function WagesPage() {
  const [rates, setRates] = useState<Rates>(DEFAULT_RATES);
  const [draftRates, setDraftRates] = useState<Rates>(DEFAULT_RATES);
  const [rounding, setRounding] = useState<TimeRounding>("exact");
  const [overtime, setOvertime] = useState<Overtime>("disabled");
  const [busy, setBusy] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [savedAt, setSavedAt] = useState<string | null>(null);
  const [loadedRounding, setLoadedRounding] = useState<TimeRounding>("exact");
  const [loadedOvertime, setLoadedOvertime] = useState<Overtime>("disabled");

  useEffect(() => {
    void (async () => {
      try {
        const [tiers, cfgRows] = await Promise.all([fetchWageTiers(), fetchSystemConfigRows()]);
        const today = new Date().toISOString().slice(0, 10);
        const active = tiers.filter(
          (t: { effective_from: string }) => t.effective_from <= today,
        );
        const latestByMin: Record<number, number> = {};
        for (const t of active as { min_age: number; hourly_rate: number | string; effective_from: string }[]) {
          latestByMin[t.min_age] = Number(t.hourly_rate);
        }
        const next: Rates = {
          age11_12: latestByMin[11] ?? DEFAULT_RATES.age11_12,
          age13_14: latestByMin[13] ?? DEFAULT_RATES.age13_14,
          age15_17: latestByMin[15] ?? DEFAULT_RATES.age15_17,
        };
        setRates(next);
        setDraftRates(next);
        const r = parseRounding(cfgRows);
        const o = parseOvertime(cfgRows);
        setRounding(r);
        setOvertime(o);
        setLoadedRounding(r);
        setLoadedOvertime(o);
      } catch (e) {
        setErrorMessage(formatSupabaseError(e));
      }
    })();
  }, []);

  const update = <K extends keyof Rates>(key: K, value: number) => {
    setDraftRates({ ...draftRates, [key]: value });
  };

  const handleSave = async () => {
    setBusy(true);
    setErrorMessage(null);
    try {
      await Promise.all([
        adminUpdateSystemConfig({
          time_rounding_mode: rounding,
          overtime_mode: overtime,
        }),
        updateWageTiers([
          { min_age: 11, max_age: 12, hourly_rate: draftRates.age11_12 },
          { min_age: 13, max_age: 14, hourly_rate: draftRates.age13_14 },
          { min_age: 15, max_age: 17, hourly_rate: draftRates.age15_17 },
        ]),
      ]);
      setRates(draftRates);
      setLoadedRounding(rounding);
      setLoadedOvertime(overtime);
      setSavedAt(new Date().toLocaleTimeString());
    } catch (e) {
      setErrorMessage(formatSupabaseError(e));
    } finally {
      setBusy(false);
    }
  };

  const handleCancel = () => {
    setDraftRates(rates);
    setRounding(loadedRounding);
    setOvertime(loadedOvertime);
  };

  return (
    <div className="space-y-6">
      {/* Page header */}
      <div>
        <h1 className="text-[32px] leading-[40px] font-bold text-white">
          Wage Configuration
        </h1>
        <p className="mt-1 text-[15px] text-[#94a3b8]">
          Configure age-based hourly rates and wage calculation rules
        </p>
      </div>

      {/* Age-Based Hourly Rates card */}
      <section className="bg-[#1e293b]/60 backdrop-blur-md border border-white/10 rounded-2xl p-6 sm:p-7 shadow-[0_24px_60px_-30px_rgba(0,0,0,0.6)]">
        <div className="flex items-center gap-2.5">
          <DollarSign className="w-5 h-5 text-[#34d399]" strokeWidth={2} />
          <h2 className="text-[18px] leading-[26px] font-semibold text-white">
            Age-Based Hourly Rates
          </h2>
        </div>
        <p className="mt-1 text-[14px] text-[#94a3b8]">
          Configure wage rates based on babysitter age groups
        </p>

        {/* Rate inputs */}
        <div className="mt-6 grid grid-cols-1 md:grid-cols-3 gap-5">
          <RateField
            label="Age 11-12"
            caption="Entry-level babysitters"
            value={draftRates.age11_12}
            onChange={(v) => update("age11_12", v)}
          />
          <RateField
            label="Age 13-14"
            caption="Intermediate babysitters"
            value={draftRates.age13_14}
            onChange={(v) => update("age13_14", v)}
          />
          <RateField
            label="Age 15-17"
            caption="Experienced babysitters"
            value={draftRates.age15_17}
            onChange={(v) => update("age15_17", v)}
          />
        </div>

        {/* Rules row */}
        <div className="mt-7 grid grid-cols-1 md:grid-cols-2 gap-5">
          <div>
            <label className="flex items-center gap-2 mb-2">
              <Clock className="w-4 h-4 text-white" strokeWidth={2} />
              <span className="text-[14px] font-semibold text-white">Time Rounding Rule</span>
            </label>
            <SelectField
              value={rounding}
              onChange={(v) => setRounding(v as TimeRounding)}
              options={Object.entries(ROUNDING_LABELS).map(([value, label]) => ({ value, label }))}
            />
            <p className="mt-2 text-[13px] text-[#94a3b8]">
              How to calculate partial hours worked
            </p>
          </div>
          <div>
            <label className="block text-[14px] font-semibold text-white mb-2">
              Overtime Rule
            </label>
            <SelectField
              value={overtime}
              onChange={(v) => setOvertime(v as Overtime)}
              options={Object.entries(OVERTIME_LABELS).map(([value, label]) => ({ value, label }))}
            />
            <p className="mt-2 text-[13px] text-[#94a3b8]">
              Optional overtime multiplier
            </p>
          </div>
        </div>

        {errorMessage ? (
          <p
            role="alert"
            className="mt-4 rounded-lg border border-red-500/40 bg-red-950/40 px-3 py-2 text-sm text-red-200"
          >
            {errorMessage}
          </p>
        ) : null}
        {savedAt ? (
          <p className="mt-4 text-sm text-[#34d399]">
            Saved to Supabase at {savedAt}. Age-tier rates take effect on the next effective date
            (see BACKEND.md §11); rounding and overtime rules are stored in{" "}
            <code className="text-[#94a3b8]">system_config</code>.
          </p>
        ) : null}

        {/* Action buttons */}
        <div className="mt-7 flex items-center gap-3">
          <button
            onClick={() => void handleSave()}
            disabled={busy}
            className="inline-flex items-center gap-2 px-5 h-[42px] bg-[#34d399]/20 hover:bg-[#34d399]/30 border border-[#34d399]/40 text-[#34d399] text-[14px] font-semibold rounded-[10px] transition-all disabled:opacity-60"
          >
            <Save className="w-4 h-4" strokeWidth={2} />
            {busy ? "Saving…" : "Save Changes"}
          </button>
          <button
            onClick={handleCancel}
            className="px-5 h-[42px] bg-transparent text-white text-[14px] font-medium hover:text-[#b8e0f0] transition-colors"
          >
            Cancel
          </button>
        </div>
      </section>

      {/* Wage Calculation Examples card */}
      <section className="bg-[#1e293b]/60 backdrop-blur-md border border-white/10 rounded-2xl p-6 sm:p-7 shadow-[0_24px_60px_-30px_rgba(0,0,0,0.6)]">
        <h2 className="text-[18px] leading-[26px] font-semibold text-white">
          Wage Calculation Examples
        </h2>
        <p className="mt-1 text-[14px] text-[#94a3b8]">
          Based on current configuration
        </p>

        <div className="mt-5 space-y-3">
          {EXAMPLES.map((ex) => {
            const rate = rateForAge(ex.age, rates);
            const wage = rate * ex.hours;
            return (
              <div
                key={ex.age}
                className="bg-[#0f172a]/60 border border-white/10 rounded-[12px] px-5 py-4 flex items-start justify-between gap-4"
              >
                <div className="min-w-0">
                  <p className="text-[15px] font-semibold text-white">
                    Babysitter Age {ex.age} <span className="mx-1 text-[#94a3b8]">•</span> {ex.hours} hours worked
                  </p>
                  <p className="mt-1 text-[13px] text-[#94a3b8]">
                    Using {ROUNDING_LABELS[rounding].toLowerCase().replace("most accurate", "").replace("(", "").replace(")", "").trim()}
                  </p>
                  <p className="mt-1 text-[13px] text-[#94a3b8]">
                    Calculation: ${rate.toFixed(2)}/hr × {ex.hours} hours
                  </p>
                </div>
                <span className="inline-flex items-center px-3 py-1 rounded-md bg-[#34d399]/15 border border-[#34d399]/25 text-[#34d399] text-[13px] font-semibold flex-shrink-0">
                  ${wage.toFixed(2)}
                </span>
              </div>
            );
          })}
        </div>
      </section>
    </div>
  );
}

function RateField({
  label,
  caption,
  value,
  onChange,
}: {
  label: string;
  caption: string;
  value: number;
  onChange: (v: number) => void;
}) {
  return (
    <div>
      <p className="text-[14px] font-semibold text-white mb-2">{label}</p>
      <div className="flex items-center gap-2">
        <span className="text-[15px] text-[#94a3b8]">$</span>
        <input
          type="number"
          value={value}
          onChange={(e) => onChange(Number(e.target.value) || 0)}
          className="flex-1 h-[44px] bg-transparent border border-white/40 rounded-[10px] px-4 text-[15px] text-white placeholder:text-[#64748b] focus:outline-none focus:border-[#b8e0f0]/60 focus:ring-2 focus:ring-[#b8e0f0]/15 transition-all"
        />
        <span className="text-[15px] text-[#94a3b8]">/hr</span>
      </div>
      <p className="mt-2 text-[13px] text-[#94a3b8]">{caption}</p>
    </div>
  );
}

function SelectField({
  value,
  onChange,
  options,
}: {
  value: string;
  onChange: (v: string) => void;
  options: { value: string; label: string }[];
}) {
  return (
    <div className="relative">
      <select
        value={value}
        onChange={(e) => onChange(e.target.value)}
        className="appearance-none w-full h-[48px] bg-transparent border border-white/40 rounded-[10px] pl-4 pr-10 text-[14px] text-white focus:outline-none focus:border-[#b8e0f0]/60 focus:ring-2 focus:ring-[#b8e0f0]/15 transition-all"
      >
        {options.map((o) => (
          <option key={o.value} value={o.value} className="bg-[#1e293b]">
            {o.label}
          </option>
        ))}
      </select>
      <ChevronDown className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-[#94a3b8] pointer-events-none" />
    </div>
  );
}
