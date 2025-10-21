-- Mock Google Fit Data for Testing User
-- User ID: d8ec065f-93f3-4806-9190-5c4c461200bb
--
-- This script inserts realistic mock data for:
-- - 1 Google Fit on Pixel 7 (connected, real device with EXACTLY 88 data records)
-- - 1 Google Fit Test Simulation (disconnected, for testing reconnection)
-- - 7 days of health data history for Pixel 7
-- - Multiple workout sessions
-- - Daily metrics (steps, calories, heart rate, distance)

-- =====================================================
-- 1. INSERT GOOGLE FIT ON PIXEL 7 (CONNECTED)
-- =====================================================

INSERT INTO connected_devices (
  id,
  user_id,
  provider,
  provider_user_id,
  display_name,
  device_type,
  status,
  scopes,
  last_sync_at,
  metadata,
  connected_at,
  created_at,
  updated_at
) VALUES (
  'google-fit-pixel7-001',
  'd8ec065f-93f3-4806-9190-5c4c461200bb',
  'google_fit',
  'google-fit-user-pixel7-67890',
  'Google Fit sur Pixel 7',
  'smartwatch',
  'connected',
  ARRAY['https://www.googleapis.com/auth/fitness.activity.read', 'https://www.googleapis.com/auth/fitness.heart_rate.read'],
  NOW() - INTERVAL '1 hour',
  jsonb_build_object(
    'device_model', 'Google Pixel 7',
    'os_version', 'Android 14',
    'google_fit_version', '2.84',
    'real_device', true,
    'total_records', 88
  ),
  NOW() - INTERVAL '10 days',
  NOW() - INTERVAL '10 days',
  NOW() - INTERVAL '1 hour'
) ON CONFLICT (id) DO UPDATE SET
  last_sync_at = NOW() - INTERVAL '1 hour',
  updated_at = NOW() - INTERVAL '1 hour',
  status = 'connected';

-- =====================================================
-- 2. INSERT GOOGLE FIT TEST SIMULATION (DISCONNECTED)
-- =====================================================

INSERT INTO connected_devices (
  id,
  user_id,
  provider,
  provider_user_id,
  display_name,
  device_type,
  status,
  scopes,
  last_sync_at,
  metadata,
  connected_at,
  created_at,
  updated_at
) VALUES (
  'google-fit-test-sim-001',
  'd8ec065f-93f3-4806-9190-5c4c461200bb',
  'google_fit',
  'google-fit-test-sim-88888',
  'Google Fit (Test Simulation)',
  'fitness_tracker',
  'disconnected',
  ARRAY['https://www.googleapis.com/auth/fitness.activity.read'],
  NOW() - INTERVAL '6 days',
  jsonb_build_object(
    'simulated', true,
    'test_device', true,
    'purpose', 'Test reconnection flow',
    'version', '1.0'
  ),
  NOW() - INTERVAL '18 days',
  NOW() - INTERVAL '18 days',
  NOW() - INTERVAL '6 days'
) ON CONFLICT (id) DO UPDATE SET
  status = 'disconnected',
  last_sync_at = NOW() - INTERVAL '6 days',
  updated_at = NOW() - INTERVAL '6 days';

-- =====================================================
-- 3. GOOGLE FIT PIXEL 7: EXACTLY 88 DATA RECORDS
-- =====================================================

