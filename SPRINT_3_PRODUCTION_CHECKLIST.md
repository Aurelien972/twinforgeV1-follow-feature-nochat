# Sprint 3 - Production Deployment Checklist

Complete checklist for deploying Sprint 3 security infrastructure to production.

---

## ✅ Pre-Deployment Verification

### Database Migrations

- [x] Migration 20251023120000 - Security logs system ready
- [x] Migration 20251023130000 - Session cleanup cron ready
- [x] Migration 20251023140000 - CSRF tokens system ready
- [ ] Run migrations on production database
- [ ] Verify all tables created successfully
- [ ] Verify all RLS policies active
- [ ] Verify all functions created
- [ ] Verify all cron jobs scheduled

### Edge Functions

#### Critical Functions (CSRF Protected)
- [x] create-checkout-session - Code ready
- [x] create-portal-session - Code ready
- [x] meal-analyzer - Code ready
- [x] chat-ai - Code ready
- [x] wearable-oauth-callback - Code ready
- [x] fridge-scan-vision - Code ready
- [x] scan-commit - Code ready

#### Deployment Steps
- [ ] Deploy all 7 protected functions
- [ ] Verify CORS headers include X-CSRF-Token
- [ ] Test CSRF validation with valid token
- [ ] Test CSRF validation with invalid token
- [ ] Test origin validation
- [ ] Monitor security logs for validation events

### Build Verification

- [x] Build successful (23.24s)
- [x] No TypeScript errors
- [x] No new runtime warnings
- [x] All imports resolved
- [x] All utilities accessible

---

## 🔧 Configuration Requirements

### Environment Variables

**No new environment variables required!** ✅

All security infrastructure uses existing configuration:
- `SUPABASE_URL` - Already configured
- `SUPABASE_SERVICE_ROLE_KEY` - Already configured
- `ALLOWED_ORIGIN` - Optional, defaults to SUPABASE_URL

### Database Configuration

**Automatic via migrations:**
- Tables created with RLS
- Functions created
- Indexes created
- Cron jobs scheduled

**Manual verification required:**
- [ ] Verify cron extension enabled (`pg_cron`)
- [ ] Verify cron jobs scheduled: `SELECT * FROM cron.job;`
- [ ] Verify database timezone correct

---

## 🎨 Frontend Integration Requirements

### CSRF Token Management

#### 1. Generate Token on Authentication

```typescript
// After successful login/signup
const { data: token } = await supabase.rpc('generate_csrf_token', {
  p_user_id: user.id,
  p_validity_minutes: 60
});

// Store token in memory or session storage (NOT localStorage for security)
sessionStorage.setItem('csrf_token', token);
```

#### 2. Include Token in Requests

```typescript
// For protected endpoints
const csrfToken = sessionStorage.getItem('csrf_token');

await fetch('/api/endpoint', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${session.access_token}`,
    'X-CSRF-Token': csrfToken, // Required for CSRF-protected functions
    'Content-Type': 'application/json',
  },
  body: JSON.stringify(data)
});
```

#### 3. Handle CSRF Errors

```typescript
if (response.status === 403) {
  const error = await response.json();
  if (error.error === 'CSRF validation failed') {
    // Token expired or invalid - regenerate
    const { data: newToken } = await supabase.rpc('generate_csrf_token', {
      p_user_id: user.id
    });
    sessionStorage.setItem('csrf_token', newToken);
    // Retry request with new token
  }
}
```

#### 4. Token Refresh Strategy

```typescript
// Refresh token every 30 minutes (default validity: 60 minutes)
setInterval(async () => {
  const { data: newToken } = await supabase.rpc('generate_csrf_token', {
    p_user_id: user.id
  });
  sessionStorage.setItem('csrf_token', newToken);
}, 30 * 60 * 1000);
```

### Functions Requiring CSRF Token

**CRITICAL (Must have token):**
- `create-checkout-session` - Financial
- `create-portal-session` - Financial

**HIGH (Recommended):**
- `meal-analyzer` - Data integrity
- `chat-ai` - Prompt injection prevention
- `fridge-scan-vision` - Token consumption
- `scan-commit` - Body data integrity

**ORIGIN ONLY (No token needed):**
- `wearable-oauth-callback` - OAuth callbacks

### Gradual Rollout Strategy

**Phase 1: Lenient Mode (Current)**
- CSRF token optional but recommended
- Origin validation enforced
- Allows gradual frontend integration
- Monitor security logs for patterns

**Phase 2: Strict Mode (Future)**
- CSRF token required for all critical functions
- Origin validation enforced
- Reject requests without valid token
- Deploy after frontend fully integrated

---

## 📊 Monitoring & Alerting

### Security Logs Monitoring

#### Dashboard Queries

```sql
-- Failed CSRF validations (last 24 hours)
SELECT
  user_id,
  edge_function,
  event_data->>'error' as error,
  created_at
