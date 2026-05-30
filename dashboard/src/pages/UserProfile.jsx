import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import {
  ArrowLeft01Icon, UserGroupIcon, StarIcon, UserBlock01Icon, UserCheck01Icon,
  Delete01Icon, Money01Icon, Clock01Icon, Motorbike01Icon, CheckmarkCircle01Icon,
  CancelCircleIcon, CallIncoming01Icon, Mail01Icon, MapPinpoint01Icon, Flag01Icon,
} from 'hugeicons-react';
import api from '../config/api';
import Avatar from '../components/Avatar';

const MOCK_USER = {
  _id: 'U-887',
  name: 'Marie Kavira',
  phone: '+243 998 765 432',
  email: 'marie.k@example.com',
  status: 'active',
  rating: 4.5,
  total_rides: 48,
  total_spent: 268500,
  joined_at: '2024-11-05T00:00:00Z',
  last_active: '2025-05-17T14:32:00Z',
  home_address: 'Quartier Himbi, Goma',
  recent_rides: [
    { id: 'RD-4521', driver: 'Jean-Pierre B.', fare: 6500, status: 'in_progress', date: '2025-05-17T14:22:00Z' },
    { id: 'RD-4490', driver: 'Sylvie N.', fare: 4200, status: 'completed', date: '2025-05-16T10:30:00Z' },
    { id: 'RD-4455', driver: 'Patrick N.', fare: 5800, status: 'completed', date: '2025-05-15T08:15:00Z' },
  ],
};

const STATUS_COLORS = {
  active: 'text-success bg-success/10 border-success/20',
  suspended: 'text-danger bg-danger/10 border-danger/20',
  inactive: 'text-slate-500 bg-slate-100 border-slate-200',
};

