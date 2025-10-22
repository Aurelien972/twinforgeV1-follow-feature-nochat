# Guide de Test - Système de Tokens Atomique

## 🎯 Objectif
Valider que le système de tokens fonctionne correctement après la migration et que le bug initial (tokens non déduits) est résolu.

## ⚠️ Bug Initial à Valider
**Problème rapporté**: "je viens de scanner une activité, et le nombres de tokens ne c'est pas défalqué du total des tokens"

## 📋 Tests à Effectuer

### Test 1: Déduction de Tokens - Activity Analyzer
**Ce test valide le bug initial**

#### Étapes:
1. Note ton solde actuel de tokens dans la sidebar
2. Va sur la page Activity (Forge énergétique)
3. Lance un scan d'activité (capture audio ou texte)
4. Attends que l'analyse soit complète
5. Vérifie que ton solde de tokens a diminué

#### Requête SQL pour vérifier:
```sql
-- Voir l'historique de consommation
SELECT
  operation_type,
  amount,
  balance_after,
  created_at,
  metadata
FROM token_balance_history
WHERE user_id = auth.uid()
ORDER BY created_at DESC
LIMIT 10;

-- Voir les verrous actifs (devrait être vide)
SELECT * FROM token_consumption_locks
WHERE user_id = auth.uid();

-- Voir si des anomalies ont été détectées
SELECT * FROM token_anomalies
WHERE user_id = auth.uid()
ORDER BY detected_at DESC;
```

#### Résultat Attendu:
- ✅ Le solde diminue du nombre de tokens utilisés
- ✅ Une entrée apparaît dans `token_balance_history`
- ✅ L'opération est marquée comme `activity_analyzer`
- ✅ Le champ `balance_after` correspond au nouveau solde

### Test 2: Idempotence (Protection Double Consommation)

#### Étapes:
1. Ouvre les DevTools (F12)
2. Va dans l'onglet Network
3. Lance une analyse d'activité
4. Dans Network, clique droit sur la requête vers l'Edge Function
5. Sélectionne "Copy as cURL"
6. Exécute cette commande cURL 2 fois rapidement

#### Résultat Attendu:
- ✅ La première requête consomme les tokens
- ✅ La seconde requête retourne le même résultat SANS consommer de tokens
- ✅ Une seule entrée dans `token_balance_history`

### Test 3: Solde Insuffisant

#### Étapes:
1. Réduis manuellement ton solde à 0:
```sql
UPDATE token_balance
SET balance = 0
WHERE user_id = auth.uid();
```

2. Essaie de lancer une analyse d'activité

#### Résultat Attendu:
- ✅ Erreur HTTP 402 (Payment Required)
- ✅ Message: "Insufficient tokens"
- ✅ L'analyse ne démarre pas
- ✅ Une notification utilisateur apparaît

#### Restauration:
```sql
UPDATE token_balance
SET balance = 15000
WHERE user_id = auth.uid();
```

### Test 4: Vérification Logs Supabase

#### Étapes:
1. Va sur Supabase Dashboard
2. Logs > Edge Functions
3. Filtre par fonction: `activity-analyzer`
4. Cherche les logs de consommation de tokens

#### Résultat Attendu:
- ✅ Pas d'erreur "function consume_tokens not found"
- ✅ Logs montrent "Token consumption successful"
- ✅ Logs montrent le requestId unique
- ✅ Logs montrent le solde après consommation

### Test 5: Race Conditions (Avancé)

#### Script de Test:
```javascript
// À exécuter dans la console DevTools
async function testRaceCondition() {
  const promises = [];
  const numRequests = 10;

  for (let i = 0; i < numRequests; i++) {
    // Remplace par l'appel réel à ton API
    promises.push(
      fetch('/api/activity-analyzer', {
        method: 'POST',
        headers: {
          'Authorization': 'Bearer YOUR_TOKEN',
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ /* payload */ })
      })
    );
  }

  const results = await Promise.all(promises);
  console.log('Results:', results.map(r => r.status));
}

testRaceCondition();
```

#### Résultat Attendu:
- ✅ Toutes les requêtes sont traitées correctement
- ✅ Chaque requête consomme les tokens de façon séquentielle
- ✅ Le solde final est cohérent
- ✅ Aucune consommation en double

### Test 6: Autres Fonctions Migrées

Répète le Test 1 pour d'autres fonctionnalités:

#### Meal Analyzer:
1. Va sur Meals
2. Scan une photo de repas
3. Vérifie la déduction de tokens

#### Fridge Scanner:
1. Va sur Fridge
2. Scan ton frigo
3. Vérifie la déduction de tokens

#### Body Scan:
1. Va sur Avatar/Scanner
2. Lance un body scan
3. Vérifie la déduction de tokens

#### Recipe Generator:
1. Va sur Fridge > Recipes
2. Génère une recette
3. Vérifie la déduction de tokens

## 🔍 Requêtes SQL Utiles

### Voir ton solde actuel:
```sql
SELECT balance, tokens_per_month, subscription_tier
FROM token_balance
WHERE user_id = auth.uid();
```

### Voir l'historique complet:
```sql
SELECT
  operation_type,
  amount,
  balance_before,
  balance_after,
  created_at,
  metadata->>'cost_breakdown' as details
FROM token_balance_history
WHERE user_id = auth.uid()
ORDER BY created_at DESC;
```

### Calculer la consommation totale:
```sql
SELECT
  operation_type,
  COUNT(*) as num_operations,
  SUM(amount) as total_tokens
FROM token_balance_history
WHERE user_id = auth.uid()
  AND amount < 0
GROUP BY operation_type
ORDER BY total_tokens;
```

### Détecter les anomalies:
```sql
SELECT
  anomaly_type,
  severity,
  details,
  detected_at
FROM token_anomalies
WHERE user_id = auth.uid()
ORDER BY detected_at DESC;
```

## ✅ Checklist de Validation

- [ ] Test 1: Activity Analyzer déduit correctement les tokens
- [ ] Test 1: Meal Analyzer déduit correctement les tokens
- [ ] Test 1: Fridge Scanner déduit correctement les tokens
- [ ] Test 2: Idempotence fonctionne (pas de double consommation)
- [ ] Test 3: Erreur correcte quand solde insuffisant
- [ ] Test 4: Logs Supabase ne montrent aucune erreur
- [ ] Test 5: Race conditions gérées correctement
- [ ] Aucune entrée dans token_anomalies (sauf tests volontaires)
- [ ] Le solde dans la sidebar se met à jour en temps réel

## 🐛 Si un Test Échoue

### Tokens toujours pas déduits:
1. Vérifie les logs Edge Function
2. Vérifie que la migration est appliquée:
```sql
SELECT * FROM token_consumption_locks LIMIT 1;
```
3. Vérifie que le middleware est appelé (logs)

### Erreur 500 Internal Server Error:
1. Vérifie les logs Supabase
2. Vérifie les permissions RLS
3. Vérifie que l'utilisateur est authentifié

### Erreur "function not found":
1. Recharge la connexion Supabase
2. Vérifie que la migration est dans `migrations/`
3. Applique manuellement si nécessaire

## 📞 Support

Si tous les tests passent, le système fonctionne parfaitement et le bug initial est résolu! 🎉

Si un test échoue, note:
- Le numéro du test qui échoue
- Le message d'erreur exact
- Les logs Supabase correspondants
