import React, { useState, useEffect } from 'react';
import {
  Wallet01Icon, DollarCircleIcon, Invoice01Icon, CreditCardIcon, ChartUpIcon,
  ChartDownIcon, ArrowUp01Icon, ArrowDown01Icon, Coins01Icon, BankIcon,
  FileDownloadIcon, Refresh01Icon, PiggyBankIcon, Money01Icon,
  CheckmarkCircle01Icon, CancelCircleIcon, AlertCircleIcon,
} from 'hugeicons-react';
import {
  AreaChart, Area, BarChart, Bar, XAxis, YAxis, CartesianGrid, ResponsiveContainer,
  Tooltip, PieChart, Pie, Cell, Legend,
} from 'recharts';
import api from '../config/api';

const PERIODS = ['today', '7d', '30d', 'all'];
const PERIOD_LABELS = { today: 'Today', '7d': '7 Days', '30d': '30 Days', all: 'All Time' };

const MOCK_STATS = {
  total_revenue: 4850000,
  platform_commission: 727500,
  driver_earnings: 4122500,
  avg_fare: 5200,
  total_rides: 932,
  total_transactions: 1048,
  refunds_total: 24000,
  refunds_count: 5,
  pending_payouts: 128000,
};

const MOCK_CHART = [
  { day: 'Mon', revenue: 620000, commission: 93000, refunds: 0 },
  { day: 'Tue', revenue: 710000, commission: 106500, refunds: 4500 },
  { day: 'Wed', revenue: 540000, commission: 81000, refunds: 8000 },
  { day: 'Thu', revenue: 830000, commission: 124500, refunds: 0 },
  { day: 'Fri', revenue: 960000, commission: 144000, refunds: 7200 },
  { day: 'Sat', revenue: 1100000, commission: 165000, refunds: 0 },
  { day: 'Sun', revenue: 790000, commission: 118500, refunds: 4300 },
];

const MOCK_BY_TYPE = [
  { type: 'Standard', revenue: 2200000, rides: 480, pct: 45 },
  { type: 'Express',  revenue: 1300000, rides: 280, pct: 27 },
  { type: 'Shared',   revenue: 850000,  rides: 112, pct: 18 },
  { type: 'Premium',  revenue: 500000,  rides: 60,  pct: 10 },
];

const MOCK_TRANSACTIONS = [
  { id: 'txn-001', rider: 'Jean-Pierre B.', driver: 'Sylvie N.', amount: 4500, commission: 675, status: 'completed', created_at: '2025-05-17T14:32:00Z' },
  { id: 'txn-002', rider: 'Marie K.',        driver: 'Rodrigue M.', amount: 6200, commission: 930, status: 'completed', created_at: '2025-05-17T13:18:00Z' },
  { id: 'txn-003', rider: 'Alain T.',        driver: 'Grace L.', amount: 3800, commission: 570, status: 'pending', created_at: '2025-05-17T12:55:00Z' },
  { id: 'txn-004', rider: 'Sophie M.',       driver: 'Patrick N.', amount: 8900, commission: 1335, status: 'completed', created_at: '2025-05-17T11:40:00Z' },
  { id: 'txn-005', rider: 'Christian A.',    driver: 'Esther B.', amount: 5100, commission: 765, status: 'refunded', created_at: '2025-05-17T10:22:00Z' },
];

const MOCK_REFUNDS = [
  { id: 'REF-001', rider: 'Marie Kamanda',   amount: 7200, reason: 'Driver cancelled mid-ride', ride_id: 'RD-4480', status: 'completed', date: '2025-05-17T11:00:00Z' },
  { id: 'REF-002', rider: 'Alain Tshimanga', amount: 5500, reason: 'Duplicate charge',          ride_id: 'RD-4461', status: 'pending',   date: '2025-05-17T07:30:00Z' },
  { id: 'REF-003', rider: 'Sophie Muhindo',  amount: 8000, reason: 'Driver no-show',            ride_id: 'RD-4440', status: 'pending',   date: '2025-05-16T18:20:00Z' },
  { id: 'REF-004', rider: 'Jeanne Mapendo',  amount: 1200, reason: 'Partial refund — long route', ride_id: 'RD-4418', status: 'completed', date: '2025-05-15T08:00:00Z' },
];

