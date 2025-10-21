import React, { useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X } from 'lucide-react';
import type { Recipe } from '../../domain/recipe';
import GlassCard from '../../ui/cards/GlassCard';
import SpatialIcon from '../../ui/icons/SpatialIcon';
import { ICONS } from '../../ui/icons/registry';

interface RecipeDetailModalProps {
  recipe: Recipe | null;
  isOpen: boolean;
  onClose: () => void;
}

const RecipeDetailModal: React.FC<RecipeDetailModalProps> = ({ recipe, isOpen, onClose }) => {
  // Lock body scroll when modal is open
  useEffect(() => {
    if (isOpen) {
      const scrollbarWidth = window.innerWidth - document.documentElement.clientWidth;
      document.body.style.overflow = 'hidden';
      document.body.style.paddingRight = `${scrollbarWidth}px`;
    } else {
      document.body.style.overflow = '';
      document.body.style.paddingRight = '';
    }

    return () => {
      document.body.style.overflow = '';
      document.body.style.paddingRight = '';
    };
  }, [isOpen]);

  // Handle ESC key
  useEffect(() => {
    const handleEscape = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && isOpen) {
        onClose();
      }
    };

    if (isOpen) {
      document.addEventListener('keydown', handleEscape);
      return () => document.removeEventListener('keydown', handleEscape);
    }
  }, [isOpen, onClose]);

  // Don't render anything if modal is not open or recipe is missing
  if (!isOpen || !recipe) return null;

  return (
    <AnimatePresence mode="wait">
      {isOpen && (
        <>
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 bg-black/60 backdrop-blur-sm"
            style={{
              zIndex: 999998,
              position: 'fixed',
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              pointerEvents: 'auto'
            }}
            onClick={onClose}
          />
          <div
            className="fixed inset-0 flex items-center justify-center p-4"
            style={{
              zIndex: 999999,
              position: 'fixed',
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              pointerEvents: 'none'
            }}
          >
          <motion.div
            initial={{ opacity: 0, scale: 0.95, y: 20 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.95, y: 20 }}
            transition={{ type: 'spring', damping: 25, stiffness: 300 }}
            className="w-full max-w-4xl pointer-events-auto"
            style={{
              maxHeight: '90vh',
              overflowY: 'auto',
              position: 'relative',
              zIndex: 1000000
            }}
          >
              <GlassCard className="p-6 relative">
                <button
                  onClick={onClose}
                  className="absolute top-4 right-4 p-2 rounded-xl bg-white/10 hover:bg-white/20 transition-colors"
                  aria-label="Fermer"
                >
                  <X size={20} className="text-white" />
                </button>

                {recipe.imageUrl && (
                  <img
                    src={recipe.imageUrl}
                    alt={recipe.title}
                    className="w-full h-64 object-cover rounded-xl mb-6"
                  />
                )}

                <h2 className="text-2xl font-bold text-white mb-2">{recipe.title}</h2>
                {recipe.description && (
                  <p className="text-white/70 mb-6">{recipe.description}</p>
                )}

                <div className="grid grid-cols-3 gap-4 mb-6">
                  <div className="glass-card p-4 rounded-xl">
                    <div className="flex items-center gap-2 mb-1">
                      <SpatialIcon Icon={ICONS.Clock} size={16} className="text-cyan-400" />
                      <span className="text-xs text-white/60">Préparation</span>
                    </div>
                    <p className="text-white font-semibold">{recipe.prepTimeMin || 0} min</p>
                  </div>
                  <div className="glass-card p-4 rounded-xl">
                    <div className="flex items-center gap-2 mb-1">
                      <SpatialIcon Icon={ICONS.Flame} size={16} className="text-orange-400" />
                      <span className="text-xs text-white/60">Cuisson</span>
                    </div>
                    <p className="text-white font-semibold">{recipe.cookTimeMin || 0} min</p>
                  </div>
                  <div className="glass-card p-4 rounded-xl">
                    <div className="flex items-center gap-2 mb-1">
                      <SpatialIcon Icon={ICONS.Users} size={16} className="text-pink-400" />
                      <span className="text-xs text-white/60">Portions</span>
                    </div>
                    <p className="text-white font-semibold">{recipe.servings || 2}</p>
                  </div>
                </div>

                {recipe.ingredients && recipe.ingredients.length > 0 && (
                  <div className="mb-6">
                    <h3 className="text-lg font-semibold text-white mb-3">Ingrédients</h3>
                    <div className="space-y-2">
                      {recipe.ingredients.map((ingredient, index) => (
                        <div key={`ingredient-${recipe.id}-${index}-${ingredient?.name || index}`} className="flex items-start gap-2">
                          <span className="text-cyan-400 mt-1">•</span>
                          <span className="text-white/80">
                            {ingredient?.quantity} {ingredient?.unit && ingredient.unit} {ingredient?.name}
                          </span>
                        </div>
                      ))}
                    </div>
                  </div>
                )}

                {recipe.instructions && recipe.instructions.length > 0 && (
                  <div className="mb-6">
                    <h3 className="text-lg font-semibold text-white mb-3">Instructions</h3>
                    <div className="space-y-4">
                      {recipe.instructions.map((instruction, index) => (
                        <div key={instruction?.step || `step-${index}`} className="flex gap-4">
                          <div className="flex-shrink-0 w-8 h-8 rounded-full bg-cyan-500/20 flex items-center justify-center">
                            <span className="text-cyan-400 font-semibold text-sm">{instruction?.step || index + 1}</span>
                          </div>
                          <div className="flex-1">
                            <p className="text-white/80">{instruction?.instruction}</p>
                            {instruction?.timeMin && (
                              <p className="text-white/50 text-sm mt-1">⏱️ {instruction.timeMin} min</p>
                            )}
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                )}

                {recipe.nutritionalInfo && (
                  <div>
                    <h3 className="text-lg font-semibold text-white mb-3">Informations nutritionnelles</h3>
                    <div className="glass-card p-4 rounded-xl grid grid-cols-4 gap-4">
                      <div>
                        <p className="text-white/60 text-xs mb-1">Calories</p>
                        <p className="text-white font-semibold">{recipe.nutritionalInfo.calories} kcal</p>
                      </div>
                      <div>
                        <p className="text-white/60 text-xs mb-1">Protéines</p>
                        <p className="text-white font-semibold">{recipe.nutritionalInfo.protein}g</p>
                      </div>
                      <div>
                        <p className="text-white/60 text-xs mb-1">Glucides</p>
                        <p className="text-white font-semibold">{recipe.nutritionalInfo.carbs}g</p>
                      </div>
                      <div>
                        <p className="text-white/60 text-xs mb-1">Lipides</p>
                        <p className="text-white font-semibold">{recipe.nutritionalInfo.fat}g</p>
                      </div>
                    </div>
                  </div>
                )}
              </GlassCard>
            </motion.div>
          </div>
        </>
      )}
    </AnimatePresence>
  );
};

export default RecipeDetailModal;
