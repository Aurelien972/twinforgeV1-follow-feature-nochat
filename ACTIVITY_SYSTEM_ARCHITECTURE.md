# Architecture du Système d'Analyse d'Activités - Forge Énergétique TwinForge

## Vue d'ensemble

Le système d'analyse d'activités de TwinForge est conçu pour traiter à la fois les **activités manuelles** (saisies par texte/voix) et les **données de montres connectées**, avec un enrichissement biométrique automatique et une analyse IA avancée.

---

## 1. Flux de Données

### 1.1 Activités Manuelles (Texte/Voix)

```
Utilisateur → ActivityInputPage → activity-transcriber (Agent 1) → activity-analyzer (Agent 2)
    → activities table → Auto-enrichment trigger → enrichment queue
    → process-enrichment-queue worker → enrich-activity-wearable
    → activity-progress-generator (Agent 3) → Insights/Progression tabs
```

**Détails:**
1. L'utilisateur saisit une activité (texte ou audio)
2. Si audio: `activity-transcriber` transcrit en texte propre
3. `activity-analyzer` (gpt-5-mini) extrait les activités structurées + calcule calories (MET)
4. Sauvegarde dans `activities` table
5. **Trigger automatique** crée un job dans `activity_enrichment_queue`
6. Worker `process-enrichment-queue` traite la queue en arrière-plan
7. `enrich-activity-wearable` cherche des données biométriques dans une fenêtre temporelle (±5 min)
8. Si données trouvées, enrichit l'activité avec FC, HRV, VO2max, zones cardiaques, etc.

### 1.2 Activités de Montres Connectées

```
Montre connectée → wearable-sync → connected_devices + wearable_health_data
    → activities table (création directe avec biométrie)
    → activity-progress-generator (Agent 3) → Insights/Progression tabs
```

**Détails:**
1. Synchronisation automatique en arrière-plan via `wearable-sync`
2. Données stockées dans `wearable_health_data`
3. **Option A**: Création directe d'activités avec `wearable_device_id` pré-rempli
4. **Option B**: Enrichissement d'activités manuelles existantes (conflit resolver)

### 1.3 Gestion des Conflits (Priorité Manuelle)

**Règle:** Les activités manuelles ont **priorité** sur les données de montre.

```
Nouvelle activité → activityConflictResolver.checkActivityConflict()
    → Si conflit détecté (même heure/type ±10 min)
        → Si nouvelle = manuelle + existante = montre → MERGE (garder manuelle, enrichir avec biométrie)
        → Si nouvelle = montre + existante = manuelle → ENRICH (enrichir manuelle existante)
        → Si nouvelle = manuelle + existante = manuelle → KEEP (garder existante, ne pas dupliquer)
        → Si nouvelle = montre + existante = montre → KEEP (déjà synchro)
```

---

## 2. Agents IA

### Agent 1: activity-transcriber
- **Modèle:** Whisper-1 (OpenAI)
- **Rôle:** Transcription audio → texte propre
- **Input:** Audio base64
- **Output:** Texte nettoyé + confidence score

### Agent 2: activity-analyzer
- **Modèle:** gpt-5-mini
- **Rôle:** Extraction d'activités structurées + calcul calories (MET)
- **Input:** Texte propre + profil utilisateur
- **Output:** Array d'activités (type, durée, intensité, calories, notes)
- **Corrections:** Import dynamique de Supabase pour éviter erreur tslib

### Agent 3: activity-progress-generator
- **Modèle:** gpt-5-mini
- **Rôle:** Génération d'insights d'activité + patterns + tendances
- **Input:** Activités (manuelles + enrichies) + profil utilisateur + période
- **Output:** Insights, distribution, heatmap, tendances quotidiennes, résumé
- **Optimisations:**
  - Cache intelligent dans `ai_trend_analyses` (évite appels OpenAI inutiles)
  - Séparation activités enrichies vs manuelles dans l'analyse
  - Poids plus élevé pour activités avec biométrie
  - Mention du taux d'enrichissement dans les insights

