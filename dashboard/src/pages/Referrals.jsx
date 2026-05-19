import React, { useState, useEffect } from 'react';
import {
  GiftIcon, UserAdd01Icon, UserGroupIcon, ChartUpIcon, Coins01Icon,
  CheckmarkCircle01Icon, Link01Icon, Copy01Icon, Money01Icon, Calendar01Icon,
  ArrowUp01Icon, FileDownloadIcon, Settings01Icon,
} from 'hugeicons-react';
import api from '../config/api';

const MOCK_STATS = {
  total_referrals: 847,
  active_referrers: 124,
  reward_given: 4235000,
  conversion_rate: 38.2,
};

const MOCK_TOP_REFERRERS = [
  { rank: 1, name: 'Jean-Pierre Bauma', type: 'driver', referrals: 24, reward: 240000, last_referral: '2025-05-16' },
  { rank: 2, name: 'Marie Kavira', type: 'passenger', referrals: 18, reward: 180000, last_referral: '2025-05-17' },
  { rank: 3, name: 'Sylvie Nzigire', type: 'driver', referrals: 15, reward: 150000, last_referral: '2025-05-15' },
  { rank: 4, name: 'Alain Tshomba', type: 'passenger', referrals: 12, reward: 120000, last_referral: '2025-05-14' },
  { rank: 5, name: 'Grace Amani', type: 'driver', referrals: 10, reward: 100000, last_referral: '2025-05-13' },
];

const MOCK_CONFIG = {
  referrer_reward: 10000,
  referee_reward: 5000,
  max_referrals_per_user: 50,
  min_rides_to_qualify: 1,
};

const RANK_COLORS = ['text-warning', 'text-slate-600', 'text-orange', 'text-slate-500', 'text-slate-500'];

