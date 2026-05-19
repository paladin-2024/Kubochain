import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import {
  ArrowLeft01Icon, Motorbike01Icon, StarIcon, UserBlock01Icon, UserCheck01Icon,
  Delete01Icon, Money01Icon, Clock01Icon, ChartUpIcon, Tick01Icon, CancelCircleIcon,
  CallIncoming01Icon, Mail01Icon, MapPinpoint01Icon, DocumentValidationIcon,
  Upload01Icon, EyeIcon, CheckmarkBadge01Icon, AlertCircleIcon, Refresh01Icon,
  Calendar01Icon, Route01Icon, ArrowRight01Icon, Award01Icon, Shield01Icon,
} from 'hugeicons-react';
import {
  AreaChart, Area, BarChart, Bar, XAxis, YAxis, CartesianGrid, ResponsiveContainer, Tooltip,
} from 'recharts';
import api from '../config/api';
import Avatar from '../components/Avatar';

const MOCK_DRIVER = {
  _id: 'D-142',
  name: 'Jean-Pierre Bauma',
  phone: '+243 812 345 678',
  email: 'jp.bauma@example.com',
  status: 'online',
  rating: 4.8,
  total_rides: 312,
  total_earnings: 1620000,
  completion_rate: 94,
  acceptance_rate: 88,
  joined_at: '2024-09-12T00:00:00Z',
  last_active: '2025-05-17T14:45:00Z',
  vehicle: { type: 'motorcycle', model: 'Honda CB500', plate: 'GOM-4521', year: 2021, color: 'Black' },
  docs: {
    license: { status: 'verified', uploaded_at: '2024-09-10T00:00:00Z' },
    insurance: { status: 'uploaded', uploaded_at: '2025-05-01T00:00:00Z' },
    vehicle_photo: { status: 'verified', uploaded_at: '2024-09-10T00:00:00Z' },
    id_card: { status: 'missing', uploaded_at: null },
  },
  location: { lat: -1.6792, lng: 29.2228, zone: 'Goma Centre' },
  weekly_earnings: [
    { week: 'Apr 14', earnings: 180000, rides: 38 },
    { week: 'Apr 21', earnings: 210000, rides: 44 },
    { week: 'Apr 28', earnings: 195000, rides: 40 },
    { week: 'May 5',  earnings: 240000, rides: 52 },
    { week: 'May 12', earnings: 220000, rides: 47 },
    { week: 'May 19', earnings: 185000, rides: 39 },
  ],
  recent_rides: [
    { id: 'RD-4521', passenger: 'Marie K.', from: 'Goma Centre', to: 'Himbi', fare: 6500, status: 'completed', date: '2025-05-17T14:22:00Z' },
    { id: 'RD-4498', passenger: 'Alain T.', from: 'Himbi', to: 'Birere', fare: 4800, status: 'completed', date: '2025-05-17T12:10:00Z' },
    { id: 'RD-4480', passenger: 'Sophie M.', from: 'Kyeshero', to: 'Goma Centre', fare: 7200, status: 'cancelled', date: '2025-05-17T10:05:00Z' },
    { id: 'RD-4461', passenger: 'Claude B.', from: 'Birere', to: 'Ndosho', fare: 5500, status: 'completed', date: '2025-05-16T18:30:00Z' },
    { id: 'RD-4440', passenger: 'Jeanne M.', from: 'Goma Centre', to: 'Kyeshero', fare: 8000, status: 'completed', date: '2025-05-16T15:45:00Z' },
    { id: 'RD-4418', passenger: 'Patrick N.', from: 'Ndosho', to: 'Birere', fare: 4200, status: 'completed', date: '2025-05-16T13:20:00Z' },
  ],
  payout_history: [
    { id: 'PAY-089', period: 'May 1–15, 2025', amount: 185000, rides: 42, status: 'completed', paid_at: '2025-05-16T08:00:00Z' },
    { id: 'PAY-071', period: 'Apr 16–30, 2025', amount: 210000, rides: 48, status: 'completed', paid_at: '2025-05-01T08:00:00Z' },
    { id: 'PAY-053', period: 'Apr 1–15, 2025', amount: 198000, rides: 45, status: 'completed', paid_at: '2025-04-16T08:00:00Z' },
  ],
};

