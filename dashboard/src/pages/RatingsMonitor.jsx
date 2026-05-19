import React, { useState, useEffect } from 'react';
import {
  StarIcon, StarCircleIcon, StarHalfIcon, UserCheck01Icon, UserGroupIcon,
  Flag01Icon, EyeIcon, CheckmarkCircle01Icon, Motorbike01Icon, ChartUpIcon,
  ChartDownIcon, Search01Icon, Cancel01Icon, FilterIcon,
} from 'hugeicons-react';
import api from '../config/api';

const MOCK_REVIEWS = [
  { id: 'r1', type: 'driver', subject: 'Jean-Pierre Bauma', reviewer: 'Marie Kavira', rating: 5, comment: 'Excellent service, very professional', ride_id: 'RD-4521', flagged: false, created_at: '2025-05-17T15:00:00Z' },
  { id: 'r2', type: 'driver', subject: 'Patrick Nkosi', reviewer: 'Alain T.', rating: 1, comment: 'Driver was rude and drove very fast', ride_id: 'RD-4510', flagged: true, created_at: '2025-05-17T13:45:00Z' },
  { id: 'r3', type: 'passenger', subject: 'Sophie M.', reviewer: 'Grace A.', rating: 2, comment: 'Passenger refused to wear helmet', ride_id: 'RD-4498', flagged: false, created_at: '2025-05-17T12:30:00Z' },
  { id: 'r4', type: 'driver', subject: 'Sylvie Nzigire', reviewer: 'Christian A.', rating: 4, comment: 'Good driver, knew the city well', ride_id: 'RD-4490', flagged: false, created_at: '2025-05-17T11:00:00Z' },
  { id: 'r5', type: 'driver', subject: 'Rodrigue Mwamba', reviewer: 'Esther B.', rating: 1, comment: 'Cancelled 3 times before finally arriving', ride_id: 'RD-4485', flagged: true, created_at: '2025-05-17T10:15:00Z' },
  { id: 'r6', type: 'passenger', subject: 'Jean-Louis K.', reviewer: 'Jean-Pierre B.', rating: 5, comment: 'Great passenger, very respectful', ride_id: 'RD-4480', flagged: false, created_at: '2025-05-17T09:00:00Z' },
];

const MOCK_STATS = {
  avg_driver_rating: 4.2,
  avg_passenger_rating: 4.6,
  flagged_count: 2,
  reviews_today: 12,
};

function Stars({ value }) {
  return (
    <div className="flex items-center gap-0.5">
      {[1, 2, 3, 4, 5].map((i) => (
        <StarIcon
          key={i}
          size={14}
          className={i <= value ? 'text-warning' : 'text-gray-700'}
        />
      ))}
    </div>
  );
}

