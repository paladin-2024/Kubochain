import React, { useState, useEffect, useCallback } from 'react';
import {
  Search01Icon,
  Cancel01Icon,
  UserBlock01Icon,
  UserCheck01Icon,
  Delete01Icon,
  EyeIcon,
  StarIcon,
} from 'hugeicons-react';
import api from '../config/api';
import Avatar from '../components/Avatar';

const ROLE_TABS = [
  { label: 'All Users',  value: '' },
  { label: 'Passengers', value: 'passenger' },
  { label: 'Riders',     value: 'rider' },
];

export default function Users() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [roleFilter, setRoleFilter] = useState('');
  const [selectedUser, setSelectedUser] = useState(null);
  const [userDetail, setUserDetail] = useState(null);
  const [detailLoading, setDetailLoading] = useState(false);
  const [actionLoading, setActionLoading] = useState(null);

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
      const res = await api.get(`/admin/users/${user.id}`);
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

  const doAction = async (userId, action) => {
    if (action === 'delete' && !window.confirm('Permanently delete this user?')) return;
    setActionLoading(`${userId}-${action}`);
    try {
      if (action === 'delete') {
        await api.delete(`/admin/users/${userId}`);
        setUsers((prev) => prev.filter((u) => u._id !== userId));
        closeDetail();
      } else {
        await api.patch(`/admin/users/${userId}/${action}`);
        const newStatus = action === 'suspend' ? 'suspended' : 'active';
        setUsers((prev) => prev.map((u) => u._id === userId ? { ...u, status: newStatus } : u));
        if (selectedUser?._id === userId) {
          setSelectedUser((u) => ({ ...u, status: newStatus }));
        }
      }
    } catch (err) {
      alert(err?.response?.data?.message || `Failed to ${action} user`);
    } finally {
      setActionLoading(null);
    }
  };

  const roleBadge = (role) => {
    const map = {
      passenger: 'bg-blue-500/10 text-blue-400 border-blue-500/20',
      rider:     'bg-success/10 text-success border-success/20',
      admin:     'bg-violet-100 text-violet-700 border-violet-200',
    };
    return (
      <span className={`px-2 py-0.5 rounded-full text-xs font-semibold border ${map[role] || 'bg-gray-500/10 text-slate-500 border-gray-500/20'}`}>
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
      <div className="flex items-center justify-between">
        <div>
          <h1 className="font-heading text-slate-900 text-2xl font-bold">Users</h1>
          <p className="text-slate-500 text-sm">All registered users — passengers and riders</p>
        </div>
        <span className="px-3 py-1 bg-dark-card text-slate-500 rounded-lg border border-dark-border text-sm">
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
                ? 'bg-primary text-slate-800 border-primary'
                : 'bg-dark-card text-slate-500 border-dark-border hover:border-primary/50 hover:text-slate-800'
            }`}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {/* Search */}
      <div className="relative">
        <Search01Icon size={16} className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-500 pointer-events-none" />
        <input
          type="text"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="Search by name, email or phone…"
          className="w-full bg-dark-card border border-dark-border rounded-xl pl-11 pr-10 py-3 text-slate-800 placeholder-slate-400 focus:outline-none focus:border-primary transition-colors"
        />
        {search && (
          <button onClick={() => setSearch('')} className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-500 hover:text-slate-800">
            <Cancel01Icon size={14} />
          </button>
        )}
      </div>

      {loading ? (
        <div className="text-center py-16 text-slate-500">Loading…</div>
      ) : (
        <div className="bg-dark-card border border-dark-border rounded-2xl overflow-hidden">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-dark-border text-slate-500 text-xs uppercase tracking-wide">
                <th className="text-left py-3 px-5">User</th>
                <th className="text-left py-3 px-5">Role</th>
                <th className="text-left py-3 px-5">Phone</th>
                <th className="text-left py-3 px-5">Joined</th>
                <th className="text-right py-3 px-5">Rides</th>
                <th className="text-right py-3 px-5">Rating</th>
                <th className="text-center py-3 px-5">Status</th>
                <th className="text-center py-3 px-5">Actions</th>
              </tr>
            </thead>
            <tbody>
              {users.map((user) => (
                <tr
                  key={user.id}
                  className="border-b border-dark-border/50 hover:bg-slate-50 transition-colors"
                >
                  <td className="py-3 px-5">
                    <div className="flex items-center gap-3">
                      <Avatar name={`${user.firstName || ''} ${user.lastName || ''}`.trim()} size={36} />
                      <div>
                        <div className="text-slate-800 font-medium">{user.firstName} {user.lastName}</div>
                        <div className="text-slate-500 text-xs">{user.email}</div>
                      </div>
                    </div>
                  </td>
                  <td className="py-3 px-5">{roleBadge(user.role)}</td>
                  <td className="py-3 px-5 text-slate-600">{user.phone}</td>
                  <td className="py-3 px-5 text-slate-500 text-xs">
                    {new Date(user.createdAt).toLocaleDateString('en-US', { dateStyle: 'medium' })}
                  </td>
                  <td className="py-3 px-5 text-right text-slate-900 font-semibold">{user.totalRides || 0}</td>
                  <td className="py-3 px-5 text-right">
                    <span className="flex items-center justify-end gap-1">
                      <StarIcon size={11} color="#FACC15" />
                      <span className="text-slate-800">{(user.rating || 5.0).toFixed(1)}</span>
                    </span>
                  </td>
                  <td className="py-3 px-5 text-center">
                    {user.status === 'suspended' ? (
                      <span className="px-2 py-0.5 bg-danger/10 text-danger border border-danger/20 rounded-full text-xs font-semibold">Suspended</span>
                    ) : (
                      <span className="px-2 py-0.5 bg-success/10 text-success border border-success/20 rounded-full text-xs font-semibold">Active</span>
                    )}
                  </td>
                  <td className="py-3 px-5">
                    <div className="flex items-center justify-center gap-1.5">
                      <button
                        onClick={() => openDetail(user)}
                        className="p-1.5 bg-primary/10 text-primary border border-primary/20 rounded-lg hover:bg-primary/20 transition-colors"
                        title="View details"
                      >
                        <EyeIcon size={13} />
                      </button>
                      {user.status === 'suspended' ? (
                        <button
                          onClick={() => doAction(user.id, 'activate')}
                          disabled={!!actionLoading}
                          className="p-1.5 bg-success/10 text-success border border-success/20 rounded-lg hover:bg-success/20 transition-colors disabled:opacity-50"
                          title="Activate user"
                        >
                          <UserCheck01Icon size={13} />
                        </button>
                      ) : (
                        <button
                          onClick={() => doAction(user.id, 'suspend')}
                          disabled={!!actionLoading}
                          className="p-1.5 bg-warning/10 text-warning border border-warning/20 rounded-lg hover:bg-warning/20 transition-colors disabled:opacity-50"
                          title="Suspend user"
                        >
                          <UserBlock01Icon size={13} />
                        </button>
                      )}
                      <button
                        onClick={() => doAction(user.id, 'delete')}
                        disabled={!!actionLoading}
                        className="p-1.5 bg-danger/10 text-danger border border-danger/20 rounded-lg hover:bg-danger/20 transition-colors disabled:opacity-50"
                        title="Delete user"
                      >
                        <Delete01Icon size={13} />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
              {users.length === 0 && (
                <tr>
                  <td colSpan={8} className="text-center py-16 text-slate-500">No users found</td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      )}

      {/* User Detail Modal */}
      {selectedUser && (
        <div
          className="fixed inset-0 bg-black/70 flex items-center justify-center z-50 p-4"
          onClick={closeDetail}
        >
          <div
            className="bg-dark-card border border-dark-border rounded-2xl w-full max-w-lg max-h-[85vh] overflow-y-auto"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="p-6 border-b border-dark-border flex items-center justify-between">
              <div className="flex items-center gap-4">
                <Avatar name={`${selectedUser.firstName || ''} ${selectedUser.lastName || ''}`.trim()} size={48} />
                <div>
                  <div className="text-slate-900 font-bold text-lg">
                    {selectedUser.firstName} {selectedUser.lastName}
                  </div>
                  <div className="text-slate-500 text-sm">{selectedUser.email}</div>
                  <div className="mt-1">{roleBadge(selectedUser.role)}</div>
                </div>
              </div>
              <button onClick={closeDetail} className="text-slate-500 hover:text-slate-800 text-2xl leading-none">&times;</button>
            </div>

            {detailLoading ? (
              <div className="p-8 text-center text-slate-500">Loading…</div>
            ) : (
              <div className="p-6 space-y-5">
                {/* Action buttons */}
                <div className="flex gap-2">
                  {selectedUser.status === 'suspended' ? (
                    <button
                      onClick={() => doAction(selectedUser._id, 'activate')}
                      disabled={!!actionLoading}
                      className="flex items-center gap-1.5 px-4 py-2 bg-success/10 text-success border border-success/20 rounded-xl text-sm font-semibold hover:bg-success/20 transition-colors disabled:opacity-50"
                    >
                      <UserCheck01Icon size={14} />
                      {actionLoading === `${selectedUser._id}-activate` ? 'Activating…' : 'Activate Account'}
                    </button>
                  ) : (
                    <button
                      onClick={() => doAction(selectedUser._id, 'suspend')}
                      disabled={!!actionLoading}
                      className="flex items-center gap-1.5 px-4 py-2 bg-warning/10 text-warning border border-warning/20 rounded-xl text-sm font-semibold hover:bg-warning/20 transition-colors disabled:opacity-50"
                    >
                      <UserBlock01Icon size={14} />
                      {actionLoading === `${selectedUser._id}-suspend` ? 'Suspending…' : 'Suspend Account'}
                    </button>
                  )}
                  <button
                    onClick={() => doAction(selectedUser._id, 'delete')}
                    disabled={!!actionLoading}
                    className="flex items-center gap-1.5 px-4 py-2 bg-danger/10 text-danger border border-danger/20 rounded-xl text-sm font-semibold hover:bg-danger/20 transition-colors disabled:opacity-50"
                  >
                    <Delete01Icon size={14} />
                    Delete
                  </button>
                </div>

                {/* Stats */}
                <div className="grid grid-cols-3 gap-3">
                  {[
                    { label: 'Total Rides', value: userDetail?.user?.totalRides || 0 },
                    { label: 'Rating', value: (userDetail?.user?.rating || 5.0).toFixed(1) },
                    { label: 'Member Since', value: new Date(selectedUser.createdAt).toLocaleDateString('en-US', { month: 'short', year: 'numeric' }) },
                  ].map((s) => (
                    <div key={s.label} className="bg-dark-bg rounded-xl p-3 border border-dark-border text-center">
                      <div className="text-slate-900 font-bold text-lg">{s.value}</div>
                      <div className="text-slate-500 text-xs mt-1">{s.label}</div>
                    </div>
                  ))}
                </div>

                {/* Contact info */}
                <div className="space-y-2">
                  <div className="text-slate-500 text-xs uppercase tracking-wide font-semibold">Contact</div>
                  <div className="bg-dark-bg rounded-xl p-4 border border-dark-border space-y-2 text-sm">
                    <div className="flex justify-between">
                      <span className="text-slate-500">Phone</span>
                      <span className="text-slate-800">{selectedUser.phone || '—'}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-slate-500">Verified</span>
                      <span className={selectedUser.isVerified ? 'text-success' : 'text-danger'}>
                        {selectedUser.isVerified ? 'Yes' : 'No'}
                      </span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-slate-500">Account Status</span>
                      <span className={selectedUser.status === 'suspended' ? 'text-danger' : 'text-success'}>
                        {selectedUser.status === 'suspended' ? 'Suspended' : 'Active'}
                      </span>
                    </div>
                  </div>
                </div>

                {/* Recent rides */}
                {(userDetail?.recentRides?.length > 0) && (
                  <div className="space-y-2">
                    <div className="text-slate-500 text-xs uppercase tracking-wide font-semibold">Recent Rides</div>
                    <div className="space-y-2">
                      {userDetail.recentRides.map((r) => (
                        <div key={r.id} className="bg-dark-bg rounded-xl p-3 border border-dark-border">
                          <div className="flex items-center justify-between mb-1">
                            <span className="text-slate-700 text-sm font-medium truncate max-w-[200px]">
                              {r.destination_address?.split(',')[0]}
                            </span>
                            {statusBadge(r.status)}
                          </div>
                          <div className="flex items-center justify-between text-xs text-slate-500">
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

