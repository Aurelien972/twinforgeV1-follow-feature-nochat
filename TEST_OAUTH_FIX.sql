-- =====================================================
-- Test OAuth Fix - SQL Queries
-- =====================================================
-- This file contains useful SQL queries to verify the OAuth fix
-- is working correctly in production

-- =====================================================
-- 1. VERIFICATION: Check RPC Function Exists
-- =====================================================

-- Should return 1 row with the function name
SELECT proname, prosrc
FROM pg_proc
WHERE proname = 'create_device_auth_flow';

-- Check function grants
SELECT grantee, privilege_type
FROM information_schema.routine_privileges
WHERE routine_name = 'create_device_auth_flow';

-- =====================================================
-- 2. TEST: Create Sample Auth Flow (as authenticated user)
-- =====================================================

-- This will only work if you're authenticated as a user
-- Test creating an auth flow for google_fit
SELECT create_device_auth_flow(
  'google_fit',
  'https://kwipydbtjagypocpvbwn.supabase.co/functions/v1/wearable-oauth-callback?provider=google_fit'
);

-- Expected result:
-- {
--   "state": "uuid-here",
--   "expires_at": "timestamp-here"
-- }

-- =====================================================
-- 3. MONITORING: Recent Auth Flows
-- =====================================================

-- View last 10 auth flows created
SELECT
  id,
  user_id,
  provider,
  state,
  status,
  created_at,
  expires_at,
  CASE
    WHEN status = 'pending' AND expires_at < NOW() THEN 'EXPIRED'
    WHEN status = 'pending' AND expires_at > NOW() THEN 'ACTIVE'
    ELSE status
  END as current_status
FROM device_auth_flows
ORDER BY created_at DESC
LIMIT 10;

-- =====================================================
-- 4. MONITORING: OAuth Success Rate (Last 24 hours)
-- =====================================================

SELECT
  status,
  COUNT(*) as count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage
FROM device_auth_flows
WHERE created_at > NOW() - INTERVAL '24 hours'
GROUP BY status
ORDER BY count DESC;

-- =====================================================
-- 5. MONITORING: OAuth Success Rate by Provider
-- =====================================================

SELECT
  provider,
  status,
  COUNT(*) as count
FROM device_auth_flows
WHERE created_at > NOW() - INTERVAL '7 days'
GROUP BY provider, status
ORDER BY provider, status;

-- =====================================================
-- 6. MONITORING: Average Time to Complete OAuth
-- =====================================================

-- Shows average time from auth flow creation to completion
SELECT
  provider,
  COUNT(*) as completed_flows,
  ROUND(AVG(EXTRACT(EPOCH FROM (updated_at - created_at))), 2) as avg_seconds,
  ROUND(MIN(EXTRACT(EPOCH FROM (updated_at - created_at))), 2) as min_seconds,
  ROUND(MAX(EXTRACT(EPOCH FROM (updated_at - created_at))), 2) as max_seconds
FROM device_auth_flows
WHERE status = 'completed'
  AND created_at > NOW() - INTERVAL '7 days'
GROUP BY provider;

-- =====================================================
-- 7. MONITORING: Expired Flows (never completed)
-- =====================================================

-- These are flows that were created but never completed
SELECT
  provider,
  COUNT(*) as expired_count,
  MAX(created_at) as most_recent_expired
FROM device_auth_flows
WHERE status = 'pending'
  AND expires_at < NOW()
GROUP BY provider
ORDER BY expired_count DESC;

-- =====================================================
-- 8. MONITORING: Currently Active (Pending) Flows
-- =====================================================

-- Flows that are still pending and not yet expired
SELECT
  provider,
  state,
  created_at,
  expires_at,
  ROUND(EXTRACT(EPOCH FROM (expires_at - NOW())) / 60, 2) as minutes_until_expiry
FROM device_auth_flows
WHERE status = 'pending'
  AND expires_at > NOW()
ORDER BY created_at DESC;

-- =====================================================
-- 9. MONITORING: Connected Devices Status
-- =====================================================

-- Check recently connected devices
SELECT
  provider,
  status,
  display_name,
  connected_at,
  last_sync_at,
  error_count
FROM connected_devices
ORDER BY connected_at DESC
LIMIT 10;

-- =====================================================
-- 10. MONITORING: Connection Success by Provider
-- =====================================================

SELECT
  provider,
  status,
  COUNT(*) as device_count
FROM connected_devices
GROUP BY provider, status
ORDER BY provider, status;

-- =====================================================
-- 11. CLEANUP: Manual Cleanup of Expired Flows
-- =====================================================

-- Run the cleanup function manually
SELECT cleanup_expired_auth_flows();

-- Verify cleanup worked
SELECT
  'Before cleanup' as phase,
  COUNT(*) as expired_pending_flows
FROM device_auth_flows
WHERE status = 'pending' AND expires_at < NOW() - INTERVAL '1 hour'
UNION ALL
SELECT
  'Old completed flows',
  COUNT(*)
