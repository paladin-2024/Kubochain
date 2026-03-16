import React, { useState, useEffect, useCallback } from 'react';
import {
  AreaChart, Area, BarChart, Bar,
  XAxis, YAxis, CartesianGrid, Cell,
} from 'recharts';
import {
  Download, Calendar, TrendingUp, Users, Bike,
  DollarSign, FileText, RefreshCw,
} from 'lucide-react';
import api from '../config/api';
import {
  ChartContainer, ChartTooltip, ChartTooltipContent,
} from '../components/ui/chart';

// ─── CSV helpers ───────────────────────────────────────────────────────────────
function toCSV(rows, columns) {
  const header = columns.map((c) => c.label).join(',');
  const body = rows.map((r) =>
    columns.map((c) => {
      const v = typeof c.get === 'function' ? c.get(r) : r[c.key] ?? '';
      return `"${String(v).replace(/"/g, '""')}"`;
    }).join(',')
  ).join('\n');
  return `${header}\n${body}`;
}

function downloadCSV(csv, filename) {
  const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}

// ─── Weekly report builder ─────────────────────────────────────────────────────
function generateWeeklyReport(data, from, to) {
  const sections = [];

  // Summary
  sections.push('=== WEEKLY SUMMARY ===');
  sections.push(`Period: ${from} to ${to}`);
  sections.push(`Total Revenue: FC ${Number(data?.summary?.revenue || 0).toLocaleString()}`);
  sections.push(`Total Trips: ${data?.summary?.trips || 0}`);
  sections.push(`Average Fare: FC ${Math.round(data?.summary?.avgFare || 0).toLocaleString()}`);
  sections.push('');

  // Daily breakdown
  sections.push('=== DAILY BREAKDOWN ===');
  sections.push(toCSV(data?.daily || [], [
    { label: 'Date', key: 'date' },
    { label: 'Revenue (FC)', key: 'revenue' },
    { label: 'Trip Count', key: 'count' },
  ]));
  sections.push('');

  // Top drivers
  sections.push('=== TOP DRIVERS ===');
  sections.push(toCSV(data?.topDrivers || [], [
    { label: 'Rank', key: 'rank' },
    { label: 'Driver Name', key: 'name' },
    { label: 'Total Trips', key: 'trips' },
    { label: 'Earnings (FC)', key: 'earnings' },
    { label: 'Rating', key: 'rating' },
  ]));
  sections.push('');

  // Ride types
  sections.push('=== REVENUE BY RIDE TYPE ===');
  sections.push(toCSV(data?.byType || [], [
    { label: 'Type', key: 'type' },
    { label: 'Revenue (FC)', key: 'revenue' },
    { label: 'Count', key: 'count' },
  ]));

  return sections.join('\n');
}

// ─── StatBox ───────────────────────────────────────────────────────────────────
function StatBox({ label, value, sub, icon: Icon, color = 'text-primary' }) {
  return (
    <div className="bg-dark-bg border border-dark-border rounded-2xl p-5">
      <div className="flex items-center gap-2 text-gray-500 text-xs uppercase tracking-wide font-semibold mb-3">
        {Icon && <Icon size={13} className={color} />}
        {label}
      </div>
      <div className="text-white text-3xl font-bold">{value}</div>
      {sub && <div className="text-gray-600 text-xs mt-1">{sub}</div>}
    </div>
  );
}

