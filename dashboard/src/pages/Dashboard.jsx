import React, { useState, useEffect, useCallback } from 'react';
import { AreaChart, Area, ResponsiveContainer } from 'recharts';
import {
  Bike, CalendarDays, Activity, DollarSign, UserCheck, Users,
  CheckCircle, RefreshCw, MapPin, Star, ArrowRight, TrendingUp,
  TrendingDown, Clock, Zap, Navigation, AlertCircle, Shield,
} from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import api from '../config/api';
import LiveMap from '../components/LiveMap';
import RideTable from '../components/RideTable';

// ─── Circular progress ring ────────────────────────────────────────────────────
function Ring({ value = 0, size = 80, stroke = 7, color = '#2F80ED', label, sub }) {
  const r = (size - stroke) / 2;
  const circ = 2 * Math.PI * r;
  const offset = circ - (Math.min(value, 100) / 100) * circ;
  return (
    <div className="flex flex-col items-center gap-1">
      <div className="relative" style={{ width: size, height: size }}>
        <svg width={size} height={size} className="-rotate-90">
          <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke="#1E2A3A" strokeWidth={stroke} />
          <circle
            cx={size / 2} cy={size / 2} r={r} fill="none"
            stroke={color} strokeWidth={stroke}
            strokeDasharray={circ} strokeDashoffset={offset}
            strokeLinecap="round"
            style={{ transition: 'stroke-dashoffset 0.8s ease' }}
          />
        </svg>
        <div className="absolute inset-0 flex items-center justify-center">
          <span className="text-white font-bold text-sm">{value}%</span>
        </div>
      </div>
      <div className="text-center">
        <div className="text-white text-xs font-semibold">{label}</div>
        {sub && <div className="text-gray-600 text-[10px]">{sub}</div>}
      </div>
    </div>
  );
}

// ─── Mini sparkline (no axes, just the curve) ──────────────────────────────────
function Sparkline({ data = [], dataKey = 'value', color = '#2F80ED' }) {
  if (!data.length) return null;
  return (
    <ResponsiveContainer width="100%" height={44}>
      <AreaChart data={data} margin={{ top: 4, right: 0, left: 0, bottom: 0 }}>
        <defs>
          <linearGradient id={`sg-${color.replace('#', '')}`} x1="0" y1="0" x2="0" y2="1">
            <stop offset="5%" stopColor={color} stopOpacity={0.3} />
            <stop offset="95%" stopColor={color} stopOpacity={0} />
          </linearGradient>
        </defs>
        <Area
          type="monotone" dataKey={dataKey}
          stroke={color} strokeWidth={1.8}
          fill={`url(#sg-${color.replace('#', '')})`}
          dot={false}
        />
      </AreaChart>
    </ResponsiveContainer>
  );
}

// ─── KPI card with sparkline ────────────────────────────────────────────────────
function KpiCard({ label, value, sub, icon: Icon, color, sparkData, sparkKey, trend }) {
  const palette = {
    primary: { icon: 'text-primary bg-primary/10 border-primary/20', stroke: '#2F80ED', glow: 'hover:border-primary/40' },
    success:  { icon: 'text-success bg-success/10 border-success/20', stroke: '#27AE60', glow: 'hover:border-success/40' },
    warning:  { icon: 'text-warning bg-warning/10 border-warning/20', stroke: '#E2B93B', glow: 'hover:border-warning/40' },
    orange:   { icon: 'text-orange bg-orange/10 border-orange/20',   stroke: '#F2994A', glow: 'hover:border-orange/40' },
    danger:   { icon: 'text-danger bg-danger/10 border-danger/20',   stroke: '#EB5757', glow: 'hover:border-danger/40' },
  };
  const p = palette[color] || palette.primary;

  return (
    <div className={`bg-dark-card border border-dark-border rounded-2xl p-5 transition-all duration-200 ${p.glow} hover:shadow-lg`}>
      <div className="flex items-start justify-between mb-3">
        <div className={`w-10 h-10 rounded-xl border flex items-center justify-center flex-shrink-0 ${p.icon}`}>
          {Icon && <Icon size={18} strokeWidth={2} />}
        </div>
        {trend !== undefined && (
          <div className={`flex items-center gap-1 text-xs font-semibold px-2 py-0.5 rounded-lg ${
            trend >= 0 ? 'bg-success/10 text-success' : 'bg-danger/10 text-danger'
          }`}>
            {trend >= 0 ? <TrendingUp size={11} /> : <TrendingDown size={11} />}
            {Math.abs(trend)}%
          </div>
        )}
      </div>
      <div className="text-gray-500 text-xs font-medium uppercase tracking-wide mb-1">{label}</div>
      <div className="text-white text-2xl font-bold mb-1">{value ?? '—'}</div>
      {sub && <div className="text-gray-600 text-xs">{sub}</div>}
      {sparkData && (
        <div className="mt-3 -mx-1">
          <Sparkline data={sparkData} dataKey={sparkKey || 'value'} color={p.stroke} />
        </div>
      )}
    </div>
  );
}

