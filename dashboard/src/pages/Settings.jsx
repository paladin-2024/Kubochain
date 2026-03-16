import React, { useState, useEffect } from 'react';
import {
  User, Database, Info, Users, Wifi, WifiOff,
  LogOut, Shield, Smartphone, Server, MapPin,
  Bell, KeyRound, ChevronRight,
} from 'lucide-react';
import api from '../config/api';

function Section({ title, icon: Icon, children }) {
  return (
    <div className="bg-dark-card border border-dark-border rounded-2xl overflow-hidden">
      <div className="px-5 py-4 border-b border-dark-border flex items-center gap-2">
        {Icon && <Icon size={16} className="text-primary" />}
        <h2 className="text-white font-semibold">{title}</h2>
      </div>
      <div className="p-5">{children}</div>
    </div>
  );
}

function Row({ label, value, icon: Icon, valueColor = 'text-white', mono }) {
  return (
    <div className="flex items-center justify-between py-2.5 border-b border-dark-border/50 last:border-0">
      <span className="flex items-center gap-2 text-gray-500 text-sm">
        {Icon && <Icon size={13} className="text-gray-600" />}
        {label}
      </span>
      <span className={`text-sm font-medium ${valueColor} ${mono ? 'font-mono bg-dark-bg px-2 py-0.5 rounded text-xs' : ''}`}>
        {value || '—'}
      </span>
    </div>
  );
}

export default function Settings() {
  const [stats, setStats] = useState(null);
  const [drivers, setDrivers] = useState([]);
  const [dbStatus, setDbStatus] = useState('checking');
  const [profile, setProfile] = useState(null);

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

  const statusColor = {
    connected: 'text-success',
    error: 'text-danger',
    checking: 'text-warning',
  }[dbStatus];

  const statusDot = {
    connected: 'bg-success',
    error: 'bg-danger',
    checking: 'bg-warning',
  }[dbStatus];

  return (
    <div className="p-6 space-y-6">
      <div>
        <h1 className="text-white text-2xl font-bold">Settings</h1>
        <p className="text-gray-400 text-sm">System information and admin configuration</p>
      </div>

      <div className="grid grid-cols-1 xl:grid-cols-2 gap-6">
        {/* Admin Account */}
        <Section title="Admin Account" icon={User}>
          <div className="flex items-center gap-4 pb-5 mb-5 border-b border-dark-border">
            <div className="w-14 h-14 bg-primary/10 rounded-2xl flex items-center justify-center text-primary text-2xl font-bold border border-primary/20">
              {profile?.email?.[0]?.toUpperCase() || 'A'}
            </div>
            <div className="flex-1 min-w-0">
              <div className="text-white font-semibold truncate">{profile?.email || 'Admin'}</div>
              <div className="text-gray-500 text-sm mt-0.5">System Administrator</div>
              <span className="mt-1 inline-flex items-center gap-1 px-2 py-0.5 bg-purple-500/10 text-purple-400 border border-purple-500/20 rounded-full text-xs font-semibold">
                <Shield size={10} /> admin
              </span>
            </div>
          </div>
          <Row label="Role" value={profile?.role || 'admin'} icon={Shield} />
          <Row label="User ID" value={profile?.id || profile?.sub} icon={KeyRound} mono />
          <Row
            label="Session expires"
            value={profile?.exp ? new Date(profile.exp * 1000).toLocaleString() : '—'}
            icon={Info}
            valueColor="text-gray-400"
          />
          <div className="mt-5">
            <button
              onClick={handleLogout}
              className="w-full flex items-center justify-center gap-2 py-2.5 bg-danger/10 border border-danger/20 text-danger rounded-xl text-sm font-semibold hover:bg-danger/20 transition-colors"
            >
              <LogOut size={14} /> Log Out
            </button>
          </div>
        </Section>

        {/* System Status */}
        <Section title="System Status" icon={Server}>
          <div className="flex items-center justify-between py-2.5 border-b border-dark-border/50">
            <span className="flex items-center gap-2 text-gray-500 text-sm">
              <Database size={13} className="text-gray-600" /> Database (Neon PostgreSQL)
            </span>
            <span className={`flex items-center gap-2 text-sm font-medium ${statusColor}`}>
              <span className={`w-2 h-2 rounded-full ${statusDot} animate-pulse`} />
              {dbStatus === 'connected' ? 'Connected' : dbStatus === 'error' ? 'Error' : 'Checking…'}
            </span>
          </div>
          <Row label="Total Rides" value={stats?.totalRides?.toLocaleString()} icon={Info} />
          <Row label="Total Drivers" value={stats?.totalDrivers?.toLocaleString()} icon={User} />
          <Row label="Total Passengers" value={stats?.totalPassengers?.toLocaleString()} icon={Users} />
          <Row
            label="Online Drivers"
            value={`${stats?.onlineDrivers || 0} / ${stats?.totalDrivers || 0}`}
            icon={Wifi}
            valueColor="text-success"
          />
          <Row label="Active Rides" value={stats?.activeRides || 0} icon={MapPin} />
          <Row
            label="Total Revenue"
            value={`FC ${(stats?.totalRevenue || 0).toLocaleString()}`}
            icon={Info}
            valueColor="text-primary"
          />
        </Section>

        {/* App Info */}
        <Section title="Application Info" icon={Info}>
          <Row label="App Name" value="KuboChain" />
          <Row label="Version" value="1.0.0" />
          <Row label="Mobile" value="Flutter 3.x (Android + iOS)" icon={Smartphone} />
          <Row label="Backend" value="Node.js + Express" icon={Server} />
          <Row label="Database" value="Neon PostgreSQL" icon={Database} />
          <Row label="Dashboard" value="React + Vite + Tailwind" icon={Info} />
          <Row label="Real-time" value="Socket.io" icon={Wifi} />
          <Row label="Push" value="Firebase Cloud Messaging" icon={Bell} />
          <Row label="Maps" value="OpenStreetMap + flutter_map" icon={MapPin} />
          <Row label="Auth" value="JWT + OTP Phone Verification" icon={Shield} />
        </Section>

        {/* Driver roster */}
        <Section title="Driver Roster" icon={Users}>
          {drivers.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-8 text-gray-600 gap-2 text-sm">
              <Users size={28} strokeWidth={1.5} />
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
                    <div className="text-white text-sm font-medium truncate">
                      {d.user ? `${d.user.firstName} ${d.user.lastName}` : 'Driver'}
                    </div>
                    <div className="text-gray-600 text-xs">{d.vehicleType || 'boda'} · {d.vehiclePlate || '—'}</div>
                  </div>
                  <span className={`flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-semibold ${
                    d.isOnline
                      ? 'bg-success/10 text-success border border-success/20'
                      : 'bg-gray-500/10 text-gray-500 border border-gray-700'
                  }`}>
                    {d.isOnline ? <Wifi size={10} /> : <WifiOff size={10} />}
                    {d.isOnline ? 'Online' : 'Offline'}
                  </span>
                </div>
              ))}
            </div>
          )}
        </Section>
      </div>
    </div>
  );
}
