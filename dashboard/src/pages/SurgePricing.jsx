import React, { useState, useEffect } from 'react';
import {
  FlashIcon, ToggleOnIcon, ToggleOffIcon, Clock01Icon, MapPinpoint01Icon,
  PlusSignIcon, Edit01Icon, Delete01Icon, CheckmarkCircle01Icon, CancelCircleIcon,
  ArrowUp01Icon, ChartUpIcon, Motorbike01Icon, AlertDiamondIcon, Settings01Icon,
  Calendar01Icon,
} from 'hugeicons-react';
import api from '../config/api';

const MOCK_ZONES_SURGE = [
  { id: 'z1', name: 'Goma Centre', active: true, multiplier: 1.8, trigger: 'manual', active_rides: 34, available_drivers: 8, expires_at: '2025-05-17T18:00:00Z' },
  { id: 'z2', name: 'Birere Market', active: false, multiplier: 1.5, trigger: 'demand', active_rides: 12, available_drivers: 15, expires_at: null },
  { id: 'z3', name: 'Ndosho', active: true, multiplier: 1.3, trigger: 'schedule', active_rides: 8, available_drivers: 5, expires_at: '2025-05-17T20:00:00Z' },
  { id: 'z4', name: 'Himbi', active: false, multiplier: 1.2, trigger: 'demand', active_rides: 5, available_drivers: 12, expires_at: null },
  { id: 'z5', name: 'Katindo', active: true, multiplier: 2.0, trigger: 'manual', active_rides: 42, available_drivers: 6, expires_at: '2025-05-17T17:30:00Z' },
];

const MOCK_RULES = [
  { id: 'r1', name: 'Peak Morning', schedule: 'Mon–Fri 07:00–09:00', multiplier: 1.5, enabled: true, zones: ['Goma Centre', 'Ndosho'] },
  { id: 'r2', name: 'Peak Evening', schedule: 'Mon–Fri 17:00–20:00', multiplier: 1.6, enabled: true, zones: ['Goma Centre', 'Birere Market', 'Katindo'] },
  { id: 'r3', name: 'Saturday Night', schedule: 'Sat 21:00–01:00', multiplier: 2.0, enabled: false, zones: ['Goma Centre'] },
  { id: 'r4', name: 'Low Supply Alert', schedule: 'Auto (< 5 drivers)', multiplier: 1.8, enabled: true, zones: ['All Zones'] },
];

function MultiplierBadge({ value }) {
  const color = value >= 2 ? 'text-danger bg-danger/10 border-danger/30'
    : value >= 1.6 ? 'text-orange bg-orange/10 border-orange/30'
    : value >= 1.3 ? 'text-warning bg-warning/10 border-warning/30'
    : 'text-success bg-success/10 border-success/20';
  return (
    <span className={`inline-flex items-center gap-1 font-heading font-bold text-sm px-2.5 py-1 rounded-lg border ${color}`}>
      <FlashIcon size={13} />
      {value}x
    </span>
  );
}

