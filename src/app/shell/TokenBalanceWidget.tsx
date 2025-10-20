import React, { useEffect, useState, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import TokenIcon from '../../ui/icons/TokenIcon';
import SpatialIcon from '../../ui/icons/SpatialIcon';
import { ICONS } from '../../ui/icons/registry';
import { TokenService, type TokenBalance } from '../../system/services/tokenService';
import { useFeedback } from '@/hooks';
import { useOverlayStore } from '../../system/store/overlayStore';
import { supabase } from '../../system/supabase/client';
import logger from '../../lib/utils/logger';

const TokenBalanceWidget: React.FC = () => {
  const [balance, setBalance] = useState<TokenBalance | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [retryCount, setRetryCount] = useState(0);
  const navigate = useNavigate();
  const { sidebarClick } = useFeedback();
  const { close } = useOverlayStore();

  const loadBalance = useCallback(async (isRetry = false) => {
    try {
      const result = await TokenService.getTokenBalance();

      if (result) {
        setBalance(result);
        setRetryCount(0);

        if (isRetry) {
          logger.info('TOKEN_BALANCE_WIDGET', 'Token balance loaded successfully after retry', {
            retryCount,
            balance: result.balance
          });
        }
      } else {
        if (retryCount < 3) {
          const delay = Math.min(1000 * Math.pow(2, retryCount), 5000);

          logger.warn('TOKEN_BALANCE_WIDGET', 'Token balance not found, scheduling retry', {
            retryCount: retryCount + 1,
            delayMs: delay
          });

          setTimeout(() => {
            setRetryCount(prev => prev + 1);
            loadBalance(true);
          }, delay);
        } else {
          logger.error('TOKEN_BALANCE_WIDGET', 'Failed to load token balance after retries', {
            maxRetriesReached: true
          });
        }
      }
    } catch (error) {
      logger.error('TOKEN_BALANCE_WIDGET', 'Error loading token balance', {
        error: error instanceof Error ? error.message : 'Unknown error',
        retryCount
      });
    } finally {
      setIsLoading(false);
    }
  }, [retryCount]);

  useEffect(() => {
    loadBalance();

    const getUserId = async () => {
      const { data: { user } } = await supabase.auth.getUser();
      return user?.id || '';
    };

    let unsubscribe: (() => void) | undefined;

    getUserId().then(userId => {
      if (userId) {
        unsubscribe = TokenService.subscribeToTokenBalance(
          userId,
          (newBalance) => {
            if (newBalance) {
              setBalance(newBalance);
              setRetryCount(0);

              logger.info('TOKEN_BALANCE_WIDGET', 'Token balance updated via subscription', {
                balance: newBalance.balance
              });
            }
          }
        );
      }
    });

    return () => {
      if (unsubscribe) {
        unsubscribe();
      }
    };
  }, [loadBalance]);

  const handleClick = () => {
    sidebarClick();
    close(); // Ferme le drawer mobile s'il est ouvert
    navigate('/settings?tab=account');
  };

  if (isLoading) {
    return null;
  }

  if (!balance) {
    return null;
  }

  const getVariant = () => {
    if (balance.balance < 50) return 'critical';
    if (balance.balance < 200) return 'warning';
    return 'success';
  };

  const variant = getVariant();
  const isLow = balance.balance < 200;
  const isCritical = balance.balance < 50;

  const getWidgetClassName = () => {
    const baseClass = 'sidebar-token-widget';
    if (isCritical) return `${baseClass} sidebar-token-widget--critical`;
    if (isLow) return `${baseClass} sidebar-token-widget--low`;
    return baseClass;
  };

  return (
    <button
      onClick={handleClick}
      className={getWidgetClassName()}
    >
      <div className="sidebar-token-widget-content">
        <div className="sidebar-token-widget-icon">
          <TokenIcon
            size={24}
            variant={variant}
            withGlow={isLow}
          />
        </div>
        <div className="sidebar-token-widget-info">
          <div className="sidebar-token-widget-balance">
            {TokenService.formatTokenAmount(balance.balance)}
          </div>
          <div className="sidebar-token-widget-label">
            {isLow ? 'Recharger mes tokens' : 'Tokens disponibles'}
          </div>
        </div>
        <div className="flex items-center gap-1">
          {isLow && (
            <div className="sidebar-token-widget-alert">
              <SpatialIcon
                Icon={ICONS.AlertCircle}
                size={12}
                className="opacity-70"
                style={{
                  color: isCritical ? '#EF4444' : '#F59E0B'
                }}
              />
            </div>
          )}
          <div className="sidebar-token-widget-arrow">
            <SpatialIcon
              Icon={ICONS.ChevronRight}
              size={12}
              className="opacity-40"
            />
          </div>
        </div>
      </div>
    </button>
  );
};

export default TokenBalanceWidget;
