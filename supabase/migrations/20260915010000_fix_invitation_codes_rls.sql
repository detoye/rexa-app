-- Fix: Allow anyone to view unused, non-expired invitation codes for joining
-- The old policy only let existing members see codes, blocking new users from joining

-- Drop the restrictive policy
drop policy if exists "Members can view invitation codes" on invitation_codes;

-- New policy: members can see all codes for their estate
create policy "Members can view invitation codes" on invitation_codes for select using (
  estate_id in (select estate_id from members where user_id = auth.uid())
);

-- New policy: anyone authenticated can view unused, non-expired codes (for joining)
create policy "Anyone can view active invitation codes for joining" on invitation_codes for select using (
  is_used = false
  and (expires_at is null or expires_at > now())
);

-- Also allow update on invitation_codes (for marking as used)
create policy "Members can update invitation codes" on invitation_codes for update using (
  estate_id in (select estate_id from members where user_id = auth.uid())
);
