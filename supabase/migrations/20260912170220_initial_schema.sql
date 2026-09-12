-- Reza (ResidentZ) — Complete Database Schema
-- Run this in Supabase SQL Editor

create extension if not exists "uuid-ossp";

-- ============================================================
-- CORE TABLES
-- ============================================================

-- Platform Admins (separate from estate members)
create table if not exists platform_admins (
  id uuid primary key references auth.users(id) on delete cascade,
  role text not null default 'admin',
  created_at timestamptz default now()
);

-- Estates table
create table if not exists estates (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  address text not null,
  logo_url text,
  description text,
  paystack_subaccount_code text,
  paystack_bank_code text,
  paystack_account_number text,
  platform_fee_percent numeric default 1.5,
  settlement_schedule text default 'daily',
  created_by uuid references auth.users(id),
  created_at timestamptz default now()
);

-- Members table
create table if not exists members (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  estate_id uuid references estates(id) on delete cascade,
  role text not null default 'tenant',
  house_number text,
  street text,
  is_verified boolean default false,
  created_at timestamptz default now()
);

-- ============================================================
-- SUBSCRIPTION & BILLING TABLES
-- ============================================================

-- Subscription Plans (editable by platform owner)
create table if not exists subscription_plans (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  price_monthly numeric default 0,
  price_yearly numeric default 0,
  max_estates int default 1,
  max_members int default 10,
  features jsonb default '{}',
  is_active boolean default true,
  display_order int default 0,
  created_at timestamptz default now()
);

-- Feature Flags (platform owner controls)
create table if not exists feature_flags (
  id uuid primary key default gen_random_uuid(),
  key text not null unique,
  label text not null,
  description text,
  is_enabled boolean default true,
  created_at timestamptz default now()
);

-- Plan-Feature Mapping
create table if not exists plan_features (
  plan_id uuid references subscription_plans(id) on delete cascade,
  feature_id uuid references feature_flags(id) on delete cascade,
  is_enabled boolean default true,
  primary key (plan_id, feature_id)
);

-- Estate Subscriptions
create table if not exists estate_subscriptions (
  id uuid primary key default gen_random_uuid(),
  estate_id uuid references estates(id) on delete cascade,
  plan_id uuid references subscription_plans(id),
  paystack_subscription_code text,
  paystack_customer_code text,
  billing_cycle text,
  start_date timestamptz,
  end_date timestamptz,
  is_active boolean default true,
  created_at timestamptz default now()
);

-- ============================================================
-- FINANCIAL TABLES
-- ============================================================

-- Due Types
create table if not exists dues (
  id uuid primary key default gen_random_uuid(),
  estate_id uuid references estates(id) on delete cascade,
  name text not null,
  description text,
  amount numeric not null,
  type text not null,
  is_recurrent boolean default false,
  recurrence_interval text,
  due_date date,
  is_active boolean default true,
  created_at timestamptz default now()
);

-- Invoices
create table if not exists invoices (
  id uuid primary key default gen_random_uuid(),
  estate_id uuid references estates(id) on delete cascade,
  member_id uuid references members(id),
  due_id uuid references dues(id),
  amount numeric not null,
  type text not null,
  is_paid boolean default false,
  due_date date,
  paid_date timestamptz,
  payment_reference text,
  created_at timestamptz default now()
);

-- Payments
create table if not exists payments (
  id uuid primary key default gen_random_uuid(),
  estate_id uuid references estates(id) on delete cascade,
  member_id uuid references members(id),
  due_id uuid references dues(id),
  invoice_id uuid references invoices(id),
  amount numeric not null,
  platform_fee numeric default 0,
  net_amount numeric default 0,
  status text not null default 'pending',
  payment_method text,
  reference text,
  paystack_reference text,
  created_at timestamptz default now()
);

-- Wallets
create table if not exists wallets (
  id uuid primary key default gen_random_uuid(),
  member_id uuid references members(id) on delete cascade unique,
  balance numeric default 0,
  total_funded numeric default 0,
  total_spent numeric default 0,
  updated_at timestamptz default now()
);

-- Wallet Transactions
create table if not exists wallet_transactions (
  id uuid primary key default gen_random_uuid(),
  wallet_id uuid references wallets(id) on delete cascade,
  amount numeric not null,
  type text not null,
  description text,
  created_at timestamptz default now()
);

