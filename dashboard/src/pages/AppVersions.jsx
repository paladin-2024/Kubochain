import React, { useState, useEffect } from 'react';
import {
  SmartPhone01Icon, AppStoreIcon, PlayStoreIcon, PlusSignIcon, Upload01Icon,
  CheckmarkCircle01Icon, CancelCircleIcon, AlertDiamondIcon, ToggleOnIcon,
  ToggleOffIcon, UserGroupIcon, Clock01Icon, Edit01Icon, Delete01Icon, ArrowUp01Icon,
} from 'hugeicons-react';
import api from '../config/api';

const PLATFORMS = { ios: { label: 'iOS', icon: AppStoreIcon, color: 'text-primary' }, android: { label: 'Android', icon: PlayStoreIcon, color: 'text-success' } };
const USER_TYPES = { passenger: { label: 'Passenger App', color: 'text-primary' }, driver: { label: 'Driver App', color: 'text-orange' } };

const MOCK_VERSIONS = [
  { id: 'v1', platform: 'android', user_type: 'passenger', version: '2.4.1', build: 241, min_version: '2.0.0', force_update: false, latest: true, changelog: 'Fixed SOS button, improved maps performance, new promo code UI', released_at: '2025-05-10', users_on_version: 847 },
  { id: 'v2', platform: 'ios', user_type: 'passenger', version: '2.4.1', build: 241, min_version: '2.0.0', force_update: false, latest: true, changelog: 'Fixed SOS button, improved maps performance, new promo code UI', released_at: '2025-05-10', users_on_version: 401 },
  { id: 'v3', platform: 'android', user_type: 'driver', version: '2.3.8', build: 238, min_version: '2.1.0', force_update: true, latest: true, changelog: 'Earnings dashboard, new onboarding flow, navigation improvements', released_at: '2025-05-08', users_on_version: 312 },
  { id: 'v4', platform: 'ios', user_type: 'driver', version: '2.3.8', build: 238, min_version: '2.1.0', force_update: false, latest: true, changelog: 'Earnings dashboard, new onboarding flow, navigation improvements', released_at: '2025-05-08', users_on_version: 89 },
  { id: 'v5', platform: 'android', user_type: 'passenger', version: '2.3.5', build: 235, min_version: '2.0.0', force_update: false, latest: false, changelog: 'Bug fixes and stability improvements', released_at: '2025-04-20', users_on_version: 124 },
];

const MOCK_ADOPTION = [
  { version: '2.4.1', pct: 68 },
  { version: '2.3.5', pct: 18 },
  { version: '2.2.x', pct: 10 },
  { version: '< 2.2', pct: 4 },
];

