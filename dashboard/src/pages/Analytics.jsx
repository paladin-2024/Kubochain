import React, { useState, useEffect } from 'react';
import {
  AreaChart, Area, BarChart, Bar, LineChart, Line,
  XAxis, YAxis, CartesianGrid, PieChart, Pie, Cell,
  RadialBarChart, RadialBar, Legend,
} from 'recharts';
import {
  CheckCircle, DollarSign, Zap, XCircle,
  TrendingUp, Users, Trophy, Clock,
} from 'lucide-react';
import api from '../config/api';
import StatsCard from '../components/StatsCard';
import {
  ChartContainer, ChartTooltip, ChartTooltipContent,
  ChartLegend, ChartLegendContent,
} from '../components/ui/chart';

const PIE_COLORS = ['#27AE60', '#EB5757', '#2F80ED', '#E2B93B'];

export default function Analytics() {
  const [stats, setStats] = useState(null);
  const [reports, setReports] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    Promise.all([api.get('/admin/stats'), api.get('/admin/reports')])
      .then(([s, r]) => { setStats(s.data); setReports(r.data); })
      .catch(() => {})
      .finally(() => setLoading(false));
  }, []);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-full">
        <div className="flex items-center gap-3 text-gray-400">
          <div className="w-5 h-5 border-2 border-primary border-t-transparent rounded-full animate-spin" />
          Loading analytics…
        </div>
      </div>
    );
  }

  const dailyRevenue = stats?.dailyRevenue || [];
  const completionRate = stats?.totalRides
    ? Math.round((stats.completedRides / stats.totalRides) * 100) : 0;
  const avgFare = stats?.completedRides > 0
    ? Math.round((stats?.totalRevenue || 0) / stats.completedRides) : 0;
  const driverUtil = stats?.totalDrivers > 0
    ? Math.round((stats.onlineDrivers / stats.totalDrivers) * 100) : 0;

  const statusData = [
    { name: 'Completed', value: stats?.completedRides || 0 },
    { name: 'Cancelled', value: stats?.cancelledRides || 0 },
    { name: 'Active', value: stats?.activeRides || 0 },
  ].filter((d) => d.value > 0);

  const rawGrowth = reports?.userGrowth || [];
  const growthMap = {};
  rawGrowth.forEach(({ date, count, role }) => {
    if (!growthMap[date]) growthMap[date] = { date, passenger: 0, rider: 0 };
    growthMap[date][role] = parseInt(count);
  });
  const userGrowthData = Object.values(growthMap).sort((a, b) => a.date.localeCompare(b.date));
  const hourlyData = reports?.hourly || [];
  const topDrivers = (reports?.topDrivers || []).slice(0, 5);

  const revenueConfig = {
    revenue: { label: 'Revenue (FC)', color: '#2F80ED' },
  };
  const tripsConfig = {
    count: { label: 'Trips', color: '#27AE60' },
  };
  const growthConfig = {
    passenger: { label: 'Passengers', color: '#2F80ED' },
    rider: { label: 'Riders', color: '#27AE60' },
  };
  const hourlyConfig = {
    count: { label: 'Trips', color: '#E2B93B' },
  };

  return (
    <div className="p-6 space-y-6">
      <div>
        <h1 className="text-white text-2xl font-bold">Analytics</h1>
        <p className="text-gray-400 text-sm">Performance metrics and platform insights</p>
      </div>

      {/* KPI cards */}
      <div className="grid grid-cols-2 xl:grid-cols-4 gap-4">
        <StatsCard label="Completion Rate" value={`${completionRate}%`} icon={CheckCircle} color="success" />
        <StatsCard label="Avg Fare (FC)" value={avgFare.toLocaleString()} icon={DollarSign} color="orange" />
        <StatsCard label="Driver Utilization" value={`${driverUtil}%`} icon={Zap} color="primary" />
        <StatsCard label="Cancelled Rides" value={stats?.cancelledRides || 0} icon={XCircle} color="danger" />
      </div>

      {/* Revenue area + Ride status pie */}
      <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
        <div className="xl:col-span-2 bg-dark-card border border-dark-border rounded-2xl p-5">
          <div className="mb-5">
            <h2 className="text-white font-semibold text-lg">Revenue — Last 7 Days</h2>
            <p className="text-gray-500 text-xs mt-0.5">Completed ride earnings</p>
          </div>
          {dailyRevenue.length > 0 ? (
            <ChartContainer config={revenueConfig} className="h-[240px]">
              <AreaChart data={dailyRevenue} margin={{ top: 5, right: 10, left: 10, bottom: 5 }}>
                <defs>
                  <linearGradient id="revGrad" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#2F80ED" stopOpacity={0.3} />
                    <stop offset="95%" stopColor="#2F80ED" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" vertical={false} />
                <XAxis dataKey="_id" axisLine={false} tickLine={false} />
                <YAxis axisLine={false} tickLine={false} tickFormatter={(v) => `${(v / 1000).toFixed(0)}k`} />
                <ChartTooltip content={<ChartTooltipContent formatter={(v) => [`FC ${Number(v).toLocaleString()}`, '']} />} />
                <Area type="monotone" dataKey="revenue" stroke="#2F80ED" fill="url(#revGrad)" />
              </AreaChart>
            </ChartContainer>
          ) : (
            <div className="flex items-center justify-center h-[240px] text-gray-600 text-sm">No revenue data yet</div>
          )}
        </div>

        <div className="bg-dark-card border border-dark-border rounded-2xl p-5">
          <div className="mb-5">
            <h2 className="text-white font-semibold text-lg">Ride Status</h2>
            <p className="text-gray-500 text-xs mt-0.5">All-time distribution</p>
          </div>
          <ChartContainer config={{}} className="h-[240px]">
            <PieChart>
              <Pie data={statusData} cx="50%" cy="50%" innerRadius={60} outerRadius={90} paddingAngle={4} dataKey="value">
                {statusData.map((_, i) => <Cell key={i} fill={PIE_COLORS[i]} />)}
              </Pie>
              <ChartTooltip content={<ChartTooltipContent />} />
              <Legend formatter={(v) => <span style={{ color: '#9E9E9E', fontSize: 11 }}>{v}</span>} />
            </PieChart>
          </ChartContainer>
        </div>
      </div>

      {/* Trips per day + Performance gauges */}
      <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
        <div className="xl:col-span-2 bg-dark-card border border-dark-border rounded-2xl p-5">
          <div className="mb-5">
            <h2 className="text-white font-semibold text-lg">Trips Per Day</h2>
            <p className="text-gray-500 text-xs mt-0.5">Last 7 days</p>
          </div>
          {dailyRevenue.length > 0 ? (
            <ChartContainer config={tripsConfig} className="h-[220px]">
              <BarChart data={dailyRevenue} margin={{ top: 5, right: 10, left: 0, bottom: 5 }}>
                <CartesianGrid strokeDasharray="3 3" vertical={false} />
                <XAxis dataKey="_id" axisLine={false} tickLine={false} />
                <YAxis axisLine={false} tickLine={false} />
                <ChartTooltip content={<ChartTooltipContent />} />
                <Bar dataKey="count" fill="#2F80ED" radius={[6, 6, 0, 0]} />
              </BarChart>
            </ChartContainer>
          ) : (
            <div className="flex items-center justify-center h-[220px] text-gray-600 text-sm">No data yet</div>
          )}
        </div>

        {/* KPI gauges */}
        <div className="bg-dark-card border border-dark-border rounded-2xl p-5">
          <div className="mb-5">
            <h2 className="text-white font-semibold text-lg">Platform Health</h2>
            <p className="text-gray-500 text-xs mt-0.5">Current metrics</p>
          </div>
          <div className="space-y-5 mt-2">
            {[
              { label: 'Completion Rate', value: completionRate, color: '#27AE60', icon: CheckCircle },
              { label: 'Driver Utilization', value: driverUtil, color: '#2F80ED', icon: Zap },
              { label: 'Cancellation Rate', value: stats?.totalRides ? Math.round((stats.cancelledRides / stats.totalRides) * 100) : 0, color: '#EB5757', icon: XCircle },
            ].map((m) => (
              <div key={m.label}>
                <div className="flex items-center justify-between text-sm mb-1.5">
                  <span className="flex items-center gap-1.5 text-gray-400">
                    <m.icon size={13} style={{ color: m.color }} />
                    {m.label}
                  </span>
                  <span className="text-white font-bold">{m.value}%</span>
                </div>
                <div className="h-2 bg-dark-bg rounded-full overflow-hidden">
                  <div
                    className="h-full rounded-full transition-all duration-700"
                    style={{ width: `${m.value}%`, backgroundColor: m.color }}
                  />
                </div>
              </div>
            ))}
          </div>
          <div className="mt-6 pt-4 border-t border-dark-border grid grid-cols-2 gap-3">
            <div className="bg-dark-bg border border-dark-border rounded-xl p-3 text-center">
              <div className="text-success text-xl font-bold">{completionRate}%</div>
              <div className="text-gray-500 text-xs mt-0.5">Completion</div>
            </div>
            <div className="bg-dark-bg border border-dark-border rounded-xl p-3 text-center">
              <div className="text-primary text-xl font-bold">{driverUtil}%</div>
              <div className="text-gray-500 text-xs mt-0.5">Driver Util.</div>
            </div>
          </div>
        </div>
      </div>

      {/* User growth */}
      <div className="bg-dark-card border border-dark-border rounded-2xl p-5">
        <div className="flex items-center gap-2 mb-5">
          <Users size={18} className="text-primary" />
          <div>
            <h2 className="text-white font-semibold text-lg">User Growth</h2>
            <p className="text-gray-500 text-xs">New signups over last 30 days</p>
          </div>
        </div>
        {userGrowthData.length > 0 ? (
          <ChartContainer config={growthConfig} className="h-[220px]">
            <LineChart data={userGrowthData} margin={{ top: 5, right: 10, left: 0, bottom: 5 }}>
              <CartesianGrid strokeDasharray="3 3" vertical={false} />
              <XAxis dataKey="date" axisLine={false} tickLine={false} />
              <YAxis axisLine={false} tickLine={false} />
              <ChartTooltip content={<ChartTooltipContent />} />
              <ChartLegend content={<ChartLegendContent />} />
              <Line type="monotone" dataKey="passenger" stroke="#2F80ED" strokeWidth={2} dot={false} />
              <Line type="monotone" dataKey="rider" stroke="#27AE60" strokeWidth={2} dot={false} />
            </LineChart>
          </ChartContainer>
        ) : (
          <div className="flex items-center justify-center h-[220px] text-gray-600 text-sm">No growth data available</div>
        )}
      </div>

      {/* Hourly heatmap + Top performers */}
      <div className="grid grid-cols-1 xl:grid-cols-2 gap-6">
        <div className="bg-dark-card border border-dark-border rounded-2xl p-5">
          <div className="flex items-center gap-2 mb-5">
            <Clock size={18} className="text-warning" />
            <div>
              <h2 className="text-white font-semibold text-lg">Hourly Distribution</h2>
              <p className="text-gray-500 text-xs">Trips by hour of day</p>
            </div>
          </div>
          {hourlyData.length > 0 ? (
            <ChartContainer config={hourlyConfig} className="h-[180px]">
              <BarChart data={hourlyData} margin={{ top: 5, right: 5, left: 0, bottom: 5 }}>
                <CartesianGrid strokeDasharray="3 3" vertical={false} />
                <XAxis dataKey="hour" axisLine={false} tickLine={false} tick={{ fontSize: 9, fill: '#828282' }} interval={2} />
                <YAxis axisLine={false} tickLine={false} />
                <ChartTooltip content={<ChartTooltipContent />} />
                <Bar dataKey="count" radius={[4, 4, 0, 0]}>
                  {hourlyData.map((entry, i) => {
                    const max = Math.max(...hourlyData.map((h) => h.count), 1);
                    const t = entry.count / max;
                    return <Cell key={i} fill={`hsl(${210 + t * 50}, ${55 + t * 35}%, ${30 + t * 30}%)`} />;
                  })}
                </Bar>
              </BarChart>
            </ChartContainer>
          ) : (
            <div className="flex items-center justify-center h-[180px] text-gray-600 text-sm">No hourly data</div>
          )}
        </div>

        <div className="bg-dark-card border border-dark-border rounded-2xl p-5">
          <div className="flex items-center gap-2 mb-5">
            <Trophy size={18} className="text-warning" />
            <div>
              <h2 className="text-white font-semibold text-lg">Top Performers</h2>
              <p className="text-gray-500 text-xs">Drivers by earnings</p>
            </div>
          </div>
          {topDrivers.length > 0 ? (
            <div className="space-y-3">
              {topDrivers.map((d, i) => {
                const maxE = topDrivers[0]?.earnings || 1;
                const pct = (d.earnings / maxE) * 100;
                const medals = ['🥇', '🥈', '🥉'];
                const barColors = ['#E2B93B', '#9E9E9E', '#F2994A', '#2F80ED', '#27AE60'];
                return (
                  <div key={d.id}>
                    <div className="flex items-center justify-between text-sm mb-1">
                      <span className="text-gray-300 flex items-center gap-2">
                        <span className="text-base">{medals[i] || `#${d.rank}`}</span>
                        <span className="truncate max-w-[120px]">{d.name}</span>
                      </span>
                      <span className="text-white font-semibold text-xs">FC {d.earnings.toLocaleString()}</span>
                    </div>
                    <div className="h-1.5 bg-dark-bg rounded-full overflow-hidden">
                      <div
                        className="h-full rounded-full transition-all duration-500"
                        style={{ width: `${pct}%`, backgroundColor: barColors[i] }}
                      />
                    </div>
                    <div className="text-gray-600 text-xs mt-0.5">{d.trips} trips · ★ {d.rating.toFixed(1)}</div>
                  </div>
                );
              })}
            </div>
          ) : (
            <div className="flex items-center justify-center h-[180px] text-gray-600 text-sm">No driver data</div>
          )}
        </div>
      </div>
    </div>
  );
}
