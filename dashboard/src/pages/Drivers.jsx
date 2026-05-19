import React, { useState, useEffect, useCallback } from 'react';
import {
  Motorbike01Icon,
  UserCheck01Icon,
  UserBlock01Icon,
  Delete01Icon,
  StarIcon,
  CheckmarkCircle01Icon,
  UserWarning01Icon,
  Search01Icon,
  Cancel01Icon,
} from 'hugeicons-react';
import api from '../config/api';
import Avatar from '../components/Avatar';
import { useSearchParams } from 'react-router-dom';

const FILTERS = [
  { value: 'all',     label: 'All Drivers' },
  { value: 'online',  label: 'Online' },
  { value: 'offline', label: 'Offline' },
  { value: 'pending', label: 'Pending Approval' },
];

export default function Drivers() {
  const [drivers, setDrivers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [searchParams] = useSearchParams();
  const initialFilter = searchParams.get('filter') === 'pending' ? 'pending' : 'all';
  const [filter, setFilter] = useState(initialFilter);
  const [actionLoading, setActionLoading] = useState(null);

  const fetchDrivers = useCallback(() => {
    setLoading(true);
    api.get('/admin/drivers')
      .then((res) => setDrivers(res.data.drivers || []))
      .catch(() => {})
      .finally(() => setLoading(false));
  }, []);

  useEffect(() => { fetchDrivers(); }, [fetchDrivers]);

  const doAction = async (driverId, action) => {
    setActionLoading(`${driverId}-${action}`);
    try {
      if (action === 'delete') {
        if (!window.confirm('Permanently delete this driver? This cannot be undone.')) return;
        await api.delete(`/admin/drivers/${driverId}`);
        setDrivers((prev) => prev.filter((d) => d._id !== driverId));
      } else {
        await api.patch(`/admin/drivers/${driverId}/${action}`);
        setDrivers((prev) => prev.map((d) => {
          if (d._id !== driverId) return d;
          if (action === 'approve') return { ...d, status: 'approved', isVerified: true };
          if (action === 'suspend') return { ...d, status: 'suspended', isOnline: false };
          if (action === 'activate') return { ...d, status: 'approved' };
          return d;
        }));
      }
    } catch (err) {
      alert(err?.response?.data?.message || `Failed to ${action} driver`);
    } finally {
      setActionLoading(null);
    }
  };

  const filtered = drivers.filter((d) => {
    const matchSearch = !search || [
      d.user?.firstName, d.user?.lastName, d.user?.phone,
      d.vehicle?.plateNumber, d.vehicle?.make,
    ].some((v) => v?.toLowerCase().includes(search.toLowerCase()));
    const matchFilter =
      filter === 'all' ? true :
      filter === 'online' ? d.isOnline :
      filter === 'offline' ? !d.isOnline && d.status !== 'pending_approval' :
      filter === 'pending' ? d.status === 'pending_approval' : true;
    return matchSearch && matchFilter;
  });

  const pendingCount = drivers.filter((d) => d.status === 'pending_approval').length;

  return (
    <div className="p-6 space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="font-heading text-slate-900 text-2xl font-bold">Drivers</h1>
          <p className="text-slate-500 text-sm">Manage and control your driver fleet</p>
        </div>
        <div className="flex gap-2 text-sm">
          {pendingCount > 0 && (
            <span className="px-3 py-1 bg-warning/10 text-warning rounded-lg border border-warning/20">
              {pendingCount} pending
            </span>
          )}
          <span className="px-3 py-1 bg-success/10 text-success rounded-lg border border-success/20">
            {drivers.filter((d) => d.isOnline).length} online
          </span>
          <span className="px-3 py-1 bg-dark-card text-slate-500 rounded-lg border border-dark-border">
            {drivers.length} total
          </span>
        </div>
      </div>

      {/* Search */}
      <div className="relative">
        <Search01Icon size={16} className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-500 pointer-events-none" />
        <input
          type="text"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="Search by name, phone or plate…"
          className="w-full bg-dark-card border border-dark-border rounded-xl pl-11 pr-10 py-3 text-slate-800 placeholder-slate-400 focus:outline-none focus:border-primary transition-colors"
        />
        {search && (
          <button onClick={() => setSearch('')} className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-500 hover:text-slate-800">
            <Cancel01Icon size={14} />
          </button>
        )}
      </div>

      {/* Filters */}
      <div className="flex gap-2 flex-wrap">
        {FILTERS.map((f) => (
          <button
            key={f.value}
            onClick={() => setFilter(f.value)}
            className={`px-4 py-2 rounded-xl text-sm font-medium transition-all ${
              filter === f.value
                ? 'bg-primary text-slate-800'
                : 'bg-dark-card border border-dark-border text-slate-500 hover:text-slate-800'
            }`}
          >
            {f.label}
            {f.value === 'pending' && pendingCount > 0 && (
              <span className="ml-2 px-1.5 py-0.5 bg-warning/20 text-warning text-xs rounded-full">{pendingCount}</span>
            )}
          </button>
        ))}
      </div>

      {loading ? (
        <div className="text-center py-16 text-slate-500">Loading…</div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
          {filtered.length === 0 ? (
            <div className="col-span-full flex flex-col items-center justify-center py-20 text-slate-500 gap-3">
              <Motorbike01Icon size={40} />
              <span className="text-sm">No drivers match this filter</span>
            </div>
          ) : filtered.map((driver) => (
            <DriverCard
              key={driver._id}
              driver={driver}
              onAction={doAction}
              actionLoading={actionLoading}
            />
          ))}
        </div>
      )}
    </div>
  );
}

function DriverCard({ driver, onAction, actionLoading }) {
  const user = driver.user || {};
  const isPending  = driver.status === 'pending_approval';
  const isSuspended = driver.status === 'suspended';

  return (
    <div className={`bg-dark-card border rounded-2xl p-5 hover:border-primary/30 transition-all ${
      isPending ? 'border-warning/40' : isSuspended ? 'border-danger/30' : 'border-dark-border'
    }`}>
      <div className="flex items-center gap-4 mb-4">
        <div className="relative flex-shrink-0">
          <Avatar
            name={user.firstName ? `${user.firstName} ${user.lastName || ''}`.trim() : 'Driver'}
            size={48}
            online={driver.isOnline}
          />
        </div>
        <div className="flex-1 min-w-0">
          <div className="text-slate-900 font-semibold truncate">
            {user.firstName} {user.lastName}
          </div>
          <div className="text-slate-500 text-xs">{user.phone}</div>
        </div>
        <div className={`px-2.5 py-1 rounded-full text-xs font-semibold ${
          isPending   ? 'bg-warning/10 text-warning border border-warning/20' :
          isSuspended ? 'bg-danger/10 text-danger border border-danger/20' :
          driver.isOnline ? 'bg-success/10 text-success border border-success/20' :
          'bg-gray-500/10 text-slate-500 border border-gray-500/20'
        }`}>
          {isPending ? 'Pending' : isSuspended ? 'Suspended' : driver.isOnline ? 'Online' : 'Offline'}
        </div>
      </div>

      {/* Vehicle */}
      {driver.vehicle && (
        <div className="bg-dark-bg rounded-xl p-3 mb-4 flex items-center gap-3">
          <Motorbike01Icon size={20} className="text-primary flex-shrink-0" />
          <div>
            <div className="text-slate-700 text-sm font-medium">
              {driver.vehicle.color} {driver.vehicle.make} {driver.vehicle.model}
            </div>
            <div className="text-slate-500 text-xs font-mono tracking-wider">
              {driver.vehicle.plateNumber}
            </div>
          </div>
        </div>
      )}

      {/* Stats */}
      <div className="grid grid-cols-3 gap-2 text-center mb-4">
        <div>
          <div className="text-slate-900 font-bold">{driver.totalRides || 0}</div>
          <div className="text-slate-500 text-xs">Trips</div>
        </div>
        <div>
          <div className="text-slate-900 font-bold flex items-center justify-center gap-0.5">
            <StarIcon size={11} className="text-yellow-400" />
            {(driver.rating || 5.0).toFixed(1)}
          </div>
          <div className="text-slate-500 text-xs">Rating</div>
        </div>
        <div>
          <div className="text-slate-900 font-bold text-xs">
            {(driver.totalEarnings || 0).toLocaleString()}
          </div>
          <div className="text-slate-500 text-xs">FC Total</div>
        </div>
      </div>

      {/* Actions */}
      <div className="pt-3 border-t border-dark-border flex gap-2 flex-wrap">
        {isPending && (
          <button
            onClick={() => onAction(driver._id, 'approve')}
            disabled={!!actionLoading}
            className="flex-1 flex items-center justify-center gap-1.5 py-1.5 bg-success/10 text-success border border-success/20 rounded-lg text-xs font-semibold hover:bg-success/20 transition-colors disabled:opacity-50"
          >
            <CheckmarkCircle01Icon size={13} />
            {actionLoading === `${driver._id}-approve` ? '…' : 'Approve'}
          </button>
        )}
        {!isPending && !isSuspended && (
          <button
            onClick={() => onAction(driver._id, 'suspend')}
            disabled={!!actionLoading}
            className="flex-1 flex items-center justify-center gap-1.5 py-1.5 bg-warning/10 text-warning border border-warning/20 rounded-lg text-xs font-semibold hover:bg-warning/20 transition-colors disabled:opacity-50"
          >
            <UserWarning01Icon size={13} />
            {actionLoading === `${driver._id}-suspend` ? '…' : 'Suspend'}
          </button>
        )}
        {isSuspended && (
          <button
            onClick={() => onAction(driver._id, 'activate')}
            disabled={!!actionLoading}
            className="flex-1 flex items-center justify-center gap-1.5 py-1.5 bg-success/10 text-success border border-success/20 rounded-lg text-xs font-semibold hover:bg-success/20 transition-colors disabled:opacity-50"
          >
            <UserCheck01Icon size={13} />
            {actionLoading === `${driver._id}-activate` ? '…' : 'Activate'}
          </button>
        )}
        <button
          onClick={() => onAction(driver._id, 'delete')}
          disabled={!!actionLoading}
          className="flex items-center justify-center gap-1 px-3 py-1.5 bg-danger/10 text-danger border border-danger/20 rounded-lg text-xs hover:bg-danger/20 transition-colors disabled:opacity-50"
        >
          <Delete01Icon size={13} />
          {actionLoading === `${driver._id}-delete` ? '…' : 'Delete'}
        </button>
      </div>

      <div className="mt-3 text-slate-500 text-xs">
        Joined {new Date(driver.createdAt).toLocaleDateString('en-US', { month: 'short', year: 'numeric' })}
      </div>
    </div>
  );
}