export default function Referrals() {
  const [stats, setStats] = useState(MOCK_STATS);
  const [referrers, setReferrers] = useState(MOCK_TOP_REFERRERS);
  const [config, setConfig] = useState(MOCK_CONFIG);
  const [editingConfig, setEditingConfig] = useState(false);
  const [tempConfig, setTempConfig] = useState(config);

  useEffect(() => {
    Promise.all([
      api.get('/admin/referrals/stats').catch(() => ({ data: null })),
      api.get('/admin/referrals/top').catch(() => ({ data: null })),
      api.get('/admin/referrals/config').catch(() => ({ data: null })),
    ]).then(([sRes, rRes, cRes]) => {
      if (sRes.data) setStats(sRes.data);
      if (rRes.data?.length) setReferrers(rRes.data);
      if (cRes.data) { setConfig(cRes.data); setTempConfig(cRes.data); }
    });
  }, []);

  const saveConfig = async () => {
    try { await api.put('/admin/referrals/config', tempConfig); setConfig(tempConfig); } catch {}
    setEditingConfig(false);
  };

  return (
    <div className="p-6 space-y-6">
      <div className="flex items-center justify-between flex-wrap gap-4">
        <div>
          <h1 className="font-heading font-bold text-slate-900 text-2xl">Referral Program</h1>
          <p className="text-slate-500 text-sm mt-0.5">Track referrals, rewards, and program performance</p>
        </div>
        <button className="flex items-center gap-2 px-4 py-2 rounded-xl bg-dark-card border border-dark-border text-slate-500 hover:text-slate-800 text-sm font-medium transition-colors">
          <FileDownloadIcon size={15} /> Export
        </button>
      </div>

      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        {[
          { label: 'Total Referrals', value: stats.total_referrals?.toLocaleString(), icon: UserAdd01Icon, color: 'text-primary' },
          { label: 'Active Referrers', value: stats.active_referrers, icon: UserGroupIcon, color: 'text-success' },
          { label: 'Rewards Paid Out', value: `FC ${(stats.reward_given / 1000).toFixed(0)}K`, icon: Coins01Icon, color: 'text-orange' },
          { label: 'Conversion Rate', value: `${stats.conversion_rate}%`, icon: ChartUpIcon, color: 'text-warning' },
        ].map(({ label, value, icon: Icon, color }) => (
          <div key={label} className="bg-dark-card border border-dark-border rounded-2xl p-4">
            <div className="flex items-center gap-2 mb-2"><Icon size={15} className={color} /><span className="text-xs text-slate-500">{label}</span></div>
            <p className={`font-heading font-bold text-2xl ${color}`}>{value}</p>
          </div>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        {/* Top referrers */}
        <div className="lg:col-span-2 bg-dark-card border border-dark-border rounded-2xl overflow-hidden">
          <div className="px-5 py-4 border-b border-dark-border">
            <h2 className="font-heading font-semibold text-slate-900">Top Referrers</h2>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-dark-border">
                  {['#', 'Member', 'Type', 'Referrals', 'Reward', 'Last Referral'].map((h) => (
                    <th key={h} className="px-4 py-3 text-left text-[11px] font-semibold uppercase tracking-widest text-slate-500">{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {referrers.map((r) => (
                  <tr key={r.rank} className="border-b border-dark-border/50 hover:bg-slate-50 transition-colors">
                    <td className={`px-4 py-3 font-heading font-black text-lg ${RANK_COLORS[r.rank - 1]}`}>{r.rank}</td>
                    <td className="px-4 py-3 text-sm font-medium text-slate-800">{r.name}</td>
                    <td className="px-4 py-3">
                      <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full border ${r.type === 'driver' ? 'text-orange bg-orange/10 border-orange/20' : 'text-primary bg-primary/10 border-primary/20'}`}>
                        {r.type.toUpperCase()}
                      </span>
                    </td>
                    <td className="px-4 py-3 font-heading font-bold text-success">{r.referrals}</td>
                    <td className="px-4 py-3 font-heading font-bold text-orange">FC {r.reward.toLocaleString()}</td>
                    <td className="px-4 py-3 text-xs text-slate-500">{r.last_referral}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {/* Program config */}
        <div className="bg-dark-card border border-dark-border rounded-2xl p-5">
          <div className="flex items-center justify-between mb-4">
            <h2 className="font-heading font-semibold text-slate-900">Program Settings</h2>
            <button
              onClick={() => editingConfig ? saveConfig() : setEditingConfig(true)}
              className={`text-xs px-3 py-1.5 rounded-lg border font-semibold transition-colors ${
                editingConfig ? 'bg-success/10 text-success border-success/20 hover:bg-success/20' : 'bg-dark-bg text-slate-500 border-dark-border hover:text-slate-800'
              }`}
            >
              {editingConfig ? 'Save' : 'Edit'}
            </button>
          </div>
          <div className="space-y-4">
            {[
              { key: 'referrer_reward', label: 'Referrer Reward', prefix: 'FC' },
              { key: 'referee_reward', label: 'Referee Reward', prefix: 'FC' },
              { key: 'max_referrals_per_user', label: 'Max Referrals/User', prefix: '' },
              { key: 'min_rides_to_qualify', label: 'Min. Rides to Qualify', prefix: '' },
            ].map(({ key, label, prefix }) => (
              <div key={key}>
                <label className="text-[10px] uppercase tracking-widest text-slate-500 mb-1 block">{label}</label>
                {editingConfig ? (
                  <input
                    type="number"
                    value={tempConfig[key] ?? ''}
                    onChange={(e) => setTempConfig((c) => ({ ...c, [key]: Number(e.target.value) }))}
                    className="w-full bg-dark-bg border border-dark-border rounded-xl px-3 py-2 text-sm text-slate-700 outline-none focus:border-primary/50"
                  />
                ) : (
                  <p className="text-sm font-semibold text-slate-900">
                    {prefix && <span className="text-slate-500 mr-1">{prefix}</span>}
                    {config[key]?.toLocaleString()}
                  </p>
                )}
              </div>
            ))}
          </div>
          {editingConfig && (
            <button onClick={() => { setEditingConfig(false); setTempConfig(config); }}
              className="w-full mt-3 py-2 rounded-xl text-sm text-slate-500 bg-dark-bg border border-dark-border hover:text-slate-800 transition-colors">
              Cancel
            </button>
          )}
        </div>
      </div>
    </div>
  );
}
