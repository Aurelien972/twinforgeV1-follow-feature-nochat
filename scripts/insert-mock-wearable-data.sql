-- Mock Wearable Data for Testing User
-- User ID: d8ec065f-93f3-4806-9190-5c4c461200bb
--
-- This script inserts realistic mock data for:
-- - 1 simulated Strava device
-- - 7 days of health data history
-- - Multiple workout sessions
-- - Daily metrics (steps, calories, heart rate, etc.)

-- 1. Insert simulated Strava device
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
  'sim-strava-test-device-001',
  'd8ec065f-93f3-4806-9190-5c4c461200bb',
  'strava',
  'sim-strava-user-12345',
  'Strava (Test Simulation)',
  'smartwatch',
  'connected',
  ARRAY['read', 'activity:read_all', 'activity:read'],
  NOW(),
  '{"simulated": true, "test_device": true, "version": "1.0"}'::jsonb,
  NOW() - INTERVAL '7 days',
  NOW() - INTERVAL '7 days',
  NOW()
) ON CONFLICT (id) DO UPDATE SET
  last_sync_at = NOW(),
  updated_at = NOW();

-- 2. Insert 7 days of daily health metrics
-- Heart Rate data (resting and average throughout day)
INSERT INTO wearable_health_data (
  id, user_id, device_id, data_type, timestamp, value_numeric, unit, quality_score, raw_data, synced_at, created_at
) VALUES
  -- Day 1 (7 days ago)
  ('sim-hr-1-rest', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'sim-strava-test-device-001', 'resting_heart_rate', NOW() - INTERVAL '7 days', 58, 'bpm', 92, '{"simulated": true, "measured_at": "morning"}'::jsonb, NOW(), NOW() - INTERVAL '7 days'),
  ('sim-hr-1-avg', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'sim-strava-test-device-001', 'heart_rate', NOW() - INTERVAL '7 days', 72, 'bpm', 88, '{"simulated": true, "daily_average": true}'::jsonb, NOW(), NOW() - INTERVAL '7 days'),

  -- Day 2 (6 days ago)
  ('sim-hr-2-rest', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'sim-strava-test-device-001', 'resting_heart_rate', NOW() - INTERVAL '6 days', 60, 'bpm', 90, '{"simulated": true, "measured_at": "morning"}'::jsonb, NOW(), NOW() - INTERVAL '6 days'),
  ('sim-hr-2-avg', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'sim-strava-test-device-001', 'heart_rate', NOW() - INTERVAL '6 days', 75, 'bpm', 89, '{"simulated": true, "daily_average": true}'::jsonb, NOW(), NOW() - INTERVAL '6 days'),

  -- Day 3 (5 days ago)
  ('sim-hr-3-rest', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'sim-strava-test-device-001', 'resting_heart_rate', NOW() - INTERVAL '5 days', 57, 'bpm', 94, '{"simulated": true, "measured_at": "morning"}'::jsonb, NOW(), NOW() - INTERVAL '5 days'),
  ('sim-hr-3-avg', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'sim-strava-test-device-001', 'heart_rate', NOW() - INTERVAL '5 days', 78, 'bpm', 91, '{"simulated": true, "daily_average": true}'::jsonb, NOW(), NOW() - INTERVAL '5 days'),

  -- Day 4 (4 days ago)
  ('sim-hr-4-rest', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'sim-strava-test-device-001', 'resting_heart_rate', NOW() - INTERVAL '4 days', 59, 'bpm', 93, '{"simulated": true, "measured_at": "morning"}'::jsonb, NOW(), NOW() - INTERVAL '4 days'),
  ('sim-hr-4-avg', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'sim-strava-test-device-001', 'heart_rate', NOW() - INTERVAL '4 days', 74, 'bpm', 90, '{"simulated": true, "daily_average": true}'::jsonb, NOW(), NOW() - INTERVAL '4 days'),

  -- Day 5 (3 days ago)
  ('sim-hr-5-rest', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'sim-strava-test-device-001', 'resting_heart_rate', NOW() - INTERVAL '3 days', 61, 'bpm', 91, '{"simulated": true, "measured_at": "morning"}'::jsonb, NOW(), NOW() - INTERVAL '3 days'),
  ('sim-hr-5-avg', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'sim-strava-test-device-001', 'heart_rate', NOW() - INTERVAL '3 days', 76, 'bpm', 88, '{"simulated": true, "daily_average": true}'::jsonb, NOW(), NOW() - INTERVAL '3 days'),

  -- Day 6 (2 days ago)
  ('sim-hr-6-rest', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'sim-strava-test-device-001', 'resting_heart_rate', NOW() - INTERVAL '2 days', 58, 'bpm', 95, '{"simulated": true, "measured_at": "morning"}'::jsonb, NOW(), NOW() - INTERVAL '2 days'),
  ('sim-hr-6-avg', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'sim-strava-test-device-001', 'heart_rate', NOW() - INTERVAL '2 days', 73, 'bpm', 92, '{"simulated": true, "daily_average": true}'::jsonb, NOW(), NOW() - INTERVAL '2 days'),

  -- Day 7 (yesterday)
  ('sim-hr-7-rest', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'sim-strava-test-device-001', 'resting_heart_rate', NOW() - INTERVAL '1 day', 60, 'bpm', 93, '{"simulated": true, "measured_at": "morning"}'::jsonb, NOW(), NOW() - INTERVAL '1 day'),
  ('sim-hr-7-avg', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'sim-strava-test-device-001', 'heart_rate', NOW() - INTERVAL '1 day', 77, 'bpm', 90, '{"simulated": true, "daily_average": true}'::jsonb, NOW(), NOW() - INTERVAL '1 day')
