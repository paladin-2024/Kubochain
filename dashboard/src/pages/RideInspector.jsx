import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import {
  ArrowLeft01Icon, Motorbike01Icon, MapPinpoint01Icon, UserGroupIcon, UserCheck01Icon,
  Clock01Icon, Money01Icon, CancelCircleIcon, CheckmarkCircle01Icon, Route01Icon,
  Navigation01Icon, FlashIcon, StarIcon, CallIncoming01Icon,
} from 'hugeicons-react';
import api from '../config/api';
import Avatar from '../components/Avatar';

const STATUS_STYLES = {
  pending: 'text-warning bg-warning/10 border-warning/20',
  accepted: 'text-primary bg-primary/10 border-primary/20',
  arriving: 'text-orange bg-orange/10 border-orange/20',
  in_progress: 'text-success bg-success/10 border-success/20',
  completed: 'text-slate-600 bg-slate-100 border-slate-200',
  cancelled: 'text-danger bg-danger/10 border-danger/20',
};

const MOCK_RIDE = {
  _id: 'RD-4521',
  status: 'in_progress',
  fare: 6500,
  distance_km: 4.2,
  duration_min: 18,
  surge_multiplier: 1.0,
  payment_method: 'cash',
  created_at: '2025-05-17T14:22:00Z',
  pickup: { address: '12 Rue de la Paix, Goma Centre', lat: -1.6792, lng: 29.2228 },
  destination: { address: 'Birere Market, Entrée Principale', lat: -1.6950, lng: 29.2100 },
  driver: { id: 'D-142', name: 'Jean-Pierre Bauma', phone: '+243 812 345 678', rating: 4.8, plate: 'GOM-4521', vehicle: 'Honda CB500' },
  passenger: { id: 'U-887', name: 'Marie Kavira', phone: '+243 998 765 432', rating: 4.5, total_rides: 48 },
  timeline: [
    { event: 'Ride Requested', time: '14:22:00' },
    { event: 'Driver Accepted', time: '14:23:15' },
    { event: 'Driver Arriving', time: '14:24:30' },
    { event: 'Ride Started', time: '14:28:45' },
  ],
};

