# Avatar 3D Viewer - Refactoring Documentation

## Overview

Le fichier `useAvatarViewerOrchestrator.ts` (1231 lignes) a été modularisé en plusieurs fichiers spécialisés pour améliorer la maintenabilité, la testabilité et la lisibilité du code.

## Structure Avant Refactorisation

```
hooks/
  └── useAvatarViewerOrchestrator.ts (1231 lignes)
      ├── Face clipping logic
      ├── State management
      ├── Refs management
      ├── Gender/skin tone processing
      ├── Scene initialization
      ├── Model loading
      ├── Morph updates with throttling
      ├── Camera controls
      └── Memory management
```

## Structure Après Refactorisation

```
hooks/
  ├── useAvatarViewerOrchestrator.refactored.ts (220 lignes) - Orchestrateur principal
  ├── useViewerState.ts (150 lignes) - Gestion d'état centralisée
  ├── useCameraControls.ts (60 lignes) - Contrôles caméra
  ├── useMorphUpdates.ts (280 lignes) - Mises à jour morphs temps réel
  ├── useViewerInitialization.ts (350 lignes) - Initialisation scène/modèle
  └── index.ts - Exports centralisés

utils/
  └── faceClipping.ts (230 lignes) - Logique de clipping facial
```

## Modules Créés

### 1. `utils/faceClipping.ts`
**Responsabilité:** Gestion du clipping facial pour mode face-only

**Fonctions exportées:**
- `applyFaceOnlyClipping(model)` - Applique le clipping au modèle
- `forceMainMeshVisible(model)` - Force la visibilité du mesh principal (debug)

**Fonctions internes:**
- `findNeckBone()` - Trouve l'os du cou pour positionnement précis
- `findMainSkinnedMesh()` - Identifie le mesh principal avec morph targets
- `applyClippingPlaneToMesh()` - Applique le plan de clipping
- `processMeshClipping()` - Traite la visibilité et le clipping d'un mesh

**Avantages:**
- Logique de clipping isolée et testable
- Réutilisable dans d'autres contextes
- Plus facile à débugger
- Pas de dépendances React

### 2. `hooks/useViewerState.ts`
**Responsabilité:** Gestion centralisée de l'état et des refs du viewer

**Exports:**
- `useViewerState()` - Hook principal
- Type `ViewerStateRefs` - Tous les refs nécessaires

**Gère:**
- État du viewer (loading, error, initialized, etc.)
- Tous les refs de contrôle (initialization, projection session, etc.)
- Calcul mémoïsé du gender final
- Calcul mémoïsé du skin tone
- Verrouillage gender/skin tone en mode projection

**Avantages:**
- Centralisation de la logique d'état
- Refs organisés dans une structure typée
- Mémoïsation optimale avec useMemo
- Séparation claire entre état et logique métier

### 3. `hooks/useCameraControls.ts`
**Responsabilité:** Contrôles de la caméra 3D

**Exports:**
- `useCameraControls()` - Hook de contrôle caméra

**Fonctions:**
- `setCameraView()` - Change la vue (front/profile/threequarter)
- `toggleAutoRotate()` - Active/désactive la rotation auto
- `resetCamera()` - Réinitialise la position caméra

**Avantages:**
- API simple et claire
- Logique de caméra isolée
- Facilite les tests unitaires
- Pas de couplage avec le reste du viewer

### 4. `hooks/useMorphUpdates.ts`
**Responsabilité:** Gestion des mises à jour morphs en temps réel avec throttling

**Exports:**
- `useMorphUpdates()` - Hook de mise à jour morphs
- `updateStats` - Statistiques de performance

**Fonctionnalités:**
- Détection de changements (morphs, limb masses, skin tone)
- Throttling adaptatif (400ms mobile, 150ms desktop)
- Batching des mises à jour
- Gestion des mises à jour concurrentes
- Statistiques de performance

**Optimisations:**
- Utilise des hashes JSON pour détecter changements
- Throttling pour éviter surcharge
- Batching des opérations
- Logging conditionnel (sample rate)
- Détection mobile pour adaptation performance

**Avantages:**
- Performance optimisée
- Code de throttling réutilisable
- Métriques de performance intégrées
- Gestion robuste des cas limites

### 5. `hooks/useViewerInitialization.ts`
**Responsabilité:** Initialisation complète du viewer (scène + modèle)

**Exports:**
- `useViewerInitialization()` - Hook d'initialisation
- `handleModelLoaded` - Callback de chargement modèle
- `retryInitialization` - Fonction de retry