ON CONFLICT (id) DO NOTHING;

-- Steps data (daily)
INSERT INTO wearable_health_data (
  id, user_id, device_id, data_type, timestamp, value_numeric, unit, quality_score, raw_data, synced_at, created_at
) VALUES
  ('sim-steps-1', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'sim-strava-test-device-001', 'steps', NOW() - INTERVAL '7 days', 8543, 'steps', 95, '{"simulated": true}'::jsonb, NOW(), NOW() - INTERVAL '7 days'),
  ('sim-steps-2', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'sim-strava-test-device-001', 'steps', NOW() - INTERVAL '6 days', 12234, 'steps', 96, '{"simulated": true}'::jsonb, NOW(), NOW() - INTERVAL '6 days'),
  ('sim-steps-3', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'sim-strava-test-device-001', 'steps', NOW() - INTERVAL '5 days', 6789, 'steps', 93, '{"simulated": true}'::jsonb, NOW(), NOW() - INTERVAL '5 days'),
  ('sim-steps-4', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'sim-strava-test-device-001', 'steps', NOW() - INTERVAL '4 days', 10567, 'steps', 94, '{"simulated": true}'::jsonb, NOW(), NOW() - INTERVAL '4 days'),
  ('sim-steps-5', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'sim-strava-test-device-001', 'steps', NOW() - INTERVAL '3 days', 9234, 'steps', 92, '{"simulated": true}'::jsonb, NOW(), NOW() - INTERVAL '3 days'),
  ('sim-steps-6', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'sim-strava-test-device-001', 'steps', NOW() - INTERVAL '2 days', 11890, 'steps', 97, '{"simulated": true}'::jsonb, NOW(), NOW() - INTERVAL '2 days'),
  ('sim-steps-7', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'sim-strava-test-device-001', 'steps', NOW() - INTERVAL '1 day', 8765, 'steps', 94, '{"simulated": true}'::jsonb, NOW(), NOW() - INTERVAL '1 day')
ON CONFLICT (id) DO NOTHING;

