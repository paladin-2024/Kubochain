import React, { useState, useEffect, useRef } from 'react';
import {
  DangerIcon, AlertDiamondIcon, Shield01Icon, MapPinpoint01Icon, Clock01Icon,
  UserGroupIcon, CheckmarkCircle01Icon, CancelCircleIcon,
  CallIncoming01Icon, Motorbike01Icon, HeadsetIcon,
} from 'hugeicons-react';
import api from '../config/api';

const SEVERITY = {
  critical: { label: 'CRITICAL', cls: 'text-danger bg-danger/10 border-danger/30', glow: 'shadow-[0_0_20px_rgba(235,87,87,0.2)]' },
  high: { label: 'HIGH', cls: 'text-orange bg-orange/10 border-orange/30', glow: 'shadow-[0_0_12px_rgba(242,153,74,0.1)]' },
  medium: { label: 'MEDIUM', cls: 'text-warning bg-warning/10 border-warning/30', glow: '' },
};

const STATUS = {
  active: { label: 'ACTIVE', cls: 'text-danger' },
  responding: { label: 'RESPONDING', cls: 'text-warning' },
  resolved: { label: 'RESOLVED', cls: 'text-success' },
};

const MOCK_SOS = [
  {
    id: 'SOS-001', severity: 'critical', status: 'active',
    reporter_type: 'passenger', reporter: 'Marie Kavira', reporter_phone: '+243 998 765 432',
    driver: 'Jean-Pierre Bauma', driver_phone: '+243 812 345 678',
    ride_id: 'RD-4521', location: 'Rue de la Paix, Goma Centre', lat: -1.6792, lng: 29.2228,
    message: 'Driver is driving erratically and ignoring stop requests',
    created_at: '2025-05-17T14:55:00Z', responded_at: null,
  },
  {
    id: 'SOS-002', severity: 'high', status: 'responding',
    reporter_type: 'driver', reporter: 'Sylvie Nzigire', reporter_phone: '+243 845 667 788',
    driver: 'Sylvie Nzigire', driver_phone: '+243 845 667 788',
    ride_id: 'RD-4515', location: 'Birere Market', lat: -1.6950, lng: 29.2100,
    message: 'Passenger is aggressive and threatening violence',
    created_at: '2025-05-17T13:30:00Z', responded_at: '2025-05-17T13:32:00Z',
  },
  {
    id: 'SOS-003', severity: 'medium', status: 'resolved',
    reporter_type: 'passenger', reporter: 'Alain T.', reporter_phone: '+243 870 222 333',
    driver: 'Patrick Nkosi', driver_phone: '+243 870 111 222',
    ride_id: 'RD-4505', location: 'Ndosho Road', lat: -1.6600, lng: 29.2300,
    message: 'Driver is lost and unable to find destination',
    created_at: '2025-05-17T11:00:00Z', responded_at: '2025-05-17T11:05:00Z',
  },
];


