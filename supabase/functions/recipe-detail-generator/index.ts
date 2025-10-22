import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const openaiApiKey = Deno.env.get('OPENAI_API_KEY')
const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

interface RecipeDetailRequest {
  user_id: string
  meal_title: string
  main_ingredients: string[]
  user_preferences: {
    identity?: any
    nutrition?: any
    kitchen_equipment?: any
    food_preferences?: any
    sensory_preferences?: any
  }
  meal_type: 'breakfast' | 'lunch' | 'dinner' | 'snack'
  target_calories?: number
}

interface DetailedRecipe {
  id: string
  title: string
  description: string
  ingredients: Array<{
    name: string
    quantity: string
    unit: string
  }>
  instructions: string[]
  prepTimeMin: number
  cookTimeMin: number
  servings: number
  nutritionalInfo: {
    kcal: number
    protein: number
    carbs: number
    fat: number
    fiber: number
  }
  dietaryTags: string[]
  difficulty: 'facile' | 'moyen' | 'difficile'
  tips: string[]
  variations: string[]
  imageSignature?: string
}

// Generate cache key for recipe detail
function generateCacheKey(request: RecipeDetailRequest): string {
  const version = 'recipe_detail_v1'
  const keyData = {
    user_id: request.user_id,
    meal_title: request.meal_title,
    main_ingredients: request.main_ingredients,
    preferences: request.user_preferences,
    meal_type: request.meal_type,
    version
  }
  
  const encoder = new TextEncoder()
  const data = encoder.encode(JSON.stringify(keyData))
  return crypto.subtle.digest('SHA-256', data).then(hashBuffer => {
    const hashArray = Array.from(new Uint8Array(hashBuffer))
    return hashArray.map(b => b.toString(16).padStart(2, '0')).join('')
  })
}

// Calculate cost for GPT-5-mini
function calculateCost(inputTokens: number, outputTokens: number): number {
  const inputCostPer1M = 0.25 // $0.25 per 1M input tokens
  const outputCostPer1M = 2.00 // $2.00 per 1M output tokens for gpt-5-mini

  return (inputTokens / 1000000 * inputCostPer1M) + (outputTokens / 1000000 * outputCostPer1M)
}

