import React, { useState, useEffect, useCallback } from 'react';
import {
  BankIcon, CheckmarkCircle01Icon, CancelCircleIcon, Clock01Icon,
  FileDownloadIcon, Search01Icon, Cancel01Icon, Refresh01Icon,
  Money01Icon, UserCheck01Icon, Tick01Icon, ArrowRight01Icon,
  AlertCircleIcon, CheckmarkBadge01Icon, DollarCircleIcon,
} from 'hugeicons-react';
import api from '../config/api';
import Avatar from '../components/Avatar';

const STATUS_STYLES = {
  pending:    'text-warning bg-warning/10 border-warning/20',
  approved:   'text-primary bg-primary/10 border-primary/20',
  processing: 'text-primary bg-primary/10 border-primary/20',
  completed:  'text-success bg-success/10 border-success/20',
  rejected:   'text-danger bg-danger/10 border-danger/20',
  failed:     'text-danger bg-danger/10 border-danger/20',
};

const MOCK_PAYOUTS = [
  { id: 'PAY-001', driver: 'Jean-Pierre Bauma', driver_id: 'D-142', phone: '+243 812 345 678', amount: 185000, period: 'May 1–15, 2025', rides: 42, avg_fare: 4405, status: 'pending', method: 'Mobile Money', created_at: '2025-05-16T08:00:00Z', notes: '' },
  { id: 'PAY-002', driver: 'Sylvie Nzigire',    driver_id: 'D-091', phone: '+243 845 667 788', amount: 142000, period: 'May 1–15, 2025', rides: 35, avg_fare: 4057, status: 'completed', method: 'Bank Transfer', created_at: '2025-05-16T08:00:00Z', notes: '' },
  { id: 'PAY-003', driver: 'Patrick Nkosi',     driver_id: 'D-078', phone: '+243 870 111 222', amount: 98500,  period: 'May 1–15, 2025', rides: 28, avg_fare: 3518, status: 'processing', method: 'Mobile Money', created_at: '2025-05-16T08:00:00Z', notes: '' },
  { id: 'PAY-004', driver: 'Grace Amani',       driver_id: 'D-055', phone: '+243 820 333 444', amount: 211000, period: 'May 1–15, 2025', rides: 51, avg_fare: 4137, status: 'pending', method: 'Mobile Money', created_at: '2025-05-16T08:00:00Z', notes: '' },
  { id: 'PAY-005', driver: 'Rodrigue Mwamba',   driver_id: 'D-033', phone: '+243 860 555 666', amount: 75000,  period: 'May 1–15, 2025', rides: 20, avg_fare: 3750, status: 'rejected', method: 'Mobile Money', created_at: '2025-05-16T08:00:00Z', notes: 'Invalid mobile money number — driver needs to update.' },
  { id: 'PAY-006', driver: 'Esther Bahati',     driver_id: 'D-019', phone: '+243 812 888 999', amount: 163000, period: 'May 1–15, 2025', rides: 39, avg_fare: 4179, status: 'pending', method: 'Bank Transfer', created_at: '2025-05-16T08:00:00Z', notes: '' },
];

