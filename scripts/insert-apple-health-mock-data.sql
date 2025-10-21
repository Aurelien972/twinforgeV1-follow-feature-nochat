-- Mock Apple Health Data for Testing User
-- User ID: d8ec065f-93f3-4806-9190-5c4c461200bb
--
-- This script inserts realistic mock data for:
-- - 1 Apple Watch Series 8 (connected, real device with data)
-- - 1 Apple Health Test Simulation (disconnected, for testing reconnection)
-- - 7 days of health data history for Apple Watch
-- - Multiple workout sessions
-- - Daily metrics (steps, calories, heart rate, sleep, HRV, VO2max)

-- =====================================================
-- 1. INSERT APPLE WATCH SERIES 8 (CONNECTED)
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
  'apple-watch-s8-001',
  'd8ec065f-93f3-4806-9190-5c4c461200bb',
  'apple_health',
  'apple-health-user-aw8-12345',
  'Apple Watch Series 8',
  'smartwatch',
  'connected',
  ARRAY['health_read'],
  NOW() - INTERVAL '2 hours',
  jsonb_build_object(
    'device_model', 'Apple Watch Series 8',
    'os_version', 'watchOS 10.5',
    'paired_iphone', 'iPhone 14 Pro',
    'watch_size', '45mm',
    'real_device', true
  ),
  NOW() - INTERVAL '14 days',
  NOW() - INTERVAL '14 days',
  NOW() - INTERVAL '2 hours'
) ON CONFLICT (id) DO UPDATE SET
  last_sync_at = NOW() - INTERVAL '2 hours',
  updated_at = NOW() - INTERVAL '2 hours',
  status = 'connected';

-- =====================================================
-- 2. INSERT APPLE HEALTH TEST SIMULATION (DISCONNECTED)
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
  'apple-health-test-sim-001',
  'd8ec065f-93f3-4806-9190-5c4c461200bb',
  'apple_health',
  'apple-health-test-sim-99999',
  'Apple Health (Test Simulation)',
  'smartwatch',
  'disconnected',
  ARRAY['health_read'],
  NOW() - INTERVAL '5 days',
  jsonb_build_object(
    'simulated', true,
    'test_device', true,
    'purpose', 'Test reconnection flow',
    'version', '1.0'
  ),
  NOW() - INTERVAL '21 days',
  NOW() - INTERVAL '21 days',
  NOW() - INTERVAL '5 days'
) ON CONFLICT (id) DO UPDATE SET
  status = 'disconnected',
  last_sync_at = NOW() - INTERVAL '5 days',
  updated_at = NOW() - INTERVAL '5 days';

-- =====================================================
-- 3. APPLE WATCH: 7 DAYS OF DAILY HEALTH METRICS
-- =====================================================

