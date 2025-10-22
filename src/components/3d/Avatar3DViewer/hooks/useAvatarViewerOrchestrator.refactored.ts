/**
 * Avatar Viewer Orchestrator Hook - Refactored & Modular
 * Coordinates all lifecycle hooks and manages complete viewer state
 *
 * This is a refactored version that delegates responsibilities to specialized hooks and utilities.
 */

import { useLayoutEffect, useEffect, useCallback } from 'react';
import { useSceneLifecycle } from './useSceneLifecycle';
import { useModelLifecycle } from './useModelLifecycle';
import { useMorphLifecycle } from './useMorphLifecycle';
import { useMaterialLifecycle } from './useMaterialLifecycle';
import { useViewerState } from './useViewerState';
import { useCameraControls } from './useCameraControls';
import { useMorphUpdates } from './useMorphUpdates';
import { useViewerInitialization } from './useViewerInitialization';
import { useMorphologyMapping } from '../../../../hooks/useMorphologyMapping';
import type { Avatar3DViewerProps, ViewerState } from '../utils/viewerTypes';
import { mobileMemoryMonitor, cleanupThreeJSResources } from '../../../../lib/3d/performance/mobileMemoryMonitor';
import logger from '../../../../lib/utils/logger';

interface UseAvatarViewerOrchestratorProps extends Avatar3DViewerProps {
  container: HTMLDivElement | null;
}

export interface AvatarViewerOrchestratorResult {
  viewerState: ViewerState;
  scene: THREE.Scene | null;
  renderer: THREE.WebGLRenderer | null;
  camera: THREE.PerspectiveCamera | null;
  controls: any;
  model: THREE.Group | null;
  mainMesh: THREE.SkinnedMesh | null;
  setCameraView: (view: 'front' | 'profile' | 'threequarter') => void;
  toggleAutoRotate: () => void;
  resetCamera: () => void;
  updateMorphData: (morphData: Record<string, number>) => void;
  retryInitialization: () => void;
  forceMorphsUpdate: (morphData: Record<string, number>) => void;
  isReady: boolean;
  hasError: boolean;
  errorMessage: string | null;
}

/**
 * Central orchestrator hook for Avatar 3D Viewer
 * Delegates to specialized hooks for better separation of concerns
 */