export default function UserProfile() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [user, setUser] = useState(MOCK_USER);
  const [loading, setLoading] = useState(null);

  useEffect(() => {
    if (id) api.get(`/admin/users/${id}`).then((r) => { if (r.data?.user) setUser(r.data.user); }).catch(() => {});
  }, [id]);

  const doAction = async (action) => {
    setLoading(action);
    try {
      if (action === 'delete') {
        if (!confirm('Delete this user? This cannot be undone.')) return;
        await api.delete(`/admin/users/${user.id}`);
        navigate('/users');
        return;
      }
      await api.patch(`/admin/users/${user.id}/${action}`);
      const statusMap = { suspend: 'suspended', activate: 'active' };
      if (statusMap[action]) setUser((u) => ({ ...u, status: statusMap[action] }));
    } catch {}
    setLoading(null);
  };

  const sc = STATUS_COLORS[user.status] ?? STATUS_COLORS.inactive;

  return (
    <div className="p-6 space-y-6 max-w-5xl mx-auto">
      <div className="flex items-center gap-3">
        <button onClick={() => navigate(-1)} className="p-2 rounded-xl bg-dark-card border border-dark-border text-slate-500 hover:text-slate-800 transition-colors">
          <ArrowLeft01Icon size={16} />
        </button>
        <div className="flex-1">
          <h1 className="font-heading font-bold text-slate-900 text-xl">{user.firstName} {user.lastName}</h1>
          <p className="text-slate-500 text-sm">User ID: {user.id}</p>
        </div>
        <div className="flex items-center gap-2">
          {user.status !== 'suspended' ? (
            <button onClick={() => doAction('suspend')} disabled={!!loading} className="flex items-center gap-1.5 px-3 py-2 rounded-xl bg-warning/10 text-warning border border-warning/20 text-sm font-semibold hover:bg-warning/20 transition-colors disabled:opacity-50">
              <UserBlock01Icon size={14} /> Suspend
            </button>
          ) : (
            <button onClick={() => doAction('activate')} disabled={!!loading} className="flex items-center gap-1.5 px-3 py-2 rounded-xl bg-success/10 text-success border border-success/20 text-sm font-semibold hover:bg-success/20 transition-colors disabled:opacity-50">
              <UserCheck01Icon size={14} /> Activate
            </button>
          )}
          <button onClick={() => doAction('delete')} disabled={!!loading} className="flex items-center gap-1.5 px-3 py-2 rounded-xl bg-danger/10 text-danger border border-danger/20 text-sm font-semibold hover:bg-danger/20 transition-colors disabled:opacity-50">
            <Delete01Icon size={14} /> Delete
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        {/* Profile */}
        <div className="bg-dark-card border border-dark-border rounded-2xl p-5">
          <div className="flex flex-col items-center text-center mb-4">
            <div className="mb-3">
              <Avatar name={`${user.firstName || ''} ${user.lastName || ''}`.trim()} size={80} ring />
            </div>
            <h2 className="font-heading font-bold text-slate-900 text-lg">{`${user.firstName || ''} ${user.lastName || ''}`.trim()}</h2>
            <span className={`text-[11px] font-bold px-2.5 py-0.5 rounded-full border mt-1 ${sc}`}>
              {user.status.toUpperCase()}
            </span>
            <div className="flex items-center gap-1 mt-2 text-warning">
              <StarIcon size={14} />
              <span className="font-heading font-bold text-slate-900">{user.rating}</span>
              <span className="text-slate-500 text-xs">passenger rating</span>
            </div>
          </div>
          <div className="space-y-2 pt-3 border-t border-dark-border">
            <div className="flex items-center gap-2 text-sm text-slate-500">
              <CallIncoming01Icon size={13} className="text-primary" /> {user.phone}
            </div>
            <div className="flex items-center gap-2 text-sm text-slate-500">
              <Mail01Icon size={13} className="text-primary" /> {user.email}
            </div>
            <div className="flex items-center gap-2 text-sm text-slate-500">
              <MapPinpoint01Icon size={13} className="text-success" /> {user.home_address}
            </div>
            <div className="flex items-center gap-2 text-sm text-slate-500">
              <Clock01Icon size={13} className="text-slate-500" />
              Joined {new Date(user.joined_at).toLocaleDateString()}
            </div>
          </div>
        </div>

        {/* Stats */}
        <div className="space-y-3">
          <div className="grid grid-cols-2 gap-3">
            {[
              { label: 'Total Rides', value: user.total_rides, icon: Motorbike01Icon, color: 'text-primary' },
              { label: 'Total Spent', value: `FC ${(user.total_spent / 1000).toFixed(0)}K`, icon: Money01Icon, color: 'text-orange' },
            ].map(({ label, value, icon: Icon, color }) => (
              <div key={label} className="bg-dark-card border border-dark-border rounded-2xl p-4 text-center">
                <Icon size={20} className={`${color} mx-auto mb-2`} />
                <p className={`font-heading font-bold text-xl ${color}`}>{value}</p>
                <p className="text-xs text-slate-500 mt-0.5">{label}</p>
              </div>
            ))}
          </div>
          <div className="bg-dark-card border border-dark-border rounded-2xl p-4">
            <p className="text-[10px] uppercase tracking-widest text-slate-500 mb-3">Activity</p>
            <div className="space-y-2">
              <div className="flex justify-between text-sm">
                <span className="text-slate-500">Last Active</span>
                <span className="text-slate-800">{new Date(user.last_active).toLocaleDateString()}</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-slate-500">Completion Rate</span>
                <span className="text-success font-semibold">96%</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-slate-500">Cancellation Rate</span>
                <span className="text-danger font-semibold">4%</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-slate-500">Avg Fare</span>
                <span className="text-orange font-semibold">FC {user.total_rides ? Math.round(user.total_spent / user.total_rides).toLocaleString() : 0}</span>
              </div>
            </div>
          </div>
        </div>

        {/* Recent rides */}
        <div className="bg-dark-card border border-dark-border rounded-2xl overflow-hidden">
          <div className="px-5 py-4 border-b border-dark-border">
            <h2 className="font-heading font-semibold text-slate-900 text-sm">Recent Rides</h2>
          </div>
          <div className="divide-y divide-dark-border/50">
            {user.recent_rides?.map((ride) => (
              <a key={ride.id} href={`/rides/${ride.id}`} className="flex items-center justify-between px-5 py-3 hover:bg-slate-50 transition-colors">
                <div>
                  <p className="text-sm font-medium text-slate-800">{ride.driver}</p>
                  <p className="text-xs text-slate-500">{new Date(ride.date).toLocaleDateString()}</p>
                </div>
                <div className="text-right">
                  <p className="text-sm font-semibold text-orange">FC {ride.fare.toLocaleString()}</p>
                  <span className={`text-[10px] font-bold ${ride.status === 'completed' ? 'text-success' : ride.status === 'in_progress' ? 'text-primary' : 'text-danger'}`}>
                    {ride.status.replace('_', ' ')}
                  </span>
                </div>
              </a>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
