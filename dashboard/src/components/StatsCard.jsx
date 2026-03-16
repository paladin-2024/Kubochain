import React from 'react';
import { TrendingUp, TrendingDown } from 'lucide-react';
import { cn } from '../lib/utils';

const VARIANTS = {
  primary: {
    bg: 'bg-primary/10',
    text: 'text-primary',
    border: 'border-primary/20',
    glow: 'group-hover:shadow-primary/10',
  },
  success: {
    bg: 'bg-success/10',
    text: 'text-success',
    border: 'border-success/20',
    glow: 'group-hover:shadow-success/10',
  },
  warning: {
    bg: 'bg-warning/10',
    text: 'text-warning',
    border: 'border-warning/20',
    glow: 'group-hover:shadow-warning/10',
  },
  danger: {
    bg: 'bg-danger/10',
    text: 'text-danger',
    border: 'border-danger/20',
    glow: 'group-hover:shadow-danger/10',
  },
  orange: {
    bg: 'bg-orange/10',
    text: 'text-orange',
    border: 'border-orange/20',
    glow: 'group-hover:shadow-orange/10',
  },
};

export default function StatsCard({
  label,
  value,
  icon: Icon,
  color = 'primary',
  trend,
  sub,
}) {
  const v = VARIANTS[color] || VARIANTS.primary;

  return (
    <div className={cn(
      'group bg-dark-card border border-dark-border rounded-2xl p-5',
      'flex items-center gap-4',
      'hover:border-primary/30 transition-all duration-200',
      'hover:shadow-lg', v.glow
    )}>
      {/* Icon */}
      <div className={cn(
        'w-11 h-11 rounded-xl flex items-center justify-center flex-shrink-0 border',
        v.bg, v.border
      )}>
        {Icon && <Icon size={20} strokeWidth={2} className={v.text} />}
      </div>

      {/* Content */}
      <div className="flex-1 min-w-0">
        <p className="text-gray-500 text-xs font-medium uppercase tracking-wide truncate">{label}</p>
        <p className="text-white text-2xl font-bold mt-0.5 truncate">{value ?? '—'}</p>
        {sub && <p className="text-gray-600 text-xs mt-0.5 truncate">{sub}</p>}
      </div>

      {/* Trend badge */}
      {trend !== undefined && (
        <div className={cn(
          'flex items-center gap-1 text-xs font-semibold px-2 py-1 rounded-lg flex-shrink-0',
          trend >= 0 ? 'bg-success/10 text-success' : 'bg-danger/10 text-danger'
        )}>
          {trend >= 0
            ? <TrendingUp size={12} />
            : <TrendingDown size={12} />}
          {Math.abs(trend)}%
        </div>
      )}
    </div>
  );
}