export default function RatingsMonitor() {
  const [reviews, setReviews] = useState(MOCK_REVIEWS);
  const [stats, setStats] = useState(MOCK_STATS);
  const [typeFilter, setTypeFilter] = useState('all');
  const [flaggedOnly, setFlaggedOnly] = useState(false);
  const [search, setSearch] = useState('');

  useEffect(() => {
    Promise.all([
      api.get('/admin/ratings').catch(() => ({ data: null })),
      api.get('/admin/ratings/stats').catch(() => ({ data: null })),
    ]).then(([rRes, sRes]) => {
      if (rRes.data?.length) setReviews(rRes.data);
      if (sRes.data) setStats(sRes.data);
    });
  }, []);

  const flagReview = async (id) => {
    try { await api.patch(`/admin/ratings/${id}/flag`); } catch {}
    setReviews((prev) => prev.map((r) => (r.id === id ? { ...r, flagged: !r.flagged } : r)));
  };

  const deleteReview = async (id) => {
    try { await api.delete(`/admin/ratings/${id}`); } catch {}
    setReviews((prev) => prev.filter((r) => r.id !== id));
  };

  const filtered = reviews.filter((r) => {
    if (typeFilter !== 'all' && r.type !== typeFilter) return false;
    if (flaggedOnly && !r.flagged) return false;
    if (search && !r.subject.toLowerCase().includes(search.toLowerCase()) && !r.reviewer.toLowerCase().includes(search.toLowerCase())) return false;
    return true;
  });

  return (
    <div className="p-6 space-y-6">
      <div className="flex items-center justify-between flex-wrap gap-4">
        <div>
          <h1 className="font-heading font-bold text-slate-900 text-2xl">Ratings Monitor</h1>
          <p className="text-slate-500 text-sm mt-0.5">Review ratings and manage feedback quality</p>
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        {[
          { label: 'Avg Driver Rating', value: stats.avg_driver_rating?.toFixed(1), icon: Motorbike01Icon, color: 'text-primary', suffix: '/ 5' },
          { label: 'Avg Passenger Rating', value: stats.avg_passenger_rating?.toFixed(1), icon: UserGroupIcon, color: 'text-success', suffix: '/ 5' },
          { label: 'Flagged Reviews', value: stats.flagged_count, icon: Flag01Icon, color: 'text-danger', suffix: '' },
          { label: 'Reviews Today', value: stats.reviews_today, icon: StarCircleIcon, color: 'text-warning', suffix: '' },
        ].map(({ label, value, icon: Icon, color, suffix }) => (
          <div key={label} className="bg-dark-card border border-dark-border rounded-2xl p-4">
            <div className="flex items-center gap-2 mb-2"><Icon size={15} className={color} /><span className="text-xs text-slate-500">{label}</span></div>
            <p className={`font-heading font-bold text-2xl ${color}`}>{value} <span className="text-sm text-slate-500">{suffix}</span></p>
          </div>
        ))}
      </div>

      {/* Filters */}
      <div className="flex flex-wrap items-center gap-3">
        <div className="flex items-center gap-2 bg-dark-card border border-dark-border rounded-xl px-3 py-2 flex-1 min-w-[200px] max-w-xs">
          <Search01Icon size={15} className="text-slate-500" />
          <input value={search} onChange={(e) => setSearch(e.target.value)} placeholder="Search..." className="bg-transparent text-sm text-slate-800 placeholder-slate-400 flex-1 outline-none" />
          {search && <button onClick={() => setSearch('')}><Cancel01Icon size={13} className="text-slate-500" /></button>}
        </div>
        <div className="flex bg-dark-card border border-dark-border rounded-xl p-1 gap-1">
          {['all', 'driver', 'passenger'].map((t) => (
            <button key={t} onClick={() => setTypeFilter(t)} className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition-all ${typeFilter === t ? 'bg-primary text-white' : 'text-slate-500 hover:text-slate-800'}`}>
              {t.charAt(0).toUpperCase() + t.slice(1)}
            </button>
          ))}
        </div>
        <button
          onClick={() => setFlaggedOnly((v) => !v)}
          className={`flex items-center gap-2 px-3 py-2 rounded-xl text-sm font-semibold border transition-colors ${flaggedOnly ? 'bg-danger/10 text-danger border-danger/30' : 'bg-dark-card text-slate-500 border-dark-border hover:text-slate-800'}`}
        >
          <Flag01Icon size={14} />
          Flagged Only
        </button>
      </div>

      {/* Reviews */}
      <div className="space-y-3">
        {filtered.map((r) => (
          <div key={r.id} className={`bg-dark-card border rounded-2xl p-4 ${r.flagged ? 'border-danger/30' : 'border-dark-border'}`}>
            <div className="flex items-start justify-between gap-3">
              <div className="flex items-start gap-3">
                <div className={`w-10 h-10 rounded-full border flex items-center justify-center flex-shrink-0 ${
                  r.type === 'driver' ? 'bg-orange/10 border-orange/30' : 'bg-success/10 border-success/30'
                }`}>
                  {r.type === 'driver' ? <Motorbike01Icon size={16} className="text-orange" /> : <UserGroupIcon size={16} className="text-success" />}
                </div>
                <div>
                  <div className="flex items-center gap-2 flex-wrap">
                    <span className="font-medium text-slate-800 text-sm">{r.subject}</span>
                    <Stars value={r.rating} />
                    {r.flagged && (
                      <span className="text-[10px] font-bold px-1.5 py-0.5 rounded-md bg-danger/10 text-danger border border-danger/20">FLAGGED</span>
                    )}
                  </div>
                  <p className="text-xs text-slate-500 mt-0.5">By {r.reviewer} · <a href={`/rides/${r.ride_id}`} className="text-primary hover:underline">{r.ride_id}</a></p>
                  <p className="text-sm text-slate-600 mt-1.5 leading-relaxed">"{r.comment}"</p>
                </div>
              </div>
              <div className="flex items-center gap-1.5 flex-shrink-0">
                <button
                  onClick={() => flagReview(r.id)}
                  className={`p-1.5 rounded-lg transition-colors ${r.flagged ? 'text-danger hover:text-slate-500' : 'text-slate-500 hover:text-danger hover:bg-danger/10'}`}
                >
                  <Flag01Icon size={14} />
                </button>
                <button onClick={() => deleteReview(r.id)} className="p-1.5 rounded-lg text-slate-500 hover:text-danger hover:bg-danger/10 transition-colors">
                  <Cancel01Icon size={14} />
                </button>
                <span className="text-xs text-slate-500">{new Date(r.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</span>
              </div>
            </div>
          </div>
        ))}
        {filtered.length === 0 && (
          <div className="py-16 text-center text-slate-500">No reviews found</div>
        )}
      </div>
    </div>
  );
}