// ─── Main ──────────────────────────────────────────────────────────────────────
export default function Reports() {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [downloading, setDownloading] = useState(false);
  const [from, setFrom] = useState(() => {
    const d = new Date();
    d.setDate(d.getDate() - 30);
    return d.toISOString().slice(0, 10);
  });
  const [to, setTo] = useState(() => new Date().toISOString().slice(0, 10));

  const fetchReports = useCallback(() => {
    setLoading(true);
    api.get(`/admin/reports?from=${from}&to=${to}`)
      .then((res) => setData(res.data))
      .catch(() => {})
      .finally(() => setLoading(false));
  }, [from, to]);

  useEffect(() => { fetchReports(); }, [fetchReports]);

  // ── Set date range to last 7 days ──
  const setLastWeek = () => {
    const t = new Date().toISOString().slice(0, 10);
    const f = new Date(Date.now() - 6 * 86400000).toISOString().slice(0, 10);
    setFrom(f);
    setTo(t);
  };

  const setLastMonth = () => {
    const t = new Date().toISOString().slice(0, 10);
    const f = new Date(Date.now() - 29 * 86400000).toISOString().slice(0, 10);
    setFrom(f);
    setTo(t);
  };

  // ── Download weekly report (last 7 days) ──
  const handleDownloadWeekly = async () => {
    setDownloading(true);
    try {
      const wFrom = new Date(Date.now() - 6 * 86400000).toISOString().slice(0, 10);
      const wTo = new Date().toISOString().slice(0, 10);
      const res = await api.get(`/admin/reports?from=${wFrom}&to=${wTo}`);
      const csv = generateWeeklyReport(res.data, wFrom, wTo);
      downloadCSV(csv, `kubochain-weekly-report-${wTo}.csv`);
    } catch {}
    setDownloading(false);
  };

  // ── Download current date range ──
  const handleDownloadCurrent = () => {
    if (!data) return;
    const csv = generateWeeklyReport(data, from, to);
    downloadCSV(csv, `kubochain-report-${from}-to-${to}.csv`);
  };

  const revenueConfig = { revenue: { label: 'Revenue (FC)', color: '#2F80ED' } };
  const countConfig   = { count:   { label: 'Trips',       color: '#27AE60' } };

  return (
    <div className="p-6 space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-white text-2xl font-bold">Reports</h1>
          <p className="text-gray-400 text-sm">Revenue, trips and performance analysis</p>
        </div>

        {/* Download buttons */}
        <div className="flex items-center gap-2 flex-wrap">
          <button
            onClick={handleDownloadWeekly}
            disabled={downloading}
            className="flex items-center gap-2 px-4 py-2 bg-primary text-white rounded-xl text-sm font-medium hover:bg-primary/90 transition-colors disabled:opacity-50"
          >
            {downloading
              ? <RefreshCw size={14} className="animate-spin" />
              : <Download size={14} />}
            Weekly Report
          </button>
          <button
            onClick={handleDownloadCurrent}
            disabled={!data}
            className="flex items-center gap-2 px-4 py-2 bg-dark-card border border-dark-border text-gray-300 rounded-xl text-sm font-medium hover:border-primary/50 hover:text-white transition-colors disabled:opacity-40"
          >
            <FileText size={14} />
            Export Current
          </button>
        </div>
      </div>

      {/* Date range controls */}
      <div className="flex flex-wrap items-center gap-3">
        <div className="flex items-center gap-2">
          <span className="text-gray-500 text-xs font-medium">Quick:</span>
          <button
            onClick={setLastWeek}
            className="px-3 py-1.5 bg-dark-card border border-dark-border rounded-lg text-gray-400 text-xs hover:border-primary/50 hover:text-white transition-colors"
          >
            Last 7 days
          </button>
          <button
            onClick={setLastMonth}
            className="px-3 py-1.5 bg-dark-card border border-dark-border rounded-lg text-gray-400 text-xs hover:border-primary/50 hover:text-white transition-colors"
          >
            Last 30 days
          </button>
        </div>
        <div className="flex items-center gap-2 ml-auto">
          <Calendar size={14} className="text-gray-500" />
          <input
            type="date" value={from} onChange={(e) => setFrom(e.target.value)}
            className="bg-dark-card border border-dark-border rounded-xl px-3 py-2 text-sm text-white focus:outline-none focus:border-primary"
          />
          <span className="text-gray-600 text-sm">→</span>
          <input
            type="date" value={to} onChange={(e) => setTo(e.target.value)}
            className="bg-dark-card border border-dark-border rounded-xl px-3 py-2 text-sm text-white focus:outline-none focus:border-primary"
          />
          <button
            onClick={fetchReports}
            className="flex items-center gap-1.5 px-4 py-2 bg-primary text-white rounded-xl text-sm font-medium hover:bg-primary/90 transition-colors"
          >
            <RefreshCw size={13} />
            Apply
          </button>
        </div>
      </div>

      {loading ? (
        <div className="flex items-center justify-center py-24 text-gray-500">
          <div className="flex items-center gap-3">
            <div className="w-5 h-5 border-2 border-primary border-t-transparent rounded-full animate-spin" />
            Loading reports…
          </div>
        </div>
      ) : (
        <>
          {/* Summary Stats */}
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <StatBox
              icon={DollarSign} color="text-primary"
              label="Total Revenue"
              value={`FC ${Number(data?.summary?.revenue || 0).toLocaleString()}`}
              sub={`${data?.summary?.trips || 0} completed trips`}
            />
            <StatBox
              icon={Bike} color="text-success"
              label="Total Trips"
              value={(data?.summary?.trips || 0).toLocaleString()}
              sub="Completed in period"
            />
            <StatBox
              icon={TrendingUp} color="text-orange"
              label="Average Fare"
              value={`FC ${Math.round(data?.summary?.avgFare || 0).toLocaleString()}`}
              sub="Per completed trip"
            />
          </div>

          {/* Daily Revenue */}
          <div className="bg-dark-card border border-dark-border rounded-2xl p-5">
            <div className="mb-5">
              <h2 className="text-white font-semibold text-lg">Daily Revenue</h2>
              <p className="text-gray-500 text-xs mt-0.5">{from} → {to}</p>
            </div>
            {data?.daily?.length > 0 ? (
              <ChartContainer config={revenueConfig} className="h-[260px]">
                <AreaChart data={data.daily} margin={{ top: 5, right: 10, left: 10, bottom: 5 }}>
                  <defs>
                    <linearGradient id="rGrad" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#2F80ED" stopOpacity={0.3} />
                      <stop offset="95%" stopColor="#2F80ED" stopOpacity={0} />
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" vertical={false} />
                  <XAxis dataKey="date" axisLine={false} tickLine={false} />
                  <YAxis axisLine={false} tickLine={false} tickFormatter={(v) => `${(v / 1000).toFixed(0)}k`} />
                  <ChartTooltip content={<ChartTooltipContent formatter={(v) => [`FC ${Number(v).toLocaleString()}`, '']} />} />
                  <Area type="monotone" dataKey="revenue" stroke="#2F80ED" fill="url(#rGrad)" />
                </AreaChart>
              </ChartContainer>
            ) : (
              <div className="flex items-center justify-center h-[260px] text-gray-600 text-sm">No revenue data for this period</div>
            )}
          </div>

          {/* Daily trips */}
          <div className="bg-dark-card border border-dark-border rounded-2xl p-5">
            <div className="mb-5">
              <h2 className="text-white font-semibold text-lg">Daily Trip Count</h2>
            </div>
            {data?.daily?.length > 0 ? (
              <ChartContainer config={countConfig} className="h-[200px]">
                <BarChart data={data.daily} margin={{ top: 5, right: 10, left: 0, bottom: 5 }}>
                  <CartesianGrid strokeDasharray="3 3" vertical={false} />
                  <XAxis dataKey="date" axisLine={false} tickLine={false} />
                  <YAxis axisLine={false} tickLine={false} />
                  <ChartTooltip content={<ChartTooltipContent />} />
                  <Bar dataKey="count" fill="#27AE60" radius={[6, 6, 0, 0]} />
                </BarChart>
              </ChartContainer>
            ) : (
              <div className="flex items-center justify-center h-[200px] text-gray-600 text-sm">No data for this period</div>
            )}
          </div>

          {/* Revenue by type + Top drivers */}
          <div className="grid grid-cols-1 xl:grid-cols-2 gap-6">
            <div className="bg-dark-card border border-dark-border rounded-2xl p-5">
              <h2 className="text-white font-semibold text-lg mb-4">Revenue by Ride Type</h2>
              {data?.byType?.length > 0 ? (
                <div className="space-y-3">
                  {data.byType.map((t, i) => {
                    const max = Math.max(...data.byType.map((x) => x.revenue), 1);
                    const pct = (t.revenue / max) * 100;
                    const colors = ['#2F80ED', '#27AE60', '#E2B93B', '#EB5757', '#F2994A'];
                    return (
                      <div key={t.type}>
                        <div className="flex justify-between text-sm mb-1.5">
                          <span className="text-gray-300 capitalize">{t.type}</span>
                          <span className="text-white font-semibold">FC {Number(t.revenue).toLocaleString()}</span>
                        </div>
                        <div className="h-2 bg-dark-bg rounded-full overflow-hidden">
                          <div className="h-full rounded-full transition-all duration-500" style={{ width: `${pct}%`, backgroundColor: colors[i % colors.length] }} />
                        </div>
                        <div className="text-gray-600 text-xs mt-0.5">{t.count} trips</div>
                      </div>
                    );
                  })}
                </div>
              ) : (
                <div className="flex items-center justify-center h-32 text-gray-600 text-sm">No type data</div>
              )}
            </div>

            <div className="bg-dark-card border border-dark-border rounded-2xl p-5">
              <h2 className="text-white font-semibold text-lg mb-4">Top Drivers</h2>
              {data?.topDrivers?.length > 0 ? (
                <div className="space-y-2">
                  {data.topDrivers.slice(0, 8).map((d) => (
                    <div key={d.id} className="flex items-center gap-3 p-2.5 bg-dark-bg rounded-xl border border-dark-border">
                      <div className="w-7 h-7 bg-primary/10 rounded-full flex items-center justify-center text-primary text-xs font-bold flex-shrink-0">
                        {d.rank}
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="text-white text-sm font-medium truncate">{d.name}</div>
                        <div className="text-gray-600 text-xs">{d.trips} trips · ★ {d.rating.toFixed(1)}</div>
                      </div>
                      <div className="text-primary text-sm font-semibold">FC {Number(d.earnings).toLocaleString()}</div>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="flex items-center justify-center h-32 text-gray-600 text-sm">No driver data</div>
              )}
            </div>
          </div>

          {/* Hourly heatmap */}
          <div className="bg-dark-card border border-dark-border rounded-2xl p-5">
            <h2 className="text-white font-semibold text-lg mb-5">Hourly Trip Distribution</h2>
            {data?.hourly?.length > 0 ? (
              <ChartContainer config={{ count: { label: 'Trips', color: '#E2B93B' } }} className="h-[180px]">
                <BarChart data={data.hourly} margin={{ top: 5, right: 10, left: 0, bottom: 5 }}>
                  <CartesianGrid strokeDasharray="3 3" vertical={false} />
                  <XAxis dataKey="hour" axisLine={false} tickLine={false} tick={{ fontSize: 9, fill: '#828282' }} interval={1} />
                  <YAxis axisLine={false} tickLine={false} />
                  <ChartTooltip content={<ChartTooltipContent />} />
                  <Bar dataKey="count" radius={[4, 4, 0, 0]}>
                    {data.hourly.map((entry, i) => {
                      const max = Math.max(...data.hourly.map((h) => h.count), 1);
                      const t = entry.count / max;
                      return <Cell key={i} fill={`hsl(${40 + t * 20}, ${60 + t * 40}%, ${25 + t * 35}%)`} />;
                    })}
                  </Bar>
                </BarChart>
              </ChartContainer>
            ) : (
              <div className="flex items-center justify-center h-[180px] text-gray-600 text-sm">No hourly data</div>
            )}
          </div>
        </>
      )}
    </div>
  );
}
