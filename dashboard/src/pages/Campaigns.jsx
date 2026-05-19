import React, { useState, useEffect } from 'react';
import {
  Megaphone01Icon, PromotionIcon, PlusSignIcon, Edit01Icon, Delete01Icon,
  ChartUpIcon, UserGroupIcon, CheckmarkCircle01Icon, CancelCircleIcon,
  ToggleOnIcon, ToggleOffIcon, Calendar01Icon, Coins01Icon, Motorbike01Icon,
  GiftIcon, Notification01Icon, Image01Icon,
} from 'hugeicons-react';
import api from '../config/api';

const CAMPAIGN_TYPES = {
  push: { label: 'Push Notification', icon: Notification01Icon, color: 'text-primary' },
  promo: { label: 'Promo Code', icon: GiftIcon, color: 'text-success' },
  banner: { label: 'In-App Banner', icon: Image01Icon, color: 'text-orange' },
};

const TARGETS = {
  all_users: 'All Users',
  all_drivers: 'All Drivers',
  new_users: 'New Users (< 7 days)',
  inactive_users: 'Inactive Users (> 30 days)',
  top_riders: 'Top Riders',
};

const MOCK_CAMPAIGNS = [
  { id: 'c1', name: 'Weekend Flash Sale', type: 'promo', target: 'all_users', status: 'active', start: '2025-05-17', end: '2025-05-18', reach: 1248, conversions: 142, budget: 500000, spent: 284000 },
  { id: 'c2', name: 'Driver Recruitment Drive', type: 'push', target: 'all_drivers', status: 'active', start: '2025-05-15', end: '2025-05-31', reach: 312, conversions: 28, budget: 0, spent: 0 },
  { id: 'c3', name: 'Win Back Inactive Riders', type: 'push', target: 'inactive_users', status: 'paused', start: '2025-05-10', end: '2025-05-25', reach: 420, conversions: 67, budget: 0, spent: 0 },
  { id: 'c4', name: 'Ramadan Campaign', type: 'banner', target: 'all_users', status: 'ended', start: '2025-03-01', end: '2025-04-01', reach: 2100, conversions: 380, budget: 800000, spent: 800000 },
];

const STATUS_STYLES = {
  active: 'text-success bg-success/10 border-success/20',
  paused: 'text-warning bg-warning/10 border-warning/20',
  draft: 'text-slate-500 bg-slate-100 border-slate-200',
  ended: 'text-slate-500 bg-slate-100 border-slate-200',
};

