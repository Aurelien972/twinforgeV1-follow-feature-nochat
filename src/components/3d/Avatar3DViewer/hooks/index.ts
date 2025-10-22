/**
 * Avatar 3D Viewer Hooks - Central Exports
 * Provides clean imports for all viewer-related hooks
 */

export { useAvatarViewerOrchestrator } from './useAvatarViewerOrchestrator.refactored';
export { useSceneLifecycle } from './useSceneLifecycle';
export { useModelLifecycle } from './useModelLifecycle';
export { useMorphLifecycle } from './useMorphLifecycle';
export { useMaterialLifecycle } from './useMaterialLifecycle';
export { useViewerState } from './useViewerState';
export { useCameraControls } from './useCameraControls';
export { useMorphUpdates } from './useMorphUpdates';
export { useViewerInitialization } from './useViewerInitialization';

export type { AvatarViewerOrchestratorResult } from './useAvatarViewerOrchestrator.refactored';
export type { ViewerStateRefs } from './useViewerState';
