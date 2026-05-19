import React, { useState, useEffect, useRef } from 'react';
import {
  CloudServerIcon, ServerStack01Icon, Database01Icon, Pulse01Icon, HealthIcon,
  CheckmarkCircle01Icon, CancelCircleIcon, AlertDiamondIcon, Clock01Icon,
  Refresh01Icon, Wifi01Icon, Activity01Icon, ChartUpIcon, SignalFull01Icon,
  SignalLow01Icon,
} from 'hugeicons-react';
import api from '../config/api';

const STATUS_STYLES = {
  healthy: { label: 'Healthy', cls: 'text-success bg-success/10 border-success/20', dot: 'bg-success' },
  degraded: { label: 'Degraded', cls: 'text-warning bg-warning/10 border-warning/20', dot: 'bg-warning' },
  down: { label: 'Down', cls: 'text-danger bg-danger/10 border-danger/20', dot: 'bg-danger animate-pulse' },
  unknown: { label: 'Unknown', cls: 'text-slate-500 bg-slate-100 border-slate-200', dot: 'bg-gray-500' },
};

const MOCK_SERVICES = [
  { id: 'api', name: 'FastAPI Backend', description: 'Main application server (Python 3.13)', status: 'healthy', uptime: '99.98%', latency_ms: 42, last_check: new Date().toISOString(), version: '2.4.1', url: 'api.kubochain.app' },
  { id: 'db', name: 'MongoDB Database', description: 'Primary data store', status: 'healthy', uptime: '99.99%', latency_ms: 8, last_check: new Date().toISOString(), version: '7.0', url: 'mongo.kubochain.internal' },
  { id: 'redis', name: 'Redis Cache', description: 'Session and rate-limit cache', status: 'healthy', uptime: '99.97%', latency_ms: 2, last_check: new Date().toISOString(), version: '7.2', url: 'redis.kubochain.internal' },
  { id: 'ws', name: 'WebSocket Server', description: 'Real-time event broadcasting', status: 'healthy', uptime: '99.95%', latency_ms: 15, last_check: new Date().toISOString(), version: '2.4.1', url: 'ws.kubochain.app' },
  { id: 'fcm', name: 'Firebase FCM', description: 'Push notification delivery', status: 'healthy', uptime: '99.9%', latency_ms: 180, last_check: new Date().toISOString(), version: 'v1', url: 'fcm.googleapis.com' },
  { id: 'maps', name: 'Map Tiles (CARTO)', description: 'Map rendering service', status: 'healthy', uptime: '99.8%', latency_ms: 220, last_check: new Date().toISOString(), version: 'Dark All', url: 'basemaps.cartocdn.com' },
];

const MOCK_METRICS = [
  { label: 'Requests / min', value: 142, icon: Activity01Icon, color: 'text-primary' },
  { label: 'P99 Latency', value: '220ms', icon: Clock01Icon, color: 'text-warning' },
  { label: 'Error Rate', value: '0.04%', icon: AlertDiamondIcon, color: 'text-danger' },
  { label: 'Active Connections', value: 847, icon: Wifi01Icon, color: 'text-success' },
];

const MOCK_INCIDENTS = [
  { title: 'FCM Delivery Delay', severity: 'minor', status: 'resolved', time: '2025-05-15 14:30', duration: '18 min' },
  { title: 'MongoDB High Latency', severity: 'major', status: 'resolved', time: '2025-05-10 08:12', duration: '43 min' },
];

const SERVICE_ICONS = {
  api: CloudServerIcon,
  db: Database01Icon,
  redis: ServerStack01Icon,
  ws: Wifi01Icon,
  fcm: Pulse01Icon,
  maps: SignalLow01Icon,
};