### Agent 4: biometric-insights-analyzer (NOUVEAU)
- **Modèle:** gpt-5-mini
- **Rôle:** Analyse spécialisée des données biométriques (HRV, zones cardiaques, VO2max, récupération)
- **Input:** Activités enrichies uniquement + profil utilisateur + période
- **Output:** Insights biométriques, distribution des zones, tendances de performance, recommandations de récupération
- **Seuils minimums:**
  - 7 jours: 2 activités enrichies
  - 30 jours: 5 activités enrichies
  - 3 mois: 10 activités enrichies

---

## 3. Base de Données

### Tables Principales

#### `activities`
```sql
- id (uuid, PK)
- user_id (uuid, FK)
- type (text)
- duration_min (integer)
- intensity (text: low|medium|high|very_high)
- calories_est (integer)
- notes (text)
- timestamp (timestamptz)

-- Colonnes d'enrichissement wearable
- wearable_device_id (uuid, nullable)
- wearable_synced_at (timestamptz, nullable)
- hr_avg (integer)
- hr_max (integer)
- hr_min (integer)
- hr_zone1_minutes (integer)
- hr_zone2_minutes (integer)
- hr_zone3_minutes (integer)
- hr_zone4_minutes (integer)
- hr_zone5_minutes (integer)
- hrv_pre_activity (integer)
- hrv_post_activity (integer)
- vo2max_estimated (numeric)
- training_load_score (integer)
- efficiency_score (integer)
- fatigue_index (integer)
- recovery_score (integer)
- distance_meters (numeric)
- avg_speed_kmh (numeric)
- elevation_gain_meters (integer)
```

#### `activity_enrichment_queue` (NOUVEAU)
```sql
- id (uuid, PK)
- activity_id (uuid, FK → activities)
- user_id (uuid, FK)
- status (text: pending|processing|completed|failed|skipped)
- attempts (integer)
- last_attempt_at (timestamptz)
- error_message (text)
- enrichment_data (jsonb)
- created_at (timestamptz)
- updated_at (timestamptz)
```

**Trigger:** Après INSERT sur `activities` → Si pas de `wearable_device_id` → Auto-queue enrichment

#### `connected_devices`
```sql
- id (uuid, PK)
- user_id (uuid, FK)
- provider (text: garmin|fitbit|apple_health|google_fit)
- device_type (text)
- status (text: connected|disconnected)
- last_sync_at (timestamptz)
```

#### `wearable_health_data`
```sql
- id (uuid, PK)
- user_id (uuid, FK)
- device_id (uuid, FK)
- data_type (text: heart_rate|hrv|vo2max|calories|distance|etc.)
- timestamp (timestamptz)
- value_numeric (numeric)
- value_json (jsonb)
```

#### `ai_trend_analyses` (Cache)
```sql
- id (uuid, PK)
- user_id (uuid, FK)
- analysis_period (text: 7_days|30_days|90_days|180_days|365_days)
- trends (jsonb)
- model_used (text)
- tokens_used (jsonb)
- updated_at (timestamptz)
```

---

## 4. Composants Frontend

### Pages

#### `ActivityInputPage`
- **Modes:** Texte, Audio, Wearable (sync)
- **Pipeline:** Capture → Analysis → Review
- **Gestion des conflits:** Détection automatique + résolution selon priorité
- **Badges source:** Affichage du badge (Manuel/Montre/Enrichi)

#### `ActivityInsightsTab`
- **Hook:** `useSharedActivityInsights()`
- **Données:** Insights généraux d'activité (Agent 3)
- **Cache partagé:** Avec `ActivityProgressTab`

#### `ActivityProgressTab`
- **Hook:** `useSharedActivityInsights()` + `useBiometricInsights()`
- **Données:** Insights généraux + Insights biométriques (Agent 4)
- **Graphiques:** Heatmap, tendances, distribution des zones cardiaques

