/**
 * Body Scan Celebration Step - Étape de Célébration avec Confettis
 * Remplace l'étape de traitement par une expérience de célébration premium
 */

import React from 'react';
import { ConditionalMotion } from '../../../lib/motion/ConditionalMotion';
import { useBodyScanPerformance } from '../../../hooks/useBodyScanPerformance';
import { useLocation, useNavigate } from 'react-router-dom';
import GlassCard from '../../../ui/cards/GlassCard';
import SpatialIcon from '../../../ui/icons/SpatialIcon';
import { ICONS } from '../../../ui/icons/registry';
import { useFeedback } from '../../../hooks/useFeedback';
import { useProgressStore } from '../../../system/store/progressStore';
import logger from '../../../lib/utils/logger';

/**
 * Body Scan Celebration Step - VisionOS 26 Premium
 * Affiche une célébration avec confettis après le traitement réussi
 */
const BodyScanCelebrationStep: React.FC = () => {
  const performanceConfig = useBodyScanPerformance();
  const location = useLocation();
  const navigate = useNavigate();
  const { successMajor, success } = useFeedback();
  const { completeProgress } = useProgressStore();
  
  // Prevent infinite loops by tracking initialization
  const hasInitialized = React.useRef(false);
  
  // Get scan results from navigation state
  const scanResults = location.state?.scanResults;
  // NOUVEAU: Détecter si c'est un scan facial
  const isFaceScan = location.state?.isFaceScan || false;

  // Redirect if no scan results
  React.useEffect(() => {
    // Prevent multiple executions
    if (hasInitialized.current) return;
    
    if (!scanResults) {
      // MODIFIED: Redirection conditionnelle
      navigate(isFaceScan ? '/avatar#avatar' : '/body-scan', { replace: true });
      return;
    }
    
    // Trigger celebration effects only once
    successMajor();
    completeProgress();
    hasInitialized.current = true;
    
    logger.info('CELEBRATION', 'Celebration step mounted with scan results', {
      hasResults: !!scanResults,
      confidence: getConfidenceFromScanResults(scanResults),
      isFaceScan: isFaceScan // NOUVEAU: Log isFaceScan
    });
  }, [scanResults, navigate, successMajor, completeProgress, isFaceScan]);

  if (!scanResults) {
    return null;
  }

  // FIXED: Extract confidence from multiple possible sources
  const confidence = getConfidenceFromScanResults(scanResults);
  const score = confidence;

  const getCelebrationContent = () => {
    // Adjust particle count based on performance mode
    const getParticleCount = (base: number) => {
      if (performanceConfig.mode === 'high-performance') return 0;
      if (performanceConfig.mode === 'balanced') return Math.ceil(base / 2);
      return base;
    };

    if (score >= 0.9) {
      return {
        title: '🌟 Scan Absolument Parfait !',
        subtitle: 'Votre morphologie a été capturée avec une précision exceptionnelle',
        celebrationMessage: 'Qualité Légendaire Atteinte',
        motivationalQuote: 'Votre reflet numérique sera d\'une fidélité saisissante',
        color: '#10B981',
        icon: ICONS.Zap,
        particleCount: getParticleCount(12),
        celebrationLevel: 'legendary'
      };
    } else if (score >= 0.7) {
      return {
        title: '✨ Scan Exceptionnel !',
        subtitle: 'Votre avatar sera d\'une qualité remarquable',
        celebrationMessage: 'Excellence Morphologique Détectée',
        motivationalQuote: 'Préparez-vous à découvrir votre double numérique parfait',
        color: '#22C55E',
        icon: ICONS.Check,
        particleCount: getParticleCount(10),
        celebrationLevel: 'exceptional'
      };
    } else if (score >= 0.5) {
      return {
        title: '🎯 Scan de Haute Qualité !',
        subtitle: 'Votre morphologie a été analysée avec précision',
        celebrationMessage: 'Analyse Premium Réussie',
        motivationalQuote: 'Votre avatar 3D sera fidèle à votre silhouette unique',
        color: '#10B981',
        icon: ICONS.Target,
        particleCount: getParticleCount(8),
        celebrationLevel: 'high'
      };
    } else if (score > 0) {
      return {
        title: '🚀 Scan Réussi avec Brio !',
        subtitle: 'Votre avatar est prêt avec des optimisations intelligentes',
        celebrationMessage: 'Analyse Avancée Activée',
        motivationalQuote: 'Votre scan a été optimisé avec précision',
        color: '#F59E0B',
        icon: ICONS.Zap,
        particleCount: getParticleCount(6),
        celebrationLevel: 'optimized'
      };
    } else {
      // No confidence data available
      return {
        title: '🎉 Avatar 3D Créé !',
        subtitle: 'Votre reflet numérique est prêt à être découvert',
        celebrationMessage: 'Scan Terminé avec Succès',
        motivationalQuote: 'Explorez votre avatar 3D personnalisé',
        color: '#8B5CF6',
        icon: ICONS.Eye,
        particleCount: getParticleCount(6),
        celebrationLevel: 'complete'
      };
    }
  };

  const celebration = getCelebrationContent();

  const handleDiscoverAvatar = () => {
    success();
    // MODIFIED: Redirection conditionnelle
    navigate(isFaceScan ? '/avatar#avatar' : '/body-scan/review', { 
      state: { scanResults },
      replace: false
    });
  };

  return (
    <div className="relative overflow-visible pt-4 pb-6 md:pb-8">
      {/* Celebration Background Effects - disabled in performance mode */}
      {performanceConfig.enableParticleEffects && (
        <div className="celebration-background-effects absolute inset-0 pointer-events-none overflow-visible">
        {/* Ambient Glow Background */}
        <div
          className="celebration-ambient-glow absolute inset-0 rounded-3xl"
          style={{
            background: `radial-gradient(circle at center, ${celebration.color}15, transparent 70%)`,
            '--celebration-color': celebration.color
          }}
        />

        {/* Floating Celebration Particles */}
        {[...Array(celebration.particleCount)].map((_, i) => (
          <div
            key={i}
            className={`celebration-particle celebration-particle--${i + 1} absolute w-3 h-3 rounded-full`}
            style={{
              background: `radial-gradient(circle, ${celebration.color}, ${celebration.color}80)`,
              left: `${15 + i * 8}%`,
              top: `${20 + (i % 4) * 15}%`,
              boxShadow: `0 0 12px ${celebration.color}80, 0 0 24px ${celebration.color}40`,
              '--celebration-color': celebration.color,
              '--particle-index': i
            }}
          />
        ))}

        {/* Celebration Rays */}
        {[...Array(6)].map((_, i) => (
          <div
            key={`ray-${i}`}
            className={`celebration-ray celebration-ray--${i + 1} absolute w-1 h-20 rounded-full`}
            style={{
              background: `linear-gradient(180deg, ${celebration.color}60, transparent)`,
              left: `${30 + i * 12}%`,
              top: '10%',
              transformOrigin: 'bottom center',
              '--celebration-color': celebration.color
            }}
          />
        ))}
        </div>
      )}

      {/* Main Celebration Content */}
      <div className="celebration-main-content relative text-center py-8 md:py-12 z-10">
        {/* Central Celebration Icon with Multi-Layer Effects */}
        <ConditionalMotion
          className="relative w-32 h-32 mx-auto mb-8"
          initial={performanceConfig.enableInitialAnimations ? { scale: 0, rotate: -180 } : false}
          animate={performanceConfig.enableInitialAnimations ? { scale: 1, rotate: 0 } : { scale: 1 }}
          transition={performanceConfig.enableFramerMotion ? {
            type: 'spring',
            stiffness: 200,
            damping: 15,
            duration: 1.2
          } : undefined}
        >
          {/* Outer Glow Ring */}
          <div
            className="celebration-icon-outer-glow absolute inset-0 rounded-full"
            style={{
              background: `radial-gradient(circle, ${celebration.color}40, transparent 70%)`,
              filter: `blur(8px)`,
              '--celebration-color': celebration.color
            }}
          />

          {/* Inner Icon Container */}
          <div
            className="celebration-icon-inner-container absolute inset-8 rounded-full flex items-center justify-center"
            style={{
              background: `linear-gradient(135deg, ${celebration.color}30, ${celebration.color}60)`,
              border: `2px solid ${celebration.color}`,
              boxShadow: `0 0 60px ${celebration.color}90, inset 0 4px 0 rgba(255,255,255,0.3)`,
              '--celebration-color': celebration.color
            }}
          >
            <SpatialIcon Icon={celebration.icon} size={48} color={celebration.color} />
          </div>

          {/* Pulse Rings - disabled in performance mode, reduced in balanced */}
          {performanceConfig.enablePulseAnimations && [
            ...Array(performanceConfig.mode === 'quality' ? 3 : 1)
          ].map((_, i) => (
            <div
              key={`pulse-${i}`}
              className={`celebration-icon-pulse-ring celebration-icon-pulse-ring--${i + 1} absolute inset-0 rounded-full border-2`}
              style={{
                borderColor: `${celebration.color}40`,
                '--celebration-color': celebration.color
              }}
            />
          ))}
        </ConditionalMotion>
        
        {/* Celebration Text - Optimized for Above the Fold */}
        <ConditionalMotion
          initial={performanceConfig.enableInitialAnimations ? { opacity: 0, y: 30 } : false}
          animate={performanceConfig.enableInitialAnimations ? { opacity: 1, y: 0 } : { opacity: 1 }}
          transition={performanceConfig.enableFramerMotion ? { delay: 0.6, duration: 0.8 } : undefined}
        >
          <ConditionalMotion
            as="h3"
            className="celebration-title-glow text-4xl md:text-5xl font-bold text-white mb-4"
            style={{ color: celebration.color }}
          >
            {celebration.title}
          </ConditionalMotion>

          <ConditionalMotion
            as="p"
            className="text-xl text-white/90 mb-6 leading-relaxed max-w-2xl mx-auto"
            initial={performanceConfig.enableStaggerAnimations ? { opacity: 0, y: 20 } : false}
            animate={performanceConfig.enableStaggerAnimations ? { opacity: 1, y: 0 } : { opacity: 1 }}
            transition={performanceConfig.enableFramerMotion ? { delay: 0.8, duration: 0.6 } : undefined}
          >
            {celebration.subtitle}
          </ConditionalMotion>
        </ConditionalMotion>
      </div>

      {/* Call to Action */}
      <ConditionalMotion
        className="flex justify-center relative z-10 mt-4"
        initial={performanceConfig.enableInitialAnimations ? { opacity: 0, y: 40 } : false}
        animate={performanceConfig.enableInitialAnimations ? { opacity: 1, y: 0 } : { opacity: 1 }}
        transition={performanceConfig.enableFramerMotion ? { delay: 1.0, duration: 0.8 } : undefined}
      >
        <ConditionalMotion
          as="button"
          onClick={handleDiscoverAvatar}
          className="btn-glass--primary px-12 py-6 text-xl font-bold relative overflow-hidden"
          whileHover={performanceConfig.enableWhileHover ? { scale: 1.03 } : undefined}
          whileTap={performanceConfig.enableWhileTap ? { scale: 0.97 } : undefined}
          style={{
            background: `linear-gradient(135deg, ${celebration.color}80, ${celebration.color}60)`,
            boxShadow: `0 12px 40px ${celebration.color}40, 0 0 60px ${celebration.color}30`,
            border: `2px solid ${celebration.color}`,
            color: '#0B0F1A'
          }}
        >
          {/* Shimmer Effect - disabled in performance mode */}
          {performanceConfig.enableShimmerEffects && (
            <div
              className="celebration-cta-shimmer absolute inset-0 bg-gradient-to-r from-transparent via-white/30 to-transparent"
            />
          )}

          {/* Celebration Sparkles - disabled in performance mode */}
          {performanceConfig.enableParticleEffects && [...Array(4)].map((_, i) => (
            <div
              key={i}
              className={`celebration-cta-sparkle celebration-cta-sparkle--${i + 1} absolute w-2 h-2 rounded-full bg-white`}
              style={{
                left: `${20 + i * 20}%`,
                top: `${30 + (i % 2) * 40}%`
              }}
            />
          ))}
          
          <div className="relative flex items-center justify-center gap-4">
            <SpatialIcon Icon={ICONS.Eye} size={28} color="#0B0F1A" />
            <span>Mon Avatar 3D</span>
          </div>
        </ConditionalMotion>
      </ConditionalMotion>

      {/* Celebration Confetti Effect - disabled in performance mode, reduced in balanced */}
      {performanceConfig.enableParticleEffects && (
        <div className="absolute inset-0 pointer-events-none overflow-visible">
          {[
            ...Array(performanceConfig.mode === 'quality' ? 8 : performanceConfig.mode === 'balanced' ? 4 : 0)
          ].map((_, i) => (
            <div
              key={`confetti-${i}`}
              className={`celebration-confetti celebration-confetti--${i + 1} absolute w-2 h-6 rounded-full`}
              style={{
                background: `linear-gradient(180deg, ${celebration.color}, ${celebration.color}60)`,
                left: `${10 + i * 10}%`,
                top: '-10%',
                '--celebration-color': celebration.color
              }}
            />
          ))}
        </div>
      )}
    </div>
  );
};

