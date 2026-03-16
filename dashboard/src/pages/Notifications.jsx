import React, { useState, useEffect } from 'react';
import {
  Bell, Send, RefreshCw, Users, UserCheck, Bike,
  CheckCircle2, XCircle, Flag, Radio, AlertCircle,
} from 'lucide-react';
import api from '../config/api';

const TYPE_CONFIG = {
  ride_request:   { Icon: Bike,          color: 'text-primary',     bg: 'bg-primary/10',     label: 'Ride Request' },
  ride_accepted:  { Icon: CheckCircle2,  color: 'text-success',     bg: 'bg-success/10',     label: 'Ride Accepted' },
  ride_completed: { Icon: Flag,          color: 'text-success',     bg: 'bg-success/10',     label: 'Trip Completed' },
  ride_cancelled: { Icon: XCircle,       color: 'text-danger',      bg: 'bg-danger/10',      label: 'Cancelled' },
  system:         { Icon: AlertCircle,   color: 'text-warning',     bg: 'bg-warning/10',     label: 'System' },
  broadcast:      { Icon: Radio,         color: 'text-orange-400',  bg: 'bg-orange-500/10',  label: 'Broadcast' },
};
const DEFAULT_TYPE = TYPE_CONFIG.broadcast;

function timeAgo(dateStr) {
  const diff = (Date.now() - new Date(dateStr)) / 1000;
  if (diff < 60) return `${Math.floor(diff)}s ago`;
  if (diff < 3600) return `${Math.floor(diff / 60)}m ago`;
  if (diff < 86400) return `${Math.floor(diff / 3600)}h ago`;
  return `${Math.floor(diff / 86400)}d ago`;
}

const TARGET_OPTIONS = [
  { value: 'all',       label: 'All Users',   icon: Users },
  { value: 'passenger', label: 'Passengers',  icon: Users },
  { value: 'rider',     label: 'Riders',      icon: UserCheck },
];

