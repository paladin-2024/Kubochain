import React, { useState, useEffect, useCallback } from 'react';
import {
  CustomerSupportIcon, Search01Icon, Cancel01Icon, Refresh01Icon, UserBlock01Icon,
  CheckmarkCircle01Icon, Clock01Icon, AlertCircleIcon, CancelCircleIcon,
  ArrowRight01Icon, MessageAdd01Icon, DollarCircleIcon, UserCheck01Icon,
  MailSend01Icon, PlusSignIcon, FilterIcon,
} from 'hugeicons-react';
import api from '../config/api';

const TYPES   = ['all', 'complaint', 'refund', 'account', 'payment', 'other'];
const STATUSES = ['all', 'open', 'in_progress', 'resolved', 'closed'];
const PRIORITIES = { urgent: 'text-danger bg-danger/10 border-danger/20', high: 'text-orange bg-orange/10 border-orange/20', medium: 'text-warning bg-warning/10 border-warning/20', low: 'text-slate-500 bg-slate-100 border-slate-200' };
const STATUS_STYLES = { open: 'text-primary bg-primary/10 border-primary/20', in_progress: 'text-warning bg-warning/10 border-warning/20', resolved: 'text-success bg-success/10 border-success/20', closed: 'text-slate-400 bg-slate-100 border-slate-200' };
const TYPE_ICONS = { complaint: AlertCircleIcon, refund: DollarCircleIcon, account: UserCheck01Icon, payment: DollarCircleIcon, other: MessageAdd01Icon };

const MOCK_TICKETS = [
  { id: 'TKT-001', user: 'Marie Kamanda', user_type: 'passenger', phone: '+243 812 111 222', subject: 'Driver was rude and refused to complete ride', type: 'complaint', priority: 'high', status: 'open', ride_id: 'RD-4480', amount: 7200, created_at: '2025-05-17T09:15:00Z', updated_at: '2025-05-17T09:15:00Z',
    messages: [
      { from: 'user', text: 'The driver suddenly stopped mid-ride and asked me to get out. He was very rude and I had to find another way home.', at: '2025-05-17T09:15:00Z' },
    ],
  },
  { id: 'TKT-002', user: 'Alain Tshimanga', user_type: 'passenger', phone: '+243 845 333 444', subject: 'Charged twice for the same ride', type: 'payment', priority: 'urgent', status: 'in_progress', ride_id: 'RD-4461', amount: 5500, created_at: '2025-05-17T07:30:00Z', updated_at: '2025-05-17T10:00:00Z',
    messages: [
      { from: 'user', text: 'My mobile money account was charged FC 5500 twice for ride RD-4461. I need a refund immediately.', at: '2025-05-17T07:30:00Z' },
      { from: 'admin', text: 'Thank you for reporting this. We are investigating your duplicate charge and will process a refund within 24 hours.', at: '2025-05-17T10:00:00Z' },
    ],
  },
  { id: 'TKT-003', user: 'Sophie Muhindo', user_type: 'passenger', phone: '+243 870 555 666', subject: 'Request for refund — ride cancelled by driver', type: 'refund', priority: 'medium', status: 'open', ride_id: 'RD-4440', amount: 8000, created_at: '2025-05-16T18:20:00Z', updated_at: '2025-05-16T18:20:00Z',
    messages: [
      { from: 'user', text: 'The driver cancelled after I waited 15 minutes. The fare was deducted but the ride never happened. Please refund FC 8000.', at: '2025-05-16T18:20:00Z' },
    ],
  },
  { id: 'TKT-004', user: 'Claude Byamana', user_type: 'passenger', phone: '+243 820 777 888', subject: 'Cannot log into my account', type: 'account', priority: 'medium', status: 'resolved', ride_id: null, amount: null, created_at: '2025-05-15T14:00:00Z', updated_at: '2025-05-16T09:30:00Z',
    messages: [
      { from: 'user', text: 'I forgot my password and the reset link is not working.', at: '2025-05-15T14:00:00Z' },
      { from: 'admin', text: 'We have sent a new password reset link to your registered email. Please check your inbox.', at: '2025-05-16T09:30:00Z' },
    ],
  },
  { id: 'TKT-005', user: 'Jeanne Mapendo', user_type: 'passenger', phone: '+243 860 999 000', subject: 'Driver took longer route and overcharged', type: 'complaint', priority: 'low', status: 'closed', ride_id: 'RD-4418', amount: 4200, created_at: '2025-05-14T11:00:00Z', updated_at: '2025-05-15T08:00:00Z',
    messages: [
      { from: 'user', text: 'The driver deliberately took a longer route. The app showed FC 3000 but I was charged FC 4200.', at: '2025-05-14T11:00:00Z' },
      { from: 'admin', text: 'After investigation, we have issued a partial refund of FC 1200 to your account.', at: '2025-05-15T08:00:00Z' },
    ],
  },
];

