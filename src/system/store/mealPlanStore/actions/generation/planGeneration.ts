/**
 * Plan Generation Module
 * Handles meal plan generation and regeneration
 */

import { supabase } from '../../../../supabase/client';
import { useUserStore } from '../../../userStore';
import logger from '../../../../../lib/utils/logger';
import type { MealPlanData, MealPlanDay } from '../../types';
import { getWeekStartDate, transformEdgeDayToFrontendDay } from '../../constants';
import { createSkeletonDay } from './helpers';

/**
 * Generate meal plan for a specific week
 */
export const generateMealPlanCore = async (
  weekNumber: number,
  inventory: any[] | undefined,
  selectedInventoryId: string | null,
  referenceStartDate: string | null,
  onProgress: (progress: number, title?: string, subtitle?: string, message?: string) => void,
  onComplete: (plan: MealPlanData) => void,
  onError: (error: Error) => void,
  startProgressSimulation: () => void,
  stopProgressSimulation: () => void
) => {
  if (!selectedInventoryId) {
    logger.error('MEAL_PLAN_STORE', 'No inventory selected for meal plan generation');
    return;
  }

  try {
    onProgress(0, 'Initialisation', 'Préparation de votre plan personnalisé', 'Démarrage de la génération...');

    // Calculate week dates using reference date
    const weekStartDate = getWeekStartDate(weekNumber, referenceStartDate);
    const skeletonDays: MealPlanDay[] = [];

    for (let i = 0; i < 7; i++) {
      const currentDate = new Date(weekStartDate);
      currentDate.setDate(weekStartDate.getDate() + i);
      const dateString = currentDate.toISOString().split('T')[0];
      const dayName = currentDate.toLocaleDateString('fr-FR', { weekday: 'long' });

      skeletonDays.push(createSkeletonDay(dateString, dayName));
    }

    // Initialize skeleton plan immediately
    const skeletonPlan: MealPlanData = {
      id: `week-${weekNumber}-skeleton`,
      weekNumber,
      startDate: weekStartDate.toISOString().split('T')[0],
      days: skeletonDays,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };

    onComplete(skeletonPlan);

    logger.info('MEAL_PLAN_STORE', 'Skeleton plan initialized', {
      weekNumber,
      skeletonDaysCount: skeletonDays.length,
      timestamp: new Date().toISOString()
    });

    // Start progress simulation
    startProgressSimulation();

    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('User not authenticated');

    const userProfile = useUserStore.getState().profile;
    if (!userProfile) throw new Error('User profile not found');

    logger.info('MEAL_PLAN_STORE', 'Starting meal plan generation', {
      weekNumber,
      inventoryId: selectedInventoryId,
      userId: user.id,
      timestamp: new Date().toISOString()
    });

    const weekEndDate = new Date(weekStartDate);
    weekEndDate.setDate(weekStartDate.getDate() + 6);

    // Get session for authentication
    const { data: { session } } = await supabase.auth.getSession();
    if (!session) throw new Error('No session found');

    const response = await fetch(`${import.meta.env.VITE_SUPABASE_URL}/functions/v1/meal-plan-generator`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${session.access_token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        user_id: user.id,
        week_number: weekNumber,
        start_date: weekStartDate.toISOString().split('T')[0],
        end_date: weekEndDate.toISOString().split('T')[0],
        inventory_count: inventory?.length || 0,
        has_preferences: !!userProfile
      })
    });

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    if (!response.body) {
      throw new Error('No response body');
    }

    // Handle SSE stream
    const reader = response.body.getReader();
    const decoder = new TextDecoder();

    let transformedDays: MealPlanDay[] = [];
    let planId = `week-${weekNumber}-${Date.now()}`;
    let nutritionalSummary: any = null;
    let estimatedWeeklyCost: number | null = null;
    let batchCookingDays: string[] = [];
    let aiExplanation: any = null;

    try {
      while (true) {
        const { done, value } = await reader.read();
        if (done) break;

        const chunk = decoder.decode(value);
        const lines = chunk.split('\n');

        for (const line of lines) {
          if (line.startsWith('data: ')) {
            try {
              const data = JSON.parse(line.slice(6));

              if (data.type === 'day') {
                const transformedDay = transformEdgeDayToFrontendDay(data.data);
                transformedDays.push(transformedDay);

                // Replace skeleton day with real day
                const updatedDays = skeletonDays.map(skeletonDay => {
                  const matchingRealDay = transformedDays.find(rd => rd.date === skeletonDay.date);
                  return matchingRealDay || skeletonDay;
                });

                const updatedPlan = {
                  ...skeletonPlan,
                  days: updatedDays,
                  updatedAt: new Date().toISOString()
                };

                onComplete(updatedPlan);

                // Update progress
                const readyDaysCount = transformedDays.filter(d => d.status === 'ready').length;
                const progress = Math.min(90, (readyDaysCount / 7) * 80);
                onProgress(progress);

                logger.info('MEAL_PLAN_STORE', 'Day received and skeleton replaced', {
                  date: transformedDay.date,
                  dayName: transformedDay.dayName,
                  readyDaysCount,
                  progress,
                  timestamp: new Date().toISOString()
                });
              } else if (data.type === 'complete') {
                planId = data.data.id || planId;
                nutritionalSummary = data.data.nutritional_summary;
                estimatedWeeklyCost = data.data.estimated_weekly_cost;
                batchCookingDays = data.data.batch_cooking_days || [];
                aiExplanation = data.data.ai_explanation || null;
              }
            } catch (parseError) {
              logger.warn('MEAL_PLAN_STORE', 'Failed to parse SSE data', {
                line: line,
                error: parseError instanceof Error ? parseError.message : 'Unknown error',
                timestamp: new Date().toISOString()
              });
            }
          }
        }
      }
    } finally {
      reader.releaseLock();
    }

    const readyDays = transformedDays.filter(d => d.status === 'ready');
    if (readyDays.length === 0) {
      throw new Error('No meal plan days received from generation');
    }

    const mealPlanData: MealPlanData = {
      id: planId,
      weekNumber,
      startDate: weekStartDate.toISOString().split('T')[0],
      days: transformedDays,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      nutritionalSummary,
      estimatedWeeklyCost,
      batchCookingDays,
      aiExplanation
    };

    onProgress(100, 'Terminé !', 'Votre plan est prêt', 'Plan de repas généré avec succès');
    onComplete(mealPlanData);

    stopProgressSimulation();

    logger.info('MEAL_PLAN_STORE', 'Meal plan generation completed', {
      weekNumber,
      planId: mealPlanData.id,
      daysCount: readyDays.length,
      timestamp: new Date().toISOString()
    });

    return mealPlanData;

  } catch (error) {
    stopProgressSimulation();
    onError(error instanceof Error ? error : new Error('Unknown error'));
    logger.error('MEAL_PLAN_STORE', 'Meal plan generation failed', {
      weekNumber,
      error: error instanceof Error ? error.message : 'Unknown error',
      timestamp: new Date().toISOString()
    });
    throw error;
  }
};
