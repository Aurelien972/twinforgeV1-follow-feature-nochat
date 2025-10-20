# Google Fit OAuth Connection - Fix Deployment Guide

## Problem Fixed

**Issue**: Users received a "400 Bad Request" error when trying to connect Google Fit devices in production.

**Root Cause**: The frontend was generating an OAuth `state` parameter and redirecting to Google, but never creating a corresponding record in the `device_auth_flows` database table. When Google redirected back to the callback function, it couldn't find the state parameter in the database, resulting in a 400 error.

## Solution Implemented

### 1. Database Migration: RPC Function for OAuth Flow Initialization

**File**: `/supabase/migrations/20251020170000_create_oauth_flow_init_function.sql`

**What it does**:
- Creates a PostgreSQL function `create_device_auth_flow(p_provider, p_redirect_uri)` that:
  - Validates the user is authenticated
  - Generates a secure state parameter (UUID)
  - Stores it in the `device_auth_flows` table
  - Returns the state and expiration timestamp to the frontend
  - Automatically cleans up expired auth flows for the same user/provider

**Benefits**:
- Secure state management
- Prevents database bloat from abandoned OAuth attempts
- Proper audit trail of all OAuth flows
- Simple and fast (no need for separate Edge Function)

### 2. Frontend Update: ConnectedDevicesTab OAuth Flow

**File**: `/src/app/pages/Settings/ConnectedDevicesTab.tsx`

**Changes**:
- Made `handleConnectDevice` an `async` function
- Added call to `supabase.rpc('create_device_auth_flow')` before redirecting to OAuth
- Uses the state parameter returned from the database instead of generating it locally
- Added proper error handling with user-friendly messages
- Added detailed logging for debugging

**Flow**:
1. User clicks "Connect" for Google Fit
2. Frontend calls RPC function to create auth flow record
3. Database returns secure state parameter
4. Frontend builds OAuth URL with this state
5. User is redirected to Google OAuth
6. Google redirects back with code and state
7. Callback function finds state in database and completes connection

### 3. Edge Function Enhancement: Better Error Messages

**File**: `/supabase/functions/wearable-oauth-callback/index.ts`

**Changes**:
- Improved error logging when state verification fails
- Added user-friendly error messages in French
- Included technical details for debugging
- Better handling of expired states

## Deployment Steps

### Step 1: Deploy Database Migration

The migration needs to be applied to your Supabase database:

```bash
# If using Supabase CLI locally
supabase db push

# Or apply directly in Supabase Dashboard:
# 1. Go to SQL Editor
# 2. Copy content of migration file
# 3. Execute the SQL
```

**Verification**:
```sql
-- Check that the function exists
SELECT proname, prosrc
FROM pg_proc
WHERE proname = 'create_device_auth_flow';

-- Test the function
SELECT create_device_auth_flow('google_fit', 'https://example.com/callback');
```

### Step 2: Redeploy Edge Function (Optional but Recommended)

The wearable-oauth-callback function has been improved with better error messages:

```bash
# Deploy the callback function
supabase functions deploy wearable-oauth-callback
```

### Step 3: Deploy Frontend Changes

Deploy the updated ConnectedDevicesTab component:

```bash
# Build and deploy your frontend (e.g., Netlify)
npm run build
# Then deploy via your CI/CD or manually
```

### Step 4: Verify Environment Variables

Ensure these are set in your environment:

**Frontend (.env)**:
```env
VITE_SUPABASE_URL=https://kwipydbtjagypocpvbwn.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
VITE_GOOGLE_OAUTH_CLIENT_ID=156410607041-k8g4ft9iblbhn5g3r92stc144mgrcrku.apps.googleusercontent.com
```

**Supabase Edge Functions (Secrets)**:
```
GOOGLE_FIT_CLIENT_ID=156410607041-k8g4ft9iblbhn5g3r92stc144mgrcrku.apps.googleusercontent.com
GOOGLE_FIT_CLIENT_SECRET=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
```

## Testing the Fix

### Test in Development

1. Go to Settings → Connected Devices
2. Click "Connect" for Google Fit
3. Check browser console for logs:
   - "Creating OAuth flow in database"
   - "Auth flow created successfully"
   - "Redirecting to OAuth provider"
