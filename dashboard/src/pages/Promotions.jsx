import React, { useState, useEffect } from 'react';
import {
  GiftIcon, CouponPercentIcon, PercentIcon, Ticket01Icon, PlusSignIcon, Edit01Icon,
  Delete01Icon, ToggleOnIcon, ToggleOffIcon, CancelCircleIcon, CheckmarkCircle01Icon,
  Calendar01Icon, UserGroupIcon, ChartUpIcon, Coins01Icon,
} from 'hugeicons-react';
import api from '../config/api';

const TYPE_COLORS = {
  percentage: 'text-primary bg-primary/10 border-primary/20',
  fixed: 'text-success bg-success/10 border-success/20',
  free_ride: 'text-orange bg-orange/10 border-orange/20',
};

const MOCK_PROMOS = [
  { id: 'p1', code: 'GOMA20', type: 'percentage', discount: 20, min_fare: 3000, max_uses: 500, used: 142, active: true, expires: '2025-06-01', description: 'Weekend promo — 20% off all rides' },
  { id: 'p2', code: 'WELCOME', type: 'fixed', discount: 2000, min_fare: 2500, max_uses: 1000, used: 847, active: true, expires: '2025-12-31', description: 'New user welcome bonus — FC 2,000 off' },
  { id: 'p3', code: 'FREEFIRST', type: 'free_ride', discount: 100, min_fare: 0, max_uses: 200, used: 200, active: false, expires: '2025-05-01', description: 'First ride free (up to FC 5,000)' },
  { id: 'p4', code: 'RAMADAN25', type: 'percentage', discount: 25, min_fare: 4000, max_uses: 300, used: 88, active: false, expires: '2025-04-01', description: 'Ramadan special — 25% off' },
];

function PromoModal({ promo, onClose, onSave }) {
  const [form, setForm] = useState(promo ?? { code: '', type: 'percentage', discount: '', min_fare: '', max_uses: '', expires: '', description: '', active: true });
  return (
    <div className="fixed inset-0 bg-black/60 backdrop-blur-sm z-50 flex items-center justify-center p-4" onClick={onClose}>
      <div className="bg-dark-card border border-dark-border rounded-2xl w-full max-w-md p-6 space-y-4" onClick={(e) => e.stopPropagation()}>
        <div className="flex items-center justify-between">
          <h2 className="font-heading font-bold text-slate-900">{promo ? 'Edit Promo' : 'New Promo Code'}</h2>
          <button onClick={onClose}><CancelCircleIcon size={20} className="text-slate-500 hover:text-slate-800 transition-colors" /></button>
        </div>
        <div className="space-y-3">
          {[
            { key: 'code', label: 'Promo Code', type: 'text', placeholder: 'e.g. GOMA20' },
            { key: 'description', label: 'Description', type: 'text', placeholder: 'Short description' },
            { key: 'discount', label: 'Discount (% or FC)', type: 'number', placeholder: '20' },
            { key: 'min_fare', label: 'Min. Fare (FC)', type: 'number', placeholder: '3000' },
            { key: 'max_uses', label: 'Max Uses', type: 'number', placeholder: '500' },
            { key: 'expires', label: 'Expiry Date', type: 'date', placeholder: '' },
          ].map(({ key, label, type, placeholder }) => (
            <div key={key}>
              <label className="text-[11px] uppercase tracking-widest text-slate-500 mb-1 block">{label}</label>
              <input type={type} value={form[key] ?? ''} onChange={(e) => setForm((f) => ({ ...f, [key]: e.target.value }))} placeholder={placeholder}
                className="w-full bg-dark-bg border border-dark-border rounded-xl px-3 py-2.5 text-sm text-slate-800 placeholder-slate-400 outline-none focus:border-primary/50 transition-colors" />
            </div>
          ))}
          <div>
            <label className="text-[11px] uppercase tracking-widest text-slate-500 mb-1 block">Type</label>
            <select value={form.type} onChange={(e) => setForm((f) => ({ ...f, type: e.target.value }))}
              className="w-full bg-dark-bg border border-dark-border rounded-xl px-3 py-2.5 text-sm text-slate-700 outline-none">
              <option value="percentage">Percentage Discount</option>
              <option value="fixed">Fixed Amount</option>
              <option value="free_ride">Free Ride</option>
            </select>
          </div>
        </div>
        <div className="flex gap-3 pt-2 border-t border-dark-border">
          <button onClick={onClose} className="flex-1 py-2.5 rounded-xl text-sm font-semibold text-slate-500 bg-dark-bg border border-dark-border hover:text-slate-800 transition-colors">Cancel</button>
          <button onClick={() => onSave(form)} className="flex-1 py-2.5 rounded-xl text-sm font-semibold text-slate-900 bg-primary hover:bg-primary/80 transition-colors">
            {promo ? 'Update' : 'Create'}
          </button>
        </div>
      </div>
    </div>
  );
}