/**
 * Extract confidence from scan results with fallback strategy
 */
function getConfidenceFromScanResults(scanResults: any): number {
  // PRIORITY 1: AI refinement confidence (most accurate after complete processing)
  const aiRefinementConfidence = scanResults?.match?.ai_refinement?.ai_confidence;
  if (typeof aiRefinementConfidence === 'number' && Number.isFinite(aiRefinementConfidence) && aiRefinementConfidence > 0 && aiRefinementConfidence <= 1) {
    logger.debug('CELEBRATION', 'Using AI refinement confidence (highest priority)', {
      confidence: aiRefinementConfidence,
      source: 'ai_refinement.ai_confidence',
      clientScanId: scanResults?.clientScanId,
      serverScanId: scanResults?.serverScanId,
      philosophy: 'ai_refinement_confidence_priority'
    });
    return aiRefinementConfidence;
  }
  
  // Try other sources for confidence with proper validation (fallback hierarchy)
  const sources = [
    scanResults?.match?.semantic_coherence_score,
    scanResults?.estimate?.extracted_data?.processing_confidence,
    scanResults?.insights?.confidence,
    scanResults?.estimate?.confidence?.vision,
    scanResults?.semantic?.semantic_confidence,
    scanResults?.commit?.confidence,
    scanResults?.blending?.confidence
  ];
  
  for (const source of sources) {
    if (typeof source === 'number' && Number.isFinite(source) && source > 0 && source <= 1) {
      logger.debug('CELEBRATION', 'Found valid confidence from fallback source', {
        confidence: source,
        source: 'fallback_hierarchy',
        clientScanId: scanResults?.clientScanId,
        serverScanId: scanResults?.serverScanId,
        philosophy: 'fallback_confidence_used'
      });
      return source;
    }
  }
  
  logger.warn('CELEBRATION', 'No valid confidence found in scan results (including AI refinement)', {
    clientScanId: scanResults?.clientScanId,
    serverScanId: scanResults?.serverScanId,
    sourcesChecked: [
      { source: 'ai_refinement.ai_confidence', value: aiRefinementConfidence, type: typeof aiRefinementConfidence, isValid: typeof aiRefinementConfidence === 'number' && Number.isFinite(aiRefinementConfidence) && aiRefinementConfidence > 0 && aiRefinementConfidence <= 1 },
      ...sources.map((s, i) => ({ index: i, value: s, type: typeof s, isValid: typeof s === 'number' && Number.isFinite(s) && s > 0 && s <= 1 }))
    ],
    philosophy: 'no_confidence_found_comprehensive_check'
  });
  
  // Return 0 if no valid confidence found (will hide score display in UI)
  return 0;
}

export default BodyScanCelebrationStep;