**Gère:**
- Initialisation scène
- Chargement modèle
- Application morphs initiaux
- Configuration matériaux
- Positionnement caméra
- Clipping facial
- Monitoring mémoire
- Gestion erreurs

**Avantages:**
- Flux d'initialisation centralisé
- Gestion d'erreurs robuste
- Intégration monitoring performance
- Support retry avec cleanup complet

### 6. `hooks/useAvatarViewerOrchestrator.refactored.ts`
**Responsabilité:** Orchestration de tous les hooks spécialisés

**Taille:** 220 lignes (vs 1231 avant)

**Structure:**
```typescript
useAvatarViewerOrchestrator()
  ├── useViewerState() - État centralisé
  ├── useSceneLifecycle() - Gestion scène
  ├── useModelLifecycle() - Gestion modèle
  ├── useMorphLifecycle() - Application morphs
  ├── useMaterialLifecycle() - Configuration matériaux
  ├── useCameraControls() - Contrôles caméra
  ├── useMorphUpdates() - Mises à jour temps réel
  └── useViewerInitialization() - Initialisation
```

**Avantages:**
- Code lisible et maintenable
- Responsabilités clairement séparées
- Facilite le debugging
- Permet tests unitaires par module
- Réutilisation possible des hooks

## Migration Guide

### Pour utiliser la version refactorisée:

```typescript
// Avant
import { useAvatarViewerOrchestrator } from './hooks/useAvatarViewerOrchestrator';

// Après
import { useAvatarViewerOrchestrator } from './hooks/useAvatarViewerOrchestrator.refactored';
// OU
import { useAvatarViewerOrchestrator } from './hooks';
```

**L'API reste identique** - aucun changement nécessaire dans le code appelant!

### Pour importer des modules spécifiques:

```typescript
// Importer un hook spécifique
import { useCameraControls } from './hooks/useCameraControls';

// Importer une utilité
import { applyFaceOnlyClipping } from './utils/faceClipping';

// Importer via l'index
import { useMorphUpdates, useViewerState } from './hooks';
```

## Métriques de Refactorisation

### Réduction de Complexité
- **Fichier original:** 1231 lignes, complexité cyclomatique élevée
- **Fichiers refactorisés:**
  - Orchestrateur: 220 lignes
  - Face clipping: 230 lignes
  - Viewer state: 150 lignes
  - Camera controls: 60 lignes
  - Morph updates: 280 lignes
  - Initialization: 350 lignes

### Séparation des Responsabilités
- ✅ Logique de clipping isolée
- ✅ État et refs centralisés
- ✅ Contrôles caméra modulaires
- ✅ Mises à jour morphs optimisées
- ✅ Initialisation découplée
- ✅ Orchestration simplifiée

### Testabilité
- ✅ Chaque hook testable indépendamment
- ✅ Utilitaires sans dépendances React
- ✅ Mocks facilités par séparation
- ✅ Assertions claires par module

### Performance
- ✅ Mémoïsation optimale (useMemo, useCallback)
- ✅ Throttling adaptatif mobile/desktop
- ✅ Batching des mises à jour
- ✅ Logging conditionnel (sample rate)
- ✅ Détection changements efficace (hashes)

## Prochaines Étapes

### Phase 2 - Tests
- [ ] Tests unitaires pour chaque hook
- [ ] Tests d'intégration orchestrateur
- [ ] Tests performance throttling
- [ ] Tests edge cases clipping

### Phase 3 - Documentation
- [ ] JSDoc pour toutes les fonctions
- [ ] Exemples d'usage
- [ ] Diagrammes de flux
- [ ] Guide de debugging

### Phase 4 - Optimisations
- [ ] Web Workers pour calculs lourds
- [ ] Streaming morphs si données volumineuses
- [ ] Cache stratégies avancées
- [ ] Profiling et benchmarks

## Notes Importantes

### Compatibilité
- ✅ **Pas de breaking changes** - L'API reste identique
- ✅ Support complet des features existantes
- ✅ Tous les debug flags préservés
- ✅ Logging conservé et amélioré

### Points d'Attention
- Les refs sont maintenant groupés dans `ViewerStateRefs`
- Le throttling est désormais dans un hook dédié
- L'initialisation est séparée de l'orchestration
- Le clipping facial est maintenant une utility pure

### Fichier Original
Le fichier original `useAvatarViewerOrchestrator.ts` est conservé pour référence.
Il peut être supprimé une fois la migration validée en production.

## Contact & Support

Pour questions ou problèmes liés à cette refactorisation:
- Consulter ce document
- Vérifier les types TypeScript
- Examiner les logs de debug
- Tester avec DEBUG_FLAGS si nécessaire
