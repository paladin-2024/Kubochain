import React, { useState, useEffect, useCallback } from 'react';
import { Trophy, Star, Bike, TrendingUp, Users, RefreshCw, Award, Zap } from 'lucide-react';
import api from '../config/api';

const SORT_OPTIONS = [
  { value: 'rating',   label: '⭐ Rating',   icon: Star },
  { value: 'trips',    label: '🚀 Trips',    icon: Bike },
  { value: 'earnings', label: '💰 Earnings', icon: TrendingUp },
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
    } catch (e) {
      setError('Failed to load top riders');
    } finally {
      setLoading(false);
    }
  }, [sortBy]);

  useEffect(() => { load(sortBy); }, [sortBy]);

  const handleSort = (v) => { setSortBy(v); load(v); };

  const medal = (rank) => {
    if (rank === 1) return { color: '#FFD700', label: '🥇', bg: 'rgba(255,215,0,0.12)', border: 'rgba(255,215,0,0.3)' };
    if (rank === 2) return { color: '#C0C0C0', label: '🥈', bg: 'rgba(192,192,192,0.1)', border: 'rgba(192,192,192,0.3)' };
    if (rank === 3) return { color: '#CD7F32', label: '🥉', bg: 'rgba(205,127,50,0.1)', border: 'rgba(205,127,50,0.3)' };
    return null;
  };

  const top3 = riders.slice(0, 3);
  const rest = riders.slice(3);

  return (
    <div className="min-h-screen bg-[#080D18] p-6 space-y-6">
      {/* Header */}
      <div className="flex items-start justify-between">
        <div>
          <div className="flex items-center gap-3 mb-1">
            <div className="w-10 h-10 rounded-xl bg-yellow-500/10 border border-yellow-500/20 flex items-center justify-center">
              <Trophy size={20} className="text-yellow-400" />
            </div>
            <h1 className="text-2xl font-bold text-white" style={{ fontFamily: 'Sora, sans-serif', letterSpacing: '-0.5px' }}>
              Top Riders
            </h1>
          </div>
          <p className="text-[#8899AA] text-sm ml-13">Leaderboard based on passenger ratings</p>
        </div>
        <button
          onClick={() => load(sortBy)}
          className="flex items-center gap-2 px-4 py-2 bg-[#141F33] border border-[#1E2E45] rounded-xl text-[#8899AA] hover:text-white transition-colors text-sm"
        >
          <RefreshCw size={14} className={loading ? 'animate-spin' : ''} />
          Refresh
        </button>
      </div>

      {/* Sort tabs */}
      <div className="flex gap-2">
        {SORT_OPTIONS.map((opt) => (
          <button
            key={opt.value}
            onClick={() => handleSort(opt.value)}
            className={`px-4 py-2 rounded-xl text-sm font-medium transition-all ${
              sortBy === opt.value
                ? 'bg-gradient-to-r from-[#2F80ED] to-[#1A5BB8] text-white shadow-lg'
                : 'bg-[#141F33] border border-[#1E2E45] text-[#8899AA] hover:text-white'
            }`}
          >
            {opt.label}
          </button>
        ))}
      </div>

      {error && (
        <div className="bg-red-900/20 border border-red-800/40 rounded-xl p-4 text-red-400 text-sm">{error}</div>
      )}

      {loading ? (
        <div className="flex items-center justify-center py-32">
          <div className="w-8 h-8 border-2 border-[#2F80ED] border-t-transparent rounded-full animate-spin" />
        </div>
      ) : riders.length === 0 ? (
        <div className="flex flex-col items-center justify-center py-32 text-[#8899AA]">
          <Trophy size={56} className="mb-4 opacity-30" />
          <p className="text-lg font-semibold text-white mb-2">No ratings yet</p>
          <p className="text-sm text-center">Complete rides and rate riders<br />to see the leaderboard.</p>
        </div>
      ) : (
        <>
          {/* Top 3 Podium */}
          {top3.length === 3 && (
            <div className="bg-[#111B2E] border border-[#1E2E45] rounded-2xl p-6">
              <h2 className="text-sm font-semibold text-[#8899AA] uppercase tracking-wider mb-6">🏆 Podium</h2>
              <div className="flex items-end justify-center gap-4">
                {[top3[1], top3[0], top3[2]].map((r, i) => {
                  const heights = [100, 130, 80];
                  const medals = [
                    { color: '#C0C0C0', label: '2nd', glow: 'rgba(192,192,192,0.3)' },
                    { color: '#FFD700', label: '1st', glow: 'rgba(255,215,0,0.4)' },
                    { color: '#CD7F32', label: '3rd', glow: 'rgba(205,127,50,0.3)' },
                  ];
                  const m = medals[i];
                  const firstName = (r.name || '').split(' ')[0];
                  return (
                    <div key={r.id} className="flex flex-col items-center flex-1">
                      <div
                        className="w-14 h-14 rounded-full flex items-center justify-center text-xl font-bold text-white mb-2"
                        style={{
                          background: `linear-gradient(135deg, ${m.color}, ${m.color}99)`,
                          boxShadow: `0 0 20px ${m.glow}`,
                        }}
                      >
                        {firstName?.[0] || '?'}
                      </div>
                      <p className="text-xs font-semibold text-white mb-1 truncate max-w-[80px] text-center">{firstName}</p>
                      <div className="flex items-center gap-1 mb-2">
                        <Star size={11} style={{ color: m.color }} fill={m.color} />
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
                        <span className="text-xs font-bold" style={{ color: m.color }}>{m.label}</span>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          )}

          {/* Stats summary bar */}
          <div className="grid grid-cols-3 gap-4">
            {[
              { label: 'Rated Riders', value: riders.length, icon: Users, color: '#2F80ED' },
              { label: 'Avg Rating', value: (riders.reduce((s, r) => s + r.rating, 0) / riders.length).toFixed(2), icon: Star, color: '#FFD700' },
              { label: 'Total Ratings', value: riders.reduce((s, r) => s + r.ratingCount, 0).toLocaleString(), icon: Award, color: '#00C896' },
            ].map((s) => (
              <div key={s.label} className="bg-[#111B2E] border border-[#1E2E45] rounded-xl p-4 flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl flex items-center justify-center" style={{ background: `${s.color}18`, border: `1px solid ${s.color}30` }}>
                  <s.icon size={18} style={{ color: s.color }} />
                </div>
                <div>
                  <p className="text-lg font-bold text-white">{s.value}</p>
                  <p className="text-xs text-[#8899AA]">{s.label}</p>
                </div>
              </div>
            ))}
          </div>

          {/* Full table */}
          <div className="bg-[#111B2E] border border-[#1E2E45] rounded-2xl overflow-hidden">
            <div className="px-6 py-4 border-b border-[#1E2E45]">
              <h2 className="text-sm font-semibold text-[#8899AA] uppercase tracking-wider">
                Full Leaderboard · {riders.length} riders
              </h2>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-[#1E2E45]">
                    {['Rank', 'Rider', 'Rating', 'Ratings', 'Trips', '5-Star', 'Tags', 'Status'].map((h) => (
                      <th key={h} className="px-4 py-3 text-left text-xs font-semibold text-[#8899AA] uppercase tracking-wider">{h}</th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {riders.map((r, i) => {
                    const m = medal(i + 1);
                    return (
                      <tr key={r.id} className="border-b border-[#1E2E45]/50 hover:bg-[#141F33] transition-colors">
                        {/* Rank */}
                        <td className="px-4 py-4">
                          <div
                            className="w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold"
                            style={m
                              ? { background: m.bg, border: `1px solid ${m.border}`, color: m.color }
                              : { background: '#1E2E45', color: '#8899AA' }}
                          >
                            {m ? m.label : `#${i + 1}`}
                          </div>
                        </td>

                        {/* Rider */}
                        <td className="px-4 py-4">
                          <div className="flex items-center gap-3">
                            <div className="w-9 h-9 rounded-full bg-gradient-to-br from-[#2F80ED] to-[#1A5BB8] flex items-center justify-center text-sm font-bold text-white flex-shrink-0">
                              {(r.name || '?')[0]}
                            </div>
                            <div>
                              <p className="text-sm font-semibold text-white">{r.name}</p>
                              <p className="text-xs text-[#8899AA]">{r.vehicle || 'Motorcycle'}</p>
                            </div>
                          </div>
                        </td>

                        {/* Rating */}
                        <td className="px-4 py-4">
                          <div className="flex items-center gap-1.5">
                            <Star size={14} fill="#FFD700" className="text-yellow-400" />
                            <span className="text-sm font-bold text-yellow-400">{r.rating?.toFixed(2)}</span>
                          </div>
                        </td>

                        {/* Rating count */}
                        <td className="px-4 py-4">
                          <span className="text-sm text-[#EDF2FF]">{r.ratingCount}</span>
                        </td>

                        {/* Trips */}
                        <td className="px-4 py-4">
                          <span className="text-sm text-[#EDF2FF]">{r.totalRides}</span>
                        </td>

                        {/* 5-star count */}
                        <td className="px-4 py-4">
                          <div className="flex items-center gap-1">
                            <Star size={11} fill="#FFD700" className="text-yellow-400" />
                            <span className="text-xs font-bold text-yellow-400">{r.fiveStarCount}</span>
                          </div>
                        </td>

                        {/* Tags */}
                        <td className="px-4 py-4">
                          <div className="flex flex-wrap gap-1 max-w-[160px]">
                            {(r.topTags || []).slice(0, 2).map((tag) => (
                              <span key={tag} className="text-xs px-2 py-0.5 rounded-full bg-[#2F80ED]/10 border border-[#2F80ED]/20 text-[#2F80ED]">
                                {tag}
                              </span>
                            ))}
                          </div>
                        </td>

                        {/* Online */}
                        <td className="px-4 py-4">
                          <div className="flex items-center gap-1.5">
                            <div className={`w-2 h-2 rounded-full ${r.isOnline ? 'bg-[#00C896]' : 'bg-[#8899AA]'}`} />
                            <span className={`text-xs ${r.isOnline ? 'text-[#00C896]' : 'text-[#8899AA]'}`}>
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
