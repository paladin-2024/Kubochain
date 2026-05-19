import React, { useState, useEffect } from 'react';
import {
  UserAdd01Icon, UserCheck01Icon, CheckmarkBadge01Icon, DocumentValidationIcon,
  Clock01Icon, CancelCircleIcon, CheckmarkCircle01Icon, EyeIcon, Motorbike01Icon,
  Refresh01Icon, Search01Icon, Cancel01Icon, AlertDiamondIcon,
  Tick01Icon, Image01Icon,
} from 'hugeicons-react';
import api from '../config/api';
import Avatar from '../components/Avatar';

const TABS = ['all', 'pending', 'documents_uploaded', 'incomplete'];
const TAB_LABELS = { all: 'All', pending: 'Pending Review', documents_uploaded: 'Docs Uploaded', incomplete: 'Incomplete' };

const DOC_STATUS = {
  verified: { label: 'Verified', color: 'text-success bg-success/10 border-success/20' },
  uploaded: { label: 'Uploaded', color: 'text-warning bg-warning/10 border-warning/20' },
  missing: { label: 'Missing', color: 'text-danger bg-danger/10 border-danger/20' },
};

const STATUS_COLORS = {
  pending: 'text-warning bg-warning/10 border-warning/20',
  documents_uploaded: 'text-primary bg-primary/10 border-primary/20',
  incomplete: 'text-danger bg-danger/10 border-danger/20',
  approved: 'text-success bg-success/10 border-success/20',
};

const MOCK = [
  { id: '1', name: 'Jean-Pierre Bauma', phone: '+243 812 345 678', email: 'jp@example.com', created_at: '2025-05-16T09:30:00Z', status: 'pending', vehicle_type: 'motorcycle', vehicle_model: 'Honda CB500', plate: 'GOM-4521', docs: { license: 'uploaded', insurance: 'missing', vehicle_photo: 'uploaded' }, selfie: null },
  { id: '2', name: 'Marie Kavira', phone: '+243 998 765 432', email: 'mk@example.com', created_at: '2025-05-15T14:00:00Z', status: 'documents_uploaded', vehicle_type: 'motorcycle', vehicle_model: 'Yamaha YBR125', plate: 'GOM-7890', docs: { license: 'uploaded', insurance: 'uploaded', vehicle_photo: 'uploaded' }, selfie: null },
  { id: '3', name: 'Rodrigue Mwamba', phone: '+243 870 111 222', email: 'rm@example.com', created_at: '2025-05-17T07:15:00Z', status: 'incomplete', vehicle_type: 'motorcycle', vehicle_model: 'Suzuki GS150', plate: 'GOM-3310', docs: { license: 'missing', insurance: 'missing', vehicle_photo: 'missing' }, selfie: null },
  { id: '4', name: 'Sylvie Nzigire', phone: '+243 845 667 788', email: 'sn@example.com', created_at: '2025-05-14T11:20:00Z', status: 'pending', vehicle_type: 'motorcycle', vehicle_model: 'TVS Apache', plate: 'GOM-5500', docs: { license: 'verified', insurance: 'uploaded', vehicle_photo: 'uploaded' }, selfie: null },
];

function DocBadge({ label, status }) {
  const s = DOC_STATUS[status] ?? DOC_STATUS.missing;
  return (
    <div className={`inline-flex items-center gap-1 text-[10px] font-semibold px-2 py-0.5 rounded-md border ${s.color}`}>
      {status === 'verified' ? <Tick01Icon size={10} /> : status === 'uploaded' ? <Image01Icon size={10} /> : <CancelCircleIcon size={10} />}
      {label}
    </div>
  );
}

