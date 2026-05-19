import React, { useState, useEffect } from 'react';
import {
  UserGroupIcon, UserAdd01Icon, UserEdit01Icon, UserBlock01Icon, UserCheck01Icon,
  Delete01Icon, Shield01Icon, Settings01Icon, CheckmarkCircle01Icon, CancelCircleIcon,
  Mail01Icon, Clock01Icon, Key01Icon, PlusSignIcon,
} from 'hugeicons-react';
import api from '../config/api';
import Avatar from '../components/Avatar';

const ROLES = ['super_admin', 'admin', 'support', 'finance', 'viewer'];
const ROLE_COLORS = {
  super_admin: 'text-danger bg-danger/10 border-danger/20',
  admin: 'text-primary bg-primary/10 border-primary/20',
  support: 'text-orange bg-orange/10 border-orange/20',
  finance: 'text-success bg-success/10 border-success/20',
  viewer: 'text-slate-500 bg-slate-100 border-slate-200',
};

const MOCK_STAFF = [
  { id: 's1', name: 'Serge Bisimwa', email: 'serge@kubochain.com', role: 'super_admin', status: 'active', last_login: '2025-05-17T14:30:00Z', actions_count: 248 },
  { id: 's2', name: 'Grace Amani', email: 'grace@kubochain.com', role: 'admin', status: 'active', last_login: '2025-05-17T10:15:00Z', actions_count: 134 },
  { id: 's3', name: 'Patrick Nkosi', email: 'patrick@kubochain.com', role: 'support', status: 'active', last_login: '2025-05-16T18:00:00Z', actions_count: 87 },
  { id: 's4', name: 'Esther Bulambo', email: 'esther@kubochain.com', role: 'finance', status: 'active', last_login: '2025-05-15T09:00:00Z', actions_count: 56 },
  { id: 's5', name: 'Christian Mugisha', email: 'christian@kubochain.com', role: 'viewer', status: 'inactive', last_login: '2025-04-20T11:00:00Z', actions_count: 12 },
];

const ROLE_PERMISSIONS = {
  super_admin: ['All access', 'Manage staff', 'Delete data', 'Config changes'],
  admin: ['Manage drivers/users', 'Cancel rides', 'Send notifications', 'View finance'],
  support: ['View incidents', 'Respond to disputes', 'Contact users'],
  finance: ['View transactions', 'Process payouts', 'Export reports'],
  viewer: ['Read-only access to all modules'],
};

function StaffModal({ staff, onClose, onSave }) {
  const [form, setForm] = useState(staff ?? { name: '', email: '', role: 'support', status: 'active' });
  return (
    <div className="fixed inset-0 bg-black/60 backdrop-blur-sm z-50 flex items-center justify-center p-4" onClick={onClose}>
      <div className="bg-dark-card border border-dark-border rounded-2xl w-full max-w-md p-6 space-y-4" onClick={(e) => e.stopPropagation()}>
        <div className="flex items-center justify-between">
          <h2 className="font-heading font-bold text-slate-900">{staff ? 'Edit Staff Member' : 'Add Staff Member'}</h2>
          <button onClick={onClose}><CancelCircleIcon size={20} className="text-slate-500 hover:text-slate-800 transition-colors" /></button>
        </div>
        <div className="space-y-3">
          {[
            { key: 'name', label: 'Full Name', type: 'text', placeholder: 'e.g. Jean Dupont' },
            { key: 'email', label: 'Email Address', type: 'email', placeholder: 'jean@kubochain.com' },
          ].map(({ key, label, type, placeholder }) => (
            <div key={key}>
              <label className="text-[11px] uppercase tracking-widest text-slate-500 mb-1 block">{label}</label>
              <input type={type} value={form[key] ?? ''} onChange={(e) => setForm((f) => ({ ...f, [key]: e.target.value }))} placeholder={placeholder}
                className="w-full bg-dark-bg border border-dark-border rounded-xl px-3 py-2.5 text-sm text-slate-800 placeholder-slate-400 outline-none focus:border-primary/50 transition-colors" />
            </div>
          ))}
          <div>
            <label className="text-[11px] uppercase tracking-widest text-slate-500 mb-1 block">Role</label>
            <select value={form.role} onChange={(e) => setForm((f) => ({ ...f, role: e.target.value }))}
              className="w-full bg-dark-bg border border-dark-border rounded-xl px-3 py-2.5 text-sm text-slate-700 outline-none">
              {ROLES.map((r) => <option key={r} value={r}>{r.replace('_', ' ').replace(/\b\w/g, (c) => c.toUpperCase())}</option>)}
            </select>
          </div>
          {form.role && (
            <div className="bg-dark-bg/50 rounded-xl p-3">
              <p className="text-[10px] uppercase text-slate-500 tracking-widest mb-1.5">Permissions</p>
              <ul className="space-y-0.5">
                {ROLE_PERMISSIONS[form.role]?.map((p) => (
                  <li key={p} className="text-xs text-slate-500 flex items-center gap-1.5">
                    <CheckmarkCircle01Icon size={10} className="text-success flex-shrink-0" /> {p}
                  </li>
                ))}
              </ul>
            </div>
          )}
        </div>
        <div className="flex gap-3 pt-2 border-t border-dark-border">
          <button onClick={onClose} className="flex-1 py-2.5 rounded-xl text-sm font-semibold text-slate-500 bg-dark-bg border border-dark-border hover:text-slate-800 transition-colors">Cancel</button>
          <button onClick={() => onSave(form)} className="flex-1 py-2.5 rounded-xl text-sm font-semibold text-slate-900 bg-primary hover:bg-primary/80 transition-colors">
            {staff ? 'Update' : 'Add Staff'}
          </button>
        </div>
      </div>
    </div>
  );
}

