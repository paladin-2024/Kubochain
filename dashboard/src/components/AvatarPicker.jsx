import React, { useState } from 'react';
import { CancelCircleIcon, CheckmarkCircle01Icon } from 'hugeicons-react';

const BG_PALETTE = [
  'dbeafe', 'e0e7ff', 'fce7f3', 'dcfce7', 'fef9c3',
  'ffedd5', 'f3e8ff', 'cffafe', 'fef2f2', 'ecfdf5',
];

// Curated seeds — visually distinct open-peeps characters
const AVATAR_OPTIONS = {
  men: [
    'adrian', 'baker', 'carlos', 'dmitri', 'ethan', 'felix',
    'gabriel', 'hassan', 'ibrahim', 'julius', 'kevin', 'leon',
  ],
  women: [
    'amara', 'bella', 'claire', 'diana', 'elena', 'fatima',
    'grace', 'hana', 'iris', 'jade', 'kira', 'luna',
  ],
  neutral: [
    'alex', 'brook', 'casey', 'drew', 'emery', 'finley',
    'gray', 'harper', 'indie', 'jules', 'kieran', 'morgan',
  ],
};

const ALL_OPTIONS = [...AVATAR_OPTIONS.men, ...AVATAR_OPTIONS.women, ...AVATAR_OPTIONS.neutral];

const TABS = [
  { key: 'all',     label: 'All' },
  { key: 'men',     label: 'Men' },
  { key: 'women',   label: 'Women' },
  { key: 'neutral', label: 'Neutral' },
];

function avatarUrl(seed, idx) {
  const bg = BG_PALETTE[idx % BG_PALETTE.length];
  return `https://api.dicebear.com/8.x/open-peeps/svg?seed=${seed}&backgroundColor=${bg}&backgroundType=solid&scale=120&translateY=8`;
}

export default function AvatarPicker({ currentSeed, onSelect, onClose }) {
  const [tab, setTab] = useState('all');
  const [hovered, setHovered] = useState(null);

  const seeds = tab === 'all' ? ALL_OPTIONS : AVATAR_OPTIONS[tab];

  return (
    <div
      className="fixed inset-0 bg-black/60 backdrop-blur-sm z-50 flex items-center justify-center p-4"
      onClick={onClose}
    >
      <div
        className="bg-white border border-slate-200 rounded-2xl w-full max-w-lg shadow-2xl"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-slate-100">
          <div>
            <h2 className="font-heading font-bold text-slate-900 text-lg">Choose Your Avatar</h2>
            <p className="text-slate-500 text-xs mt-0.5">Pick the one that looks most like you</p>
          </div>
          <button onClick={onClose}>
            <CancelCircleIcon size={22} className="text-slate-400 hover:text-slate-700 transition-colors" />
          </button>
        </div>

        {/* Tabs */}
        <div className="flex gap-1 px-6 pt-4">
          {TABS.map((t) => (
            <button
              key={t.key}
              onClick={() => setTab(t.key)}
              className={`px-4 py-1.5 rounded-lg text-sm font-medium transition-all ${
                tab === t.key
                  ? 'bg-primary text-white'
                  : 'text-slate-500 hover:text-slate-800 hover:bg-slate-100'
              }`}
            >
              {t.label}
            </button>
          ))}
        </div>

        {/* Avatar grid */}
        <div className="grid grid-cols-6 gap-3 p-6">
          {seeds.map((seed, idx) => {
            const globalIdx = ALL_OPTIONS.indexOf(seed);
            const isSelected = currentSeed === seed;
            const isHovered = hovered === seed;
            return (
              <button
                key={seed}
                onClick={() => onSelect(seed)}
                onMouseEnter={() => setHovered(seed)}
                onMouseLeave={() => setHovered(null)}
                className={`relative rounded-2xl p-1 transition-all ${
                  isSelected
                    ? 'ring-2 ring-primary ring-offset-2 bg-primary/5'
                    : isHovered
                    ? 'bg-slate-100 scale-105'
                    : 'hover:bg-slate-50'
                }`}
                title={seed}
              >
                <img
                  src={avatarUrl(seed, globalIdx >= 0 ? globalIdx : idx)}
                  alt={seed}
                  className="w-14 h-14 rounded-xl object-cover"
                  loading="lazy"
                />
                {isSelected && (
                  <div className="absolute -top-1 -right-1 w-5 h-5 bg-primary rounded-full flex items-center justify-center">
                    <CheckmarkCircle01Icon size={14} className="text-white" />
                  </div>
                )}
              </button>
            );
          })}
        </div>

        {/* Footer */}
        <div className="px-6 pb-5 flex items-center justify-between border-t border-slate-100 pt-4">
          <p className="text-xs text-slate-400">
            {currentSeed ? `Current: ${currentSeed}` : 'No custom avatar set'}
          </p>
          <div className="flex gap-2">
            {currentSeed && (
              <button
                onClick={() => onSelect(null)}
                className="px-4 py-2 rounded-xl text-sm font-medium text-slate-500 hover:text-slate-800 hover:bg-slate-100 transition-colors"
              >
                Reset to default
              </button>
            )}
            <button
              onClick={onClose}
              className="px-5 py-2 rounded-xl text-sm font-semibold bg-primary text-white hover:bg-primary/90 transition-colors"
            >
              Done
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
