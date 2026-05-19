-- Seed the marker/assessor test user into auth.users.
-- This gives the marker instant login without needing a confirmation email.
--
-- Credentials:
--   Email:    marker@mq-navigation.test
--   Password: OpenDay2026!
--   UUID:     34d6db22-73a7-408d-9dc2-ab78fa22bd13
--
-- Safe to run multiple times (ON CONFLICT DO NOTHING).

INSERT INTO auth.users (
  id,
  instance_id,
  email,
  encrypted_password,
  email_confirmed_at,
  confirmation_sent_at,
  recovery_sent_at,
  last_sign_in_at,
  raw_app_meta_data,
  raw_user_meta_data,
  is_super_admin,
  role,
  aud,
  created_at,
  updated_at,
  confirmation_token,
  email_change,
  email_change_token_new,
  recovery_token
)
VALUES (
  '34d6db22-73a7-408d-9dc2-ab78fa22bd13',
  '00000000-0000-0000-0000-000000000000',
  'marker@mq-navigation.test',
  '$2b$10$n7clT/wdhhUMTHvx5OiMKe3.JNZ.N6SBQI1QlIQn7iKDjDX/AK7cK',
  NOW(),           -- email_confirmed_at — marks email as verified instantly
  NOW(),
  NULL,
  NULL,
  '{"provider":"email","providers":["email"]}',
  '{"name":"MQ Marker"}',
  FALSE,
  'authenticated',
  'authenticated',
  NOW(),
  NOW(),
  '',
  '',
  '',
  ''
)
ON CONFLICT (id) DO NOTHING;

-- auth.identities: 'email' column is generated — omit it from INSERT.
-- provider_id for email provider = the user's email address.
-- The identity row is auto-created by Supabase trigger on auth.users insert,
-- so this is a safety net for cases where the trigger did not fire.
INSERT INTO auth.identities (
  id,
  provider_id,
  user_id,
  identity_data,
  provider,
  last_sign_in_at,
  created_at,
  updated_at
)
VALUES (
  gen_random_uuid(),
  'marker@mq-navigation.test',
  '34d6db22-73a7-408d-9dc2-ab78fa22bd13',
  '{"sub":"34d6db22-73a7-408d-9dc2-ab78fa22bd13","email":"marker@mq-navigation.test","email_verified":true}',
  'email',
  NOW(),
  NOW(),
  NOW()
)
ON CONFLICT (provider_id, provider) DO NOTHING;

