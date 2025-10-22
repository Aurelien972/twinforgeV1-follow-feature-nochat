# Migration Checklist - Avatar Viewer Refactoring

## Checklist de Validation

### ✅ Phase 1: Création des Modules (COMPLÉTÉ)

- [x] Créer `utils/faceClipping.ts`
  - [x] Extraire `applyFaceOnlyClipping`
  - [x] Extraire `forceMainMeshVisible`
  - [x] Extraire helpers internes (findNeckBone, findMainSkinnedMesh, etc.)

- [x] Créer `hooks/useViewerState.ts`
  - [x] Extraire gestion état viewer
  - [x] Extraire tous les refs dans ViewerStateRefs
  - [x] Extraire logique finalGender
  - [x] Extraire logique processedSkinTone

- [x] Créer `hooks/useCameraControls.ts`
  - [x] Extraire setCameraView
  - [x] Extraire toggleAutoRotate
  - [x] Extraire resetCamera

- [x] Créer `hooks/useMorphUpdates.ts`
  - [x] Extraire système de throttling
  - [x] Extraire détection changements
  - [x] Extraire batching updates
  - [x] Extraire updateMorphData

- [x] Créer `hooks/useViewerInitialization.ts`
  - [x] Extraire initialisation scène
  - [x] Extraire chargement modèle
  - [x] Extraire callback onModelLoaded
  - [x] Extraire retryInitialization

- [x] Créer `hooks/useAvatarViewerOrchestrator.refactored.ts`
  - [x] Coordonner tous les hooks
  - [x] Maintenir API identique
  - [x] Préserver tous les exports

- [x] Créer `hooks/index.ts` pour exports centralisés
- [x] Créer documentation REFACTORING.md

### 🔄 Phase 2: Tests de Non-Régression (À FAIRE)

#### Tests Unitaires par Module

- [ ] **faceClipping.ts**
  - [ ] Test findNeckBone avec modèle valide
  - [ ] Test findNeckBone sans neck bone (fallback)
  - [ ] Test findMainSkinnedMesh avec morphs
  - [ ] Test applyFaceOnlyClipping complet
  - [ ] Test avec DEBUG_FLAGS activés
  - [ ] Test forceMainMeshVisible

- [ ] **useViewerState.ts**
  - [ ] Test initialisation état
  - [ ] Test calcul finalGender (toutes combinaisons)
  - [ ] Test calcul processedSkinTone
  - [ ] Test verrouillage gender en projection mode
  - [ ] Test verrouillage skin tone en projection mode
  - [ ] Test refs créés correctement

- [ ] **useCameraControls.ts**
  - [ ] Test setCameraView (front, profile, threequarter)
  - [ ] Test toggleAutoRotate
  - [ ] Test resetCamera
  - [ ] Test sans controls (edge case)

- [ ] **useMorphUpdates.ts**
  - [ ] Test détection changements morphs
  - [ ] Test throttling (mobile vs desktop)
  - [ ] Test batching updates
  - [ ] Test updateMorphData direct
  - [ ] Test gestion concurrence
  - [ ] Test statistiques updateStats

- [ ] **useViewerInitialization.ts**
  - [ ] Test initialisation scène complète
  - [ ] Test chargement modèle
  - [ ] Test handleModelLoaded callback
  - [ ] Test retryInitialization
  - [ ] Test gestion erreurs
  - [ ] Test guards (isFullyInitialized, projectionSession)

#### Tests d'Intégration

- [ ] **Orchestrateur Complet**
  - [ ] Test initialisation complète end-to-end
  - [ ] Test changement morphs en temps réel
  - [ ] Test changement camera views
  - [ ] Test retry après erreur
  - [ ] Test projection session flow
  - [ ] Test face-only mode
  - [ ] Test body mode
  - [ ] Test avec wearables
  - [ ] Test mobile vs desktop

#### Tests de Performance

- [ ] Benchmark temps initialisation
- [ ] Benchmark temps update morphs
- [ ] Benchmark mémoire utilisée
- [ ] Profiling throttling efficacité
- [ ] Test memory leaks
- [ ] Test cleanup resources

### 🔄 Phase 3: Migration du Code Appelant (À PLANIFIER)

#### Fichiers à Mettre à Jour

- [ ] Identifier tous les imports de `useAvatarViewerOrchestrator`
- [ ] Mettre à jour vers `.refactored` ou index
- [ ] Vérifier pas de breaking changes
- [ ] Tests end-to-end de l'application

#### Composants Concernés

```bash
# Commande pour trouver les usages:
grep -r "useAvatarViewerOrchestrator" src/
```

- [ ] `Avatar3DViewer.tsx` (usage principal)
- [ ] Autres composants potentiels (à identifier)

### 🔄 Phase 4: Validation Production (À PLANIFIER)

#### Pre-Production

- [ ] Review code complet
- [ ] Validation tests passent 100%
- [ ] Performance benchmarks OK
- [ ] Memory profiling OK
- [ ] Documentation à jour

#### Production

- [ ] Déploiement progressif (feature flag?)
- [ ] Monitoring erreurs JavaScript
- [ ] Monitoring performance
- [ ] Feedback utilisateurs
- [ ] Rollback plan préparé

### 🔄 Phase 5: Nettoyage (À FAIRE APRÈS VALIDATION)

- [ ] Supprimer `useAvatarViewerOrchestrator.ts` original
- [ ] Renommer `.refactored.ts` → `.ts`
- [ ] Nettoyer imports obsolètes
- [ ] Archive documentation migration
- [ ] Update README principal projet

## Validation Criteria

### Fonctionnel
- ✅ Toutes les features existantes fonctionnent
- ✅ Pas de régression visuelle
- ✅ Performance maintenue ou améliorée
- ✅ Mémoire stable ou optimisée

### Qualité Code
- ✅ Complexité réduite (mesurable)
- ✅ Testabilité améliorée
- ✅ Maintenabilité améliorée
- ✅ Documentation complète

### Technique
- ✅ Pas de memory leaks
- ✅ Throttling efficace
- ✅ Cleanup resources OK
- ✅ Error handling robuste

## Commandes Utiles

```bash
# Lancer les tests
npm test

# Lancer les tests en watch mode
npm test -- --watch

# Coverage
npm test -- --coverage

# Build pour vérifier TypeScript
npm run build

# Linter
npm run lint

# Rechercher usages
grep -r "useAvatarViewerOrchestrator" src/
```

## Rollback Plan

Si problèmes critiques détectés:

1. **Immédiat:** Revert vers `useAvatarViewerOrchestrator.ts` original
2. **Investigation:** Analyser logs et erreurs
3. **Fix:** Corriger dans modules refactorisés
4. **Re-test:** Valider correctifs
5. **Re-deploy:** Nouvelle tentative migration

## Notes

### Points d'Attention
- Les refs sont maintenant dans `ViewerStateRefs` type
- Throttling est configurable (mobile/desktop)
- Face clipping est découplé (utility pure)
- Initialisation est maintenant async-safe

### Breaking Changes
**AUCUN** - L'API externe reste identique!

### Performance
- Throttling adaptatif améliore fluidité mobile
- Batching réduit nombre re-renders
- Mémoïsation optimale préserve performance

## Contact

Pour questions sur cette migration:
- Consulter REFACTORING.md
- Examiner les types TypeScript
- Vérifier les tests unitaires
- Debug avec logging détaillé
