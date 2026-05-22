"use client";

import React, { useEffect, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import {
  adminInsertCourse,
  adminUploadCourseMaterial,
  type AdminCourseInsert,
  fetchAdminCoursesWithStats,
  fetchDashboardStats,
} from "@/lib/supabase/admin";
import { formatSupabaseError } from "@/lib/supabase/errors";
import {
  ArrowLeft,
  ArrowRight,
  BookOpen,
  CheckCircle2,
  AlertCircle,
  Users,
  Check,
  ChevronDown,
  Save,
  Plus,
  FileText,
  Video,
  BookOpenCheck,
  X,
  HelpCircle,
  Eye,
} from "lucide-react";
import { Toast } from "@/components/ui/Toast";

type StepIndex = 1 | 2 | 3 | 4 | 5;

interface ModuleDraft {
  id: string;
  title: string;
  description: string;
}

type MaterialType = "PDF" | "VIDEO" | "DOCUMENT";

interface MaterialDraft {
  id: string;
  name: string;
  type: MaterialType;
  sizeMb: number;
}

interface QuestionDraft {
  id: string;
  question: string;
  options: string[];
  correctIndex: number;
}

const STEPS: { idx: StepIndex; title: string; subtitle: string }[] = [
  { idx: 1, title: "Basic Info", subtitle: "Course details" },
  { idx: 2, title: "Course Content", subtitle: "Add modules" },
  { idx: 3, title: "Materials", subtitle: "Upload resources" },
  { idx: 4, title: "Quiz", subtitle: "Add quiz questions" },
  { idx: 5, title: "Review & Publish", subtitle: "Final review" },
];

const LEVEL_OPTIONS = ["Beginner", "Intermediate", "Advanced"] as const;
type CourseLevel = (typeof LEVEL_OPTIONS)[number];

function parseDurationHoursValue(s: string): number {
  const m = String(s).trim().match(/(\d+(\.\d+)?)/);
  if (!m) return NaN;
  return parseFloat(m[1]);
}

function buildRequirementsFromMaterials(materials: MaterialDraft[]): string | null {
  if (materials.length === 0) return null;
  const lines = materials.map(
    (m) =>
      `- [${m.type}] ${m.name} (${m.sizeMb.toFixed(2)} MB; attach in storage when available)`,
  );
  return `Planned training materials:\n${lines.join("\n")}`;
}

function buildLearningObjectivesFromQuiz(
  passingScore: string,
  questions: QuestionDraft[],
): string {
  const passNum = parseFloat(passingScore);
  const passOk = Number.isFinite(passNum) ? Math.min(100, Math.max(0, Math.round(passNum))) : 80;
  let body = `Passing score: ${passOk}%`;
  if (questions.length === 0) {
    body += "\n\nQuiz: (no questions added yet.)";
    return body;
  }
  body += "\n\nQuiz outline:\n";
  questions.forEach((q, qi) => {
    body += `\n${qi + 1}. ${q.question}`;
    q.options.forEach((opt, oi) => {
      const letter = String.fromCharCode(65 + oi);
      const mark = oi === q.correctIndex ? " (correct)" : "";
      body += `\n   ${letter}. ${opt}${mark}`;
    });
  });
  return body;
}

export default function CreateCoursePage() {
  const router = useRouter();
  const [step, setStep] = useState<StepIndex>(1);
  const [statsLoading, setStatsLoading] = useState(true);
  const [statActive, setStatActive] = useState(0);
  const [statEnroll, setStatEnroll] = useState(0);
  const [statPending, setStatPending] = useState(0);
  const [statAvg, setStatAvg] = useState(0);
  const [publishBusy, setPublishBusy] = useState(false);
  const [publishError, setPublishError] = useState<string | null>(null);

  // Step 1 state
  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [category, setCategory] = useState("");
  const [duration, setDuration] = useState("4");
  const [price, setPrice] = useState("50");
  const [passingScore, setPassingScore] = useState("80");

  // Step 2 state
  const [modules, setModules] = useState<ModuleDraft[]>([]);
  const [moduleTitle, setModuleTitle] = useState("");
  const [moduleDescription, setModuleDescription] = useState("");

  // Step 3 state
  const [materials, setMaterials] = useState<MaterialDraft[]>([]);
  const [materialFileObjects, setMaterialFileObjects] = useState<Map<string, File>>(new Map());

  // Step 4 state
  const [questions, setQuestions] = useState<QuestionDraft[]>([]);
  const [questionText, setQuestionText] = useState("");
  const [options, setOptions] = useState(["", "", "", ""]);
  const [correctIndex, setCorrectIndex] = useState(0);

  // Step 5 state
  const [publishMode, setPublishMode] = useState<"draft" | "publish">("publish");
  const [showToast, setShowToast] = useState(false);
  const [level, setLevel] = useState<CourseLevel>("Beginner");
  const [instructor, setInstructor] = useState("");
  const [stepError, setStepError] = useState<string | null>(null);
  const [toastMessage, setToastMessage] = useState("");
  const [toastDescription, setToastDescription] = useState("");
  const materialFileInputRef = useRef<HTMLInputElement>(null);
  const pendingMaterialTypeRef = useRef<MaterialType | null>(null);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      setStatsLoading(true);
      try {
        const [rows, dash] = await Promise.all([
          fetchAdminCoursesWithStats(),
          fetchDashboardStats(),
        ]);
        if (cancelled) return;
        const active = rows.filter((r) => r.status === "published").length;
        const enroll = rows.reduce((s, r) => s + r.submissions_count, 0);
        const pending = dash.certs_pending;
        const withSub = rows.filter((r) => r.submissions_count > 0);
        const avg =
          withSub.length > 0
            ? Math.round(
                withSub.reduce((s, r) => s + Math.min(100, Math.round(r.completion_avg)), 0) /
                  withSub.length,
              )
            : 0;
        setStatActive(active);
        setStatEnroll(enroll);
        setStatPending(pending);
        setStatAvg(avg);
      } catch {
        if (!cancelled) {
          setStatActive(0);
          setStatEnroll(0);
          setStatPending(0);
          setStatAvg(0);
        }
      } finally {
        if (!cancelled) setStatsLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  useEffect(() => {
    setStepError(null);
  }, [step]);

  const progressPercent = (step / 5) * 100;

  const handleBack = () => router.push("/courses");
  const handlePrevious = () => {
    if (step > 1) setStep((step - 1) as StepIndex);
  };

  const validateStepForNext = (s: StepIndex): string | null => {
    switch (s) {
      case 1: {
        if (title.trim().length < 5) return "Title must be at least 5 characters.";
        if (description.trim().length < 10)
          return "Description should be at least 10 characters.";
        if (!category.trim()) return "Select a category.";
        const hrs = parseDurationHoursValue(duration);
        if (!Number.isFinite(hrs) || hrs <= 0) return "Enter a duration greater than 0 hours.";
        const pri = parseFloat(price);
        if (!Number.isFinite(pri) || pri < 0) return "Enter a valid price (0 or more).";
        return null;
      }
      case 2:
        if (modules.length < 1) return "Add at least one module before continuing.";
        return null;
      case 3:
      case 4:
      default:
        return null;
    }
  };

  const handleNext = () => {
    setPublishError(null);
    const err = validateStepForNext(step);
    if (err) {
      setStepError(err);
      return;
    }
    setStepError(null);
    if (step < 5) setStep((step + 1) as StepIndex);
  };

  const handleAddModule = () => {
    if (!moduleTitle.trim()) return;
    setModules((prev) => [
      ...prev,
      {
        id: `M${Date.now()}`,
        title: moduleTitle.trim(),
        description: moduleDescription.trim(),
      },
    ]);
    setModuleTitle("");
    setModuleDescription("");
  };

  const handleRemoveModule = (id: string) => {
    setModules((prev) => prev.filter((m) => m.id !== id));
  };

  const openMaterialPicker = (type: MaterialType) => {
    pendingMaterialTypeRef.current = type;
    const inp = materialFileInputRef.current;
    if (!inp) return;
    inp.accept =
      type === "PDF"
        ? ".pdf,application/pdf"
        : type === "VIDEO"
          ? "video/*"
          : ".doc,.docx,.txt,.md,.pdf,application/msword";
    inp.click();
  };

  const handleMaterialFileChange: React.ChangeEventHandler<HTMLInputElement> = (e) => {
    const file = e.target.files?.[0];
    const type = pendingMaterialTypeRef.current;
    e.target.value = "";
    pendingMaterialTypeRef.current = null;
    if (!file || !type) return;
    const sizeMb = Math.round((file.size / (1024 * 1024)) * 100) / 100;
    const id = `MAT-${Date.now()}`;
    setMaterials((prev) => [
      ...prev,
      { id, name: file.name, type, sizeMb: Math.max(sizeMb, 0.01) },
    ]);
    setMaterialFileObjects((prev) => {
      const next = new Map(prev);
      next.set(id, file);
      return next;
    });
  };

  const handleRemoveMaterial = (id: string) => {
    setMaterials((prev) => prev.filter((m) => m.id !== id));
    setMaterialFileObjects((prev) => {
      const next = new Map(prev);
      next.delete(id);
      return next;
    });
  };

  const handleAddQuestion = () => {
    if (!questionText.trim()) return;
    const pairs = options
      .map((o, origIndex) => ({ text: o.trim(), origIndex }))
      .filter((p) => p.text.length > 0);
    if (pairs.length < 2) return;
    let newCorrect = 0;
    const hit = pairs.findIndex((p) => p.origIndex === correctIndex);
    newCorrect = hit >= 0 ? hit : 0;
    setQuestions((prev) => [
      ...prev,
      {
        id: `Q${Date.now()}`,
        question: questionText.trim(),
        options: pairs.map((p) => p.text),
        correctIndex: newCorrect,
      },
    ]);
    setQuestionText("");
    setOptions(["", "", "", ""]);
    setCorrectIndex(0);
  };

  const persistCourse = async (intent: "draft" | "publish") => {
    setPublishError(null);
    setStepError(null);

    const t = title.trim();
    if (t.length < 5) {
      setPublishError("Course title must be at least 5 characters.");
      return;
    }
    if (!category.trim()) {
      setPublishError("Please select a category.");
      return;
    }

    const descMin = intent === "publish" ? 20 : 10;
    if (description.trim().length < descMin) {
      setPublishError(
        intent === "publish"
          ? "Description should be at least 20 characters before publishing."
          : "Description should be at least 10 characters to save a draft.",
      );
      return;
    }

    const hrs = parseDurationHoursValue(duration);
    if (!Number.isFinite(hrs) || hrs <= 0) {
      setPublishError("Enter a valid duration greater than 0.");
      return;
    }

    const pri = parseFloat(price);
    if (!Number.isFinite(pri) || pri < 0) {
      setPublishError("Enter a valid price (0 or more).");
      return;
    }

    if (intent === "publish") {
      if (modules.length < 1) {
        setPublishError("Add at least one module before publishing.");
        return;
      }
      if (questions.length < 1) {
        setPublishError("Add at least one quiz question before publishing.");
        return;
      }
    }

    const modTitles =
      modules.length > 0
        ? modules.map((m, idx) => (m.title.trim() ? m.title.trim() : `Module ${idx + 1}`))
        : ["Module 1"];

    const levelDb: AdminCourseInsert["level"] =
      level === "Intermediate" || level === "Advanced" ? level : "Beginner";

    setPublishBusy(true);
    try {
      const courseId = await adminInsertCourse({
        name: t,
        category: category.trim(),
        status: intent === "publish" ? "published" : "draft",
        description: description.trim() || null,
        modules: modTitles,
        instructor: instructor.trim() || "Star Sitters",
        duration_hours: hrs,
        level: levelDb,
        price: pri,
        requirements: buildRequirementsFromMaterials(materials),
        learning_objectives: buildLearningObjectivesFromQuiz(passingScore, questions),
        provides_certificate: true,
        material_paths: [],
      });

      // Upload course material files and patch material_paths
      if (materialFileObjects.size > 0) {
        const uploadResults = await Promise.allSettled(
          materials
            .filter((m) => materialFileObjects.has(m.id))
            .map((m) => adminUploadCourseMaterial(courseId, materialFileObjects.get(m.id)!))
        );
        const paths = uploadResults
          .filter((r): r is PromiseFulfilledResult<string> => r.status === "fulfilled")
          .map((r) => r.value);
        if (paths.length > 0) {
          const { createClient } = await import("@/lib/supabase/client");
          const supabase = createClient();
          await supabase.from("courses").update({ material_paths: paths }).eq("id", courseId);
        }
      }
      if (intent === "publish") {
        setToastMessage("Course published successfully!");
        setToastDescription("The course is now available for enrollment.");
      } else {
        setToastMessage("Draft saved successfully!");
        setToastDescription(
          "You can finish editing or publish the course from Course Management.",
        );
      }
      setShowToast(true);
      setTimeout(() => router.push("/courses"), 1200);
    } catch (e) {
      setPublishError(formatSupabaseError(e));
    } finally {
      setPublishBusy(false);
    }
  };

  const handleSaveDraft = () => {
    void persistCourse("draft");
  };

  const handleFinalizeStep5 = () => {
    void persistCourse(publishMode === "publish" ? "publish" : "draft");
  };

  return (
    <div className="space-y-6">
      {/* Back + page header */}
      <div>
        <button
          onClick={handleBack}
          className="inline-flex items-center gap-2 text-[15px] text-white hover:text-[#b8e0f0] transition-colors mb-4"
        >
          <ArrowLeft className="w-4 h-4" strokeWidth={2} />
          Back
        </button>
        <h1 className="text-[32px] leading-[40px] font-bold text-white">
          Create New Course
        </h1>
        <p className="mt-1 text-[15px] text-[#94a3b8]">
          Set up a new training course or certification program
        </p>
        {publishError && (
          <p className="mt-2 text-[13px] text-red-400" role="alert">
            {publishError}
          </p>
        )}
        {stepError && (
          <p className="mt-2 text-[13px] text-amber-400" role="status">
            {stepError}
          </p>
        )}
      </div>

      {/* Stat cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard
          label="Active Courses"
          value={statsLoading ? "—" : String(statActive)}
          valueColor="text-white"
          icon={BookOpen}
          iconColor="text-[#cbd5e1]"
        />
        <StatCard
          label="Total Enrollments"
          value={statsLoading ? "—" : String(statEnroll)}
          valueColor="text-[#34d399]"
          icon={Users}
          iconColor="text-[#34d399]"
        />
        <StatCard
          label="Pending certifications"
          value={statsLoading ? "—" : String(statPending)}
          valueColor="text-[#c4b5fd]"
          icon={AlertCircle}
          iconColor="text-[#c4b5fd]"
        />
        <StatCard
          label="Avg completion (courses w/ subs)"
          value={statsLoading ? "—" : `${statAvg}%`}
          valueColor="text-[#34d399]"
          icon={CheckCircle2}
          iconColor="text-[#34d399]"
        />
      </div>

      {/* Step progress */}
      <section className="bg-[#1e293b]/60 backdrop-blur-md border border-white/10 rounded-2xl p-6 shadow-[0_24px_60px_-30px_rgba(0,0,0,0.6)]">
        <div className="flex items-center justify-between mb-3">
          <p className="text-[15px] font-medium text-white">Step {step} of 5</p>
          <p className="text-[14px] text-[#94a3b8]">
            {Math.round(progressPercent)}% Complete
          </p>
        </div>
        <div className="h-1.5 bg-[#0f172a]/60 rounded-full overflow-hidden mb-7">
          <div
            className="h-full bg-[#b8e0f0] transition-all duration-300"
            style={{ width: `${progressPercent}%` }}
          />
        </div>

        <div className="grid grid-cols-5 gap-2">
          {STEPS.map((s) => {
            const isCompleted = s.idx < step;
            const isActive = s.idx === step;
            return (
              <div key={s.idx} className="flex flex-col items-center text-center">
                <div
                  className={`w-10 h-10 rounded-full flex items-center justify-center font-semibold text-[14px] mb-2 ${
                    isCompleted
                      ? "bg-[#86efac]/20 border border-[#86efac]/40 text-[#86efac]"
                      : isActive
                      ? "bg-[#b8e0f0] text-[#0a0f24]"
                      : "bg-[#334155]/60 border border-[#334155] text-[#64748b]"
                  }`}
                >
                  {isCompleted ? (
                    <Check className="w-5 h-5" strokeWidth={2.5} />
                  ) : (
                    s.idx
                  )}
                </div>
                <p
                  className={`text-[13px] font-medium ${
                    isCompleted || isActive ? "text-white" : "text-[#64748b]"
                  }`}
                >
                  {s.title}
                </p>
                <p
                  className={`text-[12px] mt-0.5 ${
                    isCompleted || isActive ? "text-[#94a3b8]" : "text-[#64748b]"
                  }`}
                >
                  {s.subtitle}
                </p>
              </div>
            );
          })}
        </div>
      </section>

      {/* Step content card */}
      <section className="bg-[#1e293b]/60 backdrop-blur-md border border-white/10 rounded-2xl p-6 shadow-[0_24px_60px_-30px_rgba(0,0,0,0.6)]">
        <input
          ref={materialFileInputRef}
          type="file"
          className="hidden"
          aria-hidden
          onChange={handleMaterialFileChange}
        />

        {step === 1 && (
          <Step1
            title={title}
            description={description}
            category={category}
            level={level}
            instructor={instructor}
            duration={duration}
            price={price}
            passingScore={passingScore}
            onChange={{
              title: setTitle,
              description: setDescription,
              category: setCategory,
              level: setLevel,
              instructor: setInstructor,
              duration: setDuration,
              price: setPrice,
              passingScore: setPassingScore,
            }}
          />
        )}

        {step === 2 && (
          <Step2
            modules={modules}
            moduleTitle={moduleTitle}
            moduleDescription={moduleDescription}
            onModuleTitle={setModuleTitle}
            onModuleDescription={setModuleDescription}
            onAdd={handleAddModule}
            onRemoveModule={handleRemoveModule}
          />
        )}

        {step === 3 && (
          <Step3
            materials={materials}
            onPickMaterial={openMaterialPicker}
            onRemove={handleRemoveMaterial}
          />
        )}

        {step === 4 && (
          <Step4
            questions={questions}
            questionText={questionText}
            options={options}
            correctIndex={correctIndex}
            onQuestionText={setQuestionText}
            onOptionChange={(i, val) =>
              setOptions((prev) => prev.map((o, idx) => (idx === i ? val : o)))
            }
            onCorrectIndex={setCorrectIndex}
            onAdd={handleAddQuestion}
          />
        )}

        {step === 5 && (
          <Step5
            data={{
              title: title || "New Course",
              description: description || "Enter course detail",
              category: category || "Education",
              level,
              instructor: instructor.trim() || "Star Sitters",
              duration,
              price,
              passingScore,
              modules,
              materials,
              questions,
            }}
            publishMode={publishMode}
            onPublishMode={setPublishMode}
          />
        )}

        {/* Footer */}
        <div className="mt-8 pt-6 border-t border-[#334155]/40 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
          <button
            onClick={handlePrevious}
            disabled={step === 1}
            className="inline-flex items-center justify-center gap-2 h-[44px] px-5 bg-transparent border border-white/15 text-white text-[14px] font-medium rounded-[10px] hover:bg-white/5 transition-all disabled:opacity-40 disabled:cursor-not-allowed"
          >
            <ArrowLeft className="w-4 h-4" strokeWidth={2} />
            Previous
          </button>

          <div className="flex flex-col sm:flex-row gap-3">
            <button
              type="button"
              disabled={publishBusy}
              onClick={handleSaveDraft}
              className="inline-flex items-center justify-center gap-2 h-[44px] px-5 bg-transparent border border-white/15 text-white text-[14px] font-medium rounded-[10px] hover:bg-white/5 transition-all disabled:opacity-50"
            >
              <Save className="w-4 h-4" strokeWidth={1.75} />
              Save Draft
            </button>

            {step < 5 ? (
              <button
                type="button"
                onClick={handleNext}
                className="inline-flex items-center justify-center gap-2 h-[44px] px-5 bg-[#b8e0f0] hover:bg-[#c8e8f5] text-[#0a0f24] text-[14px] font-semibold rounded-[10px] transition-all"
              >
                Next Step
                <ArrowRight className="w-4 h-4" strokeWidth={2.25} />
              </button>
            ) : (
              <button
                type="button"
                disabled={publishBusy}
                onClick={handleFinalizeStep5}
                className="inline-flex items-center justify-center gap-2 h-[44px] px-5 bg-[#22c55e] hover:bg-[#16a34a] disabled:opacity-50 text-white text-[14px] font-semibold rounded-[10px] transition-all"
              >
                <Check className="w-4 h-4" strokeWidth={2.5} />
                {publishBusy ? "Saving…" : publishMode === "publish" ? "Publish Course" : "Save Draft"}
              </button>
            )}
          </div>
        </div>
      </section>

      <Toast
        show={showToast}
        message={toastMessage || "Saved."}
        description={toastDescription}
        onClose={() => setShowToast(false)}
        duration={1800}
      />
    </div>
  );
}

function StatCard({
  label,
  value,
  valueColor,
  icon: Icon,
  iconColor,
}: {
  label: string;
  value: string;
  valueColor: string;
  icon: React.ComponentType<{ className?: string; strokeWidth?: number }>;
  iconColor: string;
}) {
  return (
    <div className="bg-[#1e293b]/60 backdrop-blur-md border border-white/10 rounded-2xl p-5 shadow-[0_24px_60px_-30px_rgba(0,0,0,0.6)]">
      <div className="flex items-start justify-between gap-3">
        <p className="text-[13px] leading-[18px] font-medium text-[#94a3b8]">
          {label}
        </p>
        <Icon className={`w-5 h-5 ${iconColor}`} strokeWidth={1.75} />
      </div>
      <p className={`mt-3 text-[28px] leading-[36px] font-bold ${valueColor}`}>
        {value}
      </p>
    </div>
  );
}

/* ---------------------------- Step 1 ---------------------------- */

function Step1({
  title,
  description,
  category,
  level,
  instructor,
  duration,
  price,
  passingScore,
  onChange,
}: {
  title: string;
  description: string;
  category: string;
  level: CourseLevel;
  instructor: string;
  duration: string;
  price: string;
  passingScore: string;
  onChange: {
    title: (v: string) => void;
    description: (v: string) => void;
    category: (v: string) => void;
    level: (v: CourseLevel) => void;
    instructor: (v: string) => void;
    duration: (v: string) => void;
    price: (v: string) => void;
    passingScore: (v: string) => void;
  };
}) {
  return (
    <div>
      <h2 className="text-[18px] leading-[26px] font-semibold text-white">
        Basic Information
      </h2>
      <p className="mt-1 text-[14px] text-[#94a3b8] mb-6">
        Enter the fundamental details about your course
      </p>

      <FieldLabel label="Course Title" required>
        <input
          value={title}
          onChange={(e) => onChange.title(e.target.value)}
          placeholder="e.g., CPR & First Aid Certification"
          className={inputClass}
        />
      </FieldLabel>

      <div className="mt-5">
        <FieldLabel label="Course Description" required>
          <textarea
            value={description}
            onChange={(e) => onChange.description(e.target.value)}
            placeholder="Provide a detailed description of what this course covers..."
            rows={4}
            className={`${inputClass} resize-none py-3`}
          />
        </FieldLabel>
        <p className="mt-2 text-[12px] text-[#64748b]">
          This will be visible to babysitters when browsing courses
        </p>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mt-5">
        <FieldLabel label="Category" required>
          <div className="relative">
            <select
              value={category}
              onChange={(e) => onChange.category(e.target.value)}
              className={`${inputClass} appearance-none pr-10`}
            >
              <option value="">Select category</option>
              <option value="Safety">Safety</option>
              <option value="Child Care">Child Care</option>
              <option value="Behavioral">Behavioral</option>
              <option value="Health">Health</option>
              <option value="Education">Education</option>
            </select>
            <ChevronDown className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-[#64748b] pointer-events-none" />
          </div>
        </FieldLabel>

        <FieldLabel label="Level">
          <div className="relative">
            <select
              value={level}
              onChange={(e) => onChange.level(e.target.value as CourseLevel)}
              className={`${inputClass} appearance-none pr-10`}
            >
              {LEVEL_OPTIONS.map((opt) => (
                <option key={opt} value={opt}>
                  {opt}
                </option>
              ))}
            </select>
            <ChevronDown className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-[#64748b] pointer-events-none" />
          </div>
        </FieldLabel>

        <FieldLabel label="Instructor (optional)">
          <input
            value={instructor}
            onChange={(e) => onChange.instructor(e.target.value)}
            placeholder="Defaults to Star Sitters if empty"
            className={inputClass}
          />
        </FieldLabel>

        <FieldLabel label="Duration (hours)" required>
          <input
            type="number"
            value={duration}
            onChange={(e) => onChange.duration(e.target.value)}
            className={inputClass}
          />
        </FieldLabel>

        <FieldLabel label="Set Price" required>
          <div className="relative">
            <span className="absolute left-4 top-1/2 -translate-y-1/2 text-[14px] text-[#64748b]">
              $
            </span>
            <input
              type="number"
              value={price}
              onChange={(e) => onChange.price(e.target.value)}
              className={`${inputClass} pl-8`}
            />
          </div>
        </FieldLabel>
      </div>

      <div className="mt-5">
        <FieldLabel label="Passing Score (%)">
          <input
            type="number"
            value={passingScore}
            onChange={(e) => onChange.passingScore(e.target.value)}
            className={inputClass}
          />
        </FieldLabel>
        <p className="mt-2 text-[12px] text-[#64748b]">
          Minimum score required to pass this course
        </p>
      </div>
    </div>
  );
}

/* ---------------------------- Step 2 ---------------------------- */

function Step2({
  modules,
  moduleTitle,
  moduleDescription,
  onModuleTitle,
  onModuleDescription,
  onAdd,
  onRemoveModule,
}: {
  modules: ModuleDraft[];
  moduleTitle: string;
  moduleDescription: string;
  onModuleTitle: (v: string) => void;
  onModuleDescription: (v: string) => void;
  onAdd: () => void;
  onRemoveModule: (id: string) => void;
}) {
  return (
    <div>
      <h2 className="text-[18px] leading-[26px] font-semibold text-white">
        Course Content
      </h2>
      <p className="mt-1 text-[14px] text-[#94a3b8] mb-6">
        Add modules and learning materials for your course
      </p>

      <div className="bg-[#0f172a]/60 border border-white/10 rounded-[12px] p-5">
        <div className="flex items-center gap-2 text-white mb-4">
          <Plus className="w-4 h-4" strokeWidth={2} />
          <span className="text-[15px] font-medium">Add New Module</span>
        </div>

        <FieldLabel label="Module Title">
          <input
            value={moduleTitle}
            onChange={(e) => onModuleTitle(e.target.value)}
            placeholder="e.g., Introduction to CPR"
            className={inputClass}
          />
        </FieldLabel>

        <div className="mt-4">
          <FieldLabel label="Module Description">
            <textarea
              value={moduleDescription}
              onChange={(e) => onModuleDescription(e.target.value)}
              placeholder="Brief description of this module..."
              rows={3}
              className={`${inputClass} resize-none py-3`}
            />
          </FieldLabel>
        </div>

        <button
          onClick={onAdd}
          className="mt-5 w-full inline-flex items-center justify-center gap-2 h-[44px] bg-[#b8e0f0]/30 hover:bg-[#b8e0f0]/50 border border-[#b8e0f0]/40 text-white text-[14px] font-medium rounded-[10px] transition-all"
        >
          <Plus className="w-4 h-4" strokeWidth={2} />
          Add Module
        </button>
      </div>

      {modules.length === 0 ? (
        <div className="mt-8 flex flex-col items-center text-center py-10">
          <div className="w-12 h-12 rounded-full border-2 border-[#334155] flex items-center justify-center mb-4">
            <AlertCircle className="w-6 h-6 text-[#64748b]" strokeWidth={1.75} />
          </div>
          <p className="text-[14px] text-[#94a3b8]">
            No modules added yet. Add at least one module to continue.
          </p>
        </div>
      ) : (
        <div className="mt-6 space-y-3">
          {modules.map((m, idx) => (
            <div
              key={m.id}
              className="bg-[#0f172a]/60 border border-white/10 rounded-[12px] px-5 py-4 flex gap-3 items-start"
            >
              <div className="min-w-0 flex-1">
                <p className="text-[14px] font-semibold text-white">
                  Module {idx + 1}: {m.title}
                </p>
                {m.description && (
                  <p className="mt-1 text-[13px] text-[#94a3b8]">
                    {m.description}
                  </p>
                )}
              </div>
              <button
                type="button"
                onClick={() => onRemoveModule(m.id)}
                aria-label={`Remove module ${idx + 1}`}
                className="p-1.5 text-[#ef4444] hover:text-[#dc2626] transition-colors flex-shrink-0"
              >
                <X className="w-4 h-4" strokeWidth={2} />
              </button>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

/* ---------------------------- Step 3 ---------------------------- */

function Step3({
  materials,
  onPickMaterial,
  onRemove,
}: {
  materials: MaterialDraft[];
  onPickMaterial: (type: MaterialType) => void;
  onRemove: (id: string) => void;
}) {
  return (
    <div>
      <h2 className="text-[18px] leading-[26px] font-semibold text-white">
        Training Materials
      </h2>
      <p className="mt-1 text-[14px] text-[#94a3b8] mb-6">
        Upload documents, videos, and other learning resources (Optional)
      </p>

      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <UploadCard
          icon={FileText}
          title="Upload PDF"
          subtitle="Documents & Guides"
          onClick={() => onPickMaterial("PDF")}
        />
        <UploadCard
          icon={Video}
          title="Upload Video"
          subtitle="Training Videos"
          onClick={() => onPickMaterial("VIDEO")}
        />
        <UploadCard
          icon={BookOpenCheck}
          title="Upload Document"
          subtitle="Study Materials"
          onClick={() => onPickMaterial("DOCUMENT")}
        />
      </div>

      {materials.length > 0 && (
        <div className="mt-7">
          <p className="text-[15px] font-medium text-white mb-3">
            Uploaded Materials ({materials.length})
          </p>
          <div className="space-y-3">
            {materials.map((m) => (
              <MaterialRow key={m.id} material={m} onRemove={onRemove} />
            ))}
          </div>
        </div>
      )}
    </div>
  );
}

function UploadCard({
  icon: Icon,
  title,
  subtitle,
  onClick,
}: {
  icon: React.ComponentType<{ className?: string; strokeWidth?: number }>;
  title: string;
  subtitle: string;
  onClick: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className="bg-[#0f172a]/40 border border-dashed border-white/15 rounded-[12px] p-6 flex flex-col items-center text-center hover:bg-[#0f172a]/70 hover:border-[#b8e0f0]/40 transition-all"
    >
      <Icon className="w-8 h-8 text-[#94a3b8] mb-3" strokeWidth={1.5} />
      <p className="text-[15px] font-medium text-white">{title}</p>
      <p className="mt-1 text-[12px] text-[#64748b]">{subtitle}</p>
    </button>
  );
}

function MaterialRow({
  material,
  onRemove,
}: {
  material: MaterialDraft;
  onRemove: (id: string) => void;
}) {
  const isPdf = material.type === "PDF";
  const isVideo = material.type === "VIDEO";
  const Icon = isVideo ? Video : isPdf ? FileText : BookOpenCheck;
  const iconColor = isVideo
    ? "text-[#c4b5fd]"
    : isPdf
    ? "text-[#60a5fa]"
    : "text-[#86efac]";

  return (
    <div className="bg-[#0f172a]/60 border border-white/10 rounded-[12px] px-5 py-3.5 flex items-center gap-3">
      <Icon className={`w-5 h-5 ${iconColor} flex-shrink-0`} strokeWidth={1.75} />
      <div className="min-w-0 flex-1">
        <p className="text-[14px] font-medium text-white truncate">
          {material.name}
        </p>
        <p className="text-[12px] text-[#64748b]">
          {material.type} • {material.sizeMb} MB
        </p>
      </div>
      <button
        onClick={() => onRemove(material.id)}
        aria-label="Remove material"
        className="p-1 text-[#ef4444] hover:text-[#dc2626] transition-colors"
      >
        <X className="w-4 h-4" strokeWidth={2} />
      </button>
    </div>
  );
}

/* ---------------------------- Step 4 ---------------------------- */

function Step4({
  questions,
  questionText,
  options,
  correctIndex,
  onQuestionText,
  onOptionChange,
  onCorrectIndex,
  onAdd,
}: {
  questions: QuestionDraft[];
  questionText: string;
  options: string[];
  correctIndex: number;
  onQuestionText: (v: string) => void;
  onOptionChange: (i: number, v: string) => void;
  onCorrectIndex: (i: number) => void;
  onAdd: () => void;
}) {
  return (
    <div>
      <h2 className="text-[18px] leading-[26px] font-semibold text-white">
        Quiz Questions
      </h2>
      <p className="mt-1 text-[14px] text-[#94a3b8] mb-6">
        Add quiz questions to test babysitters&apos; understanding of the course
        material
      </p>

      <div className="bg-[#0f172a]/60 border border-white/10 rounded-[12px] p-5">
        <div className="flex items-center gap-2 text-white mb-4">
          <Plus className="w-4 h-4" strokeWidth={2} />
          <span className="text-[15px] font-medium">Add New Question</span>
        </div>

        <FieldLabel label="Question">
          <textarea
            value={questionText}
            onChange={(e) => onQuestionText(e.target.value)}
            placeholder="e.g., What is the first step in performing CPR on an infant?"
            rows={3}
            className={`${inputClass} resize-none py-3`}
          />
        </FieldLabel>

        <div className="mt-5">
          <p className="text-[14px] font-medium text-white mb-3">
            Answer Options{" "}
            <span className="text-[13px] font-normal text-[#94a3b8]">
              (Select the correct answer)
            </span>
          </p>
          <div className="space-y-2.5">
            {options.map((opt, idx) => {
              const isCorrect = idx === correctIndex;
              return (
                <div key={idx} className="flex items-center gap-3">
                  <button
                    type="button"
                    onClick={() => onCorrectIndex(idx)}
                    aria-label={`Mark option ${idx + 1} as correct`}
                    className={`w-5 h-5 rounded-full flex items-center justify-center flex-shrink-0 transition-all ${
                      isCorrect
                        ? "bg-[#22c55e] border-2 border-[#22c55e]"
                        : "bg-transparent border-2 border-[#475569]"
                    }`}
                  >
                    {isCorrect && (
                      <span className="w-2 h-2 rounded-full bg-white" />
                    )}
                  </button>
                  <input
                    value={opt}
                    onChange={(e) => onOptionChange(idx, e.target.value)}
                    placeholder={`Option ${idx + 1}`}
                    className={`${inputClass} ${
                      isCorrect
                        ? "border-[#22c55e]/60 focus:border-[#22c55e]"
                        : ""
                    }`}
                  />
                  {isCorrect && (
                    <span className="inline-flex items-center px-2.5 py-1 rounded-md bg-[#86efac]/15 border border-[#86efac]/30 text-[#86efac] text-[12px] font-medium flex-shrink-0">
                      Correct
                    </span>
                  )}
                </div>
              );
            })}
          </div>
          <p className="mt-3 text-[12px] text-[#64748b]">
            Select the radio button to mark the correct answer. Leave empty
            options blank.
          </p>
        </div>

        <button
          onClick={onAdd}
          className="mt-5 w-full inline-flex items-center justify-center gap-2 h-[44px] bg-[#b8e0f0]/30 hover:bg-[#b8e0f0]/50 border border-[#b8e0f0]/40 text-white text-[14px] font-medium rounded-[10px] transition-all"
        >
          <Plus className="w-4 h-4" strokeWidth={2} />
          Add Question
        </button>
      </div>

      {questions.length === 0 ? (
        <div className="mt-8 flex flex-col items-center text-center py-10">
          <div className="w-12 h-12 rounded-full border-2 border-[#334155] flex items-center justify-center mb-4">
            <HelpCircle className="w-6 h-6 text-[#64748b]" strokeWidth={1.75} />
          </div>
          <p className="text-[14px] text-[#94a3b8]">
            No quiz questions added yet. Add at least one question to continue.
          </p>
        </div>
      ) : (
        <div className="mt-6 space-y-3">
          {questions.map((q, idx) => (
            <div
              key={q.id}
              className="bg-[#0f172a]/60 border border-white/10 rounded-[12px] px-5 py-4"
            >
              <p className="text-[14px] font-semibold text-white">
                Q{idx + 1}: {q.question}
              </p>
              <ul className="mt-2 space-y-1">
                {q.options.map((opt, i) =>
                  opt.trim() === "" ? null : (
                    <li
                      key={i}
                      className={`text-[13px] flex items-center gap-2 ${
                        i === q.correctIndex ? "text-[#86efac]" : "text-[#94a3b8]"
                      }`}
                    >
                      <span className="font-semibold">
                        {String.fromCharCode(65 + i)}.
                      </span>
                      {opt}
                      {i === q.correctIndex && (
                        <Check className="w-3.5 h-3.5" strokeWidth={2.5} />
                      )}
                    </li>
                  ),
                )}
              </ul>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

/* ---------------------------- Step 5 ---------------------------- */

interface ReviewData {
  title: string;
  description: string;
  category: string;
  level: CourseLevel;
  instructor: string;
  duration: string;
  price: string;
  passingScore: string;
  modules: ModuleDraft[];
  materials: MaterialDraft[];
  questions: QuestionDraft[];
}

function Step5({
  data,
  publishMode,
  onPublishMode,
}: {
  data: ReviewData;
  publishMode: "draft" | "publish";
  onPublishMode: (m: "draft" | "publish") => void;
}) {
  return (
    <div>
      <h2 className="text-[18px] leading-[26px] font-semibold text-white">
        Review Course
      </h2>
      <p className="mt-1 text-[14px] text-[#94a3b8] mb-6">
        Review all course details before publishing
      </p>

      {/* 1. Basic Information */}
      <ReviewSection number={1} title="Basic Information">
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-x-6 gap-y-4">
          <ReviewField label="Course Title" value={data.title} />
          <ReviewField label="Category" value={data.category} />
          <ReviewField label="Level" value={data.level} />
          <ReviewField label="Instructor" value={data.instructor} />
          <ReviewField label="Duration" value={`${data.duration} hours`} />
          <ReviewField label="Price" value={`$${data.price}`} />
          <ReviewField label="Passing Score" value={`${data.passingScore}%`} />
        </div>
        <div className="mt-4">
          <ReviewField label="Description" value={data.description} />
        </div>
      </ReviewSection>

      {/* 2. Course Modules */}
      <ReviewSection number={2} title="Course Modules">
        {data.modules.length === 0 ? (
          <p className="text-[14px] text-[#64748b] italic">No modules added.</p>
        ) : (
          <div className="space-y-2">
            {data.modules.map((m, idx) => (
              <div
                key={m.id}
                className="bg-[#0f172a]/40 border border-white/5 rounded-[10px] px-4 py-3"
              >
                <p className="text-[14px] font-medium text-white">
                  Module {idx + 1}: {m.title}
                </p>
                {m.description && (
                  <p className="mt-0.5 text-[13px] text-[#94a3b8]">
                    {m.description}
                  </p>
                )}
              </div>
            ))}
          </div>
        )}
      </ReviewSection>

      {/* 3. Training Materials */}
      <ReviewSection number={3} title="Training Materials">
        {data.materials.length === 0 ? (
          <p className="text-[14px] text-[#64748b] italic">
            No materials uploaded.
          </p>
        ) : (
          <ul className="space-y-1.5">
            {data.materials.map((m) => (
              <li key={m.id} className="flex items-center gap-2.5 text-[14px]">
                <span className="inline-flex items-center px-2 py-0.5 rounded-md bg-white/5 border border-white/10 text-[#cbd5e1] text-[11px] font-medium uppercase">
                  {m.type === "VIDEO" ? "video" : m.type === "PDF" ? "pdf" : "doc"}
                </span>
                <span className="text-white">{m.name}</span>
                <span className="text-[#64748b]">({m.sizeMb} MB)</span>
              </li>
            ))}
          </ul>
        )}
      </ReviewSection>

      {/* 4. Quiz Questions */}
      <ReviewSection number={4} title="Quiz Questions">
        <p className="text-[13px] text-[#94a3b8] mb-3">
          Total Questions: {data.questions.length}
        </p>
        {data.questions.length === 0 ? (
          <p className="text-[14px] text-[#64748b] italic">
            No questions added.
          </p>
        ) : (
          <div className="space-y-3">
            {data.questions.map((q, idx) => (
              <div key={q.id}>
                <p className="text-[14px] font-medium text-white mb-1.5">
                  Q{idx + 1}: {q.question}
                </p>
                <ul className="space-y-1 ml-4">
                  {q.options.map((opt, i) =>
                    opt.trim() === "" ? null : (
                      <li
                        key={i}
                        className={`text-[13px] flex items-center gap-2 ${
                          i === q.correctIndex ? "text-[#86efac]" : "text-[#94a3b8]"
                        }`}
                      >
                        <span className="font-semibold">
                          {String.fromCharCode(65 + i)}.
                        </span>
                        {opt}
                        {i === q.correctIndex && (
                          <Check className="w-3.5 h-3.5" strokeWidth={2.5} />
                        )}
                      </li>
                    ),
                  )}
                </ul>
              </div>
            ))}
          </div>
        )}
      </ReviewSection>

      {/* Ready to Publish? */}
      <div className="mt-8 bg-[#0f172a]/60 border border-white/10 rounded-[12px] p-5">
        <p className="text-[15px] font-semibold text-white">Ready to Publish?</p>
        <p className="mt-1 text-[13px] text-[#94a3b8] mb-4">
          Choose how you want to proceed with this course
        </p>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <PublishOptionCard
            icon={Save}
            title="Save as Draft"
            description="Save your progress and continue editing later. The course won't be visible to users."
            selected={publishMode === "draft"}
            onClick={() => onPublishMode("draft")}
          />
          <PublishOptionCard
            icon={Eye}
            title="Publish Course"
            description="Make the course available for babysitters to enroll and start learning immediately."
            selected={publishMode === "publish"}
            onClick={() => onPublishMode("publish")}
          />
        </div>
      </div>
    </div>
  );
}

function ReviewSection({
  number,
  title,
  children,
}: {
  number: number;
  title: string;
  children: React.ReactNode;
}) {
  return (
    <div className="mt-6 first:mt-0">
      <div className="flex items-center gap-3 mb-3">
        <span className="w-7 h-7 rounded-full bg-[#334155]/70 border border-white/10 flex items-center justify-center text-[12px] font-semibold text-white">
          {number}
        </span>
        <h3 className="text-[16px] font-semibold text-white">{title}</h3>
      </div>
      <div className="ml-10">{children}</div>
    </div>
  );
}

function ReviewField({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <p className="text-[13px] text-[#94a3b8]">{label}</p>
      <p className="mt-0.5 text-[14px] text-white">{value}</p>
    </div>
  );
}

function PublishOptionCard({
  icon: Icon,
  title,
  description,
  selected,
  onClick,
}: {
  icon: React.ComponentType<{ className?: string; strokeWidth?: number }>;
  title: string;
  description: string;
  selected: boolean;
  onClick: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`text-left p-4 rounded-[12px] border transition-all ${
        selected
          ? "bg-[#b8e0f0]/10 border-[#b8e0f0]/40"
          : "bg-[#0f172a]/40 border-white/10 hover:border-white/20"
      }`}
    >
      <div className="flex items-center gap-2.5 mb-2">
        <Icon
          className={`w-4 h-4 ${selected ? "text-[#b8e0f0]" : "text-[#94a3b8]"}`}
          strokeWidth={1.75}
        />
        <p className="text-[14px] font-semibold text-white">{title}</p>
      </div>
      <p className="text-[12px] text-[#94a3b8] leading-[18px]">{description}</p>
    </button>
  );
}

/* ---------------------------- Shared ---------------------------- */

const inputClass =
  "w-full h-[44px] bg-[#0f172a]/80 border border-[#334155]/60 rounded-[10px] px-4 text-[14px] text-white placeholder:text-[#64748b] focus:outline-none focus:border-[#b8e0f0]/60 focus:ring-2 focus:ring-[#b8e0f0]/15 transition-all";

function FieldLabel({
  label,
  required,
  children,
}: {
  label: string;
  required?: boolean;
  children: React.ReactNode;
}) {
  return (
    <label className="block">
      <span className="block text-[13px] text-[#cbd5e1] mb-2 font-medium">
        {label}
        {required && <span className="text-[#ef4444] ml-1">*</span>}
      </span>
      {children}
    </label>
  );
}
