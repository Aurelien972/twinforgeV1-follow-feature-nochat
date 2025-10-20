/**
 * Request Validation
 * Validates incoming commit requests with enhanced validation for avatar data
 */
export function validateCommitRequest(request) {
  if (!request) {
    return 'Request body is required';
  }

  const {
    user_id,
    estimate_result,
    match_result,
    semantic_result,
    final_shape_params,
    final_limb_masses,
    ai_refinement_result
  } = request;

  if (!user_id || typeof user_id !== 'string') {
    return 'Valid user_id is required';
  }

  // Validate user_id format and prevent mock IDs in production
  if (user_id.length < 10 || user_id === 'user' || user_id === 'dev' || user_id.startsWith('mock_')) {
    return 'Invalid user_id format - must be a valid UUID';
  }

  if (!estimate_result || typeof estimate_result !== 'object') {
    return 'Valid estimate_result is required';
  }

  // Validate shape_params for NaN values and range
  if (estimate_result.shape_params) {
    for (const [key, value] of Object.entries(estimate_result.shape_params)){
      if (typeof value === 'number') {
        if (!Number.isFinite(value)) {
          return `Invalid estimate_result.shape_params.${key}: must be a finite number`;
        }
        if (value < -10 || value > 10) {
          return `Invalid estimate_result.shape_params.${key}: value ${value} out of physiological range [-10, 10]`;
        }
      }
    }
  }

  // Validate limb_masses for NaN values and range
  if (estimate_result.limb_masses) {
    for (const [key, value] of Object.entries(estimate_result.limb_masses)){
      if (typeof value === 'number') {
        if (!Number.isFinite(value)) {
          return `Invalid estimate_result.limb_masses.${key}: must be a finite number`;
        }
        if (value < 0.1 || value > 5.0) {
          return `Invalid estimate_result.limb_masses.${key}: value ${value} out of physiological range [0.1, 5.0]`;
        }
      }
    }
  }

  if (!match_result || typeof match_result !== 'object') {
    return 'Valid match_result is required';
  }

  if (!semantic_result || typeof semantic_result !== 'object') {
    return 'Valid semantic_result is required';
  }

  // CRITICAL: Validate final_shape_params (from AI refinement or blend)
  if (final_shape_params && typeof final_shape_params === 'object') {
    for (const [key, value] of Object.entries(final_shape_params)){
      if (typeof value === 'number') {
        if (!Number.isFinite(value)) {
          return `Invalid final_shape_params.${key}: must be a finite number`;
        }
        if (value < -10 || value > 10) {
          return `Invalid final_shape_params.${key}: value ${value} out of physiological range [-10, 10]`;
        }
      }
    }
  }

  // CRITICAL: Validate final_limb_masses (from AI refinement or blend)
  if (final_limb_masses && typeof final_limb_masses === 'object') {
    for (const [key, value] of Object.entries(final_limb_masses)){
      if (typeof value === 'number') {
        if (!Number.isFinite(value)) {
          return `Invalid final_limb_masses.${key}: must be a finite number`;
        }
        if (value < 0.1 || value > 5.0) {
          return `Invalid final_limb_masses.${key}: value ${value} out of physiological range [0.1, 5.0]`;
        }
      }
    }
  }

  // Validate ai_refinement_result if present
  if (ai_refinement_result && typeof ai_refinement_result === 'object') {
    console.log('✅ [requestValidator] AI refinement result present', {
      ai_refine: ai_refinement_result.ai_refine,
      hasFinalShapeParams: !!ai_refinement_result.final_shape_params,
      hasFinalLimbMasses: !!ai_refinement_result.final_limb_masses,
      philosophy: 'ai_refinement_validation'
    });
  }

  return null; // Valid request
}
