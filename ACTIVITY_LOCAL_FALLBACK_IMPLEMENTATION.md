# Activity Insights Local Fallback Implementation

## Résumé des changements

Cette mise à jour implémente un système de fallback local pour les onglets Insights et Progression de la Forge Énergétique (Activity), permettant de générer des insights basiques même lorsque l'edge function `activity-progress-generator` est inaccessible (ex: environnement StackBlitz avec CORS errors).

## Problème résolu

### Avant
- Les onglets Insights et Progression échouaient complètement avec des erreurs CORS
- L'edge function `activity-progress-generator` n'était pas accessible dans l'environnement StackBlitz
- Les utilisateurs voyaient des erreurs "Failed to fetch" répétitives
- Le compteur `currentActivities` restait à 0 malgré les activités enregistrées

### Après
- Les onglets Insights et Progression fonctionnent avec un processeur local en fallback
- Les insights sont générés localement à partir des données d'activité stockées dans Supabase
- Une bannière informe l'utilisateur du mode de fonctionnement (local vs serveur)
- Le système reste 100% fonctionnel même sans accès à l'edge function

## Architecture de la solution

### 1. Processeur d'insights local

**Fichier créé:** `src/app/pages/Activity/utils/localActivityInsightsProcessor.ts`

Ce module contient toute la logique pour générer des insights localement :

- **`getMinimumActivitiesForPeriod()`** - Détermine le nombre minimum d'activités requises par période
- **`getDateRangeForPeriod()`** - Calcule les plages de dates pour chaque période
- **`generateActivitySummary()`** - Génère les statistiques globales (durée, calories, régularité, etc.)
- **`generateInsights()`** - Génère les insights personnalisés basés sur les patterns d'activité
- **`generateLocalActivityInsights()`** - Fonction principale orchestrant tout le processus

### 2. Stratégie de fallback

**Fichier modifié:** `src/app/pages/Activity/hooks/useActivitiesData.ts`

La fonction `useActivityInsightsGenerator()` a été mise à jour pour :

1. **Tenter d'abord l'edge function** (priorité au serveur pour insights IA avancés)
2. **En cas d'échec** (CORS, timeout, erreur réseau):
   - Log l'erreur sans bloquer l'utilisateur
   - Import dynamique du processeur local
   - Génération locale des insights
   - Retour d'un objet compatible avec le format attendu

```typescript
try {
  // Essayer l'edge function
  const response = await fetch(`${supabaseUrl}/functions/v1/activity-progress-generator`, ...);
  // ...
} catch (edgeFunctionError) {
  // Fallback local
  const { generateLocalActivityInsights } = await import('../utils/localActivityInsightsProcessor');
  return await generateLocalActivityInsights(userId, period, supabase);
}
```

### 3. Interface utilisateur améliorée

**Fichier modifié:** `src/app/pages/Activity/ActivityInsightsTab.tsx`

Ajout de bannières informatives pour indiquer le mode de fonctionnement :

- **Mode local (fallback)** - Bannière orange indiquant "Mode Analyse Locale"
- **Mode cache (serveur)** - Bannière verte indiquant "Données mises en cache"
- Les deux modes affichent les mêmes composants (GlobalStatsCard, ActivityInsightCards)

## Types d'insights générés localement

### 1. Régularité (Consistency)
- **Excellente** (≥70%) : Félicite l'utilisateur pour sa constance
- **Modérée** (40-69%) : Encourage à augmenter la fréquence
- **Irrégulière** (<40%) : Recommande une pratique plus régulière

### 2. Volume d'entraînement
- Compare la durée hebdomadaire moyenne à l'objectif OMS (150 min/semaine)
- Félicite si objectif atteint
- Calcule le déficit et suggère les minutes à ajouter

### 3. Variété d'activités
- **Excellente** (≥4 types) : Valorise la diversité
- **Limitée** (≤2 types) : Recommande de diversifier

### 4. Intensité
- Analyse le pourcentage d'entraînements à haute intensité
- **Bon équilibre** (≥30%) : Favorable aux progrès cardiovasculaires
- **Insuffisant** (<15%) : Recommande d'augmenter l'intensité

### 5. Données biométriques
- Informe du pourcentage d'activités enrichies avec données de montre
- Met en avant la valeur des données cardiaques

## Statistiques calculées

Le résumé local inclut :
- **Nombre total d'activités**
- **Durée totale** (minutes)
- **Calories totales** brûlées
- **Moyennes** (durée et calories par activité)
- **Activité la plus pratiquée**
- **Entraînement le plus intense** (type, calories, date)
- **Score de régularité** (% de jours avec activité)
- **Jours actifs** vs jours totaux dans la période

## Seuils par période

| Période | Jours | Activités min | Description |
|---------|-------|---------------|-------------|
| last7Days | 7 | 3 | Minimum pour analyse hebdomadaire |
| last30Days | 30 | 8 | Minimum pour analyse mensuelle |
| last3Months | 90 | 20 | Minimum pour analyse trimestrielle |
| last6Months | 180 | 35 | Minimum pour analyse semestrielle |
| last1Year | 365 | 60 | Minimum pour analyse annuelle |

## Avantages du système de fallback

1. **Résilience** - L'application reste fonctionnelle même sans accès aux edge functions
2. **Expérience utilisateur** - Pas de blocage, insights toujours disponibles
3. **Transparence** - L'utilisateur est informé du mode de fonctionnement via les bannières
4. **Performance** - Pas de timeout sur les edge functions en environnement restreint
5. **Développement** - Facilite les tests en environnement local/StackBlitz

## Compatibilité

- ✅ Fonctionne dans StackBlitz avec restrictions CORS
- ✅ Compatible avec le format de données existant
- ✅ Les onglets Progression et Insights utilisent le même hook
- ✅ Pas de changement breaking dans l'API
- ✅ Build réussi sans erreurs

## Logs et monitoring

Le système génère des logs détaillés pour diagnostic :

- `ACTIVITY_INSIGHTS_DIAGNOSTIC` - Tentative d'appel edge function
- `LOCAL_INSIGHTS_PROCESSOR` - Début/succès génération locale
- Distinction claire entre succès serveur et fallback local
- Tracking du nombre d'activités et insights générés

## Tests recommandés

1. **Test du fallback** - Bloquer l'accès à l'edge function et vérifier génération locale
2. **Test des seuils** - Vérifier le message "données insuffisantes" avec <3 activités
3. **Test des insights** - Créer différents patterns d'activité et vérifier la pertinence
4. **Test des périodes** - Valider le calcul sur week/month/quarter
5. **Test de l'UI** - Vérifier l'affichage des bannières fallback/cache

## Fichiers modifiés

1. ✅ `src/app/pages/Activity/hooks/useActivitiesData.ts` - Ajout stratégie fallback
2. ✅ `src/app/pages/Activity/ActivityInsightsTab.tsx` - Bannières mode fallback
3. ✅ `src/app/pages/Activity/utils/localActivityInsightsProcessor.ts` - Nouveau processeur local

## Prochaines étapes possibles

- Ajouter des insights plus avancés (tendances, prédictions)
- Implémenter un cache client pour les insights locaux
- Ajouter des graphiques de progression dans le mode local
- Enrichir avec des recommandations personnalisées basées sur le profil