export default function Notifications() {
  const [history, setHistory] = useState([]);
  const [histLoading, setHistLoading] = useState(true);
  const [form, setForm] = useState({ title: '', body: '', target: 'all' });
  const [sending, setSending] = useState(false);
  const [sent, setSent] = useState(false);
  const [error, setError] = useState('');

  const fetchHistory = () => {
    setHistLoading(true);
    api.get('/admin/notifications/history')
      .then((res) => setHistory(res.data.notifications || []))
      .catch(() => {})
      .finally(() => setHistLoading(false));
  };

  useEffect(() => { fetchHistory(); }, []);

  const handleSend = async (e) => {
    e.preventDefault();
    if (!form.title.trim() || !form.body.trim()) {
      setError('Title and body are required.');
      return;
    }
    setError('');
    setSending(true);
    try {
      await api.post('/admin/notifications', {
        title: form.title,
        body: form.body,
        targetRole: form.target === 'all' ? '' : form.target,
      });
      setSent(true);
      setForm({ title: '', body: '', target: 'all' });
      setTimeout(() => setSent(false), 3000);
      fetchHistory();
    } catch (err) {
      const status = err?.response?.status;
      if (status === 503) {
        setError('Database is warming up. Please wait a moment and try again.');
      } else {
        setError(err?.response?.data?.message || 'Failed to send notification.');
      }
    } finally {
      setSending(false);
    }
  };

  return (
    <div className="p-6 space-y-6">
      <div>
        <h1 className="text-white text-2xl font-bold">Notifications</h1>
        <p className="text-gray-400 text-sm">Broadcast messages to users and view notification history</p>
      </div>

      <div className="grid grid-cols-1 xl:grid-cols-2 gap-6">
        {/* Send form */}
        <div className="bg-dark-card border border-dark-border rounded-2xl p-6 space-y-5">
          <div className="flex items-center gap-2">
            <Send size={18} className="text-primary" />
            <h2 className="text-white font-semibold text-lg">Send Broadcast</h2>
          </div>

          <form onSubmit={handleSend} className="space-y-4">
            {/* Target */}
            <div>
              <label className="text-gray-500 text-xs uppercase tracking-wide font-semibold block mb-2">Target Audience</label>
              <div className="flex gap-2">
                {TARGET_OPTIONS.map((t) => {
                  const active = form.target === t.value;
                  return (
                    <button
                      key={t.value}
                      type="button"
                      onClick={() => setForm((f) => ({ ...f, target: t.value }))}
                      className={`flex items-center gap-1.5 px-3 py-2 rounded-xl text-sm font-medium border transition-all ${
                        active
                          ? 'bg-primary text-white border-primary'
                          : 'bg-dark-bg text-gray-400 border-dark-border hover:border-primary/50 hover:text-white'
                      }`}
                    >
                      <t.icon size={13} />
                      {t.label}
                    </button>
                  );
                })}
              </div>
            </div>

            <div>
              <label className="text-gray-500 text-xs uppercase tracking-wide font-semibold block mb-2">Title</label>
              <input
                type="text"
                value={form.title}
                onChange={(e) => setForm((f) => ({ ...f, title: e.target.value }))}
                placeholder="Notification title"
                className="w-full bg-dark-bg border border-dark-border rounded-xl px-4 py-3 text-white placeholder-gray-600 focus:outline-none focus:border-primary transition-colors"
              />
            </div>

            <div>
              <label className="text-gray-500 text-xs uppercase tracking-wide font-semibold block mb-2">Message</label>
              <textarea
                value={form.body}
                onChange={(e) => setForm((f) => ({ ...f, body: e.target.value }))}
                placeholder="Write your message here…"
                rows={4}
                className="w-full bg-dark-bg border border-dark-border rounded-xl px-4 py-3 text-white placeholder-gray-600 focus:outline-none focus:border-primary transition-colors resize-none"
              />
            </div>

            {error && (
              <div className="flex items-center gap-2 px-4 py-3 bg-danger/10 border border-danger/20 rounded-xl text-danger text-sm">
                <AlertCircle size={14} /> {error}
              </div>
            )}
            {sent && (
              <div className="flex items-center gap-2 px-4 py-3 bg-success/10 border border-success/20 rounded-xl text-success text-sm">
                <CheckCircle2 size={14} /> Notification sent successfully!
              </div>
            )}

            <button
              type="submit"
              disabled={sending}
              className="w-full flex items-center justify-center gap-2 py-3 bg-primary text-white rounded-xl font-semibold text-sm hover:bg-primary/90 transition-colors disabled:opacity-50"
            >
              {sending
                ? <><RefreshCw size={14} className="animate-spin" /> Sending…</>
                : <><Send size={14} /> Send Notification</>}
            </button>
          </form>
        </div>

        {/* History */}
        <div className="bg-dark-card border border-dark-border rounded-2xl p-6">
          <div className="flex items-center justify-between mb-5">
            <div className="flex items-center gap-2">
              <Bell size={18} className="text-primary" />
              <h2 className="text-white font-semibold text-lg">Recent Notifications</h2>
            </div>
            <button
              onClick={fetchHistory}
              className="p-1.5 rounded-lg text-gray-500 hover:text-white hover:bg-white/5 transition-colors"
            >
              <RefreshCw size={14} />
            </button>
          </div>

          {histLoading ? (
            <div className="flex items-center justify-center py-12 text-gray-500">
              <div className="w-5 h-5 border-2 border-primary border-t-transparent rounded-full animate-spin" />
            </div>
          ) : history.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-12 text-gray-600 gap-3">
              <Bell size={32} strokeWidth={1.5} />
              <div className="text-sm">No notifications sent yet</div>
            </div>
          ) : (
            <div className="space-y-3 max-h-[480px] overflow-y-auto pr-1">
              {history.map((n, i) => {
                const cfg = TYPE_CONFIG[n.type] || DEFAULT_TYPE;
                return (
                  <div key={n.id || i} className="flex items-start gap-3 p-3 bg-dark-bg rounded-xl border border-dark-border">
                    <div className={`w-9 h-9 ${cfg.bg} rounded-full flex items-center justify-center flex-shrink-0`}>
                      <cfg.Icon size={16} className={cfg.color} />
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center justify-between gap-2">
                        <span className="text-white text-sm font-semibold truncate">{n.title}</span>
                        <span className="text-gray-600 text-xs flex-shrink-0">{timeAgo(n.created_at || n.createdAt)}</span>
                      </div>
                      <p className="text-gray-500 text-xs mt-0.5 line-clamp-2">{n.body}</p>
                      {n.target && (
                        <span className="inline-flex items-center gap-1 mt-1 px-2 py-0.5 bg-dark-card border border-dark-border rounded-full text-gray-600 text-xs">
                          <Users size={10} /> {n.target}
                        </span>
                      )}
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
