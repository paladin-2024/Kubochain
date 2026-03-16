import React, { useState, useEffect, useCallback } from 'react';
import { Search, X } from 'lucide-react';
import api from '../config/api';

const ROLE_TABS = [
  { label: 'All Users', value: '' },
  { label: 'Passengers', value: 'passenger' },
  { label: 'Riders', value: 'rider' },
];

export default function Users() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [roleFilter, setRoleFilter] = useState('');
  const [selectedUser, setSelectedUser] = useState(null);
  const [userDetail, setUserDetail] = useState(null);
  const [detailLoading, setDetailLoading] = useState(false);

  const fetchUsers = useCallback(() => {
    setLoading(true);
    const params = new URLSearchParams();
    if (roleFilter) params.set('role', roleFilter);
    if (search) params.set('search', search);
    api.get(`/admin/users?${params}`)
      .then((res) => setUsers(res.data.users || []))
      .catch(() => {})
      .finally(() => setLoading(false));
  }, [roleFilter, search]);

  useEffect(() => {
    const timer = setTimeout(fetchUsers, 300);
    return () => clearTimeout(timer);
  }, [fetchUsers]);

  const openDetail = async (user) => {
    setSelectedUser(user);
    setDetailLoading(true);
    try {
      const res = await api.get(`/admin/users/${user._id}`);
      setUserDetail(res.data);
    } catch {
      setUserDetail({ user, recentRides: [] });
    } finally {
      setDetailLoading(false);
    }
  };

  const closeDetail = () => {
    setSelectedUser(null);
    setUserDetail(null);
  };

  const roleBadge = (role) => {
    const map = {
      passenger: 'bg-blue-500/10 text-blue-400 border-blue-500/20',
      rider: 'bg-green-500/10 text-green-400 border-green-500/20',
      admin: 'bg-purple-500/10 text-purple-400 border-purple-500/20',
    };
    return (
      <span className={`px-2 py-0.5 rounded-full text-xs font-semibold border ${map[role] || 'bg-gray-500/10 text-gray-400'}`}>
        {role}
      </span>
    );
  };

  const statusBadge = (status) => (
    <span className={`px-2 py-0.5 rounded-full text-xs font-semibold border badge-${status}`}>
      {status?.replace('_', ' ')}
    </span>
  );

  return (
    <div className="p-6 space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-white text-2xl font-bold">Users</h1>
          <p className="text-gray-400 text-sm">All registered users — passengers and riders</p>
        </div>
        <span className="px-3 py-1 bg-dark-card text-gray-400 rounded-lg border border-dark-border text-sm">
          {users.length} total
        </span>
      </div>

      {/* Role tabs */}
      <div className="flex gap-2">
        {ROLE_TABS.map((tab) => (
          <button
            key={tab.value}
            onClick={() => setRoleFilter(tab.value)}
            className={`px-4 py-2 rounded-xl text-sm font-medium border transition-all ${
              roleFilter === tab.value
                ? 'bg-primary text-white border-primary'
                : 'bg-dark-card text-gray-400 border-dark-border hover:border-primary/50 hover:text-white'
            }`}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {/* Search */}
      <div className="relative">
        <Search size={16} className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-500 pointer-events-none" />
        <input
          type="text"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="Search by name, email or phone..."
          className="w-full bg-dark-card border border-dark-border rounded-xl pl-11 pr-10 py-3 text-white placeholder-gray-600 focus:outline-none focus:border-primary transition-colors"
        />
        {search && (
          <button onClick={() => setSearch('')} className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-500 hover:text-white">
            <X size={14} />
          </button>
        )}
      </div>

      {loading ? (
        <div className="text-center py-16 text-gray-400">Loading...</div>
      ) : (
        <div className="bg-dark-card border border-dark-border rounded-2xl overflow-hidden">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-dark-border text-gray-400 text-xs uppercase tracking-wide">
                <th className="text-left py-3 px-5">User</th>
                <th className="text-left py-3 px-5">Role</th>
                <th className="text-left py-3 px-5">Phone</th>
                <th className="text-left py-3 px-5">Joined</th>
                <th className="text-right py-3 px-5">Total Rides</th>
                <th className="text-right py-3 px-5">Rating</th>
                <th className="text-center py-3 px-5">Actions</th>
              </tr>
            </thead>
            <tbody>
              {users.map((user) => (
                <tr
                  key={user._id}
                  className="border-b border-dark-border/50 hover:bg-white/2 transition-colors cursor-pointer"
                  onClick={() => openDetail(user)}
                >
                  <td className="py-3 px-5">
                    <div className="flex items-center gap-3">
                      <div className="w-9 h-9 bg-primary/10 rounded-full flex items-center justify-center text-primary font-semibold text-sm">
                        {user.firstName?.[0]}{user.lastName?.[0]}
                      </div>
                      <div>
                        <div className="text-white font-medium">{user.firstName} {user.lastName}</div>
                        <div className="text-gray-400 text-xs">{user.email}</div>
                      </div>
                    </div>
                  </td>
                  <td className="py-3 px-5">{roleBadge(user.role)}</td>
                  <td className="py-3 px-5 text-gray-300">{user.phone}</td>
                  <td className="py-3 px-5 text-gray-400 text-xs">
                    {new Date(user.createdAt).toLocaleDateString('en-US', { dateStyle: 'medium' })}
                  </td>
                  <td className="py-3 px-5 text-right text-white font-semibold">{user.totalRides || 0}</td>
                  <td className="py-3 px-5 text-right">
                    <span className="flex items-center justify-end gap-1">
                      <span className="text-yellow-400 text-xs">★</span>
                      <span className="text-white">{(user.rating || 5.0).toFixed(1)}</span>
                    </span>
                  </td>
                  <td className="py-3 px-5 text-center">
                    <button
                      onClick={(e) => { e.stopPropagation(); openDetail(user); }}
                      className="px-3 py-1 bg-primary/10 text-primary border border-primary/20 rounded-lg text-xs hover:bg-primary/20 transition-colors"
                    >
                      View
                    </button>
                  </td>
                </tr>
              ))}
              {users.length === 0 && (
                <tr>
                  <td colSpan={7} className="text-center py-16 text-gray-500">
                    No users found
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      )}

      {/* User Detail Modal */}
      {selectedUser && (
        <div
          className="fixed inset-0 bg-black/60 flex items-center justify-center z-50 p-4"
          onClick={closeDetail}
        >
          <div
            className="bg-dark-card border border-dark-border rounded-2xl w-full max-w-lg max-h-[80vh] overflow-y-auto"
            onClick={(e) => e.stopPropagation()}
          >
            {/* Modal header */}
            <div className="p-6 border-b border-dark-border flex items-center justify-between">
              <div className="flex items-center gap-4">
                <div className="w-12 h-12 bg-primary/10 rounded-full flex items-center justify-center text-primary font-bold text-lg">
                  {selectedUser.firstName?.[0]}{selectedUser.lastName?.[0]}
                </div>
                <div>
                  <div className="text-white font-bold text-lg">
                    {selectedUser.firstName} {selectedUser.lastName}
                  </div>
                  <div className="text-gray-400 text-sm">{selectedUser.email}</div>
                  <div className="mt-1">{roleBadge(selectedUser.role)}</div>
                </div>
              </div>
              <button onClick={closeDetail} className="text-gray-400 hover:text-white text-2xl leading-none">&times;</button>
            </div>

            {detailLoading ? (
              <div className="p-8 text-center text-gray-400">Loading...</div>
            ) : (
              <div className="p-6 space-y-6">
                {/* Stats */}
                <div className="grid grid-cols-3 gap-3">
                  {[
                    { label: 'Total Rides', value: userDetail?.user?.totalRides || 0 },
                    { label: 'Rating', value: (userDetail?.user?.rating || 5.0).toFixed(1) },
                    { label: 'Member Since', value: new Date(selectedUser.createdAt).toLocaleDateString('en-US', { month: 'short', year: 'numeric' }) },
                  ].map((s) => (
                    <div key={s.label} className="bg-dark-bg rounded-xl p-3 border border-dark-border text-center">
                      <div className="text-white font-bold text-lg">{s.value}</div>
                      <div className="text-gray-400 text-xs mt-1">{s.label}</div>
                    </div>
                  ))}
                </div>

                {/* Contact info */}
                <div className="space-y-2">
                  <div className="text-gray-400 text-xs uppercase tracking-wide font-semibold">Contact</div>
                  <div className="bg-dark-bg rounded-xl p-4 border border-dark-border space-y-2 text-sm">
                    <div className="flex justify-between">
                      <span className="text-gray-400">Phone</span>
                      <span className="text-white">{selectedUser.phone || '—'}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-400">Email verified</span>
                      <span className={selectedUser.isVerified ? 'text-green-400' : 'text-red-400'}>
                        {selectedUser.isVerified ? 'Yes' : 'No'}
                      </span>
                    </div>
                  </div>
                </div>

                {/* Recent rides */}
                {(userDetail?.recentRides?.length > 0) && (
                  <div className="space-y-2">
                    <div className="text-gray-400 text-xs uppercase tracking-wide font-semibold">Recent Rides</div>
                    <div className="space-y-2">
                      {userDetail.recentRides.map((r) => (
                        <div key={r.id} className="bg-dark-bg rounded-xl p-3 border border-dark-border">
                          <div className="flex items-center justify-between mb-1">
                            <span className="text-white text-sm font-medium truncate max-w-[200px]">
                              → {r.destination_address?.split(',')[0]}
                            </span>
                            {statusBadge(r.status)}
                          </div>
                          <div className="flex items-center justify-between text-xs text-gray-400">
                            <span>{new Date(r.created_at).toLocaleDateString()}</span>
                            <span className="text-primary font-semibold">FC{Number(r.price || 0).toLocaleString()}</span>
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                )}
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