FROM security_logs
WHERE event_type = 'csrf_validation_failed'
  AND created_at > now() - interval '24 hours'
ORDER BY created_at DESC;

-- Validation failures by function
SELECT
  edge_function,
  COUNT(*) as failure_count
FROM security_logs
WHERE event_type = 'input_validation_failed'
  AND created_at > now() - interval '24 hours'
GROUP BY edge_function
ORDER BY failure_count DESC;

-- High severity events
SELECT *
FROM security_logs
WHERE severity = 'high'
  AND created_at > now() - interval '24 hours'
ORDER BY created_at DESC;

-- Suspicious activity patterns
SELECT
  user_id,
  ip_address,
  COUNT(*) as event_count,
  array_agg(DISTINCT edge_function) as functions
FROM security_logs
WHERE event_type = 'suspicious_activity'
  AND created_at > now() - interval '24 hours'
GROUP BY user_id, ip_address
HAVING COUNT(*) > 5
ORDER BY event_count DESC;
```

#### Recommended Alerts

1. **Critical Events**
   - Trigger: severity = 'critical'
   - Action: Immediate notification
   - Threshold: Any occurrence

2. **CSRF Validation Failures**
   - Trigger: event_type = 'csrf_validation_failed'
   - Action: Monitor for patterns
   - Threshold: >10 failures/hour from same IP

3. **Validation Errors Spike**
   - Trigger: event_type = 'input_validation_failed'
   - Action: Check for attack patterns
   - Threshold: >100 failures/hour

4. **Session Count Anomaly**
   - Trigger: active_session_count > 10 per user
   - Action: Potential account compromise
   - Threshold: >10 concurrent sessions

### Performance Monitoring

```sql
-- Cron job execution history
SELECT
  jobname,
  schedule,
  last_run,
  next_run,
  status
FROM cron.job_run_details
ORDER BY last_run DESC
LIMIT 20;

-- Table sizes
SELECT
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables
WHERE tablename IN ('security_logs', 'session_tracking', 'csrf_tokens')
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Active sessions count
SELECT COUNT(*) as active_sessions
FROM session_tracking
WHERE expires_at > now();

-- Active CSRF tokens count
SELECT COUNT(*) as active_tokens
FROM csrf_tokens
WHERE expires_at > now()
  AND used = false;
```

---

## 🧪 Testing Checklist

### Security Logging Tests

- [ ] Test validation error logging
  - [ ] Send invalid request to fridge-scan-vision
  - [ ] Verify error logged in security_logs
  - [ ] Verify severity = 'medium'

- [ ] Test CSRF failure logging
  - [ ] Send request without CSRF token to create-checkout-session
  - [ ] Verify failure logged with severity = 'high'
  - [ ] Verify event_type = 'csrf_validation_failed'

### CSRF Protection Tests

#### create-checkout-session
- [ ] Test with valid CSRF token → Success
- [ ] Test without CSRF token → Origin validation only
- [ ] Test with invalid token → 403 error
- [ ] Test with expired token → 403 error
- [ ] Test with wrong origin → 403 error

#### create-portal-session
- [ ] Test with valid CSRF token → Success
- [ ] Test without CSRF token → Origin validation only
- [ ] Test with invalid token → 403 error

#### meal-analyzer
- [ ] Test with valid CSRF token → Success
- [ ] Test without CSRF token → Origin validation only
- [ ] Verify AI processing still works correctly

#### chat-ai
- [ ] Test with valid CSRF token → Success
- [ ] Test without CSRF token → Origin validation only
- [ ] Verify AI responses unchanged

#### wearable-oauth-callback
- [ ] Test OAuth callback flow → Success
- [ ] Test with wrong origin → 403 error
- [ ] Verify device linking still works

### Session Management Tests

- [ ] Test session creation
  - [ ] Create session for user
  - [ ] Verify session in session_tracking table
  - [ ] Verify session token returned

- [ ] Test concurrent session limit
  - [ ] Create 5 sessions → Success
  - [ ] Create 6th session → Error (max limit)
  - [ ] Verify error message clear

- [ ] Test session validation
  - [ ] Validate valid session → Success
  - [ ] Validate expired session → Failure
  - [ ] Validate non-existent session → Failure

- [ ] Test session cleanup
  - [ ] Wait for expired session
  - [ ] Verify cron job removes it
  - [ ] Check cleanup_expired_sessions() function

### Integration Tests

- [ ] Test complete flow: Login → Get token → Make request
- [ ] Test token refresh flow
- [ ] Test logout → All sessions terminated
- [ ] Test origin validation with different domains
- [ ] Test CORS headers present in all responses

---

## 🚀 Deployment Steps

### 1. Database Deployment

```bash
# Connect to production database
psql $DATABASE_URL

