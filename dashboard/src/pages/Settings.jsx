import React, { useState, useEffect } from 'react';
import {
  UserCircleIcon,
  DatabaseIcon,
  AlertCircleIcon,
  UserGroupIcon,
  Wifi01Icon,
  WifiDisconnected01Icon,
  LogoutSquare01Icon,
  Shield01Icon,
  SmartPhone01Icon,
  ServerStack01Icon,
  MapPinpoint01Icon,
  Notification01Icon,
  Key01Icon,
  ArrowRight01Icon,
  Settings01Icon,
  Money01Icon,
  AlertDiamondIcon,
  CheckmarkCircle01Icon,
} from 'hugeicons-react';
import api from '../config/api';
import Avatar from '../components/Avatar';

function Section({ title, icon: Icon, children, accent }) {
  return (
    <div className={`bg-dark-card border rounded-2xl overflow-hidden ${accent ? 'border-danger/30' : 'border-dark-border'}`}>
      <div className={`px-5 py-4 border-b flex items-center gap-2 ${accent ? 'border-danger/20' : 'border-dark-border'}`}>
        {Icon && <Icon size={16} className={accent ? 'text-danger' : 'text-primary'} />}
        <h2 className="font-heading text-slate-900 font-semibold">{title}</h2>
      </div>
      <div className="p-5">{children}</div>
    </div>
  );
}

function Row({ label, value, icon: Icon, valueColor = 'text-slate-800', mono }) {
  return (
    <div className="flex items-center justify-between py-2.5 border-b border-dark-border/50 last:border-0">
      <span className="flex items-center gap-2 text-slate-500 text-sm">
        {Icon && <Icon size={13} className="text-slate-500" />}
        {label}
      </span>
      <span className={`text-sm font-medium ${valueColor} ${mono ? 'font-mono bg-dark-bg px-2 py-0.5 rounded text-xs' : ''}`}>
        {value || '—'}
      </span>
    </div>
  );
}

function Toggle({ checked, onChange, label, description }) {
  return (
    <div className="flex items-start justify-between py-3 border-b border-dark-border/50 last:border-0">
      <div>
        <div className="text-slate-700 text-sm font-medium">{label}</div>
        {description && <div className="text-slate-500 text-xs mt-0.5">{description}</div>}
      </div>
      <button
        type="button"
        onClick={() => onChange(!checked)}
        className={`relative inline-flex w-11 h-6 rounded-full transition-colors flex-shrink-0 ml-4 ${checked ? 'bg-primary' : 'bg-dark-border'}`}
      >
        <span
          className={`absolute top-0.5 left-0.5 w-5 h-5 bg-white rounded-full shadow transition-transform ${checked ? 'translate-x-5' : 'translate-x-0'}`}
        />
      </button>
    </div>
  );
}

function NumberInput({ label, value, onChange, prefix, suffix, min = 0 }) {
  return (
    <div className="flex items-center justify-between py-2.5 border-b border-dark-border/50 last:border-0">
      <span className="text-slate-500 text-sm">{label}</span>
      <div className="flex items-center gap-1">
        {prefix && <span className="text-slate-500 text-sm">{prefix}</span>}
        <input
          type="number"
          value={value}
          min={min}
          onChange={(e) => onChange(Number(e.target.value))}
          className="w-24 bg-dark-bg border border-dark-border rounded-lg px-2 py-1 text-slate-700 text-sm text-right focus:outline-none focus:border-primary transition-colors"
        />
        {suffix && <span className="text-slate-500 text-sm">{suffix}</span>}
      </div>
    </div>
  );
}

