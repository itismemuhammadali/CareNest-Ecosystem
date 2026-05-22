"use client";

import type { ReportCertStats, ReportSummary } from "@/lib/supabase/admin";
import { jsPDF } from "jspdf";
import autoTable from "jspdf-autotable";

export type ReportsPdfInput = {
  periodLabel: string;
  summary: ReportSummary | null;
  certStats: ReportCertStats | null;
  jobsPerMonth: { month: string; jobs: number }[];
  hoursPerMonth: { month: string; hours: number }[];
  wageDistribution: { name: string; value: number }[];
  jobStatusDistribution: { name: string; value: number }[];
  userGrowth: { month: string; families: number; babysitters: number }[];
};

function money(n: number) {
  return n.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

/** Builds a multi-section PDF from the same aggregates shown on Reports & Analytics. */
export function buildReportsPdf(input: ReportsPdfInput): jsPDF {
  const doc = new jsPDF({ unit: "pt", format: "a4" });
  const margin = 40;
  let y = margin;

  doc.setFontSize(18);
  doc.text("Star Sitters — Reports & Analytics", margin, y);
  y += 22;
  doc.setFontSize(10);
  doc.setTextColor(80, 80, 80);
  doc.text(`Period: ${input.periodLabel}`, margin, y);
  doc.text(`Generated: ${new Date().toLocaleString()}`, margin + 220, y);
  doc.setTextColor(0, 0, 0);
  y += 28;

  const s = input.summary;
  autoTable(doc, {
    startY: y,
    head: [["Metric", "Value"]],
    body: [
      ["Total revenue (ledger)", s ? `$${money(s.total_revenue)}` : "—"],
      ["Completed jobs", s ? String(s.total_jobs) : "—"],
      ["Total hours (clocked)", s ? String(s.total_hours) : "—"],
      ["Avg job duration (h)", s ? String(s.avg_duration) : "—"],
      ["Window (months)", s ? String(s.window_months) : "—"],
    ],
    theme: "striped",
    styles: { fontSize: 9 },
    headStyles: { fillColor: [30, 41, 59] },
    margin: { left: margin, right: margin },
  });
  y = (doc as unknown as { lastAutoTable: { finalY: number } }).lastAutoTable.finalY + 18;

  autoTable(doc, {
    startY: y,
    head: [["Month", "Jobs"]],
    body: input.jobsPerMonth.map((r) => [r.month, String(r.jobs)]),
    theme: "striped",
    styles: { fontSize: 9 },
    headStyles: { fillColor: [30, 41, 59] },
    margin: { left: margin, right: margin },
  });
  y = (doc as unknown as { lastAutoTable: { finalY: number } }).lastAutoTable.finalY + 18;

  autoTable(doc, {
    startY: y,
    head: [["Month", "Hours"]],
    body: input.hoursPerMonth.map((r) => [r.month, String(r.hours)]),
    theme: "striped",
    styles: { fontSize: 9 },
    headStyles: { fillColor: [30, 41, 59] },
    margin: { left: margin, right: margin },
  });
  y = (doc as unknown as { lastAutoTable: { finalY: number } }).lastAutoTable.finalY + 18;

  if (y > doc.internal.pageSize.getHeight() - 80) {
    doc.addPage();
    y = margin;
  }

  autoTable(doc, {
    startY: y,
    head: [["Wage tier (12 mo)", "Earnings ($)"]],
    body:
      input.wageDistribution.length > 0
        ? input.wageDistribution.map((r) => [r.name, money(r.value)])
        : [["(no earnings)", "—"]],
    theme: "striped",
    styles: { fontSize: 9 },
    headStyles: { fillColor: [30, 41, 59] },
    margin: { left: margin, right: margin },
  });
  y = (doc as unknown as { lastAutoTable: { finalY: number } }).lastAutoTable.finalY + 18;

  autoTable(doc, {
    startY: y,
    head: [["Job status", "Count"]],
    body:
      input.jobStatusDistribution.length > 0
        ? input.jobStatusDistribution.map((r) => [r.name, String(r.value)])
        : [["(no jobs)", "—"]],
    theme: "striped",
    styles: { fontSize: 9 },
    headStyles: { fillColor: [30, 41, 59] },
    margin: { left: margin, right: margin },
  });
  y = (doc as unknown as { lastAutoTable: { finalY: number } }).lastAutoTable.finalY + 18;

  if (y > doc.internal.pageSize.getHeight() - 80) {
    doc.addPage();
    y = margin;
  }

  autoTable(doc, {
    startY: y,
    head: [["Month", "Families", "Babysitters"]],
    body: input.userGrowth.map((r) => [
      r.month,
      String(r.families),
      String(r.babysitters),
    ]),
    theme: "striped",
    styles: { fontSize: 9 },
    headStyles: { fillColor: [30, 41, 59] },
    margin: { left: margin, right: margin },
  });
  y = (doc as unknown as { lastAutoTable: { finalY: number } }).lastAutoTable.finalY + 18;

  const c = input.certStats;
  autoTable(doc, {
    startY: y,
    head: [["Certification stats", "Value"]],
    body: [
      ["Approval rate (%)", c ? String(c.approval_rate) : "—"],
      ["Avg processing (days)", c ? String(c.avg_processing_days) : "—"],
      ["Most popular course", c ? c.most_popular_course : "—"],
      ["Enrollments (top course)", c ? String(c.most_popular_enrollments) : "—"],
      ["Decided submissions", c ? String(c.decided_submissions) : "—"],
    ],
    theme: "striped",
    styles: { fontSize: 9 },
    headStyles: { fillColor: [30, 41, 59] },
    margin: { left: margin, right: margin },
  });

  return doc;
}

export function downloadReportsPdf(input: ReportsPdfInput, filename = "starsitters-reports.pdf") {
  buildReportsPdf(input).save(filename);
}
