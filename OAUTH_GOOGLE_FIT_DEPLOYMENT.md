# Guide de Déploiement - Fix OAuth Google Fit

## ✅ Problème Résolu

L'erreur `redirect_uri_mismatch` est maintenant résolue grâce à l'ajout de l'URI correcte dans Google Cloud Console.

## 📋 Résumé des Changements

### Fichiers Modifiés

1. **docs/wearables/SUPABASE_SECRETS_SETUP.md**
   - Mise à jour de la section "Erreur: redirect_uri_mismatch"
   - Ajout de l'URI exacte avec le paramètre `?provider=google_fit`
   - Instructions clarifiées

2. **.env.example**
   - Ajout de commentaires expliquant l'URI exacte requise
   - Note sur le paramètre `?provider=google_fit`

3. **docs/wearables/OAUTH_REDIRECT_URI_CONFIGURATION.md** (NOUVEAU)
   - Documentation complète du flux OAuth
   - Explication détaillée de l'architecture
   - Guide de troubleshooting
   - Tests et vérifications

## 🔧 Configuration Google Cloud Console (FAIT ✅)

Vous avez déjà ajouté l'URI correcte :

```
https://kwipydbtjagypocpvbwn.supabase.co/functions/v1/wearable-oauth-callback?provider=google_fit
```

Cette URI est maintenant enregistrée dans votre OAuth 2.0 Client ID Google.

## 🚀 Déploiement en Production

### Étape 1 : Déployer les Changements de Documentation

Les fichiers modifiés sont uniquement de la documentation, donc aucun rebuild n'est nécessaire pour ces fichiers.

### Étape 2 : Vérifier les Variables d'Environnement (Netlify)

Assurez-vous que ces variables sont configurées dans Netlify :

```
VITE_SUPABASE_URL=https://kwipydbtjagypocpvbwn.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt3aXB5ZGJ0amFneXBvY3B2YnduIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ2ODg0MjIsImV4cCI6MjA3MDI2NDQyMn0.IS5IdKbmnGtgU_AaGYtUgX3ewaNpsiSAui5kbFV31_U
VITE_GOOGLE_OAUTH_CLIENT_ID=156410607041-k8g4ft9iblbhn5g3r92stc144mgrcrku.apps.googleusercontent.com
```

### Étape 3 : Vérifier les Secrets Supabase (Déjà configurés)

Dans Supabase Dashboard > Edge Functions > Secrets, ces secrets doivent être présents :

```
GOOGLE_FIT_CLIENT_ID=156410607041-k8g4ft9iblbhn5g3r92stc144mgrcrku.apps.googleusercontent.com
GOOGLE_FIT_CLIENT_SECRET=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
```

### Étape 4 : Tester la Connexion

1. Allez sur votre app en production : https://[votre-app].netlify.app
2. Connectez-vous avec votre compte
3. Allez dans **Settings → Appareils Connectés**
4. Cliquez sur **"Connecter"** pour Google Fit
5. Vous devriez être redirigé vers Google OAuth
6. Après autorisation, vous devriez revenir sur l'app avec l'appareil connecté

## ✅ Vérifications Post-Déploiement

### 1. Vérifier le Flux OAuth

Ouvrez la console du navigateur et recherchez ces logs :

```
[CONNECTED_DEVICES] Creating OAuth flow in database
{
  provider: "google_fit",
  redirectUri: "https://kwipydbtjagypocpvbwn.supabase.co/functions/v1/wearable-oauth-callback?provider=google_fit"
}

[CONNECTED_DEVICES] Auth flow created successfully
{
  provider: "google_fit",
  state: "[UUID]",
  expiresAt: "[timestamp]"
}

[CONNECTED_DEVICES] Redirecting to OAuth provider
{
  provider: "google_fit",
  authUrl: "https://accounts.google.com/o/oauth2/v2/auth?..."
}
```

### 2. Vérifier la Base de Données

Connectez-vous à Supabase SQL Editor et exécutez :

```sql
-- Vérifier les auth flows
SELECT
  provider,
  redirect_uri,
  status,
  created_at,
  expires_at
FROM device_auth_flows
WHERE provider = 'google_fit'
  AND created_at > NOW() - INTERVAL '1 hour'
ORDER BY created_at DESC;

-- Vérifier les appareils connectés
SELECT
  provider,
  display_name,
  status,
  connected_at,
  last_sync_at
FROM connected_devices
WHERE provider = 'google_fit'
ORDER BY connected_at DESC;
```

### 3. Vérifier les Logs Edge Function

Dans Supabase Dashboard > Edge Functions > wearable-oauth-callback > Logs :