-- ============================================================
-- GOVERNANCE TABLES
-- ============================================================

-- Meetings
create table if not exists meetings (
  id uuid primary key default gen_random_uuid(),
  estate_id uuid references estates(id) on delete cascade,
  title text not null,
  description text,
  minutes text,
  meeting_date timestamptz not null,
  meeting_type text default 'general',
  document_url text,
  attendees uuid[] default '{}',
  created_at timestamptz default now()
);

-- Committees
create table if not exists committees (
  id uuid primary key default gen_random_uuid(),
  estate_id uuid references estates(id) on delete cascade,
  name text not null,
  description text,
  chairperson uuid references members(id),
  status text default 'active',
  created_at timestamptz default now()
);

-- Committee Members
create table if not exists committee_members (
  id uuid primary key default gen_random_uuid(),
  committee_id uuid references committees(id) on delete cascade,
  member_id uuid references members(id) on delete cascade,
  role text default 'member',
  created_at timestamptz default now()
);

-- Projects
create table if not exists projects (
  id uuid primary key default gen_random_uuid(),
  estate_id uuid references estates(id) on delete cascade,
  name text not null,
  description text,
  budget numeric,
  spent numeric default 0,
  progress_percent int default 0,
  status text default 'active',
  photos text[] default '{}',
  videos text[] default '{}',
  created_at timestamptz default now()
);

-- ============================================================
-- COMMUNICATION TABLES
-- ============================================================

-- Announcements
create table if not exists announcements (
  id uuid primary key default gen_random_uuid(),
  estate_id uuid references estates(id) on delete cascade,
  title text not null,
  content text not null,
  author_id uuid references members(id),
  priority text default 'normal',
  category text default 'general',
  is_pinned boolean default false,
  attachments text[] default '{}',
  created_at timestamptz default now()
);

-- Posts (Community Feed)
create table if not exists posts (
  id uuid primary key default gen_random_uuid(),
  estate_id uuid references estates(id) on delete cascade,
  author_id uuid references members(id),
  category text not null default 'Update',
  title text,
  content text not null,
  photos text[] default '{}',
  video_url text,
  likes uuid[] default '{}',
  num_comments int default 0,
  is_pinned boolean default false,
  created_at timestamptz default now()
);

-- Comments
create table if not exists comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid references posts(id) on delete cascade,
  author_id uuid references members(id),
  content text not null,
  created_at timestamptz default now()
);

-- Activities (Timeline)
create table if not exists activities (
  id uuid primary key default gen_random_uuid(),
  estate_id uuid references estates(id) on delete cascade,
  actor_id uuid references members(id),
  activity_type text not null,
  description text not null,
  metadata jsonb default '{}',
  created_at timestamptz default now()
);

-- Notifications
create table if not exists notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  estate_id uuid references estates(id) on delete cascade,
  type text not null,
  title text not null,
  body text,
  is_read boolean default false,
  data jsonb default '{}',
  created_at timestamptz default now()
);

-- Member Ads
create table if not exists member_ads (
  id uuid primary key default gen_random_uuid(),
  member_id uuid references members(id) on delete cascade,
  title text not null,
  description text not null,
  image_url text,
  category text,
  contact_phone text,
  contact_email text,
  is_featured boolean default false,
  is_active boolean default true,
  created_at timestamptz default now()
);

-- ============================================================
-- PROPERTY TABLES
-- ============================================================

-- Properties
create table if not exists properties (
  id uuid primary key default gen_random_uuid(),
  estate_id uuid references estates(id) on delete cascade,
  owner_id uuid references members(id),
  title text not null,
  description text,
  type text not null,
  listing_type text not null default 'sale',
  price numeric not null,
  price_unit text,
  bedrooms int,
  bathrooms int,
  area numeric,
  address text,
  photos text[] default '{}',
  is_available boolean default true,
  created_at timestamptz default now()
);

-- Property Deals (Quick)
create table if not exists property_deals (
  id uuid primary key default gen_random_uuid(),
  estate_id uuid references estates(id) on delete cascade,
  seller_id uuid references members(id),
  title text not null,
  description text,
  deal_type text not null,
  price numeric not null,
  property_type text,
  image_url text,
  is_active boolean default true,
  created_at timestamptz default now()
);