-- Calories data (daily)
INSERT INTO wearable_health_data (
  id, user_id, device_id, data_type, timestamp, value_numeric, unit, quality_score, raw_data, synced_at, created_at
) VALUES
  ('sim-cal-1', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'sim-strava-test-device-001', 'calories', NOW() - INTERVAL '7 days', 2234, 'kcal', 90, '{"simulated": true, "active_calories": 534, "resting_calories": 1700}'::jsonb, NOW(), NOW() - INTERVAL '7 days'),
  ('sim-cal-2', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'sim-strava-test-device-001', 'calories', NOW() - INTERVAL '6 days', 2678, 'kcal', 92, '{"simulated": true, "active_calories": 978, "resting_calories": 1700}'::jsonb, NOW(), NOW() - INTERVAL '6 days'),
  ('sim-cal-3', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'sim-strava-test-device-001', 'calories', NOW() - INTERVAL '5 days', 2089, 'kcal', 88, '{"simulated": true, "active_calories": 389, "resting_calories": 1700}'::jsonb, NOW(), NOW() - INTERVAL '5 days'),
  ('sim-cal-4', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'sim-strava-test-device-001', 'calories', NOW() - INTERVAL '4 days', 2456, 'kcal', 91, '{"simulated": true, "active_calories": 756, "resting_calories": 1700}'::jsonb, NOW(), NOW() - INTERVAL '4 days'),
  ('sim-cal-5', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'sim-strava-test-device-001', 'calories', NOW() - INTERVAL '3 days', 2345, 'kcal', 89, '{"simulated": true, "active_calories": 645, "resting_calories": 1700}'::jsonb, NOW(), NOW() - INTERVAL '3 days'),
  ('sim-cal-6', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'sim-strava-test-device-001', 'calories', NOW() - INTERVAL '2 days', 2567, 'kcal', 93, '{"simulated": true, "active_calories": 867, "resting_calories": 1700}'::jsonb, NOW(), NOW() - INTERVAL '2 days'),
  ('sim-cal-7', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'sim-strava-test-device-001', 'calories', NOW() - INTERVAL '1 day', 2298, 'kcal', 90, '{"simulated": true, "active_calories": 598, "resting_calories": 1700}'::jsonb, NOW(), NOW() - INTERVAL '1 day')
ON CONFLICT (id) DO NOTHING;

-- 3. Insert workout sessions
INSERT INTO wearable_health_data (
  id, user_id, device_id, data_type, timestamp, value_json, unit, quality_score, source_workout_id, raw_data, synced_at, created_at
) VALUES
  -- Workout 1: Morning run (7 days ago)
  (
    'sim-workout-1',
    'd8ec065f-93f3-4806-9190-5c4c461200bb',
    'sim-strava-test-device-001',
    'workout',
    NOW() - INTERVAL '7 days' - INTERVAL '8 hours',
    jsonb_build_object(
      'activityType', 'running',
      'startTime', (NOW() - INTERVAL '7 days' - INTERVAL '8 hours')::text,
      'endTime', (NOW() - INTERVAL '7 days' - INTERVAL '7 hours' - INTERVAL '25 minutes')::text,
      'durationSeconds', 2100,
      'distanceMeters', 5200,
      'caloriesBurned', 420,
      'avgHeartRate', 152,
      'maxHeartRate', 178,
      'elevationGainMeters', 45,
      'avgPace', '6:44',
      'zones', jsonb_build_object(
        'zone1Minutes', 3,
        'zone2Minutes', 8,
        'zone3Minutes', 15,
        'zone4Minutes', 8,
        'zone5Minutes', 1
      )
    ),
    'activity',
    95,
    'strava-workout-sim-001',
    '{"simulated": true, "sport": "running", "device": "strava"}'::jsonb,
    NOW(),
    NOW() - INTERVAL '7 days'
  ),

  -- Workout 2: Cycling session (5 days ago)
  (
    'sim-workout-2',
    'd8ec065f-93f3-4806-9190-5c4c461200bb',
    'sim-strava-test-device-001',
    'workout',
    NOW() - INTERVAL '5 days' - INTERVAL '9 hours',
    jsonb_build_object(
      'activityType', 'cycling',
      'startTime', (NOW() - INTERVAL '5 days' - INTERVAL '9 hours')::text,
      'endTime', (NOW() - INTERVAL '5 days' - INTERVAL '7 hours' - INTERVAL '45 minutes')::text,
      'durationSeconds', 4500,
      'distanceMeters', 28500,
      'caloriesBurned', 780,
      'avgHeartRate', 138,
      'maxHeartRate', 165,
      'elevationGainMeters', 320,
      'avgPace', '9:28',
      'avgCadence', 85,
      'zones', jsonb_build_object(
        'zone1Minutes', 8,
        'zone2Minutes', 25,
        'zone3Minutes', 35,
        'zone4Minutes', 7,
        'zone5Minutes', 0
      )
    ),
    'activity',
    93,
    'strava-workout-sim-002',
    '{"simulated": true, "sport": "cycling", "device": "strava"}'::jsonb,
    NOW(),
    NOW() - INTERVAL '5 days'
  ),

  -- Workout 3: Interval training (3 days ago)
  (
    'sim-workout-3',
    'd8ec065f-93f3-4806-9190-5c4c461200bb',
    'sim-strava-test-device-001',
    'workout',
    NOW() - INTERVAL '3 days' - INTERVAL '18 hours',
    jsonb_build_object(
      'activityType', 'running',
      'startTime', (NOW() - INTERVAL '3 days' - INTERVAL '18 hours')::text,
      'endTime', (NOW() - INTERVAL '3 days' - INTERVAL '17 hours' - INTERVAL '15 minutes')::text,
      'durationSeconds', 2700,
      'distanceMeters', 7800,
      'caloriesBurned', 620,
      'avgHeartRate', 165,
      'maxHeartRate', 189,
      'elevationGainMeters', 78,
      'avgPace', '5:46',
      'zones', jsonb_build_object(
        'zone1Minutes', 2,
        'zone2Minutes', 5,
        'zone3Minutes', 12,
        'zone4Minutes', 18,
        'zone5Minutes', 8
      )
    ),
    'activity',
    96,
    'strava-workout-sim-003',
    '{"simulated": true, "sport": "interval_training", "device": "strava", "intervals": 8}'::jsonb,
    NOW(),
    NOW() - INTERVAL '3 days'
  ),

  -- Workout 4: Easy recovery run (yesterday)
  (
    'sim-workout-4',
    'd8ec065f-93f3-4806-9190-5c4c461200bb',
    'sim-strava-test-device-001',
    'workout',
    NOW() - INTERVAL '1 day' - INTERVAL '7 hours',
    jsonb_build_object(
      'activityType', 'running',
      'startTime', (NOW() - INTERVAL '1 day' - INTERVAL '7 hours')::text,
      'endTime', (NOW() - INTERVAL '1 day' - INTERVAL '6 hours' - INTERVAL '30 minutes')::text,
      'durationSeconds', 1800,
      'distanceMeters', 4200,
      'caloriesBurned', 320,
      'avgHeartRate', 135,
      'maxHeartRate', 152,
      'elevationGainMeters', 22,
      'avgPace', '7:08',
      'zones', jsonb_build_object(
        'zone1Minutes', 5,
        'zone2Minutes', 18,
        'zone3Minutes', 7,
        'zone4Minutes', 0,
        'zone5Minutes', 0
      )
    ),
    'activity',
    92,
    'strava-workout-sim-004',
    '{"simulated": true, "sport": "running", "device": "strava", "recovery": true}'::jsonb,
    NOW(),
    NOW() - INTERVAL '1 day'
  )