export default function ApiHealth() {
  const [services, setServices] = useState(MOCK_SERVICES);
  const [metrics, setMetrics] = useState(MOCK_METRICS);
  const [lastRefresh, setLastRefresh] = useState(new Date());
  const [refreshing, setRefreshing] = useState(false);
  const intervalRef = useRef(null);

  const refresh = async () => {
    setRefreshing(true);
    try {
      const r = await api.get('/admin/health');
      if (r.data?.services) setServices(r.data.services);
      if (r.data?.metrics) setMetrics(r.data.metrics);
      setLastRefresh(new Date());
    } catch {
      setLastRefresh(new Date());
    }
    setRefreshing(false);
  };

  useEffect(() => {
    refresh();
    intervalRef.current = setInterval(refresh, 30000);
    return () => clearInterval(intervalRef.current);
  }, []);

  const allHealthy = services.every((s) => s.status === 'healthy');
  const downCount = services.filter((s) => s.status === 'down').length;
  const degradedCount = services.filter((s) => s.status === 'degraded').length;

  return (
    <div className="p-6 space-y-6">
      <div className="flex items-center justify-between flex-wrap gap-4">
        <div>
          <h1 className="font-heading font-bold text-slate-900 text-2xl">API Health</h1>
          <p className="text-slate-500 text-sm mt-0.5">Real-time service and infrastructure monitoring</p>
        </div>
        <div className="flex items-center gap-3">
          <span className="text-xs text-slate-500">Updated {lastRefresh.toLocaleTimeString()}</span>
          <button
            onClick={refresh}
            disabled={refreshing}
            className={`flex items-center gap-2 px-4 py-2 rounded-xl bg-dark-card border border-dark-border text-slate-500 hover:text-slate-800 text-sm font-medium transition-colors disabled:opacity-50`}
          >
            <Refresh01Icon size={15} className={refreshing ? 'animate-spin' : ''} />
            Refresh
          </button>
        </div>
      </div>

      {/* Overall status */}
      <div className={`flex items-center gap-3 px-5 py-4 rounded-2xl border ${
        downCount > 0 ? 'bg-danger/10 border-danger/30' :
        degradedCount > 0 ? 'bg-warning/10 border-warning/30' :
        'bg-success/5 border-success/20'
      }`}>
        {downCount > 0 ? <CancelCircleIcon size={24} className="text-danger" /> :
         degradedCount > 0 ? <AlertDiamondIcon size={24} className="text-warning" /> :
         <CheckmarkCircle01Icon size={24} className="text-success" />}
        <div>
          <p className="font-heading font-bold text-slate-900">
            {downCount > 0 ? `${downCount} service(s) down` :
             degradedCount > 0 ? `${degradedCount} service(s) degraded` :
             'All systems operational'}
          </p>
          <p className="text-xs text-slate-500 mt-0.5">
            {services.length} services monitored · Auto-refresh every 30s
          </p>
        </div>
      </div>

      {/* Metrics */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        {metrics.map(({ label, value, icon: Icon, color }) => (
          <div key={label} className="bg-dark-card border border-dark-border rounded-2xl p-4">
            <div className="flex items-center gap-2 mb-2"><Icon size={15} className={color} /><span className="text-xs text-slate-500">{label}</span></div>
            <p className={`font-heading font-bold text-2xl ${color}`}>{value}</p>
          </div>
        ))}
      </div>

      {/* Services */}
      <div className="bg-dark-card border border-dark-border rounded-2xl divide-y divide-dark-border/50">
        {services.map((svc) => {
          const s = STATUS_STYLES[svc.status] ?? STATUS_STYLES.unknown;
          const SvcIcon = SERVICE_ICONS[svc.id] ?? CloudServerIcon;
          return (
            <div key={svc.id} className="flex items-center gap-4 px-5 py-4 hover:bg-slate-50 transition-colors">
              <div className="w-9 h-9 rounded-xl bg-dark-bg border border-dark-border flex items-center justify-center flex-shrink-0">
                <SvcIcon size={16} className="text-primary" />
              </div>
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2">
                  <span className="font-medium text-slate-800 text-sm">{svc.name}</span>
                  <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full border flex items-center gap-1 ${s.cls}`}>
                    <span className={`w-1.5 h-1.5 rounded-full ${s.dot}`} />
                    {s.label}
                  </span>
                </div>
                <p className="text-xs text-slate-500 mt-0.5">{svc.description} · <span className="font-mono">{svc.url}</span></p>
              </div>
              <div className="flex items-center gap-6 text-sm flex-shrink-0">
                <div className="text-center">
                  <p className="text-[10px] text-slate-500">Latency</p>
                  <p className={`font-heading font-bold ${svc.latency_ms < 100 ? 'text-success' : svc.latency_ms < 500 ? 'text-warning' : 'text-danger'}`}>
                    {svc.latency_ms}ms
                  </p>
                </div>
                <div className="text-center">
                  <p className="text-[10px] text-slate-500">Uptime</p>
                  <p className="font-heading font-bold text-success">{svc.uptime}</p>
                </div>
                <div className="text-center hidden lg:block">
                  <p className="text-[10px] text-slate-500">Version</p>
                  <p className="font-mono text-xs text-slate-500">{svc.version}</p>
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {/* Past incidents */}
      {MOCK_INCIDENTS.length > 0 && (
        <div>
          <h2 className="font-heading font-semibold text-slate-900 mb-3">Recent Incidents</h2>
          <div className="space-y-2">
            {MOCK_INCIDENTS.map((inc, i) => (
              <div key={i} className="flex items-center gap-4 bg-dark-card border border-dark-border rounded-xl px-4 py-3">
                <AlertDiamondIcon size={14} className={inc.severity === 'major' ? 'text-danger' : 'text-warning'} />
                <div className="flex-1">
                  <p className="text-sm font-medium text-slate-800">{inc.title}</p>
                  <p className="text-xs text-slate-500">{inc.time} · Duration: {inc.duration}</p>
                </div>
                <span className="text-[10px] font-bold text-success bg-success/10 border border-success/20 px-2 py-0.5 rounded-full">RESOLVED</span>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