-- ============================================================
-- SECURITY TABLES
-- ============================================================

-- Guest Manifests
create table if not exists guest_manifests (
  id uuid primary key default gen_random_uuid(),
  estate_id uuid references estates(id) on delete cascade,
  visitor_name text not null,
  visitor_phone text,
  purpose text,
  host_member_id uuid references members(id),
  check_in_time timestamptz not null,
  check_out_time timestamptz,
  created_at timestamptz default now()
);

-- Security Alerts
create table if not exists security_alerts (
  id uuid primary key default gen_random_uuid(),
  estate_id uuid references estates(id) on delete cascade,
  title text not null,
  description text not null,
  severity text not null default 'low',
  is_active boolean default true,
  created_at timestamptz default now()
);

-- ============================================================
-- INVITATION SYSTEM
-- ============================================================

create table if not exists invitation_codes (
  id uuid primary key default gen_random_uuid(),
  estate_id uuid references estates(id) on delete cascade,
  code text not null unique,
  created_by uuid references members(id),
  used_by uuid references members(id),
  role text default 'tenant',
  is_used boolean default false,
  expires_at timestamptz,
  created_at timestamptz default now()
);

-- ============================================================
-- ENABLE RLS
-- ============================================================

alter table platform_admins enable row level security;
alter table estates enable row level security;
alter table members enable row level security;
alter table subscription_plans enable row level security;
alter table feature_flags enable row level security;
alter table plan_features enable row level security;
alter table estate_subscriptions enable row level security;
alter table dues enable row level security;
alter table invoices enable row level security;
alter table payments enable row level security;
alter table wallets enable row level security;
alter table wallet_transactions enable row level security;
alter table meetings enable row level security;
alter table committees enable row level security;
alter table committee_members enable row level security;
alter table projects enable row level security;
alter table announcements enable row level security;
alter table posts enable row level security;
alter table comments enable row level security;
alter table activities enable row level security;
alter table notifications enable row level security;
alter table member_ads enable row level security;
alter table properties enable row level security;
alter table property_deals enable row level security;
alter table guest_manifests enable row level security;
alter table security_alerts enable row level security;
alter table invitation_codes enable row level security;

-- ============================================================
-- RLS POLICIES
-- ============================================================

-- Platform Admin policies
create policy "Platform admins can view all" on platform_admins for select
  using (exists (select 1 from platform_admins where id = auth.uid()));

create policy "Platform admins can insert" on platform_admins for insert
  with check (exists (select 1 from platform_admins where id = auth.uid()));

-- Estate policies
create policy "Members can view estate" on estates for select using (
  exists (select 1 from members where members.estate_id = estates.id and members.user_id = auth.uid())
);

create policy "Platform admins can view all estates" on estates for select using (
  exists (select 1 from platform_admins where id = auth.uid())
);

create policy "Platform admins can insert estates" on estates for insert
  with check (exists (select 1 from platform_admins where id = auth.uid()));

-- Member policies
create policy "Members can view members" on members for select using (
  estate_id in (select estate_id from members where user_id = auth.uid())
);

create policy "Members can insert member" on members for insert with check (
  user_id = auth.uid()
);

-- Subscription Plans (read-only for everyone, editable by platform admin)
create policy "Anyone can view active plans" on subscription_plans for select
  using (is_active = true);

create policy "Platform admins can manage plans" on subscription_plans for all
  using (exists (select 1 from platform_admins where id = auth.uid()));

-- Feature Flags
create policy "Anyone can view enabled flags" on feature_flags for select
  using (is_enabled = true);

create policy "Platform admins can manage flags" on feature_flags for all
  using (exists (select 1 from platform_admins where id = auth.uid()));

-- Plan Features
create policy "Anyone can view plan features" on plan_features for select
  using (true);

create policy "Platform admins can manage plan features" on plan_features for all
  using (exists (select 1 from platform_admins where id = auth.uid()));

-- Estate Subscriptions
create policy "Members can view own estate subscription" on estate_subscriptions for select
  using (
    estate_id in (select estate_id from members where user_id = auth.uid())
  );

