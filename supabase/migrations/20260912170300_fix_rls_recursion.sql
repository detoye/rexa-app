-- Fix infinite recursion in RLS policies

-- Drop recursive platform_admins policies
drop policy if exists "Platform admins can view all" on platform_admins;
drop policy if exists "Platform admins can insert" on platform_admins;

-- Recreate without self-reference
create policy "Platform admins can view all" on platform_admins for select
  using (id = auth.uid());

create policy "Platform admins can insert" on platform_admins for insert
  with check (true);

-- Fix members self-referencing policy
drop policy if exists "Members can view members" on members;

create policy "Members can view members" on members for select using (
  user_id = auth.uid()
);
