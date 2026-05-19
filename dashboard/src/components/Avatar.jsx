import React, { useState } from 'react';

const BG_PALETTE = [
  'dbeafe', 'e0e7ff', 'fce7f3', 'dcfce7', 'fef9c3',
  'ffedd5', 'f3e8ff', 'cffafe', 'fef2f2', 'ecfdf5',
];

function seedColor(name = '') {
  let h = 0;
  for (let i = 0; i < name.length; i++) h = name.charCodeAt(i) + ((h << 5) - h);
  return BG_PALETTE[Math.abs(h) % BG_PALETTE.length];
}

function initials(name = '') {
  return name.trim().split(/\s+/).filter(Boolean).map((p) => p[0].toUpperCase()).slice(0, 2).join('');
}

/**
 * Avatar — DiceBear open-peeps illustration with initials fallback.
 *
 * Props:
 *   name     {string}  — Person's full name (used as seed + initials)
 *   size     {number}  — Pixel size of the circle (default 40)
 *   online   {boolean} — If set, shows a green/gray presence dot
 *   ring     {boolean} — Adds a 2px primary-colour border ring
 *   className {string} — Extra classes on the wrapper div
 */
export default function Avatar({ name = '', size = 40, online, ring = false, className = '', seed: seedOverride }) {
  const [imgError, setImgError] = useState(false);
  const bg = seedColor(name);
  const seed = seedOverride ?? encodeURIComponent((name || 'user').trim());
  const src = `https://api.dicebear.com/8.x/open-peeps/svg?seed=${seed}&backgroundColor=${bg}&backgroundType=solid&scale=120&translateY=8`;

  const fontSize = Math.round(size * 0.35);
  const dotSize  = Math.max(8, Math.round(size * 0.22));
  const borderW  = Math.max(1, Math.round(size * 0.05));

  return (
    <div
      className={`relative inline-flex flex-shrink-0 ${className}`}
      style={{ width: size, height: size }}
    >
      {/* Illustration */}
      {!imgError ? (
        <img
          src={src}
          alt={name || 'Avatar'}
          width={size}
          height={size}
          onError={() => setImgError(true)}
          className={`w-full h-full rounded-full object-cover bg-slate-100 ${ring ? 'ring-2 ring-primary ring-offset-1' : 'border border-dark-border'}`}
          style={{ display: 'block' }}
        />
      ) : (
        /* Initials fallback */
        <div
          className={`w-full h-full rounded-full flex items-center justify-center font-heading font-bold text-primary bg-primary/10 ${ring ? 'ring-2 ring-primary ring-offset-1' : 'border border-primary/20'}`}
          style={{ fontSize }}
        >
          {initials(name) || '?'}
        </div>
      )}

      {/* Presence dot */}
      {online !== undefined && (
        <span
          className={`absolute bottom-0 right-0 rounded-full border-white ${online ? 'bg-success' : 'bg-slate-300'}`}
          style={{ width: dotSize, height: dotSize, borderWidth: borderW }}
        />
      )}
    </div>
  );
}
