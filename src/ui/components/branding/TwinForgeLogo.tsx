import React from 'react';
import ForgeHammerIcon from '../../icons/ForgeHammerIcon';
import { usePerformanceMode } from '../../../system/context/PerformanceModeContext';

interface TwinForgeLogoProps {
  variant?: 'desktop' | 'mobile';
  isHovered?: boolean;
  className?: string;
}

export const TwinForgeLogo: React.FC<TwinForgeLogoProps> = ({
  variant = 'desktop',
  isHovered = false,
  className = ''
}) => {
  const isDesktop = variant === 'desktop';
  const { mode } = usePerformanceMode();

  // Use simplified gradient in high-performance mode for better compatibility
  const isHighPerformance = mode === 'high-performance';

  // Simplified 2-color gradient for ultra performance mode
  const gradientStyle = isHighPerformance
    ? 'linear-gradient(135deg, #FF6B35 0%, #FDC830 100%)'
    : 'linear-gradient(135deg, #FF6B35 0%, #F7931E 50%, #FDC830 100%)';

  // Fallback solid color for maximum compatibility
  const fallbackColor = '#FF8C42';

  if (isDesktop) {
    return (
      <div
        className={`flex items-center ${className}`}
        style={{
          transition: 'none',
          height: '100%'
        }}
      >
        <div style={{ display: 'inline-flex', alignItems: 'baseline', gap: '0' }}>
          <span
            style={{
              fontFamily: "'Montserrat', sans-serif",
              fontSize: '25px',
              fontWeight: 800,
              letterSpacing: '1.2px',
              color: '#E5E7EB',
              lineHeight: 1,
              textTransform: 'uppercase',
              filter: 'none',
              transition: 'none'
            }}
          >
            TWIN
          </span>
          {/* Gradient statique pour tous les modes - sans animation */}
          <span
            style={{
              fontFamily: "'Montserrat', sans-serif",
              fontSize: '25px',
              fontWeight: 800,
              letterSpacing: '1.2px',
              color: fallbackColor,
              background: gradientStyle,
              WebkitBackgroundClip: 'text',
              WebkitTextFillColor: 'transparent',
              backgroundClip: 'text',
              lineHeight: 1,
              textTransform: 'uppercase',
              filter: 'none',
              transition: 'none'
            }}
          >
            FØRGE
          </span>
        </div>
      </div>
    );
  }

  return (
    <div
      className={`flex items-center ${className}`}
      style={{
        transition: 'none',
        gap: '8px',
        position: 'relative'
      }}
    >
      <div style={{
        position: 'relative',
        display: 'flex',
        alignItems: 'center'
      }}>
        <ForgeHammerIcon
          width={42}
          height={50}
          isHovered={isHovered}
        />
      </div>

      <div style={{
        display: 'flex',
        flexDirection: 'column',
        gap: '2px',
        alignItems: 'flex-start',
        justifyContent: 'center',
        transform: 'translateY(2px)'
      }}>
        <span
          style={{
            fontFamily: "'Montserrat', sans-serif",
            fontSize: '15px',
            fontWeight: 800,
            letterSpacing: '0.8px',
            color: '#E5E7EB',
            lineHeight: 1,
            textTransform: 'uppercase',
            filter: 'none',
            transition: 'none'
          }}
        >
          TWIN
        </span>
        {/* Gradient statique pour tous les modes - sans animation */}
        <span
          style={{
            fontFamily: "'Montserrat', sans-serif",
            fontSize: '15px',
            fontWeight: 800,
            letterSpacing: '0.8px',
            color: fallbackColor,
            background: gradientStyle,
            WebkitBackgroundClip: 'text',
            WebkitTextFillColor: 'transparent',
            backgroundClip: 'text',
            lineHeight: 1,
            textTransform: 'uppercase',
            filter: 'none',
            transition: 'none'
          }}
        >
          FØRGE
        </span>
      </div>
    </div>
  );
};

export default TwinForgeLogo;
