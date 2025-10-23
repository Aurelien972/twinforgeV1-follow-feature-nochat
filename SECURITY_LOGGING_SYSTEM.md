# Security Logging System - Sprint 3 Phase 4

This document describes the comprehensive security logging and session management system implemented in Sprint 3.

## Overview

The security logging system provides:
- Centralized security event logging
- Concurrent session management and limiting
- Automated cleanup of old logs and expired sessions
- Real-time monitoring capabilities

## Database Tables

### security_logs

Main table for logging security events.

**Columns:**
- `id` (uuid, primary key)
- `user_id` (uuid, foreign key to auth.users)
- `event_type` (text) - Type of security event
- `severity` (text) - low|medium|high|critical
- `ip_address` (text) - Source IP address
- `user_agent` (text) - Browser/client information
- `edge_function` (text) - Which Edge Function triggered the event
- `event_data` (jsonb) - Additional event data
- `created_at` (timestamptz) - Event timestamp

**Indexes:**
- `user_id` - Fast lookup by user
- `event_type` - Filter by event type
- `severity` - Filter by severity
- `created_at` - Time-based queries
- `edge_function` - Filter by function

**RLS Policies:**
- Users can read their own logs
- Service role can insert logs (for Edge Functions)
- Service role can read all logs (for admin dashboard)

### session_tracking

Active session tracking for concurrent session limiting.

**Columns:**
- `id` (uuid, primary key)
- `user_id` (uuid, foreign key to auth.users)
- `session_token` (text, unique) - Session identifier
- `ip_address` (text) - Session IP
- `user_agent` (text) - Session client
- `last_activity` (timestamptz) - Last activity timestamp
- `created_at` (timestamptz) - Session creation time
- `expires_at` (timestamptz) - Session expiry time

**Indexes:**
- `user_id` - Fast lookup by user
- `session_token` - Fast session validation
- `expires_at` - Cleanup queries
- `last_activity` - Activity tracking

**RLS Policies:**
- Users can read their own sessions
- Service role can manage all sessions

## Database Functions

### log_security_event()

Logs a security event to the database.

```sql
SELECT public.log_security_event(
  p_user_id := 'user-uuid',
  p_event_type := 'input_validation_failed',
  p_severity := 'medium',
  p_ip_address := '192.168.1.1',
  p_user_agent := 'Mozilla/5.0...',
  p_edge_function := 'fridge-scan-vision',
  p_event_data := '{"error": "Invalid input"}'::jsonb
);
```

### cleanup_old_security_logs()

Removes security logs older than 90 days. Returns count of deleted rows.

**Scheduled:** Daily at 3:00 AM

### cleanup_expired_sessions()

Removes expired sessions. Returns count of deleted rows.

**Scheduled:** Every hour

### get_active_session_count()

Returns count of active sessions for a user.

```sql
SELECT public.get_active_session_count('user-uuid');
```

### update_session_activity()

Updates the last_activity timestamp for a session.

```sql
SELECT public.update_session_activity('session-token');
```

## TypeScript Utilities

### SecurityLogger

Class for logging security events from Edge Functions.

**Usage:**

```typescript
import { createClient } from 'npm:@supabase/supabase-js@2';
import { createSecurityLogger } from '../_shared/securityLogger.ts';

const supabase = createClient(supabaseUrl, supabaseServiceKey);
const securityLogger = createSecurityLogger(supabase);

// Log validation error
await securityLogger.logValidationError(
  'fridge-scan-vision',
  'Invalid image format',
  request,
  userId
);

// Log suspicious activity
await securityLogger.logSuspiciousActivity(
  'scan-commit',
  'Multiple rapid requests',
  request,
  userId
);

// Log rate limit exceeded
await securityLogger.logRateLimitExceeded(
  'meal-analyzer',
  request,
  userId
);

// Log unauthorized access
await securityLogger.logUnauthorizedAccess(
  'chat-ai',
  request,
  userId
);

// Log custom event
await securityLogger.logEvent({
  userId: 'user-uuid',
  eventType: 'session_created',
  severity: 'low',
  ipAddress: '192.168.1.1',
  userAgent: 'Mozilla/5.0...',
  edgeFunction: 'auth-function',
  eventData: { action: 'login' }
});
```

### SessionManager

Class for managing user sessions and enforcing limits.

**Usage:**

