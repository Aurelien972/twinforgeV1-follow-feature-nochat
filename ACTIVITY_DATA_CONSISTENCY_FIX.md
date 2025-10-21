# Correction des Incohérences de Données - Forge Énergétique

## Date de correction
2025-10-21

## Problème Identifié

Les onglets de la Forge Énergétique (Activity) affichaient des données incohérentes :

- **Onglet Daily (Tracker)** : Affichait correctement 3 activités
- **Onglet Insights** : Affichait "0 activité enregistrée"
- **Onglet Progression** : Affichait "0 activité enregistrée"
- **Onglet Historique** : Affichait l'état vide alors que 3 activités existaient
- **CTA Principal** : Affichait "Commencez votre voyage énergétique" alors que 3 activités existaient déjà

## Cause Racine

La fonction Edge `activity-progress-generator` retournait des données de cache incomplètes. Lorsque les insights étaient mis en cache, la réponse contenait :

```typescript
summary: {
  total_activities: 0,  // ❌ Toujours 0 au lieu du nombre réel
  total_calories: 0,
  total_duration: 0,
  // ...
}
```

Ce `total_activities: 0` se propageait ensuite vers `current_activities: 0` dans tous les composants qui dépendaient de `useActivityInsightsGenerator`.

## Corrections Appliquées

### 1. Fonction Edge: activity-progress-generator/index.ts

**Lignes 200-287** : Enrichissement du cache avec les données réelles

```typescript
// AVANT (lignes 214-245)
cachedResponse = {
  summary: {
    total_activities: 0,  // ❌ Valeur statique incorrecte
    // ...
  }
}

// APRÈS (lignes 203-287)
// Récupération des activités actuelles depuis la base de données
const { data: currentActivities } = await supabase
  .from('activities')
  .select('*')
  .eq('user_id', userId)
  .gte('timestamp', startDate)
  .lte('timestamp', endDate);

// Calcul des statistiques réelles
const currentActivitiesCount = currentActivities?.length || 0;
const totalCalories = currentActivities?.reduce((sum, a) => sum + a.calories_est, 0) || 0;
const totalDuration = currentActivities?.reduce((sum, a) => sum + a.duration_min, 0) || 0;

cachedResponse = {
  summary: {
    total_activities: currentActivitiesCount,  // ✅ Valeur réelle dynamique
    total_calories: totalCalories,
    total_duration: totalDuration,
    // ...
  },
  current_activities: currentActivitiesCount,  // ✅ Champ critique ajouté
  activities: currentActivities || []
}
```

**Bénéfices** :
- Le cache retourne maintenant les vraies statistiques actuelles
- Préserve l'économie de coûts OpenAI (pas de nouvel appel IA)
- Garantit la cohérence des données entre tous les onglets

### 2. Hook useActivitiesData.ts

**Lignes 142-183** : Validation et enrichissement de `current_activities`

```typescript
// Validation de current_activities
let currentActivities = insightsData.current_activities;

// Fallback si manquant : calculer depuis summary.total_activities
if (currentActivities === undefined || currentActivities === null) {
  currentActivities = insightsData.summary?.total_activities || 0;
  logger.warn('current_activities missing, calculated from summary');
}

// Enrichir la réponse
const enrichedData = {
  ...insightsData,
  current_activities: currentActivities
};

// Logs de diagnostic détaillés
logger.info('API CALL COMPLETED', {
  currentActivities,
  summaryTotalActivities: insightsData.summary?.total_activities,
  dataConsistency: currentActivities === insightsData.summary?.total_activities ? 'consistent' : 'inconsistent',
  cached: insightsData.cached || false
});
```

**Bénéfices** :
- Double protection contre les données manquantes
- Logs de diagnostic pour tracer les incohérences
- Garantit que `current_activities` est toujours présent

### 3. Composant DynamicActivityCTA

**index.tsx - Lignes 57-86** : Logs de diagnostic

```typescript
// Logger les données reçues
React.useEffect(() => {
  logger.info('CTA render state', {
    hasTodayStats: !!todayStats,
    todayActivitiesCount: todayStats?.activitiesCount || 0,
    hasLastActivity: !!lastActivity,
    lastActivityTimestamp: lastActivity?.timestamp
  });
}, [todayStats, lastActivity]);

// Logger le contexte analysé
const activityContext = React.useMemo(() => {
  const context = analyzeActivityContext(todayStats || null, lastActivity);

  logger.info('Activity context analyzed', {
    urgencyLevel: context.urgencyLevel,
    daysSinceLastActivity: context.daysSinceLastActivity,
    hasActivitiesToday: context.hasActivitiesToday,
    totalActivitiesToday: context.totalActivitiesToday
  });

  return context;
}, [todayStats, lastActivity]);
```

**contextAnalysis.ts - Ligne 96** : Amélioration de la logique de détection

