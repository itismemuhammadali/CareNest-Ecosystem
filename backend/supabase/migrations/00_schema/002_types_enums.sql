-- Star Sitters — enums (BACKEND.md §5 Migration 2)
create type public.user_role as enum ('family', 'sitter', 'admin');
create type public.job_status as enum (
  'draft', 'open', 'hired', 'active', 'completed', 'cancelled'
);
create type public.application_status as enum (
  'pending', 'accepted', 'rejected', 'withdrawn'
);
create type public.verification_status as enum (
  'not_submitted', 'pending', 'approved', 'rejected'
);
create type public.ledger_type as enum (
  'earning', 'withdrawal', 'adjustment', 'refund'
);
