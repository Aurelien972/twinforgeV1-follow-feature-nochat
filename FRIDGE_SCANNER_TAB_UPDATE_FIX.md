# Fix: Fridge Scanner Tab Not Updating After Scan

## Problème Identifié

Après avoir scanné un frigo et validé l'inventaire, l'onglet Scanner continuait d'afficher l'état vide (`EmptyFridgeScannerState`) au lieu de montrer l'interface complète avec l'historique des scans et les statistiques.

### Logs Observés

Les logs montraient que :
- ✅ 33 items détectés et traités correctement
- ✅ Session sauvegardée avec succès dans `recipe_sessions`
- ✅ Meal plan store mis à jour avec le nouvel inventaire
- ❌ L'onglet Scanner ne se mettait pas à jour

```
FRIDGE_SCAN_PIPELINE — Recipe session saved successfully
sessionId: fcda2096-07bd-4ef4-ad3f-9fb99a87f06a
savedRecipesCount: 0
```

## Cause Racine

Le composant `ScannerTab` utilise une React Query pour déterminer s'il doit afficher l'état vide ou l'interface complète :

```typescript
const { data: hasAnyFridgeScanHistory = false } = useQuery({
  queryKey: ['fridge-scan-sessions', 'has-history', session?.user?.id],
  queryFn: async () => {
    // Vérifie si l'utilisateur a des sessions
  },
  staleTime: 5 * 60 * 1000, // 5 minutes de cache
});

if (!hasAnyFridgeScanHistory) {
  return <EmptyFridgeScannerState />;
}
```

**Le problème :** Après avoir sauvegardé une session, le cache React Query n'était pas invalidé, donc la query continuait de retourner `false` pendant 5 minutes (durée du `staleTime`).

## Solution Implémentée

### 1. Export du QueryClient

**Fichier :** `src/app/providers/AppProviders.tsx`

Exportation du `queryClient` pour permettre son utilisation dans les stores et services :

```typescript
// Create QueryClient with enhanced cache configuration for persistence
// Export for use in stores and services
export const queryClient = new QueryClient({
  // ... configuration
});
```

### 2. Invalidation du Cache Après Sauvegarde

**Fichier :** `src/system/store/fridgeScan/actions/sessionActions.ts`

Ajout de l'invalidation du cache React Query après la sauvegarde réussie d'une session :

```typescript
// Invalidate React Query cache to update Scanner tab
try {
  const { queryClient } = await import('../../../../app/providers/AppProviders');
  if (queryClient) {
    await queryClient.invalidateQueries({
      queryKey: ['fridge-scan-sessions', 'has-history']
    });

    logger.info('FRIDGE_SCAN_PIPELINE', 'React Query cache invalidated for Scanner tab', {
      sessionId: state.currentSessionId,
      timestamp: new Date().toISOString()
    });
  }
} catch (error) {
  logger.warn('FRIDGE_SCAN_PIPELINE', 'Failed to invalidate React Query cache', {
    error: error instanceof Error ? error.message : 'Unknown error',
    sessionId: state.currentSessionId,
    timestamp: new Date().toISOString()
  });
}
```

## Flux de Correction

1. **Utilisateur scanne son frigo** → Photos capturées et analysées
2. **Inventaire validé** → 33 items détectés
3. **Session sauvegardée** → `recipe_sessions` créée en base
4. **Meal plan store mis à jour** → Inventaire disponible
5. **🆕 Cache React Query invalidé** → Query `has-history` refetch automatiquement
6. **Onglet Scanner mis à jour** → Affiche l'interface complète au lieu de l'état vide

## Comportement Après Fix

### Avant
- ❌ Onglet Scanner reste en état vide après scan
- ❌ Nécessite un refresh manuel de la page
- ❌ Mauvaise expérience utilisateur

### Après
- ✅ Onglet Scanner se met à jour automatiquement
- ✅ Interface complète affichée immédiatement
- ✅ Historique des scans visible
- ✅ Statistiques disponibles
- ✅ Expérience utilisateur fluide

## Tests Recommandés

Pour valider la correction :

1. **Premier scan utilisateur**
   - Scanner un frigo pour la première fois
   - Valider l'inventaire
   - Revenir à l'onglet Scanner
   - ✅ Vérifier que l'interface complète s'affiche (pas l'état vide)

2. **Scans suivants**
   - Scanner un nouveau frigo
   - Valider l'inventaire
   - Revenir à l'onglet Scanner
   - ✅ Vérifier que les statistiques sont mises à jour
   - ✅ Vérifier que l'historique inclut le nouveau scan

3. **Vérifier les logs**
   - ✅ Confirmer la présence du log : `React Query cache invalidated for Scanner tab`
   - ✅ Aucun warning d'erreur d'invalidation

## Fichiers Modifiés

1. `src/app/providers/AppProviders.tsx`
   - Export du `queryClient` pour utilisation externe

2. `src/system/store/fridgeScan/actions/sessionActions.ts`
   - Ajout de l'invalidation du cache après `saveRecipeSession()`
   - Logging amélioré

## Impact Technique

### Avantages
- ✅ Mise à jour automatique de l'UI sans refresh
- ✅ Synchronisation parfaite entre l'état de la base et l'UI
- ✅ Pas d'impact sur les performances (invalidation async)
- ✅ Gestion d'erreur robuste (try/catch)

### Considérations
- L'invalidation est asynchrone et ne bloque pas la sauvegarde
- En cas d'échec de l'invalidation, le composant se mettra à jour après le `staleTime` (5 minutes)
- Le logging permet de diagnostiquer d'éventuels problèmes

## Patterns Réutilisables

Ce pattern d'invalidation de cache peut être réutilisé pour d'autres fonctionnalités :

```typescript
// Import queryClient
const { queryClient } = await import('path/to/AppProviders');

// Invalider une query spécifique
await queryClient.invalidateQueries({
  queryKey: ['your-query-key']
});

// Invalider toutes les queries d'un préfixe
await queryClient.invalidateQueries({
  queryKey: ['prefix'],
  refetchType: 'active'
});
```

## Date de Correction

2025-10-21