const STATUS_STYLES = {
  online:    'text-success bg-success/10 border-success/20',
  offline:   'text-slate-500 bg-slate-100 border-slate-200',
  suspended: 'text-danger bg-danger/10 border-danger/20',
  pending:   'text-warning bg-warning/10 border-warning/20',
  pending_approval: 'text-warning bg-warning/10 border-warning/20',
};

const DOC_ITEMS = [
  { key: 'license',       label: "Driver's License",  icon: DocumentValidationIcon },
  { key: 'insurance',     label: 'Insurance Certificate', icon: Shield01Icon },
  { key: 'vehicle_photo', label: 'Vehicle Photo',     icon: Motorbike01Icon },
  { key: 'id_card',       label: 'National ID Card',  icon: CheckmarkBadge01Icon },
];

function DocCard({ docKey, label, icon: Icon, doc, onAction }) {
  const status = doc?.status ?? 'missing';
  const cfg = {
    verified: { cls: 'text-success bg-success/10 border-success/20', label: 'Verified' },
    uploaded: { cls: 'text-warning bg-warning/10 border-warning/20', label: 'Needs Review' },
    rejected: { cls: 'text-danger bg-danger/10 border-danger/20',   label: 'Rejected' },
    missing:  { cls: 'text-slate-400 bg-slate-100 border-slate-200', label: 'Missing' },
  }[status] ?? { cls: 'text-slate-400 bg-slate-100 border-slate-200', label: status };

  return (
    <div className="bg-white border border-dark-border rounded-2xl p-4 flex items-start justify-between gap-4">
      <div className="flex items-start gap-3">
        <div className={`w-10 h-10 rounded-xl flex items-center justify-center flex-shrink-0 ${cfg.cls}`}>
          <Icon size={18} />
        </div>
        <div>
          <p className="text-sm font-semibold text-slate-800">{label}</p>
          {doc?.uploaded_at ? (
            <p className="text-xs text-slate-400 mt-0.5">Uploaded {new Date(doc.uploaded_at).toLocaleDateString()}</p>
          ) : (
            <p className="text-xs text-slate-400 mt-0.5">Not submitted</p>
          )}
          <span className={`inline-flex items-center gap-1 text-[10px] font-bold px-2 py-0.5 rounded-full border mt-1.5 ${cfg.cls}`}>
            {status === 'verified' && <Tick01Icon size={8} />}
            {status === 'uploaded' && <AlertCircleIcon size={8} />}
            {status === 'missing' || status === 'rejected' ? <CancelCircleIcon size={8} /> : null}
            {cfg.label}
          </span>
        </div>
      </div>
      <div className="flex flex-col gap-1.5 flex-shrink-0">
        {status === 'uploaded' && (
          <>
            <button onClick={() => onAction(docKey, 'verify')} className="flex items-center gap-1 text-[11px] font-bold px-2.5 py-1 rounded-lg bg-success/10 text-success border border-success/20 hover:bg-success/20 transition-colors">
              <Tick01Icon size={11} /> Approve
            </button>
            <button onClick={() => onAction(docKey, 'reject')} className="flex items-center gap-1 text-[11px] font-bold px-2.5 py-1 rounded-lg bg-danger/10 text-danger border border-danger/20 hover:bg-danger/20 transition-colors">
              <CancelCircleIcon size={11} /> Reject
            </button>
          </>
        )}
        {status === 'verified' && (
          <button onClick={() => onAction(docKey, 'view')} className="flex items-center gap-1 text-[11px] font-bold px-2.5 py-1 rounded-lg bg-primary/10 text-primary border border-primary/20 hover:bg-primary/20 transition-colors">
            <EyeIcon size={11} /> View
          </button>
        )}
        {(status === 'missing' || status === 'rejected') && (
          <button onClick={() => onAction(docKey, 'request')} className="flex items-center gap-1 text-[11px] font-bold px-2.5 py-1 rounded-lg bg-warning/10 text-warning border border-warning/20 hover:bg-warning/20 transition-colors">
            <Upload01Icon size={11} /> Request
          </button>
        )}
      </div>
    </div>
  );
}

