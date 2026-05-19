import React, { useState, useEffect } from 'react';
import {
  Image01Icon, PlusSignIcon, Edit01Icon, Delete01Icon, ToggleOnIcon, ToggleOffIcon,
  EyeIcon, Calendar01Icon, UserGroupIcon, Motorbike01Icon, CheckmarkCircle01Icon,
  CancelCircleIcon, Link01Icon, Upload01Icon,
} from 'hugeicons-react';
import api from '../config/api';

const AUDIENCE_OPTIONS = { all: 'All Users', passengers: 'Passengers Only', drivers: 'Drivers Only' };
const PLACEMENT_OPTIONS = { home: 'Home Screen', rides: 'Rides Screen', profile: 'Profile Screen' };

const MOCK_BANNERS = [
  { id: 'b1', title: 'Weekend Special', subtitle: 'Get 20% off your next ride', cta: 'Book Now', cta_link: '/promo/GOMA20', audience: 'passengers', placement: 'home', active: true, start: '2025-05-17', end: '2025-05-18', impressions: 4821, taps: 342, bg_color: '#1A3A6E', text_color: '#FFFFFF' },
  { id: 'b2', title: 'Drive with us!', subtitle: 'Earn more this weekend — double bonus', cta: 'Learn More', cta_link: '/driver/bonus', audience: 'drivers', placement: 'home', active: true, start: '2025-05-17', end: '2025-05-19', impressions: 1204, taps: 98, bg_color: '#1A4A2A', text_color: '#FFFFFF' },
  { id: 'b3', title: 'New Feature: SOS Button', subtitle: 'Your safety is our priority', cta: 'See How', cta_link: '/safety', audience: 'all', placement: 'rides', active: false, start: '2025-05-10', end: '2025-05-15', impressions: 8420, taps: 1023, bg_color: '#3D1A1A', text_color: '#FFFFFF' },
];

function BannerPreview({ banner }) {
  return (
    <div
      className="rounded-xl p-4 flex flex-col justify-between min-h-[120px] relative overflow-hidden"
      style={{ background: banner.bg_color ?? '#1A3A6E' }}
    >
      <div className="absolute inset-0 bg-gradient-to-br from-white/5 to-transparent pointer-events-none" />
      <div>
        <p className="font-heading font-bold text-lg leading-tight" style={{ color: banner.text_color }}>{banner.title}</p>
        <p className="text-sm opacity-80 mt-0.5" style={{ color: banner.text_color }}>{banner.subtitle}</p>
      </div>
      <div className="mt-3">
        <span className="inline-block text-xs font-bold px-3 py-1.5 rounded-lg bg-white/20 backdrop-blur-sm" style={{ color: banner.text_color }}>
          {banner.cta}
        </span>
      </div>
    </div>
  );
}