FROM device_auth_flows
WHERE status IN ('completed', 'failed') AND created_at < NOW() - INTERVAL '7 days';

-- =====================================================
-- 12. DEBUG: Find Specific Auth Flow by State
-- =====================================================

-- Replace 'your-state-uuid-here' with actual state from logs
SELECT *
FROM device_auth_flows
WHERE state = 'your-state-uuid-here';

-- =====================================================
-- 13. DEBUG: User's Recent Auth Attempts
-- =====================================================

-- Replace 'user-id-here' with actual user UUID
SELECT
  provider,
  status,
  created_at,
  expires_at,
  CASE
    WHEN status = 'completed' THEN 'SUCCESS'
    WHEN status = 'pending' AND expires_at > NOW() THEN 'IN PROGRESS'
    WHEN status = 'pending' AND expires_at < NOW() THEN 'EXPIRED'
    ELSE status
  END as flow_status
FROM device_auth_flows
WHERE user_id = 'user-id-here'
ORDER BY created_at DESC
LIMIT 20;

-- =====================================================
-- 14. HEALTH CHECK: System Overview
-- =====================================================

SELECT
  'Total Auth Flows (7d)' as metric,
  COUNT(*)::TEXT as value
FROM device_auth_flows
WHERE created_at > NOW() - INTERVAL '7 days'
UNION ALL
SELECT
  'Successful Completions (7d)',
  COUNT(*)::TEXT
FROM device_auth_flows
WHERE status = 'completed'
  AND created_at > NOW() - INTERVAL '7 days'
UNION ALL
SELECT
  'Currently Active Flows',
  COUNT(*)::TEXT
FROM device_auth_flows
WHERE status = 'pending'
  AND expires_at > NOW()
UNION ALL
SELECT
  'Expired Flows (cleanup needed)',
  COUNT(*)::TEXT
FROM device_auth_flows
WHERE status = 'pending'
  AND expires_at < NOW() - INTERVAL '1 hour'
UNION ALL
SELECT
  'Total Connected Devices',
  COUNT(*)::TEXT
FROM connected_devices
UNION ALL
SELECT
  'Active Connected Devices',
  COUNT(*)::TEXT
FROM connected_devices
WHERE status = 'connected';

-- =====================================================
-- 15. PERFORMANCE: Slowest OAuth Completions
-- =====================================================

-- Find flows that took unusually long to complete
SELECT
  provider,
  state,
  ROUND(EXTRACT(EPOCH FROM (updated_at - created_at)), 2) as completion_seconds,
  created_at,
  updated_at
FROM device_auth_flows
WHERE status = 'completed'
  AND created_at > NOW() - INTERVAL '7 days'
ORDER BY completion_seconds DESC
LIMIT 10;

-- =====================================================
-- 16. AUDIT: All Activity for a Specific Provider
-- =====================================================

-- Replace 'google_fit' with any provider
SELECT
  'Auth Flows Created' as activity,
  COUNT(*)::TEXT as count,
  MIN(created_at)::TEXT as first_occurrence,
  MAX(created_at)::TEXT as last_occurrence
FROM device_auth_flows
WHERE provider = 'google_fit'
UNION ALL
SELECT
  'Successful Connections',
  COUNT(*)::TEXT,
  MIN(connected_at)::TEXT,
  MAX(connected_at)::TEXT
FROM connected_devices
WHERE provider = 'google_fit'
  AND status = 'connected';

-- =====================================================
-- 17. VERIFICATION: RLS Policies Working
-- =====================================================

-- This should only work if you're authenticated
-- and should only return YOUR auth flows
SELECT
  'Your Recent Auth Flows' as info,
  COUNT(*) as count
FROM device_auth_flows
WHERE created_at > NOW() - INTERVAL '24 hours';

-- =====================================================
-- NOTES
-- =====================================================

/*
HOW TO USE THIS FILE:

1. VERIFICATION (Queries 1-2):
   Run these immediately after deployment to verify the RPC function exists

2. TESTING (Query 3):
   Test creating an auth flow as an authenticated user

3. MONITORING (Queries 4-11):
   Run these regularly to monitor OAuth performance and success rates

4. DEBUG (Queries 12-13):
   Use when investigating specific issues or user reports

5. HEALTH CHECK (Query 14):
   Quick overview of system health

6. CLEANUP (Query 11):
   Run manually if you notice many expired flows

EXPECTED RESULTS AFTER FIX:

- Success rate should be > 90% (most flows complete successfully)
- Average completion time should be 30-120 seconds (typical user OAuth flow)
- Very few expired flows (< 5% of total)
- No pending flows older than 10 minutes (unless user is actively in OAuth flow)

RED FLAGS:

- Success rate < 50%: Something is wrong with OAuth callback
- Many expired flows: Users are not completing OAuth (UX issue or callback error)
- Completion time > 300 seconds: Performance issue or users getting confused

*/