function TicketModal({ ticket, onClose, onUpdate }) {
  const [reply, setReply] = useState('');
  const [status, setStatus] = useState(ticket.status);
  const [sending, setSending] = useState(false);
  const [messages, setMessages] = useState(ticket.messages || []);

  const sendReply = async () => {
    if (!reply.trim()) return;
    setSending(true);
    const newMsg = { from: 'admin', text: reply, at: new Date().toISOString() };
    try {
      await api.post(`/admin/support/${ticket.id}/reply`, { message: reply });
    } catch {}
    setMessages((m) => [...m, newMsg]);
    setReply('');
    setSending(false);
  };

  const changeStatus = async (newStatus) => {
    try {
      await api.patch(`/admin/support/${ticket.id}`, { status: newStatus });
    } catch {}
    setStatus(newStatus);
    onUpdate(ticket.id, { status: newStatus });
  };

  const processRefund = async () => {
    if (!ticket.amount) return;
    if (!confirm(`Process refund of FC ${ticket.amount.toLocaleString()} to ${ticket.user}?`)) return;
    try {
      await api.post(`/admin/support/${ticket.id}/refund`);
    } catch {}
    const refundMsg = { from: 'admin', text: `Refund of FC ${ticket.amount.toLocaleString()} has been processed to your account.`, at: new Date().toISOString() };
    setMessages((m) => [...m, refundMsg]);
    changeStatus('resolved');
  };

  const suspendUser = async () => {
    if (!confirm(`Suspend user ${ticket.user}?`)) return;
    try {
      await api.post(`/admin/support/${ticket.id}/suspend-user`);
    } catch {}
    changeStatus('resolved');
  };

  const TypeIcon = TYPE_ICONS[ticket.type] || MessageAdd01Icon;
  const ss = STATUS_STYLES[status] || STATUS_STYLES.open;

  return (
    <div className="fixed inset-0 bg-black/40 backdrop-blur-sm z-50 flex items-center justify-center p-4" onClick={onClose}>
      <div className="bg-white border border-dark-border rounded-2xl w-full max-w-2xl max-h-[90vh] flex flex-col" onClick={(e) => e.stopPropagation()}>
        {/* Header */}
        <div className="px-6 py-4 border-b border-dark-border flex items-start justify-between gap-4">
          <div className="flex items-start gap-3">
            <div className={`w-9 h-9 rounded-xl flex items-center justify-center flex-shrink-0 ${PRIORITIES[ticket.priority]}`}>
              <TypeIcon size={16} />
            </div>
            <div>
              <p className="font-heading font-semibold text-slate-900 text-sm leading-snug">{ticket.subject}</p>
              <p className="text-xs text-slate-500 mt-0.5">{ticket.id} · {ticket.user} ({ticket.user_type}) · {new Date(ticket.created_at).toLocaleString()}</p>
            </div>
          </div>
          <button onClick={onClose}><CancelCircleIcon size={20} className="text-slate-400 hover:text-slate-700 transition-colors" /></button>
        </div>

        {/* Actions bar */}
        <div className="px-6 py-3 border-b border-dark-border bg-slate-50 flex items-center gap-2 flex-wrap">
          <select value={status} onChange={(e) => changeStatus(e.target.value)} className={`text-xs font-bold px-3 py-1.5 rounded-lg border outline-none ${ss}`}>
            {['open', 'in_progress', 'resolved', 'closed'].map((s) => (
              <option key={s} value={s}>{s.replace('_', ' ').toUpperCase()}</option>
            ))}
          </select>
          {ticket.amount && (
            <button onClick={processRefund} className="flex items-center gap-1.5 text-xs font-bold px-3 py-1.5 rounded-lg bg-success/10 text-success border border-success/20 hover:bg-success/20 transition-colors">
              <DollarCircleIcon size={13} /> Refund FC {ticket.amount.toLocaleString()}
            </button>
          )}
          <button onClick={suspendUser} className="flex items-center gap-1.5 text-xs font-bold px-3 py-1.5 rounded-lg bg-danger/10 text-danger border border-danger/20 hover:bg-danger/20 transition-colors">
            <UserBlock01Icon size={13} /> Suspend User
          </button>
          {ticket.ride_id && (
            <a href={`/rides/${ticket.ride_id}`} target="_blank" rel="noreferrer" className="flex items-center gap-1.5 text-xs font-bold px-3 py-1.5 rounded-lg bg-primary/10 text-primary border border-primary/20 hover:bg-primary/20 transition-colors">
              View Ride {ticket.ride_id} <ArrowRight01Icon size={11} />
            </a>
          )}
        </div>

        {/* Message thread */}
        <div className="flex-1 overflow-y-auto px-6 py-4 space-y-3">
          {messages.map((msg, i) => (
            <div key={i} className={`flex ${msg.from === 'admin' ? 'justify-end' : 'justify-start'}`}>
              <div className={`max-w-[80%] rounded-2xl px-4 py-3 text-sm ${msg.from === 'admin' ? 'bg-primary text-slate-800 rounded-tr-sm' : 'bg-slate-100 text-slate-800 rounded-tl-sm'}`}>
                <p>{msg.text}</p>
                <p className={`text-[10px] mt-1.5 ${msg.from === 'admin' ? 'text-slate-800/60' : 'text-slate-400'}`}>
                  {msg.from === 'admin' ? 'Support Team' : ticket.user} · {new Date(msg.at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                </p>
              </div>
            </div>
          ))}
        </div>

        {/* Reply input */}
        <div className="px-6 py-4 border-t border-dark-border">
          <div className="flex gap-2">
            <textarea
              value={reply}
              onChange={(e) => setReply(e.target.value)}
              onKeyDown={(e) => { if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); sendReply(); } }}
              rows={2}
              placeholder="Type your reply… (Enter to send)"
              className="flex-1 border border-dark-border rounded-xl px-3 py-2.5 text-sm text-slate-800 placeholder-slate-400 bg-slate-50 outline-none resize-none focus:border-primary/50"
            />
            <button onClick={sendReply} disabled={!reply.trim() || sending} className="px-4 rounded-xl bg-primary text-slate-800 hover:bg-primary/90 transition-colors disabled:opacity-40">
              <MailSend01Icon size={16} />
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

export default function SupportTickets() {
  const [tickets, setTickets] = useState(MOCK_TICKETS);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [typeFilter, setTypeFilter] = useState('all');
  const [selected, setSelected] = useState(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    setLoading(true);
    api.get('/admin/support/tickets').then((r) => { if (r.data?.length) setTickets(r.data); }).catch(() => {}).finally(() => setLoading(false));
  }, []);

  const updateTicket = useCallback((id, changes) => {
    setTickets((prev) => prev.map((t) => t.id === id ? { ...t, ...changes } : t));
    if (selected?.id === id) setSelected((t) => ({ ...t, ...changes }));
  }, [selected]);

  const filtered = tickets.filter((t) => {
    if (statusFilter !== 'all' && t.status !== statusFilter) return false;
    if (typeFilter !== 'all' && t.type !== typeFilter) return false;
    if (search && !t.user.toLowerCase().includes(search.toLowerCase()) && !t.subject.toLowerCase().includes(search.toLowerCase())) return false;
    return true;
  });

  const counts = {
    open:        tickets.filter((t) => t.status === 'open').length,
    in_progress: tickets.filter((t) => t.status === 'in_progress').length,
    resolved:    tickets.filter((t) => t.status === 'resolved').length,
    urgent:      tickets.filter((t) => t.priority === 'urgent').length,
  };

  return (
    <div className="p-6 space-y-6">
      {selected && <TicketModal ticket={selected} onClose={() => setSelected(null)} onUpdate={updateTicket} />}

      <div className="flex items-center justify-between flex-wrap gap-4">
        <div>
          <h1 className="font-heading font-bold text-slate-900 text-2xl">Support Tickets</h1>
          <p className="text-slate-500 text-sm mt-0.5">Manage user complaints, refunds, and account issues</p>
        </div>
        <button className="flex items-center gap-2 px-4 py-2.5 rounded-xl bg-primary text-slate-700 text-sm font-semibold hover:bg-primary/90 transition-colors">
          <PlusSignIcon size={15} /> New Ticket
        </button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        {[
          { label: 'Open',        value: counts.open,        icon: Clock01Icon,           color: 'text-primary', bg: 'bg-primary/10' },
          { label: 'In Progress', value: counts.in_progress, icon: AlertCircleIcon,       color: 'text-warning', bg: 'bg-warning/10' },
          { label: 'Resolved',    value: counts.resolved,    icon: CheckmarkCircle01Icon, color: 'text-success', bg: 'bg-success/10' },
          { label: 'Urgent',      value: counts.urgent,      icon: CancelCircleIcon,      color: 'text-danger',  bg: 'bg-danger/10' },
        ].map(({ label, value, icon: Icon, color, bg }) => (
          <div key={label} className="bg-white border border-dark-border rounded-2xl p-4 flex items-center gap-3">
            <div className={`w-10 h-10 rounded-xl ${bg} flex items-center justify-center flex-shrink-0`}>
              <Icon size={18} className={color} />
            </div>
            <div>
              <p className={`font-heading font-bold text-2xl ${color}`}>{value}</p>
              <p className="text-xs text-slate-500">{label}</p>
            </div>
          </div>
        ))}
      </div>

      {/* Filters */}
      <div className="flex items-center gap-3 flex-wrap">
        <div className="flex items-center gap-2 bg-white border border-dark-border rounded-xl px-3 py-2 flex-1 min-w-[200px] max-w-xs">
          <Search01Icon size={15} className="text-slate-400" />
          <input value={search} onChange={(e) => setSearch(e.target.value)} placeholder="Search tickets..." className="bg-transparent text-sm text-slate-800 placeholder-slate-400 flex-1 outline-none" />
          {search && <button onClick={() => setSearch('')}><Cancel01Icon size={13} className="text-slate-400" /></button>}
        </div>
        <select value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)} className="bg-white border border-dark-border rounded-xl px-3 py-2 text-sm text-slate-600 outline-none">
          {STATUSES.map((s) => <option key={s} value={s}>{s === 'all' ? 'All Statuses' : s.replace('_',' ')}</option>)}
        </select>
        <select value={typeFilter} onChange={(e) => setTypeFilter(e.target.value)} className="bg-white border border-dark-border rounded-xl px-3 py-2 text-sm text-slate-600 outline-none">
          {TYPES.map((t) => <option key={t} value={t}>{t === 'all' ? 'All Types' : t.charAt(0).toUpperCase() + t.slice(1)}</option>)}
        </select>
        <button onClick={() => { api.get('/admin/support/tickets').then((r) => { if (r.data?.length) setTickets(r.data); }).catch(() => {}); }} className="flex items-center gap-1.5 px-3 py-2 rounded-xl bg-white border border-dark-border text-slate-500 hover:text-slate-800 text-sm transition-colors">
          <Refresh01Icon size={14} /> Refresh
        </button>
      </div>

      {/* Ticket list */}
      <div className="bg-white border border-dark-border rounded-2xl overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="border-b border-dark-border bg-slate-50">
                {['Ticket', 'User', 'Type', 'Priority', 'Status', 'Created', ''].map((h) => (
                  <th key={h} className="px-4 py-3 text-left text-[11px] font-semibold uppercase tracking-widest text-slate-500">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {filtered.length === 0 ? (
                <tr>
                  <td colSpan={7} className="px-4 py-12 text-center text-slate-400 text-sm">No tickets found</td>
                </tr>
              ) : filtered.map((t) => {
                const TypeIcon = TYPE_ICONS[t.type] || MessageAdd01Icon;
                const ss = STATUS_STYLES[t.status] || STATUS_STYLES.open;
                const ps = PRIORITIES[t.priority] || PRIORITIES.low;
                return (
                  <tr key={t.id} className="border-b border-dark-border/60 hover:bg-slate-50 transition-colors cursor-pointer" onClick={() => setSelected(t)}>
                    <td className="px-4 py-3.5">
                      <p className="text-sm font-semibold text-slate-800 max-w-[240px] truncate">{t.subject}</p>
                      <p className="text-xs text-slate-400 font-mono mt-0.5">{t.id}</p>
                    </td>
                    <td className="px-4 py-3.5">
                      <p className="text-sm font-medium text-slate-700">{t.user}</p>
                      <p className="text-xs text-slate-400">{t.user_type}</p>
                    </td>
                    <td className="px-4 py-3.5">
                      <span className="inline-flex items-center gap-1.5 text-xs text-slate-600">
                        <TypeIcon size={12} />
                        {t.type.charAt(0).toUpperCase() + t.type.slice(1)}
                      </span>
                    </td>
                    <td className="px-4 py-3.5">
                      <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full border ${ps}`}>
                        {t.priority.toUpperCase()}
                      </span>
                    </td>
                    <td className="px-4 py-3.5">
                      <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full border ${ss}`}>
                        {t.status.replace('_', ' ').toUpperCase()}
                      </span>
                    </td>
                    <td className="px-4 py-3.5 text-xs text-slate-400 whitespace-nowrap">
                      {new Date(t.created_at).toLocaleDateString()}
                    </td>
                    <td className="px-4 py-3.5">
                      <ArrowRight01Icon size={14} className="text-slate-400" />
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