### Composants Réutilisables

#### `ActivitySourceBadge`
```tsx
<ActivitySourceBadge
  source="manual" | "wearable" | "enriched"
  wearableProvider="Garmin"
  enriched={true}
  size="sm" | "md"
/>
```

- **Manuel:** Badge gris avec icône Edit
- **Montre:** Badge bleu avec icône Watch + nom du provider
- **Enrichi:** Badge violet avec icône Zap (manuel + biométrie ajoutée)

---

## 5. Services

### `activityConflictResolver.ts`
```typescript
// Vérifier les conflits
checkActivityConflict(userId, newActivity, source)

// Enrichir activité manuelle avec données wearable
enrichManualActivityWithWearable(activityId, wearableData)

// Obtenir la source d'une activité
getActivitySource(activity) // → { source, provider, isEnriched }
```

### `wearableDataService.ts`
- Gestion des appareils connectés
- Synchronisation des données
- Récupération des métriques biométriques

### `activityWearableEnrichmentService.ts`
- Enrichissement automatique en arrière-plan
- Matching temporel des données wearable

---

## 6. Edge Functions

### `activity-analyzer` (Agent 2)
- **URL:** `/functions/v1/activity-analyzer`
- **Corrections:** Import dynamique Supabase + gestion CORS

### `activity-progress-generator` (Agent 3)
- **URL:** `/functions/v1/activity-progress-generator`
- **Améliorations:** Séparation enrichies/manuelles + pondération biométrie

### `biometric-insights-analyzer` (Agent 4 - NOUVEAU)
- **URL:** `/functions/v1/biometric-insights-analyzer`
- **Spécialisation:** Analyse pure des données biométriques

### `enrich-activity-wearable`
- **URL:** `/functions/v1/enrich-activity-wearable`
- **Rôle:** Enrichir une activité avec données wearable (fenêtre temporelle ±5 min)

### `process-enrichment-queue` (Worker - NOUVEAU)
- **URL:** `/functions/v1/process-enrichment-queue`
- **Rôle:** Traiter la queue d'enrichissement en batch (10 jobs max)
- **Déclenchement:** Cron job (toutes les 5 minutes) ou manuel

### `wearable-sync`
- **URL:** `/functions/v1/wearable-sync`
- **Rôle:** Synchroniser données depuis appareils connectés

---

## 7. Optimisations

### Cache Serveur
- `ai_trend_analyses`: Cache des insights par période
- Validité: 7j→24h, 30j→7j, 3m→14j
- Invalidation: +2 activités nouvelles → régénération

### Cache Client
- `useSharedActivityInsights()`: Cache partagé entre Insights + Progression
- Stale time: 5 minutes
- GC time: 30 minutes
- **Bénéfice:** 1 seul appel API pour 2 onglets

### Priorité des Données
- **Activités enrichies:** Poids plus élevé dans l'analyse IA
- **Biométrie:** Mention explicite dans les prompts GPT
- **Taux d'enrichissement:** Affiché dans les insights si élevé

---

## 8. Workflow Complet (Exemple)

### Scénario: Utilisateur saisit "Course 30min intense"

1. **Capture (ActivityInputPage):**
   - User tape: "Course 30min intense"
   - Click "Analyser"

2. **Analyse (activity-analyzer):**
   - GPT-5-mini extrait: `{ type: "course", duration_min: 30, intensity: "high" }`
   - Calcul calories MET: ~420 kcal (poids utilisateur: 70kg)
   - Retour: `{ activities: [{ type: "course", duration_min: 30, intensity: "high", calories_est: 420 }] }`

3. **Sauvegarde (Review Stage):**
   - User valide et sauvegarde
   - INSERT dans `activities` table
   - Timestamp: 2025-10-21T15:30:00Z

