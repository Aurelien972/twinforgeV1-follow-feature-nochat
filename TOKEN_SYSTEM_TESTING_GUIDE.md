# Guide de Test - Système de Tokens pour Nouveaux Utilisateurs

## Vue d'ensemble
Ce guide explique comment tester le système complet de tokens pour les nouveaux utilisateurs, de la création de compte à l'affichage de la notification de bienvenue.

## Prérequis
- Accès à la base de données Supabase
- Application en mode développement
- Accès aux DevTools du navigateur

---

## Test 1: Création d'un Nouveau Compte

### Objectif
Vérifier que le système de tokens fonctionne correctement lors de l'inscription d'un nouvel utilisateur.

### Étapes
1. **Créer un nouveau compte**
   - Aller sur la page d'inscription
   - Créer un compte avec une nouvelle adresse email
   - Se connecter immédiatement après création

2. **Vérifier les logs de la console**
   ```
   Attendu:
   ✅ Aucune erreur PGRST116
   ✅ Log "TOKEN_BALANCE_WIDGET" avec "Token balance loaded successfully"
   ✅ Log "WELCOME_TOKENS_TOAST" avec "Welcome tokens toast shown"
   ```

3. **Vérifier l'UI**
   - Le widget de tokens dans la sidebar affiche "15k tokens disponibles"
   - Un toast de bienvenue apparaît après ~2 secondes
   - La notification premium s'affiche en haut de page

4. **Vérifier la base de données**
   ```sql
   -- Remplacer <user_id> par l'ID du nouvel utilisateur

   -- Vérifier le solde
   SELECT * FROM user_token_balance WHERE user_id = '<user_id>';
   -- Attendu: available_tokens = 15000, bonus_tokens = 15000

   -- Vérifier l'abonnement
   SELECT * FROM user_subscriptions WHERE user_id = '<user_id>';
   -- Attendu: plan_type = 'free', subscription_status = 'trialing'

   -- Vérifier la transaction
   SELECT * FROM token_transactions
   WHERE user_id = '<user_id>'
     AND transaction_type = 'bonus'
     AND metadata->>'reason' = 'welcome_bonus';
   -- Attendu: 1 ligne avec token_amount = 15000
   ```

### Critères de Succès
- ✅ Aucune erreur dans la console
- ✅ Widget affiche le bon solde
- ✅ Toast et notification apparaissent
- ✅ Données correctes en base

---

## Test 2: Connexion avec Compte Existant

### Objectif
Vérifier que le système ne re-affiche pas la notification pour les utilisateurs existants.

### Étapes
1. **Se déconnecter et se reconnecter**
   - Déconnexion du compte créé dans Test 1
   - Reconnexion avec le même compte

2. **Vérifier l'UI**
   - Le widget de tokens s'affiche normalement
   - **Aucune notification de bienvenue ne doit apparaître**
   - **Aucun toast de bienvenue ne doit apparaître**

3. **Vérifier localStorage**
   ```javascript
   // Dans la console du navigateur
   const userId = '<user_id>'; // Remplacer par l'ID réel
   console.log('Toast shown:', localStorage.getItem(`welcome_tokens_toast_shown_${userId}`));
   console.log('Notification shown:', localStorage.getItem(`welcome_tokens_shown_${userId}`));
   // Attendu: Les deux doivent être 'true'
   ```

### Critères de Succès
- ✅ Widget fonctionne normalement
- ✅ Aucune notification ne réapparaît
- ✅ LocalStorage contient les flags

---

## Test 3: Retry Logic du Widget

### Objectif
Vérifier que le widget gère correctement les cas où le solde n'est pas immédiatement disponible.

### Étapes
1. **Simuler un délai de création**
   ```sql
   -- Dans Supabase SQL Editor
   -- Désactiver temporairement le trigger
   DROP TRIGGER IF EXISTS on_user_created_token_balance ON auth.users;
   ```

2. **Créer un nouveau compte**
   - L'utilisateur ne devrait pas avoir de solde initialement