function SosItem({ sos, onResolve, onRespond }) {
  const sev = SEVERITY[sos.severity];
  const st = STATUS[sos.status];
  const elapsed = Math.floor((Date.now() - new Date(sos.created_at).getTime()) / 60000);

  return (
    <div className={`relative bg-dark-card border rounded-2xl p-5 overflow-hidden ${
      sos.status === 'active' ? 'border-danger/40 shadow-[0_0_20px_rgba(235,87,87,0.1)]' :
      sos.status === 'responding' ? 'border-warning/30' : 'border-dark-border opacity-80'
    }`}>
      {sos.status === 'active' && (
        <div className="absolute top-0 left-0 right-0 h-0.5 bg-gradient-to-r from-transparent via-danger to-transparent animate-pulse" />
      )}

      <div className="flex items-start justify-between gap-3 mb-3">
        <div className="flex items-center gap-2 flex-wrap">
          <DangerIcon size={16} className={sev.cls.split(' ')[0]} />
          <span className="font-heading font-bold text-slate-900">{sos.id}</span>
          <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full border ${sev.cls}`}>{sev.label}</span>
          <span className={`text-[10px] font-bold ${st.cls}`}>● {st.label}</span>
        </div>
        <div className="flex items-center gap-1 text-xs text-slate-500">
          <Clock01Icon size={11} />
          {elapsed}m ago
        </div>
      </div>

      <p className="text-sm text-slate-700 font-medium mb-3 leading-relaxed">"{sos.message}"</p>

      <div className="grid grid-cols-2 gap-3 mb-4">
        <div className="bg-dark-bg/60 rounded-xl p-3">
          <div className="flex items-center gap-1.5 mb-1">
            {sos.reporter_type === 'driver' ? <Motorbike01Icon size={12} className="text-orange" /> : <UserGroupIcon size={12} className="text-primary" />}
            <span className="text-[10px] uppercase tracking-widest text-slate-500">
              {sos.reporter_type === 'driver' ? 'Driver (Reporter)' : 'Passenger (Reporter)'}
            </span>
          </div>
          <p className="text-sm font-medium text-slate-800">{sos.reporter}</p>
          <a href={`tel:${sos.reporter_phone}`} className="text-xs text-primary hover:underline">{sos.reporter_phone}</a>
        </div>
        <div className="bg-dark-bg/60 rounded-xl p-3">
          <div className="flex items-center gap-1.5 mb-1">
            <MapPinpoint01Icon size={12} className="text-danger" />
            <span className="text-[10px] uppercase tracking-widest text-slate-500">Location</span>
          </div>
          <p className="text-sm font-medium text-slate-800">{sos.location}</p>
          <a href={`/rides/${sos.ride_id}`} className="text-xs text-primary hover:underline">{sos.ride_id}</a>
        </div>
      </div>

      {sos.status !== 'resolved' && (
        <div className="flex gap-2">
          {sos.status === 'active' && (
            <button
              onClick={() => onRespond(sos.id)}
              className="flex-1 flex items-center justify-center gap-1.5 py-2.5 rounded-xl bg-warning/10 text-warning border border-warning/20 text-sm font-semibold hover:bg-warning/20 transition-colors"
            >
              <HeadsetIcon size={14} /> Respond
            </button>
          )}
          <button
            onClick={() => onResolve(sos.id)}
            className="flex-1 flex items-center justify-center gap-1.5 py-2.5 rounded-xl bg-success/10 text-success border border-success/20 text-sm font-semibold hover:bg-success/20 transition-colors"
          >
            <CheckmarkCircle01Icon size={14} /> Resolve
          </button>
          <a
            href={`tel:${sos.reporter_phone}`}
            className="flex items-center justify-center gap-1.5 px-4 py-2.5 rounded-xl bg-primary/10 text-primary border border-primary/20 text-sm font-semibold hover:bg-primary/20 transition-colors"
          >
            <CallIncoming01Icon size={14} />
          </a>
        </div>
      )}
    </div>
  );
}

export default function SosEmergency() {
  const [alerts, setAlerts] = useState(MOCK_SOS);

  useEffect(() => {
    api.get('/admin/sos').then((r) => { if (r.data?.length) setAlerts(r.data); }).catch(() => {});
    const ws = new WebSocket(`${import.meta.env.VITE_WS_URL ?? 'ws://localhost:8000'}/ws/admin`);
    ws.onmessage = (e) => {
      try {
        const { event, data } = JSON.parse(e.data);
        if (event === 'sos_alert') setAlerts((prev) => [data, ...prev]);
      } catch {}
    };
    return () => ws.close();
  }, []);

  const resolve = async (id) => {
    try { await api.patch(`/admin/sos/${id}/resolve`); } catch {}
    setAlerts((prev) => prev.map((a) => (a.id === id ? { ...a, status: 'resolved' } : a)));
  };

  const respond = async (id) => {
    try { await api.patch(`/admin/sos/${id}/respond`); } catch {}
    setAlerts((prev) => prev.map((a) => (a.id === id ? { ...a, status: 'responding' } : a)));
  };

  const active = alerts.filter((a) => a.status !== 'resolved');
  const resolved = alerts.filter((a) => a.status === 'resolved');

  return (
    <div className="p-6 space-y-6">
      <div className="flex items-center justify-between flex-wrap gap-4">
        <div>
          <h1 className="font-heading font-bold text-slate-900 text-2xl flex items-center gap-2">
            <DangerIcon size={24} className="text-danger" />
            SOS Emergency
          </h1>
          <p className="text-slate-500 text-sm mt-0.5">Real-time safety alerts and emergency responses</p>
        </div>
        {active.length > 0 && (
          <div className="flex items-center gap-2 px-4 py-2 rounded-xl bg-danger/10 border border-danger/30 text-danger font-semibold text-sm animate-pulse">
            <AlertDiamondIcon size={16} />
            {active.length} Active Alert{active.length > 1 ? 's' : ''}
          </div>
        )}
      </div>

      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        {[
          { label: 'Active', value: alerts.filter((a) => a.status === 'active').length, color: 'text-danger', icon: DangerIcon },
          { label: 'Responding', value: alerts.filter((a) => a.status === 'responding').length, color: 'text-warning', icon: HeadsetIcon },
          { label: 'Resolved Today', value: resolved.length, color: 'text-success', icon: CheckmarkCircle01Icon },
          { label: 'Total Alerts', value: alerts.length, color: 'text-primary', icon: AlertDiamondIcon },
        ].map(({ label, value, color, icon: Icon }) => (
          <div key={label} className="bg-dark-card border border-dark-border rounded-2xl p-4">
            <div className="flex items-center gap-2 mb-2"><Icon size={15} className={color} /><span className="text-xs text-slate-500">{label}</span></div>
            <p className={`font-heading font-bold text-2xl ${color}`}>{value}</p>
          </div>
        ))}
      </div>

      {active.length > 0 && (
        <div>
          <h2 className="font-heading font-semibold text-danger mb-3 flex items-center gap-2">
            <AlertDiamondIcon size={16} /> Active Alerts
          </h2>
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
            {active.map((a) => <SosItem key={a.id} sos={a} onResolve={resolve} onRespond={respond} />)}
          </div>
        </div>
      )}

      {resolved.length > 0 && (
        <div>
          <h2 className="font-heading font-semibold text-slate-500 mb-3">Resolved</h2>
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
            {resolved.map((a) => <SosItem key={a.id} sos={a} onResolve={resolve} onRespond={respond} />)}
          </div>
        </div>
      )}

      {alerts.length === 0 && (
        <div className="py-20 text-center">
          <Shield01Icon size={40} className="text-success mx-auto mb-3" />
          <p className="font-heading font-semibold text-slate-500">All clear — no active alerts</p>
          <p className="text-slate-500 text-sm mt-1">Real-time SOS alerts will appear here</p>
        </div>
      )}
    </div>
  );
}
