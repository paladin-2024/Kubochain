import React, { useState, useEffect, useCallback } from 'react';
import {
  Search01Icon,
  Cancel01Icon,
  Refresh01Icon,
  FileDownloadIcon,
  CancelCircleIcon,
} from 'hugeicons-react';
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
  const [cancelling, setCancelling] = useState(null);

  const fetchRides = useCallback(async () => {
    setLoading(true);
    try {
      const params = new URLSearchParams({ page, limit: 20 });
      if (status !== 'all') params.append('status', status);
      if (search) params.append('search', search);
      const res = await api.get(`/admin/rides?${params}`);
      setRides(res.data.rides || []);
      setTotal(res.data.total || 0);
    } catch {}
    setLoading(false);
  }, [status, page, search]);

  useEffect(() => {
    const t = setTimeout(fetchRides, search ? 300 : 0);
    return () => clearTimeout(t);
  }, [fetchRides]);

  const handleCancel = async (rideId) => {
    if (!window.confirm('Cancel this ride?')) return;
    setCancelling(rideId);
    try {
      await api.patch(`/admin/rides/${rideId}/cancel`);
      setRides((prev) => prev.map((r) => r._id === rideId ? { ...r, status: 'cancelled' } : r));
    } catch (err) {
      alert(err?.response?.data?.message || 'Failed to cancel ride');
    } finally {
      setCancelling(null);
    }
  };

  const exportCSV = () => {
    const headers = ['Passenger', 'Pickup', 'Destination', 'Driver', 'Status', 'Fare', 'Date'];
    const rows = rides.map((r) => [
      r.passenger ? `${r.passenger.firstName} ${r.passenger.lastName}` : '',
      r.pickup?.address || '',
      r.destination?.address || '',
      r.driver?.user ? `${r.driver.user.firstName} ${r.driver.user.lastName}` : '',
      r.status || '',
      r.price || 0,
      r.createdAt ? new Date(r.createdAt).toLocaleString() : '',
    ]);
    const csv = [headers, ...rows].map((row) => row.map((c) => `"${c}"`).join(',')).join('\n');
    const url = URL.createObjectURL(new Blob([csv], { type: 'text/csv' }));
    const a = document.createElement('a');
    a.href = url;
    a.download = `rides-${status}-${new Date().toISOString().slice(0, 10)}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  };

  const activeStatuses = new Set(['pending', 'accepted', 'arriving', 'in_progress']);

  return (
    <div className="p-6 space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="font-heading text-slate-900 text-2xl font-bold">Rides</h1>
          <p className="text-slate-500 text-sm">Manage and track all ride activity</p>
        </div>
        <button
          onClick={exportCSV}
          className="flex items-center gap-2 px-4 py-2 bg-dark-card border border-dark-border rounded-xl text-sm text-slate-500 hover:border-primary/50 hover:text-slate-800 transition-all"
        >
          <FileDownloadIcon size={14} /> Export CSV
        </button>
      </div>

      {/* Search */}
      <div className="relative">
        <Search01Icon size={16} className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-500 pointer-events-none" />
        <input
          type="text"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="Search by passenger, driver or address…"
          className="w-full bg-dark-card border border-dark-border rounded-xl pl-11 pr-10 py-3 text-slate-800 placeholder-slate-400 focus:outline-none focus:border-primary transition-colors"
        />
        {search && (
          <button onClick={() => setSearch('')} className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-500 hover:text-slate-800">
            <Cancel01Icon size={14} />
          </button>
        )}
      </div>

      {/* Filters */}
      <div className="flex flex-wrap items-center gap-2">
        {STATUSES.map((s) => (
          <button
            key={s}
            onClick={() => { setStatus(s); setPage(1); }}
            className={`px-4 py-2 rounded-xl text-sm font-medium capitalize transition-all ${
              status === s
                ? 'bg-primary text-white'
                : 'bg-dark-card border border-dark-border text-slate-500 hover:text-slate-800 hover:border-primary/40'
            }`}
          >
            {s === 'all' ? 'All Rides' : s.replace('_', ' ')}
          </button>
        ))}
        <div className="ml-auto text-slate-500 text-sm">
          {total.toLocaleString()} total
        </div>
      </div>

      {/* Table */}
      <div className="bg-dark-card border border-dark-border rounded-2xl overflow-hidden">
        {loading ? (
          <div className="flex items-center justify-center py-16 gap-3 text-slate-500">
            <Refresh01Icon size={20} className="animate-spin" />
            Loading rides…
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-dark-border text-slate-500 text-xs uppercase tracking-wide">
                  <th className="text-left py-3 px-4">Passenger</th>
                  <th className="text-left py-3 px-4">Pickup</th>
                  <th className="text-left py-3 px-4">Destination</th>
                  <th className="text-left py-3 px-4">Driver</th>
                  <th className="text-left py-3 px-4">Status</th>
                  <th className="text-right py-3 px-4">Fare</th>
                  <th className="text-right py-3 px-4">Date</th>
                  <th className="text-center py-3 px-4">Actions</th>
                </tr>
              </thead>
              <tbody>
                {rides.map((ride) => (
                  <tr key={ride._id} className="border-b border-dark-border/50 hover:bg-slate-50 transition-colors">
                    <td className="py-3 px-4">
                      <div className="font-medium text-slate-800">
                        {ride.passenger ? `${ride.passenger.firstName} ${ride.passenger.lastName}` : '—'}
                      </div>
                      <div className="text-slate-500 text-xs">{ride.passenger?.phone}</div>
                    </td>
                    <td className="py-3 px-4">
                      <div className="text-slate-600 max-w-[130px] truncate">{ride.pickup?.address?.split(',')[0]}</div>
                    </td>
                    <td className="py-3 px-4">
                      <div className="text-slate-600 max-w-[130px] truncate">{ride.destination?.address?.split(',')[0]}</div>
                    </td>
                    <td className="py-3 px-4">
                      {ride.driver?.user ? (
                        <div>
                          <div className="font-medium text-slate-800">
                            {ride.driver.user.firstName} {ride.driver.user.lastName}
                          </div>
                          <div className="text-slate-500 text-xs">{ride.driver.vehicle?.plateNumber}</div>
                        </div>
                      ) : (
                        <span className="text-slate-500">Unassigned</span>
                      )}
                    </td>
                    <td className="py-3 px-4">
                      <span className={`px-2.5 py-1 rounded-full text-xs font-semibold badge-${ride.status}`}>
                        {ride.status?.replace('_', ' ')}
                      </span>
                    </td>
                    <td className="py-3 px-4 text-right font-semibold text-slate-900">
                      FC {ride.price?.toLocaleString()}
                    </td>
                    <td className="py-3 px-4 text-right text-slate-500 text-xs">
                      {ride.createdAt ? new Date(ride.createdAt).toLocaleString('en-US', { dateStyle: 'short', timeStyle: 'short' }) : '—'}
                    </td>
                    <td className="py-3 px-4 text-center">
                      {activeStatuses.has(ride.status) ? (
                        <button
                          onClick={() => handleCancel(ride._id)}
                          disabled={cancelling === ride._id}
                          className="flex items-center gap-1 px-3 py-1.5 bg-danger/10 text-danger border border-danger/20 rounded-lg text-xs hover:bg-danger/20 transition-colors disabled:opacity-50 mx-auto"
                        >
                          <CancelCircleIcon size={12} />
                          {cancelling === ride._id ? '…' : 'Cancel'}
                        </button>
                      ) : (
                        <span className="text-gray-700 text-xs">—</span>
                      )}
                    </td>
                  </tr>
                ))}
                {rides.length === 0 && (
                  <tr>
                    <td colSpan={8} className="text-center py-16 text-slate-500">No rides found</td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Pagination */}
      {total > 20 && (
        <div className="flex items-center justify-center gap-3">
          <button
            onClick={() => setPage((p) => Math.max(1, p - 1))}
            disabled={page === 1}
            className="px-4 py-2 bg-dark-card border border-dark-border rounded-xl text-sm text-slate-500 hover:text-slate-800 disabled:opacity-40 transition-all"
          >
            Previous
          </button>
          <span className="text-slate-500 text-sm">Page {page} of {Math.ceil(total / 20)}</span>
          <button
            onClick={() => setPage((p) => p + 1)}
            disabled={page >= Math.ceil(total / 20)}
            className="px-4 py-2 bg-dark-card border border-dark-border rounded-xl text-sm text-slate-500 hover:text-slate-800 disabled:opacity-40 transition-all"
          >
            Next
          </button>
        </div>
      )}
    </div>
  );
}