function SuspendModal({ driver, onClose, onConfirm }) {
  const [reason, setReason] = useState('');
  const [duration, setDuration] = useState('indefinite');
  return (
    <div className="fixed inset-0 bg-black/40 backdrop-blur-sm z-50 flex items-center justify-center p-4" onClick={onClose}>
      <div className="bg-white border border-dark-border rounded-2xl w-full max-w-md p-6 space-y-4" onClick={(e) => e.stopPropagation()}>
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-danger/10 flex items-center justify-center">
            <UserBlock01Icon size={18} className="text-danger" />
          </div>
          <div>
            <h3 className="font-heading font-bold text-slate-900">Suspend Driver</h3>
            <p className="text-xs text-slate-500">{driver.name}</p>
          </div>
        </div>
        <div>
          <label className="text-xs font-semibold text-slate-600 uppercase tracking-widest block mb-1.5">Duration</label>
          <select value={duration} onChange={(e) => setDuration(e.target.value)} className="w-full border border-dark-border rounded-xl px-3 py-2.5 text-sm text-slate-800 bg-slate-50 outline-none">
            <option value="1d">1 Day</option>
            <option value="3d">3 Days</option>
            <option value="7d">7 Days</option>
            <option value="30d">30 Days</option>
            <option value="indefinite">Indefinite</option>
          </select>
        </div>
        <div>
          <label className="text-xs font-semibold text-slate-600 uppercase tracking-widest block mb-1.5">Reason</label>
          <textarea
            value={reason}
            onChange={(e) => setReason(e.target.value)}
            rows={3}
            placeholder="Explain why this driver is being suspended..."
            className="w-full border border-dark-border rounded-xl px-3 py-2.5 text-sm text-slate-800 placeholder-slate-400 bg-slate-50 outline-none resize-none focus:border-danger/50"
          />
        </div>
        <div className="flex gap-3 pt-1">
          <button onClick={onClose} className="flex-1 py-2.5 rounded-xl text-sm font-semibold text-slate-500 bg-slate-100 hover:bg-slate-200 transition-colors">Cancel</button>
          <button
            onClick={() => onConfirm(reason, duration)}
            disabled={!reason.trim()}
            className="flex-1 py-2.5 rounded-xl text-sm font-semibold text-slate-900 bg-danger hover:bg-danger/90 transition-colors disabled:opacity-40"
          >
            Suspend Driver
          </button>
        </div>
      </div>
    </div>
  );
}

const TABS = ['Overview', 'Documents', 'Earnings', 'Trip History'];

