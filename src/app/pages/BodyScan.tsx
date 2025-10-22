import React from 'react';
import BodyScanCapture from './BodyScan/BodyScanCapture';

/**
 * BodyScan - Pipeline de scan corporel
 * Point d'entrée pour le processus de scan corporel complet
 * Lance le flux de capture photo et traitement IA
 */
const BodyScan: React.FC = () => {
  return (
    <div
      className="max-w-4xl mx-auto mt-4 forge-body-page-container"
      style={{
        position: 'static',
        overflow: 'visible',
        contain: 'none',
        isolation: 'auto',
        transform: 'none',
        willChange: 'auto'
      }}
    >
      <BodyScanCapture />
    </div>
  );
};

export default BodyScan;