function BannerModal({ banner, onClose, onSave }) {
  const [form, setForm] = useState(banner ?? { title: '', subtitle: '', cta: 'Book Now', cta_link: '', audience: 'all', placement: 'home', bg_color: '#1A3A6E', text_color: '#FFFFFF', start: '', end: '', active: true });
  return (
    <div className="fixed inset-0 bg-black/60 backdrop-blur-sm z-50 flex items-center justify-center p-4" onClick={onClose}>
      <div className="bg-dark-card border border-dark-border rounded-2xl w-full max-w-lg p-6 space-y-4 max-h-[90vh] overflow-y-auto" onClick={(e) => e.stopPropagation()}>
        <div className="flex items-center justify-between">
          <h2 className="font-heading font-bold text-slate-900">{banner ? 'Edit Banner' : 'New Banner'}</h2>
          <button onClick={onClose}><CancelCircleIcon size={20} className="text-slate-500 hover:text-slate-800 transition-colors" /></button>
        </div>
        {form.title && (
          <BannerPreview banner={form} />
        )}
        <div className="space-y-3">
          {[
            { key: 'title', label: 'Title', placeholder: 'Weekend Special' },
            { key: 'subtitle', label: 'Subtitle', placeholder: 'Get 20% off your next ride' },
            { key: 'cta', label: 'CTA Button Text', placeholder: 'Book Now' },
            { key: 'cta_link', label: 'CTA Link', placeholder: '/promo/CODE' },
          ].map(({ key, label, placeholder }) => (
            <div key={key}>
              <label className="text-[11px] uppercase tracking-widest text-slate-500 mb-1 block">{label}</label>
              <input value={form[key] ?? ''} onChange={(e) => setForm((f) => ({ ...f, [key]: e.target.value }))} placeholder={placeholder}
                className="w-full bg-dark-bg border border-dark-border rounded-xl px-3 py-2.5 text-sm text-slate-800 placeholder-slate-400 outline-none focus:border-primary/50 transition-colors" />
            </div>
          ))}
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="text-[11px] uppercase tracking-widest text-slate-500 mb-1 block">Audience</label>
              <select value={form.audience} onChange={(e) => setForm((f) => ({ ...f, audience: e.target.value }))}
                className="w-full bg-dark-bg border border-dark-border rounded-xl px-3 py-2.5 text-sm text-slate-700 outline-none">
                {Object.entries(AUDIENCE_OPTIONS).map(([k, v]) => <option key={k} value={k}>{v}</option>)}
              </select>
            </div>
            <div>
              <label className="text-[11px] uppercase tracking-widest text-slate-500 mb-1 block">Placement</label>
              <select value={form.placement} onChange={(e) => setForm((f) => ({ ...f, placement: e.target.value }))}
                className="w-full bg-dark-bg border border-dark-border rounded-xl px-3 py-2.5 text-sm text-slate-700 outline-none">
                {Object.entries(PLACEMENT_OPTIONS).map(([k, v]) => <option key={k} value={k}>{v}</option>)}
              </select>
            </div>
            <div>
              <label className="text-[11px] uppercase tracking-widest text-slate-500 mb-1 block">BG Color</label>
              <div className="flex gap-2 items-center">
                <input type="color" value={form.bg_color} onChange={(e) => setForm((f) => ({ ...f, bg_color: e.target.value }))} className="w-10 h-9 rounded-lg border border-dark-border bg-transparent cursor-pointer" />
                <input value={form.bg_color} onChange={(e) => setForm((f) => ({ ...f, bg_color: e.target.value }))} className="flex-1 bg-dark-bg border border-dark-border rounded-xl px-3 py-2 text-sm text-slate-800 outline-none" />
              </div>
            </div>
            <div>
              <label className="text-[11px] uppercase tracking-widest text-slate-500 mb-1 block">Text Color</label>
              <div className="flex gap-2 items-center">
                <input type="color" value={form.text_color} onChange={(e) => setForm((f) => ({ ...f, text_color: e.target.value }))} className="w-10 h-9 rounded-lg border border-dark-border bg-transparent cursor-pointer" />
                <input value={form.text_color} onChange={(e) => setForm((f) => ({ ...f, text_color: e.target.value }))} className="flex-1 bg-dark-bg border border-dark-border rounded-xl px-3 py-2 text-sm text-slate-800 outline-none" />
              </div>
            </div>
            <div>
              <label className="text-[11px] uppercase tracking-widest text-slate-500 mb-1 block">Start Date</label>
              <input type="date" value={form.start} onChange={(e) => setForm((f) => ({ ...f, start: e.target.value }))} className="w-full bg-dark-bg border border-dark-border rounded-xl px-3 py-2 text-sm text-slate-800 outline-none" />
            </div>
            <div>
              <label className="text-[11px] uppercase tracking-widest text-slate-500 mb-1 block">End Date</label>
              <input type="date" value={form.end} onChange={(e) => setForm((f) => ({ ...f, end: e.target.value }))} className="w-full bg-dark-bg border border-dark-border rounded-xl px-3 py-2 text-sm text-slate-800 outline-none" />
            </div>
          </div>
        </div>
        <div className="flex gap-3 pt-2 border-t border-dark-border">
          <button onClick={onClose} className="flex-1 py-2.5 rounded-xl text-sm font-semibold text-slate-500 bg-dark-bg border border-dark-border hover:text-slate-800 transition-colors">Cancel</button>
          <button onClick={() => onSave(form)} className="flex-1 py-2.5 rounded-xl text-sm font-semibold text-slate-900 bg-primary hover:bg-primary/80 transition-colors">
            {banner ? 'Update Banner' : 'Create Banner'}
          </button>
        </div>
      </div>
    </div>
  );
}

