import React, { useState, useEffect } from 'react';
import {
  ToggleOnIcon, ToggleOffIcon, Settings01Icon, Shield01Icon, FlashIcon,
  Motorbike01Icon, UserGroupIcon, CheckmarkCircle01Icon, AlertDiamondIcon,
  Edit01Icon, Clock01Icon, UserCheck01Icon, CodeIcon,
} from 'hugeicons-react';
import api from '../config/api';

const FLAG_CATEGORIES = {
  safety: { label: 'Safety', icon: Shield01Icon, color: 'text-danger' },
  payments: { label: 'Payments', icon: FlashIcon, color: 'text-warning' },
  ui: { label: 'UI/UX', icon: Settings01Icon, color: 'text-primary' },
  operations: { label: 'Operations', icon: Motorbike01Icon, color: 'text-orange' },
  experimental: { label: 'Experimental', icon: CodeIcon, color: 'text-success' },
};

const MOCK_FLAGS = [
  { id: 'f1', key: 'sos_button_enabled', label: 'SOS Button', description: 'Show emergency SOS button in app during rides', category: 'safety', enabled: true, rollout_pct: 100, last_changed: '2025-05-01', changed_by: 'Admin Serge' },
  { id: 'f2', key: 'mobile_money_payments', label: 'Mobile Money Payments', description: 'Allow passengers to pay via mobile money in-app', category: 'payments', enabled: true, rollout_pct: 100, last_changed: '2025-04-15', changed_by: 'Admin Grace' },
  { id: 'f3', key: 'driver_earnings_dashboard', label: 'Driver Earnings Dashboard', description: 'New earnings breakdown screen in driver app', category: 'ui', enabled: true, rollout_pct: 100, last_changed: '2025-04-20', changed_by: 'Admin Serge' },
  { id: 'f4', key: 'surge_pricing_v2', label: 'Surge Pricing V2', description: 'AI-powered surge pricing with zone-specific multipliers', category: 'operations', enabled: false, rollout_pct: 0, last_changed: '2025-05-10', changed_by: 'Admin Grace' },
  { id: 'f5', key: 'chat_during_ride', label: 'In-Ride Chat', description: 'Encrypted chat between driver and passenger', category: 'experimental', enabled: false, rollout_pct: 20, last_changed: '2025-05-12', changed_by: 'Admin Serge' },
  { id: 'f6', key: 'scheduled_rides', label: 'Scheduled Rides', description: 'Book rides up to 24 hours in advance', category: 'experimental', enabled: false, rollout_pct: 0, last_changed: '2025-05-05', changed_by: 'Admin Grace' },
  { id: 'f7', key: 'auto_tip_prompt', label: 'Auto Tip Prompt', description: 'Show tipping screen after ride completion', category: 'payments', enabled: true, rollout_pct: 50, last_changed: '2025-05-08', changed_by: 'Admin Serge' },
  { id: 'f8', key: 'referral_program', label: 'Referral Program', description: 'Enable referral system with rewards', category: 'operations', enabled: true, rollout_pct: 100, last_changed: '2025-03-01', changed_by: 'Admin Grace' },
];

