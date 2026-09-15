-- Platform settings table for admin configuration
create table if not exists platform_settings (
  key text primary key,
  value jsonb not null default 'true'::jsonb,
  updated_at timestamptz default now()
);

alter table platform_settings enable row level security;

-- Platform admins can manage settings
create policy "Platform admins can manage settings" on platform_settings
  for all using (
    exists (select 1 from platform_admins where id = auth.uid())
  );

-- Members can view settings
create policy "Members can view settings" on platform_settings
  for select using (true);

-- Insert policy for dues (admins only)
create policy "Admins can insert dues" on dues for insert with check (
  exists (
    select 1 from members
    where user_id = auth.uid()
      and estate_id = dues.estate_id
      and role in ('admin', 'super_admin')
  )
);

-- Admins can update dues
create policy "Admins can update dues" on dues for update using (
  exists (
    select 1 from members
    where user_id = auth.uid()
      and estate_id = dues.estate_id
      and role in ('admin', 'super_admin')
  )
);

-- Insert default platform settings
insert into platform_settings (key, value) values
  ('push_notifications', 'true'::jsonb),
  ('email_notifications', 'true'::jsonb),
  ('sms_notifications', 'false'::jsonb),
  ('community_feed', 'true'::jsonb),
  ('property_listings', 'true'::jsonb),
  ('business_ads', 'true'::jsonb),
  ('iot_integration', 'false'::jsonb)
on conflict (key) do nothing;
