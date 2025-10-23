# CSRF Integration Plan - Sprint 3 Phase 5.3

## Critical Functions Requiring CSRF Protection

Based on security analysis, these 7 Edge Functions require CSRF protection:

### 1. **scan-commit** ✅ (Security logging already integrated)
**Why:** Commits final body scan data to database
**Risk:** High - Could inject fake body data
**Operations:** Write to body_scans, user_profile
**Priority:** CRITICAL

### 2. **fridge-scan-vision** ✅ (Security logging already integrated)
**Why:** Processes fridge images and creates inventory
**Risk:** High - Could consume tokens with fake requests
**Operations:** Vision API calls, inventory creation
**Priority:** CRITICAL

### 3. **meal-analyzer**
**Why:** Analyzes meal photos and creates nutrition records
**Risk:** High - Could manipulate nutrition tracking
**Operations:** Vision API calls, meal records creation
**Priority:** HIGH

### 4. **chat-ai**
**Why:** AI chat interactions with user context
**Risk:** Medium-High - Could inject malicious prompts
**Operations:** OpenAI API calls with user context
**Priority:** HIGH

### 5. **create-checkout-session**
**Why:** Creates Stripe payment sessions
**Risk:** CRITICAL - Financial transactions
**Operations:** Stripe checkout creation
**Priority:** CRITICAL

### 6. **create-portal-session**
**Why:** Creates Stripe customer portal access
**Risk:** HIGH - Access to billing information
**Operations:** Stripe portal creation
**Priority:** HIGH

### 7. **wearable-oauth-callback**
**Why:** OAuth callback for wearable device connection
**Risk:** HIGH - Could connect unauthorized devices
**Operations:** OAuth token exchange, device linking
**Priority:** HIGH

## Integration Strategy

For each function, we will:

1. ✅ Validate CSRF token (if provided in header)
2. ✅ Validate origin/referer headers
3. ✅ Log failed CSRF validations to security_logs
4. ✅ Preserve all AI agent logic (ZERO modification)
5. ✅ Return clear error messages on validation failure

## Implementation Pattern

```typescript
import { createClient } from 'npm:@supabase/supabase-js@2';
import { createCSRFProtection } from '../_shared/csrfProtection.ts';

// Initialize
const supabase = createClient(supabaseUrl, supabaseServiceKey);
const csrfProtection = createCSRFProtection(supabase);

// Extract CSRF token from header
const csrfToken = req.headers.get('x-csrf-token');

// Validate (origin validation is automatic)
const validation = await csrfProtection.validateRequest(
  user_id,
  csrfToken,
  req,
  'function-name'
);

if (!validation.valid) {
  return new Response(JSON.stringify({
    error: 'CSRF validation failed',
    message: validation.error
  }), {
    status: 403,
    headers: corsHeaders
  });
}
```

## Priority Order

1. create-checkout-session (CRITICAL - Financial)
2. scan-commit (CRITICAL - Already has security logging)
3. fridge-scan-vision (CRITICAL - Already has security logging)
4. meal-analyzer (HIGH - Data integrity)
5. create-portal-session (HIGH - Financial access)
6. wearable-oauth-callback (HIGH - Device security)
7. chat-ai (HIGH - Prompt injection prevention)

## Header Requirements

Frontend must send:
- `x-csrf-token` header with valid token (optional but recommended)
- `origin` or `referer` header (automatic in browsers)

## Token Generation

Frontend should request CSRF tokens via new endpoint or include in auth response.
Tokens are valid for 60 minutes by default.

## Backward Compatibility

CSRF token validation is lenient:
- If no token provided, only origin validation is performed
- This allows gradual rollout without breaking existing clients
- Can be made stricter in Phase 2 deployment