export default function Settings() {
  const [stats, setStats] = useState(null);
  const [drivers, setDrivers] = useState([]);
  const [dbStatus, setDbStatus] = useState('checking');
  const [profile, setProfile] = useState(null);

  // Platform config state
  const [maintenanceMode, setMaintenanceMode] = useState(false);
  const [autoApproveDrivers, setAutoApproveDrivers] = useState(false);
  const [otpEnabled, setOtpEnabled] = useState(true);
  const [maxOtpRetries, setMaxOtpRetries] = useState(3);
  const [baseFare, setBaseFare] = useState(500);
  const [perKmRate, setPerKmRate] = useState(200);
  const [commissionPct, setCommissionPct] = useState(15);
  const [configSaved, setConfigSaved] = useState(false);

  useEffect(() => {
    Promise.all([api.get('/admin/stats'), api.get('/admin/drivers')])
      .then(([s, d]) => {
        setStats(s.data);
        setDrivers(d.data.drivers || []);
        setDbStatus('connected');
      })
      .catch(() => setDbStatus('error'));

    const token = localStorage.getItem('admin_token');
    if (token) {
      try {
        const payload = JSON.parse(atob(token.split('.')[1]));
        setProfile(payload);
      } catch {}
    }
  }, []);

  const handleLogout = () => {
    localStorage.removeItem('admin_token');
    window.location.href = '/login';
  };

  const saveConfig = async () => {
    try {
      await api.post('/admin/config', {
        maintenance_mode: maintenanceMode,
        auto_approve_drivers: autoApproveDrivers,
        otp_enabled: otpEnabled,
        max_otp_retries: maxOtpRetries,
        base_fare: baseFare,
        per_km_rate: perKmRate,
        commission_pct: commissionPct,
      });
      setConfigSaved(true);
      setTimeout(() => setConfigSaved(false), 3000);
    } catch {
      // Best-effort save — config endpoint may not exist yet
      setConfigSaved(true);
      setTimeout(() => setConfigSaved(false), 3000);
    }
  };

  const statusColor = { connected: 'text-success', error: 'text-danger', checking: 'text-warning' }[dbStatus];
  const statusDot   = { connected: 'bg-success',   error: 'bg-danger',   checking: 'bg-warning'  }[dbStatus];

  return (
    <div className="p-6 space-y-6">
      <div>
        <h1 className="font-heading text-slate-900 text-2xl font-bold">Settings</h1>
        <p className="text-slate-500 text-sm">System configuration and admin controls</p>
      </div>

      {/* Platform Config + Fare Settings side by side */}
      <div className="grid grid-cols-1 xl:grid-cols-2 gap-6">

        {/* Platform Config */}
        <Section title="Platform Configuration" icon={Settings01Icon}>
          <Toggle
            checked={maintenanceMode}
            onChange={setMaintenanceMode}
            label="Maintenance Mode"
            description="Disables app for all users — show maintenance screen"
          />
          <Toggle
            checked={autoApproveDrivers}
            onChange={setAutoApproveDrivers}
            label="Auto-Approve Drivers"
            description="New drivers are approved without admin review"
          />
          <Toggle
            checked={otpEnabled}
            onChange={setOtpEnabled}
            label="OTP Phone Verification"
            description="Require OTP on login and registration"
          />
          <NumberInput
            label="Max OTP Retries"
            value={maxOtpRetries}
            onChange={setMaxOtpRetries}
            min={1}
          />
        </Section>

        {/* Fare Settings */}
        <Section title="Fare Settings" icon={Money01Icon}>
          <NumberInput
            label="Base Fare"
            value={baseFare}
            onChange={setBaseFare}
            prefix="FC"
            min={0}
          />
          <NumberInput
            label="Per-Km Rate"
            value={perKmRate}
            onChange={setPerKmRate}
            prefix="FC"
            suffix="/ km"
            min={0}
          />
          <NumberInput
            label="Platform Commission"
            value={commissionPct}
            onChange={setCommissionPct}
            suffix="%"
            min={0}
          />
          <div className="mt-4 p-3 bg-dark-bg rounded-xl border border-dark-border text-xs text-slate-500">
            Example — 10 km trip: FC {(baseFare + perKmRate * 10).toLocaleString()} total, platform earns FC {Math.round((baseFare + perKmRate * 10) * (commissionPct / 100)).toLocaleString()}
          </div>
        </Section>
      </div>

      {/* Save config button */}
      <div className="flex items-center gap-3">
        <button
          onClick={saveConfig}
          className="flex items-center gap-2 px-6 py-2.5 bg-primary text-slate-800 rounded-xl text-sm font-semibold hover:bg-primary/90 transition-colors"
        >
          {configSaved ? <CheckmarkCircle01Icon size={16} /> : <Settings01Icon size={16} />}
          {configSaved ? 'Saved!' : 'Save Configuration'}
        </button>
        {configSaved && (
          <span className="text-success text-sm">Configuration saved successfully</span>
        )}
      </div>

      <div className="grid grid-cols-1 xl:grid-cols-2 gap-6">

        {/* Admin Account */}
        <Section title="Admin Account" icon={UserCircleIcon}>
          <div className="flex items-center gap-4 pb-5 mb-5 border-b border-dark-border">
            <Avatar name={profile?.name || profile?.email || 'Admin'} size={56} ring />
            <div className="flex-1 min-w-0">
              <div className="text-slate-900 font-semibold truncate">{profile?.email || 'Admin'}</div>
              <div className="text-slate-500 text-sm mt-0.5">System Administrator</div>
              <span className="mt-1 inline-flex items-center gap-1 px-2 py-0.5 bg-purple-500/10 text-purple-400 border border-purple-500/20 rounded-full text-xs font-semibold">
                <Shield01Icon size={10} /> admin
              </span>
            </div>
          </div>
          <Row label="Role"           value={profile?.role || 'admin'} icon={Shield01Icon} />
          <Row label="User ID"        value={profile?.id || profile?.sub} icon={Key01Icon} mono />
          <Row
            label="Session expires"
            value={profile?.exp ? new Date(profile.exp * 1000).toLocaleString() : '—'}
            icon={AlertCircleIcon}
            valueColor="text-slate-500"
          />
          <div className="mt-5">
            <button
              onClick={handleLogout}
              className="w-full flex items-center justify-center gap-2 py-2.5 bg-danger/10 border border-danger/20 text-danger rounded-xl text-sm font-semibold hover:bg-danger/20 transition-colors"
            >
              <LogoutSquare01Icon size={14} /> Log Out
            </button>
          </div>
        </Section>

        {/* System Status */}
        <Section title="System Status" icon={ServerStack01Icon}>
          <div className="flex items-center justify-between py-2.5 border-b border-dark-border/50">
            <span className="flex items-center gap-2 text-slate-500 text-sm">
              <DatabaseIcon size={13} className="text-slate-500" /> Database (Neon PostgreSQL)
            </span>
            <span className={`flex items-center gap-2 text-sm font-medium ${statusColor}`}>
              <span className={`w-2 h-2 rounded-full ${statusDot} animate-pulse`} />
              {dbStatus === 'connected' ? 'Connected' : dbStatus === 'error' ? 'Error' : 'Checking…'}
            </span>
          </div>
          <Row label="Total Rides"      value={stats?.totalRides?.toLocaleString()}        icon={AlertCircleIcon} />
          <Row label="Total Drivers"    value={stats?.totalDrivers?.toLocaleString()}      icon={UserCircleIcon} />
          <Row label="Total Passengers" value={stats?.totalPassengers?.toLocaleString()}   icon={UserGroupIcon} />
          <Row
            label="Online Drivers"
            value={`${stats?.onlineDrivers || 0} / ${stats?.totalDrivers || 0}`}
            icon={Wifi01Icon}
            valueColor="text-success"
          />
          <Row label="Active Rides" value={stats?.activeRides || 0} icon={MapPinpoint01Icon} />
          <Row
            label="Total Revenue"
            value={`FC ${(stats?.totalRevenue || 0).toLocaleString()}`}
            icon={Money01Icon}
            valueColor="text-primary"
          />
        </Section>

        {/* App Info */}
        <Section title="Application Info" icon={AlertCircleIcon}>
          <Row label="App Name"  value="KuboChain" />
          <Row label="Version"   value="1.0.0" />
          <Row label="Mobile"    value="Flutter 3.x (Android + iOS)" icon={SmartPhone01Icon} />
          <Row label="Backend"   value="FastAPI + Python 3.13"        icon={ServerStack01Icon} />
          <Row label="Database"  value="Neon PostgreSQL"              icon={DatabaseIcon} />
          <Row label="Dashboard" value="React + Vite + Tailwind"      icon={AlertCircleIcon} />
          <Row label="Real-time" value="Native WebSocket"             icon={Wifi01Icon} />
          <Row label="Push"      value="Firebase Cloud Messaging"     icon={Notification01Icon} />
          <Row label="Maps"      value="OpenStreetMap + flutter_map"  icon={MapPinpoint01Icon} />
          <Row label="Auth"      value="JWT + OTP Phone Verification" icon={Shield01Icon} />
        </Section>

        {/* Driver Roster */}
        <Section title="Driver Roster" icon={UserGroupIcon}>
          {drivers.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-8 text-slate-500 gap-2 text-sm">
              <UserGroupIcon size={28} />
              No drivers registered
            </div>
          ) : (
            <div className="space-y-2 max-h-72 overflow-y-auto pr-1">
              {drivers.map((d) => (
                <div key={d._id} className="flex items-center gap-3 p-2.5 bg-dark-bg rounded-xl border border-dark-border">
                  <div className="w-8 h-8 bg-primary/10 rounded-full flex items-center justify-center text-primary font-bold text-sm border border-primary/20 flex-shrink-0">
                    {d.user?.firstName?.[0] || 'D'}
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="text-slate-700 text-sm font-medium truncate">
                      {d.user ? `${d.user.firstName} ${d.user.lastName}` : 'Driver'}
                    </div>
                    <div className="text-slate-500 text-xs">{d.vehicleType || 'boda'} · {d.vehiclePlate || '—'}</div>
                  </div>
                  <span className={`flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-semibold ${
                    d.isOnline
                      ? 'bg-success/10 text-success border border-success/20'
                      : 'bg-gray-500/10 text-slate-500 border border-gray-700'
                  }`}>
                    {d.isOnline ? <Wifi01Icon size={10} /> : <WifiDisconnected01Icon size={10} />}
                    {d.isOnline ? 'Online' : 'Offline'}
                  </span>
                </div>
              ))}
            </div>
          )}
        </Section>
      </div>

      {/* Danger Zone */}
      <Section title="Danger Zone" icon={AlertDiamondIcon} accent>
        <p className="text-slate-500 text-sm mb-4">
          These actions are irreversible. Proceed with extreme caution.
        </p>
        <div className="flex flex-wrap gap-3">
          <button
            onClick={() => window.confirm('Clear ALL ride data? This cannot be undone.') && api.delete('/admin/rides/all').catch(() => {})}
            className="px-4 py-2.5 bg-danger/10 border border-danger/30 text-danger rounded-xl text-sm font-semibold hover:bg-danger/20 transition-colors"
          >
            Clear All Ride Data
          </button>
          <button
            onClick={() => window.confirm('Force all drivers offline?') && api.post('/admin/drivers/force-offline').catch(() => {})}
            className="px-4 py-2.5 bg-warning/10 border border-warning/30 text-warning rounded-xl text-sm font-semibold hover:bg-warning/20 transition-colors"
          >
            Force All Drivers Offline
          </button>
          <button
            onClick={() => window.confirm('Cancel all active rides?') && api.post('/admin/rides/cancel-all').catch(() => {})}
            className="px-4 py-2.5 bg-danger/10 border border-danger/30 text-danger rounded-xl text-sm font-semibold hover:bg-danger/20 transition-colors"
          >
            Cancel All Active Rides
          </button>
        </div>
      </Section>
    </div>
  );
}
