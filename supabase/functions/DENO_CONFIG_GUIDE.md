# Guide de Configuration Deno pour les Edge Functions Supabase

## Problème Résolu

**Erreur initiale:** `Cannot find module 'tslib'`

Cette erreur se produisait lorsque les fonctions Edge tentaient d'importer `@supabase/supabase-js` sans configuration appropriée des dépendances externes.

## Solution Implémentée

Chaque fonction Edge qui utilise `npm:@supabase/supabase-js` doit avoir un fichier `deno.json` qui:

1. Configure les imports pour utiliser ESM via `esm.sh`
2. Déclare explicitement `tslib` et les sous-modules Supabase comme externes
3. Configure les options du compilateur TypeScript pour Deno

## Template deno.json Standard

```json
{
  "imports": {
    "npm:@supabase/supabase-js@2.54.0": "https://esm.sh/@supabase/supabase-js@2.54.0?target=deno&external=tslib,@supabase/node-fetch,@supabase/storage-js,@supabase/functions-js,@supabase/auth-js,@supabase/realtime-js,@supabase/postgrest-js",
    "npm:@supabase/supabase-js@2": "https://esm.sh/@supabase/supabase-js@2.54.0?target=deno&external=tslib,@supabase/node-fetch,@supabase/storage-js,@supabase/functions-js,@supabase/auth-js,@supabase/realtime-js,@supabase/postgrest-js",
    "npm:tslib": "https://esm.sh/tslib@2.6.2?target=deno"
  },
  "compilerOptions": {
    "lib": ["deno.window", "dom", "dom.iterable", "dom.asynciterable"],
    "types": ["npm:@types/node"]
  }
}
```

## Fonctions Corrigées

Les fonctions suivantes ont reçu un fichier `deno.json` pour résoudre l'erreur:

### Fonctions d'Analyse d'Activités (Priority: HIGH)
- `biometric-insights-analyzer` ⭐ (fonction principale problématique)
- `activity-analyzer`
- `activity-progress-generator` (avait déjà un deno.json partiel)

### Fonctions de Scan Corporel
- `scan-estimate`
- `scan-semantic`
- `scan-commit`
- `scan-latest`

### Fonctions de Nutrition
- `meal-analyzer`
- `daily-nutrition-summary`
- `nutrition-trend-analysis`

### Fonctions de Jeûne
- `fasting-insights-generator`
- `fasting-progression-analyzer`

### Fonctions de Frigo et Recettes
- `fridge-scan-vision`
- `inventory-processor`
- `recipe-generator`

### Fonctions de Paiement
- `stripe-webhooks`
- `create-checkout-session`
- `create-portal-session`

### Autres Fonctions
- `chat-ai`
- `activity-transcriber`
- `morphology-mapping`
- `generate-morph-insights`
- `detect-equipment`
- `process-detection-jobs`
- `process-pending-enrichments`
- `reset-monthly-tokens`

## Fonctions Utilisant des Imports CDN Directs (OK)

Les fonctions suivantes utilisent déjà des imports CDN ESM directs et n'ont pas besoin de deno.json:
- `image-generator`
- `inventory-complementer`
- `wearable-oauth-callback`
- `enrich-activity-wearable`
- `recipe-detail-generator`
- `wearable-sync` (a déjà un deno.json)
- `shopping-list-generator`
- `process-enrichment-queue`

## Best Practices

### Pour les Nouvelles Edge Functions

1. **Utilisez toujours un import CDN ESM direct** (recommandé):
   ```typescript
   import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
   ```

2. **OU créez un deno.json** si vous utilisez `npm:` imports:
   - Copiez le template ci-dessus
   - Ajustez la version si nécessaire
   - Placez-le dans le dossier de votre fonction

3. **Pour les imports dynamiques**, utilisez toujours:
   ```typescript
   const { createClient } = await import('https://esm.sh/@supabase/supabase-js@2.54.0');
   ```

### Pourquoi `external=tslib` est Nécessaire

Le paramètre `external=tslib` dans l'URL ESM indique à `esm.sh` de ne pas bundle `tslib` dans le module. Cela permet au runtime Deno de résoudre `tslib` via l'import map défini dans `deno.json`, évitant ainsi l'erreur "Cannot find module 'tslib'".

### Dépendances Externes Requises

Toutes les sous-bibliothèques Supabase doivent être déclarées comme externes:
- `tslib` (critique)
- `@supabase/node-fetch`
- `@supabase/storage-js`
- `@supabase/functions-js`
- `@supabase/auth-js`
- `@supabase/realtime-js`
- `@supabase/postgrest-js`

## Vérification et Tests

Pour tester qu'une fonction fonctionne correctement:

1. Déployez la fonction via Supabase CLI ou l'interface
2. Vérifiez les logs pour toute erreur de module manquant
3. Testez un appel réel depuis le frontend
4. Vérifiez que les imports sont bien résolus

## Maintenance Future

Si vous ajoutez une nouvelle fonction qui utilise `@supabase/supabase-js`:

1. Créez immédiatement le fichier `deno.json`
2. Utilisez le template standard
3. Testez localement avec Supabase CLI avant de déployer
4. Documentez toute déviation de la configuration standard

## Troubleshooting

### Si vous voyez "Cannot find module 'X'"

1. Vérifiez que `deno.json` existe dans le dossier de la fonction
2. Vérifiez que le module manquant est listé dans `external=...`
3. Ajoutez une entrée dans `imports` pour mapper le module
4. Redéployez la fonction

### Si les imports ne se résolvent pas

1. Vérifiez la version dans l'URL ESM
2. Assurez-vous que `target=deno` est présent
3. Vérifiez que l'URL ESM est accessible
4. Testez manuellement l'import avec `deno run`

---

**Date de Création:** 2025-10-21
**Auteur:** Système de correction automatique
**Version:** 1.0
