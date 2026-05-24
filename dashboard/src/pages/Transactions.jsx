import React, { useState, useEffect, useCallback } from 'react';
import {
  Invoice01Icon, CreditCardIcon, Coins01Icon, CheckmarkCircle01Icon, CancelCircleIcon,
  Clock01Icon, FileDownloadIcon, Search01Icon, Cancel01Icon, ArrowUp01Icon,
  ArrowDown01Icon, Money01Icon, FilterIcon,
} from 'hugeicons-react';
import api from '../config/api';

const STATUS_STYLES = {
  paid: 'text-success bg-success/10 border-success/20',
  completed: 'text-success bg-success/10 border-success/20',
  pending: 'text-warning bg-warning/10 border-warning/20',
  processing: 'text-blue-600 bg-blue-50 border-blue-200',
  refunded: 'text-danger bg-danger/10 border-danger/20',
  failed: 'text-slate-500 bg-slate-100 border-slate-200',
};

const MOCK_TXN = [
  { id: 'TXN-1001', rider: 'Marie Kavira', driver: 'Jean-Pierre B.', ride_id: 'RD-4521', amount: 6500, commission: 975, driver_earning: 5525, method: 'cash', status: 'completed', created_at: '2025-05-17T14:32:00Z' },
  { id: 'TXN-1000', rider: 'Alain T.', driver: 'Sylvie N.', ride_id: 'RD-4510', amount: 4800, commission: 720, driver_earning: 4080, method: 'mobile_money', status: 'completed', created_at: '2025-05-17T13:18:00Z' },
  { id: 'TXN-999', rider: 'Sophie M.', driver: 'Patrick N.', ride_id: 'RD-4498', amount: 8900, commission: 1335, driver_earning: 7565, method: 'cash', status: 'refunded', created_at: '2025-05-17T12:00:00Z' },
  { id: 'TXN-998', rider: 'Christian A.', driver: 'Grace A.', ride_id: 'RD-4490', amount: 5100, commission: 765, driver_earning: 4335, method: 'mobile_money', status: 'completed', created_at: '2025-05-17T11:40:00Z' },
  { id: 'TXN-997', rider: 'Esther B.', driver: 'Rodrigue M.', ride_id: 'RD-4485', amount: 3800, commission: 570, driver_earning: 3230, method: 'cash', status: 'pending', created_at: '2025-05-17T10:22:00Z' },
  { id: 'TXN-996', rider: 'Jean-Louis K.', driver: 'Jean-Pierre B.', ride_id: 'RD-4480', amount: 7200, commission: 1080, driver_earning: 6120, method: 'mobile_money', status: 'completed', created_at: '2025-05-17T09:15:00Z' },
];

