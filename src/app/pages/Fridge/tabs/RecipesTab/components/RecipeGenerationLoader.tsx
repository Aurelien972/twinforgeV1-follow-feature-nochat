import React from 'react';
import { motion } from 'framer-motion';
import { usePerformanceMode } from '../../../../../../system/context/PerformanceModeContext';
import GlassCard from '../../../../../../ui/cards/GlassCard';
import SpatialIcon from '../../../../../../ui/icons/SpatialIcon';
import { ICONS } from '../../../../../../ui/icons/registry';

/**
 * Recipe Generation Loader - Animated loader for recipe generation
 * Displays during recipe generation process with green energy theme
 * Enhanced with vibrant green color palette and smooth animations
 */
const RecipeGenerationLoader: React.FC = () => {
  const { isPerformanceMode } = usePerformanceMode();
  const MotionDiv = isPerformanceMode ? 'div' : motion.div;

  return (
    <MotionDiv
      {...(!isPerformanceMode && {
        initial: { opacity: 0, y: 20 },
        animate: { opacity: 1, y: 0 },
        exit: { opacity: 0, y: -20 },
        transition: { duration: 0.5 }
      })}
      className="mb-6"
    >
      <GlassCard
        className="p-8 text-center relative overflow-hidden"
        style={{
          background: `
            radial-gradient(circle at 30% 20%, color-mix(in srgb, #10B981 12%, transparent) 0%, transparent 60%),
            radial-gradient(circle at 70% 80%, color-mix(in srgb, #34D399 8%, transparent) 0%, transparent 50%),
            linear-gradient(145deg, rgba(255,255,255,0.08), rgba(255,255,255,0.05)),
            var(--glass-opacity)
          `,
          borderColor: 'color-mix(in srgb, #10B981 30%, transparent)',
          boxShadow: `
            0 20px 60px rgba(0, 0, 0, 0.3),
            0 0 40px color-mix(in srgb, #10B981 20%, transparent),
            inset 0 2px 0 rgba(255, 255, 255, 0.15)
          `,
          backdropFilter: 'blur(24px) saturate(150%)',
          WebkitBackdropFilter: 'blur(24px) saturate(150%)'
        }}
      >
        <div className="space-y-6">
          {/* Enhanced Animated Icon with Green Glow */}
          <div className="flex justify-center">
            <div
              className="relative"
              style={{
                width: '96px',
                height: '96px',
                overflow: 'hidden',
                contain: 'paint layout'
              }}
            >
              <div
                className={`absolute inset-0 rounded-full flex items-center justify-center ${isPerformanceMode ? '' : 'recipe-gen-icon-pulse'}`}
                style={{
                  background: `
                    radial-gradient(circle at 30% 30%, rgba(255, 255, 255, 0.25) 0%, transparent 60%),
                    linear-gradient(135deg,
                      color-mix(in srgb, #10B981 40%, transparent),
                      color-mix(in srgb, #34D399 35%, transparent)
                    )
                  `,
                  border: '3px solid color-mix(in srgb, #10B981 60%, transparent)',
                  boxShadow: isPerformanceMode ? 'none' : `
                    0 0 30px color-mix(in srgb, #10B981 50%, transparent),
                    0 0 60px color-mix(in srgb, #34D399 30%, transparent),
                    inset 0 2px 0 rgba(255, 255, 255, 0.3)
                  `
                }}
              >
                <MotionDiv
                  {...(!isPerformanceMode && {
                    animate: { rotate: 360 },
                    transition: { repeat: Infinity, duration: 3, ease: "linear" }
                  })}
                >
                  <SpatialIcon
                    Icon={ICONS.ChefHat}
                    size={48}
                    color="#fff"
                    variant="pure"
                  />
                </MotionDiv>
              </div>

              {/* Pulsing Ring Effect */}
              {!isPerformanceMode && (
                <div
                  className="absolute rounded-full recipe-gen-ring-pulse"
                  style={{
                    border: '2px solid color-mix(in srgb, #10B981 40%, transparent)',
                    top: '-10%',
                    left: '-10%',
                    right: '-10%',
                    bottom: '-10%',
                    pointerEvents: 'none'
                  }}
                />
              )}
            </div>
          </div>

          {/* Enhanced Loading Text with Green Glow */}
          <div className="space-y-3">
            <h3
              className="text-3xl font-bold text-white"
              style={{
                textShadow: isPerformanceMode ? 'none' : '0 0 25px color-mix(in srgb, #10B981 60%, transparent)'
              }}
            >
              Génération de Recettes en Cours
            </h3>
            <p className="text-white/90 text-lg">
              La Forge Spatiale compose vos recettes personnalisées
            </p>
          </div>

          {/* Enhanced Animated Dots with Green Theme */}
          <div className="flex justify-center gap-3">
            {[0, 1, 2].map((index) => (
              <MotionDiv
                key={index}
                className="rounded-full"
                style={{
                  width: '12px',
                  height: '12px',
                  background: 'linear-gradient(135deg, #10B981, #34D399)',
                  boxShadow: isPerformanceMode ? 'none' : '0 0 12px color-mix(in srgb, #10B981 60%, transparent)'
                }}
                {...(!isPerformanceMode && {
                  animate: {
                    scale: [1, 1.4, 1],
                    opacity: [0.6, 1, 0.6]
                  },
                  transition: {
                    duration: 1.2,
                    repeat: Infinity,
                    delay: index * 0.15,
                    ease: "easeInOut"
                  }
                })}
              />
            ))}
          </div>

          {/* Enhanced Progress Indicator */}
          <div className="space-y-4">
            <div className="flex items-center justify-center gap-2 text-sm" style={{ color: '#D1FAE5' }}>
              <SpatialIcon
                Icon={ICONS.Sparkles}
                size={16}
                color="#10B981"
                variant="pure"
              />
              <span>Analyse des ingrédients et génération des instructions...</span>
            </div>

            {/* Enhanced Animated Progress Bar with Green Energy */}
            <div
              className="w-full max-w-md mx-auto h-3 rounded-full relative"
              style={{
                background: 'rgba(16, 185, 129, 0.15)',
                boxShadow: 'inset 0 2px 4px rgba(0, 0, 0, 0.2)',
                overflow: 'hidden',
                contain: 'paint layout'
              }}
            >
              <MotionDiv
                className="h-full rounded-full relative"
                style={{
                  background: 'linear-gradient(90deg, #10B981, #34D399, #6EE7B7)',
                  boxShadow: isPerformanceMode ? 'none' : '0 0 15px color-mix(in srgb, #10B981 60%, transparent)',
                  maxWidth: '100%'
                }}
                {...(!isPerformanceMode && {
                  animate: {
                    width: ['30%', '70%', '30%']
                  },
                  transition: {
                    duration: 2.5,
                    repeat: Infinity,
                    ease: "easeInOut"
                  }
                })}
              >
                {!isPerformanceMode && (
                  <div
                    className="absolute inset-0 rounded-full"
                    style={{
                      background: 'linear-gradient(90deg, transparent 0%, rgba(255,255,255,0.4) 50%, transparent 100%)',
                      animation: 'recipe-shimmer 1.5s ease-in-out infinite',
                      overflow: 'hidden'
                    }}
                  />
                )}
              </MotionDiv>
            </div>
          </div>

          {/* Energy Particles */}
          {!isPerformanceMode && (
            <div className="absolute inset-0 pointer-events-none overflow-hidden">
              {[...Array(6)].map((_, i) => (
                <div
                  key={i}
                  className="absolute w-1 h-1 rounded-full recipe-gen-particle"
                  style={{
                    background: '#10B981',
                    left: `${20 + i * 12}%`,
                    top: `${30 + (i % 3) * 20}%`,
                    animationDelay: `${i * 0.3}s`,
                    boxShadow: '0 0 8px color-mix(in srgb, #10B981 80%, transparent)'
                  }}
                />
              ))}
            </div>
          )}
        </div>
      </GlassCard>

      {/* Inline Keyframes for Custom Animations */}
      <style>{`
        @keyframes recipe-gen-icon-pulse {
          0%, 100% {
            transform: scale(1);
            box-shadow: 0 0 30px color-mix(in srgb, #10B981 50%, transparent),
                        0 0 60px color-mix(in srgb, #34D399 30%, transparent),
                        inset 0 2px 0 rgba(255, 255, 255, 0.3);
          }
          50% {
            transform: scale(1.05);
            box-shadow: 0 0 40px color-mix(in srgb, #10B981 70%, transparent),
                        0 0 80px color-mix(in srgb, #34D399 50%, transparent),
                        inset 0 2px 0 rgba(255, 255, 255, 0.35);
          }
        }

        @keyframes recipe-gen-ring-pulse {
          0%, 100% {
            opacity: 0.3;
            transform: scale(1);
          }
          50% {
            opacity: 0.6;
            transform: scale(1.15);
          }
        }

        .recipe-gen-ring-pulse {
          animation: recipe-gen-ring-pulse 2s ease-in-out infinite;
        }

        @keyframes recipe-shimmer {
          0% { transform: translateX(-100%); }
          100% { transform: translateX(200%); }
        }

        @keyframes recipe-gen-particle {
          0%, 100% {
            transform: translateY(0) scale(1);
            opacity: 0.4;
          }
          25% {
            transform: translateY(-10px) scale(1.3);
            opacity: 0.8;
          }
          50% {
            transform: translateY(-5px) scale(0.9);
            opacity: 0.6;
          }
          75% {
            transform: translateY(-15px) scale(1.2);
            opacity: 0.9;
          }
        }

        .recipe-gen-particle {
          animation: recipe-gen-particle 3s ease-in-out infinite;
        }

        @media (prefers-reduced-motion: reduce) {
          .recipe-gen-icon-pulse,
          .recipe-gen-ring-pulse,
          .recipe-gen-particle {
            animation: none !important;
          }
        }
      `}</style>
    </MotionDiv>
  );
};

export default RecipeGenerationLoader;