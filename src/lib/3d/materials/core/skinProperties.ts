/**
 * Skin Properties
 * Defines and applies realistic skin material properties
 */

import * as THREE from 'three';
import { type SkinToneV2 } from '../../../scan/normalizeSkinTone';
import logger from '../../../utils/logger';

interface SkinMaterialProperties {
  // Base color (linear space)
  baseColor: { r: number; g: number; b: number };
  
  // PBR properties
  metalness: number;
  roughness: number;
  
  // Subsurface Scattering (SSS)
  transmission: number;
  thickness: number;
  ior: number;
  attenuationDistance: number;
  attenuationColor: { r: number; g: number; b: number };
  
  // Surface properties
  sheen: number;
  sheenRoughness: number;
  clearcoat: number;
  clearcoatRoughness: number;
  
  // Advanced properties
  specularIntensity: number;
  iridescence: number;
  iridescenceIOR: number;
}

/**
 * Calculate optimal skin properties based on skin tone with AI metadata
 */
export function calculateSkinProperties(skinTone: SkinToneV2): SkinMaterialProperties {
  const { linear_f32 } = skinTone;

  // Calculate luminance for adaptive properties
  const luminance = linear_f32.r * 0.299 + linear_f32.g * 0.587 + linear_f32.b * 0.114;

  // Adaptive properties based on skin tone luminance
  const isDarkSkin = luminance < 0.3;
  const isLightSkin = luminance > 0.7;
  const isVeryLightSkin = luminance > 0.75; // NEW: Category for very pale/white skin

  // ENHANCED: Use AI metadata for contextual SSS optimization
  const undertone = (skinTone as any).undertone || 'neutral';
  const ethnicityHint = (skinTone as any).ethnicity_hint || 'unknown';

  logger.info('SKIN_PROPERTIES', 'AI metadata detected for contextual rendering', {
    undertone,
    ethnicityHint,
    luminance: luminance.toFixed(3),
    source: skinTone.source,
    philosophy: 'ai_contextual_sss_optimization'
  });
  
  // ENHANCED: Industry-standard SSS values for photo-realistic skin
  // Based on GPU Gems 3 and modern PBR workflows (ReadyPlayerMe/Morph3D standards)
  // Transmission values: 0.25-0.55 for realistic subsurface scattering
  let transmission = 0.35;  // INCREASED: Industry standard for medium skin
  let thickness = 0.30;     // INCREASED: Realistic skin thickness
  let roughness = 0.55;
  let sheen = 0.3;          // INCREASED: More realistic surface sheen
  let clearcoat = 0.25;     // INCREASED: Oil layer representation

  // Adjust for dark skin (more absorption, less transmission)
  if (isDarkSkin) {
    transmission = 0.25;   // INCREASED: Realistic dark skin SSS
    thickness = 0.20;      // INCREASED: More depth for realism
    roughness = 0.45;      // Smoother for realistic dark skin
    sheen = 0.35;          // More natural oils on dark skin
    clearcoat = 0.3;       // Pronounced oil layer
  }

  // CRITICAL FIX: Very light/white skin - minimal SSS to preserve exact color
  // High transmission was causing light to pass through skin and darken it (bronze effect)
  if (isVeryLightSkin) {
    transmission = 0.05;   // DRASTICALLY REDUCED: Minimal SSS for color preservation
    thickness = 0.08;      // DRASTICALLY REDUCED: Very thin SSS layer
    roughness = 0.65;      // More visible texture on very light skin
    sheen = 0.20;          // Subtle sheen to avoid darkening
    clearcoat = 0.12;      // Minimal clearcoat to preserve brightness
  }
  // Adjust for light skin (moderate transmission, reduced from previous)
  else if (isLightSkin) {
    transmission = 0.12;   // REDUCED from 0.45: Minimal SSS for light skin color preservation
    thickness = 0.15;      // REDUCED from 0.40: Thinner layer to avoid darkening
    roughness = 0.65;      // More visible texture on light skin
    sheen = 0.22;          // Subtle sheen
    clearcoat = 0.15;      // REDUCED from 0.2: Less oil layer to preserve brightness
  }
  
  // ENHANCED: AI-guided attenuation color based on undertone
  // Attenuation color controls the color of light passing through skin
  let attenuationR: number;
  let attenuationG: number;
  let attenuationB: number;

  // CRITICAL FIX: For very light/white skin, use EXACT base color for attenuation
  // This prevents the warm/reddish tint from darkening/bronzing the skin
  if (isVeryLightSkin) {
    // Use base color with 99% preservation, 1% slight warm bias for realism
    attenuationR = Math.min(1.0, linear_f32.r * 0.99 + 0.01);
    attenuationG = Math.min(1.0, linear_f32.g * 0.99 + 0.01);
    attenuationB = Math.min(1.0, linear_f32.b * 0.99 + 0.01);
  }
  // CRITICAL FIX: For light skin, significantly reduce amplification to preserve color
  else if (isLightSkin) {
    // Reduced amplification from 1.4/1.2/1.0 to 1.05/1.03/1.02 to avoid bronzing
    attenuationR = Math.min(1.0, linear_f32.r * 1.05 + 0.03);
    attenuationG = Math.min(1.0, linear_f32.g * 1.03 + 0.02);
    attenuationB = Math.min(1.0, linear_f32.b * 1.02 + 0.01);
  }
  // Medium/dark skin - original enhanced attenuation for realistic SSS
  else {
    attenuationR = Math.min(1.0, linear_f32.r * 1.4 + 0.15);
    attenuationG = Math.min(1.0, linear_f32.g * 1.2 + 0.10);
    attenuationB = Math.min(1.0, linear_f32.b * 1.0 + 0.05);
  }

  // Adjust for undertone (warm/cool/neutral) - skip for very light skin to preserve color
  if (!isVeryLightSkin) {
    if (undertone === 'warm') {
      // Warm undertone: more red-orange subsurface scatter
      attenuationR = Math.min(1.0, attenuationR * 1.1);
      attenuationG = Math.min(1.0, attenuationG * 0.95);
    } else if (undertone === 'cool') {
      // Cool undertone: more pink-blue subsurface scatter
      attenuationR = Math.min(1.0, attenuationR * 0.95);
      attenuationB = Math.min(1.0, attenuationB * 1.1);
    }
  }
  
  const properties: SkinMaterialProperties = {
    baseColor: linear_f32,
    metalness: 0.0,
    roughness,
    transmission,
    thickness,
    ior: 1.35,
    attenuationDistance: 0.5,
    attenuationColor: { r: attenuationR, g: attenuationG, b: attenuationB },
    sheen,
    sheenRoughness: 0.4,
    clearcoat,
    clearcoatRoughness: 0.4,
    specularIntensity: 0.8,
    iridescence: 0.05,
    iridescenceIOR: 1.3
  };
  
  logger.info('SKIN_PROPERTIES', 'Calculated adaptive skin properties', {
    skinToneHex: skinTone.hex,
    luminance: luminance.toFixed(3),
    skinCategory: isVeryLightSkin ? 'very_light' : isDarkSkin ? 'dark' : isLightSkin ? 'light' : 'medium',
    colorPreservationMode: isVeryLightSkin ? 'ACTIVE_MAX' : isLightSkin ? 'ACTIVE' : 'DISABLED',
    adaptiveProperties: {
      transmission,
      thickness,
      roughness,
      sheen,
      clearcoat
    },
    attenuationColor: `rgb(${attenuationR.toFixed(3)}, ${attenuationG.toFixed(3)}, ${attenuationB.toFixed(3)})`,
    baseSkinColor: `rgb(${linear_f32.r.toFixed(3)}, ${linear_f32.g.toFixed(3)}, ${linear_f32.b.toFixed(3)})`,
    attenuationVsBase: {
      rDelta: (attenuationR - linear_f32.r).toFixed(3),
      gDelta: (attenuationG - linear_f32.g).toFixed(3),
      bDelta: (attenuationB - linear_f32.b).toFixed(3)
    },
    philosophy: 'adaptive_skin_properties_with_color_preservation'
  });
  
  return properties;
}