// ─── Activity event row ─────────────────────────────────────────────────────────
const EVENT_CONFIG = {
  completed:   { Icon: CheckCircle, color: 'text-success',  bg: 'bg-success/10',  label: 'Trip completed' },
  cancelled:   { Icon: AlertCircle, color: 'text-danger',   bg: 'bg-danger/10',   label: 'Ride cancelled' },
  in_progress: { Icon: Navigation,  color: 'text-primary',  bg: 'bg-primary/10',  label: 'Trip in progress' },
  accepted:    { Icon: UserCheck,   color: 'text-success',  bg: 'bg-success/10',  label: 'Driver accepted' },
  arriving:    { Icon: MapPin,      color: 'text-orange',   bg: 'bg-orange/10',   label: 'Driver arriving' },
  pending:     { Icon: Clock,       color: 'text-warning',  bg: 'bg-warning/10',  label: 'Ride requested' },
};

function timeAgo(dateStr) {
  const s = (Date.now() - new Date(dateStr)) / 1000;
  if (s < 60) return `${Math.floor(s)}s ago`;
  if (s < 3600) return `${Math.floor(s / 60)}m ago`;
  if (s < 86400) return `${Math.floor(s / 3600)}h ago`;
  return `${Math.floor(s / 86400)}d ago`;
}

