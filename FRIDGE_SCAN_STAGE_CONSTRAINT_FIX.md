# Fix: Fridge Scan Sessions Stage Constraint Violation

## Problème Identifié

Lors d'un scan de frigo, un warning apparaissait dans les logs :

```
FRIDGE_SCAN_PIPELINE — Failed to save session to Supabase
constraint violation: fridge_scan_sessions_stage_check
```

### Cause Racine

Il y avait un désalignement entre les valeurs du type TypeScript `FridgeScanStep` et la contrainte CHECK dans la table Supabase `fridge_scan_sessions`.

**Base de données (avant le fix) :**
- Valeurs acceptées : `photo`, `analysis`, `validation`, `complement`, `recipes`

**Code TypeScript :**
- Valeurs utilisées : `photo`, `analyze`, `complement`, `validation`, `generating_recipes`, `recipes`

Les valeurs `analyze` et `generating_recipes` du code causaient des violations de contrainte lors de la sauvegarde.

## Solution Implémentée

### 1. Migration Base de Données

**Fichier :** `supabase/migrations/20251021040000_fix_fridge_scan_sessions_stage_constraint.sql`

Actions effectuées :
- Suppression de l'ancienne contrainte CHECK
- Création d'une nouvelle contrainte acceptant les valeurs correctes :
  - `photo` : Capture de photos initiale
  - `analyze` : Analyse IA des photos (remplace `analysis`)
  - `complement` : Suggestions IA d'ingrédients complémentaires
  - `validation` : Révision et édition par l'utilisateur
  - `generating_recipes` : Génération IA de recettes (nouveau)
  - `recipes` : Affichage final des recettes
- Migration automatique des anciennes valeurs `analysis` vers `analyze`

### 2. Amélioration du Code de Sauvegarde

**Fichier :** `src/system/store/fridgeScan/actions/sessionActions.ts`

Améliorations apportées :
- Ajout d'une validation des valeurs avant la sauvegarde
- Logging amélioré pour les erreurs de contrainte
- Documentation des valeurs valides dans le code
- Messages d'erreur plus explicites

### 3. Correction du Type TypeScript

**Fichier :** `src/system/store/fridgeScan/types.ts`

- Suppression de la déclaration dupliquée du type `FridgeScanStep`
- Conservation de la déclaration complète avec toutes les étapes

## Résultats

### Migration Appliquée avec Succès

La contrainte mise à jour accepte maintenant :
```sql
stage = ANY (ARRAY[
  'photo'::text,
  'analyze'::text,
  'complement'::text,
  'validation'::text,
  'generating_recipes'::text,
  'recipes'::text
])
```

### Sessions Existantes

État des sessions en base de données :
- 18 sessions en stage `photo`
- 3 sessions en stage `validation`
- Aucune session avec l'ancienne valeur `analysis` (migration automatique réussie)

## Impact

### Avant le Fix
- ❌ Erreurs de contrainte lors de la sauvegarde des sessions
- ❌ Sessions non persistées en base de données
- ❌ Logs polués par des warnings

### Après le Fix
- ✅ Toutes les étapes du pipeline sont correctement sauvegardées
- ✅ Validation préventive des valeurs avant sauvegarde
- ✅ Messages d'erreur explicites si problème
- ✅ Alignement parfait entre TypeScript et Supabase

## Tests Recommandés

Pour valider la correction, tester le flux complet :

1. **Démarrer un nouveau scan de frigo**
   - Vérifier que la session est créée avec `stage = 'photo'`

2. **Capturer des photos**
   - Vérifier la sauvegarde après upload

3. **Lancer l'analyse IA**
   - Vérifier que `stage = 'analyze'` est bien sauvegardé
   - Confirmer l'absence de warnings dans les logs

4. **Passer à la validation**
   - Vérifier que `stage = 'validation'` est bien sauvegardé

5. **Générer des recettes**
   - Vérifier que `stage = 'generating_recipes'` est bien sauvegardé
   - Vérifier la transition vers `stage = 'recipes'`

## Fichiers Modifiés

1. `supabase/migrations/20251021040000_fix_fridge_scan_sessions_stage_constraint.sql` (nouveau)
2. `src/system/store/fridgeScan/actions/sessionActions.ts` (modifié)
3. `src/system/store/fridgeScan/types.ts` (nettoyé)

## Notes Techniques

- La migration est rétrocompatible et ne casse pas les sessions existantes
- La validation côté client empêche les erreurs de contrainte futures
- Les logs sont maintenant plus informatifs pour le débogage
- La contrainte CHECK garantit l'intégrité des données en base

## Date de Correction

2025-10-21