ON CONFLICT (id) DO NOTHING;

-- 4. Insert HRV data (Heart Rate Variability - recovery indicator)
INSERT INTO wearable_health_data (
  id, user_id, device_id, data_type, timestamp, value_numeric, unit, quality_score, raw_data, synced_at, created_at
) VALUES
  ('sim-hrv-1', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'sim-strava-test-device-001', 'hrv', NOW() - INTERVAL '7 days', 52, 'ms', 88, '{"simulated": true, "recovery_score": "good"}'::jsonb, NOW(), NOW() - INTERVAL '7 days'),
  ('sim-hrv-2', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'sim-strava-test-device-001', 'hrv', NOW() - INTERVAL '6 days', 48, 'ms', 86, '{"simulated": true, "recovery_score": "moderate"}'::jsonb, NOW(), NOW() - INTERVAL '6 days'),
  ('sim-hrv-3', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'sim-strava-test-device-001', 'hrv', NOW() - INTERVAL '5 days', 55, 'ms', 90, '{"simulated": true, "recovery_score": "excellent"}'::jsonb, NOW(), NOW() - INTERVAL '5 days'),
  ('sim-hrv-4', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'sim-strava-test-device-001', 'hrv', NOW() - INTERVAL '4 days', 51, 'ms', 87, '{"simulated": true, "recovery_score": "good"}'::jsonb, NOW(), NOW() - INTERVAL '4 days'),
  ('sim-hrv-5', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'sim-strava-test-device-001', 'hrv', NOW() - INTERVAL '3 days', 46, 'ms', 84, '{"simulated": true, "recovery_score": "moderate"}'::jsonb, NOW(), NOW() - INTERVAL '3 days'),
  ('sim-hrv-6', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'sim-strava-test-device-001', 'hrv', NOW() - INTERVAL '2 days', 53, 'ms', 89, '{"simulated": true, "recovery_score": "good"}'::jsonb, NOW(), NOW() - INTERVAL '2 days'),
  ('sim-hrv-7', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'sim-strava-test-device-001', 'hrv', NOW() - INTERVAL '1 day', 50, 'ms', 88, '{"simulated": true, "recovery_score": "good"}'::jsonb, NOW(), NOW() - INTERVAL '1 day')