4. Complete Google OAuth flow
5. Verify you're redirected back successfully
6. Check device appears in connected devices list

### Test in Production

1. Deploy all changes
2. Clear browser cache and local storage
3. Open Settings → Connected Devices in production
4. Click "Connect" for Google Fit
5. Complete OAuth flow
6. Verify successful connection

### Verify Database Records

```sql
-- Check auth flows are being created
SELECT * FROM device_auth_flows
WHERE created_at > NOW() - INTERVAL '1 hour'
ORDER BY created_at DESC;

-- Check connected devices
SELECT * FROM connected_devices
ORDER BY connected_at DESC;
```

## Troubleshooting

### Issue: RPC function not found

**Error**: `function create_device_auth_flow(text, text) does not exist`

**Solution**: Ensure migration has been applied. Run:
```sql
SELECT proname FROM pg_proc WHERE proname = 'create_device_auth_flow';
```

### Issue: Permission denied on function

**Error**: `permission denied for function create_device_auth_flow`

**Solution**: The migration includes proper grants. Verify:
```sql
SELECT grantee, privilege_type
FROM information_schema.routine_privileges
WHERE routine_name = 'create_device_auth_flow';
```

### Issue: Still getting 400 error

**Possible causes**:
1. Frontend changes not deployed
2. Browser cache (clear and retry)
3. Migration not applied
4. Edge function not redeployed (for better error messages)

**Debug steps**:
1. Check browser console for "Creating OAuth flow in database" log
2. Check Supabase logs for RPC call
3. Check Edge Function logs for callback errors
4. Verify state exists in database before redirect

## Rollback Plan

If issues occur, you can rollback safely:

### Rollback Database (NOT RECOMMENDED - keep data for audit)

```sql
-- Only if absolutely necessary
DROP FUNCTION IF EXISTS create_device_auth_flow(TEXT, TEXT);
DROP FUNCTION IF EXISTS cleanup_expired_auth_flows();
```

### Rollback Frontend

Revert the ConnectedDevicesTab.tsx changes:
- Remove `supabase` import
- Change `handleConnectDevice` back to non-async
- Use `crypto.randomUUID()` directly instead of RPC call

**Note**: This will bring back the original 400 error. Only rollback if the fix causes worse issues.

## Monitoring

### Metrics to Watch

1. **OAuth Success Rate**: Monitor `device_auth_flows` table for completed flows
2. **Error Rate**: Check Edge Function logs for 400 errors
3. **Abandoned Flows**: Count pending flows that never complete

### Useful Queries

```sql
-- OAuth flow success rate (last 24 hours)
SELECT
  status,
  COUNT(*) as count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage
FROM device_auth_flows
WHERE created_at > NOW() - INTERVAL '24 hours'
GROUP BY status;

-- Average time from creation to completion
SELECT
  provider,
  AVG(EXTRACT(EPOCH FROM (updated_at - created_at))) as avg_seconds
FROM device_auth_flows
WHERE status = 'completed'
  AND created_at > NOW() - INTERVAL '7 days'
GROUP BY provider;

-- Expired flows that never completed
SELECT COUNT(*)
FROM device_auth_flows
WHERE status = 'pending'
  AND expires_at < NOW();
```

## Cleanup Maintenance

The migration includes a `cleanup_expired_auth_flows()` function. You can:

### Manual Cleanup
```sql
SELECT cleanup_expired_auth_flows();
```

### Scheduled Cleanup (Optional)

If you have pg_cron enabled:
```sql
-- Run cleanup every hour
SELECT cron.schedule(
  'cleanup-auth-flows',
  '0 * * * *',
  'SELECT cleanup_expired_auth_flows()'
);
```

Or create a scheduled Edge Function to call it periodically.

## Support

For issues or questions:
1. Check Supabase logs in Dashboard
2. Review browser console logs
3. Check this deployment guide
4. Consult `/docs/wearables/` documentation

## Summary

This fix resolves the OAuth 400 error by properly managing the state parameter lifecycle:
- **Before**: State generated in frontend, never stored in database → callback fails
- **After**: State generated by database function, properly stored → callback succeeds

The solution is production-ready, secure, and maintains proper audit trails of all OAuth attempts.
