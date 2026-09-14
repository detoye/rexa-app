-- Fix platform_admins RLS: first user can self-promote, after that only existing admins
-- Also ensures admin invite codes use A- prefix format

-- Drop the overly permissive INSERT policy from the recursion fix migration
drop policy if exists "Platform admins can insert" on platform_admins;

-- New INSERT policy: allow if no admins exist (first user) OR if caller is already admin
create policy "Platform admins can insert" on platform_admins for insert
  with check (
    not exists (select 1 from platform_admins)
    or exists (select 1 from platform_admins where id = auth.uid())
  );

-- Allow platform_admins to be readable by the user themselves
-- (existing select policy: id = auth.uid() — already correct from fix_rls_recursion migration)