export default function Campaigns() {
  const [campaigns, setCampaigns] = useState(MOCK_CAMPAIGNS);

  useEffect(() => {
    api.get('/admin/campaigns').then((r) => { if (r.data?.length) setCampaigns(r.data); }).catch(() => {});
  }, []);

  const toggleStatus = async (id, current) => {
    const next = current === 'active' ? 'paused' : 'active';
    try { await api.patch(`/admin/campaigns/${id}`, { status: next }); } catch {}
    setCampaigns((prev) => prev.map((c) => (c.id === id ? { ...c, status: next } : c)));
  };

  const deleteCampaign = async (id) => {
    if (!confirm('Delete this campaign?')) return;
    try { await api.delete(`/admin/campaigns/${id}`); } catch {}
    setCampaigns((prev) => prev.filter((c) => c.id !== id));
  };

  const totalReach = campaigns.reduce((a, c) => a + c.reach, 0);
  const totalConversions = campaigns.reduce((a, c) => a + c.conversions, 0);

  return (
    <div className="p-6 space-y-6">
      <div className="flex items-center justify-between flex-wrap gap-4">
        <div>
          <h1 className="font-heading font-bold text-slate-900 text-2xl">Campaigns</h1>
          <p className="text-slate-500 text-sm mt-0.5">Marketing campaigns and user engagement</p>
        </div>
        <button className="flex items-center gap-2 px-4 py-2.5 rounded-xl bg-primary text-slate-700 text-sm font-semibold hover:bg-primary/80 transition-colors">
          <PlusSignIcon size={16} /> New Campaign
        </button>
      </div>

      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        {[
          { label: 'Total Campaigns', value: campaigns.length, icon: Megaphone01Icon, color: 'text-primary' },
          { label: 'Active', value: campaigns.filter((c) => c.status === 'active').length, icon: CheckmarkCircle01Icon, color: 'text-success' },
          { label: 'Total Reach', value: totalReach.toLocaleString(), icon: UserGroupIcon, color: 'text-orange' },
          { label: 'Conversions', value: totalConversions.toLocaleString(), icon: ChartUpIcon, color: 'text-warning' },
        ].map(({ label, value, icon: Icon, color }) => (
          <div key={label} className="bg-dark-card border border-dark-border rounded-2xl p-4">
            <div className="flex items-center gap-2 mb-2"><Icon size={15} className={color} /><span className="text-xs text-slate-500">{label}</span></div>
            <p className={`font-heading font-bold text-2xl ${color}`}>{value}</p>
          </div>
        ))}
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {campaigns.map((c) => {
          const typeInfo = CAMPAIGN_TYPES[c.type];
          const TypeIcon = typeInfo?.icon ?? Megaphone01Icon;
          const convRate = c.reach > 0 ? ((c.conversions / c.reach) * 100).toFixed(1) : 0;
          const budgetPct = c.budget > 0 ? Math.min((c.spent / c.budget) * 100, 100) : 0;

          return (
            <div key={c.id} className={`bg-dark-card border rounded-2xl p-5 ${c.status === 'active' ? 'border-success/30' : 'border-dark-border'}`}>
              <div className="flex items-start justify-between mb-3">
                <div>
                  <div className="flex items-center gap-2 flex-wrap">
                    <TypeIcon size={15} className={typeInfo?.color ?? 'text-slate-500'} />
                    <span className="font-heading font-semibold text-slate-900">{c.name}</span>
                    <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full border ${STATUS_STYLES[c.status]}`}>
                      {c.status.toUpperCase()}
                    </span>
                  </div>
                  <div className="flex items-center gap-3 mt-1 text-xs text-slate-500">
                    <span className={typeInfo?.color}>{typeInfo?.label}</span>
                    <span>· {TARGETS[c.target]}</span>
                  </div>
                </div>
                <div className="flex items-center gap-1">
                  <button className="p-1.5 rounded-lg text-slate-500 hover:text-slate-800 hover:bg-slate-50 transition-colors">
                    <Edit01Icon size={14} />
                  </button>
                  <button onClick={() => deleteCampaign(c.id)} className="p-1.5 rounded-lg text-slate-500 hover:text-danger hover:bg-danger/10 transition-colors">
                    <Delete01Icon size={14} />
                  </button>
                </div>
              </div>

              <div className="grid grid-cols-3 gap-2 mb-3">
                <div className="bg-dark-bg/50 rounded-xl p-2 text-center">
                  <p className="text-[10px] text-slate-500">Reach</p>
                  <p className="font-heading font-bold text-primary">{c.reach.toLocaleString()}</p>
                </div>
                <div className="bg-dark-bg/50 rounded-xl p-2 text-center">
                  <p className="text-[10px] text-slate-500">Conversions</p>
                  <p className="font-heading font-bold text-success">{c.conversions}</p>
                </div>
                <div className="bg-dark-bg/50 rounded-xl p-2 text-center">
                  <p className="text-[10px] text-slate-500">CVR</p>
                  <p className="font-heading font-bold text-orange">{convRate}%</p>
                </div>
              </div>

              {c.budget > 0 && (
                <div className="mb-3">
                  <div className="flex justify-between text-xs mb-1">
                    <span className="text-slate-500">Budget Spent</span>
                    <span className="text-slate-500">FC {c.spent.toLocaleString()} / FC {c.budget.toLocaleString()}</span>
                  </div>
                  <div className="h-1.5 bg-dark-bg rounded-full overflow-hidden">
                    <div className={`h-full rounded-full ${budgetPct >= 90 ? 'bg-danger' : 'bg-warning'}`} style={{ width: `${budgetPct}%` }} />
                  </div>
                </div>
              )}

              <div className="flex items-center justify-between">
                <div className="flex items-center gap-1 text-xs text-slate-500">
                  <Calendar01Icon size={11} />
                  {c.start} → {c.end}
                </div>
                {c.status !== 'ended' && (
                  <button onClick={() => toggleStatus(c.id, c.status)}>
                    {c.status === 'active' ? <ToggleOnIcon size={26} className="text-success" /> : <ToggleOffIcon size={26} className="text-slate-500" />}
                  </button>
                )}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