export default function Staff() {
  const [staff, setStaff] = useState(MOCK_STAFF);
  const [modal, setModal] = useState(null);

  useEffect(() => {
    api.get('/admin/staff').then((r) => { if (r.data?.length) setStaff(r.data); }).catch(() => {});
  }, []);

  const saveStaff = async (form) => {
    if (modal?.id) {
      try { await api.patch(`/admin/staff/${modal.id}`, form); } catch {}
      setStaff((prev) => prev.map((s) => (s.id === modal.id ? { ...s, ...form } : s)));
    } else {
      const ns = { ...form, id: `s${Date.now()}`, last_login: null, actions_count: 0 };
      try { await api.post('/admin/staff', form); } catch {}
      setStaff((prev) => [...prev, ns]);
    }
    setModal(null);
  };

  const toggleStatus = async (id) => {
    const s = staff.find((s) => s.id === id);
    const newStatus = s.status === 'active' ? 'inactive' : 'active';
    try { await api.patch(`/admin/staff/${id}`, { status: newStatus }); } catch {}
    setStaff((prev) => prev.map((s) => (s.id === id ? { ...s, status: newStatus } : s)));
  };

  const deleteStaff = async (id) => {
    if (!confirm('Remove this staff member?')) return;
    try { await api.delete(`/admin/staff/${id}`); } catch {}
    setStaff((prev) => prev.filter((s) => s.id !== id));
  };

  return (
    <div className="p-6 space-y-6">
      {modal !== null && (
        <StaffModal staff={modal === 'new' ? null : modal} onClose={() => setModal(null)} onSave={saveStaff} />
      )}

      <div className="flex items-center justify-between flex-wrap gap-4">
        <div>
          <h1 className="font-heading font-bold text-slate-900 text-2xl">Admin Staff</h1>
          <p className="text-slate-500 text-sm mt-0.5">Manage admin team members and permissions</p>
        </div>
        <button onClick={() => setModal('new')} className="flex items-center gap-2 px-4 py-2.5 rounded-xl bg-primary text-slate-700 text-sm font-semibold hover:bg-primary/80 transition-colors">
          <PlusSignIcon size={16} /> Add Member
        </button>
      </div>

      {/* Roles overview */}
      <div className="grid grid-cols-2 lg:grid-cols-5 gap-3">
        {ROLES.map((role) => {
          const count = staff.filter((s) => s.role === role).length;
          return (
            <div key={role} className="bg-dark-card border border-dark-border rounded-xl p-3 text-center">
              <p className={`text-[11px] font-bold px-2 py-0.5 rounded-full border inline-block mb-1.5 ${ROLE_COLORS[role]}`}>
                {role.replace('_', ' ').toUpperCase()}
              </p>
              <p className="font-heading font-bold text-xl text-slate-800">{count}</p>
            </div>
          );
        })}
      </div>

      {/* Staff list */}
      <div className="bg-dark-card border border-dark-border rounded-2xl overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="border-b border-dark-border">
                {['Member', 'Role', 'Status', 'Last Login', 'Actions', ''].map((h) => (
                  <th key={h} className="px-4 py-3 text-left text-[11px] font-semibold uppercase tracking-widest text-slate-500">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {staff.map((s) => (
                <tr key={s.id} className="border-b border-dark-border/50 hover:bg-slate-50 transition-colors">
                  <td className="px-4 py-3">
                    <div className="flex items-center gap-3">
                      <Avatar name={s.name} size={32} />
                      <div>
                        <p className="font-medium text-slate-800 text-sm">{s.name}</p>
                        <p className="text-xs text-slate-500">{s.email}</p>
                      </div>
                    </div>
                  </td>
                  <td className="px-4 py-3">
                    <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full border ${ROLE_COLORS[s.role]}`}>
                      {s.role.replace('_', ' ').toUpperCase()}
                    </span>
                  </td>
                  <td className="px-4 py-3">
                    <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full border ${s.status === 'active' ? 'text-success bg-success/10 border-success/20' : 'text-slate-500 bg-slate-100 border-slate-200'}`}>
                      {s.status.toUpperCase()}
                    </span>
                  </td>
                  <td className="px-4 py-3 text-xs text-slate-500">
                    {s.last_login ? new Date(s.last_login).toLocaleDateString() : 'Never'}
                  </td>
                  <td className="px-4 py-3 font-heading font-semibold text-sm text-primary">{s.actions_count}</td>
                  <td className="px-4 py-3">
                    <div className="flex items-center gap-1.5">
                      <button onClick={() => setModal(s)} className="p-1.5 rounded-lg text-slate-500 hover:text-slate-800 hover:bg-slate-50 transition-colors">
                        <UserEdit01Icon size={14} />
                      </button>
                      <button onClick={() => toggleStatus(s.id)} className="p-1.5 rounded-lg text-slate-500 hover:text-warning hover:bg-warning/10 transition-colors">
                        {s.status === 'active' ? <UserBlock01Icon size={14} /> : <UserCheck01Icon size={14} />}
                      </button>
                      <button onClick={() => deleteStaff(s.id)} className="p-1.5 rounded-lg text-slate-500 hover:text-danger hover:bg-danger/10 transition-colors">
                        <Delete01Icon size={14} />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