export default function RideInspector() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [ride, setRide] = useState(MOCK_RIDE);
  const [cancelling, setCancelling] = useState(false);

  useEffect(() => {
    if (id) {
      api.get(`/admin/rides/${id}`).then((r) => { if (r.data) setRide(r.data); }).catch(() => {});
    }
  }, [id]);

  const cancelRide = async () => {
    if (!confirm('Cancel this ride?')) return;
    setCancelling(true);
    try {
      await api.patch(`/admin/rides/${ride._id}/cancel`);
      setRide((r) => ({ ...r, status: 'cancelled' }));
    } catch {}
    setCancelling(false);
  };

  const s = STATUS_STYLES[ride.status] ?? STATUS_STYLES.pending;
  const activeStatuses = new Set(['pending', 'accepted', 'arriving', 'in_progress']);
  const isActive = activeStatuses.has(ride.status);

  return (
    <div className="p-6 space-y-6 max-w-4xl mx-auto">
      {/* Header */}
      <div className="flex items-center gap-3 flex-wrap">
        <button onClick={() => navigate(-1)} className="p-2 rounded-xl bg-dark-card border border-dark-border text-slate-500 hover:text-slate-800 transition-colors">
          <ArrowLeft01Icon size={16} />
        </button>
        <div className="flex-1">
          <div className="flex items-center gap-2 flex-wrap">
            <h1 className="font-heading font-bold text-slate-900 text-xl">{ride._id}</h1>
            <span className={`text-[11px] font-bold px-2.5 py-0.5 rounded-full border ${s}`}>
              {ride.status.replace('_', ' ').toUpperCase()}
            </span>
          </div>
          <p className="text-slate-500 text-sm mt-0.5">{new Date(ride.created_at).toLocaleString()}</p>
        </div>
        {isActive && (
          <button
            onClick={cancelRide}
            disabled={cancelling}
            className="flex items-center gap-2 px-4 py-2.5 rounded-xl bg-danger/10 text-danger border border-danger/20 hover:bg-danger/20 text-sm font-semibold transition-colors disabled:opacity-50"
          >
            <CancelCircleIcon size={15} />
            Cancel Ride
          </button>
        )}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        {/* Fare stats */}
        <div className="bg-dark-card border border-dark-border rounded-2xl p-5 space-y-4">
          <h2 className="font-heading font-semibold text-slate-900 text-sm uppercase tracking-widest text-slate-500">Fare Summary</h2>
          {[
            { label: 'Total Fare', value: `FC ${ride.fare?.toLocaleString()}`, color: 'text-orange', icon: Money01Icon },
            { label: 'Distance', value: `${ride.distance_km} km`, color: 'text-primary', icon: Route01Icon },
            { label: 'Duration', value: `${ride.duration_min} min`, color: 'text-success', icon: Clock01Icon },
            { label: 'Surge', value: `${ride.surge_multiplier}x`, color: ride.surge_multiplier > 1 ? 'text-warning' : 'text-slate-500', icon: FlashIcon },
            { label: 'Payment', value: ride.payment_method, color: 'text-slate-600', icon: Money01Icon },
          ].map(({ label, value, color, icon: Icon }) => (
            <div key={label} className="flex items-center justify-between">
              <div className="flex items-center gap-2 text-slate-500 text-sm">
                <Icon size={13} />
                {label}
              </div>
              <span className={`font-semibold text-sm ${color}`}>{value}</span>
            </div>
          ))}
        </div>

        {/* Route */}
        <div className="bg-dark-card border border-dark-border rounded-2xl p-5 space-y-4">
          <h2 className="font-heading font-semibold text-slate-900 text-sm uppercase tracking-widest text-slate-500">Route</h2>
          <div className="space-y-3">
            <div className="flex items-start gap-3">
              <div className="w-8 h-8 rounded-full bg-success/15 border border-success/30 flex items-center justify-center flex-shrink-0 mt-0.5">
                <MapPinpoint01Icon size={14} className="text-success" />
              </div>
              <div>
                <p className="text-[10px] uppercase text-slate-500 tracking-widest mb-0.5">Pickup</p>
                <p className="text-sm text-slate-700 font-medium">{ride.pickup?.address}</p>
              </div>
            </div>
            <div className="ml-4 w-px h-6 bg-dark-border" />
            <div className="flex items-start gap-3">
              <div className="w-8 h-8 rounded-full bg-danger/15 border border-danger/30 flex items-center justify-center flex-shrink-0 mt-0.5">
                <Navigation01Icon size={14} className="text-danger" />
              </div>
              <div>
                <p className="text-[10px] uppercase text-slate-500 tracking-widest mb-0.5">Destination</p>
                <p className="text-sm text-slate-700 font-medium">{ride.destination?.address}</p>
              </div>
            </div>
          </div>
          {/* Timeline */}
          <div className="pt-3 border-t border-dark-border">
            <p className="text-[10px] uppercase text-slate-500 tracking-widest mb-2">Timeline</p>
            <div className="space-y-1.5">
              {ride.timeline?.map((t, i) => (
                <div key={i} className="flex items-center justify-between text-xs">
                  <span className="text-slate-500">{t.event}</span>
                  <span className="font-mono text-slate-500">{t.time}</span>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* People */}
        <div className="space-y-4">
          {[
            { label: 'Driver', person: ride.driver, icon: Motorbike01Icon, color: 'text-orange', extra: `${ride.driver?.vehicle} · ${ride.driver?.plate}`, link: `/drivers/${ride.driver?.id}` },
            { label: 'Passenger', person: ride.passenger, icon: UserGroupIcon, color: 'text-primary', extra: `${ride.passenger?.total_rides} rides total`, link: `/users/${ride.passenger?.id}` },
          ].map(({ label, person, icon: Icon, color, extra, link }) => (
            <div key={label} className="bg-dark-card border border-dark-border rounded-2xl p-5">
              <div className="flex items-center gap-2 mb-3">
                <Icon size={14} className={color} />
                <span className="text-[10px] uppercase text-slate-500 tracking-widest">{label}</span>
              </div>
              <div className="flex items-center gap-3">
                <Avatar name={person?.name || ''} size={40} />
                <div>
                  <a href={link} className="font-heading font-semibold text-slate-900 hover:text-primary transition-colors">{person?.name}</a>
                  <p className="text-xs text-slate-500">{person?.phone}</p>
                  <p className="text-xs text-slate-500 mt-0.5">{extra}</p>
                </div>
                <div className="ml-auto flex items-center gap-1 text-warning text-xs font-bold">
                  <StarIcon size={12} />
                  {person?.rating}
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
