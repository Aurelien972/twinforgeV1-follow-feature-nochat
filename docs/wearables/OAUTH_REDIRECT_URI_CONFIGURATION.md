# Configuration de l'URI de Redirection OAuth - Google Fit

## Vue d'Ensemble

Cette documentation explique comment l'URI de redirection OAuth est construite et utilisée dans l'application pour la connexion Google Fit.

## Architecture du Flux OAuth

### 1. Génération de l'URI par le Frontend

**Fichier**: `src/app/pages/Settings/ConnectedDevicesTab.tsx` (ligne 68)

```typescript
const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const redirectUri = `${supabaseUrl}/functions/v1/wearable-oauth-callback?provider=${provider}`;
```

Pour Google Fit, cela génère :
```
https://kwipydbtjagypocpvbwn.supabase.co/functions/v1/wearable-oauth-callback?provider=google_fit
```

### 2. Flux OAuth Complet

```
1. Utilisateur clique sur "Connecter" pour Google Fit
   ↓
2. Frontend appelle supabase.rpc('create_device_auth_flow')
   - Crée un enregistrement dans device_auth_flows
   - Génère un state sécurisé (UUID)
   - Stocke redirect_uri : "...?provider=google_fit"
   ↓
3. Frontend construit l'URL d'autorisation Google :
   - Authorization endpoint: https://accounts.google.com/o/oauth2/v2/auth
   - response_type: code
   - client_id: 156410607041-k8g4ft9iblbhn5g3r92stc144mgrcrku.apps.googleusercontent.com
   - redirect_uri: https://kwipydbtjagypocpvbwn.supabase.co/functions/v1/wearable-oauth-callback?provider=google_fit
   - state: [UUID généré par la DB]
   - scope: https://www.googleapis.com/auth/fitness.activity.read ...
   - access_type: offline
   - prompt: consent
   ↓
4. Redirection vers Google OAuth
   - L'utilisateur se connecte et autorise l'application
   ↓
5. Google redirige vers :
   https://kwipydbtjagypocpvbwn.supabase.co/functions/v1/wearable-oauth-callback?provider=google_fit&code=xxx&state=yyy
   ↓
6. Edge Function wearable-oauth-callback reçoit la requête
   - Extrait provider, code, state des query params
   - Vérifie state dans device_auth_flows
   - Échange code contre access_token
   - Stocke les tokens dans connected_devices
   ↓
7. Redirection vers l'app :
   https://[app-url]/settings?tab=appareils&connected=google_fit
```

### 3. Traitement par l'Edge Function

**Fichier**: `supabase/functions/wearable-oauth-callback/index.ts` (ligne 52-56)

```typescript
const url = new URL(req.url);
const provider = url.searchParams.get('provider');  // "google_fit"
const code = url.searchParams.get('code');          // Code d'autorisation de Google
const state = url.searchParams.get('state');        // UUID de vérification
const error = url.searchParams.get('error');        // Erreur éventuelle
```

## Configuration Google Cloud Console

### URI de Redirection Autorisée

Dans Google Cloud Console > APIs & Services > Credentials > OAuth 2.0 Client IDs, vous DEVEZ ajouter l'URI **EXACTE** :

```
https://kwipydbtjagypocpvbwn.supabase.co/functions/v1/wearable-oauth-callback?provider=google_fit
```

### Points Importants

1. **Le paramètre `?provider=google_fit` est OBLIGATOIRE**
   - Google vérifie l'URI complète incluant les query parameters
   - Sans ce paramètre, vous obtiendrez l'erreur `redirect_uri_mismatch`

2. **L'URI doit correspondre EXACTEMENT**
   - Pas d'espace avant ou après
   - Respecter la casse
   - Inclure le protocole HTTPS
   - Inclure le query parameter

3. **Format de l'URI**
   ```
   [PROTOCOLE]://[DOMAINE]/functions/v1/wearable-oauth-callback?provider=[PROVIDER_ID]
   ```

## Variables d'Environnement

### Frontend (.env)

```env
VITE_SUPABASE_URL=https://kwipydbtjagypocpvbwn.supabase.co
VITE_GOOGLE_OAUTH_CLIENT_ID=156410607041-k8g4ft9iblbhn5g3r92stc144mgrcrku.apps.googleusercontent.com
```

**Note** : La variable `VITE_GOOGLE_OAUTH_REDIRECT_URI` existe mais n'est PAS utilisée par le code. L'URI est construite dynamiquement.

### Supabase Edge Functions (Secrets)

```
GOOGLE_FIT_CLIENT_ID=156410607041-k8g4ft9iblbhn5g3r92stc144mgrcrku.apps.googleusercontent.com
GOOGLE_FIT_CLIENT_SECRET=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
```

## Vérification de la Configuration

### 1. Vérifier le Frontend

Ouvrez la console du navigateur et recherchez :

