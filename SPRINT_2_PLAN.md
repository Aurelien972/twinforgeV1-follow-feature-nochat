# Sprint 2 - Input Validation & CSP Enforcement - Plan Détaillé

## Status: 🚀 READY TO START

**Durée estimée**: 3-4 jours
**Priorité**: IMPORTANT
**Risque de régression**: 🟡 MEDIUM (Attention particulière aux AI agents)

---

## Objectifs Sprint 2

1. ✅ Créer un système de validation unifié
2. ✅ Valider les 5 Edge Functions AI les plus critiques
3. ✅ Activer le CSP strict (après monitoring)
4. ✅ Implémenter les tokens CSRF pour les opérations critiques

---

## Phase 3: Input Validation

### Phase 3.1: Système de Validation Unifié ⏱️ 1 jour

#### Objectif
Créer un système de validation partagé pour toutes les Edge Functions, **sans modifier les paramètres AI existants**.

#### Principes de Base

**🚨 RÈGLES CRITIQUES - NE PAS CASSER LES AI AGENTS**:
1. ❌ **NE PAS** modifier les prompts AI
2. ❌ **NE PAS** modifier les modèles utilisés (gpt-4o, gpt-4o-mini, gpt-o1-preview)
3. ❌ **NE PAS** modifier les paramètres temperature/top_p
4. ❌ **NE PAS** modifier les max_tokens
5. ✅ **UNIQUEMENT** valider les inputs AVANT d'appeler l'AI
6. ✅ **UNIQUEMENT** valider les outputs APRÈS réception de l'AI

#### Implémentation

**Fichier à créer**: `supabase/functions/_shared/validation/index.ts`

```typescript
// Validation des inputs utilisateur (avant AI)
export const validateUserInput = {
  userId: (id: string) => {
    // Valider format UUID
    // Vérifier longueur
    // Sanitize
  },

  imageData: (data: string) => {
    // Valider base64
    // Vérifier taille max
    // Vérifier format
  },

  textInput: (text: string, maxLength: number) => {
    // Valider longueur
    // Sanitize HTML
    // Vérifier encodage
  }
};

// Validation des paramètres métier (non-AI)
export const validateBusinessParams = {
  weight: (kg: number) => {
    // 20-300 kg
  },
  height: (cm: number) => {
    // 100-250 cm
  },
  age: (years: number) => {
    // 13-120 ans
  }
};

// ⚠️ NE PAS VALIDER LES RÉPONSES AI
// Les AI agents sont configurés avec soin, ne pas les brider
```

#### Fichiers Concernés

**Créer**:
- `supabase/functions/_shared/validation/index.ts`
- `supabase/functions/_shared/validation/schemas.ts`
- `supabase/functions/_shared/validation/sanitizers.ts`

**Ne PAS modifier**:
- Aucune modification des fonctions AI existantes pour l'instant
- On validera dans Phase 3.2 de manière chirurgicale

---

### Phase 3.2: Validation des 5 Edge Functions Critiques ⏱️ 2 jours

#### Les 5 Fonctions AI Critiques Identifiées

1. **scan-estimate** 📸
   - Analyse photos avec GPT-4o Vision
   - **Risque**: Injection via images malformées
   - **À valider**: Format images, taille, user_id
   - **NE PAS toucher**: Prompt vision, température, max_tokens

2. **scan-refine-morphs** 🎨
   - Raffinement morphologique avec GPT-4o
   - **Risque**: Manipulation des paramètres morphologiques
   - **À valider**: Paramètres numériques (ranges), user_id
   - **NE PAS toucher**: Prompt AI, logique de raffinement

3. **meal-analyzer** 🍽️
   - Analyse nutritionnelle avec GPT-4o
   - **Risque**: Injection via descriptions de repas
   - **À valider**: Images, texte utilisateur, scanned_products
   - **NE PAS toucher**: Prompt nutritionnel, contexte utilisateur

4. **activity-analyzer** 🏃
   - Analyse activités avec GPT-5-mini
   - **Risque**: Injection via description activité
   - **À valider**: Texte transcrit, user_id, timestamps
   - **NE PAS toucher**: Logique MET, calcul calories, prompt

5. **chat-ai** 💬
   - Chat multi-contexte avec GPT-4o-mini
   - **Risque**: Injection de prompts malveillants
   - **À valider**: Messages utilisateur, longueur, encodage
   - **NE PAS toucher**: System prompts, modes, streaming

#### Stratégie de Validation Par Fonction

##### 1. scan-estimate - Validation Images

**Avant AI**:
```typescript
// Valider AVANT l'appel à analyzePhotosWithVision()
const validatedPhotos = photos.map(photo => {
  validateUserInput.imageData(photo);
  // Vérifier dimensions max
  // Vérifier format (jpeg/png)
  // Vérifier taille < 20MB
  return photo;
});
```