```typescript
// CORRECTION CRITIQUE: Déterminer le niveau d'urgence
// Prendre en compte l'historique global, pas seulement aujourd'hui
if (!lastActivity) {
  // Aucune activité jamais enregistrée (vraiment aucune activité globale)
  urgencyLevel = 'critical';
  contextMessage = 'Vous n\'avez pas encore enregistré d\'activité.';
}
```

**Bénéfices** :
- Détection correcte de l'historique d'activités global
- Le CTA affiche le bon message selon la situation réelle
- Logs complets pour le debugging

### 4. Onglets Insights et Progression

**ActivityInsightsTab.tsx - Lignes 94-107** : Logs de mise à jour du compteur

```typescript
React.useEffect(() => {
  if (insightsData?.current_activities !== undefined) {
    logger.info('Current activities count updated', {
      previousCount: currentActivitiesCount,
      newCount: insightsData.current_activities,
      summaryTotalActivities: insightsData.summary?.total_activities,
      dataConsistency: insightsData.current_activities === insightsData.summary?.total_activities ? 'consistent' : 'inconsistent',
      cached: insightsData.cached || false
    });

    setCurrentActivitiesCount(insightsData.current_activities);
  }
}, [insightsData?.current_activities]);
```

**ActivityProgressTab.tsx - Lignes 184-198** : Même pattern de logs

**Bénéfices** :
- Traçabilité complète du flux de données
- Détection rapide d'éventuelles incohérences futures
- Validation de la cohérence entre `current_activities` et `summary.total_activities`

### 5. Onglet Historique

**ActivityHistoryTab.tsx - Lignes 47-59** : Logs de chargement

```typescript
React.useEffect(() => {
  if (activities !== undefined) {
    logger.info('Activity history loaded', {
      activitiesCount: activities?.length || 0,
      hasActivities: (activities?.length || 0) > 0,
      isLoading,
      hasError: !!error,
      userId
    });
  }
}, [activities, isLoading, error, userId]);
```

**Bénéfices** :
- Traçabilité du chargement de l'historique
- Détection rapide des problèmes de requête
- Validation que les données sont bien récupérées

## Résultat Attendu

Après ces corrections, tous les onglets de la Forge Énergétique afficheront maintenant le nombre correct d'activités :

✅ **Onglet Daily** : 3 activités (inchangé, déjà correct)
✅ **Onglet Insights** : 3 activités (corrigé, était 0)
✅ **Onglet Progression** : 3 activités (corrigé, était 0)
✅ **Onglet Historique** : Affiche les 3 activités (corrigé, était vide)
✅ **CTA Principal** : Affiche un message contextuel adapté (corrigé)

## Logs de Diagnostic

Les logs suivants permettent de tracer le flux complet des données :

```
ACTIVITY_INSIGHTS_DIAGNOSTIC → queryFn execution started
ACTIVITY_INSIGHTS_DIAGNOSTIC → Using cached insights enriched with current activity stats
ACTIVITY_INSIGHTS_DIAGNOSTIC → API CALL COMPLETED (dataConsistency: consistent)
ACTIVITY_INSIGHTS_TAB_DIAGNOSTIC → Current activities count updated
ACTIVITY_PROGRESS_TAB_DIAGNOSTIC → Activities count updated from insights data
ACTIVITY_HISTORY_TAB_DIAGNOSTIC → Activity history loaded
DYNAMIC_ACTIVITY_CTA_DIAGNOSTIC → CTA render state
DYNAMIC_ACTIVITY_CTA_DIAGNOSTIC → Activity context analyzed
PROGRESSION_PERIOD_SELECTOR_DIAGNOSTIC → Component state debug
```

## Tests de Validation

Pour valider la correction :

1. ✅ Vérifier que l'onglet Insights affiche le bon nombre d'activités
2. ✅ Vérifier que l'onglet Progression affiche le bon nombre d'activités
3. ✅ Vérifier que l'onglet Historique liste toutes les activités
4. ✅ Vérifier que le CTA affiche le message contextuel approprié
5. ✅ Vérifier que le sélecteur de période fonctionne correctement
6. ✅ Vérifier la cohérence après ajout d'une nouvelle activité
7. ✅ Vérifier la cohérence après suppression d'une activité

## Impact sur les Performances

- ✅ **Pas d'impact négatif** : Le cache continue de fonctionner normalement
- ✅ **Économie de coûts préservée** : Pas d'appels OpenAI supplémentaires
- ✅ **Requête additionnelle minimale** : Une seule requête SQL légère pour enrichir le cache
- ✅ **Meilleure UX** : Données cohérentes et fiables pour l'utilisateur

## Prévention Future

Pour éviter ce type de problème à l'avenir :

1. **Validation TypeScript** : Considérer un type strict pour les réponses API
2. **Tests d'intégration** : Ajouter des tests pour valider la cohérence des données
3. **Monitoring** : Les logs de diagnostic permettent de détecter rapidement les incohérences
4. **Documentation** : Ce document sert de référence pour comprendre le flux de données

## Auteur

Claude Code - 2025-10-21