3. **Observer les logs**
   ```
   Attendu:
   ⚠️ Log "TOKEN_BALANCE_WIDGET" avec "Token balance not found, scheduling retry"
   ⚠️ Log avec "retryCount: 1, delayMs: 1000"
   ```

4. **Créer manuellement le solde**
   ```sql
   -- Remplacer <user_id>
   INSERT INTO user_token_balance (
     user_id, available_tokens, subscription_tokens,
     onetime_tokens, bonus_tokens
   ) VALUES (
     '<user_id>', 15000, 0, 0, 15000
   );
   ```

5. **Vérifier que le widget se met à jour**
   - Le widget devrait afficher le solde après quelques secondes
   - Log "Token balance loaded successfully after retry"

6. **Réactiver le trigger**
   ```sql
   CREATE TRIGGER on_user_created_token_balance
     AFTER INSERT ON auth.users
     FOR EACH ROW
     EXECUTE FUNCTION create_user_token_balance();
   ```

### Critères de Succès
- ✅ Widget détecte l'absence de solde
- ✅ Retry automatique fonctionne
- ✅ Widget se met à jour quand le solde est créé

---

## Test 4: Subscription Temps Réel

### Objectif
Vérifier que le widget se met à jour en temps réel quand le solde change.

### Étapes
1. **Ouvrir deux onglets**
   - Onglet 1: Interface utilisateur normale
   - Onglet 2: Supabase SQL Editor

2. **Modifier le solde dans l'onglet 2**
   ```sql
   UPDATE user_token_balance
   SET available_tokens = 20000,
       bonus_tokens = 20000
   WHERE user_id = '<user_id>';
   ```

3. **Observer l'onglet 1**
   - Le widget devrait se mettre à jour automatiquement
   - Le solde devrait passer à "20k tokens disponibles"
   - Log "Token balance updated via subscription"

### Critères de Succès
- ✅ Widget se met à jour sans refresh
- ✅ Nouvelle valeur affichée instantanément
- ✅ Log de subscription présent

---

## Test 5: Migration des Utilisateurs Existants

### Objectif
Vérifier que tous les utilisateurs existants ont reçu leur solde rétroactivement.

### Étapes
1. **Lister tous les utilisateurs**
   ```sql
   SELECT
     u.id,
     u.email,
     u.created_at as user_created,
     utb.available_tokens,
     utb.created_at as balance_created,
     tt.metadata->>'reason' as transaction_reason
   FROM auth.users u
   LEFT JOIN user_token_balance utb ON u.id = utb.user_id
   LEFT JOIN token_transactions tt ON u.id = tt.user_id
     AND tt.transaction_type = 'bonus'
   ORDER BY u.created_at DESC;
   ```

2. **Vérifier les résultats**
   - Tous les utilisateurs doivent avoir un solde
   - Les utilisateurs créés avant la migration doivent avoir `transaction_reason = 'backfill_welcome_bonus'`
   - Les nouveaux utilisateurs doivent avoir `transaction_reason = 'welcome_bonus'`

3. **Vérifier qu'aucun utilisateur n'est oublié**
   ```sql
   SELECT COUNT(*) as users_without_balance
   FROM auth.users u
   LEFT JOIN user_token_balance utb ON u.id = utb.user_id
   WHERE utb.user_id IS NULL;
   -- Attendu: 0
   ```

### Critères de Succès
- ✅ Tous les utilisateurs ont un solde
- ✅ Backfill correctement identifié
- ✅ Aucun utilisateur oublié

---

## Test 6: Gestion d'Erreurs

### Objectif
Vérifier que le système gère les erreurs gracieusement.

### Scénarios à tester

### 6.1 Trigger échoue mais n'empêche pas la création de compte
```sql
-- Simuler une erreur dans le trigger
CREATE OR REPLACE FUNCTION create_user_token_balance()
RETURNS TRIGGER AS $$
BEGIN
  RAISE EXCEPTION 'Simulated error';
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Créer un nouveau compte
-- Attendu: Le compte est créé, warning dans les logs PostgreSQL

-- Restaurer le trigger
-- (Réappliquer la migration 20251020220000)
```

