-- Production cleanup template
-- Once SELECT preview queries first.
-- Then uncomment only the DELETE blocks you really want.

-- 1. Preview suspicious demo/test users
select id, role, phone, email, is_active
from users
where
  coalesce(phone, '') ilike '%555%'
  or coalesce(email, '') ilike '%test%'
  or coalesce(email, '') ilike '%demo%'
order by role, phone nulls last, email nulls last;

-- 2. Preview suspicious provider profiles
select user_id, full_name, approval_status, services, age, hourly_rate, daily_rate
from provider_profiles
where
  coalesce(full_name, '') ilike '%deneme%'
  or coalesce(full_name, '') ilike '%test%'
  or coalesce(full_name, '') ilike '%demo%'
order by user_id desc;

-- 3. Preview recent care requests
select id, parent_user_id, status, note, created_at
from care_requests
order by created_at desc
limit 50;

-- 4. Preview recent bookings
select id, parent_user_id, provider_user_id, service, status, created_at
from bookings
order by created_at desc
limit 50;

-- 5. Preview recent conversations/messages
select id, user_a_id, user_b_id, last_message, last_message_at
from conversations
order by last_message_at desc nulls last
limit 50;

-- Example cleanup block for obvious demo providers.
-- Replace UUID values after checking the SELECT results above.
--
-- begin;
-- delete from device_push_tokens where user_id in (
--   'UUID_1',
--   'UUID_2'
-- );
-- delete from notifications where user_id in (
--   'UUID_1',
--   'UUID_2'
-- );
-- delete from messages where conversation_id in (
--   select id from conversations
--   where user_a_id in ('UUID_1','UUID_2')
--      or user_b_id in ('UUID_1','UUID_2')
-- );
-- delete from conversations
-- where user_a_id in ('UUID_1','UUID_2')
--    or user_b_id in ('UUID_1','UUID_2');
-- delete from calls where user_id in ('UUID_1','UUID_2');
-- delete from favorites where user_id in ('UUID_1','UUID_2') or provider_user_id in ('UUID_1','UUID_2');
-- delete from care_request_candidates where provider_user_id in ('UUID_1','UUID_2');
-- delete from bookings where parent_user_id in ('UUID_1','UUID_2') or provider_user_id in ('UUID_1','UUID_2');
-- delete from care_requests where parent_user_id in ('UUID_1','UUID_2') or assigned_provider_user_id in ('UUID_1','UUID_2');
-- delete from provider_accounts where provider_user_id in ('UUID_1','UUID_2');
-- delete from provider_blocks where user_id in ('UUID_1','UUID_2');
-- delete from provider_availability where user_id in ('UUID_1','UUID_2');
-- delete from provider_profiles where user_id in ('UUID_1','UUID_2');
-- delete from parent_profiles where user_id in ('UUID_1','UUID_2');
-- delete from users where id in ('UUID_1','UUID_2');
-- commit;

-- Safety note:
-- Keep ADMIN users and known real parent/provider accounts out of cleanup lists.
