-- Star Sitters — job status → timeline events (BACKEND.md §31.6 §10)

create or replace function public.fn_jobs_timeline_trigger()
returns trigger language plpgsql security definer
set search_path = public as $$
declare
  v_event text;
begin
  if old.status is distinct from new.status then
    v_event := case new.status::text
      when 'open'      then 'posted'
      when 'hired'     then 'hired'
      when 'active'    then 'clock_in'
      when 'completed' then 'completed'
      when 'cancelled' then 'cancelled'
      else null
    end;

    if v_event is not null then
      insert into public.job_timeline_events (job_id, event_type, title, actor_id)
      values (
        new.id,
        v_event,
        'Status changed to ' || new.status::text,
        auth.uid()
      );
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_jobs_timeline on public.jobs;
create trigger trg_jobs_timeline
  after update of status on public.jobs
  for each row execute function public.fn_jobs_timeline_trigger();
