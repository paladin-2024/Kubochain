import React, { useState, useEffect } from 'react';
import {
  MapsIcon, MapPinpoint01Icon, PlusSignIcon, Edit01Icon, Delete01Icon,
  ToggleOnIcon, ToggleOffIcon, Motorbike01Icon, UserGroupIcon, ChartUpIcon,
  CheckmarkCircle01Icon, CancelCircleIcon, Search01Icon, Cancel01Icon,
  Location01Icon, GlobeIcon, Settings01Icon, Route01Icon,
} from 'hugeicons-react';
import api from '../config/api';

const MOCK_ZONES = [
  { id: 'z1', name: 'Goma Centre', description: 'City center and commercial district', active: true, drivers_online: 24, active_rides: 18, total_rides: 4821, area_km2: 12.5, lat: -1.6792, lng: 29.2228 },
  { id: 'z2', name: 'Birere Market', description: 'Busy market district with high foot traffic', active: true, drivers_online: 15, active_rides: 9, total_rides: 2145, area_km2: 8.2, lat: -1.6950, lng: 29.2100 },
  { id: 'z3', name: 'Ndosho', description: 'Residential zone north of centre', active: true, drivers_online: 8, active_rides: 4, total_rides: 1203, area_km2: 15.0, lat: -1.6500, lng: 29.2300 },
  { id: 'z4', name: 'Himbi', description: 'Western residential area', active: false, drivers_online: 0, active_rides: 0, total_rides: 987, area_km2: 9.8, lat: -1.6900, lng: 29.1900 },
  { id: 'z5', name: 'Katindo', description: 'Northern zone near Congo Park', active: true, drivers_online: 11, active_rides: 7, total_rides: 1654, area_km2: 11.3, lat: -1.6600, lng: 29.2450 },
  { id: 'z6', name: 'Karisimbi', description: 'Volcano slopes residential area', active: false, drivers_online: 0, active_rides: 0, total_rides: 432, area_km2: 20.1, lat: -1.5800, lng: 29.2600 },
];

function ZoneModal({ zone, onClose, onSave }) {
  const [form, setForm] = useState(zone ?? { name: '', description: '', active: true, lat: '', lng: '', area_km2: '' });
  return (
    <div className="fixed inset-0 bg-black/60 backdrop-blur-sm z-50 flex items-center justify-center p-4" onClick={onClose}>
      <div className="bg-dark-card border border-dark-border rounded-2xl w-full max-w-md p-6 space-y-4" onClick={(e) => e.stopPropagation()}>
        <div className="flex items-center justify-between">
          <h2 className="font-heading font-bold text-slate-900">{zone ? 'Edit Zone' : 'New Zone'}</h2>
          <button onClick={onClose}><CancelCircleIcon size={20} className="text-slate-500 hover:text-slate-800 transition-colors" /></button>
        </div>
        <div className="space-y-3">
          {[
            { key: 'name', label: 'Zone Name', type: 'text', placeholder: 'e.g. Goma Centre' },
            { key: 'description', label: 'Description', type: 'text', placeholder: 'Short description' },
            { key: 'lat', label: 'Latitude', type: 'number', placeholder: '-1.6792' },
            { key: 'lng', label: 'Longitude', type: 'number', placeholder: '29.2228' },
            { key: 'area_km2', label: 'Area (km²)', type: 'number', placeholder: '10.5' },
          ].map(({ key, label, type, placeholder }) => (
            <div key={key}>
              <label className="text-[11px] uppercase tracking-widest text-slate-500 mb-1 block">{label}</label>
              <input
                type={type}
                value={form[key] ?? ''}
                onChange={(e) => setForm((f) => ({ ...f, [key]: e.target.value }))}
                placeholder={placeholder}
                className="w-full bg-dark-bg border border-dark-border rounded-xl px-3 py-2.5 text-sm text-slate-800 placeholder-slate-400 outline-none focus:border-primary/50 transition-colors"
              />
            </div>
          ))}
          <div className="flex items-center justify-between py-2">
            <span className="text-sm text-slate-600">Zone Active</span>
            <button onClick={() => setForm((f) => ({ ...f, active: !f.active }))}>
              {form.active ? <ToggleOnIcon size={28} className="text-success" /> : <ToggleOffIcon size={28} className="text-slate-500" />}
            </button>
          </div>
        </div>
        <div className="flex gap-3 pt-2 border-t border-dark-border">
          <button onClick={onClose} className="flex-1 py-2.5 rounded-xl text-sm font-semibold text-slate-500 bg-dark-bg border border-dark-border hover:text-slate-800 transition-colors">Cancel</button>
          <button onClick={() => onSave(form)} className="flex-1 py-2.5 rounded-xl text-sm font-semibold text-slate-900 bg-primary hover:bg-primary/80 transition-colors">
            {zone ? 'Update Zone' : 'Create Zone'}
          </button>
        </div>
      </div>
    </div>
  );
}