export default function AppBanners() {
  const [banners, setBanners] = useState(MOCK_BANNERS);
  const [modal, setModal] = useState(null);

  useEffect(() => {
    api.get('/admin/banners').then((r) => { if (r.data?.length) setBanners(r.data); }).catch(() => {});
  }, []);

  const toggle = async (id, active) => {
    try { await api.patch(`/admin/banners/${id}`, { active }); } catch {}
    setBanners((prev) => prev.map((b) => (b.id === id ? { ...b, active } : b)));
  };

  const deleteBanner = async (id) => {
    if (!confirm('Delete this banner?')) return;
    try { await api.delete(`/admin/banners/${id}`); } catch {}
    setBanners((prev) => prev.filter((b) => b.id !== id));
  };

  const saveBanner = async (form) => {
    if (modal?.id) {
      try { await api.patch(`/admin/banners/${modal.id}`, form); } catch {}
      setBanners((prev) => prev.map((b) => (b.id === modal.id ? { ...b, ...form } : b)));
    } else {
      const nb = { ...form, id: `b${Date.now()}`, impressions: 0, taps: 0, active: true };
      try { await api.post('/admin/banners', form); } catch {}
      setBanners((prev) => [...prev, nb]);
    }
    setModal(null);
  };

  return (
    <div className="p-6 space-y-6">
      {modal !== null && (
        <BannerModal banner={modal === 'new' ? null : modal} onClose={() => setModal(null)} onSave={saveBanner} />
      )}

      <div className="flex items-center justify-between flex-wrap gap-4">
        <div>
          <h1 className="font-heading font-bold text-slate-900 text-2xl">App Banners</h1>
          <p className="text-slate-500 text-sm mt-0.5">Manage in-app promotional banners</p>
        </div>
        <button onClick={() => setModal('new')} className="flex items-center gap-2 px-4 py-2.5 rounded-xl bg-primary text-slate-700 text-sm font-semibold hover:bg-primary/80 transition-colors">
          <PlusSignIcon size={16} /> New Banner
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
        {banners.map((b) => {
          const tapRate = b.impressions > 0 ? ((b.taps / b.impressions) * 100).toFixed(1) : 0;
          return (
            <div key={b.id} className={`bg-dark-card border rounded-2xl overflow-hidden ${b.active ? 'border-primary/30' : 'border-dark-border opacity-75'}`}>
              <BannerPreview banner={b} />
              <div className="p-4">
                <div className="flex items-center justify-between mb-3">
                  <div className="flex flex-wrap gap-1.5">
                    <span className="text-[10px] font-bold px-2 py-0.5 rounded-md bg-primary/10 text-primary border border-primary/20">{AUDIENCE_OPTIONS[b.audience]}</span>
                    <span className="text-[10px] font-bold px-2 py-0.5 rounded-md bg-dark-bg text-slate-500 border border-dark-border">{PLACEMENT_OPTIONS[b.placement]}</span>
                  </div>
                  <div className="flex items-center gap-1">
                    <button onClick={() => setModal(b)} className="p-1.5 rounded-lg text-slate-500 hover:text-slate-800 hover:bg-slate-50 transition-colors">
                      <Edit01Icon size={13} />
                    </button>
                    <button onClick={() => deleteBanner(b.id)} className="p-1.5 rounded-lg text-slate-500 hover:text-danger hover:bg-danger/10 transition-colors">
                      <Delete01Icon size={13} />
                    </button>
                  </div>
                </div>
                <div className="grid grid-cols-3 gap-2 mb-3">
                  <div className="text-center">
                    <p className="text-[10px] text-slate-500">Impressions</p>
                    <p className="font-heading font-bold text-sm text-primary">{b.impressions.toLocaleString()}</p>
                  </div>
                  <div className="text-center">
                    <p className="text-[10px] text-slate-500">Taps</p>
                    <p className="font-heading font-bold text-sm text-success">{b.taps}</p>
                  </div>
                  <div className="text-center">
                    <p className="text-[10px] text-slate-500">CTR</p>
                    <p className="font-heading font-bold text-sm text-orange">{tapRate}%</p>
                  </div>
                </div>
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-1 text-xs text-slate-500">
                    <Calendar01Icon size={11} />
                    {b.start} → {b.end}
                  </div>
                  <button onClick={() => toggle(b.id, !b.active)}>
                    {b.active ? <ToggleOnIcon size={26} className="text-success" /> : <ToggleOffIcon size={26} className="text-slate-500" />}
                  </button>
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