function PayoutDetailModal({ payout, onClose, onApprove, onReject }) {
  const [rejectReason, setRejectReason] = useState('');
  const [mode, setMode] = useState('view');
  const ss = STATUS_STYLES[payout.status] || STATUS_STYLES.pending;

  return (
    <div className="fixed inset-0 bg-black/40 backdrop-blur-sm z-50 flex items-center justify-center p-4" onClick={onClose}>
      <div className="bg-white border border-dark-border rounded-2xl w-full max-w-md p-6 space-y-5" onClick={(e) => e.stopPropagation()}>
        <div className="flex items-center justify-between">
          <h3 className="font-heading font-bold text-slate-900">Payout Detail</h3>
          <button onClick={onClose}><CancelCircleIcon size={20} className="text-slate-400 hover:text-slate-700" /></button>
        </div>

        <div className="flex items-center gap-3 bg-slate-50 rounded-2xl p-4">
          <Avatar name={payout.driver} size={48} />
          <div>
            <p className="font-semibold text-slate-900">{payout.driver}</p>
            <p className="text-xs text-slate-500">{payout.phone} · ID {payout.driver_id}</p>
          </div>
        </div>

        <div className="grid grid-cols-2 gap-3">
          {[
            { label: 'Payout Amount', value: `FC ${payout.amount.toLocaleString()}`, highlight: true },
            { label: 'Rides', value: payout.rides },
            { label: 'Avg Fare', value: `FC ${payout.avg_fare.toLocaleString()}` },
            { label: 'Method', value: payout.method },
            { label: 'Period', value: payout.period },
            { label: 'Status', value: <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full border ${ss}`}>{payout.status.toUpperCase()}</span> },
          ].map(({ label, value, highlight }) => (
            <div key={label} className="bg-slate-50 rounded-xl p-3">
              <p className="text-[10px] uppercase tracking-widest text-slate-400 mb-1">{label}</p>
              <p className={`text-sm font-semibold ${highlight ? 'text-orange' : 'text-slate-800'}`}>{value}</p>
            </div>
          ))}
        </div>

        {payout.notes && (
          <div className="bg-warning/10 border border-warning/20 rounded-xl px-4 py-3 text-sm text-warning">
            <strong>Note:</strong> {payout.notes}
          </div>
        )}

        {mode === 'reject' && (
          <div>
            <label className="text-xs font-semibold text-slate-600 uppercase tracking-widest block mb-1.5">Rejection Reason</label>
            <textarea
              value={rejectReason}
              onChange={(e) => setRejectReason(e.target.value)}
              rows={2}
              placeholder="Explain why this payout is being rejected..."
              className="w-full border border-dark-border rounded-xl px-3 py-2.5 text-sm text-slate-800 placeholder-slate-400 bg-slate-50 outline-none resize-none"
            />
          </div>
        )}

        {payout.status === 'pending' && (
          <div className="flex gap-2">
            {mode === 'view' && (
              <>
                <button onClick={() => onApprove(payout.id)} className="flex-1 flex items-center justify-center gap-2 py-2.5 rounded-xl bg-success text-slate-700 text-sm font-semibold hover:bg-success/90 transition-colors">
                  <Tick01Icon size={14} /> Approve
                </button>
                <button onClick={() => setMode('reject')} className="flex-1 flex items-center justify-center gap-2 py-2.5 rounded-xl bg-danger/10 text-danger border border-danger/20 text-sm font-semibold hover:bg-danger/20 transition-colors">
                  <CancelCircleIcon size={14} /> Reject
                </button>
              </>
            )}
            {mode === 'reject' && (
              <>
                <button onClick={() => setMode('view')} className="flex-1 py-2.5 rounded-xl text-sm font-semibold text-slate-500 bg-slate-100 hover:bg-slate-200 transition-colors">Back</button>
                <button onClick={() => onReject(payout.id, rejectReason)} disabled={!rejectReason.trim()} className="flex-1 py-2.5 rounded-xl text-sm font-semibold text-slate-900 bg-danger hover:bg-danger/90 transition-colors disabled:opacity-40">
                  Confirm Reject
                </button>
              </>
            )}
          </div>
        )}
        {payout.status === 'failed' && (
          <button onClick={() => onApprove(payout.id)} className="w-full flex items-center justify-center gap-2 py-2.5 rounded-xl bg-warning text-slate-700 text-sm font-semibold hover:bg-warning/90 transition-colors">
            Retry Payout
          </button>
        )}
      </div>
    </div>
  );
}

function exportCSV(payouts) {
  const rows = [
    ['ID', 'Driver', 'Phone', 'Period', 'Rides', 'Amount (FC)', 'Method', 'Status'],
    ...payouts.map((p) => [p.id, p.driver, p.phone, p.period, p.rides, p.amount, p.method, p.status]),
  ];
  const csv = rows.map((r) => r.join(',')).join('\n');
  const blob = new Blob([csv], { type: 'text/csv' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url; a.download = 'payouts.csv'; a.click();
  URL.revokeObjectURL(url);
}

export default function Payouts() {
  const [payouts, setPayouts] = useState(MOCK_PAYOUTS);
  const [statusFilter, setStatusFilter] = useState('all');
  const [search, setSearch] = useState('');
  const [selected, setSelected] = useState([]);
  const [detailPayout, setDetailPayout] = useState(null);
  const [processing, setProcessing] = useState(null);

  useEffect(() => {
    api.get('/admin/payouts').then((r) => { if (r.data?.length) setPayouts(r.data); }).catch(() => {});
  }, []);

  const approvePayout = useCallback(async (id) => {
    setProcessing(id);
    try {
      await api.post(`/admin/payouts/${id}/approve`);
      setPayouts((prev) => prev.map((p) => p.id === id ? { ...p, status: 'processing' } : p));
    } catch {}
    setProcessing(null);
    setDetailPayout(null);
  }, []);

  const rejectPayout = useCallback(async (id, reason) => {
    setProcessing(id);
    try {
      await api.post(`/admin/payouts/${id}/reject`, { reason });
      setPayouts((prev) => prev.map((p) => p.id === id ? { ...p, status: 'rejected', notes: reason } : p));
    } catch {}
    setProcessing(null);
    setDetailPayout(null);
  }, []);

  const bulkApprove = async () => {
    for (const id of selected) await approvePayout(id);
    setSelected([]);
  };

  const toggleSelect = (id) => setSelected((prev) => prev.includes(id) ? prev.filter((x) => x !== id) : [...prev, id]);
  const toggleAll = () => {
    const pendingIds = filtered.filter((p) => p.status === 'pending').map((p) => p.id);
    setSelected((prev) => prev.length === pendingIds.length ? [] : pendingIds);
  };

  const filtered = payouts.filter((p) => {
    if (statusFilter !== 'all' && p.status !== statusFilter) return false;
    if (search && !p.driver.toLowerCase().includes(search.toLowerCase())) return false;
    return true;
  });

  const pendingTotal = payouts.filter((p) => p.status === 'pending').reduce((a, p) => a + p.amount, 0);
  const completedTotal = payouts.filter((p) => p.status === 'completed').reduce((a, p) => a + p.amount, 0);
  const pendingCount = payouts.filter((p) => p.status === 'pending').length;

  return (
    <div className="p-6 space-y-6">
      {detailPayout && (
        <PayoutDetailModal
          payout={detailPayout}
          onClose={() => setDetailPayout(null)}
          onApprove={approvePayout}
          onReject={rejectPayout}
        />
      )}

      <div className="flex items-center justify-between flex-wrap gap-4">
        <div>
          <h1 className="font-heading font-bold text-slate-900 text-2xl">Driver Payouts</h1>
          <p className="text-slate-500 text-sm mt-0.5">Review, approve and track driver earnings payments</p>
        </div>
        <div className="flex items-center gap-2">
          {selected.length > 0 && (
            <button onClick={bulkApprove} className="flex items-center gap-2 px-4 py-2.5 rounded-xl bg-success text-slate-700 text-sm font-semibold hover:bg-success/90 transition-colors">
              <CheckmarkBadge01Icon size={15} /> Approve {selected.length} Selected
            </button>
          )}
          <button onClick={() => exportCSV(filtered)} className="flex items-center gap-2 px-4 py-2 rounded-xl bg-white border border-dark-border text-slate-500 hover:text-slate-800 text-sm font-medium transition-colors">
            <FileDownloadIcon size={15} /> Export CSV
          </button>
          <button onClick={() => api.get('/admin/payouts').then((r) => { if (r.data?.length) setPayouts(r.data); }).catch(() => {})} className="flex items-center gap-2 px-3 py-2 rounded-xl bg-white border border-dark-border text-slate-500 hover:text-slate-800 text-sm transition-colors">
            <Refresh01Icon size={14} />
          </button>
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        {[
          { label: 'Pending Payout',   value: `FC ${(pendingTotal / 1000).toFixed(0)}K`,    icon: Clock01Icon,           color: 'text-warning' },
          { label: 'Completed (period)', value: `FC ${(completedTotal / 1000).toFixed(0)}K`, icon: CheckmarkCircle01Icon, color: 'text-success' },
          { label: 'Awaiting Approval', value: pendingCount,                                icon: UserCheck01Icon,       color: 'text-primary' },
          { label: 'Rejected / Failed', value: payouts.filter((p) => p.status === 'rejected' || p.status === 'failed').length, icon: CancelCircleIcon, color: 'text-danger' },
        ].map(({ label, value, icon: Icon, color }) => (
          <div key={label} className="bg-white border border-dark-border rounded-2xl p-4">
            <div className="flex items-center gap-2 mb-2">
              <Icon size={15} className={color} />
              <span className="text-xs text-slate-500">{label}</span>
            </div>
            <p className={`font-heading font-bold text-2xl ${color}`}>{value}</p>
          </div>
        ))}
      </div>

      {pendingCount > 0 && (
        <div className="flex items-center gap-3 bg-warning/10 border border-warning/20 rounded-xl px-4 py-3">
          <AlertCircleIcon size={16} className="text-warning flex-shrink-0" />
          <p className="text-sm text-warning font-medium flex-1">{pendingCount} payout{pendingCount !== 1 ? 's' : ''} awaiting approval — FC {(pendingTotal / 1000).toFixed(0)}K total</p>
          <button onClick={bulkApprove} className="text-xs font-bold px-3 py-1.5 rounded-lg bg-warning text-white hover:bg-warning/90 transition-colors">
            Approve All
          </button>
        </div>
      )}

      {/* Filters */}
      <div className="flex items-center gap-3 flex-wrap">
        <div className="flex items-center gap-2 bg-white border border-dark-border rounded-xl px-3 py-2 flex-1 min-w-[200px] max-w-xs">
          <Search01Icon size={15} className="text-slate-400" />
          <input value={search} onChange={(e) => setSearch(e.target.value)} placeholder="Search driver..." className="bg-transparent text-sm text-slate-800 placeholder-slate-400 flex-1 outline-none" />
          {search && <button onClick={() => setSearch('')}><Cancel01Icon size={13} className="text-slate-400" /></button>}
        </div>
        <select value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)} className="bg-white border border-dark-border rounded-xl px-3 py-2 text-sm text-slate-600 outline-none">
          <option value="all">All Statuses</option>
          {['pending', 'approved', 'processing', 'completed', 'rejected', 'failed'].map((s) => (
            <option key={s} value={s}>{s.charAt(0).toUpperCase() + s.slice(1)}</option>
          ))}
        </select>
      </div>

      {/* Table */}
      <div className="bg-white border border-dark-border rounded-2xl overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="border-b border-dark-border bg-slate-50">
                <th className="px-4 py-3">
                  <input
                    type="checkbox"
                    checked={selected.length > 0 && selected.length === filtered.filter((p) => p.status === 'pending').length}
                    onChange={toggleAll}
                    className="rounded"
                  />
                </th>
                {['ID', 'Driver', 'Period', 'Rides', 'Amount', 'Method', 'Status', 'Actions'].map((h) => (
                  <th key={h} className="px-4 py-3 text-left text-[11px] font-semibold uppercase tracking-widest text-slate-500">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {filtered.map((p) => {
                const ss = STATUS_STYLES[p.status] || STATUS_STYLES.pending;
                const isPending = p.status === 'pending';
                return (
                  <tr key={p.id} className="border-b border-dark-border/60 hover:bg-slate-50 transition-colors">
                    <td className="px-4 py-3.5">
                      {isPending && (
                        <input type="checkbox" checked={selected.includes(p.id)} onChange={() => toggleSelect(p.id)} className="rounded" />
                      )}
                    </td>
                    <td className="px-4 py-3.5 font-mono text-xs text-slate-400">{p.id}</td>
                    <td className="px-4 py-3.5">
                      <p className="font-medium text-slate-800 text-sm">{p.driver}</p>
                      <p className="text-xs text-slate-400">{p.phone}</p>
                    </td>
                    <td className="px-4 py-3.5 text-xs text-slate-500">{p.period}</td>
                    <td className="px-4 py-3.5 text-sm font-semibold text-primary">{p.rides}</td>
                    <td className="px-4 py-3.5 font-heading font-bold text-orange text-sm">FC {p.amount.toLocaleString()}</td>
                    <td className="px-4 py-3.5 text-xs text-slate-500">{p.method}</td>
                    <td className="px-4 py-3.5">
                      <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full border ${ss}`}>
                        {p.status.toUpperCase()}
                      </span>
                    </td>
                    <td className="px-4 py-3.5">
                      <div className="flex items-center gap-1.5">
                        {isPending && (
                          <>
                            <button onClick={() => approvePayout(p.id)} disabled={processing === p.id} className="text-xs font-semibold border border-success/20 bg-success/10 text-success px-2 py-1 rounded-lg hover:bg-success/20 transition-colors disabled:opacity-50">
                              Approve
                            </button>
                            <button onClick={() => setDetailPayout(p)} className="text-xs font-semibold border border-dark-border bg-white text-slate-500 px-2 py-1 rounded-lg hover:bg-slate-50 transition-colors">
                              Review
                            </button>
                          </>
                        )}
                        {(p.status === 'rejected' || p.status === 'failed') && (
                          <button onClick={() => approvePayout(p.id)} disabled={processing === p.id} className="text-xs font-semibold border border-warning/20 bg-warning/10 text-warning px-2 py-1 rounded-lg hover:bg-warning/20 transition-colors">
                            Retry
                          </button>
                        )}
                        <button onClick={() => setDetailPayout(p)} className="p-1.5 rounded-lg text-slate-400 hover:text-primary hover:bg-primary/10 transition-colors">
                          <ArrowRight01Icon size={13} />
                        </button>
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
