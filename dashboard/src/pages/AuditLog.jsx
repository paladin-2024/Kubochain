import React, { useState, useEffect } from 'react';
import {
  Audit01Icon, Clock01Icon, UserCheck01Icon, UserGroupIcon, Settings01Icon,
  CancelCircleIcon, CheckmarkCircle01Icon, FileDownloadIcon, Search01Icon,
  Cancel01Icon, FilterIcon, Calendar01Icon, Shield01Icon, Delete01Icon,
  Motorbike01Icon, Notification01Icon, Money01Icon, Edit01Icon, UserEdit01Icon,
} from 'hugeicons-react';
import api from '../config/api';

const ACTION_TYPES = {
  driver_approved: { label: 'Driver Approved', icon: UserCheck01Icon, color: 'text-success' },
  driver_suspended: { label: 'Driver Suspended', icon: UserCheck01Icon, color: 'text-danger' },
  driver_deleted: { label: 'Driver Deleted', icon: Delete01Icon, color: 'text-danger' },
  user_suspended: { label: 'User Suspended', icon: UserGroupIcon, color: 'text-warning' },
  user_deleted: { label: 'User Deleted', icon: Delete01Icon, color: 'text-danger' },
  ride_cancelled: { label: 'Ride Cancelled', icon: CancelCircleIcon, color: 'text-danger' },
  config_changed: { label: 'Config Changed', icon: Settings01Icon, color: 'text-primary' },
  notification_sent: { label: 'Notification Sent', icon: Notification01Icon, color: 'text-orange' },
  payout_processed: { label: 'Payout Processed', icon: Money01Icon, color: 'text-success' },
  incident_resolved: { label: 'Incident Resolved', icon: CheckmarkCircle01Icon, color: 'text-success' },
  surge_activated: { label: 'Surge Activated', icon: Shield01Icon, color: 'text-warning' },
  admin_login: { label: 'Admin Login', icon: Shield01Icon, color: 'text-primary' },
  admin_created: { label: 'Admin Created', icon: UserEdit01Icon, color: 'text-primary' },
};

const MOCK_LOGS = [
  { id: '1', action: 'driver_approved', admin: 'Admin Serge', target: 'Jean-Pierre Bauma (driver)', meta: { driver_id: 'D-142' }, created_at: '2025-05-17T14:32:00Z' },
  { id: '2', action: 'config_changed', admin: 'Admin Grace', target: 'Platform Config', meta: { field: 'base_fare', old: 'FC 450', new: 'FC 500' }, created_at: '2025-05-17T13:15:00Z' },
  { id: '3', action: 'notification_sent', admin: 'Admin Serge', target: 'All Riders (1,248)', meta: { title: 'Weekend Promo', type: 'promotional' }, created_at: '2025-05-17T12:00:00Z' },
  { id: '4', action: 'ride_cancelled', admin: 'Admin Grace', target: 'Ride RD-4521', meta: { reason: 'Safety concern' }, created_at: '2025-05-17T10:45:00Z' },
  { id: '5', action: 'user_suspended', admin: 'Admin Serge', target: 'Marie Kavira (user)', meta: { reason: 'Payment fraud' }, created_at: '2025-05-17T09:30:00Z' },
  { id: '6', action: 'driver_suspended', admin: 'Admin Grace', target: 'Rodrigue Mwamba (driver)', meta: { reason: 'Multiple complaints' }, created_at: '2025-05-17T08:20:00Z' },
  { id: '7', action: 'surge_activated', admin: 'Admin Serge', target: 'Zone: Goma Centre', meta: { multiplier: '1.8x', duration: '2h' }, created_at: '2025-05-17T07:00:00Z' },
  { id: '8', action: 'incident_resolved', admin: 'Admin Grace', target: 'Incident INC-002', meta: { resolution: 'Driver warned' }, created_at: '2025-05-16T22:10:00Z' },
  { id: '9', action: 'payout_processed', admin: 'System', target: 'Batch Payout #48', meta: { amount: 'FC 1.2M', drivers: 38 }, created_at: '2025-05-16T20:00:00Z' },
  { id: '10', action: 'admin_login', admin: 'Admin Serge', target: 'Authentication', meta: { ip: '196.200.x.x' }, created_at: '2025-05-16T08:05:00Z' },
];

