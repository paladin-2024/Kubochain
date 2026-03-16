import React, { createContext, useContext, useId } from 'react';
import { ResponsiveContainer, Tooltip, Legend } from 'recharts';
import { cn } from '../../lib/utils';

// ─── Context ──────────────────────────────────────────────────────────────────
const ChartContext = createContext(null);
function useChart() {
  const ctx = useContext(ChartContext);
  if (!ctx) throw new Error('useChart must be inside ChartContainer');
  return ctx;
}

// ─── ChartContainer ────────────────────────────────────────────────────────────
export function ChartContainer({ config = {}, children, className }) {
  const id = useId();
  const colorVars = Object.entries(config).reduce((acc, [key, val]) => {
    if (val.color) acc[`--color-${key}`] = val.color;
    return acc;
  }, {});

  return (
    <ChartContext.Provider value={{ config, id }}>
      <div
        className={cn('w-full', className)}
        style={colorVars}
        data-chart={id}
      >
        <style>{`
          [data-chart="${id}"] .recharts-cartesian-grid line { stroke: #2D3D50; }
          [data-chart="${id}"] .recharts-cartesian-axis-tick-value { fill: #828282; font-size: 11px; }
          [data-chart="${id}"] .recharts-curve { stroke-width: 2.5; }
          [data-chart="${id}"] .recharts-dot { r: 3; }
        `}</style>
        <ResponsiveContainer width="100%" height="100%">
          {children}
        </ResponsiveContainer>
      </div>
    </ChartContext.Provider>
  );
}

// ─── ChartTooltipContent ───────────────────────────────────────────────────────
export function ChartTooltipContent({
  active, payload, label, className,
  formatter, labelFormatter, hideLabel = false, indicator = 'dot',
}) {
  const { config } = useChart();
  if (!active || !payload?.length) return null;

  return (
    <div className={cn(
      'min-w-[140px] rounded-xl border border-dark-border bg-dark-card p-3 shadow-xl text-xs',
      className
    )}>
      {!hideLabel && label && (
        <p className="mb-2 font-semibold text-gray-400">
          {labelFormatter ? labelFormatter(label, payload) : label}
        </p>
      )}
      <div className="space-y-1.5">
        {payload.map((item, i) => {
          const cfg = config[item.dataKey] || {};
          const color = item.color || cfg.color || '#2F80ED';
          const name = cfg.label || item.name;
          const val = formatter
            ? formatter(item.value, item.dataKey, item, i, payload)
            : item.value?.toLocaleString();

          return (
            <div key={i} className="flex items-center justify-between gap-4">
              <span className="flex items-center gap-1.5 text-gray-400">
                {indicator === 'dot' && (
                  <span className="w-2 h-2 rounded-full flex-shrink-0" style={{ backgroundColor: color }} />
                )}
                {indicator === 'line' && (
                  <span className="w-3 h-0.5 flex-shrink-0" style={{ backgroundColor: color }} />
                )}
                {name}
              </span>
              <span className="font-bold text-white">{val}</span>
            </div>
          );
        })}
      </div>
    </div>
  );
}

// ─── ChartLegendContent ────────────────────────────────────────────────────────
export function ChartLegendContent({ payload, className }) {
  const { config } = useChart();
  if (!payload?.length) return null;

  return (
    <div className={cn('flex flex-wrap items-center justify-center gap-4 pt-2', className)}>
      {payload.map((item, i) => {
        const cfg = config[item.dataKey || item.value] || {};
        const color = item.color || cfg.color;
        const label = cfg.label || item.value;
        return (
          <span key={i} className="flex items-center gap-1.5 text-xs text-gray-400">
            <span className="w-2.5 h-2.5 rounded-sm flex-shrink-0" style={{ backgroundColor: color }} />
            {label}
          </span>
        );
      })}
    </div>
  );
}

// ─── Re-exports for convenience ────────────────────────────────────────────────
export { Tooltip as ChartTooltip, Legend as ChartLegend };
