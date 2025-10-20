import React from 'react';
import { motion } from 'framer-motion';
import { usePerformanceMode } from '../../../../../system/context/PerformanceModeContext';
import CalorieHighlightCard from './CalorieHighlightCard';
import MacronutrientsCard from './MacronutrientsCard';
import DetectedFoodsCard from './DetectedFoodsCard';
import PhotoDisplayCard from './PhotoDisplayCard';
import ActionButtons from './ActionButtons';
import MealProgressHeader from '../MealProgressHeader';

interface CapturedMealPhoto {
  file: File;
  url: string;
  validationResult: {
    isValid: boolean;
    issues: string[];
    confidence: number;
  };
  captureReport: any;
}

interface MealResultsDisplayStepProps {
  analysisResults: any;
  capturedPhoto: CapturedMealPhoto | null;
  onSaveMeal: () => Promise<void>;
  isSaving: boolean;
  onRetake: () => void;
  onNewScan: () => void;
  progress: number;
  progressMessage: string;
  progressSubMessage: string;
}

/**
 * Meal Results Display Step - Orchestrateur Principal
 * Coordonne l'affichage des résultats d'analyse de repas
 */
const MealResultsDisplayStep: React.FC<MealResultsDisplayStepProps> = ({
  analysisResults,
  capturedPhoto,
  onSaveMeal,
  isSaving,
  onRetake,
  onNewScan,
  progress,
  progressMessage,
  progressSubMessage,
}) => {
  const { isPerformanceMode } = usePerformanceMode();
  const [celebrationActive, setCelebrationActive] = React.useState(false);


  if (!analysisResults || !capturedPhoto) {
    return null;
  }

  // Gérer l'effet de célébration
  React.useEffect(() => {
    if (isSaving) {
      setCelebrationActive(true);
    } else {
      // Désactiver la célébration après un délai
      const timer = setTimeout(() => setCelebrationActive(false), 1000);
      return () => clearTimeout(timer);
    }
  }, [isSaving]);

  return (
    <div className={`space-y-6 w-full meal-results-enter pb-6 ${celebrationActive ? 'celebration-active celebration-glow-css' : ''}`}>
      {/* MealProgressHeader au-dessus de tout */}
      <MealProgressHeader
        currentStep="results"
        progress={progress}
        message={progressMessage}
        subMessage={progressSubMessage}
        celebrationActive={celebrationActive}
      />
      
      <div>
        <CalorieHighlightCard
          totalCalories={analysisResults.total_calories}
          mealName={analysisResults.meal_name}
          confidence={analysisResults.confidence}
          analysisModel={analysisResults.analysis_metadata?.analysis_model_used || 'advanced'}
          celebrationActive={celebrationActive}
          analysisMetadata={analysisResults.analysis_metadata}
        />
      </div>
      
      <div>
        <MacronutrientsCard 
          analysisResults={analysisResults}
          celebrationActive={celebrationActive}
        />
      </div>
      
      <div>
        <DetectedFoodsCard analysisResults={analysisResults} />
      </div>
      
      <div>
        <PhotoDisplayCard capturedPhoto={capturedPhoto} />
      </div>
      
      <div>
        <ActionButtons
          isSaving={isSaving}
          onSaveMeal={onSaveMeal}
          onRetake={onRetake}
          onNewScan={onNewScan}
          analysisResults={analysisResults}
        />
      </div>
    </div>
  );
};

export default MealResultsDisplayStep;