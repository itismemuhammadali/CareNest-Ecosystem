-- Fix PostgREST HTTP 500 on admin reads (families, disputes, users batch, etc.).
-- admin_users had: USING (public.is_admin()). is_admin() runs
--   SELECT EXISTS (SELECT 1 FROM public.admin_users WHERE id = auth.uid()).
-- That inner SELECT re-evaluates the same policy → infinite recursion → DB error → 500.
-- Allow each principal to read only their own membership row; that is enough for
-- is_admin() / admin_only_bool() / middleware checks and breaks the cycle.

drop policy if exists "admin_users: admin select all" on public.admin_users;

create policy "admin_users: select own membership row"
  on public.admin_users for select
  using (id = auth.uid());