/**
 * Apply skin properties to a Three.js material
 */
export function applySkinPropertiesToMaterial(
  material: THREE.Material,
  properties: SkinMaterialProperties,
  materialName: string
): boolean {
  try {
    const mat = material as any;
    
    // CRITICAL FIX: Ensure color property is valid before proceeding
    if (!mat.color || !(mat.color instanceof THREE.Color)) {
      logger.warn('SKIN_PROPERTIES', 'Material missing valid color property, initializing', {
        materialName,
        hasColorProperty: 'color' in mat,
        colorType: typeof mat.color,
        colorConstructor: mat.color ? mat.color.constructor.name : 'undefined',
        philosophy: 'color_property_emergency_fix'
      });
      
      // Initialize with default skin color
      mat.color = new THREE.Color(0.8, 0.6, 0.4);
      mat.needsUpdate = true;
    }
    
    // Store original properties for comparison
    const originalProperties = {
      color: mat.color ? {
        r: mat.color.r.toFixed(6),
        g: mat.color.g.toFixed(6),
        b: mat.color.b.toFixed(6),
        hex: '#' + mat.color.getHexString()
      } : null,
      metalness: mat.metalness,
      roughness: mat.roughness,
      transmission: mat.transmission,
      thickness: mat.thickness,
      ior: mat.ior,
      sheen: mat.sheen,
      clearcoat: mat.clearcoat
    };
    
    // ENHANCED: Comprehensive pre-modification audit
    logger.info('SKIN_PROPERTIES', 'BEFORE: Material properties comprehensive audit', {
      materialName,
      materialType: material.type,
      materialConstructor: material.constructor.name,
      originalProperties,
      // ENHANCED: Material type analysis
      materialTypeAnalysis: {
        isMeshStandardMaterial: material instanceof THREE.MeshStandardMaterial,
        isMeshPhysicalMaterial: material instanceof THREE.MeshPhysicalMaterial,
        supportsSSS: material instanceof THREE.MeshPhysicalMaterial,
        supportsPBR: material instanceof THREE.MeshStandardMaterial || material instanceof THREE.MeshPhysicalMaterial
      },
      // ENHANCED: Properties availability check
      propertiesAvailability: {
        hasColorProperty: 'color' in mat && mat.color instanceof THREE.Color,
        hasMetalnessProperty: 'metalness' in mat,
        hasRoughnessProperty: 'roughness' in mat,
        hasTransmissionProperty: 'transmission' in mat,
        hasThicknessProperty: 'thickness' in mat,
        hasIorProperty: 'ior' in mat,
        hasAttenuationColorProperty: 'attenuationColor' in mat,
        hasAttenuationDistanceProperty: 'attenuationDistance' in mat,
        hasSheenProperty: 'sheen' in mat,
        hasSheenColorProperty: 'sheenColor' in mat,
        hasClearcoatProperty: 'clearcoat' in mat
      },
      philosophy: 'pre_modification_audit'
    });
    
    // Apply base color
    logger.info('SKIN_PROPERTIES_APPLY', 'CRITICAL: Applying base color to material - BEFORE APPLICATION', {
      materialName,
      materialType: material.type,
      materialConstructor: material.constructor.name,
      targetColorRGB: {
        r: properties.baseColor.r.toFixed(6),
        g: properties.baseColor.g.toFixed(6),
        b: properties.baseColor.b.toFixed(6)
      },
      targetColorHex: `#${Math.round(properties.baseColor.r * 255).toString(16).padStart(2, '0')}${Math.round(properties.baseColor.g * 255).toString(16).padStart(2, '0')}${Math.round(properties.baseColor.b * 255).toString(16).padStart(2, '0')}`,
      currentMaterialColor: mat.color ? {
        r: mat.color.r.toFixed(6),
        g: mat.color.g.toFixed(6),
        b: mat.color.b.toFixed(6),
        hex: '#' + mat.color.getHexString()
      } : 'NO_COLOR_PROPERTY',
      philosophy: 'critical_color_application_before'
    });
    mat.color.setRGB(properties.baseColor.r, properties.baseColor.g, properties.baseColor.b);
    
    // CRITICAL: Log color AFTER application to verify it was applied correctly
    logger.info('SKIN_PROPERTIES_APPLY', 'CRITICAL: Base color applied to material - AFTER APPLICATION', {
      materialName,
      appliedColorRGB: {
        r: mat.color.r.toFixed(6),
        g: mat.color.g.toFixed(6),
        b: mat.color.b.toFixed(6)
      },
      appliedColorHex: '#' + mat.color.getHexString(),
      colorApplicationSuccess: Math.abs(mat.color.r - properties.baseColor.r) < 0.01 &&
                              Math.abs(mat.color.g - properties.baseColor.g) < 0.01 &&
                              Math.abs(mat.color.b - properties.baseColor.b) < 0.01,
      colorDelta: {
        r: Math.abs(mat.color.r - properties.baseColor.r).toFixed(6),
        g: Math.abs(mat.color.g - properties.baseColor.g).toFixed(6),
        b: Math.abs(mat.color.b - properties.baseColor.b).toFixed(6)
      },
      philosophy: 'critical_color_application_after'
    });
    
    // Remove base color texture to let color show through
    if (mat.map) {
      // ENHANCED: Texture removal logging
      logger.info('SKIN_PROPERTIES', 'Removing base color texture - detailed', {
        materialName,
        textureRemoved: !!mat.map,
        textureName: mat.map.name || 'unnamed',
        textureUuid: mat.map.uuid || 'no-uuid',
        textureFormat: mat.map.format || 'unknown',
        textureType: mat.map.type || 'unknown',
        reason: 'allow_solid_color_to_show_through'
      });
      mat.map = null;
    }
    
    // Apply basic PBR properties
    mat.metalness = properties.metalness;
    mat.roughness = properties.roughness;
    
    // Apply advanced properties for MeshPhysicalMaterial
    if (material instanceof THREE.MeshPhysicalMaterial) {
      // ENHANCED: SSS properties application logging
      logger.info('SKIN_PROPERTIES', 'Applying advanced SSS properties - comprehensive', {
        materialName,
        materialType: material.type,
        materialConstructor: material.constructor.name,
        // ENHANCED: SSS properties being applied
        sssPropertiesBeingApplied: {
          transmission: properties.transmission,
          thickness: properties.thickness,
          ior: properties.ior,
          attenuationDistance: properties.attenuationDistance,
          attenuationColor: {
            r: properties.attenuationColor.r.toFixed(3),
            g: properties.attenuationColor.g.toFixed(3),
            b: properties.attenuationColor.b.toFixed(3)
          },
          sheen: properties.sheen,
          sheenRoughness: properties.sheenRoughness,
          clearcoat: properties.clearcoat,
          clearcoatRoughness: properties.clearcoatRoughness,
          specularIntensity: properties.specularIntensity,
          iridescence: properties.iridescence,
          iridescenceIOR: properties.iridescenceIOR
        },
        philosophy: 'advanced_sss_application'
      });
      
      // Subsurface Scattering
      mat.transmission = properties.transmission;
      mat.thickness = properties.thickness;
      mat.ior = properties.ior;
      mat.attenuationDistance = properties.attenuationDistance;
      mat.attenuationColor = new THREE.Color(
        properties.attenuationColor.r,
        properties.attenuationColor.g,
        properties.attenuationColor.b
      );
      
      // Surface properties
      mat.sheen = properties.sheen;
      mat.sheenRoughness = properties.sheenRoughness;
      mat.clearcoat = properties.clearcoat;
      mat.clearcoatRoughness = properties.clearcoatRoughness;
      mat.specularIntensity = properties.specularIntensity;
      mat.iridescence = properties.iridescence;
      mat.iridescenceIOR = properties.iridescenceIOR;
      
      // Set sheen color to match skin tone
      if (mat.sheenColor) {
        const sheenR = Math.min(1.0, properties.baseColor.r * 1.05);
        const sheenG = Math.min(1.0, properties.baseColor.g * 1.02);
        const sheenB = Math.min(1.0, properties.baseColor.b * 0.98);
        mat.sheenColor.setRGB(sheenR, sheenG, sheenB);
        
        logger.debug('SKIN_PROPERTIES', 'Sheen color applied', {
          materialName,
          sheenColor: {
            r: sheenR.toFixed(3),
            g: sheenG.toFixed(3),
            b: sheenB.toFixed(3),
            hex: '#' + mat.sheenColor.getHexString()
          }
        });
      }
       
       // CRITICAL: Force enable subsurface if it's disabled
       if (mat.subsurface !== undefined && mat.subsurface === 0) {
         mat.subsurface = 0.1; // Enable subsurface scattering
         logger.info('SKIN_PROPERTIES', 'CRITICAL FIX: Enabled subsurface scattering', {
           materialName,
           subsurfaceValue: mat.subsurface,
           reason: 'subsurface_was_disabled_in_model',
           philosophy: 'subsurface_activation_fix'
         });
       }
    } else {
      // ENHANCED: Log when SSS properties cannot be applied
      logger.warn('SKIN_PROPERTIES', 'SSS properties NOT applied - material type limitation', {
        materialName,
        materialType: material.type,
        materialConstructor: material.constructor.name,
        isMeshStandardMaterial: material instanceof THREE.MeshStandardMaterial,
        isMeshPhysicalMaterial: material instanceof THREE.MeshPhysicalMaterial,
        sssLimitation: 'Only MeshPhysicalMaterial supports SSS properties',
        appliedPropertiesOnly: ['color', 'metalness', 'roughness'],
        missingSSSProperties: ['transmission', 'thickness', 'ior', 'attenuationColor', 'sheen', 'clearcoat'],
        recommendedAction: 'Material should be upgraded to MeshPhysicalMaterial',
        philosophy: 'sss_limitation_material_type'
      });
    }
    
    // Force material update
    mat.needsUpdate = true;
    
    // Verify color was applied correctly
    const colorApplied = 
      Math.abs(mat.color.r - properties.baseColor.r) < 0.01 &&
      Math.abs(mat.color.g - properties.baseColor.g) < 0.01 &&
      Math.abs(mat.color.b - properties.baseColor.b) < 0.01;
    
    // Log final state
    const finalProperties = {
      color: {
        r: mat.color.r.toFixed(6),
        g: mat.color.g.toFixed(6),
        b: mat.color.b.toFixed(6),
        hex: '#' + mat.color.getHexString()
      },
      metalness: mat.metalness,
      roughness: mat.roughness,
      transmission: mat.transmission,
      thickness: mat.thickness,
      ior: mat.ior,
      sheen: mat.sheen,
      clearcoat: mat.clearcoat,
      attenuationColor: mat.attenuationColor ? {
        r: mat.attenuationColor.r.toFixed(3),
        g: mat.attenuationColor.g.toFixed(3),
        b: mat.attenuationColor.b.toFixed(3),
        hex: '#' + mat.attenuationColor.getHexString()
      } : null,
      subsurface: mat.subsurface || 'undefined',
      needsUpdate: mat.needsUpdate
    };
    
    // ENHANCED: Comprehensive post-modification audit
    logger.info('SKIN_PROPERTIES', 'AFTER: Material properties comprehensive audit', {
      materialName,
      materialType: material.type,
      materialConstructor: material.constructor.name,
      finalProperties,
      colorApplicationSuccess: colorApplied,
      propertiesChanged: JSON.stringify(originalProperties) !== JSON.stringify(finalProperties),
      // ENHANCED: Application success analysis
      applicationSuccessAnalysis: {
        colorAppliedCorrectly: colorApplied,
        expectedColor: {
          r: properties.baseColor.r.toFixed(6),
          g: properties.baseColor.g.toFixed(6),
          b: properties.baseColor.b.toFixed(6)
        },
        actualColor: {
          r: mat.color.r.toFixed(6),
          g: mat.color.g.toFixed(6),
          b: mat.color.b.toFixed(6)
        },
        colorDelta: {
          r: Math.abs(mat.color.r - properties.baseColor.r).toFixed(6),
          g: Math.abs(mat.color.g - properties.baseColor.g).toFixed(6),
          b: Math.abs(mat.color.b - properties.baseColor.b).toFixed(6)
        },
        sssPropertiesApplied: material instanceof THREE.MeshPhysicalMaterial,
        subsurfaceEnabled: mat.subsurface > 0,
        materialUpdateForced: mat.needsUpdate,
        baseTextureRemoved: !mat.map
      },
      // ENHANCED: Rendering impact prediction
      renderingImpactPrediction: {
        willRenderWithSSS: material instanceof THREE.MeshPhysicalMaterial && mat.transmission > 0,
        willRenderWithSheen: material instanceof THREE.MeshPhysicalMaterial && mat.sheen > 0,
        willRenderWithClearcoat: material instanceof THREE.MeshPhysicalMaterial && mat.clearcoat > 0,
        willRenderWithSubsurface: material instanceof THREE.MeshPhysicalMaterial && (mat.subsurface || 0) > 0,
        expectedVisualResult: material instanceof THREE.MeshPhysicalMaterial ? 
          'realistic_skin_with_sss' : 'basic_pbr_skin_without_sss'
      },
      philosophy: 'post_modification_audit'
    });
    
    return colorApplied;
    
  } catch (error) {
    // ENHANCED: Comprehensive error logging
    logger.error('SKIN_PROPERTIES', 'CRITICAL ERROR applying skin properties - Complete Diagnostic', {
      materialName,
      materialType: material.type,
      materialConstructor: material.constructor.name,
      error: error instanceof Error ? error.message : 'Unknown error',
      stack: error instanceof Error ? error.stack : undefined,
      // ENHANCED: Error context analysis
      errorContext: {
        materialWasValid: !!(material && material.type),
        propertiesWereValid: !!(properties && properties.baseColor),
        materialNameWasValid: typeof materialName === 'string',
        errorOccurredAt: 'skin_properties_application',
        materialState: material ? {
          name: material.name,
          type: material.type,
          uuid: material.uuid,
          hasColor: 'color' in material,
          constructor: material.constructor.name
        } : null,
        propertiesState: properties ? {
          hasBaseColor: !!(properties.baseColor),
          baseColorValid: !!(properties.baseColor && 
            typeof properties.baseColor.r === 'number' && 
            typeof properties.baseColor.g === 'number' && 
            typeof properties.baseColor.b === 'number'),
          hasTransmission: typeof properties.transmission === 'number',
          hasThickness: typeof properties.thickness === 'number'
        } : null
      },
      philosophy: 'skin_properties_application_error'
    });
    return false;
  }
}

