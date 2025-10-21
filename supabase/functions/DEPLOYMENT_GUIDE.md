# Edge Functions Deployment Guide

## Overview
This guide explains how to deploy the updated Supabase Edge Functions with fixed CORS and import issues.

## Fixed Functions

The following edge functions have been updated with corrected imports and CORS handling:

### Critical Functions (Deploy These First)
1. **activity-progress-generator** - AI-powered activity insights generation
2. **wearable-sync** - Wearable device data synchronization
3. **enrich-activity-wearable** - Activity enrichment with biometric data
4. **wearable-oauth-callback** - OAuth callback handler for device connections
5. **process-enrichment-queue** - Background queue processor for activity enrichment

### What Was Fixed

#### 1. CORS Headers (activity-progress-generator)
- Simplified OPTIONS preflight response
- Ensured consistent CORS headers across all responses
- Status: 204 for OPTIONS requests

#### 2. Supabase Dynamic Imports
**Problem:** Dynamic imports using `npm:@supabase/supabase-js@2.54.0` fail in Deno edge runtime
**Solution:** Changed to `https://esm.sh/@supabase/supabase-js@2.54.0`

**Files Updated:**
- `wearable-sync/index.ts` (line 37)
- `enrich-activity-wearable/index.ts` (line 34)
- `wearable-oauth-callback/index.ts` (line 89)
- `process-enrichment-queue/index.ts` (line 39)

## Deployment Instructions

### Prerequisites
- Supabase CLI installed: `npm install -g supabase`
- Authenticated with Supabase: `supabase login`
- Project linked: `supabase link --project-ref YOUR_PROJECT_REF`

### Deploy Individual Function
```bash
# Deploy activity insights function
supabase functions deploy activity-progress-generator

# Deploy wearable sync function
supabase functions deploy wearable-sync

# Deploy activity enrichment function
supabase functions deploy enrich-activity-wearable

# Deploy OAuth callback handler
supabase functions deploy wearable-oauth-callback

# Deploy queue processor
supabase functions deploy process-enrichment-queue
```

### Deploy All Functions
```bash
# Deploy all functions at once
supabase functions deploy
```

### Verify Deployment
```bash
# Check function status
supabase functions list

# View function logs
supabase functions logs activity-progress-generator --tail
```

## Testing After Deployment

### Test Activity Insights Tab
1. Navigate to Activity page
2. Click on "Insights" tab
3. Verify insights load without CORS errors
4. Check for "Mode Analyse Locale" banner (should not appear if edge function works)
5. Confirm AI-generated insights display properly

### Test Wearable Sync
1. Navigate to Settings → Connected Devices
2. Connect a wearable device
3. Click "Sync Now" button
4. Verify sync completes without errors
5. Check that activity data appears enriched with biometric metrics

### Test Progression Tab
1. Navigate to Activity → Progression
2. Verify charts and visualizations load
3. Change time period (Week/Month/Quarter)
4. Confirm data updates correctly

## Current Status

### ✅ Code Fixed (Local Files)
- All edge function code has been updated
- CORS headers corrected
- Import statements fixed for Deno compatibility

### ⏳ Deployment Required
The fixes are in the local codebase but **NOT YET DEPLOYED** to Supabase.
The live edge functions at `https://kwipydbtjagypocpvbwn.supabase.co/functions/v1/` still have the old code.

### 🔄 Fallback Working
The frontend correctly falls back to local processing when edge functions fail.
Users can still use the Insights tab with locally-generated insights.

## Environment Variables Required

Ensure these environment variables are set in Supabase Dashboard:

```bash
OPENAI_API_KEY=sk-...           # For AI insights generation
SUPABASE_URL=https://...        # Auto-populated
SUPABASE_SERVICE_ROLE_KEY=...   # Auto-populated
```

## Troubleshooting

### CORS Errors Persist After Deployment
1. Clear browser cache
2. Hard refresh (Ctrl+Shift+R or Cmd+Shift+R)
3. Check function logs for actual errors
4. Verify OPTIONS request returns 204 status

### Import Errors in Logs
1. Verify esm.sh URLs are correct
2. Check Deno runtime version compatibility
3. Ensure no `npm:` prefix in dynamic imports

### Function Not Found
1. Verify deployment succeeded: `supabase functions list`
2. Check project reference is correct
3. Ensure function is enabled in Supabase dashboard

## Performance Optimization

### Caching Strategy
The edge functions implement intelligent caching:
- **7 days analysis**: 24h cache
- **30 days analysis**: 7 days cache
- **90 days analysis**: 14 days cache

This minimizes OpenAI API costs while keeping insights fresh.

### Cost Monitoring
Track AI analysis costs in the `ai_analysis_jobs` table:
```sql
SELECT
  DATE(created_at) as date,
  COUNT(*) as analyses,
  SUM((result_payload->>'costUsd')::numeric) as total_cost
FROM ai_analysis_jobs
WHERE analysis_type = 'trend_analysis'
GROUP BY DATE(created_at)
ORDER BY date DESC
LIMIT 30;
```

## Next Steps

1. **Deploy the functions** using the commands above
2. **Test thoroughly** using the testing checklist
3. **Monitor logs** for any remaining issues
4. **Verify costs** are within expected ranges

## Support

If issues persist after deployment:
1. Check Supabase function logs
2. Verify environment variables
3. Test with curl to isolate frontend vs backend issues
4. Review CORS configuration in Supabase dashboard