function VersionModal({ version, onClose, onSave }) {
  const [form, setForm] = useState(version ?? { platform: 'android', user_type: 'passenger', version: '', build: '', min_version: '', changelog: '', force_update: false });
  return (
    <div className="fixed inset-0 bg-black/60 backdrop-blur-sm z-50 flex items-center justify-center p-4" onClick={onClose}>
      <div className="bg-dark-card border border-dark-border rounded-2xl w-full max-w-md p-6 space-y-4" onClick={(e) => e.stopPropagation()}>
        <div className="flex items-center justify-between">
          <h2 className="font-heading font-bold text-slate-900">{version ? 'Edit Version' : 'New Release'}</h2>
          <button onClick={onClose}><CancelCircleIcon size={20} className="text-slate-500 hover:text-slate-800 transition-colors" /></button>
        </div>
        <div className="space-y-3">
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="text-[11px] uppercase tracking-widest text-slate-500 mb-1 block">Platform</label>
              <select value={form.platform} onChange={(e) => setForm((f) => ({ ...f, platform: e.target.value }))}
                className="w-full bg-dark-bg border border-dark-border rounded-xl px-3 py-2.5 text-sm text-slate-700 outline-none">
                <option value="android">Android</option>
                <option value="ios">iOS</option>
              </select>
            </div>
            <div>
              <label className="text-[11px] uppercase tracking-widest text-slate-500 mb-1 block">App Type</label>
              <select value={form.user_type} onChange={(e) => setForm((f) => ({ ...f, user_type: e.target.value }))}
                className="w-full bg-dark-bg border border-dark-border rounded-xl px-3 py-2.5 text-sm text-slate-700 outline-none">
                <option value="passenger">Passenger</option>
                <option value="driver">Driver</option>
              </select>
            </div>
          </div>
          {[
            { key: 'version', label: 'Version', placeholder: '2.4.1' },
            { key: 'build', label: 'Build Number', placeholder: '241' },
            { key: 'min_version', label: 'Min. Required Version', placeholder: '2.0.0' },
            { key: 'changelog', label: 'Changelog', placeholder: 'What changed in this release...' },
          ].map(({ key, label, placeholder }) => (
            <div key={key}>
              <label className="text-[11px] uppercase tracking-widest text-slate-500 mb-1 block">{label}</label>
              {key === 'changelog' ? (
                <textarea value={form[key] ?? ''} onChange={(e) => setForm((f) => ({ ...f, [key]: e.target.value }))} placeholder={placeholder} rows={3}
                  className="w-full bg-dark-bg border border-dark-border rounded-xl px-3 py-2.5 text-sm text-slate-800 placeholder-slate-400 outline-none focus:border-primary/50 resize-none" />
              ) : (
                <input value={form[key] ?? ''} onChange={(e) => setForm((f) => ({ ...f, [key]: e.target.value }))} placeholder={placeholder}
                  className="w-full bg-dark-bg border border-dark-border rounded-xl px-3 py-2.5 text-sm text-slate-800 placeholder-slate-400 outline-none focus:border-primary/50 transition-colors" />
              )}
            </div>
          ))}
          <div className="flex items-center justify-between py-1">
            <div>
              <p className="text-sm text-slate-600">Force Update</p>
              <p className="text-xs text-slate-500">Users must update before using the app</p>
            </div>
            <button onClick={() => setForm((f) => ({ ...f, force_update: !f.force_update }))}>
              {form.force_update ? <ToggleOnIcon size={28} className="text-danger" /> : <ToggleOffIcon size={28} className="text-slate-500" />}
            </button>
          </div>
        </div>
        <div className="flex gap-3 pt-2 border-t border-dark-border">
          <button onClick={onClose} className="flex-1 py-2.5 rounded-xl text-sm font-semibold text-slate-500 bg-dark-bg border border-dark-border hover:text-slate-800 transition-colors">Cancel</button>
          <button onClick={() => onSave(form)} className="flex-1 py-2.5 rounded-xl text-sm font-semibold text-slate-900 bg-primary hover:bg-primary/80 transition-colors">
            {version ? 'Update' : 'Publish Release'}
          </button>
        </div>
      </div>
    </div>
  );
}

