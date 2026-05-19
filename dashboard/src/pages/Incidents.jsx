import React, { useState, useEffect } from 'react';
import {
  AlertDiamondIcon, Shield01Icon, Flag01Icon, CheckmarkCircle01Icon, CancelCircleIcon,
  Clock01Icon, EyeIcon, UserCheck01Icon, HeadsetIcon, FilterIcon, Search01Icon,
  Cancel01Icon, Refresh01Icon, UserGroupIcon, TrafficIncidentIcon, DangerIcon,
  ArrowUp01Icon, FileDownloadIcon,
} from 'hugeicons-react';
import api from '../config/api';

const PRIORITIES = ['all', 'critical', 'high', 'medium', 'low'];
const STATUSES = ['all', 'open', 'in_review', 'resolved', 'closed'];
const TYPES = ['all', 'ride_dispute', 'driver_complaint', 'payment_issue', 'safety_concern', 'harassment'];

const PRIORITY_STYLES = {
  critical: { label: 'CRITICAL', cls: 'text-danger bg-danger/10 border-danger/30' },
  high: { label: 'HIGH', cls: 'text-orange bg-orange/10 border-orange/30' },
  medium: { label: 'MEDIUM', cls: 'text-warning bg-warning/10 border-warning/30' },
  low: { label: 'LOW', cls: 'text-primary bg-primary/10 border-primary/30' },
};

const STATUS_STYLES = {
  open: { label: 'Open', cls: 'text-danger bg-danger/10 border-danger/20' },
  in_review: { label: 'In Review', cls: 'text-warning bg-warning/10 border-warning/20' },
  resolved: { label: 'Resolved', cls: 'text-success bg-success/10 border-success/20' },
  closed: { label: 'Closed', cls: 'text-slate-500 bg-slate-100 border-slate-200' },
};

const TYPE_ICONS = {
  ride_dispute: TrafficIncidentIcon,
  driver_complaint: UserCheck01Icon,
  payment_issue: DangerIcon,
  safety_concern: Shield01Icon,
  harassment: AlertDiamondIcon,
};

const MOCK = [
  { id: 'INC-001', title: 'Driver demanded extra payment', type: 'driver_complaint', priority: 'high', status: 'open', reporter: 'Marie Kavira', ride_id: 'RD-4521', created_at: '2025-05-17T08:30:00Z', assigned_to: null, description: 'Driver requested additional payment beyond the app fare, threatening to cancel the trip.' },
  { id: 'INC-002', title: 'Passenger threatened with violence', type: 'safety_concern', priority: 'critical', status: 'in_review', reporter: 'Jean-Pierre B.', ride_id: 'RD-4510', created_at: '2025-05-17T06:15:00Z', assigned_to: 'Admin Serge', description: 'Passenger made threatening remarks during the ride and refused to exit the vehicle.' },
  { id: 'INC-003', title: 'Fare charged incorrectly', type: 'payment_issue', priority: 'medium', status: 'open', reporter: 'Sophie M.', ride_id: 'RD-4498', created_at: '2025-05-16T21:00:00Z', assigned_to: null, description: 'Final fare was 3x the estimated amount with no explanation.' },
  { id: 'INC-004', title: 'Driver did not show up', type: 'ride_dispute', priority: 'low', status: 'resolved', reporter: 'Alain T.', ride_id: 'RD-4490', created_at: '2025-05-16T18:45:00Z', assigned_to: 'Admin Grace', description: 'Driver accepted the ride but never arrived and marked it as completed.' },
  { id: 'INC-005', title: 'Inappropriate messages from driver', type: 'harassment', priority: 'high', status: 'in_review', reporter: 'Esther B.', ride_id: 'RD-4485', created_at: '2025-05-16T15:20:00Z', assigned_to: 'Admin Serge', description: 'Driver sent inappropriate messages after the ride through the in-app chat.' },
];