export default function FeatureFlags() {
  const [flags, setFlags] = useState(MOCK_FLAGS);
  const [categoryFilter, setCategoryFilter] = useState('all');
  const [editing, setEditing] = useState(null);
  const [editPct, setEditPct] = useState(0);

  useEffect(() => {
    api.get('/admin/features').then((r) => { if (r.data?.length) setFlags(r.data); }).catch(() => {});
  }, []);

  const toggle = async (id, enabled) => {
    try { await api.patch(`/admin/features/${id}`, { enabled }); } catch {}
    setFlags((prev) => prev.map((f) => (f.id === id ? { ...f, enabled } : f)));
  };

  const saveRollout = async (id) => {
    try { await api.patch(`/admin/features/${id}`, { rollout_pct: editPct }); } catch {}
    setFlags((prev) => prev.map((f) => (f.id === id ? { ...f, rollout_pct: editPct } : f)));
    setEditing(null);
  };

  const filtered = flags.filter((f) => categoryFilter === 'all' || f.category === categoryFilter);
  const enabledCount = flags.filter((f) => f.enabled).length;

  return (
    <div className="p-6 space-y-6">
      <div className="flex items-center justify-between flex-wrap gap-4">
        <div>
          <h1 className="font-heading font-bold text-slate-900 text-2xl">Feature Flags</h1>
          <p className="text-slate-500 text-sm mt-0.5">Control feature rollouts and experimental features</p>
        </div>
        <div className={`flex items-center gap-2 px-3 py-1.5 rounded-xl text-sm font-semibold border ${enabledCount > 0 ? 'text-success bg-success/10 border-success/20' : 'text-slate-500 bg-dark-card border-dark-border'}`}>
          <CheckmarkCircle01Icon size={14} />
          {enabledCount} / {flags.length} enabled
        </div>
      </div>

      {/* Category filters */}
      <div className="flex flex-wrap gap-2">
        <button
          onClick={() => setCategoryFilter('all')}
          className={`px-3 py-1.5 rounded-xl text-xs font-semibold border transition-all ${categoryFilter === 'all' ? 'bg-primary text-slate-800 border-primary/30' : 'text-slate-500 bg-dark-card border-dark-border hover:text-slate-800'}`}
        >
          All ({flags.length})
        </button>
        {Object.entries(FLAG_CATEGORIES).map(([key, { label, icon: Icon, color }]) => (
          <button
            key={key}
            onClick={() => setCategoryFilter(key)}
            className={`flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-semibold border transition-all ${
              categoryFilter === key ? `bg-primary text-slate-800 border-primary/30` : `text-slate-500 bg-dark-card border-dark-border hover:text-slate-800`
            }`}
          >
            <Icon size={12} className={categoryFilter === key ? 'text-slate-800' : color} />
            {label} ({flags.filter((f) => f.category === key).length})
          </button>
        ))}
      </div>

      {/* Flags list */}
      <div className="bg-dark-card border border-dark-border rounded-2xl divide-y divide-dark-border/50">
        {filtered.map((flag) => {
          const cat = FLAG_CATEGORIES[flag.category];
          const CatIcon = cat?.icon ?? Settings01Icon;
          const isEditing = editing === flag.id;

          return (
            <div key={flag.id} className="flex items-start gap-4 px-5 py-4 hover:bg-slate-50 transition-colors">
              <div className={`w-8 h-8 rounded-xl flex items-center justify-center flex-shrink-0 mt-0.5 bg-dark-bg border border-dark-border`}>
                <CatIcon size={14} className={cat?.color ?? 'text-slate-500'} />
              </div>
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2 flex-wrap">
                  <span className="font-medium text-slate-800 text-sm">{flag.label}</span>
                  <code className="text-[10px] bg-dark-bg border border-dark-border rounded px-1.5 py-0.5 text-slate-500 font-mono">{flag.key}</code>
                  {!flag.enabled && flag.rollout_pct > 0 && (
                    <span className="text-[10px] text-warning bg-warning/10 border border-warning/20 px-1.5 py-0.5 rounded-md font-semibold">
                      {flag.rollout_pct}% rollout
                    </span>
                  )}
                </div>
                <p className="text-xs text-slate-500 mt-0.5">{flag.description}</p>
                <div className="flex items-center gap-3 mt-1.5">
                  <div className="flex items-center gap-1 text-[10px] text-slate-500">
                    <Clock01Icon size={10} />
                    {flag.last_changed}
                  </div>
                  <div className="flex items-center gap-1 text-[10px] text-slate-500">
                    <UserCheck01Icon size={10} />
                    {flag.changed_by}
                  </div>
                </div>
                {isEditing && (
                  <div className="flex items-center gap-2 mt-2">
                    <span className="text-xs text-slate-500">Rollout %:</span>
                    <input
                      type="range" min="0" max="100" value={editPct}
                      onChange={(e) => setEditPct(Number(e.target.value))}
                      className="flex-1"
                    />
                    <span className="text-xs text-warning font-bold w-8 text-right">{editPct}%</span>
                    <button onClick={() => saveRollout(flag.id)} className="text-xs text-success font-semibold px-2 py-1 rounded-lg bg-success/10 border border-success/20">Save</button>
                    <button onClick={() => setEditing(null)} className="text-xs text-slate-500 px-2 py-1 rounded-lg bg-dark-bg border border-dark-border">Cancel</button>
                  </div>
                )}
              </div>
              <div className="flex items-center gap-2 flex-shrink-0 mt-0.5">
                {!isEditing && (
                  <button
                    onClick={() => { setEditing(flag.id); setEditPct(flag.rollout_pct); }}
                    className="p-1.5 rounded-lg text-slate-500 hover:text-slate-800 hover:bg-slate-50 transition-colors"
                  >
                    <Edit01Icon size={13} />
                  </button>
                )}
                <button onClick={() => toggle(flag.id, !flag.enabled)}>
                  {flag.enabled
                    ? <ToggleOnIcon size={28} className="text-success" />
                    : <ToggleOffIcon size={28} className="text-slate-500" />
                  }
                </button>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