### 6.2 Widget ne peut pas charger le solde
- Ouvrir DevTools > Network
- Bloquer les requêtes vers `/rest/v1/user_token_balance`
- Recharger la page
- Attendu: Widget masqué, logs d'erreur propres

### Critères de Succès
- ✅ Erreurs loggées mais n'empêchent pas l'usage
- ✅ UI se dégrade gracieusement
- ✅ Aucun crash de l'application

---

## Test 7: Performance

### Objectif
Vérifier que le système n'impacte pas les performances.

### Métriques à mesurer

1. **Temps de création de compte**
   ```sql
   -- Dans les logs PostgreSQL, chercher:
   -- NOTICE: Token balance backfill complete. Fixed N users.
   ```

2. **Temps de chargement du widget**
   - DevTools > Performance
   - Mesurer le temps entre mount et affichage
   - Attendu: < 500ms

3. **Taille des requêtes**
   - DevTools > Network
   - Vérifier la taille de la réponse `user_token_balance`
   - Attendu: < 1KB

### Critères de Succès
- ✅ Création de compte < 2 secondes
- ✅ Widget chargé < 500ms
- ✅ Pas de lag visible

---

## Checklist de Validation Finale

Avant de considérer le système prêt pour la production:

### Base de Données
- [ ] Migration appliquée sans erreur
- [ ] Tous les utilisateurs ont un solde
- [ ] Toutes les transactions sont loggées
- [ ] Triggers fonctionnent correctement

### Frontend
- [ ] Widget affiche correctement le solde
- [ ] Retry logic fonctionne
- [ ] Subscription temps réel fonctionne
- [ ] Toast de bienvenue s'affiche
- [ ] Notification premium s'affiche
- [ ] LocalStorage gère les flags

### Expérience Utilisateur
- [ ] Aucune erreur visible pour l'utilisateur
- [ ] Notifications apparaissent au bon moment
- [ ] Messages clairs et compréhensibles
- [ ] Design cohérent avec le reste de l'app

### Sécurité
- [ ] RLS policies en place
- [ ] Aucune donnée sensible exposée
- [ ] Logs ne contiennent pas de PII
- [ ] Triggers avec SECURITY DEFINER

### Monitoring
- [ ] Logs structurés et recherchables
- [ ] Métriques de succès définies
- [ ] Alerts configurées pour les erreurs
- [ ] Dashboard de monitoring prêt

---

## Dépannage

### Problème: Widget n'affiche pas le solde

**Diagnostic:**
```sql
-- Vérifier si l'utilisateur a un solde
SELECT * FROM user_token_balance WHERE user_id = '<user_id>';
```

**Solutions:**
1. Si pas de solde: Créer manuellement
2. Si erreur RLS: Vérifier les policies
3. Si erreur network: Vérifier Supabase status

### Problème: Notification ne s'affiche pas

**Diagnostic:**
```javascript
// Console du navigateur
const userId = '<user_id>';
console.log('Shown:', localStorage.getItem(`welcome_tokens_shown_${userId}`));
```

**Solutions:**
1. Clear localStorage et rafraîchir
2. Vérifier la transaction dans `token_transactions`
3. Vérifier les logs console pour erreurs

### Problème: Trigger ne s'exécute pas

**Diagnostic:**
```sql
-- Vérifier que le trigger existe
SELECT * FROM pg_trigger WHERE tgname = 'on_user_created_token_balance';
```

**Solutions:**
1. Réappliquer la migration
2. Vérifier les permissions du trigger
3. Consulter les logs PostgreSQL

---

## Contacts

Pour toute question ou problème:
- Documentation: `TOKEN_ONBOARDING_FIX_SUMMARY.md`
- Logs: Chercher "TOKEN_BALANCE_WIDGET", "WELCOME_TOKENS"
- Support: Consulter les logs Supabase

---

**Date de dernière mise à jour**: 2025-10-20
**Version du système**: 1.0.0
**Migration**: 20251020220000_fix_token_balance_creation_for_new_users