const SPLIT_COLORS = ['#2563EB', '#16A34A'];
const TYPE_COLORS  = ['#2563EB', '#16A34A', '#D97706', '#EA580C'];

const STATUS_BADGE = {
  completed: 'text-success bg-success/10 border-success/20',
  pending:   'text-warning bg-warning/10 border-warning/20',
  refunded:  'text-danger bg-danger/10 border-danger/20',
};

function fmt(n) {
  if (n >= 1000000) return `FC ${(n / 1000000).toFixed(1)}M`;
  if (n >= 1000)    return `FC ${(n / 1000).toFixed(0)}K`;
  return `FC ${n}`;
}

function exportCSV(transactions, period) {
  const rows = [
    ['Txn ID', 'Rider', 'Driver', 'Amount (FC)', 'Commission (FC)', 'Status', 'Time'],
    ...transactions.map((t) => [t.id, t.rider, t.driver, t.amount, t.commission, t.status, t.created_at]),
  ];
  const csv = rows.map((r) => r.join(',')).join('\n');
  const a = document.createElement('a');
  a.href = 'data:text/csv,' + encodeURIComponent(csv);
  a.download = `finance-${period}-${new Date().toISOString().slice(0, 10)}.csv`;
  a.click();
}

export default function FinanceDashboard() {
  const [period, setPeriod] = useState('7d');
  const [stats, setStats] = useState(MOCK_STATS);
  const [chart, setChart] = useState(MOCK_CHART);
  const [transactions, setTransactions] = useState(MOCK_TRANSACTIONS);
  const [refunds, setRefunds] = useState(MOCK_REFUNDS);
  const [activeTab, setActiveTab] = useState('overview');

  useEffect(() => {
    (async () => {
      try {
        const [sRes, cRes, tRes] = await Promise.all([
          api.get(`/admin/finance/stats?period=${period}`),
          api.get(`/admin/finance/chart?period=${period}`),
          api.get('/admin/transactions?page=1'),
        ]);
        if (sRes.data) setStats(sRes.data);
        if (cRes.data) setChart(cRes.data);
        if (tRes.data) setTransactions(tRes.data);
      } catch {}
    })();
  }, [period]);

  const processRefund = async (id) => {
    try { await api.post(`/admin/finance/refunds/${id}/approve`); } catch {}
    setRefunds((prev) => prev.map((r) => r.id === id ? { ...r, status: 'completed' } : r));
  };

  const splitData = [
    { name: 'Platform Commission', value: stats.platform_commission },
    { name: 'Driver Earnings', value: stats.driver_earnings },
  ];

  const STAT_CARDS = [
    { label: 'Total Revenue',       value: fmt(stats.total_revenue),       icon: Wallet01Icon,    color: 'text-primary', change: '+12.4%', up: true },
    { label: 'Platform Commission', value: fmt(stats.platform_commission),  icon: PiggyBankIcon,   color: 'text-success', change: '+12.4%', up: true },
    { label: 'Driver Earnings',     value: fmt(stats.driver_earnings),      icon: DollarCircleIcon,color: 'text-orange',  change: '+11.8%', up: true },
    { label: 'Avg Fare',            value: `FC ${stats.avg_fare?.toLocaleString()}`, icon: Money01Icon, color: 'text-warning', change: '-2.1%', up: false },
  ];

  return (
    <div className="p-6 space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between flex-wrap gap-4">
        <div>
          <h1 className="font-heading font-bold text-slate-900 text-2xl">Finance Dashboard</h1>
          <p className="text-slate-500 text-sm mt-0.5">Revenue, commissions, and transaction overview</p>
        </div>
        <div className="flex items-center gap-2">
          <div className="flex bg-white border border-dark-border rounded-xl p-1 gap-1">
            {PERIODS.map((p) => (
              <button key={p} onClick={() => setPeriod(p)}
                className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition-all ${period === p ? 'bg-primary text-slate-800 shadow-sm' : 'text-slate-500 hover:text-slate-700'}`}>
                {PERIOD_LABELS[p]}
              </button>
            ))}
          </div>
          <button onClick={() => exportCSV(transactions, period)} className="flex items-center gap-2 px-4 py-2 rounded-xl bg-white border border-dark-border text-slate-500 hover:text-slate-800 text-sm font-medium transition-colors">
            <FileDownloadIcon size={15} /> Export CSV
          </button>
        </div>
      </div>

      {/* Stat cards */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        {STAT_CARDS.map(({ label, value, icon: Icon, color, change, up }) => (
          <div key={label} className="bg-white border border-dark-border rounded-2xl p-5">
            <Icon size={18} className={`${color} mb-3`} />
            <p className="text-xs text-slate-500 mb-1">{label}</p>
            <p className={`font-heading font-bold text-xl ${color}`}>{value}</p>
            <div className={`flex items-center gap-1 mt-2 text-xs font-semibold ${up ? 'text-success' : 'text-danger'}`}>
              {up ? <ArrowUp01Icon size={12} /> : <ArrowDown01Icon size={12} />}
              {change} vs last period
            </div>
          </div>
        ))}
      </div>

      {/* Revenue summary bar */}
      <div className="bg-white border border-dark-border rounded-2xl p-5">
        <div className="flex items-center justify-between mb-4">
          <div>
            <h2 className="font-heading font-semibold text-slate-900">Revenue Split</h2>
            <p className="text-xs text-slate-500 mt-0.5">Commission vs driver earnings for {PERIOD_LABELS[period]}</p>
          </div>
          <div className="flex items-center gap-4 text-xs text-slate-500">
            {splitData.map((s, i) => (
              <div key={s.name} className="flex items-center gap-1.5">
                <span className="w-2.5 h-2.5 rounded-full" style={{ backgroundColor: SPLIT_COLORS[i] }} />
                {s.name}: <strong className="text-slate-800">{fmt(s.value)}</strong>
              </div>
            ))}
          </div>
        </div>
        <div className="h-4 bg-slate-100 rounded-full overflow-hidden flex">
          {splitData.map((s, i) => {
            const pct = (s.value / stats.total_revenue) * 100;
            return <div key={s.name} className="h-full transition-all duration-700 rounded-full" style={{ width: `${pct}%`, backgroundColor: SPLIT_COLORS[i], marginLeft: i > 0 ? 2 : 0 }} />;
          })}
        </div>
        <div className="flex justify-between text-xs text-slate-400 mt-1.5">
          <span>{Math.round((stats.platform_commission / stats.total_revenue) * 100)}% platform</span>
          <span>{Math.round((stats.driver_earnings / stats.total_revenue) * 100)}% drivers</span>
        </div>
      </div>

      {/* Chart + Revenue by type */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        <div className="lg:col-span-2 bg-white border border-dark-border rounded-2xl p-5">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h2 className="font-heading font-semibold text-slate-900">Revenue Trend</h2>
              <p className="text-xs text-slate-500 mt-0.5">Daily breakdown for {PERIOD_LABELS[period]}</p>
            </div>
            <div className="flex items-center gap-3 text-xs">
              {[{ color: '#2563EB', label: 'Revenue' }, { color: '#16A34A', label: 'Commission' }, { color: '#DC2626', label: 'Refunds' }].map(({ color, label }) => (
                <div key={label} className="flex items-center gap-1.5 text-slate-500">
                  <div className="w-2.5 h-2.5 rounded-sm" style={{ backgroundColor: color }} />
                  {label}
                </div>
              ))}
            </div>
          </div>
          <ResponsiveContainer width="100%" height={220}>
            <BarChart data={chart} margin={{ top: 5, right: 10, left: 0, bottom: 5 }} barSize={12} barCategoryGap="30%">
              <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#E2E8F0" />
              <XAxis dataKey="day" axisLine={false} tickLine={false} tick={{ fill: '#94A3B8', fontSize: 11 }} />
              <YAxis axisLine={false} tickLine={false} tick={{ fill: '#94A3B8', fontSize: 11 }} tickFormatter={(v) => `${(v/1000).toFixed(0)}K`} />
              <Tooltip formatter={(v, n) => [`FC ${Number(v).toLocaleString()}`, n]} contentStyle={{ borderRadius: 12, border: '1px solid #E2E8F0', background: '#fff', fontSize: 12 }} />
              <Bar dataKey="revenue"    fill="#2563EB" radius={[4, 4, 0, 0]} />
              <Bar dataKey="commission" fill="#16A34A" radius={[4, 4, 0, 0]} />
              <Bar dataKey="refunds"    fill="#DC2626" radius={[4, 4, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>

        <div className="bg-white border border-dark-border rounded-2xl p-5">
          <h2 className="font-heading font-semibold text-slate-900 mb-4">Répartition des paiements</h2>
          <div className="space-y-3">
            {stats.by_method && Object.entries(stats.by_method).map(([method, data]) => {
              const label = method === 'airtel_money' ? 'Airtel Money' : 'Espèces';
              const color = method === 'airtel_money' ? '#E02020' : '#10B981';
              const total = Object.values(stats.by_method).reduce((s, v) => s + v.count, 0);
              const pct = total > 0 ? Math.round((data.count / total) * 100) : 0;
              return (
                <div key={method}>
                  <div className="flex justify-between text-sm mb-1.5">
                    <span className="font-medium" style={{ color }}>{label}</span>
                    <span className="text-slate-500 text-xs">{data.count} trajets · FC {Number(data.total).toLocaleString()}</span>
                  </div>
                  <div className="h-1.5 bg-slate-100 rounded-full overflow-hidden">
                    <div className="h-full rounded-full transition-all duration-700" style={{ width: `${pct}%`, backgroundColor: color }} />
                  </div>
                </div>
              );
            })}
          </div>
          <div className="mt-4 pt-4 border-t border-dark-border space-y-2">
            {[
              { label: 'Total Rides',       value: stats.total_rides?.toLocaleString(), icon: ChartUpIcon, color: 'text-primary' },
              { label: 'Commission Rate',   value: '15%',                               icon: Coins01Icon, color: 'text-success' },
              { label: 'Pending Payouts',   value: fmt(stats.pending_payouts),          icon: BankIcon,    color: 'text-warning' },
              { label: 'Refunds Issued',    value: fmt(stats.refunds_total),            icon: CreditCardIcon, color: 'text-danger' },
            ].map(({ label, value, icon: Icon, color }) => (
              <div key={label} className="flex items-center justify-between py-1.5">
                <div className="flex items-center gap-2">
                  <Icon size={13} className={color} />
                  <span className="text-xs text-slate-500">{label}</span>
                </div>
                <span className={`text-xs font-bold ${color}`}>{value}</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Tabs: Transactions | Refunds */}
      <div>
        <div className="flex gap-1 bg-slate-100 p-1 rounded-xl w-fit mb-4">
          {['overview', 'refunds'].map((t) => (
            <button key={t} onClick={() => setActiveTab(t)}
              className={`px-4 py-1.5 rounded-lg text-sm font-medium transition-all capitalize ${activeTab === t ? 'bg-white text-slate-900 shadow-sm' : 'text-slate-500 hover:text-slate-700'}`}>
              {t === 'overview' ? 'Transactions' : 'Refunds'}
              {t === 'refunds' && refunds.filter((r) => r.status === 'pending').length > 0 && (
                <span className="ml-1.5 bg-danger text-slate-800 text-[10px] font-bold px-1.5 py-0.5 rounded-full">
                  {refunds.filter((r) => r.status === 'pending').length}
                </span>
              )}
            </button>
          ))}
        </div>

        {activeTab === 'overview' && (
          <div className="bg-white border border-dark-border rounded-2xl overflow-hidden">
            <div className="flex items-center justify-between px-5 py-4 border-b border-dark-border">
              <h2 className="font-heading font-semibold text-slate-900">Recent Transactions</h2>
              <a href="/transactions" className="text-xs text-primary hover:underline">View all →</a>
            </div>
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-dark-border bg-slate-50">
                    {['Txn ID', 'Rider', 'Driver', 'Amount', 'Commission', 'Status', 'Time'].map((h) => (
                      <th key={h} className="px-4 py-3 text-left text-[11px] font-semibold uppercase tracking-widest text-slate-500">{h}</th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {transactions.map((txn) => (
                    <tr key={txn.id} className="border-b border-dark-border/60 hover:bg-slate-50 transition-colors">
                      <td className="px-4 py-3 font-mono text-xs text-slate-400">{txn.id}</td>
                      <td className="px-4 py-3 text-slate-800 font-medium">{txn.rider}</td>
                      <td className="px-4 py-3 text-slate-500">{txn.driver}</td>
                      <td className="px-4 py-3 font-heading font-semibold text-orange">FC {txn.amount.toLocaleString()}</td>
                      <td className="px-4 py-3 text-success font-semibold">FC {txn.commission.toLocaleString()}</td>
                      <td className="px-4 py-3">
                        <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full border ${STATUS_BADGE[txn.status]}`}>
                          {txn.status.toUpperCase()}
                        </span>
                      </td>
                      <td className="px-4 py-3 text-xs text-slate-400">
                        {new Date(txn.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {activeTab === 'refunds' && (
          <div className="bg-white border border-dark-border rounded-2xl overflow-hidden">
            <div className="flex items-center justify-between px-5 py-4 border-b border-dark-border">
              <div>
                <h2 className="font-heading font-semibold text-slate-900">Refund Requests</h2>
                <p className="text-xs text-slate-500 mt-0.5">{refunds.filter((r) => r.status === 'pending').length} pending approval</p>
              </div>
              <div className="flex items-center gap-2 text-xs text-slate-500">
                <span>Total refunded: <strong className="text-danger">{fmt(stats.refunds_total)}</strong></span>
              </div>
            </div>
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-dark-border bg-slate-50">
                    {['Ref ID', 'Rider', 'Reason', 'Ride', 'Amount', 'Status', 'Date', ''].map((h) => (
                      <th key={h} className="px-4 py-3 text-left text-[11px] font-semibold uppercase tracking-widest text-slate-500">{h}</th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {refunds.map((r) => (
                    <tr key={r.id} className="border-b border-dark-border/60 hover:bg-slate-50 transition-colors">
                      <td className="px-4 py-3 font-mono text-xs text-slate-400">{r.id}</td>
                      <td className="px-4 py-3 font-medium text-slate-800">{r.rider}</td>
                      <td className="px-4 py-3 text-xs text-slate-500 max-w-[180px] truncate">{r.reason}</td>
                      <td className="px-4 py-3">
                        {r.ride_id && (
                          <a href={`/rides/${r.ride_id}`} className="text-xs text-primary hover:underline">{r.ride_id}</a>
                        )}
                      </td>
                      <td className="px-4 py-3 font-heading font-bold text-orange text-sm">FC {r.amount.toLocaleString()}</td>
                      <td className="px-4 py-3">
                        <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full border ${r.status === 'completed' ? 'text-success bg-success/10 border-success/20' : 'text-warning bg-warning/10 border-warning/20'}`}>
                          {r.status.toUpperCase()}
                        </span>
                      </td>
                      <td className="px-4 py-3 text-xs text-slate-400">{new Date(r.date).toLocaleDateString()}</td>
                      <td className="px-4 py-3">
                        {r.status === 'pending' && (
                          <button onClick={() => processRefund(r.id)} className="text-xs font-semibold border border-success/20 bg-success/10 text-success px-2 py-1 rounded-lg hover:bg-success/20 transition-colors">
                            Approve
                          </button>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