**Ne pas modifier**:
- `visionAnalyzer.ts` - Prompt et logique AI
- Paramètres GPT-4o (temperature, max_tokens)
- Logique d'estimation

##### 2. scan-refine-morphs - Validation Paramètres

**Avant AI**:
```typescript
// Valider AVANT l'appel à callOpenAIForRefinement()
validateBusinessParams.morphParams(blend_shape_params);
validateBusinessParams.limbMasses(blend_limb_masses);
// Ranges déjà définis dans votre code (0-1)
```

**Ne pas modifier**:
- `openaiClient.ts` - Configuration OpenAI
- `promptBuilder.ts` - Construction du prompt
- Logique K5 envelope

##### 3. meal-analyzer - Validation Nutritionnelle

**Avant AI**:
```typescript
// Valider description textuelle utilisateur
if (userDescription) {
  validateUserInput.textInput(userDescription, 2000);
}

// Valider produits scannés
scanned_products?.forEach(product => {
  validateUserInput.barcode(product.barcode);
  validateUserInput.textInput(product.name, 200);
});
```

**Ne pas modifier**:
- Prompt nutritionnel complexe
- Contexte utilisateur enrichi
- Logique de calcul macros

##### 4. activity-analyzer - Validation Activités

**Avant AI**:
```typescript
// Valider transcription audio
validateUserInput.textInput(transcriptionText, 5000);

// Valider métadonnées
validateBusinessParams.duration(duration_minutes);
validateBusinessParams.intensity(intensity);
```

**Ne pas modifier**:
- Table MET_VALUES
- Prompt d'analyse
- Calcul calories

##### 5. chat-ai - Validation Messages

**Avant AI**:
```typescript
// Valider chaque message utilisateur
messages
  .filter(msg => msg.role === 'user')
  .forEach(msg => {
    validateUserInput.textInput(msg.content, 10000);
    // Sanitize HTML
    // Vérifier injections
  });
```

**Ne pas modifier**:
- System prompts par mode
- Logique de contexte
- Streaming

#### Plan d'Implémentation

**Jour 1** - scan-estimate + scan-refine-morphs:
1. Créer validation images dans `_shared/validation/images.ts`
2. Créer validation morphs dans `_shared/validation/morphs.ts`
3. Intégrer dans scan-estimate (ligne ~44, avant analyzePhotosWithVision)
4. Intégrer dans scan-refine-morphs (ligne ~53, avant callOpenAIForRefinement)
5. Tester: Body scan complet

**Jour 2** - meal-analyzer + activity-analyzer + chat-ai:
1. Créer validation nutrition dans `_shared/validation/nutrition.ts`
2. Créer validation activities dans `_shared/validation/activities.ts`
3. Créer validation chat dans `_shared/validation/chat.ts`
4. Intégrer dans meal-analyzer
5. Intégrer dans activity-analyzer
6. Intégrer dans chat-ai
7. Tester: Meal scan, Activity tracking, Chat AI

---

## Phase 2.3: Activation CSP Strict ⏱️ 0.5 jour

### Pré-requis

✅ Sprint 1 terminé (CSP en report-only)
⏱️ Monitoring de 1-2 semaines en staging
✅ Documentation des violations légitimes

### Plan d'Activation

#### Étape 1: Analyser les Violations (fait en staging)

```bash
# Vérifier les violations CSP dans les logs Netlify
# Identifier les ressources légitimes
# Documenter les exceptions nécessaires
```

#### Étape 2: Mettre à Jour la Politique

**Fichier**: `netlify.toml`

**Changement minimal**:
```toml
# AVANT (Sprint 1)
Content-Security-Policy-Report-Only = """..."""

# APRÈS (Sprint 2)
Content-Security-Policy = """..."""
# Retirer "-Report-Only"
```

**⚠️ Si violations légitimes détectées**:
- Ajouter les domaines nécessaires dans connect-src
- Ajouter les CDN nécessaires dans script-src/style-src
- **Documenter chaque exception**

#### Étape 3: Déploiement Progressif

1. **Staging first**: Activer CSP strict en staging
2. **Monitor 24-48h**: Vérifier aucun blocage
3. **Production**: Activer après validation staging

#### Étape 4: Rollback Plan

Si problèmes en production:
```toml
# Rollback immédiat en report-only
Content-Security-Policy-Report-Only = """..."""
```

---

## Phase 5: Protection CSRF ⏱️ 0.5 jour

### Phase 5.1: Génération Tokens CSRF

#### Objectif
Protéger les opérations critiques contre les attaques CSRF.

#### Opérations à Protéger

**Priority 1 - Critical**:
1. `create-checkout-session` - Paiements Stripe
2. `stripe-webhooks` - Webhooks Stripe
3. `wearable-oauth-callback` - OAuth wearables
4. `scan-commit` - Enregistrement scan body

