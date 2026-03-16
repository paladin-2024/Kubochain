import React, { useState, useEffect } from 'react';
import api from '../config/api';
import RideTable from '../components/RideTable';

const STATUSES = ['all', 'pending', 'accepted', 'arriving', 'in_progress', 'completed', 'cancelled'];

export default function Rides() {
  const [rides, setRides] = useState([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [status, setStatus] = useState('all');
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');

  const fetchRides = async () => {
    setLoading(true);
    try {
      const params = new URLSearchParams({ page, limit: 20 });
      if (status !== 'all') params.append('status', status);
      const res = await api.get(`/admin/rides?${params}`);
      setRides(res.data.rides || []);
      setTotal(res.data.total || 0);
    } catch {}
    setLoading(false);
  };

  useEffect(() => { fetchRides(); }, [status, page]);

  return (
    <div className="p-6 space-y-6">
      <div>
        <h1 className="text-white text-2xl font-bold">Rides</h1>
        <p className="text-gray-400 text-sm">Manage and track all ride activity</p>
      </div>

      {/* Filters */}
      <div className="flex flex-wrap items-center gap-3">
        {STATUSES.map((s) => (
          <button
            key={s}
            onClick={() => { setStatus(s); setPage(1); }}
            className={`px-4 py-2 rounded-xl text-sm font-medium capitalize transition-all ${
              status === s
                ? 'bg-primary text-white'
                : 'bg-dark-card border border-dark-border text-gray-400 hover:text-white hover:border-primary/40'
            }`}
          >
            {s === 'all' ? 'All Rides' : s.replace('_', ' ')}
          </button>
        ))}
        <div className="ml-auto text-gray-400 text-sm">
          {total.toLocaleString()} total rides
        </div>
      </div>

      {/* Table */}
      <div className="bg-dark-card border border-dark-border rounded-2xl overflow-hidden">
        {loading ? (
          <div className="text-center py-16 text-gray-400">
            <div className="animate-spin text-3xl mb-3">⟳</div>
            Loading rides...
          </div>
        ) : (
          <RideTable rides={rides} />
        )}
      </div>

      {/* Pagination */}
      {total > 20 && (
        <div className="flex items-center justify-center gap-3">
          <button
            onClick={() => setPage((p) => Math.max(1, p - 1))}
            disabled={page === 1}
            className="px-4 py-2 bg-dark-card border border-dark-border rounded-xl text-sm text-gray-400 hover:text-white disabled:opacity-40 transition-all"
          >
            ← Previous
          </button>
          <span className="text-gray-400 text-sm">Page {page} of {Math.ceil(total / 20)}</span>
          <button
            onClick={() => setPage((p) => p + 1)}
            disabled={page >= Math.ceil(total / 20)}
            className="px-4 py-2 bg-dark-card border border-dark-border rounded-xl text-sm text-gray-400 hover:text-white disabled:opacity-40 transition-all"
          >
            Next →
          </button>
        </div>
      )}
    </div>
  );
}