// Generate detailed recipe using GPT-5-mini
async function generateDetailedRecipe(request: RecipeDetailRequest): Promise<DetailedRecipe> {
  // Ensure meal title is not undefined
  const mealTitle = request.meal_title && request.meal_title !== 'undefined' 
    ? request.meal_title 
    : 'Repas personnalisé'

  // Ensure mealTitle is always valid
  const safeMealTitle = mealTitle || 'Repas sans nom';

  const mealTypeContext = {
    breakfast: 'petit-déjeuner énergisant',
    lunch: 'déjeuner équilibré',
    dinner: 'dîner satisfaisant',
    snack: 'collation saine'
  }

  const prompt = `Tu es un chef cuisinier expert spécialisé dans les recettes détaillées et personnalisées.

CONTEXTE:
- Repas à détailler: "${mealTitle}"
- Type de repas: ${mealTypeContext[request.meal_type]}
- Ingrédients principaux: ${(request.main_ingredients || []).join(', ')}
- Calories cibles: ${request.target_calories || 'non spécifié'}
- Préférences utilisateur: ${JSON.stringify(request.user_preferences)}

MISSION:
Crée une recette complète et détaillée pour ce repas.

CONTRAINTES:
- Utilise les ingrédients principaux fournis
- Respecte les préférences et restrictions alimentaires
- Propose des instructions claires et précises
- Inclus des conseils pratiques et des variations
- Adapte la difficulté selon l'équipement disponible

FORMAT DE RÉPONSE (JSON strict):
{
  "id": "${crypto.randomUUID()}",
  "title": "${mealTitle}",
  "description": "Description appétissante et détaillée du plat (150-200 caractères)",
  "ingredients": [
    {
      "name": "nom de l'ingrédient",
      "quantity": "quantité",
      "unit": "unité (g, ml, pièce, etc.)"
    }
  ],
  "instructions": [
    "Étape 1: instruction détaillée",
    "Étape 2: instruction détaillée",
    "..."
  ],
  "prepTimeMin": 15,
  "cookTimeMin": 20,
  "servings": 2,
  "nutritionalInfo": {
    "kcal": 450,
    "protein": 25,
    "carbs": 35,
    "fat": 18,
    "fiber": 8
  },
  "dietaryTags": ["riche en protéines", "sans gluten", "végétarien"],
  "difficulty": "facile",
  "tips": [
    "Conseil pratique 1",
    "Conseil pratique 2"
  ],
  "variations": [
    "Variation possible 1",
    "Variation possible 2"
  ]
}

IMPORTANT: Réponds UNIQUEMENT avec le JSON, sans texte additionnel.`

  const requestBody = {
    model: 'gpt-5-mini',
    messages: [
      {
        role: 'system',
        content: 'Tu es un chef cuisinier expert. Tu réponds toujours avec du JSON valide uniquement.'
      },
      {
        role: 'user',
        content: prompt
      }
    ],
    max_completion_tokens: 2000
  };

  console.log('📤 Sending request to OpenAI:', {
    model: requestBody.model,
    max_completion_tokens: requestBody.max_completion_tokens,
    messages_count: requestBody.messages.length
  });

  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${openaiApiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(requestBody),
  })

  if (!response.ok) {
    const errorBody = await response.text();
    console.error('❌ OpenAI API error details:', {
      status: response.status,
      statusText: response.statusText,
      errorBody,
      requestBody: {
        model: requestBody.model,
        max_completion_tokens: requestBody.max_completion_tokens
      }
    });
    throw new Error(`OpenAI API error (gpt-5-mini): ${response.status} - ${errorBody}`)
  }

  const data = await response.json()
  const content = data.choices[0].message.content

  try {
    // Extract JSON from the response, handling potential markdown or extra text
    let jsonString = content.trim()
    
    // Find the first { and last } to extract JSON
    const firstBrace = jsonString.indexOf('{')
    const lastBrace = jsonString.lastIndexOf('}')
    
    if (firstBrace !== -1 && lastBrace !== -1 && lastBrace > firstBrace) {
      jsonString = jsonString.substring(firstBrace, lastBrace + 1)
    }
    
    const recipe = JSON.parse(jsonString) as DetailedRecipe
    
    // Generate stable image signature
    const canonicalPayload = JSON.stringify({
      title: recipe.title,
      ingredients: recipe.ingredients
        .map(ing => ing.name)
        .sort()
        .join(',')
    });
    
    const encoder = new TextEncoder();
    const data = encoder.encode(canonicalPayload);
    const hashBuffer = await crypto.subtle.digest('SHA-256', data);
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    recipe.imageSignature = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
    
    return recipe
  } catch (error) {
    console.error('Failed to parse GPT-5-mini response:', { content, error: error.message })
    throw new Error('Invalid JSON response from GPT-5-mini')
  }
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders })
  }

  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405, headers: corsHeaders })
  }

  try {
    const supabase = createClient(supabaseUrl, supabaseServiceKey)
    const request: RecipeDetailRequest = await req.json()

    // Generate cache key
    const cacheKey = await generateCacheKey(request)

    // Check cache first
    const { data: cachedJob } = await supabase
      .from('ai_analysis_jobs')
      .select('*')
      .eq('input_hash', cacheKey)
      .eq('analysis_type', 'recipe_detail_generation')
      .eq('status', 'completed')
      .single()

    if (cachedJob?.result_payload) {
      console.log('Using cached detailed recipe')
      return new Response(JSON.stringify({
        recipe: cachedJob.result_payload,
        cached: true,
        model_used: 'gpt-5-mini'
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // Generate detailed recipe with AI
    console.log('Generating detailed recipe with GPT-5-mini for:', request.meal_title)
    const recipe = await generateDetailedRecipe(request)

    // Calculate cost (mock usage for now, would need actual token count)
    const estimatedInputTokens = 800
    const estimatedOutputTokens = 600
    const cost = calculateCost(estimatedInputTokens, estimatedOutputTokens)

    // Save to cache
    const { error: jobError } = await supabase
      .from('ai_analysis_jobs')
      .insert({
        user_id: request.user_id,
        analysis_type: 'recipe_detail_generation',
        status: 'completed',
        request_payload: request,
        result_payload: recipe,
        input_hash: cacheKey
      })

    if (jobError) {
      console.error('Failed to save recipe detail job:', jobError)
    }

    return new Response(JSON.stringify({
      recipe,
      cached: false,
      model_used: 'gpt-5-mini',
      cost_usd: cost
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })

  } catch (error) {
    console.error('Recipe detail generation error:', error)
    return new Response(
      JSON.stringify({ error: error.message || 'Internal server error' }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
})