function IncidentRow({ inc, onSelect }) {
  const p = PRIORITY_STYLES[inc.priority];
  const s = STATUS_STYLES[inc.status];
  const TypeIcon = TYPE_ICONS[inc.type] ?? AlertDiamondIcon;

  return (
    <tr
      onClick={() => onSelect(inc)}
      className="border-b border-dark-border/50 hover:bg-slate-50 cursor-pointer transition-colors"
    >
      <td className="px-4 py-3 font-mono text-xs text-slate-500">{inc.id}</td>
      <td className="px-4 py-3">
        <div className="flex items-center gap-2">
          <TypeIcon size={14} className="text-slate-500 flex-shrink-0" />
          <span className="text-sm text-slate-700 font-medium">{inc.title}</span>
        </div>
      </td>
      <td className="px-4 py-3">
        <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full border ${p.cls}`}>{p.label}</span>
      </td>
      <td className="px-4 py-3">
        <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full border ${s.cls}`}>{s.label}</span>
      </td>
      <td className="px-4 py-3 text-sm text-slate-600">{inc.reporter}</td>
      <td className="px-4 py-3 text-xs text-slate-500">{inc.assigned_to ?? <span className="text-warning">Unassigned</span>}</td>
      <td className="px-4 py-3 text-xs text-slate-500">
        {new Date(inc.created_at).toLocaleDateString()} {new Date(inc.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
      </td>
    </tr>
  );
}

function IncidentModal({ inc, onClose, onResolve }) {
  if (!inc) return null;
  const p = PRIORITY_STYLES[inc.priority];
  const s = STATUS_STYLES[inc.status];
  return (
    <div className="fixed inset-0 bg-black/60 backdrop-blur-sm z-50 flex items-center justify-center p-4" onClick={onClose}>
      <div
        className="bg-dark-card border border-dark-border rounded-2xl w-full max-w-lg p-6 space-y-4"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="flex items-start justify-between gap-3">
          <div>
            <div className="flex items-center gap-2 mb-1">
              <span className="font-mono text-xs text-slate-500">{inc.id}</span>
              <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full border ${p.cls}`}>{p.label}</span>
              <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full border ${s.cls}`}>{s.label}</span>
            </div>
            <h2 className="font-heading font-bold text-slate-900 text-lg">{inc.title}</h2>
          </div>
          <button onClick={onClose} className="text-slate-500 hover:text-slate-800 transition-colors mt-1">
            <CancelCircleIcon size={20} />
          </button>
        </div>
        <p className="text-slate-500 text-sm leading-relaxed">{inc.description}</p>
        <div className="grid grid-cols-2 gap-3 text-sm">
          <div className="bg-slate-50 rounded-xl p-3">
            <p className="text-[10px] uppercase tracking-widest text-slate-500 mb-1">Reporter</p>
            <p className="text-slate-800 font-medium">{inc.reporter}</p>
          </div>
          <div className="bg-slate-50 rounded-xl p-3">
            <p className="text-[10px] uppercase tracking-widest text-slate-500 mb-1">Ride ID</p>
            <p className="text-primary font-mono">{inc.ride_id}</p>
          </div>
          <div className="bg-slate-50 rounded-xl p-3">
            <p className="text-[10px] uppercase tracking-widest text-slate-500 mb-1">Assigned To</p>
            <p className={inc.assigned_to ? 'text-slate-800 font-medium' : 'text-warning'}>{inc.assigned_to ?? 'Unassigned'}</p>
          </div>
          <div className="bg-slate-50 rounded-xl p-3">
            <p className="text-[10px] uppercase tracking-widest text-slate-500 mb-1">Reported</p>
            <p className="text-slate-800 font-medium">{new Date(inc.created_at).toLocaleDateString()}</p>
          </div>
        </div>
        <div className="flex gap-2 pt-2 border-t border-dark-border">
          <button
            onClick={() => onResolve(inc.id, 'resolved')}
            className="flex-1 flex items-center justify-center gap-1.5 px-4 py-2.5 rounded-xl bg-success/10 text-success font-semibold text-sm border border-success/20 hover:bg-success/20 transition-colors"
          >
            <CheckmarkCircle01Icon size={15} />
            Mark Resolved
          </button>
          <button
            onClick={() => onResolve(inc.id, 'in_review')}
            className="flex-1 flex items-center justify-center gap-1.5 px-4 py-2.5 rounded-xl bg-warning/10 text-warning font-semibold text-sm border border-warning/20 hover:bg-warning/20 transition-colors"
          >
            <HeadsetIcon size={15} />
            Assign to Me
          </button>
          <button
            onClick={() => onResolve(inc.id, 'closed')}
            className="flex items-center justify-center gap-1.5 px-4 py-2.5 rounded-xl bg-dark-bg text-slate-500 font-semibold text-sm border border-dark-border hover:text-slate-800 transition-colors"
          >
            <CancelCircleIcon size={15} />
          </button>
        </div>
      </div>
    </div>
  );
}