```typescript
import { createClient } from 'npm:@supabase/supabase-js@2';
import { createSessionManager } from '../_shared/sessionManager.ts';

const supabase = createClient(supabaseUrl, supabaseServiceKey);
const sessionManager = createSessionManager(supabase, {
  maxConcurrentSessions: 5,
  sessionExpiryHours: 24
});

// Create new session
const result = await sessionManager.createSession(userId, request);
if (result.success) {
  const sessionToken = result.sessionToken;
  // Store token in user's client
}

// Validate session
const validation = await sessionManager.validateSession(sessionToken);
if (validation.valid) {
  const userId = validation.userId;
  // Session is valid, proceed
}

// Update session activity
await sessionManager.updateSessionActivity(sessionToken);

// Terminate session
await sessionManager.terminateSession(sessionToken);

// Terminate all user sessions (on logout)
await sessionManager.terminateAllUserSessions(userId);

// Get active session count
const count = await sessionManager.getActiveSessionCount(userId);

// Get all user sessions
const sessions = await sessionManager.getUserSessions(userId);

// Cleanup expired sessions (manual)
const cleanedCount = await sessionManager.cleanupExpiredSessions();
```

## Security Event Types

| Event Type | Severity | Description |
|-----------|----------|-------------|
| `auth_login_success` | low | Successful login |
| `auth_login_failed` | medium | Failed login attempt |
| `auth_logout` | low | User logout |
| `validation_error` | medium | Input validation failure (already handled) |
| `input_validation_failed` | medium | Input validation failure |
| `rate_limit_exceeded` | medium | Rate limit hit |
| `suspicious_activity` | high | Suspicious behavior detected |
| `unauthorized_access` | high | Access without authorization |
| `token_expired` | low | Token expiration |
| `session_created` | low | New session created |
| `session_terminated` | low | Session ended |
| `csrf_validation_failed` | high | CSRF token validation failed |

## Severity Levels

- **low**: Normal operations, informational
- **medium**: Warning, potential issue
- **high**: Security concern, needs attention
- **critical**: Active attack, immediate action required

## Integration in Edge Functions

### Step 1: Import utilities

```typescript
import { createClient } from 'npm:@supabase/supabase-js@2';
import { createSecurityLogger } from '../_shared/securityLogger.ts';
```

### Step 2: Initialize security logger

```typescript
const supabaseUrl = Deno.env.get('SUPABASE_URL');
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
const supabase = createClient(supabaseUrl, supabaseServiceKey);
const securityLogger = createSecurityLogger(supabase);
```

### Step 3: Log validation errors

```typescript
const validationError = validateRequest(requestBody);
if (validationError) {
  await securityLogger.logValidationError(
    'function-name',
    validationError,
    req,
    user_id
  );

  return new Response(JSON.stringify({ error: validationError }), {
    status: 400,
    headers: corsHeaders
  });
}
```

## Already Integrated Functions

1. ✅ fridge-scan-vision - Vision AI for fridge scanning
2. ✅ scan-commit - Body scan data commit

## Monitoring and Analytics

Query examples for monitoring:

```sql
-- Failed validations in last 24 hours
SELECT user_id, event_type, COUNT(*)
FROM public.security_logs
WHERE severity = 'medium'
  AND event_type = 'input_validation_failed'
  AND created_at > now() - interval '24 hours'
GROUP BY user_id, event_type;

-- Suspicious activities
SELECT user_id, ip_address, event_data, created_at
FROM public.security_logs
WHERE severity = 'high'
  AND event_type = 'suspicious_activity'
ORDER BY created_at DESC;

-- Active sessions per user
SELECT user_id, COUNT(*) as session_count
FROM public.session_tracking
WHERE expires_at > now()
GROUP BY user_id
HAVING COUNT(*) > 3
ORDER BY session_count DESC;

-- Session activity patterns
SELECT
  DATE_TRUNC('hour', last_activity) as hour,
  COUNT(*) as active_sessions
FROM public.session_tracking
WHERE expires_at > now()
GROUP BY hour
ORDER BY hour DESC;
```

## Best Practices

1. **Always log validation failures** - Helps detect attack patterns
2. **Log suspicious activities** - Multiple rapid requests, unusual patterns
3. **Monitor session counts** - Detect credential sharing or attacks
4. **Review high severity events daily** - Quick response to threats
5. **Set up alerts** - Critical severity events should trigger notifications

## Automated Maintenance

- **Expired sessions cleanup**: Every hour
- **Old logs cleanup**: Daily at 3:00 AM (90-day retention)
- **Performance optimization**: Indexes ensure fast queries even with millions of logs

## Security Considerations

- All logging is asynchronous and non-blocking
- Failures in logging never block the main request flow
- Sensitive data is never logged in event_data
- IP addresses are logged for security analysis
- RLS ensures users can only see their own logs
- Service role has full access for admin monitoring

## Future Enhancements

- Real-time alerting system
- Dashboard for security monitoring
- Geolocation tracking for sessions
- Anomaly detection algorithms
- Integration with external SIEM systems
