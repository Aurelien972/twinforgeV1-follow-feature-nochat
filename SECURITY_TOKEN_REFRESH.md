# Automatic Token Refresh - TwinForge

## Overview

The automatic token refresh system ensures users remain authenticated without interruption by proactively refreshing Supabase session tokens before they expire.

## How It Works

### Refresh Strategy

- **Timing**: Tokens are refreshed **5 minutes before expiration**
- **Monitoring**: Checks every 60 seconds for upcoming expiration
- **Safety**: Mutex locking prevents concurrent refresh attempts
- **Security**: Forces logout after 3 consecutive refresh failures

### Implementation Details

The token refresh system is implemented in `src/hooks/useTokenRefresh.ts` and integrated into the application providers at `src/app/providers/AppProviders.tsx`.

### Refresh Workflow

```
1. User logs in
   ↓
2. Hook monitors session expiration
   ↓
3. 5 minutes before expiry → Trigger refresh
   ↓
4. Call supabase.auth.refreshSession()
   ↓
5. Update session in userStore
   ↓
6. Schedule next refresh check
```

## Configuration Constants

```typescript
REFRESH_BEFORE_EXPIRY_MS = 5 * 60 * 1000;  // 5 minutes
MAX_REFRESH_FAILURES = 3;                   // Force logout threshold
REFRESH_CHECK_INTERVAL_MS = 60 * 1000;     // Check every minute
```

### Why 5 Minutes?

- Provides buffer time for network latency
- Prevents race conditions during API calls
- User won't notice the refresh happening
- Aligns with Supabase best practices

## Security Features

### 1. Mutex Locking

Prevents concurrent refresh attempts that could cause race conditions:

```typescript
if (isRefreshingRef.current) {
  logger.debug('TOKEN_REFRESH', 'Refresh already in progress, skipping');
  return false;
}
isRefreshingRef.current = true;
```

### 2. Failure Tracking

Monitors consecutive failures and forces logout if threshold exceeded:

```typescript
if (failureCount >= MAX_REFRESH_FAILURES) {
  logger.error('TOKEN_REFRESH', 'Max refresh failures reached, forcing logout');
  await supabase.auth.signOut();
  window.location.href = '/';
}
```

### 3. Comprehensive Logging

All refresh events are logged for security monitoring:

```typescript
logger.info('TOKEN_REFRESH', 'Token refreshed successfully', {
  expiresAt: new Date(session.expires_at * 1000).toISOString(),
  nextRefreshAt: nextRefresh.toISOString(),
});
```

## Hook API

### Usage

```typescript
const {
  isRefreshing,    // boolean: Is refresh currently in progress?
  lastRefresh,     // Date | null: When was the last successful refresh?
  nextRefreshAt,   // Date | null: When is the next refresh scheduled?
  failureCount,    // number: How many consecutive failures?
  manualRefresh,   // () => Promise<boolean>: Trigger manual refresh
} = useTokenRefresh();
```

### Manual Refresh

For testing or explicit refresh needs:

```typescript
const { manualRefresh } = useTokenRefresh();

// Trigger manual refresh
const success = await manualRefresh();
if (success) {
  console.log('Token refreshed successfully');
}
```

## Monitoring & Debugging

### Development Console

In development mode, you can monitor token refresh activity:

```javascript
// The hook logs all activity automatically
// Check browser console for:
// - TOKEN_REFRESH: Starting token refresh
// - TOKEN_REFRESH: Token refreshed successfully
// - TOKEN_REFRESH: Token refresh failed
```

### Log Levels

- **INFO**: Successful refreshes, initialization
- **DEBUG**: Refresh checks, skipped refreshes
- **ERROR**: Failures, forced logouts

### Example Logs