export function useAvatarViewerOrchestrator(
  props: UseAvatarViewerOrchestratorProps
): AvatarViewerOrchestratorResult {
  const {
    container,
    serverScanId,
    onViewerReady,
    autoRotate = false,
    faceMorphData,
    faceSkinTone,
    faceOnly = false,
    ...restProps
  } = props;

  const { data: morphologyMapping } = useMorphologyMapping();

  const {
    viewerState,
    setViewerState,
    refs,
    finalGender,
    processedSkinTone,
    isReady,
    hasError
  } = useViewerState({
    props,
    autoRotate,
    onViewerReady
  });

  refs.morphologyMappingRef.current = morphologyMapping;

  useLayoutEffect(() => {
    if (refs.isFullyInitializedRef.current) return;

    logger.debug('ORCHESTRATOR', 'Initialization values', {
      finalGender,
      skinToneRGB: processedSkinTone?.rgb ? `rgb(${processedSkinTone.rgb.r}, ${processedSkinTone.rgb.g}, ${processedSkinTone.rgb.b})` : 'none',
      serverScanId,
      faceOnly,
      hasMorphologyMapping: !!morphologyMapping,
      hasOverrideProps: !!(props.overrideMorphData || props.overrideGender || props.overrideSkinTone),
      containerDimensions: container ? { width: container.clientWidth, height: container.clientHeight } : null,
      philosophy: 'orchestrator_initialization'
    });
  }, [finalGender, processedSkinTone, serverScanId, faceOnly, morphologyMapping, container, props.overrideMorphData, props.overrideGender, props.overrideSkinTone, refs]);

  const sceneLifecycle = useSceneLifecycle({
    container,
    finalGender,
    serverScanId,
    faceOnly,
    onSceneReady: useCallback(() => {
      logger.info('ORCHESTRATOR', 'Scene ready, proceeding to model loading', {
        serverScanId,
        philosophy: 'scene_to_model_transition'
      });
    }, [serverScanId])
  });

  const morphLifecycle = useMorphLifecycle({
    finalGender,
    morphologyMapping,
    serverScanId
  });

  const materialLifecycle = useMaterialLifecycle({
    scene: sceneLifecycle.scene,
    skinTone: processedSkinTone,
    finalGender,
    serverScanId
  });

  const { handleModelLoaded, retryInitialization } = useViewerInitialization({
    container,
    refs,
    viewerState,
    setViewerState,
    sceneLifecycle,
    modelLifecycle: { isLoading: false, loadModel: () => Promise.resolve() } as any,
    morphLifecycle,
    materialLifecycle,
    finalGender,
    processedSkinTone,
    serverScanId,
    faceOnly,
    autoRotate
  });

  const modelLifecycle = useModelLifecycle({
    finalGender,
    serverScanId,
    onModelLoaded: handleModelLoaded
  });

  const cameraControls = useCameraControls({
    viewerState,
    setViewerState,
    controls: sceneLifecycle.controls
  });

  const morphUpdates = useMorphUpdates({
    refs,
    viewerState: { isViewerReady: viewerState.isViewerReady },
    modelRef: modelLifecycle.modelRef,
    overrideMorphData: props.overrideMorphData,
    overrideLimbMasses: props.overrideLimbMasses,
    overrideSkinTone: props.overrideSkinTone,
    faceOnly,
    morphologyMapping,
    applyMorphs: morphLifecycle.applyMorphs,
    applyLimbMasses: morphLifecycle.applyLimbMasses,
    configureMaterials: materialLifecycle.configureMaterials
  });

  useEffect(() => {
    if (!sceneLifecycle.scene) return;

    const cleanupCallback = () => {
      if (sceneLifecycle.scene) {
        cleanupThreeJSResources(sceneLifecycle.scene);
      }
    };

    mobileMemoryMonitor.onMemoryPressure(cleanupCallback);

    logger.info('ORCHESTRATOR', 'Registered Three.js cleanup callback for memory pressure', {
      serverScanId,
      philosophy: 'memory_pressure_cleanup_registered'
    });
  }, [sceneLifecycle.scene, serverScanId]);

  useLayoutEffect(() => {
    if (!refs.isProjectionSessionActiveRef.current || !import.meta.env.DEV) return;

    const logInterval = setInterval(() => {
      logger.info('ORCHESTRATOR', '📊 PROJECTION SESSION STATS', {
        sessionActive: refs.isProjectionSessionActiveRef.current,
        fullyInitialized: refs.isFullyInitializedRef.current,
        updateAttempts: morphUpdates.updateStats.attempts,
        successfulUpdates: morphUpdates.updateStats.successes,
        successRate: morphUpdates.updateStats.attempts > 0
          ? `${((morphUpdates.updateStats.successes / morphUpdates.updateStats.attempts) * 100).toFixed(1)}%`
          : 'N/A',
        viewerReady: viewerState.isViewerReady,
        hasModel: !!modelLifecycle.model,
        philosophy: 'projection_session_stats'
      });
    }, 10000);

    return () => clearInterval(logInterval);
  }, [viewerState.isViewerReady, modelLifecycle.model, refs, morphUpdates.updateStats]);

  useEffect(() => {
    return () => {
      mobileMemoryMonitor.stopMonitoring();
      logger.info('ORCHESTRATOR', 'Memory monitoring stopped on unmount', {
        serverScanId,
        philosophy: 'memory_monitoring_cleanup'
      });
    };
  }, [serverScanId]);

  const forceMorphsUpdate = useCallback((morphData: Record<string, number>) => {
    if (modelLifecycle.modelRef.current) {
      morphLifecycle.forceMorphsUpdate(
        modelLifecycle.modelRef.current,
        morphData,
        faceMorphData,
        morphologyMapping
      );
      logger.debug('ORCHESTRATOR', 'Forced morph cache reset via orchestrator', {
        serverScanId,
        philosophy: 'orchestrator_force_morph_update'
      });
    }
  }, [modelLifecycle.modelRef, morphLifecycle.forceMorphsUpdate, serverScanId, faceMorphData, morphologyMapping]);

  return {
    viewerState,
    scene: sceneLifecycle.scene,
    renderer: sceneLifecycle.renderer,
    camera: sceneLifecycle.camera,
    controls: sceneLifecycle.controls,
    model: modelLifecycle.model,
    mainMesh: modelLifecycle.modelRef.current,
    setCameraView: cameraControls.setCameraView,
    toggleAutoRotate: cameraControls.toggleAutoRotate,
    resetCamera: cameraControls.resetCamera,
    updateMorphData: morphUpdates.updateMorphData,
    retryInitialization,
    forceMorphsUpdate,
    isReady,
    hasError,
    errorMessage: viewerState.error,
  };
}