export default function Incidents() {
  const [incidents, setIncidents] = useState(MOCK);
  const [priority, setPriority] = useState('all');
  const [status, setStatus] = useState('all');
  const [search, setSearch] = useState('');
  const [selected, setSelected] = useState(null);

  useEffect(() => {
    api.get('/admin/incidents').then((r) => { if (r.data?.length) setIncidents(r.data); }).catch(() => {});
  }, []);

  const doResolve = async (id, newStatus) => {
    try {
      await api.patch(`/admin/incidents/${id}`, { status: newStatus });
      setIncidents((prev) => prev.map((i) => (i.id === id ? { ...i, status: newStatus } : i)));
    } catch {}
    setSelected(null);
  };

  const filtered = incidents.filter((i) => {
    if (priority !== 'all' && i.priority !== priority) return false;
    if (status !== 'all' && i.status !== status) return false;
    if (search && !i.title.toLowerCase().includes(search.toLowerCase()) && !i.reporter.toLowerCase().includes(search.toLowerCase())) return false;
    return true;
  });

  const countByStatus = (s) => incidents.filter((i) => i.status === s).length;

  return (
    <div className="p-6 space-y-6">
      <IncidentModal inc={selected} onClose={() => setSelected(null)} onResolve={doResolve} />

      <div className="flex items-center justify-between flex-wrap gap-4">
        <div>
          <h1 className="font-heading font-bold text-slate-900 text-2xl">Incidents & Disputes</h1>
          <p className="text-slate-500 text-sm mt-0.5">Safety reports and ride disputes</p>
        </div>
        <button className="flex items-center gap-2 px-4 py-2 rounded-xl bg-dark-card border border-dark-border text-slate-500 hover:text-slate-800 text-sm font-medium transition-colors">
          <FileDownloadIcon size={15} />
          Export
        </button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        {[
          { label: 'Open', value: countByStatus('open'), color: 'text-danger', icon: AlertDiamondIcon },
          { label: 'In Review', value: countByStatus('in_review'), color: 'text-warning', icon: Clock01Icon },
          { label: 'Resolved', value: countByStatus('resolved'), color: 'text-success', icon: CheckmarkCircle01Icon },
          { label: 'Total', value: incidents.length, color: 'text-primary', icon: TrafficIncidentIcon },
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
          <input value={search} onChange={(e) => setSearch(e.target.value)} placeholder="Search incidents..." className="bg-transparent text-sm text-slate-800 placeholder-slate-400 flex-1 outline-none" />
          {search && <button onClick={() => setSearch('')}><Cancel01Icon size={13} className="text-slate-500" /></button>}
        </div>
        <select
          value={priority}
          onChange={(e) => setPriority(e.target.value)}
          className="bg-dark-card border border-dark-border rounded-xl px-3 py-2 text-sm text-slate-600 outline-none"
        >
          {PRIORITIES.map((p) => <option key={p} value={p}>{p === 'all' ? 'All Priorities' : p.charAt(0).toUpperCase() + p.slice(1)}</option>)}
        </select>
        <select
          value={status}
          onChange={(e) => setStatus(e.target.value)}
          className="bg-dark-card border border-dark-border rounded-xl px-3 py-2 text-sm text-slate-600 outline-none"
        >
          {STATUSES.map((s) => <option key={s} value={s}>{s === 'all' ? 'All Statuses' : s.replace('_', ' ').charAt(0).toUpperCase() + s.replace('_', ' ').slice(1)}</option>)}
        </select>
      </div>

      {/* Table */}
      <div className="bg-dark-card border border-dark-border rounded-2xl overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="border-b border-dark-border">
                {['ID', 'Title', 'Priority', 'Status', 'Reporter', 'Assigned', 'Created'].map((h) => (
                  <th key={h} className="px-4 py-3 text-left text-[11px] font-semibold uppercase tracking-widest text-slate-500">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {filtered.length === 0 ? (
                <tr><td colSpan={7} className="px-4 py-16 text-center text-slate-500">No incidents found</td></tr>
              ) : (
                filtered.map((inc) => <IncidentRow key={inc.id} inc={inc} onSelect={setSelected} />)
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