export default function DriverProfile() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [driver, setDriver] = useState(MOCK_DRIVER);
  const [tab, setTab] = useState('Overview');
  const [loading, setLoading] = useState(null);
  const [showSuspendModal, setShowSuspendModal] = useState(false);
  const [notification, setNotification] = useState('');

  useEffect(() => {
    if (id) api.get(`/admin/drivers/${id}`).then((r) => { if (r.data) setDriver(r.data); }).catch(() => {});
  }, [id]);

  const notify = (msg) => {
    setNotification(msg);
    setTimeout(() => setNotification(''), 3000);
  };

  const doAction = async (action) => {
    setLoading(action);
    try {
      if (action === 'delete') {
        if (!confirm('Delete this driver permanently? This cannot be undone.')) { setLoading(null); return; }
        await api.delete(`/admin/drivers/${driver._id}`);
        navigate('/drivers');
        return;
      }
      await api.patch(`/admin/drivers/${driver._id}/${action}`);
      const statusMap = { approve: 'online', activate: 'online' };
      if (statusMap[action]) setDriver((d) => ({ ...d, status: statusMap[action] }));
      notify(`Driver ${action === 'approve' ? 'approved' : 'activated'} successfully.`);
    } catch {
      notify('Action failed. Please try again.');
    }
    setLoading(null);
  };

  const handleSuspend = async (reason, duration) => {
    setShowSuspendModal(false);
    setLoading('suspend');
    try {
      await api.patch(`/admin/drivers/${driver._id}/suspend`, { reason, duration });
      setDriver((d) => ({ ...d, status: 'suspended' }));
      notify('Driver suspended successfully.');
    } catch {
      notify('Suspension failed. Please try again.');
    }
    setLoading(null);
  };

  const handleDocAction = async (docKey, action) => {
    if (action === 'view') { notify('Document viewer coming soon.'); return; }
    if (action === 'request') { notify(`Re-upload request sent for ${docKey}.`); return; }
    try {
      await api.patch(`/admin/drivers/${driver._id}/docs/${docKey}`, { status: action === 'verify' ? 'verified' : 'rejected' });
      setDriver((d) => ({
        ...d,
        docs: { ...d.docs, [docKey]: { ...d.docs?.[docKey], status: action === 'verify' ? 'verified' : 'rejected' } },
      }));
      notify(`Document ${action === 'verify' ? 'approved' : 'rejected'}.`);
    } catch {
      notify('Document action failed.');
    }
  };

  const sc = STATUS_STYLES[driver.status] ?? STATUS_STYLES.offline;
  const uploadedDocs = Object.values(driver.docs || {}).filter((d) => d?.status === 'uploaded').length;
  const verifiedDocs = Object.values(driver.docs || {}).filter((d) => d?.status === 'verified').length;

  return (
    <div className="p-6 space-y-5 max-w-5xl mx-auto">
      {notification && (
        <div className="fixed top-4 right-4 z-50 bg-white border border-dark-border text-slate-800 text-sm px-4 py-3 rounded-xl shadow-lg animate-slide-in">
          {notification}
        </div>
      )}
      {showSuspendModal && <SuspendModal driver={driver} onClose={() => setShowSuspendModal(false)} onConfirm={handleSuspend} />}

      {/* Header */}
      <div className="flex items-center gap-3 flex-wrap">
        <button onClick={() => navigate(-1)} className="p-2 rounded-xl bg-white border border-dark-border text-slate-500 hover:text-slate-800 hover:bg-slate-50 transition-colors">
          <ArrowLeft01Icon size={16} />
        </button>
        <div className="flex-1">
          <div className="flex items-center gap-2.5">
            <h1 className="font-heading font-bold text-slate-900 text-xl">{driver.name}</h1>
            <span className={`text-[11px] font-bold px-2.5 py-0.5 rounded-full border ${sc}`}>
              {(driver.status || 'offline').replace('_', ' ').toUpperCase()}
            </span>
          </div>
          <p className="text-slate-500 text-sm mt-0.5">Driver ID: {driver._id} · Joined {new Date(driver.joined_at).toLocaleDateString()}</p>
        </div>
        <div className="flex items-center gap-2 flex-wrap">
          {(driver.status === 'pending' || driver.status === 'pending_approval') && (
            <button onClick={() => doAction('approve')} disabled={!!loading} className="flex items-center gap-1.5 px-3 py-2 rounded-xl bg-success/10 text-success border border-success/20 text-sm font-semibold hover:bg-success/20 transition-colors disabled:opacity-50">
              <Tick01Icon size={14} /> Approve
            </button>
          )}
          {driver.status !== 'suspended' && driver.status !== 'pending' && driver.status !== 'pending_approval' && (
            <button onClick={() => setShowSuspendModal(true)} disabled={!!loading} className="flex items-center gap-1.5 px-3 py-2 rounded-xl bg-warning/10 text-warning border border-warning/20 text-sm font-semibold hover:bg-warning/20 transition-colors disabled:opacity-50">
              <UserBlock01Icon size={14} /> Suspend
            </button>
          )}
          {driver.status === 'suspended' && (
            <button onClick={() => doAction('activate')} disabled={!!loading} className="flex items-center gap-1.5 px-3 py-2 rounded-xl bg-success/10 text-success border border-success/20 text-sm font-semibold hover:bg-success/20 transition-colors disabled:opacity-50">
              <UserCheck01Icon size={14} /> Reinstate
            </button>
          )}
          <button onClick={() => doAction('delete')} disabled={!!loading} className="flex items-center gap-1.5 px-3 py-2 rounded-xl bg-danger/10 text-danger border border-danger/20 text-sm font-semibold hover:bg-danger/20 transition-colors disabled:opacity-50">
            <Delete01Icon size={14} /> Delete
          </button>
        </div>
      </div>

      {/* Profile top row */}
      <div className="grid grid-cols-1 lg:grid-cols-4 gap-4">
        <div className="bg-white border border-dark-border rounded-2xl p-5 flex flex-col items-center text-center">
          <div className="mb-3">
            <Avatar name={driver.name} size={80} ring />
          </div>
          <div className="flex items-center gap-1 text-amber-500">
            <StarIcon size={14} />
            <span className="font-bold text-slate-900 text-lg">{driver.rating}</span>
          </div>
          <p className="text-xs text-slate-400 mt-0.5">{driver.total_rides} total rides</p>
          <div className="w-full pt-3 mt-3 border-t border-dark-border space-y-2">
            {[
              { icon: CallIncoming01Icon, text: driver.phone },
              { icon: Mail01Icon, text: driver.email },
              { icon: MapPinpoint01Icon, text: driver.location?.zone },
            ].map(({ icon: Icon, text }) => (
              <div key={text} className="flex items-center gap-2 text-xs text-slate-500">
                <Icon size={12} className="text-primary flex-shrink-0" />
                <span className="truncate">{text}</span>
              </div>
            ))}
          </div>
        </div>

        {[
          { label: 'Completion Rate', value: `${driver.completion_rate}%`, icon: Award01Icon, color: 'text-success', bg: 'bg-success/10' },
          { label: 'Acceptance Rate', value: `${driver.acceptance_rate}%`, icon: Tick01Icon, color: 'text-primary', bg: 'bg-primary/10' },
          { label: 'Total Earnings', value: `FC ${(driver.total_earnings / 1000).toFixed(0)}K`, icon: Money01Icon, color: 'text-orange', bg: 'bg-orange/10' },
        ].map(({ label, value, icon: Icon, color, bg }) => (
          <div key={label} className="bg-white border border-dark-border rounded-2xl p-5 flex flex-col justify-between">
            <div className={`w-10 h-10 rounded-xl ${bg} flex items-center justify-center mb-3`}>
              <Icon size={18} className={color} />
            </div>
            <div>
              <p className={`font-heading font-bold text-2xl ${color}`}>{value}</p>
              <p className="text-xs text-slate-500 mt-1">{label}</p>
            </div>
          </div>
        ))}
      </div>

      {/* Tabs */}
      <div className="flex gap-1 bg-slate-100 p-1 rounded-xl w-fit">
        {TABS.map((t) => (
          <button
            key={t}
            onClick={() => setTab(t)}
            className={`px-4 py-1.5 rounded-lg text-sm font-medium transition-all ${
              tab === t ? 'bg-white text-slate-900 shadow-sm' : 'text-slate-500 hover:text-slate-700'
            }`}
          >
            {t}
            {t === 'Documents' && uploadedDocs > 0 && (
              <span className="ml-1.5 bg-warning text-white text-[10px] font-bold px-1.5 py-0.5 rounded-full">{uploadedDocs}</span>
            )}
          </button>
        ))}
      </div>

      {/* Tab: Overview */}
      {tab === 'Overview' && (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          {/* Vehicle */}
          <div className="bg-white border border-dark-border rounded-2xl p-5">
            <p className="text-[11px] uppercase tracking-widest text-slate-500 font-semibold mb-4">Vehicle Info</p>
            <div className="flex items-center gap-3 mb-4">
              <div className="w-12 h-12 bg-orange/10 border border-orange/20 rounded-xl flex items-center justify-center">
                <Motorbike01Icon size={22} className="text-orange" />
              </div>
              <div>
                <p className="font-semibold text-slate-800">{driver.vehicle?.model} ({driver.vehicle?.year})</p>
                <p className="text-sm text-slate-500">{driver.vehicle?.color} · {driver.vehicle?.plate}</p>
              </div>
            </div>
            <div className="grid grid-cols-2 gap-3">
              {[
                { label: 'Type', value: driver.vehicle?.type },
                { label: 'Plate', value: driver.vehicle?.plate },
                { label: 'Year', value: driver.vehicle?.year },
                { label: 'Color', value: driver.vehicle?.color },
              ].map(({ label, value }) => (
                <div key={label} className="bg-slate-50 rounded-xl p-3">
                  <p className="text-[10px] uppercase text-slate-400 tracking-widest">{label}</p>
                  <p className="text-sm font-semibold text-slate-800 mt-0.5 capitalize">{value}</p>
                </div>
              ))}
            </div>
          </div>

          {/* Performance */}
          <div className="bg-white border border-dark-border rounded-2xl p-5">
            <p className="text-[11px] uppercase tracking-widest text-slate-500 font-semibold mb-4">Performance</p>
            <div className="space-y-4">
              {[
                { label: 'Completion Rate', value: driver.completion_rate, color: '#16A34A' },
                { label: 'Acceptance Rate', value: driver.acceptance_rate, color: '#2563EB' },
                { label: 'Rating Score',    value: Math.round((driver.rating / 5) * 100), color: '#D97706' },
              ].map(({ label, value, color }) => (
                <div key={label}>
                  <div className="flex justify-between text-sm mb-1.5">
                    <span className="text-slate-600">{label}</span>
                    <span className="font-bold text-slate-900">{value}%</span>
                  </div>
                  <div className="h-2 bg-slate-100 rounded-full overflow-hidden">
                    <div className="h-full rounded-full transition-all duration-700" style={{ width: `${value}%`, backgroundColor: color }} />
                  </div>
                </div>
              ))}
            </div>
            <div className="mt-4 pt-4 border-t border-dark-border grid grid-cols-2 gap-3 text-sm">
              <div>
                <p className="text-slate-500 text-xs">Docs verified</p>
                <p className="font-bold text-slate-900">{verifiedDocs} / {DOC_ITEMS.length}</p>
              </div>
              <div>
                <p className="text-slate-500 text-xs">Last active</p>
                <p className="font-bold text-slate-900">{new Date(driver.last_active).toLocaleDateString()}</p>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Tab: Documents */}
      {tab === 'Documents' && (
        <div className="space-y-3">
          {uploadedDocs > 0 && (
            <div className="flex items-center gap-2 bg-warning/10 border border-warning/20 rounded-xl px-4 py-3 text-sm text-warning font-medium">
              <AlertCircleIcon size={15} />
              {uploadedDocs} document{uploadedDocs !== 1 ? 's' : ''} awaiting review
            </div>
          )}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
            {DOC_ITEMS.map(({ key, label, icon }) => (
              <DocCard key={key} docKey={key} label={label} icon={icon} doc={driver.docs?.[key]} onAction={handleDocAction} />
            ))}
          </div>
        </div>
      )}

      {/* Tab: Earnings */}
      {tab === 'Earnings' && (
        <div className="space-y-4">
          <div className="bg-white border border-dark-border rounded-2xl p-5">
            <div className="flex items-center justify-between mb-5">
              <div>
                <h3 className="font-heading font-semibold text-slate-900">Weekly Earnings</h3>
                <p className="text-xs text-slate-500 mt-0.5">Last 6 weeks</p>
              </div>
            </div>
            <ResponsiveContainer width="100%" height={220}>
              <AreaChart data={driver.weekly_earnings} margin={{ top: 5, right: 10, left: 10, bottom: 5 }}>
                <defs>
                  <linearGradient id="earnGrad" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#2563EB" stopOpacity={0.25} />
                    <stop offset="95%" stopColor="#2563EB" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#E2E8F0" />
                <XAxis dataKey="week" axisLine={false} tickLine={false} tick={{ fill: '#94A3B8', fontSize: 11 }} />
                <YAxis axisLine={false} tickLine={false} tick={{ fill: '#94A3B8', fontSize: 11 }} tickFormatter={(v) => `${(v/1000).toFixed(0)}K`} />
                <Tooltip formatter={(v) => [`FC ${Number(v).toLocaleString()}`, 'Earnings']} contentStyle={{ borderRadius: 12, border: '1px solid #E2E8F0', background: '#fff', fontSize: 12 }} />
                <Area type="monotone" dataKey="earnings" stroke="#2563EB" strokeWidth={2.5} fill="url(#earnGrad)" dot={false} />
              </AreaChart>
            </ResponsiveContainer>
          </div>

          <div className="bg-white border border-dark-border rounded-2xl p-5">
            <h3 className="font-heading font-semibold text-slate-900 mb-4">Payout History</h3>
            <div className="space-y-2">
              {driver.payout_history?.map((p) => (
                <div key={p.id} className="flex items-center justify-between p-3 bg-slate-50 rounded-xl">
                  <div>
                    <p className="text-sm font-semibold text-slate-800">{p.period}</p>
                    <p className="text-xs text-slate-500">{p.rides} rides · Paid {new Date(p.paid_at).toLocaleDateString()}</p>
                  </div>
                  <div className="text-right">
                    <p className="font-heading font-bold text-orange text-sm">FC {p.amount.toLocaleString()}</p>
                    <span className="text-[10px] font-bold px-2 py-0.5 rounded-full text-success bg-success/10 border border-success/20">PAID</span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* Tab: Trip History */}
      {tab === 'Trip History' && (
        <div className="bg-white border border-dark-border rounded-2xl overflow-hidden">
          <div className="px-5 py-4 border-b border-dark-border flex items-center justify-between">
            <h3 className="font-heading font-semibold text-slate-900">Recent Trips</h3>
            <span className="text-xs text-slate-500">{driver.recent_rides?.length} shown</span>
          </div>
          <div className="divide-y divide-dark-border/60">
            {driver.recent_rides?.map((ride) => (
              <div key={ride.id} className="flex items-center justify-between px-5 py-3.5 hover:bg-slate-50 transition-colors">
                <div className="flex items-center gap-3">
                  <div className={`w-8 h-8 rounded-xl flex items-center justify-center flex-shrink-0 ${ride.status === 'completed' ? 'bg-success/10' : 'bg-danger/10'}`}>
                    <Motorbike01Icon size={14} className={ride.status === 'completed' ? 'text-success' : 'text-danger'} />
                  </div>
                  <div>
                    <p className="text-sm font-medium text-slate-800">{ride.passenger}</p>
                    <p className="text-xs text-slate-400">{ride.from} → {ride.to}</p>
                  </div>
                </div>
                <div className="text-right">
                  <p className="text-sm font-bold text-orange">FC {ride.fare.toLocaleString()}</p>
                  <p className="text-xs text-slate-400">{new Date(ride.date).toLocaleDateString()}</p>
                </div>
                <button onClick={() => navigate(`/rides/${ride.id}`)} className="ml-3 p-1.5 rounded-lg text-slate-400 hover:text-primary hover:bg-primary/10 transition-colors">
                  <ArrowRight01Icon size={14} />
                </button>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