```
[CONNECTED_DEVICES] Creating OAuth flow in database
{
  provider: "google_fit",
  redirectUri: "https://kwipydbtjagypocpvbwn.supabase.co/functions/v1/wearable-oauth-callback?provider=google_fit"
}
```

### 2. Vérifier Google Cloud Console

1. Allez dans : https://console.cloud.google.com/apis/credentials
2. Cliquez sur votre OAuth 2.0 Client ID
3. Vérifiez que cette URI EXACTE est listée :
   ```
   https://kwipydbtjagypocpvbwn.supabase.co/functions/v1/wearable-oauth-callback?provider=google_fit
   ```

### 3. Vérifier la Base de Données

```sql
-- Vérifier les auth flows créés
SELECT
  id,
  user_id,
  provider,
  redirect_uri,
  status,
  created_at,
  expires_at
FROM device_auth_flows
WHERE provider = 'google_fit'
ORDER BY created_at DESC
LIMIT 5;
```

L'URI doit apparaître avec `?provider=google_fit` dans la colonne `redirect_uri`.

## Troubleshooting

### Erreur : redirect_uri_mismatch

**Symptômes** :
```
Erreur 400 : redirect_uri_mismatch
You can't sign in to this app because it doesn't comply with Google's OAuth 2.0 policy
```

**Causes possibles** :

1. ❌ L'URI dans Google Cloud Console ne contient pas `?provider=google_fit`
2. ❌ Il y a une différence de casse (ex: `google_Fit` vs `google_fit`)
3. ❌ Il y a des espaces avant/après l'URI
4. ❌ Le protocole est incorrect (http au lieu de https)
5. ❌ L'URI a été modifiée après ajout dans Google Cloud Console

**Solutions** :

1. ✅ Vérifiez que l'URI **EXACTE** est dans Google Cloud Console :
   ```
   https://kwipydbtjagypocpvbwn.supabase.co/functions/v1/wearable-oauth-callback?provider=google_fit
   ```

2. ✅ Supprimez et recréez l'URI si nécessaire (copier-coller depuis ce document)

3. ✅ Attendez quelques minutes après modification (cache Google)

4. ✅ Testez dans une fenêtre de navigation privée

### Erreur : État de sécurité invalide

**Symptômes** :
```
État de sécurité invalide ou expiré
```

**Causes** :
- Le state n'existe pas dans `device_auth_flows`
- Le state a expiré (>15 minutes)
- Le state a déjà été utilisé (status = 'completed')

**Solutions** :
1. Vérifiez que la migration `20251020170000_create_oauth_flow_init_function.sql` est appliquée
2. Vérifiez que la fonction RPC `create_device_auth_flow` existe
3. Réessayez la connexion (un nouveau state sera généré)

## Tests

### Test Manuel

1. Allez dans Settings > Appareils Connectés
2. Désactivez le mode simulation (si activé)
3. Cliquez sur "Connecter" pour Google Fit
4. Vérifiez dans la console :
   - "Creating OAuth flow in database"
   - "Auth flow created successfully"
   - "Redirecting to OAuth provider"
5. Complétez l'autorisation Google
6. Vérifiez que vous êtes redirigé vers `/settings?tab=appareils&connected=google_fit`
7. Vérifiez que l'appareil apparaît dans la liste

### Test SQL

```sql
-- Vérifier le flux complet
SELECT
  daf.provider,
  daf.redirect_uri,
  daf.status AS auth_status,
  daf.created_at AS auth_created,
  cd.display_name,
  cd.status AS device_status,
  cd.connected_at
FROM device_auth_flows daf
LEFT JOIN connected_devices cd
  ON cd.user_id = daf.user_id
  AND cd.provider = daf.provider
WHERE daf.provider = 'google_fit'
ORDER BY daf.created_at DESC
LIMIT 5;
```

## Support Multi-Provider

Le même système fonctionne pour tous les wearables :

- `?provider=google_fit` → Google Fit
- `?provider=strava` → Strava
- `?provider=garmin` → Garmin
- `?provider=fitbit` → Fitbit
- etc.

Chaque provider doit avoir son URI complète configurée dans la console OAuth respective.

## Résumé

✅ **Configuration Correcte** :
- Code frontend génère l'URI avec `?provider=google_fit`
- URI complète stockée dans `device_auth_flows.redirect_uri`
- URI complète configurée dans Google Cloud Console
- Edge function extrait le provider des query params

✅ **Points de Vérification** :
1. Frontend construit l'URI dynamiquement
2. Base de données stocke l'URI complète
3. Google Cloud Console a l'URI exacte
4. Edge function traite correctement les query params

✅ **Documentation Mise à Jour** :
- ✅ SUPABASE_SECRETS_SETUP.md
- ✅ .env.example
- ✅ Ce document (OAUTH_REDIRECT_URI_CONFIGURATION.md)