-- STEPS DATA (7 daily records = 7 records)
INSERT INTO wearable_health_data (
  id, user_id, device_id, data_type, timestamp, value_numeric, unit, quality_score, raw_data, synced_at, created_at
) VALUES
  ('gfit-steps-1', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'steps', NOW() - INTERVAL '7 days' + INTERVAL '22 hours', 8234, 'steps', 94, jsonb_build_object('source', 'Google Fit Pixel 7', 'data_source', 'com.google.android.gms'), NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days'),
  ('gfit-steps-2', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'steps', NOW() - INTERVAL '6 days' + INTERVAL '22 hours', 11234, 'steps', 96, jsonb_build_object('source', 'Google Fit Pixel 7', 'data_source', 'com.google.android.gms'), NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days'),
  ('gfit-steps-3', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'steps', NOW() - INTERVAL '5 days' + INTERVAL '22 hours', 6789, 'steps', 92, jsonb_build_object('source', 'Google Fit Pixel 7', 'data_source', 'com.google.android.gms'), NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days'),
  ('gfit-steps-4', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'steps', NOW() - INTERVAL '4 days' + INTERVAL '22 hours', 9876, 'steps', 95, jsonb_build_object('source', 'Google Fit Pixel 7', 'data_source', 'com.google.android.gms'), NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days'),
  ('gfit-steps-5', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'steps', NOW() - INTERVAL '3 days' + INTERVAL '22 hours', 8567, 'steps', 93, jsonb_build_object('source', 'Google Fit Pixel 7', 'data_source', 'com.google.android.gms'), NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),
  ('gfit-steps-6', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'steps', NOW() - INTERVAL '2 days' + INTERVAL '22 hours', 10456, 'steps', 97, jsonb_build_object('source', 'Google Fit Pixel 7', 'data_source', 'com.google.android.gms'), NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
  ('gfit-steps-7', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'steps', NOW() - INTERVAL '1 day' + INTERVAL '22 hours', 9123, 'steps', 94, jsonb_build_object('source', 'Google Fit Pixel 7', 'data_source', 'com.google.android.gms'), NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day')
ON CONFLICT (id) DO NOTHING;

-- CALORIES DATA (7 daily records = 7 records)
INSERT INTO wearable_health_data (
  id, user_id, device_id, data_type, timestamp, value_numeric, unit, quality_score, raw_data, synced_at, created_at
) VALUES
  ('gfit-cal-1', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'calories', NOW() - INTERVAL '7 days' + INTERVAL '22 hours', 2145, 'kcal', 91, jsonb_build_object('source', 'Google Fit Pixel 7', 'active_calories', 512, 'bmr_calories', 1633), NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days'),
  ('gfit-cal-2', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'calories', NOW() - INTERVAL '6 days' + INTERVAL '22 hours', 2534, 'kcal', 93, jsonb_build_object('source', 'Google Fit Pixel 7', 'active_calories', 901, 'bmr_calories', 1633), NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days'),
  ('gfit-cal-3', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'calories', NOW() - INTERVAL '5 days' + INTERVAL '22 hours', 1978, 'kcal', 89, jsonb_build_object('source', 'Google Fit Pixel 7', 'active_calories', 345, 'bmr_calories', 1633), NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days'),
  ('gfit-cal-4', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'calories', NOW() - INTERVAL '4 days' + INTERVAL '22 hours', 2312, 'kcal', 92, jsonb_build_object('source', 'Google Fit Pixel 7', 'active_calories', 679, 'bmr_calories', 1633), NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days'),
  ('gfit-cal-5', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'calories', NOW() - INTERVAL '3 days' + INTERVAL '22 hours', 2198, 'kcal', 90, jsonb_build_object('source', 'Google Fit Pixel 7', 'active_calories', 565, 'bmr_calories', 1633), NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),
  ('gfit-cal-6', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'calories', NOW() - INTERVAL '2 days' + INTERVAL '22 hours', 2445, 'kcal', 94, jsonb_build_object('source', 'Google Fit Pixel 7', 'active_calories', 812, 'bmr_calories', 1633), NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
  ('gfit-cal-7', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'calories', NOW() - INTERVAL '1 day' + INTERVAL '22 hours', 2267, 'kcal', 91, jsonb_build_object('source', 'Google Fit Pixel 7', 'active_calories', 634, 'bmr_calories', 1633), NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day')
ON CONFLICT (id) DO NOTHING;

-- DISTANCE DATA (7 daily records = 7 records)
INSERT INTO wearable_health_data (
  id, user_id, device_id, data_type, timestamp, value_numeric, unit, quality_score, raw_data, synced_at, created_at
) VALUES
  ('gfit-dist-1', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'distance', NOW() - INTERVAL '7 days' + INTERVAL '22 hours', 6234, 'meters', 93, jsonb_build_object('source', 'Google Fit Pixel 7', 'activity_types', ARRAY['walking', 'running']), NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days'),
  ('gfit-dist-2', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'distance', NOW() - INTERVAL '6 days' + INTERVAL '22 hours', 8456, 'meters', 95, jsonb_build_object('source', 'Google Fit Pixel 7', 'activity_types', ARRAY['walking', 'running', 'cycling']), NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days'),
  ('gfit-dist-3', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'distance', NOW() - INTERVAL '5 days' + INTERVAL '22 hours', 5123, 'meters', 91, jsonb_build_object('source', 'Google Fit Pixel 7', 'activity_types', ARRAY['walking']), NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days'),
  ('gfit-dist-4', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'distance', NOW() - INTERVAL '4 days' + INTERVAL '22 hours', 7456, 'meters', 94, jsonb_build_object('source', 'Google Fit Pixel 7', 'activity_types', ARRAY['walking', 'running']), NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days'),
  ('gfit-dist-5', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'distance', NOW() - INTERVAL '3 days' + INTERVAL '22 hours', 6478, 'meters', 92, jsonb_build_object('source', 'Google Fit Pixel 7', 'activity_types', ARRAY['walking', 'running']), NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),
  ('gfit-dist-6', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'distance', NOW() - INTERVAL '2 days' + INTERVAL '22 hours', 7890, 'meters', 96, jsonb_build_object('source', 'Google Fit Pixel 7', 'activity_types', ARRAY['walking', 'running']), NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
  ('gfit-dist-7', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'distance', NOW() - INTERVAL '1 day' + INTERVAL '22 hours', 6890, 'meters', 93, jsonb_build_object('source', 'Google Fit Pixel 7', 'activity_types', ARRAY['walking', 'running']), NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day')
ON CONFLICT (id) DO NOTHING;

-- HEART RATE DATA (21 records: 3 per day for 7 days = 21 records)
-- Morning, Afternoon, Evening readings
INSERT INTO wearable_health_data (
  id, user_id, device_id, data_type, timestamp, value_numeric, unit, quality_score, raw_data, synced_at, created_at
) VALUES
  -- Day 7 ago
  ('gfit-hr-1a', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'heart_rate', NOW() - INTERVAL '7 days' + INTERVAL '8 hours', 62, 'bpm', 90, jsonb_build_object('source', 'Google Fit Pixel 7', 'time_of_day', 'morning'), NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days'),
  ('gfit-hr-1b', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'heart_rate', NOW() - INTERVAL '7 days' + INTERVAL '14 hours', 75, 'bpm', 88, jsonb_build_object('source', 'Google Fit Pixel 7', 'time_of_day', 'afternoon'), NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days'),
  ('gfit-hr-1c', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'heart_rate', NOW() - INTERVAL '7 days' + INTERVAL '20 hours', 68, 'bpm', 89, jsonb_build_object('source', 'Google Fit Pixel 7', 'time_of_day', 'evening'), NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days'),

  -- Day 6 ago
  ('gfit-hr-2a', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'heart_rate', NOW() - INTERVAL '6 days' + INTERVAL '8 hours', 64, 'bpm', 91, jsonb_build_object('source', 'Google Fit Pixel 7', 'time_of_day', 'morning'), NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days'),
  ('gfit-hr-2b', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'heart_rate', NOW() - INTERVAL '6 days' + INTERVAL '14 hours', 78, 'bpm', 90, jsonb_build_object('source', 'Google Fit Pixel 7', 'time_of_day', 'afternoon'), NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days'),
  ('gfit-hr-2c', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'heart_rate', NOW() - INTERVAL '6 days' + INTERVAL '20 hours', 70, 'bpm', 91, jsonb_build_object('source', 'Google Fit Pixel 7', 'time_of_day', 'evening'), NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days'),

  -- Day 5 ago
  ('gfit-hr-3a', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'heart_rate', NOW() - INTERVAL '5 days' + INTERVAL '8 hours', 61, 'bpm', 92, jsonb_build_object('source', 'Google Fit Pixel 7', 'time_of_day', 'morning'), NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days'),
  ('gfit-hr-3b', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'heart_rate', NOW() - INTERVAL '5 days' + INTERVAL '14 hours', 73, 'bpm', 89, jsonb_build_object('source', 'Google Fit Pixel 7', 'time_of_day', 'afternoon'), NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days'),
  ('gfit-hr-3c', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'heart_rate', NOW() - INTERVAL '5 days' + INTERVAL '20 hours', 67, 'bpm', 90, jsonb_build_object('source', 'Google Fit Pixel 7', 'time_of_day', 'evening'), NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days'),

  -- Day 4 ago
  ('gfit-hr-4a', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'heart_rate', NOW() - INTERVAL '4 days' + INTERVAL '8 hours', 63, 'bpm', 91, jsonb_build_object('source', 'Google Fit Pixel 7', 'time_of_day', 'morning'), NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days'),
  ('gfit-hr-4b', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'heart_rate', NOW() - INTERVAL '4 days' + INTERVAL '14 hours', 76, 'bpm', 88, jsonb_build_object('source', 'Google Fit Pixel 7', 'time_of_day', 'afternoon'), NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days'),
  ('gfit-hr-4c', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'heart_rate', NOW() - INTERVAL '4 days' + INTERVAL '20 hours', 69, 'bpm', 90, jsonb_build_object('source', 'Google Fit Pixel 7', 'time_of_day', 'evening'), NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days'),

  -- Day 3 ago
  ('gfit-hr-5a', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'heart_rate', NOW() - INTERVAL '3 days' + INTERVAL '8 hours', 65, 'bpm', 89, jsonb_build_object('source', 'Google Fit Pixel 7', 'time_of_day', 'morning'), NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),
  ('gfit-hr-5b', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'heart_rate', NOW() - INTERVAL '3 days' + INTERVAL '14 hours', 77, 'bpm', 87, jsonb_build_object('source', 'Google Fit Pixel 7', 'time_of_day', 'afternoon'), NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),
  ('gfit-hr-5c', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'heart_rate', NOW() - INTERVAL '3 days' + INTERVAL '20 hours', 71, 'bpm', 88, jsonb_build_object('source', 'Google Fit Pixel 7', 'time_of_day', 'evening'), NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),

  -- Day 2 ago
  ('gfit-hr-6a', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'heart_rate', NOW() - INTERVAL '2 days' + INTERVAL '8 hours', 62, 'bpm', 92, jsonb_build_object('source', 'Google Fit Pixel 7', 'time_of_day', 'morning'), NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
  ('gfit-hr-6b', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'heart_rate', NOW() - INTERVAL '2 days' + INTERVAL '14 hours', 74, 'bpm', 90, jsonb_build_object('source', 'Google Fit Pixel 7', 'time_of_day', 'afternoon'), NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
  ('gfit-hr-6c', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'heart_rate', NOW() - INTERVAL '2 days' + INTERVAL '20 hours', 68, 'bpm', 91, jsonb_build_object('source', 'Google Fit Pixel 7', 'time_of_day', 'evening'), NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),

  -- Day 1 ago
  ('gfit-hr-7a', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'heart_rate', NOW() - INTERVAL '1 day' + INTERVAL '8 hours', 64, 'bpm', 91, jsonb_build_object('source', 'Google Fit Pixel 7', 'time_of_day', 'morning'), NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),
  ('gfit-hr-7b', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'heart_rate', NOW() - INTERVAL '1 day' + INTERVAL '14 hours', 76, 'bpm', 89, jsonb_build_object('source', 'Google Fit Pixel 7', 'time_of_day', 'afternoon'), NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),
  ('gfit-hr-7c', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'heart_rate', NOW() - INTERVAL '1 day' + INTERVAL '20 hours', 70, 'bpm', 90, jsonb_build_object('source', 'Google Fit Pixel 7', 'time_of_day', 'evening'), NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day')
ON CONFLICT (id) DO NOTHING;

-- ACTIVE MINUTES DATA (7 daily records = 7 records)
INSERT INTO wearable_health_data (
  id, user_id, device_id, data_type, timestamp, value_numeric, unit, quality_score, raw_data, synced_at, created_at
) VALUES
  ('gfit-active-1', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'active_minutes', NOW() - INTERVAL '7 days' + INTERVAL '22 hours', 45, 'minutes', 93, jsonb_build_object('source', 'Google Fit Pixel 7', 'activity_level', 'moderate_to_vigorous'), NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days'),
  ('gfit-active-2', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'active_minutes', NOW() - INTERVAL '6 days' + INTERVAL '22 hours', 68, 'minutes', 95, jsonb_build_object('source', 'Google Fit Pixel 7', 'activity_level', 'moderate_to_vigorous'), NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days'),
  ('gfit-active-3', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'active_minutes', NOW() - INTERVAL '5 days' + INTERVAL '22 hours', 32, 'minutes', 91, jsonb_build_object('source', 'Google Fit Pixel 7', 'activity_level', 'moderate_to_vigorous'), NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days'),
  ('gfit-active-4', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'active_minutes', NOW() - INTERVAL '4 days' + INTERVAL '22 hours', 52, 'minutes', 94, jsonb_build_object('source', 'Google Fit Pixel 7', 'activity_level', 'moderate_to_vigorous'), NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days'),
  ('gfit-active-5', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'active_minutes', NOW() - INTERVAL '3 days' + INTERVAL '22 hours', 41, 'minutes', 92, jsonb_build_object('source', 'Google Fit Pixel 7', 'activity_level', 'moderate_to_vigorous'), NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),
  ('gfit-active-6', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'active_minutes', NOW() - INTERVAL '2 days' + INTERVAL '22 hours', 58, 'minutes', 96, jsonb_build_object('source', 'Google Fit Pixel 7', 'activity_level', 'moderate_to_vigorous'), NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
  ('gfit-active-7', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'active_minutes', NOW() - INTERVAL '1 day' + INTERVAL '22 hours', 47, 'minutes', 93, jsonb_build_object('source', 'Google Fit Pixel 7', 'activity_level', 'moderate_to_vigorous'), NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day')
ON CONFLICT (id) DO NOTHING;

-- WORKOUT SESSIONS (4 workouts = 4 records)
INSERT INTO wearable_health_data (
  id, user_id, device_id, data_type, timestamp, value_json, unit, quality_score, source_workout_id, raw_data, synced_at, created_at
) VALUES
  -- Workout 1: Morning Walk (6 days ago)
  (
    'gfit-workout-1',
    'd8ec065f-93f3-4806-9190-5c4c461200bb',
    'google-fit-pixel7-001',
    'workout',
    NOW() - INTERVAL '6 days' - INTERVAL '9 hours',
    jsonb_build_object(
      'activityType', 'walking',
      'workoutName', 'Morning Walk',
      'startTime', (NOW() - INTERVAL '6 days' - INTERVAL '9 hours')::text,
      'endTime', (NOW() - INTERVAL '6 days' - INTERVAL '8 hours' - INTERVAL '25 minutes')::text,
      'durationSeconds', 2100,
      'distanceMeters', 3200,
      'caloriesBurned', 245,
      'avgHeartRate', 98,
      'maxHeartRate', 118
    ),
    'activity',
    94,
    'google-fit-workout-001',
    jsonb_build_object('source', 'Google Fit Pixel 7', 'sport', 'walking', 'outdoor', true),
    NOW() - INTERVAL '6 days',
    NOW() - INTERVAL '6 days'
  ),

  -- Workout 2: Running (4 days ago)
  (
    'gfit-workout-2',
    'd8ec065f-93f3-4806-9190-5c4c461200bb',
    'google-fit-pixel7-001',
    'workout',
    NOW() - INTERVAL '4 days' - INTERVAL '8 hours',
    jsonb_build_object(
      'activityType', 'running',
      'workoutName', 'Morning Run',
      'startTime', (NOW() - INTERVAL '4 days' - INTERVAL '8 hours')::text,
      'endTime', (NOW() - INTERVAL '4 days' - INTERVAL '7 hours' - INTERVAL '18 minutes')::text,
      'durationSeconds', 2520,
      'distanceMeters', 5800,
      'caloriesBurned', 485,
      'avgHeartRate', 154,
      'maxHeartRate', 176,
      'avgPace', '7:15'
    ),
    'activity',
    96,
    'google-fit-workout-002',
    jsonb_build_object('source', 'Google Fit Pixel 7', 'sport', 'running', 'outdoor', true),
    NOW() - INTERVAL '4 days',
    NOW() - INTERVAL '4 days'
  ),

  -- Workout 3: Cycling (2 days ago)
  (
    'gfit-workout-3',
    'd8ec065f-93f3-4806-9190-5c4c461200bb',
    'google-fit-pixel7-001',
    'workout',
    NOW() - INTERVAL '2 days' - INTERVAL '10 hours',
    jsonb_build_object(
      'activityType', 'cycling',
      'workoutName', 'Bike Ride',
      'startTime', (NOW() - INTERVAL '2 days' - INTERVAL '10 hours')::text,
      'endTime', (NOW() - INTERVAL '2 days' - INTERVAL '8 hours' - INTERVAL '45 minutes')::text,
      'durationSeconds', 4500,
      'distanceMeters', 18500,
      'caloriesBurned', 612,
      'avgHeartRate', 135,
      'maxHeartRate', 162
    ),
    'activity',
    95,
    'google-fit-workout-003',
    jsonb_build_object('source', 'Google Fit Pixel 7', 'sport', 'cycling', 'outdoor', true),
    NOW() - INTERVAL '2 days',
    NOW() - INTERVAL '2 days'
  ),

  -- Workout 4: Yoga (yesterday)
  (
    'gfit-workout-4',
    'd8ec065f-93f3-4806-9190-5c4c461200bb',
    'google-fit-pixel7-001',
    'workout',
    NOW() - INTERVAL '1 day' - INTERVAL '19 hours',
    jsonb_build_object(
      'activityType', 'yoga',
      'workoutName', 'Evening Yoga',
      'startTime', (NOW() - INTERVAL '1 day' - INTERVAL '19 hours')::text,
      'endTime', (NOW() - INTERVAL '1 day' - INTERVAL '18 hours' - INTERVAL '15 minutes')::text,
      'durationSeconds', 2700,
      'caloriesBurned', 185,
      'avgHeartRate', 88,
      'maxHeartRate', 105
    ),
    'activity',
    92,
    'google-fit-workout-004',
    jsonb_build_object('source', 'Google Fit Pixel 7', 'sport', 'yoga', 'indoor', true),
    NOW() - INTERVAL '1 day',
    NOW() - INTERVAL '1 day'
  )
ON CONFLICT (id) DO NOTHING;

-- WEIGHT DATA (3 records over 7 days = 3 records)
INSERT INTO wearable_health_data (
  id, user_id, device_id, data_type, timestamp, value_numeric, unit, quality_score, raw_data, synced_at, created_at
) VALUES
  ('gfit-weight-1', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'weight', NOW() - INTERVAL '7 days' + INTERVAL '8 hours', 78.5, 'kg', 97, jsonb_build_object('source', 'Google Fit Pixel 7', 'manual_entry', true), NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days'),
  ('gfit-weight-2', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'weight', NOW() - INTERVAL '4 days' + INTERVAL '8 hours', 78.2, 'kg', 96, jsonb_build_object('source', 'Google Fit Pixel 7', 'manual_entry', true), NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days'),
  ('gfit-weight-3', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'weight', NOW() - INTERVAL '1 day' + INTERVAL '8 hours', 78.0, 'kg', 98, jsonb_build_object('source', 'Google Fit Pixel 7', 'manual_entry', true), NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day')
ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- TOTAL COUNT: 7 + 7 + 7 + 21 + 7 + 4 + 3 = 56 records
-- Need 32 more records to reach exactly 88
-- =====================================================

-- RESTING HEART RATE DATA (7 daily morning measurements = 7 records)
INSERT INTO wearable_health_data (
  id, user_id, device_id, data_type, timestamp, value_numeric, unit, quality_score, raw_data, synced_at, created_at
) VALUES
  ('gfit-hr-rest-1', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'resting_heart_rate', NOW() - INTERVAL '7 days' + INTERVAL '7 hours', 59, 'bpm', 94, jsonb_build_object('source', 'Google Fit Pixel 7', 'measured_during', 'night'), NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days'),
  ('gfit-hr-rest-2', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'resting_heart_rate', NOW() - INTERVAL '6 days' + INTERVAL '7 hours', 61, 'bpm', 93, jsonb_build_object('source', 'Google Fit Pixel 7', 'measured_during', 'night'), NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days'),
  ('gfit-hr-rest-3', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'resting_heart_rate', NOW() - INTERVAL '5 days' + INTERVAL '7 hours', 58, 'bpm', 95, jsonb_build_object('source', 'Google Fit Pixel 7', 'measured_during', 'night'), NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days'),
  ('gfit-hr-rest-4', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'resting_heart_rate', NOW() - INTERVAL '4 days' + INTERVAL '7 hours', 60, 'bpm', 94, jsonb_build_object('source', 'Google Fit Pixel 7', 'measured_during', 'night'), NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days'),
  ('gfit-hr-rest-5', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'resting_heart_rate', NOW() - INTERVAL '3 days' + INTERVAL '7 hours', 62, 'bpm', 92, jsonb_build_object('source', 'Google Fit Pixel 7', 'measured_during', 'night'), NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),
  ('gfit-hr-rest-6', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'resting_heart_rate', NOW() - INTERVAL '2 days' + INTERVAL '7 hours', 59, 'bpm', 95, jsonb_build_object('source', 'Google Fit Pixel 7', 'measured_during', 'night'), NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
  ('gfit-hr-rest-7', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'resting_heart_rate', NOW() - INTERVAL '1 day' + INTERVAL '7 hours', 61, 'bpm', 93, jsonb_build_object('source', 'Google Fit Pixel 7', 'measured_during', 'night'), NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day')
ON CONFLICT (id) DO NOTHING;

-- HOURLY STEP DATA (25 additional hourly records to reach exactly 88)
-- Distributing across different times of the day for the last 7 days
INSERT INTO wearable_health_data (
  id, user_id, device_id, data_type, timestamp, value_numeric, unit, quality_score, raw_data, synced_at, created_at
) VALUES
  -- Day 7 - 4 hourly records
  ('gfit-steps-h-1a', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'steps', NOW() - INTERVAL '7 days' + INTERVAL '9 hours', 456, 'steps', 92, jsonb_build_object('source', 'Google Fit Pixel 7', 'hourly_segment', true), NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days'),
  ('gfit-steps-h-1b', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'steps', NOW() - INTERVAL '7 days' + INTERVAL '12 hours', 823, 'steps', 93, jsonb_build_object('source', 'Google Fit Pixel 7', 'hourly_segment', true), NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days'),
  ('gfit-steps-h-1c', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'steps', NOW() - INTERVAL '7 days' + INTERVAL '15 hours', 1234, 'steps', 94, jsonb_build_object('source', 'Google Fit Pixel 7', 'hourly_segment', true), NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days'),
  ('gfit-steps-h-1d', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'steps', NOW() - INTERVAL '7 days' + INTERVAL '18 hours', 678, 'steps', 91, jsonb_build_object('source', 'Google Fit Pixel 7', 'hourly_segment', true), NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days'),

  -- Day 6 - 4 hourly records
  ('gfit-steps-h-2a', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'steps', NOW() - INTERVAL '6 days' + INTERVAL '9 hours', 534, 'steps', 93, jsonb_build_object('source', 'Google Fit Pixel 7', 'hourly_segment', true), NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days'),
  ('gfit-steps-h-2b', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'steps', NOW() - INTERVAL '6 days' + INTERVAL '12 hours', 1456, 'steps', 95, jsonb_build_object('source', 'Google Fit Pixel 7', 'hourly_segment', true), NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days'),
  ('gfit-steps-h-2c', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'steps', NOW() - INTERVAL '6 days' + INTERVAL '15 hours', 1678, 'steps', 96, jsonb_build_object('source', 'Google Fit Pixel 7', 'hourly_segment', true), NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days'),
  ('gfit-steps-h-2d', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'steps', NOW() - INTERVAL '6 days' + INTERVAL '18 hours', 789, 'steps', 92, jsonb_build_object('source', 'Google Fit Pixel 7', 'hourly_segment', true), NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days'),

  -- Day 5 - 3 hourly records
  ('gfit-steps-h-3a', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'steps', NOW() - INTERVAL '5 days' + INTERVAL '10 hours', 412, 'steps', 91, jsonb_build_object('source', 'Google Fit Pixel 7', 'hourly_segment', true), NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days'),
  ('gfit-steps-h-3b', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'steps', NOW() - INTERVAL '5 days' + INTERVAL '14 hours', 923, 'steps', 92, jsonb_build_object('source', 'Google Fit Pixel 7', 'hourly_segment', true), NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days'),
  ('gfit-steps-h-3c', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'steps', NOW() - INTERVAL '5 days' + INTERVAL '17 hours', 567, 'steps', 90, jsonb_build_object('source', 'Google Fit Pixel 7', 'hourly_segment', true), NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days'),

  -- Day 4 - 4 hourly records
  ('gfit-steps-h-4a', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'steps', NOW() - INTERVAL '4 days' + INTERVAL '9 hours', 623, 'steps', 93, jsonb_build_object('source', 'Google Fit Pixel 7', 'hourly_segment', true), NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days'),
  ('gfit-steps-h-4b', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'steps', NOW() - INTERVAL '4 days' + INTERVAL '13 hours', 1234, 'steps', 94, jsonb_build_object('source', 'Google Fit Pixel 7', 'hourly_segment', true), NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days'),
  ('gfit-steps-h-4c', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'steps', NOW() - INTERVAL '4 days' + INTERVAL '16 hours', 1098, 'steps', 95, jsonb_build_object('source', 'Google Fit Pixel 7', 'hourly_segment', true), NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days'),
  ('gfit-steps-h-4d', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'steps', NOW() - INTERVAL '4 days' + INTERVAL '19 hours', 734, 'steps', 92, jsonb_build_object('source', 'Google Fit Pixel 7', 'hourly_segment', true), NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days'),

  -- Day 3 - 3 hourly records
  ('gfit-steps-h-5a', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'steps', NOW() - INTERVAL '3 days' + INTERVAL '10 hours', 567, 'steps', 91, jsonb_build_object('source', 'Google Fit Pixel 7', 'hourly_segment', true), NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),
  ('gfit-steps-h-5b', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'steps', NOW() - INTERVAL '3 days' + INTERVAL '14 hours', 1123, 'steps', 93, jsonb_build_object('source', 'Google Fit Pixel 7', 'hourly_segment', true), NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),
  ('gfit-steps-h-5c', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'steps', NOW() - INTERVAL '3 days' + INTERVAL '18 hours', 678, 'steps', 90, jsonb_build_object('source', 'Google Fit Pixel 7', 'hourly_segment', true), NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),

  -- Day 2 - 4 hourly records
  ('gfit-steps-h-6a', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'steps', NOW() - INTERVAL '2 days' + INTERVAL '9 hours', 712, 'steps', 94, jsonb_build_object('source', 'Google Fit Pixel 7', 'hourly_segment', true), NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
  ('gfit-steps-h-6b', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'steps', NOW() - INTERVAL '2 days' + INTERVAL '13 hours', 1456, 'steps', 96, jsonb_build_object('source', 'Google Fit Pixel 7', 'hourly_segment', true), NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
  ('gfit-steps-h-6c', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'steps', NOW() - INTERVAL '2 days' + INTERVAL '16 hours', 1234, 'steps', 95, jsonb_build_object('source', 'Google Fit Pixel 7', 'hourly_segment', true), NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
  ('gfit-steps-h-6d', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'steps', NOW() - INTERVAL '2 days' + INTERVAL '19 hours', 823, 'steps', 93, jsonb_build_object('source', 'Google Fit Pixel 7', 'hourly_segment', true), NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),

  -- Day 1 - 3 hourly records
  ('gfit-steps-h-7a', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'steps', NOW() - INTERVAL '1 day' + INTERVAL '10 hours', 634, 'steps', 92, jsonb_build_object('source', 'Google Fit Pixel 7', 'hourly_segment', true), NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),
  ('gfit-steps-h-7b', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'steps', NOW() - INTERVAL '1 day' + INTERVAL '14 hours', 1234, 'steps', 94, jsonb_build_object('source', 'Google Fit Pixel 7', 'hourly_segment', true), NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),
  ('gfit-steps-h-7c', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'google-fit-pixel7-001', 'steps', NOW() - INTERVAL '1 day' + INTERVAL '18 hours', 789, 'steps', 91, jsonb_build_object('source', 'Google Fit Pixel 7', 'hourly_segment', true), NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day')
ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- FINAL TOTAL: 56 + 7 + 25 = 88 RECORDS EXACTLY
-- =====================================================

-- =====================================================
-- 4. SYNC HISTORY FOR GOOGLE FIT PIXEL 7
-- =====================================================

INSERT INTO device_sync_history (
  id, device_id, user_id, sync_type, status, data_types_synced, records_fetched, records_stored, duration_ms, started_at, completed_at, created_at
) VALUES
  ('gfit-sync-1', 'google-fit-pixel7-001', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'automatic', 'success', ARRAY['steps', 'calories', 'distance', 'heart_rate'], 38, 38, 2780, NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days' + INTERVAL '2.78 seconds', NOW() - INTERVAL '7 days'),
  ('gfit-sync-2', 'google-fit-pixel7-001', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'automatic', 'success', ARRAY['steps', 'calories', 'distance', 'heart_rate', 'workout'], 42, 42, 3120, NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days' + INTERVAL '3.12 seconds', NOW() - INTERVAL '6 days'),
  ('gfit-sync-3', 'google-fit-pixel7-001', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'automatic', 'success', ARRAY['steps', 'calories', 'distance', 'heart_rate'], 35, 35, 2450, NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days' + INTERVAL '2.45 seconds', NOW() - INTERVAL '5 days'),
  ('gfit-sync-4', 'google-fit-pixel7-001', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'automatic', 'success', ARRAY['steps', 'calories', 'distance', 'heart_rate', 'workout', 'weight'], 45, 45, 3450, NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days' + INTERVAL '3.45 seconds', NOW() - INTERVAL '4 days'),
  ('gfit-sync-5', 'google-fit-pixel7-001', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'automatic', 'success', ARRAY['steps', 'calories', 'distance', 'heart_rate'], 36, 36, 2670, NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days' + INTERVAL '2.67 seconds', NOW() - INTERVAL '3 days'),
  ('gfit-sync-6', 'google-fit-pixel7-001', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'automatic', 'success', ARRAY['steps', 'calories', 'distance', 'heart_rate', 'workout'], 41, 41, 3080, NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days' + INTERVAL '3.08 seconds', NOW() - INTERVAL '2 days'),
  ('gfit-sync-7', 'google-fit-pixel7-001', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'automatic', 'success', ARRAY['steps', 'calories', 'distance', 'heart_rate', 'workout', 'weight'], 43, 43, 3210, NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day' + INTERVAL '3.21 seconds', NOW() - INTERVAL '1 day'),
  ('gfit-sync-8', 'google-fit-pixel7-001', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'automatic', 'success', ARRAY['steps', 'heart_rate'], 12, 12, 980, NOW() - INTERVAL '1 hour', NOW() - INTERVAL '1 hour' + INTERVAL '0.98 seconds', NOW() - INTERVAL '1 hour')
ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- 5. VERIFICATION QUERIES
-- =====================================================

-- Check Google Fit devices
-- SELECT id, display_name, status, last_sync_at
-- FROM connected_devices
-- WHERE provider = 'google_fit' AND user_id = 'd8ec065f-93f3-4806-9190-5c4c461200bb';

-- Check EXACT count of Google Fit Pixel 7 data (should be 88)
-- SELECT COUNT(*) as total_records
-- FROM wearable_health_data
-- WHERE device_id = 'google-fit-pixel7-001';

-- Check data distribution
-- SELECT
--   data_type,
--   COUNT(*) as count
-- FROM wearable_health_data
-- WHERE device_id = 'google-fit-pixel7-001'
-- GROUP BY data_type
-- ORDER BY data_type;