export default function Zones() {
  const [zones, setZones] = useState(MOCK_ZONES);
  const [search, setSearch] = useState('');
  const [modal, setModal] = useState(null);

  useEffect(() => {
    api.get('/admin/zones').then((r) => { if (r.data?.length) setZones(r.data); }).catch(() => {});
  }, []);

  const toggleZone = async (id, active) => {
    try { await api.patch(`/admin/zones/${id}`, { active }); } catch {}
    setZones((prev) => prev.map((z) => (z.id === id ? { ...z, active } : z)));
  };

  const saveZone = async (form) => {
    if (modal?.id) {
      try { await api.patch(`/admin/zones/${modal.id}`, form); } catch {}
      setZones((prev) => prev.map((z) => (z.id === modal.id ? { ...z, ...form } : z)));
    } else {
      const newZone = { ...form, id: `z${Date.now()}`, drivers_online: 0, active_rides: 0, total_rides: 0 };
      try { await api.post('/admin/zones', form); } catch {}
      setZones((prev) => [...prev, newZone]);
    }
    setModal(null);
  };

  const deleteZone = async (id) => {
    if (!confirm('Delete this zone?')) return;
    try { await api.delete(`/admin/zones/${id}`); } catch {}
    setZones((prev) => prev.filter((z) => z.id !== id));
  };

  const filtered = zones.filter((z) => !search || z.name.toLowerCase().includes(search.toLowerCase()));
  const activeCount = zones.filter((z) => z.active).length;
  const totalDrivers = zones.reduce((a, z) => a + z.drivers_online, 0);
  const totalRides = zones.reduce((a, z) => a + z.active_rides, 0);

  return (
    <div className="p-6 space-y-6">
      {modal !== null && (
        <ZoneModal
          zone={modal === 'new' ? null : modal}
          onClose={() => setModal(null)}
          onSave={saveZone}
        />
      )}

      <div className="flex items-center justify-between flex-wrap gap-4">
        <div>
          <h1 className="font-heading font-bold text-slate-900 text-2xl">Service Zones</h1>
          <p className="text-slate-500 text-sm mt-0.5">Manage operational areas and coverage</p>
        </div>
        <button
          onClick={() => setModal('new')}
          className="flex items-center gap-2 px-4 py-2.5 rounded-xl bg-primary text-slate-700 text-sm font-semibold hover:bg-primary/80 transition-colors"
        >
          <PlusSignIcon size={16} />
          Add Zone
        </button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        {[
          { label: 'Total Zones', value: zones.length, icon: MapsIcon, color: 'text-primary' },
          { label: 'Active Zones', value: activeCount, icon: CheckmarkCircle01Icon, color: 'text-success' },
          { label: 'Drivers Online', value: totalDrivers, icon: Motorbike01Icon, color: 'text-orange' },
          { label: 'Active Rides', value: totalRides, icon: Route01Icon, color: 'text-warning' },
        ].map(({ label, value, icon: Icon, color }) => (
          <div key={label} className="bg-dark-card border border-dark-border rounded-2xl p-4">
            <div className="flex items-center gap-2 mb-2">
              <Icon size={15} className={color} />
              <span className="text-xs text-slate-500">{label}</span>
            </div>
            <p className={`font-heading font-bold text-2xl ${color}`}>{value}</p>
          </div>
        ))}
      </div>

      {/* Search */}
      <div className="flex items-center gap-2 bg-dark-card border border-dark-border rounded-xl px-3 py-2 max-w-xs">
        <Search01Icon size={15} className="text-slate-500" />
        <input value={search} onChange={(e) => setSearch(e.target.value)} placeholder="Search zones..." className="bg-transparent text-sm text-slate-800 placeholder-slate-400 flex-1 outline-none" />
        {search && <button onClick={() => setSearch('')}><Cancel01Icon size={13} className="text-slate-500" /></button>}
      </div>

      {/* Zone grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
        {filtered.map((zone) => (
          <div
            key={zone.id}
            className={`bg-dark-card border rounded-2xl p-5 transition-all ${zone.active ? 'border-success/30' : 'border-dark-border opacity-75'}`}
          >
            <div className="flex items-start justify-between mb-3">
              <div>
                <div className="flex items-center gap-2">
                  <MapPinpoint01Icon size={15} className={zone.active ? 'text-success' : 'text-slate-500'} />
                  <span className="font-heading font-semibold text-slate-900">{zone.name}</span>
                </div>
                <p className="text-xs text-slate-500 mt-0.5">{zone.description}</p>
              </div>
              <div className="flex items-center gap-1.5">
                <button onClick={() => setModal(zone)} className="p-1.5 rounded-lg text-slate-500 hover:text-slate-800 hover:bg-slate-50 transition-colors">
                  <Edit01Icon size={14} />
                </button>
                <button onClick={() => deleteZone(zone.id)} className="p-1.5 rounded-lg text-slate-500 hover:text-danger hover:bg-danger/10 transition-colors">
                  <Delete01Icon size={14} />
                </button>
              </div>
            </div>

            <div className="grid grid-cols-3 gap-2 mb-4">
              {[
                { label: 'Drivers', value: zone.drivers_online, color: 'text-orange' },
                { label: 'Rides', value: zone.active_rides, color: 'text-primary' },
                { label: 'Total', value: zone.total_rides?.toLocaleString(), color: 'text-success' },
              ].map(({ label, value, color }) => (
                <div key={label} className="bg-slate-50 rounded-xl p-2 text-center">
                  <p className="text-[10px] text-slate-500 mb-0.5">{label}</p>
                  <p className={`font-heading font-bold text-base ${color}`}>{value}</p>
                </div>
              ))}
            </div>

            <div className="flex items-center justify-between text-xs text-slate-500 mb-3">
              <div className="flex items-center gap-1">
                <GlobeIcon size={11} />
                {zone.area_km2} km²
              </div>
              <div className="flex items-center gap-1">
                <Location01Icon size={11} />
                {zone.lat?.toFixed(4)}, {zone.lng?.toFixed(4)}
              </div>
            </div>

            <button
              onClick={() => toggleZone(zone.id, !zone.active)}
              className={`w-full flex items-center justify-center gap-2 py-2.5 rounded-xl text-sm font-semibold transition-all ${
                zone.active
                  ? 'bg-danger/10 text-danger border border-danger/20 hover:bg-danger/20'
                  : 'bg-success/10 text-success border border-success/20 hover:bg-success/20'
              }`}
            >
              {zone.active ? <ToggleOffIcon size={15} /> : <ToggleOnIcon size={15} />}
              {zone.active ? 'Deactivate Zone' : 'Activate Zone'}
            </button>
          </div>
        ))}
      </div>
    </div>
  );
}