```
[INFO] TOKEN_REFRESH: Token refresh monitoring initialized {
  checkIntervalMinutes: 1,
  refreshBeforeExpiryMinutes: 5
}

[INFO] TOKEN_REFRESH: Token refreshed successfully {
  expiresAt: "2025-10-23T15:30:00.000Z",
  nextRefreshAt: "2025-10-23T15:25:00.000Z"
}

[ERROR] TOKEN_REFRESH: Token refresh failed {
  error: "Network request failed",
  failureCount: 1,
  willForceLogout: false
}
```

## Testing

### Manual Testing Checklist

- [ ] User stays logged in for 2+ hours without interruption
- [ ] Tokens refresh automatically before expiration
- [ ] No "Unauthorized" errors during long sessions
- [ ] Forced logout occurs after 3 consecutive failures
- [ ] Manual refresh works correctly

### Test Scenarios

#### 1. Normal Operation

1. Log in to the application
2. Leave tab open for 2 hours
3. Interact with features periodically
4. **Expected**: No authentication errors, seamless experience

#### 2. Network Failure Recovery

1. Log in to the application
2. Open DevTools → Network tab
3. Set throttling to "Offline"
4. Wait for refresh attempt to fail
5. Set throttling back to "Online"
6. **Expected**: Next refresh succeeds, user stays logged in

#### 3. Forced Logout

1. Log in to the application
2. Simulate 3 consecutive refresh failures (requires code modification)
3. **Expected**: User is logged out and redirected to login page

## Troubleshooting

### Issue: User gets logged out unexpectedly

**Possible Causes:**
- Network connectivity issues
- Supabase service interruption
- Expired refresh token (> 30 days old)

**Solution:**
- Check browser console for error logs
- Verify network connectivity
- Check Supabase service status
- User should log in again

### Issue: Token refresh not happening

**Possible Causes:**
- Hook not integrated into component tree
- Browser tab suspended (mobile Safari)
- JavaScript execution paused

**Solution:**
- Verify TokenRefreshManager is in AppProviders
- Check browser console for logs
- Test in different browsers

### Issue: Multiple refresh attempts

**Possible Causes:**
- Mutex lock not working correctly
- Multiple hook instances

**Solution:**
- Verify only one TokenRefreshManager instance exists
- Check for duplicate AppProviders

## Best Practices

### DO ✅

- Use the hook at the app-level only (AppProviders)
- Monitor logs in development to ensure refresh is working
- Test long sessions before production deployment
- Keep refresh timing conservative (5 minutes before expiry)

### DON'T ❌

- Don't use the hook in multiple components
- Don't modify refresh timing without testing
- Don't ignore refresh failure logs
- Don't disable automatic refresh in production

## Integration with Other Features

### User Store

The token refresh hook updates the session in the user store:

```typescript
setSession(data.session);
```

This ensures all components using `useUserStore()` have access to the latest session data.

### Supabase Client

The refresh happens through the official Supabase client:

```typescript
const { data, error } = await supabase.auth.refreshSession();
```

This ensures compatibility with all Supabase features and maintains proper authentication state.

## Future Enhancements

### Phase 1 (Current)
- [x] Automatic refresh 5 minutes before expiry
- [x] Mutex locking to prevent concurrent refreshes
- [x] Failure tracking with forced logout
- [x] Comprehensive logging

### Phase 2 (Future)
- [ ] Exponential backoff on refresh failures
- [ ] User notification before forced logout
- [ ] Refresh token rotation tracking
- [ ] Analytics for refresh success/failure rates

### Phase 3 (Future)
- [ ] Offline-first refresh strategy
- [ ] Predictive refresh based on user activity
- [ ] Multi-tab synchronization
- [ ] Custom refresh timing per user role

## Related Documentation

- [Environment Configuration](./DEPLOYMENT.md)
- [Content Security Policy](./SECURITY_CSP.md)
- [Supabase Authentication](https://supabase.com/docs/guides/auth)

## Support

For issues or questions about token refresh:

1. Check browser console for error logs
2. Review this documentation
3. Test with manual refresh
4. Contact development team if issue persists
