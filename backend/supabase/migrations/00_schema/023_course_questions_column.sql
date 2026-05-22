-- S4: Move quiz questions to DB so admins can update without an app release.
-- Adds a `questions` JSONB column to the `courses` table.
-- Each element: {question: string, options: [string], correct: int (0-indexed)}
alter table public.courses
  add column if not exists questions jsonb not null default '[]'::jsonb;

comment on column public.courses.questions is
  'Array of quiz questions: [{question, options, correct}]. Updated by admins without an app release.';

-- Seed the existing CPR course with the current hardcoded questions.
update public.courses
set questions = '[
  {"question": "What should you do FIRST in an emergency?", "options": ["Start CPR immediately", "Call the parents", "Call 911", "Check for a pulse"], "correct": 2},
  {"question": "What is the correct compression rate for CPR on a child?", "options": ["60-80 per minute", "100-120 per minute", "140-160 per minute", "80-100 per minute"], "correct": 1},
  {"question": "How deep should chest compressions be for a child?", "options": ["About 1 inch", "About 3 inches", "About 2 inches", "About 4 inches"], "correct": 2}
]'::jsonb
where name ilike '%cpr%' or name ilike '%first aid%';