export default function Promotions() {
  const [promos, setPromos] = useState(MOCK_PROMOS);
  const [modal, setModal] = useState(null);

  useEffect(() => {
    api.get('/admin/promotions').then((r) => { if (r.data?.length) setPromos(r.data); }).catch(() => {});
  }, []);

  const toggle = async (id, active) => {
    try { await api.patch(`/admin/promotions/${id}`, { active }); } catch {}
    setPromos((prev) => prev.map((p) => (p.id === id ? { ...p, active } : p)));
  };

  const deletePromo = async (id) => {
    if (!confirm('Delete this promo code?')) return;
    try { await api.delete(`/admin/promotions/${id}`); } catch {}
    setPromos((prev) => prev.filter((p) => p.id !== id));
  };

  const savePromo = async (form) => {
    if (modal?.id) {
      try { await api.patch(`/admin/promotions/${modal.id}`, form); } catch {}
      setPromos((prev) => prev.map((p) => (p.id === modal.id ? { ...p, ...form } : p)));
    } else {
      const np = { ...form, id: `p${Date.now()}`, used: 0, active: true };
      try { await api.post('/admin/promotions', form); } catch {}
      setPromos((prev) => [...prev, np]);
    }
    setModal(null);
  };

  const activeCount = promos.filter((p) => p.active).length;
  const totalRedemptions = promos.reduce((a, p) => a + p.used, 0);

  return (
    <div className="p-6 space-y-6">
      {modal !== null && (
        <PromoModal promo={modal === 'new' ? null : modal} onClose={() => setModal(null)} onSave={savePromo} />
      )}

      <div className="flex items-center justify-between flex-wrap gap-4">
        <div>
          <h1 className="font-heading font-bold text-slate-900 text-2xl">Promotions</h1>
          <p className="text-slate-500 text-sm mt-0.5">Promo codes, discounts, and ride offers</p>
        </div>
        <button onClick={() => setModal('new')} className="flex items-center gap-2 px-4 py-2.5 rounded-xl bg-primary text-slate-700 text-sm font-semibold hover:bg-primary/80 transition-colors">
          <PlusSignIcon size={16} /> New Promo
        </button>
      </div>

      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        {[
          { label: 'Total Promos', value: promos.length, icon: Ticket01Icon, color: 'text-primary' },
          { label: 'Active', value: activeCount, icon: CheckmarkCircle01Icon, color: 'text-success' },
          { label: 'Total Redeemed', value: totalRedemptions.toLocaleString(), icon: ChartUpIcon, color: 'text-orange' },
          { label: 'Revenue Impact', value: '-FC 847K', icon: Coins01Icon, color: 'text-warning' },
        ].map(({ label, value, icon: Icon, color }) => (
          <div key={label} className="bg-dark-card border border-dark-border rounded-2xl p-4">
            <div className="flex items-center gap-2 mb-2"><Icon size={15} className={color} /><span className="text-xs text-slate-500">{label}</span></div>
            <p className={`font-heading font-bold text-2xl ${color}`}>{value}</p>
          </div>
        ))}
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
        {promos.map((p) => {
          const usagePct = Math.min((p.used / p.max_uses) * 100, 100);
          const expired = p.expires && new Date(p.expires) < new Date();
          return (
            <div key={p.id} className={`bg-dark-card border rounded-2xl p-5 transition-all ${p.active && !expired ? 'border-primary/30' : 'border-dark-border opacity-75'}`}>
              <div className="flex items-start justify-between mb-3">
                <div>
                  <div className="flex items-center gap-2 flex-wrap">
                    <span className="font-heading font-black text-xl text-slate-900 tracking-wider">{p.code}</span>
                    <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full border ${TYPE_COLORS[p.type]}`}>
                      {p.type.replace('_', ' ').toUpperCase()}
                    </span>
                  </div>
                  <p className="text-xs text-slate-500 mt-1">{p.description}</p>
                </div>
                <div className="flex items-center gap-1">
                  <button onClick={() => setModal(p)} className="p-1.5 rounded-lg text-slate-500 hover:text-slate-800 hover:bg-slate-50 transition-colors">
                    <Edit01Icon size={14} />
                  </button>
                  <button onClick={() => deletePromo(p.id)} className="p-1.5 rounded-lg text-slate-500 hover:text-danger hover:bg-danger/10 transition-colors">
                    <Delete01Icon size={14} />
                  </button>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-2 mb-3">
                <div className="bg-dark-bg/50 rounded-xl p-2.5">
                  <p className="text-[10px] text-slate-500 mb-0.5">Discount</p>
                  <p className="font-heading font-bold text-primary">
                    {p.type === 'percentage' ? `${p.discount}%` : p.type === 'fixed' ? `FC ${p.discount.toLocaleString()}` : 'Free'}
                  </p>
                </div>
                <div className="bg-dark-bg/50 rounded-xl p-2.5">
                  <p className="text-[10px] text-slate-500 mb-0.5">Min. Fare</p>
                  <p className="font-heading font-bold text-slate-600">FC {p.min_fare.toLocaleString()}</p>
                </div>
              </div>

              {/* Usage bar */}
              <div className="mb-3">
                <div className="flex justify-between text-xs mb-1">
                  <span className="text-slate-500">Usage</span>
                  <span className="text-slate-500">{p.used} / {p.max_uses}</span>
                </div>
                <div className="h-1.5 bg-dark-bg rounded-full overflow-hidden">
                  <div
                    className={`h-full rounded-full transition-all ${usagePct >= 100 ? 'bg-danger' : usagePct >= 75 ? 'bg-warning' : 'bg-primary'}`}
                    style={{ width: `${usagePct}%` }}
                  />
                </div>
              </div>

              <div className="flex items-center justify-between">
                <div className="flex items-center gap-1 text-xs text-slate-500">
                  <Calendar01Icon size={11} />
                  {expired ? <span className="text-danger">Expired {p.expires}</span> : `Exp. ${p.expires}`}
                </div>
                <button
                  onClick={() => toggle(p.id, !p.active)}
                  className={p.active ? 'text-success' : 'text-slate-500'}
                >
                  {p.active ? <ToggleOnIcon size={26} /> : <ToggleOffIcon size={26} />}
                </button>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
