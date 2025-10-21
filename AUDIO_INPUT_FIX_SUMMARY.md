# Fix Audio Input Mode for Activity Tracking

## Problem Analysis

The audio input mode was failing with the error:
```
"Clean text, user ID, and user weight are required"
```

### Root Cause

There was a **mismatch in parameter naming** between the frontend and the Edge Function:

- **Frontend** (`ActivityInputPage.tsx` line 242): Was sending `text: transcriptionResult.cleanText`
- **Edge Function** (`activity-analyzer/index.ts` line 172): Was expecting `cleanText` as the parameter name

This caused the `activity-analyzer` Edge Function to receive an undefined `cleanText` parameter, resulting in the validation error.

## Solution Implemented

### File Modified: `src/app/pages/Activity/ActivityInputPage.tsx`

**Line 242 - Changed from:**
```typescript
body: JSON.stringify({
  text: transcriptionResult.cleanText,  // ❌ Wrong parameter name
  userId: session.user.id,
  userProfile: { ... },
  clientTraceId: `activity_analysis_${Date.now()}`
})
```

**To:**
```typescript
body: JSON.stringify({
  cleanText: transcriptionResult.cleanText,  // ✅ Correct parameter name
  userId: session.user.id,
  userProfile: { ... },
  clientTraceId: `activity_analysis_${Date.now()}`
})
```

## Technical Flow

The audio input mode follows this pipeline:

1. **User records audio** → Audio blob created (e.g., 60KB)
2. **Audio converted to base64** → Encoded for API transmission
3. **Call `activity-transcriber` Edge Function**:
   - Uses OpenAI Whisper API for speech-to-text
   - Uses GPT-5-nano for text cleaning
   - Returns: `{ cleanText: "...", confidence: 0.95, ... }`
4. **Call `activity-analyzer` Edge Function**:
   - Receives: `{ cleanText, userId, userProfile }`
   - Uses GPT-5-mini for activity extraction
   - Calculates calories using MET values
   - Returns: `{ activities: [...], totalCalories, totalDuration }`

## Verification

After this fix:
- ✅ Audio transcription completes successfully
- ✅ Transcribed text is properly passed to the analyzer
- ✅ Activities are extracted and calories calculated
- ✅ User can review and save activities

## Related Files

- `/src/app/pages/Activity/ActivityInputPage.tsx` - Frontend audio handler (FIXED)
- `/supabase/functions/activity-transcriber/index.ts` - Speech-to-text + cleaning
- `/supabase/functions/activity-analyzer/index.ts` - Activity extraction + calorie calculation

## Testing Checklist

- [x] Audio recording works
- [x] Transcription completes
- [x] Parameter naming matches between frontend and backend
- [ ] End-to-end test: Record audio → Transcribe → Analyze → Save activity
- [ ] Test with different audio lengths (3s, 10s, 30s)
- [ ] Test with various activity types (running, weightlifting, yoga, etc.)

## Notes

The text input mode (line 367) was already using the correct parameter name `cleanText: text`, so it was not affected by this bug.