function ZoneCard({ zone, onToggle }) {
  const ratio = zone.active_rides / Math.max(zone.available_drivers, 1);
  const demand = ratio > 4 ? 'Very High' : ratio > 2.5 ? 'High' : ratio > 1.5 ? 'Medium' : 'Low';
  const demandColor = ratio > 4 ? 'text-danger' : ratio > 2.5 ? 'text-orange' : ratio > 1.5 ? 'text-warning' : 'text-success';

  return (
    <div className={`bg-dark-card border rounded-2xl p-5 transition-all ${zone.active ? 'border-warning/40 shadow-[0_0_20px_rgba(226,185,59,0.06)]' : 'border-dark-border'}`}>
      <div className="flex items-start justify-between mb-3">
        <div>
          <div className="flex items-center gap-2">
            <MapPinpoint01Icon size={15} className="text-primary" />
            <span className="font-heading font-semibold text-slate-900">{zone.name}</span>
            {zone.active && (
              <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-warning/10 text-warning border border-warning/20 animate-pulse">
                ACTIVE
              </span>
            )}
          </div>
          <p className="text-xs text-slate-500 mt-1">Trigger: {zone.trigger}</p>
        </div>
        <MultiplierBadge value={zone.multiplier} />
      </div>

      <div className="grid grid-cols-2 gap-3 mb-4">
        <div className="bg-slate-50 rounded-xl p-2.5 text-center">
          <p className="text-[11px] text-slate-500 mb-0.5">Active Rides</p>
          <p className="font-heading font-bold text-orange text-lg">{zone.active_rides}</p>
        </div>
        <div className="bg-slate-50 rounded-xl p-2.5 text-center">
          <p className="text-[11px] text-slate-500 mb-0.5">Free Drivers</p>
          <p className="font-heading font-bold text-success text-lg">{zone.available_drivers}</p>
        </div>
      </div>

      <div className="flex items-center justify-between mb-3">
        <div className="flex items-center gap-1.5 text-xs">
          <ChartUpIcon size={12} className={demandColor} />
          <span className={`font-semibold ${demandColor}`}>{demand} Demand</span>
        </div>
        {zone.expires_at && (
          <div className="flex items-center gap-1 text-xs text-slate-500">
            <Clock01Icon size={11} />
            Exp. {new Date(zone.expires_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
          </div>
        )}
      </div>

      <button
        onClick={() => onToggle(zone.id, !zone.active)}
        className={`w-full flex items-center justify-center gap-2 py-2.5 rounded-xl text-sm font-semibold transition-all ${
          zone.active
            ? 'bg-danger/10 text-danger border border-danger/20 hover:bg-danger/20'
            : 'bg-warning/10 text-warning border border-warning/20 hover:bg-warning/20'
        }`}
      >
        {zone.active ? <ToggleOffIcon size={16} /> : <ToggleOnIcon size={16} />}
        {zone.active ? 'Deactivate Surge' : 'Activate Surge'}
      </button>
    </div>
  );
}

export default function SurgePricing() {
  const [zones, setZones] = useState(MOCK_ZONES_SURGE);
  const [rules, setRules] = useState(MOCK_RULES);
  const [globalSurge, setGlobalSurge] = useState(false);
  const [globalMult, setGlobalMult] = useState(1.5);

  const toggleZone = async (id, active) => {
    try {
      await api.patch(`/admin/surge/zones/${id}`, { active });
      setZones((prev) => prev.map((z) => (z.id === id ? { ...z, active } : z)));
    } catch {
      setZones((prev) => prev.map((z) => (z.id === id ? { ...z, active } : z)));
    }
  };

  const toggleRule = (id, enabled) => {
    setRules((prev) => prev.map((r) => (r.id === id ? { ...r, enabled } : r)));
    api.patch(`/admin/surge/rules/${id}`, { enabled }).catch(() => {});
  };

  const activeSurgeCount = zones.filter((z) => z.active).length;

  return (
    <div className="p-6 space-y-6">
      <div className="flex items-center justify-between flex-wrap gap-4">
        <div>
          <h1 className="font-heading font-bold text-slate-900 text-2xl flex items-center gap-2">
            <FlashIcon size={24} className="text-warning" />
            Surge Pricing
          </h1>
          <p className="text-slate-500 text-sm mt-0.5">Control dynamic pricing multipliers by zone</p>
        </div>
        <div className="flex items-center gap-3">
          <span className="text-sm text-slate-500">{activeSurgeCount} zones active</span>
          <div className={`flex items-center gap-2 px-4 py-2 rounded-xl border text-sm font-semibold transition-all ${activeSurgeCount > 0 ? 'bg-warning/10 text-warning border-warning/30' : 'bg-dark-card text-slate-500 border-dark-border'}`}>
            <FlashIcon size={15} />
            {activeSurgeCount > 0 ? 'Surge Live' : 'No Active Surge'}
          </div>
        </div>
      </div>

      {/* Global override */}
      <div className="bg-dark-card border border-dark-border rounded-2xl p-5">
        <div className="flex items-center justify-between flex-wrap gap-4">
          <div>
            <h2 className="font-heading font-semibold text-slate-900 flex items-center gap-2">
              <AlertDiamondIcon size={18} className="text-danger" />
              Global Emergency Override
            </h2>
            <p className="text-slate-500 text-sm mt-0.5">Apply uniform surge multiplier to ALL zones instantly</p>
          </div>
          <div className="flex items-center gap-3">
            <div className="flex items-center gap-2 bg-dark-bg border border-dark-border rounded-xl px-3 py-2">
              <span className="text-sm text-slate-500">Multiplier:</span>
              <input
                type="number"
                min="1"
                max="5"
                step="0.1"
                value={globalMult}
                onChange={(e) => setGlobalMult(parseFloat(e.target.value))}
                className="w-16 bg-transparent text-warning font-heading font-bold text-center outline-none"
              />
              <span className="text-warning font-bold">x</span>
            </div>
            <button
              onClick={() => {
                setGlobalSurge((v) => !v);
                api.post('/admin/surge/global', { active: !globalSurge, multiplier: globalMult }).catch(() => {});
              }}
              className={`flex items-center gap-2 px-5 py-2.5 rounded-xl font-semibold text-sm transition-all ${
                globalSurge
                  ? 'bg-danger text-slate-800 hover:bg-danger/80'
                  : 'bg-warning text-slate-800 hover:bg-warning/80'
              }`}
            >
              {globalSurge ? <ToggleOffIcon size={16} /> : <ToggleOnIcon size={16} />}
              {globalSurge ? 'Deactivate All' : 'Activate Global'}
            </button>
          </div>
        </div>
      </div>

      {/* Zone cards */}
      <div>
        <h2 className="font-heading font-semibold text-slate-900 mb-4 flex items-center gap-2">
          <MapPinpoint01Icon size={16} className="text-primary" />
          Zones
        </h2>
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
          {zones.map((z) => <ZoneCard key={z.id} zone={z} onToggle={toggleZone} />)}
        </div>
      </div>

      {/* Scheduled rules */}
      <div>
        <h2 className="font-heading font-semibold text-slate-900 mb-4 flex items-center gap-2">
          <Calendar01Icon size={16} className="text-primary" />
          Scheduled Rules
        </h2>
        <div className="bg-dark-card border border-dark-border rounded-2xl overflow-hidden">
          <div className="divide-y divide-dark-border/50">
            {rules.map((rule) => (
              <div key={rule.id} className="flex items-center gap-4 px-5 py-4 hover:bg-slate-50 transition-colors">
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 flex-wrap">
                    <span className="font-medium text-slate-800 text-sm">{rule.name}</span>
                    <MultiplierBadge value={rule.multiplier} />
                    {!rule.enabled && <span className="text-[10px] text-slate-500 bg-slate-100 border border-slate-200 rounded-full px-2 py-0.5">DISABLED</span>}
                  </div>
                  <p className="text-xs text-slate-500 mt-0.5">{rule.schedule}</p>
                  <div className="flex flex-wrap gap-1 mt-1.5">
                    {rule.zones.map((z) => (
                      <span key={z} className="text-[10px] bg-primary/10 text-primary border border-primary/20 rounded-md px-1.5 py-0.5">{z}</span>
                    ))}
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <button
                    onClick={() => toggleRule(rule.id, !rule.enabled)}
                    className={`text-2xl transition-colors ${rule.enabled ? 'text-success' : 'text-slate-500'}`}
                  >
                    {rule.enabled ? <ToggleOnIcon size={28} /> : <ToggleOffIcon size={28} />}
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
