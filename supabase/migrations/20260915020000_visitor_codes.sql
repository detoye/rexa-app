-- Visitor Codes: tenants create codes for their guests, security verifies at gate
create table if not exists visitor_codes (
  id uuid primary key default gen_random_uuid(),
  estate_id uuid references estates(id) on delete cascade,
  host_member_id uuid references members(id) not null,
  code text not null,
  visitor_name text not null,
  visitor_phone text,
  purpose text,
  expires_at timestamptz not null,
  is_used boolean default false,
  used_at timestamptz,
  created_at timestamptz default now()
);

alter table visitor_codes enable row level security;

-- Host (tenant) can view their own visitor codes
create policy "Hosts can view their visitor codes" on visitor_codes for select using (
  host_member_id in (select id from members where user_id = auth.uid())
);

-- Hosts can create visitor codes for their estate
create policy "Hosts can create visitor codes" on visitor_codes for insert with check (
  host_member_id in (select id from members where user_id = auth.uid() and estate_id = visitor_codes.estate_id)
);

-- Security and admins can view all visitor codes in the estate (for verification)
create policy "Security can view estate visitor codes" on visitor_codes for select using (
  estate_id in (
    select estate_id from members
    where user_id = auth.uid()
    and role in ('admin', 'super_admin', 'security')
  )
);

-- Security and admins can update visitor codes (mark as used)
create policy "Security can update visitor codes" on visitor_codes for update using (
  estate_id in (
    select estate_id from members
    where user_id = auth.uid()
    and role in ('admin', 'super_admin', 'security')
  )
);

-- Index for fast code lookup
create index if not exists idx_visitor_codes_code on visitor_codes(code);
create index if not exists idx_visitor_codes_estate on visitor_codes(estate_id, is_used);