create policy "Platform admins can manage subscriptions" on estate_subscriptions for all
  using (exists (select 1 from platform_admins where id = auth.uid()));

-- Dues
create policy "Members can view dues" on dues for select using (
  estate_id in (select estate_id from members where user_id = auth.uid())
);

-- Invoices
create policy "Members can view invoices" on invoices for select using (
  estate_id in (select estate_id from members where user_id = auth.uid())
);

create policy "Admins can insert invoices" on invoices for insert with check (
  exists (select 1 from members where user_id = auth.uid() and estate_id = invoices.estate_id and role in ('admin', 'super_admin'))
);

-- Payments
create policy "Members can view payments" on payments for select using (
  member_id in (select id from members where user_id = auth.uid())
);

create policy "Members can insert payments" on payments for insert with check (
  member_id in (select id from members where user_id = auth.uid())
);

-- Wallets
create policy "Members can view wallet" on wallets for select using (
  member_id in (select id from members where user_id = auth.uid())
);

-- Wallet Transactions
create policy "Members can view wallet transactions" on wallet_transactions for select using (
  wallet_id in (select id from wallets where member_id in (select id from members where user_id = auth.uid()))
);

-- Meetings
create policy "Members can view meetings" on meetings for select using (
  estate_id in (select estate_id from members where user_id = auth.uid())
);

-- Committees
create policy "Members can view committees" on committees for select using (
  estate_id in (select estate_id from members where user_id = auth.uid())
);

-- Committee Members
create policy "Members can view committee members" on committee_members for select using (
  committee_id in (select id from committees where estate_id in (select estate_id from members where user_id = auth.uid()))
);

-- Projects
create policy "Members can view projects" on projects for select using (
  estate_id in (select estate_id from members where user_id = auth.uid())
);

-- Announcements
create policy "Members can view announcements" on announcements for select using (
  estate_id in (select estate_id from members where user_id = auth.uid())
);

create policy "Admins can insert announcements" on announcements for insert with check (
  exists (select 1 from members where user_id = auth.uid() and estate_id = announcements.estate_id and role in ('admin', 'super_admin'))
);

-- Posts
create policy "Members can view posts" on posts for select using (
  estate_id in (select estate_id from members where user_id = auth.uid())
);

create policy "Members can insert posts" on posts for insert with check (
  estate_id in (select estate_id from members where user_id = auth.uid())
);

create policy "Members can update posts" on posts for update using (
  author_id in (select id from members where user_id = auth.uid())
);

-- Comments
create policy "Members can view comments" on comments for select using (
  post_id in (select id from posts where estate_id in (select estate_id from members where user_id = auth.uid()))
);

create policy "Members can insert comments" on comments for insert with check (
  author_id in (select id from members where user_id = auth.uid())
);

-- Activities
create policy "Members can view activities" on activities for select using (
  estate_id in (select estate_id from members where user_id = auth.uid())
);

-- Notifications
create policy "Users can view own notifications" on notifications for select using (
  user_id = auth.uid()
);

create policy "Users can update own notifications" on notifications for update using (
  user_id = auth.uid()
);

-- Member Ads
create policy "Members can view member ads" on member_ads for select using (
  member_id in (select id from members where user_id = auth.uid())
);

create policy "Members can insert member ads" on member_ads for insert with check (
  member_id in (select id from members where user_id = auth.uid())
);

-- Properties
create policy "Members can view properties" on properties for select using (
  estate_id in (select estate_id from members where user_id = auth.uid())
);

create policy "Members can insert properties" on properties for insert with check (
  estate_id in (select estate_id from members where user_id = auth.uid())
);

-- Property Deals
create policy "Members can view property deals" on property_deals for select using (
  estate_id in (select estate_id from members where user_id = auth.uid())
);

create policy "Members can insert property deals" on property_deals for insert with check (
  estate_id in (select estate_id from members where user_id = auth.uid())
);

-- Guest Manifests
create policy "Members can view guest manifests" on guest_manifests for select using (
  estate_id in (select estate_id from members where user_id = auth.uid())
);

-- Security Alerts
create policy "Members can view security alerts" on security_alerts for select using (
  estate_id in (select estate_id from members where user_id = auth.uid())
);