**Priority 2 - Important**:
5. `meal-analyzer` - Enregistrement repas
6. `activity-analyzer` - Enregistrement activité
7. `fridge-scan-vision` - Scan frigo

#### Implémentation

**Fichier à créer**: `supabase/functions/_shared/csrf/index.ts`

```typescript
/**
 * CSRF Token Management
 * Double-submit cookie pattern
 */

export async function generateCSRFToken(userId: string): Promise<string> {
  const token = crypto.randomUUID();
  const hash = await hashToken(token);

  // Stocker dans Redis/KV store (ou Supabase)
  await storeToken(userId, hash, { expiresIn: '1h' });

  return token;
}

export async function validateCSRFToken(
  userId: string,
  token: string
): Promise<boolean> {
  const hash = await hashToken(token);
  const stored = await getStoredToken(userId);

  if (!stored || stored !== hash) {
    return false;
  }

  // Invalider après utilisation (one-time use)
  await invalidateToken(userId);

  return true;
}

async function hashToken(token: string): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(token);
  const hashBuffer = await crypto.subtle.digest('SHA-256', data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
}
```

#### Migration Supabase pour CSRF

**Fichier**: `supabase/migrations/YYYYMMDDHHMMSS_create_csrf_tokens.sql`

```sql
/*
  # CSRF Token Storage System

  1. New Tables
    - `csrf_tokens`
      - `user_id` (uuid, FK to auth.users)
      - `token_hash` (text, hashed token)
      - `created_at` (timestamptz)
      - `expires_at` (timestamptz)
      - `used` (boolean)

  2. Security
    - Enable RLS
    - Users can only access their own tokens
    - Automatic cleanup of expired tokens
*/

CREATE TABLE IF NOT EXISTS csrf_tokens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  token_hash text NOT NULL,
  created_at timestamptz DEFAULT now(),
  expires_at timestamptz NOT NULL,
  used boolean DEFAULT false,
  CONSTRAINT unique_active_token_per_user UNIQUE (user_id, token_hash)
);

-- Index pour performance
CREATE INDEX idx_csrf_tokens_user_id ON csrf_tokens(user_id);
CREATE INDEX idx_csrf_tokens_expires_at ON csrf_tokens(expires_at);

-- Enable RLS
ALTER TABLE csrf_tokens ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can access own tokens"
  ON csrf_tokens FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "System can manage tokens"
  ON csrf_tokens FOR ALL
  TO service_role
  USING (true);

-- Function to clean expired tokens (run via cron)
CREATE OR REPLACE FUNCTION clean_expired_csrf_tokens()
RETURNS void AS $$
BEGIN
  DELETE FROM csrf_tokens
  WHERE expires_at < now() OR used = true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

#### Intégration dans Edge Functions

**Exemple - create-checkout-session**:

```typescript
import { validateCSRFToken } from '../_shared/csrf/index.ts';