-- Resting Heart Rate data (morning measurements)
INSERT INTO wearable_health_data (
  id, user_id, device_id, data_type, timestamp, value_numeric, unit, quality_score, raw_data, synced_at, created_at
) VALUES
  -- Day 1 (7 days ago)
  ('aw8-hr-rest-1', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'apple-watch-s8-001', 'resting_heart_rate', NOW() - INTERVAL '7 days' + INTERVAL '7 hours', 54, 'bpm', 96, jsonb_build_object('source', 'Apple Watch S8', 'measured_during', 'sleep', 'confidence', 'high'), NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days'),

  -- Day 2 (6 days ago)
  ('aw8-hr-rest-2', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'apple-watch-s8-001', 'resting_heart_rate', NOW() - INTERVAL '6 days' + INTERVAL '7 hours', 56, 'bpm', 95, jsonb_build_object('source', 'Apple Watch S8', 'measured_during', 'sleep', 'confidence', 'high'), NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days'),

  -- Day 3 (5 days ago)
  ('aw8-hr-rest-3', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'apple-watch-s8-001', 'resting_heart_rate', NOW() - INTERVAL '5 days' + INTERVAL '7 hours', 53, 'bpm', 97, jsonb_build_object('source', 'Apple Watch S8', 'measured_during', 'sleep', 'confidence', 'high'), NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days'),

  -- Day 4 (4 days ago)
  ('aw8-hr-rest-4', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'apple-watch-s8-001', 'resting_heart_rate', NOW() - INTERVAL '4 days' + INTERVAL '7 hours', 55, 'bpm', 96, jsonb_build_object('source', 'Apple Watch S8', 'measured_during', 'sleep', 'confidence', 'high'), NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days'),

  -- Day 5 (3 days ago)
  ('aw8-hr-rest-5', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'apple-watch-s8-001', 'resting_heart_rate', NOW() - INTERVAL '3 days' + INTERVAL '7 hours', 57, 'bpm', 94, jsonb_build_object('source', 'Apple Watch S8', 'measured_during', 'sleep', 'confidence', 'medium'), NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),

  -- Day 6 (2 days ago)
  ('aw8-hr-rest-6', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'apple-watch-s8-001', 'resting_heart_rate', NOW() - INTERVAL '2 days' + INTERVAL '7 hours', 54, 'bpm', 97, jsonb_build_object('source', 'Apple Watch S8', 'measured_during', 'sleep', 'confidence', 'high'), NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),

  -- Day 7 (yesterday)
  ('aw8-hr-rest-7', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'apple-watch-s8-001', 'resting_heart_rate', NOW() - INTERVAL '1 day' + INTERVAL '7 hours', 56, 'bpm', 95, jsonb_build_object('source', 'Apple Watch S8', 'measured_during', 'sleep', 'confidence', 'high'), NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day')
ON CONFLICT (id) DO NOTHING;

-- Average Heart Rate (daily averages)
INSERT INTO wearable_health_data (
  id, user_id, device_id, data_type, timestamp, value_numeric, unit, quality_score, raw_data, synced_at, created_at
) VALUES
  ('aw8-hr-avg-1', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'apple-watch-s8-001', 'heart_rate', NOW() - INTERVAL '7 days' + INTERVAL '18 hours', 68, 'bpm', 93, jsonb_build_object('source', 'Apple Watch S8', 'daily_average', true, 'samples', 1420), NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days'),
  ('aw8-hr-avg-2', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'apple-watch-s8-001', 'heart_rate', NOW() - INTERVAL '6 days' + INTERVAL '18 hours', 71, 'bpm', 91, jsonb_build_object('source', 'Apple Watch S8', 'daily_average', true, 'samples', 1385), NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days'),
  ('aw8-hr-avg-3', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'apple-watch-s8-001', 'heart_rate', NOW() - INTERVAL '5 days' + INTERVAL '18 hours', 74, 'bpm', 94, jsonb_build_object('source', 'Apple Watch S8', 'daily_average', true, 'samples', 1456), NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days'),
  ('aw8-hr-avg-4', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'apple-watch-s8-001', 'heart_rate', NOW() - INTERVAL '4 days' + INTERVAL '18 hours', 70, 'bpm', 92, jsonb_build_object('source', 'Apple Watch S8', 'daily_average', true, 'samples', 1398), NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days'),
  ('aw8-hr-avg-5', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'apple-watch-s8-001', 'heart_rate', NOW() - INTERVAL '3 days' + INTERVAL '18 hours', 72, 'bpm', 90, jsonb_build_object('source', 'Apple Watch S8', 'daily_average', true, 'samples', 1411), NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),
  ('aw8-hr-avg-6', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'apple-watch-s8-001', 'heart_rate', NOW() - INTERVAL '2 days' + INTERVAL '18 hours', 69, 'bpm', 95, jsonb_build_object('source', 'Apple Watch S8', 'daily_average', true, 'samples', 1432), NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
  ('aw8-hr-avg-7', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'apple-watch-s8-001', 'heart_rate', NOW() - INTERVAL '1 day' + INTERVAL '18 hours', 73, 'bpm', 93, jsonb_build_object('source', 'Apple Watch S8', 'daily_average', true, 'samples', 1404), NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day')
ON CONFLICT (id) DO NOTHING;

-- Steps data (daily totals)
INSERT INTO wearable_health_data (
  id, user_id, device_id, data_type, timestamp, value_numeric, unit, quality_score, raw_data, synced_at, created_at
) VALUES
  ('aw8-steps-1', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'apple-watch-s8-001', 'steps', NOW() - INTERVAL '7 days' + INTERVAL '23 hours', 9823, 'steps', 98, jsonb_build_object('source', 'Apple Watch S8', 'tracking_duration_hours', 16), NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days'),
  ('aw8-steps-2', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'apple-watch-s8-001', 'steps', NOW() - INTERVAL '6 days' + INTERVAL '23 hours', 13456, 'steps', 97, jsonb_build_object('source', 'Apple Watch S8', 'tracking_duration_hours', 17), NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days'),
  ('aw8-steps-3', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'apple-watch-s8-001', 'steps', NOW() - INTERVAL '5 days' + INTERVAL '23 hours', 7234, 'steps', 96, jsonb_build_object('source', 'Apple Watch S8', 'tracking_duration_hours', 15), NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days'),
  ('aw8-steps-4', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'apple-watch-s8-001', 'steps', NOW() - INTERVAL '4 days' + INTERVAL '23 hours', 11234, 'steps', 99, jsonb_build_object('source', 'Apple Watch S8', 'tracking_duration_hours', 18), NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days'),
  ('aw8-steps-5', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'apple-watch-s8-001', 'steps', NOW() - INTERVAL '3 days' + INTERVAL '23 hours', 8967, 'steps', 95, jsonb_build_object('source', 'Apple Watch S8', 'tracking_duration_hours', 16), NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),
  ('aw8-steps-6', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'apple-watch-s8-001', 'steps', NOW() - INTERVAL '2 days' + INTERVAL '23 hours', 12678, 'steps', 98, jsonb_build_object('source', 'Apple Watch S8', 'tracking_duration_hours', 17), NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
  ('aw8-steps-7', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'apple-watch-s8-001', 'steps', NOW() - INTERVAL '1 day' + INTERVAL '23 hours', 9456, 'steps', 97, jsonb_build_object('source', 'Apple Watch S8', 'tracking_duration_hours', 16), NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day')
ON CONFLICT (id) DO NOTHING;

-- Calories data (daily totals - active + resting)
INSERT INTO wearable_health_data (
  id, user_id, device_id, data_type, timestamp, value_numeric, unit, quality_score, raw_data, synced_at, created_at
) VALUES
  ('aw8-cal-1', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'apple-watch-s8-001', 'calories', NOW() - INTERVAL '7 days' + INTERVAL '23 hours', 2456, 'kcal', 94, jsonb_build_object('source', 'Apple Watch S8', 'active_calories', 623, 'resting_calories', 1833), NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days'),
  ('aw8-cal-2', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'apple-watch-s8-001', 'calories', NOW() - INTERVAL '6 days' + INTERVAL '23 hours', 2834, 'kcal', 96, jsonb_build_object('source', 'Apple Watch S8', 'active_calories', 1001, 'resting_calories', 1833), NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days'),
  ('aw8-cal-3', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'apple-watch-s8-001', 'calories', NOW() - INTERVAL '5 days' + INTERVAL '23 hours', 2167, 'kcal', 92, jsonb_build_object('source', 'Apple Watch S8', 'active_calories', 334, 'resting_calories', 1833), NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days'),
  ('aw8-cal-4', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'apple-watch-s8-001', 'calories', NOW() - INTERVAL '4 days' + INTERVAL '23 hours', 2612, 'kcal', 95, jsonb_build_object('source', 'Apple Watch S8', 'active_calories', 779, 'resting_calories', 1833), NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days'),
  ('aw8-cal-5', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'apple-watch-s8-001', 'calories', NOW() - INTERVAL '3 days' + INTERVAL '23 hours', 2389, 'kcal', 93, jsonb_build_object('source', 'Apple Watch S8', 'active_calories', 556, 'resting_calories', 1833), NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),
  ('aw8-cal-6', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'apple-watch-s8-001', 'calories', NOW() - INTERVAL '2 days' + INTERVAL '23 hours', 2723, 'kcal', 97, jsonb_build_object('source', 'Apple Watch S8', 'active_calories', 890, 'resting_calories', 1833), NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
  ('aw8-cal-7', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'apple-watch-s8-001', 'calories', NOW() - INTERVAL '1 day' + INTERVAL '23 hours', 2501, 'kcal', 94, jsonb_build_object('source', 'Apple Watch S8', 'active_calories', 668, 'resting_calories', 1833), NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day')
ON CONFLICT (id) DO NOTHING;

-- HRV data (Heart Rate Variability - recovery indicator)
INSERT INTO wearable_health_data (
  id, user_id, device_id, data_type, timestamp, value_numeric, unit, quality_score, raw_data, synced_at, created_at
) VALUES
  ('aw8-hrv-1', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'apple-watch-s8-001', 'hrv', NOW() - INTERVAL '7 days' + INTERVAL '7 hours', 64, 'ms', 91, jsonb_build_object('source', 'Apple Watch S8', 'sdnn', 64, 'recovery_score', 'excellent'), NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days'),
  ('aw8-hrv-2', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'apple-watch-s8-001', 'hrv', NOW() - INTERVAL '6 days' + INTERVAL '7 hours', 58, 'ms', 89, jsonb_build_object('source', 'Apple Watch S8', 'sdnn', 58, 'recovery_score', 'good'), NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days'),
  ('aw8-hrv-3', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'apple-watch-s8-001', 'hrv', NOW() - INTERVAL '5 days' + INTERVAL '7 hours', 67, 'ms', 93, jsonb_build_object('source', 'Apple Watch S8', 'sdnn', 67, 'recovery_score', 'excellent'), NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days'),
  ('aw8-hrv-4', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'apple-watch-s8-001', 'hrv', NOW() - INTERVAL '4 days' + INTERVAL '7 hours', 61, 'ms', 90, jsonb_build_object('source', 'Apple Watch S8', 'sdnn', 61, 'recovery_score', 'good'), NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days'),
  ('aw8-hrv-5', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'apple-watch-s8-001', 'hrv', NOW() - INTERVAL '3 days' + INTERVAL '7 hours', 55, 'ms', 87, jsonb_build_object('source', 'Apple Watch S8', 'sdnn', 55, 'recovery_score', 'moderate'), NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),
  ('aw8-hrv-6', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'apple-watch-s8-001', 'hrv', NOW() - INTERVAL '2 days' + INTERVAL '7 hours', 63, 'ms', 92, jsonb_build_object('source', 'Apple Watch S8', 'sdnn', 63, 'recovery_score', 'good'), NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
  ('aw8-hrv-7', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'apple-watch-s8-001', 'hrv', NOW() - INTERVAL '1 day' + INTERVAL '7 hours', 60, 'ms', 91, jsonb_build_object('source', 'Apple Watch S8', 'sdnn', 60, 'recovery_score', 'good'), NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day')
ON CONFLICT (id) DO NOTHING;

-- VO2Max estimates
INSERT INTO wearable_health_data (
  id, user_id, device_id, data_type, timestamp, value_numeric, unit, quality_score, raw_data, synced_at, created_at
) VALUES
  ('aw8-vo2-1', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'apple-watch-s8-001', 'vo2max', NOW() - INTERVAL '7 days', 51.3, 'ml/kg/min', 88, jsonb_build_object('source', 'Apple Watch S8', 'fitness_level', 'excellent', 'age_category', '25-34'), NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days'),
  ('aw8-vo2-2', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'apple-watch-s8-001', 'vo2max', NOW() - INTERVAL '4 days', 51.7, 'ml/kg/min', 90, jsonb_build_object('source', 'Apple Watch S8', 'fitness_level', 'excellent', 'age_category', '25-34'), NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days'),
  ('aw8-vo2-3', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'apple-watch-s8-001', 'vo2max', NOW() - INTERVAL '1 day', 52.1, 'ml/kg/min', 91, jsonb_build_object('source', 'Apple Watch S8', 'fitness_level', 'excellent', 'age_category', '25-34', 'improving', true), NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day')
ON CONFLICT (id) DO NOTHING;

-- Sleep data (nightly sessions)
INSERT INTO wearable_health_data (
  id, user_id, device_id, data_type, timestamp, value_json, unit, quality_score, raw_data, synced_at, created_at
) VALUES
  ('aw8-sleep-1', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'apple-watch-s8-001', 'sleep', NOW() - INTERVAL '7 days' + INTERVAL '2 hours', jsonb_build_object('total_minutes', 456, 'deep_minutes', 98, 'rem_minutes', 112, 'light_minutes', 246, 'awake_minutes', 12, 'sleep_score', 87), 'minutes', 94, jsonb_build_object('source', 'Apple Watch S8', 'bedtime', '23:15', 'wake_time', '07:51'), NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days'),
  ('aw8-sleep-2', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'apple-watch-s8-001', 'sleep', NOW() - INTERVAL '6 days' + INTERVAL '2 hours', jsonb_build_object('total_minutes', 423, 'deep_minutes', 89, 'rem_minutes', 98, 'light_minutes', 226, 'awake_minutes', 18, 'sleep_score', 82), 'minutes', 91, jsonb_build_object('source', 'Apple Watch S8', 'bedtime', '23:45', 'wake_time', '07:08'), NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days'),
  ('aw8-sleep-3', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'apple-watch-s8-001', 'sleep', NOW() - INTERVAL '5 days' + INTERVAL '2 hours', jsonb_build_object('total_minutes', 478, 'deep_minutes', 112, 'rem_minutes', 125, 'light_minutes', 241, 'awake_minutes', 8, 'sleep_score', 92), 'minutes', 96, jsonb_build_object('source', 'Apple Watch S8', 'bedtime', '22:50', 'wake_time', '07:28'), NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days'),
  ('aw8-sleep-4', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'apple-watch-s8-001', 'sleep', NOW() - INTERVAL '4 days' + INTERVAL '2 hours', jsonb_build_object('total_minutes', 441, 'deep_minutes', 95, 'rem_minutes', 105, 'light_minutes', 231, 'awake_minutes', 14, 'sleep_score', 85), 'minutes', 93, jsonb_build_object('source', 'Apple Watch S8', 'bedtime', '23:30', 'wake_time', '07:51'), NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days'),
  ('aw8-sleep-5', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'apple-watch-s8-001', 'sleep', NOW() - INTERVAL '3 days' + INTERVAL '2 hours', jsonb_build_object('total_minutes', 398, 'deep_minutes', 78, 'rem_minutes', 92, 'light_minutes', 218, 'awake_minutes', 22, 'sleep_score', 76), 'minutes', 88, jsonb_build_object('source', 'Apple Watch S8', 'bedtime', '00:15', 'wake_time', '07:13'), NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),
  ('aw8-sleep-6', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'apple-watch-s8-001', 'sleep', NOW() - INTERVAL '2 days' + INTERVAL '2 hours', jsonb_build_object('total_minutes', 462, 'deep_minutes', 105, 'rem_minutes', 118, 'light_minutes', 239, 'awake_minutes', 10, 'sleep_score', 89), 'minutes', 95, jsonb_build_object('source', 'Apple Watch S8', 'bedtime', '23:00', 'wake_time', '07:42'), NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
  ('aw8-sleep-7', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'apple-watch-s8-001', 'sleep', NOW() - INTERVAL '1 day' + INTERVAL '2 hours', jsonb_build_object('total_minutes', 445, 'deep_minutes', 92, 'rem_minutes', 108, 'light_minutes', 235, 'awake_minutes', 15, 'sleep_score', 86), 'minutes', 92, jsonb_build_object('source', 'Apple Watch S8', 'bedtime', '23:20', 'wake_time', '07:45'), NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day')
ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- 4. APPLE WATCH: WORKOUT SESSIONS
-- =====================================================

INSERT INTO wearable_health_data (
  id, user_id, device_id, data_type, timestamp, value_json, unit, quality_score, source_workout_id, raw_data, synced_at, created_at
) VALUES
  -- Workout 1: Morning Outdoor Run (6 days ago)
  (
    'aw8-workout-1',
    'd8ec065f-93f3-4806-9190-5c4c461200bb',
    'apple-watch-s8-001',
    'workout',
    NOW() - INTERVAL '6 days' - INTERVAL '10 hours',
    jsonb_build_object(
      'activityType', 'running',
      'workoutName', 'Morning Run',
      'startTime', (NOW() - INTERVAL '6 days' - INTERVAL '10 hours')::text,
      'endTime', (NOW() - INTERVAL '6 days' - INTERVAL '9 hours' - INTERVAL '12 minutes')::text,
      'durationSeconds', 2880,
      'distanceMeters', 7500,
      'caloriesBurned', 612,
      'avgHeartRate', 158,
      'maxHeartRate', 182,
      'elevationGainMeters', 87,
      'avgPace', '6:24',
      'zones', jsonb_build_object(
        'zone1Minutes', 2,
        'zone2Minutes', 6,
        'zone3Minutes', 22,
        'zone4Minutes', 16,
        'zone5Minutes', 2
      )
    ),
    'activity',
    97,
    'apple-health-workout-001',
    jsonb_build_object('source', 'Apple Watch S8', 'sport', 'outdoor_running', 'weather', 'sunny', 'gps', true),
    NOW() - INTERVAL '6 days',
    NOW() - INTERVAL '6 days'
  ),

  -- Workout 2: HIIT Training (4 days ago)
  (
    'aw8-workout-2',
    'd8ec065f-93f3-4806-9190-5c4c461200bb',
    'apple-watch-s8-001',
    'workout',
    NOW() - INTERVAL '4 days' - INTERVAL '18 hours',
    jsonb_build_object(
      'activityType', 'high_intensity_interval_training',
      'workoutName', 'HIIT Session',
      'startTime', (NOW() - INTERVAL '4 days' - INTERVAL '18 hours')::text,
      'endTime', (NOW() - INTERVAL '4 days' - INTERVAL '17 hours' - INTERVAL '30 minutes')::text,
      'durationSeconds', 1800,
      'caloriesBurned', 485,
      'avgHeartRate', 167,
      'maxHeartRate', 191,
      'zones', jsonb_build_object(
        'zone1Minutes', 1,
        'zone2Minutes', 3,
        'zone3Minutes', 8,
        'zone4Minutes', 12,
        'zone5Minutes', 6
      )
    ),
    'activity',
    95,
    'apple-health-workout-002',
    jsonb_build_object('source', 'Apple Watch S8', 'sport', 'hiit', 'indoor', true, 'intervals', 12),
    NOW() - INTERVAL '4 days',
    NOW() - INTERVAL '4 days'
  ),

  -- Workout 3: Cycling (2 days ago)
  (
    'aw8-workout-3',
    'd8ec065f-93f3-4806-9190-5c4c461200bb',
    'apple-watch-s8-001',
    'workout',
    NOW() - INTERVAL '2 days' - INTERVAL '8 hours',
    jsonb_build_object(
      'activityType', 'cycling',
      'workoutName', 'Afternoon Ride',
      'startTime', (NOW() - INTERVAL '2 days' - INTERVAL '8 hours')::text,
      'endTime', (NOW() - INTERVAL '2 days' - INTERVAL '6 hours' - INTERVAL '15 minutes')::text,
      'durationSeconds', 6300,
      'distanceMeters', 32400,
      'caloriesBurned', 845,
      'avgHeartRate', 142,
      'maxHeartRate', 171,
      'elevationGainMeters', 412,
      'avgCadence', 82,
      'zones', jsonb_build_object(
        'zone1Minutes', 12,
        'zone2Minutes', 38,
        'zone3Minutes', 48,
        'zone4Minutes', 7,
        'zone5Minutes', 0
      )
    ),
    'activity',
    98,
    'apple-health-workout-003',
    jsonb_build_object('source', 'Apple Watch S8', 'sport', 'outdoor_cycling', 'weather', 'partly_cloudy', 'gps', true),
    NOW() - INTERVAL '2 days',
    NOW() - INTERVAL '2 days'
  )
ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- 5. SYNC HISTORY FOR APPLE WATCH
-- =====================================================

INSERT INTO device_sync_history (
  id, device_id, user_id, sync_type, status, data_types_synced, records_fetched, records_stored, duration_ms, started_at, completed_at, created_at
) VALUES
  ('aw8-sync-1', 'apple-watch-s8-001', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'automatic', 'success', ARRAY['heart_rate', 'steps', 'calories', 'sleep', 'hrv'], 52, 52, 3450, NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days' + INTERVAL '3.45 seconds', NOW() - INTERVAL '7 days'),
  ('aw8-sync-2', 'apple-watch-s8-001', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'automatic', 'success', ARRAY['heart_rate', 'steps', 'calories', 'sleep', 'workout', 'hrv'], 64, 64, 4120, NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days' + INTERVAL '4.12 seconds', NOW() - INTERVAL '6 days'),
  ('aw8-sync-3', 'apple-watch-s8-001', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'automatic', 'success', ARRAY['heart_rate', 'steps', 'calories', 'sleep', 'hrv'], 48, 48, 2980, NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days' + INTERVAL '2.98 seconds', NOW() - INTERVAL '5 days'),
  ('aw8-sync-4', 'apple-watch-s8-001', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'automatic', 'success', ARRAY['heart_rate', 'steps', 'calories', 'sleep', 'workout', 'hrv', 'vo2max'], 68, 68, 4560, NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days' + INTERVAL '4.56 seconds', NOW() - INTERVAL '4 days'),
  ('aw8-sync-5', 'apple-watch-s8-001', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'automatic', 'success', ARRAY['heart_rate', 'steps', 'calories', 'sleep', 'hrv'], 51, 51, 3210, NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days' + INTERVAL '3.21 seconds', NOW() - INTERVAL '3 days'),
  ('aw8-sync-6', 'apple-watch-s8-001', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'automatic', 'success', ARRAY['heart_rate', 'steps', 'calories', 'sleep', 'workout', 'hrv'], 62, 62, 3890, NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days' + INTERVAL '3.89 seconds', NOW() - INTERVAL '2 days'),
  ('aw8-sync-7', 'apple-watch-s8-001', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'automatic', 'success', ARRAY['heart_rate', 'steps', 'calories', 'sleep', 'hrv', 'vo2max'], 55, 55, 3450, NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day' + INTERVAL '3.45 seconds', NOW() - INTERVAL '1 day'),
  ('aw8-sync-8', 'apple-watch-s8-001', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'automatic', 'success', ARRAY['heart_rate', 'steps'], 18, 18, 1450, NOW() - INTERVAL '2 hours', NOW() - INTERVAL '2 hours' + INTERVAL '1.45 seconds', NOW() - INTERVAL '2 hours')
ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- 6. VERIFICATION QUERIES
-- =====================================================

-- Check Apple Watch device
-- SELECT id, display_name, status, last_sync_at
-- FROM connected_devices
-- WHERE provider = 'apple_health' AND user_id = 'd8ec065f-93f3-4806-9190-5c4c461200bb';

-- Check Apple Watch data count
-- SELECT
--   data_type,
--   COUNT(*) as count
-- FROM wearable_health_data
-- WHERE device_id = 'apple-watch-s8-001'
-- GROUP BY data_type
-- ORDER BY data_type;
