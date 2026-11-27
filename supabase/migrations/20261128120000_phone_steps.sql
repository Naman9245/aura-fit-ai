-- Steps counted by the phone's own step sensor, as well as typed in. The
-- app keeps one steps reading a day and only ever raises it, so a higher
-- number typed by hand stays.
alter table public.health_samples
  drop constraint health_samples_source_check,
  add constraint health_samples_source_check
    check (source in ('manual', 'phone'));