Recherchez des logs récents de connexion. Vous devriez voir :
- Extraction des paramètres (provider, code, state)
- Vérification du state dans la DB
- Échange du code contre un token
- Création de l'appareil connecté

## 🐛 Troubleshooting

### Si vous voyez encore "redirect_uri_mismatch"

1. **Vérifiez Google Cloud Console**
   - Allez sur https://console.cloud.google.com/apis/credentials
   - Cliquez sur votre OAuth 2.0 Client ID
   - Vérifiez que cette URI EXACTE est présente :
     ```
     https://kwipydbtjagypocpvbwn.supabase.co/functions/v1/wearable-oauth-callback?provider=google_fit
     ```
   - Pas d'espaces, bonne casse, avec le paramètre

2. **Videz le cache**
   - Google peut mettre en cache les configurations OAuth
   - Attendez 5-10 minutes après modification
   - Testez en navigation privée

3. **Vérifiez l'URL générée**
   - Dans la console du navigateur, copiez l'URL complète de redirection Google
   - Extrayez le paramètre `redirect_uri`
   - Comparez-le avec ce qui est dans Google Cloud Console

### Si l'état de sécurité est invalide

1. **Vérifiez la migration**
   ```sql
   -- Vérifier que la fonction RPC existe
   SELECT proname, prosrc
   FROM pg_proc
   WHERE proname = 'create_device_auth_flow';
   ```

2. **Testez la fonction manuellement**
   ```sql
   SELECT create_device_auth_flow(
     'google_fit',
     'https://kwipydbtjagypocpvbwn.supabase.co/functions/v1/wearable-oauth-callback?provider=google_fit'
   );
   ```

3. **Vérifiez les enregistrements**
   ```sql
   SELECT * FROM device_auth_flows
   ORDER BY created_at DESC
   LIMIT 5;
   ```

## 📊 Monitoring

### Métriques à Suivre

```sql
-- Taux de succès OAuth (dernières 24h)
SELECT
  status,
  COUNT(*) as count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage
FROM device_auth_flows
WHERE created_at > NOW() - INTERVAL '24 hours'
GROUP BY status;

-- Temps moyen de complétion
SELECT
  AVG(EXTRACT(EPOCH FROM (updated_at - created_at))) as avg_seconds
FROM device_auth_flows
WHERE status = 'completed'
  AND created_at > NOW() - INTERVAL '7 days';

-- Erreurs récentes
SELECT
  provider,
  status,
  created_at,
  expires_at
FROM device_auth_flows
WHERE status = 'pending'
  AND expires_at < NOW()
ORDER BY created_at DESC
LIMIT 10;
```

## 📚 Documentation

Pour plus de détails, consultez :

1. **docs/wearables/OAUTH_REDIRECT_URI_CONFIGURATION.md**
   - Architecture complète du flux OAuth
   - Troubleshooting détaillé

2. **docs/wearables/SUPABASE_SECRETS_SETUP.md**
   - Configuration des secrets
   - Variables d'environnement

3. **docs/wearables/HEALTH_CONNECT_SETUP.md**
   - Configuration Google Cloud Console
   - Activation des APIs

4. **OAUTH_FIX_DEPLOYMENT_GUIDE.md**
   - Guide de déploiement de la fix précédente
   - Tests et vérifications

## ✅ Checklist de Déploiement

- [x] URI ajoutée dans Google Cloud Console
- [x] Documentation mise à jour
- [x] Variables d'environnement Netlify vérifiées
- [x] Secrets Supabase vérifiés
- [ ] Test de connexion en production
- [ ] Vérification des logs
- [ ] Vérification de la base de données
- [ ] Monitoring des métriques

## 🎉 Résultat Attendu

Après déploiement, les utilisateurs pourront :

1. ✅ Cliquer sur "Connecter" pour Google Fit
2. ✅ Être redirigés vers Google OAuth (pas d'erreur 400)
3. ✅ Autoriser l'application
4. ✅ Revenir sur l'app avec l'appareil connecté
5. ✅ Voir l'appareil dans la liste "Mes Appareils"
6. ✅ Synchroniser les données de santé

## 📞 Support

Si vous rencontrez des problèmes après déploiement :

1. Vérifiez les logs de la console du navigateur
2. Vérifiez les logs Supabase Edge Functions
3. Vérifiez la base de données (device_auth_flows et connected_devices)
4. Consultez la documentation dans docs/wearables/
5. Vérifiez que l'URI dans Google Cloud Console est EXACTE (avec ?provider=google_fit)

---

**Date de création** : 2025-10-20
**Version** : 1.0
**Statut** : ✅ Prêt pour production