function DriverCard({ driver, onAction, loading }) {
  return (
    <div className="bg-dark-card border border-dark-border rounded-2xl p-5 flex flex-col gap-4 hover:border-primary/30 transition-colors">
      <div className="flex items-start gap-3">
        <Avatar name={driver.name} size={48} />
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2 flex-wrap">
            <p className="font-heading font-semibold text-slate-900 text-sm truncate">{driver.name}</p>
            <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full border ${STATUS_COLORS[driver.status] ?? ''}`}>
              {driver.status.replace('_', ' ').toUpperCase()}
            </span>
          </div>
          <p className="text-xs text-slate-500 mt-0.5">{driver.phone}</p>
          <p className="text-[11px] text-slate-500 mt-0.5">{driver.email}</p>
        </div>
      </div>

      <div className="flex items-center gap-2 bg-slate-50 rounded-xl px-3 py-2">
        <Motorbike01Icon size={16} className="text-orange flex-shrink-0" />
        <div className="min-w-0">
          <p className="text-xs font-semibold text-slate-900">{driver.vehicle_model}</p>
          <p className="text-[11px] text-slate-500">{driver.plate}</p>
        </div>
      </div>

      <div>
        <p className="text-[10px] uppercase tracking-widest text-slate-500 mb-2">Documents</p>
        <div className="flex flex-wrap gap-1.5">
          <DocBadge label="License" status={driver.docs.license} />
          <DocBadge label="Insurance" status={driver.docs.insurance} />
          <DocBadge label="Vehicle Photo" status={driver.docs.vehicle_photo} />
        </div>
      </div>

      <div className="flex items-center gap-2 pt-1 border-t border-dark-border">
        <button
          onClick={() => onAction(driver.id, 'approve')}
          disabled={loading === driver.id}
          className="flex-1 flex items-center justify-center gap-1.5 px-3 py-2 rounded-xl bg-success/10 text-success text-xs font-semibold border border-success/20 hover:bg-success/20 transition-colors disabled:opacity-50"
        >
          <CheckmarkCircle01Icon size={13} />
          Approve
        </button>
        <button
          onClick={() => onAction(driver.id, 'reject')}
          disabled={loading === driver.id}
          className="flex-1 flex items-center justify-center gap-1.5 px-3 py-2 rounded-xl bg-danger/10 text-danger text-xs font-semibold border border-danger/20 hover:bg-danger/20 transition-colors disabled:opacity-50"
        >
          <CancelCircleIcon size={13} />
          Reject
        </button>
        <button
          onClick={() => onAction(driver.id, 'request_info')}
          disabled={loading === driver.id}
          className="flex items-center justify-center gap-1.5 px-3 py-2 rounded-xl bg-warning/10 text-warning text-xs font-semibold border border-warning/20 hover:bg-warning/20 transition-colors disabled:opacity-50"
        >
          <AlertDiamondIcon size={13} />
        </button>
      </div>
    </div>
  );
}

export default function DriverOnboarding() {
  const [tab, setTab] = useState('all');
  const [search, setSearch] = useState('');
  const [drivers, setDrivers] = useState(MOCK);
  const [loading, setLoading] = useState(false);
  const [actionLoading, setActionLoading] = useState(null);
  const [stats, setStats] = useState({ total_pending: 4, approved_today: 3, rejected_today: 1, reviewed_today: 4 });

  useEffect(() => {
    (async () => {
      try {
        const [dRes, sRes] = await Promise.all([
          api.get('/admin/drivers/onboarding'),
          api.get('/admin/drivers/onboarding/stats'),
        ]);
        setDrivers(dRes.data || MOCK);
        if (sRes.data) setStats(sRes.data);
      } catch {}
    })();
  }, []);

  const doAction = async (id, action) => {
    setActionLoading(id);
    try {
      await api.patch(`/admin/drivers/${id}/${action}`);
      setDrivers((prev) => prev.filter((d) => d.id !== id));
    } catch {}
    setActionLoading(null);
  };

  const filtered = drivers.filter((d) => {
    if (tab !== 'all' && d.status !== tab) return false;
    if (search && !d.name.toLowerCase().includes(search.toLowerCase()) && !d.phone.includes(search)) return false;
    return true;
  });

  const tabCount = (t) => (t === 'all' ? drivers.length : drivers.filter((d) => d.status === t).length);

  return (
    <div className="p-6 space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between flex-wrap gap-4">
        <div>
          <h1 className="font-heading font-bold text-slate-900 text-2xl">Driver Onboarding</h1>
          <p className="text-slate-500 text-sm mt-0.5">Review and approve new driver applications</p>
        </div>
        <button
          onClick={async () => {
            setLoading(true);
            try {
              const [dRes, sRes] = await Promise.all([
                api.get('/admin/drivers/onboarding'),
                api.get('/admin/drivers/onboarding/stats'),
              ]);
              setDrivers(dRes.data || MOCK);
              if (sRes.data) setStats(sRes.data);
            } catch {}
            setLoading(false);
          }}
          disabled={loading}
          className="flex items-center gap-2 px-4 py-2 rounded-xl bg-dark-card border border-dark-border text-slate-500 hover:text-slate-800 text-sm font-medium transition-colors disabled:opacity-50"
        >
          <Refresh01Icon size={15} className={loading ? 'animate-spin' : ''} />
          Refresh
        </button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        {[
          { label: 'Total Pending', value: stats.total_pending, icon: Clock01Icon, color: 'text-warning' },
          { label: 'Reviewed Today', value: stats.reviewed_today, icon: EyeIcon, color: 'text-primary' },
          { label: 'Approved Today', value: stats.approved_today, icon: CheckmarkBadge01Icon, color: 'text-success' },
          { label: 'Rejected Today', value: stats.rejected_today, icon: CancelCircleIcon, color: 'text-danger' },
        ].map(({ label, value, icon: Icon, color }) => (
          <div key={label} className="bg-dark-card border border-dark-border rounded-2xl p-4">
            <div className="flex items-center gap-2 mb-2">
              <Icon size={16} className={color} />
              <span className="text-xs text-slate-500">{label}</span>
            </div>
            <p className={`font-heading font-bold text-2xl ${color}`}>{value}</p>
          </div>
        ))}
      </div>

      {/* Filters */}
      <div className="flex items-center gap-3 flex-wrap">
        <div className="flex bg-dark-card border border-dark-border rounded-xl p-1 gap-1">
          {TABS.map((t) => (
            <button
              key={t}
              onClick={() => setTab(t)}
              className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition-all ${tab === t ? 'bg-primary text-white' : 'text-slate-500 hover:text-slate-800'}`}
            >
              {TAB_LABELS[t]}
              <span className={`ml-1.5 text-[10px] px-1.5 py-0.5 rounded-full ${tab === t ? 'bg-white/20' : 'bg-dark-bg'}`}>
                {tabCount(t)}
              </span>
            </button>
          ))}
        </div>
        <div className="flex items-center gap-2 flex-1 min-w-[200px] max-w-xs bg-dark-card border border-dark-border rounded-xl px-3 py-2">
          <Search01Icon size={15} className="text-slate-500" />
          <input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search drivers..."
            className="bg-transparent text-sm text-slate-800 placeholder-slate-400 flex-1 outline-none"
          />
          {search && <button onClick={() => setSearch('')}><Cancel01Icon size={13} className="text-slate-500" /></button>}
        </div>
      </div>

      {/* Grid */}
      {filtered.length === 0 ? (
        <div className="flex flex-col items-center justify-center py-20 text-center">
          <UserCheck01Icon size={40} className="text-gray-700 mb-3" />
          <p className="font-heading font-semibold text-slate-500">No drivers in this queue</p>
          <p className="text-slate-500 text-sm mt-1">All caught up — check back later</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 2xl:grid-cols-4 gap-4">
          {filtered.map((d) => (
            <DriverCard key={d.id} driver={d} onAction={doAction} loading={actionLoading} />
          ))}
        </div>
      )}
    </div>
  );
}