// ─── Main dashboard ────────────────────────────────────────────────────────────
export default function Dashboard() {
  const navigate = useNavigate();
  const [stats, setStats] = useState(null);
  const [activeRides, setActiveRides] = useState([]);
  const [recentRides, setRecentRides] = useState([]);
  const [onlineDrivers, setOnlineDrivers] = useState([]);
  const [allDrivers, setAllDrivers] = useState([]);
  const [topDrivers, setTopDrivers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [lastUpdated, setLastUpdated] = useState(null);

  const fetchData = useCallback(async (isRefresh = false) => {
    if (isRefresh) setRefreshing(true);
    try {
      const [statsRes, activeRes, recentRes, driversRes, reportsRes] = await Promise.all([
        api.get('/admin/stats'),
        api.get('/admin/rides/active'),
        api.get('/admin/rides?limit=8'),
        api.get('/admin/drivers'),
        api.get('/admin/reports'),
      ]);

      setStats(statsRes.data);
      setActiveRides(activeRes.data.rides || []);
      setRecentRides(recentRes.data.rides || []);
      setTopDrivers((reportsRes.data.topDrivers || []).slice(0, 5));

      const drivers = (driversRes.data.drivers || []);
      setAllDrivers(drivers);
      setOnlineDrivers(
        drivers.filter((d) => d.isOnline).map((d) => ({
          id: d._id,
          name: d.user ? `${d.user.firstName} ${d.user.lastName}` : 'Driver',
          lat: d.location?.coordinates?.[1],
          lng: d.location?.coordinates?.[0],
        }))
      );
      setLastUpdated(new Date());
    } catch (err) {
      console.error('Dashboard fetch error:', err.message);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, []);

  useEffect(() => {
    fetchData();
    const t = setInterval(() => fetchData(), 15000);
    return () => clearInterval(t);
  }, [fetchData]);

  // Derived
  const completionRate = stats?.totalRides
    ? Math.round((stats.completedRides / stats.totalRides) * 100) : 0;
  const cancelRate = stats?.totalRides
    ? Math.round((stats.cancelledRides / stats.totalRides) * 100) : 0;
  const driverUtil = stats?.totalDrivers
    ? Math.round((stats.onlineDrivers / stats.totalDrivers) * 100) : 0;
  const dailyRevenue = stats?.dailyRevenue || [];
  const revenueSparkData = dailyRevenue.map((d) => ({ value: d.revenue, label: d._id }));
  const tripsSparkData   = dailyRevenue.map((d) => ({ value: d.count,   label: d._id }));

  const now = new Date();
  const hour = now.getHours();
  const greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
  const dateStr = now.toLocaleDateString('en-US', { weekday: 'long', month: 'long', day: 'numeric' });

  if (loading) {
    return (
      <div className="flex items-center justify-center h-full">
        <div className="flex flex-col items-center gap-4 text-gray-400">
          <div className="w-10 h-10 border-2 border-primary border-t-transparent rounded-full animate-spin" />
          <span className="text-sm">Loading dashboard…</span>
        </div>
      </div>
    );
  }

  return (
    <div className="p-6 space-y-6 min-h-full">

      {/* ── Hero header ──────────────────────────────────────────────────── */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <div className="flex items-center gap-2 mb-1">
            <span className="flex items-center gap-1.5 text-xs text-success font-semibold px-2.5 py-1 bg-success/10 border border-success/20 rounded-full">
              <span className="w-1.5 h-1.5 rounded-full bg-success animate-pulse" />
              Live
            </span>
            {lastUpdated && (
              <span className="text-gray-600 text-xs">Updated {timeAgo(lastUpdated)}</span>
            )}
          </div>
          <h1 className="text-white text-2xl font-bold">{greeting}, Admin</h1>
          <p className="text-gray-500 text-sm mt-0.5">{dateStr} · KuboChain Operations Center</p>
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={() => navigate('/reports')}
            className="flex items-center gap-2 px-4 py-2 bg-dark-card border border-dark-border rounded-xl text-sm text-gray-400 hover:border-primary/50 hover:text-white transition-all"
          >
            <TrendingUp size={14} /> Reports
          </button>
          <button
            onClick={() => fetchData(true)}
            disabled={refreshing}
            className="flex items-center gap-2 px-4 py-2 bg-primary text-white rounded-xl text-sm font-medium hover:bg-primary/90 transition-all disabled:opacity-50"
          >
            <RefreshCw size={14} className={refreshing ? 'animate-spin' : ''} />
            Refresh
          </button>
        </div>
      </div>

      {/* ── KPI cards ─────────────────────────────────────────────────────── */}
      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">
        <KpiCard
          label="Total Rides" icon={Bike} color="primary"
          value={stats?.totalRides?.toLocaleString()}
          sub={`${stats?.todayRides || 0} today`}
          sparkData={tripsSparkData} sparkKey="value"
        />
        <KpiCard
          label="Total Revenue" icon={DollarSign} color="orange"
          value={`FC ${(stats?.totalRevenue || 0).toLocaleString()}`}
          sub="All completed rides"
          sparkData={revenueSparkData} sparkKey="value"
        />
        <KpiCard
          label="Active Rides" icon={Activity} color="warning"
          value={stats?.activeRides || 0}
          sub="Right now"
        />
        <KpiCard
          label="Online Drivers" icon={UserCheck} color="success"
          value={`${stats?.onlineDrivers || 0} / ${stats?.totalDrivers || 0}`}
          sub={`${driverUtil}% utilization`}
        />
      </div>

      {/* ── Revenue chart + Platform health ─────────────────────────────── */}
      <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
        {/* Revenue 7-day area */}
        <div className="xl:col-span-2 bg-dark-card border border-dark-border rounded-2xl p-5">
          <div className="flex items-center justify-between mb-5">
            <div>
              <h2 className="text-white font-semibold text-lg">Revenue Trend</h2>
              <p className="text-gray-500 text-xs mt-0.5">Last 7 days — completed rides</p>
            </div>
            {dailyRevenue.length > 0 && (() => {
              const last = dailyRevenue[dailyRevenue.length - 1]?.revenue || 0;
              const prev = dailyRevenue[dailyRevenue.length - 2]?.revenue || 0;
              const pct = prev > 0 ? Math.round(((last - prev) / prev) * 100) : 0;
              return (
                <div className={`flex items-center gap-1 text-sm font-semibold px-3 py-1 rounded-xl ${
                  pct >= 0 ? 'bg-success/10 text-success' : 'bg-danger/10 text-danger'
                }`}>
                  {pct >= 0 ? <TrendingUp size={14} /> : <TrendingDown size={14} />}
                  {Math.abs(pct)}% vs yesterday
                </div>
              );
            })()}
          </div>
          {dailyRevenue.length > 0 ? (
            <ResponsiveContainer width="100%" height={200}>
              <AreaChart data={dailyRevenue} margin={{ top: 5, right: 10, left: 10, bottom: 5 }}>
                <defs>
                  <linearGradient id="revMain" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#2F80ED" stopOpacity={0.25} />
                    <stop offset="95%" stopColor="#2F80ED" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <Area
                  type="monotone" dataKey="revenue"
                  stroke="#2F80ED" strokeWidth={2.5}
                  fill="url(#revMain)" dot={false}
                />
              </AreaChart>
            </ResponsiveContainer>
          ) : (
            <div className="flex items-center justify-center h-[200px] text-gray-600 text-sm">No revenue data yet</div>
          )}
          {/* Day labels + values */}
          {dailyRevenue.length > 0 && (
            <div className="mt-3 flex justify-between gap-1">
              {dailyRevenue.map((d) => (
                <div key={d._id} className="flex-1 text-center">
                  <div className="text-gray-600 text-[10px] truncate">{d._id?.slice(5)}</div>
                  <div className="text-white text-xs font-semibold mt-0.5">{(d.count || 0)}</div>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Platform health */}
        <div className="bg-dark-card border border-dark-border rounded-2xl p-5">
          <div className="mb-5">
            <h2 className="text-white font-semibold text-lg">Platform Health</h2>
            <p className="text-gray-500 text-xs mt-0.5">Real-time KPIs</p>
          </div>
          <div className="flex justify-around mb-6">
            <Ring value={completionRate} color="#27AE60" label="Completion" sub="All time" />
            <Ring value={driverUtil}     color="#2F80ED" label="Driver Util" sub={`${stats?.onlineDrivers || 0} online`} />
          </div>
          <div className="flex justify-center">
            <Ring value={Math.max(0, 100 - cancelRate)} size={90} stroke={8} color="#E2B93B" label="Success Score" sub={`${cancelRate}% cancel rate`} />
          </div>
          <div className="mt-5 space-y-2">
            {[
              { label: 'Completed', val: stats?.completedRides || 0, color: 'bg-success' },
              { label: 'Active',    val: stats?.activeRides    || 0, color: 'bg-warning' },
              { label: 'Cancelled', val: stats?.cancelledRides || 0, color: 'bg-danger'  },
            ].map((item) => (
              <div key={item.label} className="flex items-center justify-between text-xs">
                <span className="flex items-center gap-2 text-gray-500">
                  <span className={`w-2 h-2 rounded-full ${item.color}`} />{item.label}
                </span>
                <span className="text-white font-semibold">{item.val.toLocaleString()}</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* ── Live Map + Active rides ───────────────────────────────────────── */}
      <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
        <div className="xl:col-span-2 bg-dark-card border border-dark-border rounded-2xl p-5">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h2 className="text-white font-semibold text-lg">Live Map</h2>
              <p className="text-gray-500 text-xs mt-0.5">{onlineDrivers.length} drivers tracked</p>
            </div>
            <div className="flex items-center gap-3 text-xs text-gray-500">
              <span className="flex items-center gap-1.5"><span className="w-2 h-2 bg-primary rounded-full" />Drivers</span>
              <span className="flex items-center gap-1.5"><span className="w-2 h-2 bg-success rounded-full" />Pickup</span>
              <span className="flex items-center gap-1.5"><span className="w-2 h-2 bg-danger rounded-full" />Drop-off</span>
            </div>
          </div>
          <LiveMap drivers={onlineDrivers} activeRides={activeRides} height="340px" />
        </div>

        {/* Active rides panel */}
        <div className="bg-dark-card border border-dark-border rounded-2xl p-5 flex flex-col">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-white font-semibold text-lg flex items-center gap-2">
              Active Rides
              <span className="px-2 py-0.5 bg-warning/10 text-warning text-xs rounded-full border border-warning/20 font-medium">
                {activeRides.length}
              </span>
            </h2>
            <button
              onClick={() => navigate('/rides')}
              className="text-primary text-xs hover:underline flex items-center gap-1"
            >
              View all <ArrowRight size={11} />
            </button>
          </div>
          <div className="flex-1 space-y-2.5 overflow-y-auto max-h-[300px]">
            {activeRides.length === 0 ? (
              <div className="flex flex-col items-center justify-center h-32 text-gray-600 text-sm gap-2">
                <Bike size={28} strokeWidth={1.5} />
                No active rides
              </div>
            ) : activeRides.map((ride) => (
              <div key={ride._id} className="p-3 bg-dark-bg rounded-xl border border-dark-border hover:border-dark-border/80 transition-colors">
                <div className="flex items-center justify-between mb-1.5">
                  <div className="flex items-center gap-2">
                    <div className="w-7 h-7 bg-primary/10 rounded-full flex items-center justify-center text-primary text-xs font-bold border border-primary/20">
                      {ride.passenger?.firstName?.[0] || '?'}
                    </div>
                    <span className="text-white text-sm font-medium">
                      {ride.passenger ? `${ride.passenger.firstName} ${ride.passenger.lastName}` : 'Passenger'}
                    </span>
                  </div>
                  <span className={`px-2 py-0.5 rounded-full text-[10px] font-semibold badge-${ride.status}`}>
                    {ride.status?.replace('_', ' ')}
                  </span>
                </div>
                <div className="flex items-center gap-1 text-xs text-gray-600 mb-1">
                  <MapPin size={10} className="text-success flex-shrink-0" />
                  <span className="truncate">{ride.pickup?.address?.split(',')[0]}</span>
                </div>
                <div className="flex items-center gap-1 text-xs text-gray-600 mb-2">
                  <MapPin size={10} className="text-danger flex-shrink-0" />
                  <span className="truncate">{ride.destination?.address?.split(',')[0]}</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-primary text-xs font-bold">FC {ride.price?.toLocaleString()}</span>
                  {ride.driver?.user && (
                    <span className="text-gray-600 text-[10px]">
                      {ride.driver.user.firstName} {ride.driver.user.lastName}
                    </span>
                  )}
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* ── Activity Feed + Top Drivers + Quick Actions ───────────────────── */}
      <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">

        {/* Recent Activity */}
        <div className="bg-dark-card border border-dark-border rounded-2xl p-5">
          <h2 className="text-white font-semibold text-lg mb-4 flex items-center gap-2">
            <Activity size={16} className="text-primary" />
            Recent Activity
          </h2>
          <div className="space-y-3">
            {recentRides.slice(0, 7).map((ride) => {
              const cfg = EVENT_CONFIG[ride.status] || EVENT_CONFIG.pending;
              return (
                <div key={ride._id} className="flex items-start gap-3">
                  <div className={`w-7 h-7 rounded-full ${cfg.bg} flex items-center justify-center flex-shrink-0 mt-0.5`}>
                    <cfg.Icon size={13} className={cfg.color} />
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="text-white text-xs font-semibold">{cfg.label}</div>
                    <div className="text-gray-500 text-[11px] truncate">
                      {ride.passenger
                        ? `${ride.passenger.firstName} ${ride.passenger.lastName}`
                        : 'Unknown'
                      } → {ride.destination?.address?.split(',')[0]}
                    </div>
                  </div>
                  <div className="text-gray-600 text-[10px] flex-shrink-0 mt-0.5">
                    {timeAgo(ride.createdAt)}
                  </div>
                </div>
              );
            })}
            {recentRides.length === 0 && (
              <div className="flex flex-col items-center py-8 text-gray-600 gap-2 text-sm">
                <Clock size={24} strokeWidth={1.5} />
                No recent activity
              </div>
            )}
          </div>
        </div>

        {/* Top Drivers */}
        <div className="bg-dark-card border border-dark-border rounded-2xl p-5">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-white font-semibold text-lg flex items-center gap-2">
              <Star size={16} className="text-warning" fill="#E2B93B" />
              Top Drivers
            </h2>
            <button onClick={() => navigate('/drivers')} className="text-primary text-xs hover:underline flex items-center gap-1">
              All <ArrowRight size={11} />
            </button>
          </div>
          <div className="space-y-3">
            {topDrivers.length > 0 ? topDrivers.map((d, i) => {
              const maxE = topDrivers[0]?.earnings || 1;
              const pct = Math.round((d.earnings / maxE) * 100);
              const medals = ['🥇', '🥈', '🥉'];
              return (
                <div key={d.id}>
                  <div className="flex items-center justify-between mb-1">
                    <span className="flex items-center gap-2 text-sm text-gray-300">
                      <span className="text-base">{medals[i] || `#${d.rank}`}</span>
                      <span className="truncate max-w-[110px]">{d.name}</span>
                    </span>
                    <span className="text-white text-xs font-bold">FC {d.earnings.toLocaleString()}</span>
                  </div>
                  <div className="h-1.5 bg-dark-bg rounded-full overflow-hidden">
                    <div
                      className="h-full rounded-full"
                      style={{
                        width: `${pct}%`,
                        backgroundColor: ['#E2B93B','#9E9E9E','#F2994A','#2F80ED','#27AE60'][i],
                        transition: 'width 0.7s ease',
                      }}
                    />
                  </div>
                  <div className="flex justify-between text-[10px] text-gray-600 mt-0.5">
                    <span>{d.trips} trips</span>
                    <span>★ {d.rating.toFixed(1)}</span>
                  </div>
                </div>
              );
            }) : (
              <div className="flex flex-col items-center py-8 text-gray-600 gap-2 text-sm">
                <Star size={24} strokeWidth={1.5} />
                No data yet
              </div>
            )}
          </div>
        </div>

        {/* Quick stats + actions */}
        <div className="bg-dark-card border border-dark-border rounded-2xl p-5 space-y-4">
          <h2 className="text-white font-semibold text-lg flex items-center gap-2">
            <Zap size={16} className="text-warning" />
            Quick Overview
          </h2>

          {/* Mini stat grid */}
          <div className="grid grid-cols-2 gap-2">
            {[
              { label: 'Passengers', value: stats?.totalPassengers?.toLocaleString() || 0, icon: Users, color: 'text-primary bg-primary/10' },
              { label: 'All Drivers', value: stats?.totalDrivers || 0, icon: UserCheck, color: 'text-success bg-success/10' },
              { label: 'Completed', value: stats?.completedRides?.toLocaleString() || 0, icon: CheckCircle, color: 'text-success bg-success/10' },
              { label: 'Today', value: stats?.todayRides || 0, icon: CalendarDays, color: 'text-warning bg-warning/10' },
            ].map((s) => (
              <div key={s.label} className="bg-dark-bg border border-dark-border rounded-xl p-3">
                <div className={`w-7 h-7 rounded-lg flex items-center justify-center mb-2 ${s.color}`}>
                  <s.icon size={14} />
                </div>
                <div className="text-white text-lg font-bold leading-tight">{s.value}</div>
                <div className="text-gray-600 text-[10px] mt-0.5">{s.label}</div>
              </div>
            ))}
          </div>

          {/* Quick navigation */}
          <div className="space-y-1.5">
            <p className="text-gray-600 text-[10px] font-semibold uppercase tracking-widest mb-2">Quick Actions</p>
            {[
              { label: 'View all rides',    path: '/rides',         icon: Bike,        color: 'text-primary' },
              { label: 'Manage drivers',    path: '/drivers',       icon: UserCheck,   color: 'text-success' },
              { label: 'Send notification', path: '/notifications', icon: Shield,      color: 'text-warning' },
              { label: 'Download report',   path: '/reports',       icon: TrendingUp,  color: 'text-orange'  },
            ].map((a) => (
              <button
                key={a.path}
                onClick={() => navigate(a.path)}
                className="w-full flex items-center justify-between px-3 py-2.5 bg-dark-bg border border-dark-border rounded-xl text-sm text-gray-400 hover:border-primary/40 hover:text-white transition-all group"
              >
                <span className="flex items-center gap-2.5">
                  <a.icon size={14} className={a.color} />
                  {a.label}
                </span>
                <ArrowRight size={13} className="text-gray-700 group-hover:text-primary transition-colors" />
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* ── Recent Rides Table ───────────────────────────────────────────── */}
      <div className="bg-dark-card border border-dark-border rounded-2xl p-5">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-white font-semibold text-lg">Recent Rides</h2>
          <button
            onClick={() => navigate('/rides')}
            className="flex items-center gap-1 text-primary text-xs hover:underline"
          >
            View all <ArrowRight size={11} />
          </button>
        </div>
        <RideTable rides={recentRides} />
      </div>

    </div>
  );
}
