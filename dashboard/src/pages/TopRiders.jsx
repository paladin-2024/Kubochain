import React, { useState, useEffect, useCallback } from 'react';
import {
  Award01Icon,
  StarIcon,
  Motorbike01Icon,
  ChartUpIcon,
  UserGroupIcon,
  Refresh01Icon,
  Award02Icon,
  CrownIcon,
} from 'hugeicons-react';
import api from '../config/api';
import Avatar from '../components/Avatar';

const SORT_OPTIONS = [
  { value: 'rating',   label: 'Rating',   icon: StarIcon },
  { value: 'trips',    label: 'Trips',    icon: Motorbike01Icon },
  { value: 'earnings', label: 'Earnings', icon: ChartUpIcon },
];

const MEDAL_STYLES = [
  { color: '#FFD700', bg: 'rgba(255,215,0,0.12)', border: 'rgba(255,215,0,0.3)', label: '1st' },
  { color: '#C0C0C0', bg: 'rgba(192,192,192,0.1)', border: 'rgba(192,192,192,0.3)', label: '2nd' },
  { color: '#CD7F32', bg: 'rgba(205,127,50,0.1)', border: 'rgba(205,127,50,0.3)', label: '3rd' },
];

export default function TopRiders() {
  const [riders, setRiders] = useState([]);
  const [loading, setLoading] = useState(true);
  const [sortBy, setSortBy] = useState('rating');
  const [error, setError] = useState('');

  const load = useCallback(async (sort = sortBy) => {
    setLoading(true);
    setError('');
    try {
      const res = await api.get(`/admin/top-riders?limit=50&sort=${sort}`);
      setRiders(res.data.riders || []);
    } catch {
      setError('Failed to load top riders');
    } finally {
      setLoading(false);
    }
  }, [sortBy]);

  useEffect(() => { load(sortBy); }, [sortBy]);

  const handleSort = (v) => { setSortBy(v); load(v); };

  const top3 = riders.slice(0, 3);
  const rest = riders.slice(3);

  return (
    <div className="min-h-screen p-6 space-y-6">
      {/* Header */}
      <div className="flex items-start justify-between">
        <div>
          <div className="flex items-center gap-3 mb-1">
            <div className="w-10 h-10 rounded-xl bg-yellow-500/10 border border-yellow-500/20 flex items-center justify-center">
              <Award01Icon size={20} className="text-yellow-500" />
            </div>
            <h1 className="font-heading text-2xl font-bold text-slate-900 tracking-tight">Top Riders</h1>
          </div>
          <p className="text-slate-500 text-sm ml-13">Leaderboard based on passenger ratings</p>
        </div>
        <button
          onClick={() => load(sortBy)}
          className="flex items-center gap-2 px-4 py-2 bg-white border border-dark-border rounded-xl text-slate-500 hover:text-slate-800 hover:bg-slate-50 transition-colors text-sm"
        >
          <Refresh01Icon size={14} className={loading ? 'animate-spin' : ''} />
          Refresh
        </button>
      </div>

      {/* Sort tabs */}
      <div className="flex gap-2">
        {SORT_OPTIONS.map((opt) => (
          <button
            key={opt.value}
            onClick={() => handleSort(opt.value)}
            className={`flex items-center gap-1.5 px-4 py-2 rounded-xl text-sm font-medium transition-all ${
              sortBy === opt.value
                ? 'bg-primary text-slate-800 shadow-md shadow-primary/20'
                : 'bg-white border border-dark-border text-slate-500 hover:text-slate-800 hover:bg-slate-50'
            }`}
          >
            <opt.icon size={13} />
            {opt.label}
          </button>
        ))}
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 rounded-xl p-4 text-red-600 text-sm">{error}</div>
      )}

      {loading ? (
        <div className="flex items-center justify-center py-32">
          <div className="w-8 h-8 border-2 border-primary border-t-transparent rounded-full animate-spin" />
        </div>
      ) : riders.length === 0 ? (
        <div className="flex flex-col items-center justify-center py-32 text-slate-400">
          <Award01Icon size={56} className="mb-4 opacity-30" />
          <p className="text-lg font-semibold text-slate-700 mb-2">No ratings yet</p>
          <p className="text-sm text-center">Complete rides and rate riders to see the leaderboard.</p>
        </div>
      ) : (
        <>
          {/* Top 3 Podium */}
          {top3.length === 3 && (
            <div className="bg-white border border-dark-border rounded-2xl p-6">
              <div className="flex items-center gap-2 mb-6">
                <CrownIcon size={16} className="text-yellow-500" />
                <h2 className="font-heading text-sm font-semibold text-slate-500 uppercase tracking-wider">Podium</h2>
              </div>
              <div className="flex items-end justify-center gap-4">
                {[top3[1], top3[0], top3[2]].map((r, i) => {
                  const heights = [100, 130, 80];
                  const podiumMedals = [MEDAL_STYLES[1], MEDAL_STYLES[0], MEDAL_STYLES[2]];
                  const m = podiumMedals[i];
                  const firstName = (r.name || '').split(' ')[0];
                  return (
                    <div key={r.id} className="flex flex-col items-center flex-1">
                      <div className="mb-2" style={{ filter: `drop-shadow(0 0 8px ${m.color}70)` }}>
                        <Avatar name={r.name} size={56} ring />
                      </div>
                      <p className="text-xs font-semibold text-slate-700 mb-1 truncate max-w-[80px] text-center">{firstName}</p>
                      <div className="flex items-center gap-1 mb-2">
                        <StarIcon size={11} color={m.color} />
                        <span className="text-xs font-bold" style={{ color: m.color }}>
                          {r.rating?.toFixed(1)}
                        </span>
                      </div>
                      <div
                        className="w-full rounded-t-lg flex items-center justify-center"
                        style={{
                          height: `${heights[i]}px`,
                          background: `linear-gradient(to bottom, ${m.color}25, ${m.color}08)`,
                          border: `1px solid ${m.color}40`,
                          borderBottom: 'none',
                        }}
                      >
                        <span className="text-xs font-bold font-heading" style={{ color: m.color }}>{m.label}</span>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          )}

          {/* Stats summary */}
          <div className="grid grid-cols-3 gap-4">
            {[
              { label: 'Rated Riders',  value: riders.length,
                icon: UserGroupIcon, color: '#2563EB' },
              { label: 'Avg Rating',    value: (riders.reduce((s, r) => s + r.rating, 0) / riders.length).toFixed(2),
                icon: StarIcon, color: '#D97706' },
              { label: 'Total Ratings', value: riders.reduce((s, r) => s + r.ratingCount, 0).toLocaleString(),
                icon: Award02Icon, color: '#16A34A' },
            ].map((s) => (
              <div key={s.label} className="bg-white border border-dark-border rounded-xl p-4 flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl flex items-center justify-center" style={{ background: `${s.color}18`, border: `1px solid ${s.color}30` }}>
                  <s.icon size={18} color={s.color} />
                </div>
                <div>
                  <p className="font-heading text-lg font-bold text-slate-900">{s.value}</p>
                  <p className="text-xs text-slate-500">{s.label}</p>
                </div>
              </div>
            ))}
          </div>

          {/* Full leaderboard table */}
          <div className="bg-white border border-dark-border rounded-2xl overflow-hidden">
            <div className="px-6 py-4 border-b border-dark-border">
              <h2 className="font-heading text-sm font-semibold text-slate-500 uppercase tracking-wider">
                Full Leaderboard — {riders.length} riders
              </h2>
            </div>
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-dark-border bg-slate-50">
                    {['Rank', 'Rider', 'Rating', 'Ratings', 'Trips', 'Top Star', 'Tags', 'Status'].map((h) => (
                      <th key={h} className="px-4 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider">{h}</th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {riders.map((r, i) => {
                    const m = i < 3 ? MEDAL_STYLES[i] : null;
                    return (
                      <tr key={r.id} className="border-b border-dark-border/60 hover:bg-slate-50 transition-colors">
                        <td className="px-4 py-4">
                          <div
                            className="w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold font-heading"
                            style={m
                              ? { background: m.bg, border: `1px solid ${m.border}`, color: m.color }
                              : { background: '#F1F5F9', color: '#64748B' }}
                          >
                            {m ? m.label.replace('st','').replace('nd','').replace('rd','') : `${i + 1}`}
                          </div>
                        </td>
                        <td className="px-4 py-4">
                          <div className="flex items-center gap-3">
                            <Avatar name={r.name} size={36} />
                            <div>
                              <p className="text-sm font-semibold text-slate-800">{r.name}</p>
                              <p className="text-xs text-slate-500">{r.vehicle || 'Motorcycle'}</p>
                            </div>
                          </div>
                        </td>
                        <td className="px-4 py-4">
                          <div className="flex items-center gap-1.5">
                            <StarIcon size={14} color="#D97706" />
                            <span className="text-sm font-bold text-amber-600">{r.rating?.toFixed(2)}</span>
                          </div>
                        </td>
                        <td className="px-4 py-4">
                          <span className="text-sm text-slate-700">{r.ratingCount}</span>
                        </td>
                        <td className="px-4 py-4">
                          <span className="text-sm text-slate-700">{r.totalRides}</span>
                        </td>
                        <td className="px-4 py-4">
                          <div className="flex items-center gap-1">
                            <StarIcon size={11} color="#D97706" />
                            <span className="text-xs font-bold text-amber-600">{r.fiveStarCount}</span>
                          </div>
                        </td>
                        <td className="px-4 py-4">
                          <div className="flex flex-wrap gap-1 max-w-[160px]">
                            {(r.topTags || []).slice(0, 2).map((tag) => (
                              <span key={tag} className="text-xs px-2 py-0.5 rounded-full bg-primary/10 border border-primary/20 text-primary">
                                {tag}
                              </span>
                            ))}
                          </div>
                        </td>
                        <td className="px-4 py-4">
                          <div className="flex items-center gap-1.5">
                            <div className={`w-2 h-2 rounded-full ${r.isOnline ? 'bg-success' : 'bg-slate-300'}`} />
                            <span className={`text-xs ${r.isOnline ? 'text-success' : 'text-slate-400'}`}>
                              {r.isOnline ? 'Online' : 'Offline'}
                            </span>
                          </div>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </div>
        </>
      )}
    </div>
  );
}
