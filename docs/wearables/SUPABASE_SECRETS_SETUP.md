# Configuration des Secrets Supabase pour Google Fit

Ce guide explique comment configurer les secrets nécessaires dans Supabase pour l'intégration Google Fit.

## Prérequis

Avant de commencer, vous devez avoir :
1. Les credentials OAuth 2.0 de Google Cloud Console
2. Accès au Dashboard Supabase de votre projet

## Configuration des Secrets

### Étape 1 : Accéder aux Secrets Supabase

1. Connectez-vous à [Supabase Dashboard](https://app.supabase.com)
2. Sélectionnez votre projet
3. Dans le menu latéral, allez dans **Edge Functions**
4. Cliquez sur l'onglet **Secrets**

### Étape 2 : Ajouter les Secrets Google Fit

Vous devez ajouter **2 secrets** avec les noms exacts suivants :

#### Secret 1 : GOOGLE_FIT_CLIENT_ID

**Nom du secret :**
```
GOOGLE_FIT_CLIENT_ID
```

**Valeur :**
```
156410607041-k8g4ft9iblbhn5g3r92stc144mgrcrku.apps.googleusercontent.com
```

**Note :** C'est la même valeur que `VITE_GOOGLE_OAUTH_CLIENT_ID` dans votre fichier `.env`

#### Secret 2 : GOOGLE_FIT_CLIENT_SECRET

**Nom du secret :**
```
GOOGLE_FIT_CLIENT_SECRET
```

**Valeur :**
```
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
```

**Note :** C'est la même valeur que `GOOGLE_OAUTH_CLIENT_SECRET` dans votre fichier `.env`

### Étape 3 : Vérifier la Configuration

Après avoir ajouté les secrets :

1. Vérifiez que les deux secrets apparaissent dans la liste
2. Les secrets sont automatiquement disponibles pour toutes vos Edge Functions
3. Les valeurs sont chiffrées et ne peuvent plus être lues après création

## Naming Convention Important

⚠️ **ATTENTION** : Les Edge Functions utilisent une convention de nommage spécifique :

- Pour Google Fit, les secrets doivent être nommés `GOOGLE_FIT_*` (avec underscore)
- La fonction construit le nom dynamiquement : `${provider.toUpperCase()}_CLIENT_ID`
- Exemple : pour le provider `google_fit`, la fonction cherche `GOOGLE_FIT_CLIENT_ID`

## Structure des Edge Functions

Les secrets sont utilisés dans deux Edge Functions :

### 1. wearable-oauth-callback

Cette fonction utilise les secrets pour :
- Échanger le code d'autorisation contre un access token
- Récupérer l'ID utilisateur du provider

```typescript
const clientId = Deno.env.get(`${provider.toUpperCase()}_CLIENT_ID`);
const clientSecret = Deno.env.get(`${provider.toUpperCase()}_CLIENT_SECRET`);
```

### 2. wearable-sync

Cette fonction utilise l'access token stocké pour :
- Récupérer les données de santé depuis Google Fit API
- Normaliser les données pour la base de données

## Variables d'Environnement - Vue d'Ensemble

### Frontend (.env local)

```env
VITE_GOOGLE_OAUTH_CLIENT_ID=156410607041-k8g4ft9iblbhn5g3r92stc144mgrcrku.apps.googleusercontent.com
VITE_GOOGLE_OAUTH_REDIRECT_URI=https://kwipydbtjagypocpvbwn.supabase.co/functions/v1/wearable-oauth-callback
```

### Supabase Edge Functions (Secrets Dashboard)

```
GOOGLE_FIT_CLIENT_ID=156410607041-k8g4ft9iblbhn5g3r92stc144mgrcrku.apps.googleusercontent.com
GOOGLE_FIT_CLIENT_SECRET=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
```

### Netlify (Production - Environment Variables)

```
VITE_GOOGLE_OAUTH_CLIENT_ID=156410607041-k8g4ft9iblbhn5g3r92stc144mgrcrku.apps.googleusercontent.com
VITE_GOOGLE_OAUTH_REDIRECT_URI=https://kwipydbtjagypocpvbwn.supabase.co/functions/v1/wearable-oauth-callback
```

## Test de Configuration

Après avoir configuré les secrets :

1. Redéployez vos Edge Functions (si nécessaire)
2. Allez dans Settings > Connected Devices
3. Désactivez le mode simulation
4. Cliquez sur "Connecter" pour Google Fit
5. Vérifiez que la redirection OAuth fonctionne
6. Après autorisation, vérifiez que l'appareil apparaît comme "Connecté"

## Troubleshooting

### Erreur : "Provider google_fit not configured"

**Cause :** Les secrets ne sont pas configurés ou mal nommés

**Solution :**
- Vérifiez que les secrets sont nommés exactement `GOOGLE_FIT_CLIENT_ID` et `GOOGLE_FIT_CLIENT_SECRET`
- Vérifiez qu'il n'y a pas d'espaces avant/après les noms ou valeurs

### Erreur : "Token exchange failed"

**Cause :** Client ID ou Client Secret incorrect

**Solution :**
- Vérifiez que les valeurs correspondent exactement à celles de Google Cloud Console
- Vérifiez qu'il n'y a pas de caractères cachés (copier-coller depuis un éditeur de texte)

### Erreur : "redirect_uri_mismatch"

**Cause :** L'URI de redirection ne correspond pas à celle configurée dans Google Cloud Console

**Solution :**
- L'application génère dynamiquement l'URI avec un paramètre de query string pour identifier le provider
- Vérifiez dans Google Cloud Console que l'URI **EXACTE** suivante est bien dans la liste des URI autorisés :
  ```
  https://kwipydbtjagypocpvbwn.supabase.co/functions/v1/wearable-oauth-callback?provider=google_fit
  ```
- **IMPORTANT** : L'URI doit inclure le paramètre `?provider=google_fit` pour que Google l'accepte
- Si vous voyez toujours l'erreur, vérifiez qu'il n'y a pas d'espaces avant ou après l'URI dans Google Cloud Console

## Sécurité

### Best Practices

1. **Ne jamais commiter les secrets** dans git
2. **Ne jamais exposer GOOGLE_FIT_CLIENT_SECRET** côté client
3. **Utiliser des secrets différents** pour développement et production (recommandé)
4. **Renouveler les secrets** régulièrement pour plus de sécurité

### Rotation des Secrets

Si vous devez changer les secrets :

1. Créez de nouveaux credentials dans Google Cloud Console
2. Mettez à jour les secrets dans Supabase Dashboard
3. Mettez à jour les variables d'environnement frontend
4. Les utilisateurs devront se reconnecter à leurs appareils

## Support

Pour toute question :
- Documentation complète : `/docs/wearables/HEALTH_CONNECT_SETUP.md`
- Edge Functions code : `/supabase/functions/wearable-oauth-callback/` et `/supabase/functions/wearable-sync/`