function timeAgo(dateStr) {
  const diff = Date.now() - new Date(dateStr).getTime();
  const m = Math.floor(diff / 60000);
  if (m < 60) return `${m}m ago`;
  const h = Math.floor(m / 60);
  if (h < 24) return `${h}h ago`;
  return `${Math.floor(h / 24)}d ago`;
}

export default function AuditLog() {
  const [logs, setLogs] = useState(MOCK_LOGS);
  const [search, setSearch] = useState('');
  const [actionFilter, setActionFilter] = useState('all');
  const [adminFilter, setAdminFilter] = useState('all');
  const [dateFrom, setDateFrom] = useState('');
  const [dateTo, setDateTo] = useState('');

  useEffect(() => {
    api.get('/admin/audit').then((r) => { if (r.data?.length) setLogs(r.data); }).catch(() => {});
  }, []);

  const admins = ['all', ...Array.from(new Set(logs.map((l) => l.admin)))];
  const actionKeys = ['all', ...Object.keys(ACTION_TYPES)];

  const filtered = logs.filter((l) => {
    if (actionFilter !== 'all' && l.action !== actionFilter) return false;
    if (adminFilter !== 'all' && l.admin !== adminFilter) return false;
    if (search && !l.target.toLowerCase().includes(search.toLowerCase()) && !l.admin.toLowerCase().includes(search.toLowerCase())) return false;
    if (dateFrom && new Date(l.created_at) < new Date(dateFrom)) return false;
    if (dateTo && new Date(l.created_at) > new Date(dateTo + 'T23:59:59Z')) return false;
    return true;
  });

  const exportCSV = () => {
    const rows = [['ID', 'Action', 'Admin', 'Target', 'Time'], ...filtered.map((l) => [l.id, l.action, l.admin, l.target, l.created_at])];
    const csv = rows.map((r) => r.join(',')).join('\n');
    const a = document.createElement('a');
    a.href = 'data:text/csv,' + encodeURIComponent(csv);
    a.download = 'audit_log.csv';
    a.click();
  };

  return (
    <div className="p-6 space-y-6">
      <div className="flex items-center justify-between flex-wrap gap-4">
        <div>
          <h1 className="font-heading font-bold text-slate-900 text-2xl">Audit Log</h1>
          <p className="text-slate-500 text-sm mt-0.5">Complete record of all admin actions</p>
        </div>
        <button
          onClick={exportCSV}
          className="flex items-center gap-2 px-4 py-2 rounded-xl bg-dark-card border border-dark-border text-slate-500 hover:text-slate-800 text-sm font-medium transition-colors"
        >
          <FileDownloadIcon size={15} />
          Export CSV
        </button>
      </div>

      {/* Stats bar */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        {[
          { label: 'Total Actions', value: logs.length, color: 'text-primary', icon: Audit01Icon },
          { label: 'Today', value: logs.filter((l) => new Date(l.created_at).toDateString() === new Date().toDateString()).length, color: 'text-success', icon: Clock01Icon },
          { label: 'By Serge', value: logs.filter((l) => l.admin === 'Admin Serge').length, color: 'text-orange', icon: UserEdit01Icon },
          { label: 'By Grace', value: logs.filter((l) => l.admin === 'Admin Grace').length, color: 'text-warning', icon: UserEdit01Icon },
        ].map(({ label, value, color, icon: Icon }) => (
          <div key={label} className="bg-dark-card border border-dark-border rounded-2xl p-4">
            <div className="flex items-center gap-2 mb-2">
              <Icon size={15} className={color} />
              <span className="text-xs text-slate-500">{label}</span>
            </div>
            <p className={`font-heading font-bold text-2xl ${color}`}>{value}</p>
          </div>
        ))}
      </div>

      {/* Filters */}
      <div className="flex flex-wrap items-center gap-3">
        <div className="flex items-center gap-2 bg-dark-card border border-dark-border rounded-xl px-3 py-2 flex-1 min-w-[200px] max-w-xs">
          <Search01Icon size={15} className="text-slate-500" />
          <input value={search} onChange={(e) => setSearch(e.target.value)} placeholder="Search by admin or target..." className="bg-transparent text-sm text-slate-800 placeholder-slate-400 flex-1 outline-none" />
          {search && <button onClick={() => setSearch('')}><Cancel01Icon size={13} className="text-slate-500" /></button>}
        </div>
        <select value={actionFilter} onChange={(e) => setActionFilter(e.target.value)} className="bg-dark-card border border-dark-border rounded-xl px-3 py-2 text-sm text-slate-600 outline-none">
          <option value="all">All Actions</option>
          {Object.entries(ACTION_TYPES).map(([k, v]) => <option key={k} value={k}>{v.label}</option>)}
        </select>
        <select value={adminFilter} onChange={(e) => setAdminFilter(e.target.value)} className="bg-dark-card border border-dark-border rounded-xl px-3 py-2 text-sm text-slate-600 outline-none">
          {admins.map((a) => <option key={a} value={a}>{a === 'all' ? 'All Admins' : a}</option>)}
        </select>
        <div className="flex items-center gap-2">
          <Calendar01Icon size={14} className="text-slate-500" />
          <input type="date" value={dateFrom} onChange={(e) => setDateFrom(e.target.value)}
            className="bg-dark-card border border-dark-border rounded-xl px-3 py-2 text-sm text-slate-700 focus:outline-none focus:border-primary" />
          <span className="text-slate-500 text-sm">→</span>
          <input type="date" value={dateTo} onChange={(e) => setDateTo(e.target.value)}
            className="bg-dark-card border border-dark-border rounded-xl px-3 py-2 text-sm text-slate-700 focus:outline-none focus:border-primary" />
          {(dateFrom || dateTo) && (
            <button onClick={() => { setDateFrom(''); setDateTo(''); }}
              className="text-xs text-slate-500 hover:text-slate-800 px-2 py-1 rounded-lg border border-dark-border hover:border-danger/40 transition-colors">
              Clear
            </button>
          )}
        </div>
      </div>

      {/* Timeline */}
      <div className="bg-dark-card border border-dark-border rounded-2xl overflow-hidden">
        {filtered.length === 0 ? (
          <div className="py-16 text-center text-slate-500">No actions found</div>
        ) : (
          <div className="divide-y divide-dark-border/50">
            {filtered.map((log, idx) => {
              const def = ACTION_TYPES[log.action] ?? { label: log.action, icon: Audit01Icon, color: 'text-slate-500' };
              const Icon = def.icon;
              return (
                <div key={log.id} className="flex items-start gap-4 px-5 py-4 hover:bg-slate-50 transition-colors group">
                  {/* Timeline dot */}
                  <div className="relative flex flex-col items-center flex-shrink-0 mt-0.5">
                    <div className={`w-8 h-8 rounded-full bg-dark-bg border border-dark-border flex items-center justify-center ${def.color}`}>
                      <Icon size={14} />
                    </div>
                    {idx < filtered.length - 1 && (
                      <div className="absolute top-8 w-px h-full bg-dark-border/40" />
                    )}
                  </div>
                  {/* Content */}
                  <div className="flex-1 min-w-0 pb-2">
                    <div className="flex items-start justify-between gap-2 flex-wrap">
                      <div>
                        <span className={`text-sm font-semibold ${def.color}`}>{def.label}</span>
                        <span className="text-slate-500 text-sm"> — </span>
                        <span className="text-sm text-slate-600">{log.target}</span>
                      </div>
                      <span className="text-xs text-slate-500 flex-shrink-0">{timeAgo(log.created_at)}</span>
                    </div>
                    <p className="text-xs text-slate-500 mt-0.5">By <span className="text-slate-500 font-medium">{log.admin}</span></p>
                    {log.meta && (
                      <div className="flex flex-wrap gap-2 mt-2">
                        {Object.entries(log.meta).map(([k, v]) => (
                          <span key={k} className="text-[10px] bg-dark-bg border border-dark-border/50 rounded-lg px-2 py-0.5 text-slate-500">
                            <span className="text-slate-500">{k}: </span>{String(v)}
                          </span>
                        ))}
                      </div>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
}