ON CONFLICT (id) DO NOTHING;

-- 5. Insert VO2Max estimates
INSERT INTO wearable_health_data (
  id, user_id, device_id, data_type, timestamp, value_numeric, unit, quality_score, raw_data, synced_at, created_at
) VALUES
  ('sim-vo2-1', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'sim-strava-test-device-001', 'vo2max', NOW() - INTERVAL '7 days', 48.2, 'ml/kg/min', 85, '{"simulated": true, "fitness_level": "good"}'::jsonb, NOW(), NOW() - INTERVAL '7 days'),
  ('sim-vo2-2', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'sim-strava-test-device-001', 'vo2max', NOW() - INTERVAL '3 days', 48.8, 'ml/kg/min', 87, '{"simulated": true, "fitness_level": "good"}'::jsonb, NOW(), NOW() - INTERVAL '3 days'),
  ('sim-vo2-3', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'sim-strava-test-device-001', 'vo2max', NOW() - INTERVAL '1 day', 49.1, 'ml/kg/min', 88, '{"simulated": true, "fitness_level": "good", "improving": true}'::jsonb, NOW(), NOW() - INTERVAL '1 day')
ON CONFLICT (id) DO NOTHING;

-- 6. Insert sync history records
INSERT INTO device_sync_history (
  id, device_id, user_id, sync_type, status, data_types_synced, records_fetched, records_stored, duration_ms, started_at, completed_at, created_at
) VALUES
  ('sync-1', 'sim-strava-test-device-001', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'automatic', 'success', ARRAY['heart_rate', 'steps', 'calories', 'workout'], 45, 45, 2340, NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days' + INTERVAL '2.34 seconds', NOW() - INTERVAL '7 days'),
  ('sync-2', 'sim-strava-test-device-001', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'automatic', 'success', ARRAY['heart_rate', 'steps', 'calories'], 32, 32, 1890, NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days' + INTERVAL '1.89 seconds', NOW() - INTERVAL '6 days'),
  ('sync-3', 'sim-strava-test-device-001', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'automatic', 'success', ARRAY['heart_rate', 'steps', 'calories', 'workout', 'hrv'], 52, 52, 3120, NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days' + INTERVAL '3.12 seconds', NOW() - INTERVAL '5 days'),
  ('sync-4', 'sim-strava-test-device-001', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'automatic', 'success', ARRAY['heart_rate', 'steps', 'calories', 'vo2max'], 38, 38, 2150, NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days' + INTERVAL '2.15 seconds', NOW() - INTERVAL '4 days'),
  ('sync-5', 'sim-strava-test-device-001', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'automatic', 'success', ARRAY['heart_rate', 'steps', 'calories', 'workout', 'hrv'], 48, 48, 2890, NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days' + INTERVAL '2.89 seconds', NOW() - INTERVAL '3 days'),
  ('sync-6', 'sim-strava-test-device-001', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'automatic', 'success', ARRAY['heart_rate', 'steps', 'calories', 'hrv', 'vo2max'], 41, 41, 2450, NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days' + INTERVAL '2.45 seconds', NOW() - INTERVAL '2 days'),
  ('sync-7', 'sim-strava-test-device-001', 'd8ec065f-93f3-4806-9190-5c4c461200bb', 'automatic', 'success', ARRAY['heart_rate', 'steps', 'calories', 'workout', 'hrv', 'vo2max'], 55, 55, 3340, NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day' + INTERVAL '3.34 seconds', NOW() - INTERVAL '1 day')
ON CONFLICT (id) DO NOTHING;

-- Verification query (run this to check the inserted data)
-- SELECT
--   COUNT(*) as total_records,
--   COUNT(DISTINCT data_type) as unique_data_types,
--   MIN(timestamp) as earliest_data,
--   MAX(timestamp) as latest_data
-- FROM wearable_health_data
-- WHERE user_id = 'd8ec065f-93f3-4806-9190-5c4c461200bb';

-- SELECT provider, status, last_sync_at
-- FROM connected_devices
-- WHERE user_id = 'd8ec065f-93f3-4806-9190-5c4c461200bb';