-- Invitation Codes
create policy "Members can view invitation codes" on invitation_codes for select using (
  estate_id in (select estate_id from members where user_id = auth.uid())
);

create policy "Admins can insert invitation codes" on invitation_codes for insert with check (
  exists (select 1 from members where user_id = auth.uid() and estate_id = invitation_codes.estate_id and role in ('admin', 'super_admin'))
);

-- ============================================================
-- INDEXES
-- ============================================================

create index if not exists idx_members_estate on members(estate_id, user_id);
create index if not exists idx_members_user on members(user_id);
create index if not exists idx_estates_created_by on estates(created_by);
create index if not exists idx_properties_estate on properties(estate_id, is_available);
create index if not exists idx_dues_estate on dues(estate_id);
create index if not exists idx_invoices_estate on invoices(estate_id, is_paid);
create index if not exists idx_invoices_member on invoices(member_id);
create index if not exists idx_payments_member on payments(member_id, created_at desc);
create index if not exists idx_payments_estate on payments(estate_id);
create index if not exists idx_announcements_estate on announcements(estate_id, created_at desc);
create index if not exists idx_posts_estate on posts(estate_id, created_at desc);
create index if not exists idx_comments_post on comments(post_id);
create index if not exists idx_activities_estate on activities(estate_id, created_at desc);
create index if not exists idx_notifications_user on notifications(user_id, is_read);
create index if not exists idx_guest_manifests_estate on guest_manifests(estate_id, check_in_time desc);
create index if not exists idx_security_alerts_estate on security_alerts(estate_id, is_active);
create index if not exists idx_estate_subscriptions_estate on estate_subscriptions(estate_id);
create index if not exists idx_invitation_codes_estate on invitation_codes(estate_id);
create index if not exists idx_invitation_codes_code on invitation_codes(code);

-- ============================================================
-- SEED DATA: Default Subscription Plans
-- ============================================================

insert into subscription_plans (name, slug, price_monthly, price_yearly, max_estates, max_members, features, display_order) values
  ('Free', 'free', 0, 0, 1, 10, '{"announcements": true, "community_feed": true, "guest_manifest": true, "members_view": true, "dues_manual": true}', 0),
  ('Basic', 'basic', 8000, 80000, 1, 150, '{"payment_gateway": true, "invoices": true, "wallet": true, "property_listings": true, "business_ads": true, "quick_deals": true, "reports_basic": true}', 1),
  ('Premium', 'premium', 25000, 250000, 5, 999999, '{"committees": true, "projects": true, "multi_estate": true, "reports_advanced": true, "subscription_management": true}', 2),
  ('Enterprise', 'enterprise', 0, 0, 999999, 999999, '{"api_access": true, "white_label": true, "dedicated_support": true}', 3);

-- Seed Feature Flags
insert into feature_flags (key, label, description) values
  ('payment_gateway', 'Payment Gateway', 'Enable Paystack payment integration'),
  ('invoices', 'Invoices', 'Generate and manage invoices'),
  ('wallet', 'Wallet', 'Enable wallet balance and funding'),
  ('property_listings', 'Property Listings', 'List properties for rent/sale'),
  ('business_ads', 'Business Ads', 'Member classified advertisements'),
  ('quick_deals', 'Quick Property Deals', 'Quick rent/sale deals'),
  ('committees', 'Committees', 'Create and manage committees'),
  ('projects', 'Projects', 'Track estate projects with progress'),
  ('multi_estate', 'Multi-Estate View', 'Manage multiple estates from one account'),
  ('reports_basic', 'Basic Reports', 'Basic financial and activity reports'),
  ('reports_advanced', 'Advanced Reports', 'Detailed analytics and exports'),
  ('api_access', 'API Access', 'REST API for external integrations'),
  ('white_label', 'White Label', 'Custom branding for the app'),
  ('dedicated_support', 'Dedicated Support', 'Priority support channel'),
  ('announcements', 'Announcements', 'Estate-wide announcements'),
  ('community_feed', 'Community Feed', 'Posts, comments, likes'),
  ('guest_manifest', 'Guest Manifest', 'Visitor check-in/check-out tracking'),
  ('subscription_management', 'Subscription Management', 'Plan upgrade/downgrade');