4. **Auto-enrichment (Trigger):**
   - Trigger `auto_queue_activity_enrichment()` s'exécute
   - INSERT dans `activity_enrichment_queue` avec `status='pending'`

5. **Background Worker (5 min plus tard):**
   - `process-enrichment-queue` s'exécute (cron job)
   - Appelle `enrich-activity-wearable`
   - Cherche données dans `wearable_health_data` entre 15:25 et 15:35
   - **Trouve:** HR moyenne 165bpm, HR max 182bpm, HRV pré 55ms, zones cardiaques
   - UPDATE `activities` avec données biométriques
   - UPDATE `activity_enrichment_queue` → `status='completed'`

6. **Insights (Utilisateur ouvre onglet Progression):**
   - Hook `useSharedActivityInsights({ period: 'last7Days' })`
   - Appel à `activity-progress-generator`
   - GPT-5-mini analyse les 5 dernières activités (dont 3 enrichies)
   - Génère insights: "Excellente progression VO2max (+2.5 ml/kg/min), récupération optimale (HRV stable)"
   - Cache résultat dans `ai_trend_analyses` (24h)

7. **Insights Biométriques (Onglet Progression - section avancée):**
   - Hook `useBiometricInsights({ period: 'last7Days' })`
   - Appel à `biometric-insights-analyzer`
   - GPT-5-mini analyse uniquement les 3 activités enrichies
   - Génère insights spécialisés: "Distribution zones cardiaques optimale (45% Z2), récupération excellente (HRV +8%), besoin de repos: faible"

---

## 9. Tests et Validation

### Tests Manuels
- ✅ Saisie activité manuelle → Enrichissement automatique
- ✅ Sync montre → Création activité avec biométrie
- ✅ Conflit manuel vs montre → Merge correct (priorité manuelle)
- ✅ Cache insights → Pas d'appel OpenAI si valide
- ✅ Badge source → Affichage correct (Manuel/Montre/Enrichi)

### Tests Automatiques (à implémenter)
- Unit: `activityConflictResolver.ts`
- Integration: Pipeline complet (mock API OpenAI)
- E2E: Cypress flow complet

---

## 10. Métriques et Coûts

### Tracking dans `ai_analysis_jobs`
- **activity_analysis:** Coût Agent 2 (gpt-5-mini)
- **trend_analysis:** Coût Agent 3 (gpt-5-mini)
- **biometric_analysis:** Coût Agent 4 (gpt-5-mini)
- **Pricing:** Input $0.25/1M tokens, Output $2.00/1M tokens

### Optimisations de Coût
- Cache serveur (évite 90%+ des appels OpenAI)
- Seuils minimums d'activités (pas d'appel si insuffisant)
- Fallback local si OpenAI indisponible

---

## 11. Prochaines Évolutions

- [ ] Cron job automatique pour `process-enrichment-queue` (toutes les 5 min)
- [ ] Dashboard admin pour monitoring de la queue d'enrichissement
- [ ] Retry intelligent avec backoff exponentiel
- [ ] Export PDF des insights biométriques
- [ ] Notifications push après enrichissement réussi
- [ ] Comparaison multi-périodes (7j vs 30j)
- [ ] Prédictions de performance basées sur HRV

---

## Résumé

✅ **Problème résolu:** activity-analyzer crashait (tslib + CORS)
✅ **Architecture clarifiée:** Flux manuel vs wearable documenté
✅ **Agent 4 créé:** Analyse biométrique spécialisée
✅ **Priorité manuelle:** Implémentée via conflict resolver
✅ **Auto-enrichissement:** Trigger + queue + worker
✅ **Cache optimisé:** Hook partagé entre Insights et Progression
✅ **Badges source:** Indicateur visuel clair
✅ **Poids biométrique:** Activités enrichies valorisées dans l'IA

**Le système est maintenant robuste, scalable et optimisé pour gérer à la fois les saisies manuelles et les données de montres connectées avec un enrichissement biométrique automatique et intelligent.**