Deno.serve(async (req) => {
  // ... CORS et validation existante ...

  const { user_id, csrf_token } = await req.json();

  // Valider CSRF token
  const isValidCSRF = await validateCSRFToken(user_id, csrf_token);
  if (!isValidCSRF) {
    return new Response(
      JSON.stringify({ error: 'Invalid or expired CSRF token' }),
      {
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    );
  }

  // Continuer avec la logique normale
  // ...
});
```

#### Frontend - Génération Token

**Fichier**: `src/system/services/csrfService.ts`

```typescript
import { supabase } from '../supabase/client';

export async function getCSRFToken(): Promise<string> {
  const { data, error } = await supabase.functions.invoke('generate-csrf-token');

  if (error) throw error;

  return data.csrf_token;
}

// Usage dans un composant
async function handleCheckout() {
  const csrfToken = await getCSRFToken();

  const { data, error } = await supabase.functions.invoke('create-checkout-session', {
    body: {
      user_id: userId,
      csrf_token: csrfToken,
      // ... autres données
    }
  });
}
```

---

## Testing & Non-Regression

### Test Plan

#### Phase 3.1 - Validation System
- [ ] Valider que le système refuse les inputs malformés
- [ ] Valider que les inputs légitimes passent
- [ ] Vérifier aucun impact performance

#### Phase 3.2 - AI Functions
- [ ] **scan-estimate**: Body scan complet (webcam)
- [ ] **scan-refine-morphs**: Raffinement morphologique
- [ ] **meal-analyzer**: Scan repas (photo + barcode)
- [ ] **activity-analyzer**: Tracking activité (audio)
- [ ] **chat-ai**: Conversation dans chaque mode

#### Phase 2.3 - CSP Strict
- [ ] Aucune ressource bloquée en staging
- [ ] 3D rendering fonctionne (Three.js)
- [ ] Webcam/micro accessibles
- [ ] Supabase API calls fonctionnent

#### Phase 5.1 - CSRF Tokens
- [ ] Paiements Stripe fonctionnent
- [ ] OAuth wearables fonctionne
- [ ] Body scan commit fonctionne
- [ ] Tokens invalidés après usage

---

## Métriques de Succès

### Sécurité
- ✅ Validation input sur 100% des Edge Functions critiques
- ✅ CSP strict activé sans régression
- ✅ CSRF protection sur opérations critiques
- ✅ Aucune vulnérabilité injection détectée

### Qualité
- ✅ Zero régression sur AI agents
- ✅ Prompts AI inchangés
- ✅ Modèles AI inchangés
- ✅ Paramètres AI inchangés

### Performance
- ⏱️ Validation input < 50ms overhead
- ⏱️ CSRF validation < 100ms overhead
- ✅ Aucun impact sur temps de réponse AI

---

## Risques & Mitigations

### Risque 1: Casser les AI Agents 🔴 HIGH

**Mitigation**:
- ✅ Ne toucher QUE la validation des inputs
- ✅ Tests exhaustifs avant/après
- ✅ Rollback immédiat si problème
- ✅ Documentation des changements

### Risque 2: CSP Bloque Ressources Légitimes 🟡 MEDIUM

**Mitigation**:
- ✅ Monitoring 1-2 semaines en report-only
- ✅ Documentation des exceptions
- ✅ Staging first
- ✅ Rollback plan

### Risque 3: CSRF Tokens Bloquent Utilisateurs 🟡 MEDIUM

**Mitigation**:
- ✅ Expiration généreuse (1h)
- ✅ Messages d'erreur clairs
- ✅ Retry automatique
- ✅ Fallback si échec

---

## Fichiers à Créer

### Validation System
- `supabase/functions/_shared/validation/index.ts`
- `supabase/functions/_shared/validation/schemas.ts`
- `supabase/functions/_shared/validation/sanitizers.ts`
- `supabase/functions/_shared/validation/images.ts`
- `supabase/functions/_shared/validation/morphs.ts`
- `supabase/functions/_shared/validation/nutrition.ts`
- `supabase/functions/_shared/validation/activities.ts`
- `supabase/functions/_shared/validation/chat.ts`

### CSRF System
- `supabase/functions/_shared/csrf/index.ts`
- `supabase/functions/generate-csrf-token/index.ts`
- `supabase/migrations/YYYYMMDDHHMMSS_create_csrf_tokens.sql`
- `src/system/services/csrfService.ts`

### Documentation
- `SECURITY_INPUT_VALIDATION.md`
- `SECURITY_CSRF.md`
- `SPRINT_2_SUMMARY.md`

---

## Fichiers à Modifier

### CSP Enforcement
- `netlify.toml` (retirer -Report-Only)

### Edge Functions avec Validation
- `supabase/functions/scan-estimate/index.ts`
- `supabase/functions/scan-refine-morphs/index.ts`
- `supabase/functions/meal-analyzer/index.ts`
- `supabase/functions/activity-analyzer/index.ts`
- `supabase/functions/chat-ai/index.ts`

### Edge Functions avec CSRF
- `supabase/functions/create-checkout-session/index.ts`
- `supabase/functions/stripe-webhooks/index.ts`
- `supabase/functions/wearable-oauth-callback/index.ts`
- `supabase/functions/scan-commit/index.ts`

---

## Planning Détaillé

### Jour 1: Système de Validation + scan-* functions
- **Matin**: Créer système validation unifié
- **Après-midi**: Intégrer scan-estimate + scan-refine-morphs
- **Soir**: Tests body scan

### Jour 2: meal-analyzer + activity-analyzer + chat-ai
- **Matin**: Intégrer meal-analyzer + activity-analyzer
- **Après-midi**: Intégrer chat-ai
- **Soir**: Tests complets AI functions

### Jour 3: CSP Strict + CSRF (Jour 1)
- **Matin**: Analyser violations CSP staging
- **Après-midi**: Activer CSP strict staging
- **Soir**: Créer système CSRF + migration

### Jour 4: CSRF (Jour 2) + Tests finaux
- **Matin**: Intégrer CSRF dans 7 fonctions critiques
- **Après-midi**: Tests non-régression complets
- **Soir**: Documentation finale

---

## Questions Avant de Commencer

1. ✅ Avez-vous des réglages AI spécifiques à documenter ?
2. ✅ Faut-il monitorer le CSP plus longtemps ?
3. ✅ Quelles Edge Functions utiliser en priorité pour CSRF ?
4. ✅ Préférence pour stockage CSRF (Supabase vs Redis) ?

---

## Prêt à Démarrer ?

Une fois validé, on démarre par la Phase 3.1 : Système de Validation Unifié.

**Next Action**: Créer `supabase/functions/_shared/validation/index.ts`