export default function Transactions() {
  const [txns, setTxns] = useState(MOCK_TXN);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [methodFilter, setMethodFilter] = useState('all');
  const [page, setPage] = useState(1);

  const load = useCallback(() => {
    const params = new URLSearchParams({ page });
    if (statusFilter !== 'all') params.append('status', statusFilter);
    if (methodFilter !== 'all') params.append('method', methodFilter);
    if (search) params.append('search', search);
    api.get(`/admin/transactions?${params}`)
      .then((r) => { if (r.data) setTxns(r.data); })
      .catch(() => {});
  }, [page, statusFilter, methodFilter, search]);

  useEffect(() => { load(); }, [load]);

  const overrideStatus = async (rideId, newStatus) => {
    try {
      await api.patch(`/admin/payments/${rideId}/status`, { status: newStatus });
      setTxns((prev) => prev.map((t) => t.ride_id === rideId ? { ...t, status: newStatus } : t));
    } catch (e) {
      console.error('Override failed', e);
    }
  };

  const filtered = txns.filter((t) => {
    if (statusFilter !== 'all' && t.status !== statusFilter) return false;
    if (methodFilter !== 'all' && t.method !== methodFilter) return false;
    if (search && !t.rider.toLowerCase().includes(search.toLowerCase()) && !t.driver.toLowerCase().includes(search.toLowerCase()) && !t.id.toLowerCase().includes(search.toLowerCase())) return false;
    return true;
  });

  const totalRevenue = filtered.filter((t) => t.status === 'completed').reduce((a, t) => a + t.amount, 0);
  const totalCommission = filtered.filter((t) => t.status === 'completed').reduce((a, t) => a + t.commission, 0);

  return (
    <div className="p-6 space-y-6">
      <div className="flex items-center justify-between flex-wrap gap-4">
        <div>
          <h1 className="font-heading font-bold text-slate-900 text-2xl">Transactions</h1>
          <p className="text-slate-500 text-sm mt-0.5">All ride payment transactions</p>
        </div>
        <button className="flex items-center gap-2 px-4 py-2 rounded-xl bg-dark-card border border-dark-border text-slate-500 hover:text-slate-800 text-sm font-medium transition-colors">
          <FileDownloadIcon size={15} /> Export CSV
        </button>
      </div>

      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        {[
          { label: 'Total Revenue', value: `FC ${(totalRevenue / 1000).toFixed(0)}K`, icon: Money01Icon, color: 'text-primary' },
          { label: 'Commission', value: `FC ${(totalCommission / 1000).toFixed(0)}K`, icon: Coins01Icon, color: 'text-success' },
          { label: 'Completed', value: filtered.filter((t) => t.status === 'completed').length, icon: CheckmarkCircle01Icon, color: 'text-success' },
          { label: 'Refunds', value: filtered.filter((t) => t.status === 'refunded').length, icon: CancelCircleIcon, color: 'text-danger' },
        ].map(({ label, value, icon: Icon, color }) => (
          <div key={label} className="bg-dark-card border border-dark-border rounded-2xl p-4">
            <div className="flex items-center gap-2 mb-2"><Icon size={15} className={color} /><span className="text-xs text-slate-500">{label}</span></div>
            <p className={`font-heading font-bold text-2xl ${color}`}>{value}</p>
          </div>
        ))}
      </div>

      <div className="flex flex-wrap items-center gap-3">
        <div className="flex items-center gap-2 bg-dark-card border border-dark-border rounded-xl px-3 py-2 flex-1 min-w-[200px] max-w-xs">
          <Search01Icon size={15} className="text-slate-500" />
          <input value={search} onChange={(e) => setSearch(e.target.value)} placeholder="Search..." className="bg-transparent text-sm text-slate-800 placeholder-slate-400 flex-1 outline-none" />
          {search && <button onClick={() => setSearch('')}><Cancel01Icon size={13} className="text-slate-500" /></button>}
        </div>
        <select value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)} className="bg-dark-card border border-dark-border rounded-xl px-3 py-2 text-sm text-slate-600 outline-none">
          <option value="all">All Statuses</option>
          {['completed', 'pending', 'refunded', 'failed'].map((s) => <option key={s} value={s}>{s.charAt(0).toUpperCase() + s.slice(1)}</option>)}
        </select>
        <select value={methodFilter} onChange={(e) => setMethodFilter(e.target.value)} className="bg-dark-card border border-dark-border rounded-xl px-3 py-2 text-sm text-slate-600 outline-none">
          <option value="all">All Methods</option>
          <option value="cash">Espèces</option>
          <option value="airtel_money">Airtel Money</option>
          <option value="mtn_momo">MTN MoMo</option>
        </select>
      </div>

      <div className="bg-dark-card border border-dark-border rounded-2xl overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-dark-border">
                {['Txn ID', 'Rider', 'Driver', 'Ride', 'Amount', 'Commission', 'Method', 'Status', 'Time', 'Actions'].map((h) => (
                  <th key={h} className="px-4 py-3 text-left text-[11px] font-semibold uppercase tracking-widest text-slate-500">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {filtered.map((t) => (
                <tr key={t.id} className="border-b border-dark-border/50 hover:bg-slate-50 transition-colors">
                  <td className="px-4 py-3 font-mono text-xs text-slate-500">{t.id}</td>
                  <td className="px-4 py-3 text-slate-800 font-medium">{t.rider}</td>
                  <td className="px-4 py-3 text-slate-600">{t.driver}</td>
                  <td className="px-4 py-3">
                    <a href={`/rides/${t.ride_id}`} className="font-mono text-xs text-primary hover:underline">{t.ride_id}</a>
                  </td>
                  <td className="px-4 py-3 font-heading font-bold text-orange">FC {t.amount.toLocaleString()}</td>
                  <td className="px-4 py-3 text-success font-semibold">FC {t.commission.toLocaleString()}</td>
                  <td className="px-4 py-3 text-xs text-slate-500">{t.method.replace('_', ' ')}</td>
                  <td className="px-4 py-3">
                    <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full border ${STATUS_STYLES[t.status]}`}>{t.status.toUpperCase()}</span>
                  </td>
                  <td className="px-4 py-3 text-xs text-slate-500">
                    {new Date(t.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                  </td>
                  <td className="px-4 py-3">
                    {(t.status === 'processing' || t.status === 'failed' || t.status === 'pending') && (
                      <div className="flex gap-1.5">
                        <button
                          onClick={() => overrideStatus(t.ride_id, 'paid')}
                          className="text-[10px] px-2 py-1 rounded-full bg-success/10 text-success border border-success/20 hover:bg-success/20 font-semibold whitespace-nowrap"
                        >
                          Marquer payé
                        </button>
                        {t.status !== 'failed' && (
                          <button
                            onClick={() => overrideStatus(t.ride_id, 'failed')}
                            className="text-[10px] px-2 py-1 rounded-full bg-danger/10 text-danger border border-danger/20 hover:bg-danger/20 font-semibold whitespace-nowrap"
                          >
                            Échoué
                          </button>
                        )}
                      </div>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
