-- Star Sitters — denormalized sitter totals (BACKEND.md §5 Migration 14)
create or replace function public.fn_update_sitter_totals()
returns trigger language plpgsql security definer
set search_path = public as $$
begin
  if old.clock_out_at is null
     and new.clock_out_at is not null
     and new.computed_minutes is not null
     and new.computed_wage is not null
  then
    perform set_config('app.bypass_immutability', 'true', true);
    update public.sitter_profiles
       set total_minutes_worked = total_minutes_worked + new.computed_minutes,
           total_earnings       = total_earnings + new.computed_wage,
           updated_at           = now()
     where user_id = new.sitter_id;
  end if;
  return new;
end;
$$;

create trigger trg_update_sitter_totals
  after update of clock_out_at, computed_minutes, computed_wage
  on public.time_entries
  for each row execute function public.fn_update_sitter_totals();