# Run migrations in order
\i supabase/migrations/20251023120000_create_security_logs_system.sql
\i supabase/migrations/20251023130000_add_session_cleanup_cron.sql
\i supabase/migrations/20251023140000_create_csrf_tokens_system.sql

# Verify
\dt public.*                     # List tables
\df public.*                     # List functions
SELECT * FROM cron.job;          # Check cron jobs
```

### 2. Edge Functions Deployment

```bash
# Deploy protected functions (example using Supabase CLI)
supabase functions deploy create-checkout-session
supabase functions deploy create-portal-session
supabase functions deploy meal-analyzer
supabase functions deploy chat-ai
supabase functions deploy wearable-oauth-callback
supabase functions deploy fridge-scan-vision
supabase functions deploy scan-commit

# Verify deployment
supabase functions list
```

### 3. Verification

```bash
# Test database functions
psql $DATABASE_URL -c "SELECT public.generate_csrf_token('test-user-id', 60);"
psql $DATABASE_URL -c "SELECT public.get_active_session_count('test-user-id');"

# Check cron jobs scheduled
psql $DATABASE_URL -c "SELECT * FROM cron.job;"

# Monitor first security events
psql $DATABASE_URL -c "SELECT * FROM security_logs ORDER BY created_at DESC LIMIT 10;"
```

### 4. Post-Deployment Monitoring

- [ ] Monitor security_logs for first 24 hours
- [ ] Check for any unexpected validation failures
- [ ] Verify cron jobs executing successfully
- [ ] Monitor table sizes and growth
- [ ] Check Edge Function logs for errors
- [ ] Verify no impact on AI agent performance

---

## 🔄 Rollback Plan

### If Issues Detected

1. **Disable CSRF validation temporarily**
   ```typescript
   // In affected Edge Functions, comment out CSRF validation
   // Keep origin validation active
   // const csrfValidation = await csrfProtection.validateRequest(...);
   // if (!csrfValidation.valid) { return ... }
   ```

2. **Database rollback**
   ```sql
   -- Drop cron jobs
   SELECT cron.unschedule('cleanup-expired-sessions');
   SELECT cron.unschedule('cleanup-old-security-logs');
   SELECT cron.unschedule('cleanup-expired-csrf-tokens');

   -- Drop tables (if needed - CAREFUL: loses data!)
   -- DROP TABLE IF EXISTS csrf_tokens CASCADE;
   -- DROP TABLE IF EXISTS session_tracking CASCADE;
   -- DROP TABLE IF EXISTS security_logs CASCADE;
   ```

3. **Function rollback**
   - Redeploy previous Edge Function versions
   - Remove CSRF headers from CORS configuration
   - Monitor for restoration of normal operation

---

## 📋 Success Criteria

### Deployment Successful If

- ✅ All migrations applied without errors
- ✅ All Edge Functions deployed successfully
- ✅ All tests passing
- ✅ Security logs receiving events
- ✅ CSRF tokens generating correctly
- ✅ Session management working
- ✅ No increase in error rates
- ✅ AI agents functioning normally
- ✅ User experience unchanged

### Metrics to Monitor (First Week)

1. **Security Logs**
   - Total events logged
   - Failed validations count
   - High severity events
   - No critical events

2. **Performance**
   - Edge Function response times unchanged
   - Database query performance stable
   - Cron jobs completing successfully
   - No timeout issues

3. **User Experience**
   - No increase in failed requests
   - Token refresh working smoothly
   - CSRF errors minimal (during frontend integration)
   - No complaints about access issues

---

## 📞 Support & Troubleshooting

### Common Issues

**Issue: CSRF validation failing for all requests**
- Check: CSRF tokens table populated
- Check: generate_csrf_token() function working
- Check: Frontend sending X-CSRF-Token header
- Fix: Regenerate token, verify header name case-sensitive

**Issue: Origin validation failing**
- Check: Request has origin or referer header
- Check: Origin matches SUPABASE_URL or ALLOWED_ORIGIN
- Check: CORS configuration correct
- Fix: Add domain to allowed origins

**Issue: Cron jobs not running**
- Check: pg_cron extension enabled
- Check: Cron jobs scheduled: `SELECT * FROM cron.job;`
- Check: Database timezone correct
- Fix: Reschedule jobs, check permissions

**Issue: Security logs growing too fast**
- Check: Abnormal validation failure rate
- Check: Attack pattern detected
- Action: Investigate source IPs, block if needed
- Optimize: Reduce log retention period if needed

---

## ✅ Final Checklist

Before marking deployment complete:

- [ ] All database migrations applied
- [ ] All Edge Functions deployed
- [ ] All tests passing
- [ ] Frontend integration started
- [ ] Monitoring dashboard configured
- [ ] Alerts configured
- [ ] Documentation shared with team
- [ ] Rollback plan tested
- [ ] 24-hour monitoring period completed
- [ ] No critical issues detected

---

*Sprint 3 Production Deployment Checklist - v1.0*
