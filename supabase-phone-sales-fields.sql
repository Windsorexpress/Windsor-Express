-- Run once in the Supabase SQL editor for the Windsor Express project.
-- Safe to run again: columns and named constraints are only added when missing.

alter table public.phones
  add column if not exists sale_price numeric(10,2),
  add column if not exists battery_health smallint,
  add column if not exists professionally_refurbished boolean not null default false,
  add column if not exists software_version text,
  add column if not exists software_support text,
  add column if not exists software_source_url text;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'phones_sale_price_positive'
      and conrelid = 'public.phones'::regclass
  ) then
    alter table public.phones
      add constraint phones_sale_price_positive
      check (sale_price is null or sale_price > 0);
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'phones_sale_price_below_regular'
      and conrelid = 'public.phones'::regclass
  ) then
    alter table public.phones
      add constraint phones_sale_price_below_regular
      check (sale_price is null or sale_price < price);
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'phones_battery_health_range'
      and conrelid = 'public.phones'::regclass
  ) then
    alter table public.phones
      add constraint phones_battery_health_range
      check (battery_health is null or battery_health between 0 and 100);
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'phones_software_source_https'
      and conrelid = 'public.phones'::regclass
  ) then
    alter table public.phones
      add constraint phones_software_source_https
      check (
        software_source_url is null
        or software_source_url = ''
        or software_source_url ~* '^https://'
      );
  end if;
end
$$;