export default function AppVersions() {
  const [versions, setVersions] = useState(MOCK_VERSIONS);
  const [modal, setModal] = useState(null);

  useEffect(() => {
    api.get('/admin/versions').then((r) => { if (r.data?.length) setVersions(r.data); }).catch(() => {});
  }, []);

  const saveVersion = async (form) => {
    if (modal?.id) {
      try { await api.patch(`/admin/versions/${modal.id}`, form); } catch {}
      setVersions((prev) => prev.map((v) => (v.id === modal.id ? { ...v, ...form } : v)));
    } else {
      const nv = { ...form, id: `v${Date.now()}`, latest: true, users_on_version: 0, released_at: new Date().toISOString().split('T')[0] };
      try { await api.post('/admin/versions', form); } catch {}
      setVersions((prev) => [...prev, nv]);
    }
    setModal(null);
  };

  const toggleForceUpdate = async (id, force_update) => {
    try { await api.patch(`/admin/versions/${id}`, { force_update }); } catch {}
    setVersions((prev) => prev.map((v) => (v.id === id ? { ...v, force_update } : v)));
  };

  const deleteVersion = async (id) => {
    if (!confirm('Remove this version entry?')) return;
    try { await api.delete(`/admin/versions/${id}`); } catch {}
    setVersions((prev) => prev.filter((v) => v.id !== id));
  };

  return (
    <div className="p-6 space-y-6">
      {modal !== null && (
        <VersionModal version={modal === 'new' ? null : modal} onClose={() => setModal(null)} onSave={saveVersion} />
      )}

      <div className="flex items-center justify-between flex-wrap gap-4">
        <div>
          <h1 className="font-heading font-bold text-slate-900 text-2xl">App Versions</h1>
          <p className="text-slate-500 text-sm mt-0.5">Manage release versions and update policies</p>
        </div>
        <button onClick={() => setModal('new')} className="flex items-center gap-2 px-4 py-2.5 rounded-xl bg-primary text-slate-700 text-sm font-semibold hover:bg-primary/80 transition-colors">
          <Upload01Icon size={16} /> Publish Release
        </button>
      </div>

      {/* Adoption chart */}
      <div className="bg-dark-card border border-dark-border rounded-2xl p-5">
        <h2 className="font-heading font-semibold text-slate-900 mb-4">Version Adoption</h2>
        <div className="space-y-2.5">
          {MOCK_ADOPTION.map((a) => (
            <div key={a.version} className="flex items-center gap-3">
              <span className="text-xs text-slate-500 w-16 flex-shrink-0">{a.version}</span>
              <div className="flex-1 h-2 bg-dark-bg rounded-full overflow-hidden">
                <div className={`h-full rounded-full ${a.pct > 50 ? 'bg-primary' : a.pct > 20 ? 'bg-warning' : 'bg-danger'}`} style={{ width: `${a.pct}%` }} />
              </div>
              <span className={`text-xs font-bold w-10 text-right ${a.pct > 50 ? 'text-primary' : a.pct > 20 ? 'text-warning' : 'text-danger'}`}>{a.pct}%</span>
            </div>
          ))}
        </div>
      </div>

      {/* Versions table */}
      <div className="bg-dark-card border border-dark-border rounded-2xl overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="border-b border-dark-border">
                {['Platform', 'App Type', 'Version', 'Min. Required', 'Force Update', 'Users', 'Released', ''].map((h) => (
                  <th key={h} className="px-4 py-3 text-left text-[11px] font-semibold uppercase tracking-widest text-slate-500">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {versions.map((v) => {
                const plat = PLATFORMS[v.platform];
                const utype = USER_TYPES[v.user_type];
                const PlatIcon = plat?.icon ?? SmartPhone01Icon;
                return (
                  <tr key={v.id} className="border-b border-dark-border/50 hover:bg-slate-50 transition-colors">
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-2">
                        <PlatIcon size={15} className={plat?.color} />
                        <span className="text-sm text-slate-700">{plat?.label}</span>
                      </div>
                    </td>
                    <td className="px-4 py-3">
                      <span className={`text-xs font-semibold ${utype?.color}`}>{utype?.label}</span>
                    </td>
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-1.5">
                        <span className="font-heading font-bold text-slate-900">{v.version}</span>
                        {v.latest && <span className="text-[10px] font-bold text-success bg-success/10 border border-success/20 px-1.5 py-0.5 rounded-md">LATEST</span>}
                      </div>
                      <p className="text-[10px] text-slate-500 font-mono">build {v.build}</p>
                    </td>
                    <td className="px-4 py-3 font-mono text-xs text-slate-500">{v.min_version}</td>
                    <td className="px-4 py-3">
                      <button onClick={() => toggleForceUpdate(v.id, !v.force_update)}>
                        {v.force_update
                          ? <ToggleOnIcon size={24} className="text-danger" />
                          : <ToggleOffIcon size={24} className="text-slate-500" />}
                      </button>
                    </td>
                    <td className="px-4 py-3 font-heading font-semibold text-primary">{v.users_on_version?.toLocaleString()}</td>
                    <td className="px-4 py-3 text-xs text-slate-500">{v.released_at}</td>
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-1">
                        <button onClick={() => setModal(v)} className="p-1.5 rounded-lg text-slate-500 hover:text-slate-800 hover:bg-slate-50 transition-colors">
                          <Edit01Icon size={13} />
                        </button>
                        <button onClick={() => deleteVersion(v.id)} className="p-1.5 rounded-lg text-slate-500 hover:text-danger hover:bg-danger/10 transition-colors">
                          <Delete01Icon size={13} />
                        </button>
                      </div>
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
