import React, { useState, useEffect } from 'react';
import api from '../config/api';

export default function Drivers() {
  const [drivers, setDrivers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('all'); // all | online | offline

  useEffect(() => {
    api.get('/admin/drivers')
      .then((res) => setDrivers(res.data.drivers || []))
      .catch(() => {})
      .finally(() => setLoading(false));
  }, []);

  const filtered = drivers.filter((d) => {
    if (filter === 'online') return d.isOnline;
    if (filter === 'offline') return !d.isOnline;
    return true;
  });

  return (
    <div className="p-6 space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-white text-2xl font-bold">Drivers</h1>
          <p className="text-gray-400 text-sm">Manage your driver fleet</p>
        </div>
        <div className="flex gap-2 text-sm">
          <span className="px-3 py-1 bg-success/10 text-success rounded-lg border border-success/20">
            {drivers.filter((d) => d.isOnline).length} online
          </span>
          <span className="px-3 py-1 bg-dark-card text-gray-400 rounded-lg border border-dark-border">
            {drivers.length} total
          </span>
        </div>
      </div>

      {/* Filters */}
      <div className="flex gap-3">
        {['all', 'online', 'offline'].map((f) => (
          <button
            key={f}
            onClick={() => setFilter(f)}
            className={`px-4 py-2 rounded-xl text-sm font-medium capitalize transition-all ${
              filter === f
                ? 'bg-primary text-white'
                : 'bg-dark-card border border-dark-border text-gray-400 hover:text-white'
            }`}
          >
            {f === 'all' ? 'All Drivers' : f}
          </button>
        ))}
      </div>

      {loading ? (
        <div className="text-center py-16 text-gray-400">Loading...</div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
          {filtered.map((driver) => (
            <DriverCard key={driver._id} driver={driver} />
          ))}
        </div>
      )}
    </div>
  );
}

function DriverCard({ driver }) {
  const user = driver.user || {};
  const initials = user.firstName
    ? `${user.firstName[0]}${user.lastName?.[0] || ''}`.toUpperCase()
    : 'D';

  return (
    <div className="bg-dark-card border border-dark-border rounded-2xl p-5 hover:border-primary/30 transition-all">
      <div className="flex items-center gap-4 mb-4">
        <div className="relative">
          <div className="w-12 h-12 bg-primary/10 rounded-full flex items-center justify-center text-primary font-bold text-lg">
            {initials}
          </div>
          <div className={`absolute -bottom-0.5 -right-0.5 w-3.5 h-3.5 rounded-full border-2 border-dark-card ${driver.isOnline ? 'bg-success' : 'bg-gray-500'}`} />
        </div>
        <div className="flex-1 min-w-0">
          <div className="text-white font-semibold truncate">
            {user.firstName} {user.lastName}
          </div>
          <div className="text-gray-400 text-xs">{user.phone}</div>
        </div>
        <div className={`px-2.5 py-1 rounded-full text-xs font-semibold ${driver.isOnline ? 'bg-success/10 text-success border border-success/20' : 'bg-gray-500/10 text-gray-400 border border-gray-500/20'}`}>
          {driver.isOnline ? 'Online' : 'Offline'}
        </div>
      </div>

      {/* Vehicle */}
      {driver.vehicle && (
        <div className="bg-dark-bg rounded-xl p-3 mb-4 flex items-center gap-3">
          <span className="text-xl">🏍️</span>
          <div>
            <div className="text-white text-sm font-medium">
              {driver.vehicle.color} {driver.vehicle.make} {driver.vehicle.model}
            </div>
            <div className="text-gray-400 text-xs font-mono tracking-wider">
              {driver.vehicle.plateNumber}
            </div>
          </div>
        </div>
      )}

      {/* Stats */}
      <div className="grid grid-cols-3 gap-2 text-center">
        <div>
          <div className="text-white font-bold">{driver.totalRides || 0}</div>
          <div className="text-gray-500 text-xs">Trips</div>
        </div>
        <div>
          <div className="text-white font-bold flex items-center justify-center gap-0.5">
            <span className="text-yellow-400 text-xs">★</span>
            {(driver.rating || 5.0).toFixed(1)}
          </div>
          <div className="text-gray-500 text-xs">Rating</div>
        </div>
        <div>
          <div className="text-white font-bold text-xs">
            {(driver.totalEarnings || 0).toLocaleString()}
          </div>
          <div className="text-gray-500 text-xs">FC Total</div>
        </div>
      </div>

      {/* Join date */}
      <div className="mt-3 pt-3 border-t border-dark-border text-gray-500 text-xs">
        Member since {new Date(driver.createdAt).toLocaleDateString('en-US', { month: 'short', year: 'numeric' })}
      </div>
    </div>
  );
}
