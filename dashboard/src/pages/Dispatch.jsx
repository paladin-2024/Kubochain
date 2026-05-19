import React, { useState, useEffect, useRef, useCallback } from 'react';
import { MapContainer, TileLayer, CircleMarker, Polyline, Tooltip, useMap } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';
import {
  Motorbike01Icon, MapPinpoint01Icon, MapsIcon, Activity01Icon,
  Refresh01Icon, Navigation01Icon,
} from 'hugeicons-react';
import api from '../config/api';
import Avatar from '../components/Avatar';

const GOMA_CENTER = [-1.6792, 29.2228];
const ROUTE_COLORS = ['#6366F1', '#22C55E', '#F97316', '#EAB308', '#EF4444'];

const MOCK_DRIVERS = [
  { id: 'D1', name: 'Jean-Pierre B.', status: 'online', lat: -1.6790, lng: 29.2230, rides_today: 8 },
  { id: 'D2', name: 'Sylvie N.',      status: 'busy',   lat: -1.6850, lng: 29.2180, rides_today: 12 },
  { id: 'D3', name: 'Patrick N.',     status: 'online', lat: -1.6720, lng: 29.2300, rides_today: 5 },
  { id: 'D4', name: 'Grace A.',       status: 'busy',   lat: -1.6950, lng: 29.2120, rides_today: 9 },
  { id: 'D5', name: 'Rodrigue M.',    status: 'online', lat: -1.6660, lng: 29.2380, rides_today: 3 },
];

const MOCK_ACTIVE_RIDES = [
  {
    id: 'RD-4521', driver: 'Jean-Pierre B.', passenger: 'Marie K.',
    pickup:      { lat: -1.6790, lng: 29.2230, address: 'Goma Centre' },
    destination: { lat: -1.6950, lng: 29.2100, address: 'Birere Market' },
  },
  {
    id: 'RD-4522', driver: 'Grace A.', passenger: 'Alain T.',
    pickup:      { lat: -1.6950, lng: 29.2120, address: 'Ndosho' },
    destination: { lat: -1.6720, lng: 29.2280, address: 'Katindo' },
  },
];

function PanTo({ target }) {
  const map = useMap();
  useEffect(() => {
    if (target) map.setView([target.lat, target.lng], 16, { animate: true });
  }, [target, map]);
  return null;
}

export default function Dispatch() {
  const [drivers, setDrivers] = useState(MOCK_DRIVERS);
  const [rides, setRides] = useState(MOCK_ACTIVE_RIDES);
  const [selected, setSelected] = useState(null);
  const [fetching, setFetching] = useState(false);
  const wsRef = useRef(null);

  const fetchData = useCallback(() => {
    setFetching(true);
    Promise.all([
      api.get('/admin/drivers/online').catch(() => ({ data: null })),
      api.get('/admin/rides/active').catch(() => ({ data: null })),
    ]).then(([dRes, rRes]) => {
      if (dRes.data?.length) setDrivers(dRes.data);
      if (rRes.data?.length) setRides(rRes.data);
    }).finally(() => setFetching(false));
  }, []);

  useEffect(() => {
    fetchData();

    const wsUrl = import.meta.env.VITE_WS_URL ?? 'ws://localhost:8000';
    wsRef.current = new WebSocket(`${wsUrl}/ws/admin`);
    wsRef.current.onmessage = (e) => {
      try {
        const { event, data } = JSON.parse(e.data);
        if (event === 'driver_location_update') {
          setDrivers((prev) => prev.map((d) =>
            d.id === data.driver_id ? { ...d, lat: data.lat, lng: data.lng } : d
          ));
        }
        if (event === 'ride_started' || event === 'ride_completed') {
          api.get('/admin/rides/active').then((r) => { if (r.data) setRides(r.data); }).catch(() => {});
        }
      } catch {}
    };
    return () => wsRef.current?.close();
  }, [fetchData]);

  const onlineCount = drivers.filter((d) => d.status === 'online').length;
  const busyCount   = drivers.filter((d) => d.status === 'busy').length;

  return (
    <div className="flex flex-col flex-1 h-full">
      {/* Top bar */}
      <div className="flex items-center gap-4 px-4 py-3 bg-white border-b border-dark-border flex-wrap flex-shrink-0">
        <div className="flex items-center gap-2">
          <MapsIcon size={16} className="text-primary" />
          <span className="font-heading font-semibold text-slate-900">Live Dispatch</span>
        </div>
        <div className="flex items-center gap-4 ml-auto text-sm flex-wrap">
          <div className="flex items-center gap-1.5">
            <span className="w-2 h-2 rounded-full bg-success animate-pulse" />
            <span className="text-slate-500">{onlineCount} Available</span>
          </div>
          <div className="flex items-center gap-1.5">
            <span className="w-2 h-2 rounded-full bg-orange" />
            <span className="text-slate-500">{busyCount} On Ride</span>
          </div>
          <div className="flex items-center gap-1.5">
            <Activity01Icon size={13} className="text-primary" />
            <span className="text-slate-500">{rides.length} Active Rides</span>
          </div>
          <button
            onClick={fetchData}
            className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-slate-50 border border-dark-border text-slate-500 hover:text-slate-800 text-xs transition-colors"
          >
            <Refresh01Icon size={12} className={fetching ? 'animate-spin' : ''} />
            Refresh
          </button>
        </div>
      </div>

      <div className="flex flex-1 overflow-hidden">
        {/* Map */}
        <div className="flex-1 relative" style={{ zIndex: 0 }}>
          <MapContainer
            center={GOMA_CENTER}
            zoom={14}
            style={{ height: '100%', width: '100%' }}
            zoomControl
            scrollWheelZoom
            attributionControl={false}
          >
            <TileLayer
              url="https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png"
              attribution='&copy; CARTO'
            />

            {selected && <PanTo target={selected} />}

            {/* Straight-line routes */}
            {rides.map((ride, i) =>
              ride.pickup?.lat && ride.destination?.lat ? (
                <Polyline
                  key={ride.id}
                  positions={[
                    [ride.pickup.lat, ride.pickup.lng],
                    [ride.destination.lat, ride.destination.lng],
                  ]}
                  pathOptions={{
                    color: ROUTE_COLORS[i % ROUTE_COLORS.length],
                    weight: 4,
                    opacity: 0.7,
                    dashArray: '8 6',
                  }}
                />
              ) : null
            )}

            {/* Pickup markers */}
            {rides.map((ride) =>
              ride.pickup?.lat ? (
                <CircleMarker
                  key={`pk-${ride.id}`}
                  center={[ride.pickup.lat, ride.pickup.lng]}
                  radius={8}
                  pathOptions={{ fillColor: '#16A34A', color: '#fff', weight: 2, fillOpacity: 1 }}
                >
                  <Tooltip direction="top" offset={[0, -10]} opacity={0.95}>
                    <span style={{ fontSize: 11 }}>Pickup · {ride.pickup.address}</span>
                  </Tooltip>
                </CircleMarker>
              ) : null
            )}

            {/* Destination markers */}
            {rides.map((ride) =>
              ride.destination?.lat ? (
                <CircleMarker
                  key={`dst-${ride.id}`}
                  center={[ride.destination.lat, ride.destination.lng]}
                  radius={8}
                  pathOptions={{ fillColor: '#DC2626', color: '#fff', weight: 2, fillOpacity: 1 }}
                >
                  <Tooltip direction="top" offset={[0, -10]} opacity={0.95}>
                    <span style={{ fontSize: 11 }}>Drop-off · {ride.destination.address}</span>
                  </Tooltip>
                </CircleMarker>
              ) : null
            )}

            {/* Driver markers */}
            {drivers.filter((d) => d.lat && d.lng).map((d) => (
              <CircleMarker
                key={d.id}
                center={[d.lat, d.lng]}
                radius={11}
                pathOptions={{
                  fillColor: d.status === 'busy' ? '#EA580C' : '#16A34A',
                  color: '#fff',
                  weight: 3,
                  fillOpacity: 1,
                }}
                eventHandlers={{ click: () => setSelected(selected?.id === d.id ? null : d) }}
              >
                <Tooltip direction="top" offset={[0, -14]} opacity={0.97} permanent={selected?.id === d.id}>
                  <div style={{ fontWeight: 600, fontSize: 12 }}>
                    {d.name}
                    <span style={{ marginLeft: 4, color: d.status === 'busy' ? '#EA580C' : '#16A34A', fontSize: 10 }}>
                      ● {d.status === 'busy' ? 'On Ride' : 'Available'}
                    </span>
                  </div>
                </Tooltip>
              </CircleMarker>
            ))}
          </MapContainer>

          {/* Route legend */}
          {rides.length > 0 && (
            <div className="absolute bottom-4 left-4 bg-white/90 backdrop-blur-sm border border-dark-border rounded-xl p-3 space-y-1.5" style={{ zIndex: 1000 }}>
              <p className="text-[10px] uppercase tracking-widest text-slate-500 font-semibold mb-2">Active Routes</p>
              <div className="flex items-center gap-2 text-xs text-slate-500 mb-1">
                <div className="w-4 h-2 rounded-full bg-success" /> Pickup
                <div className="w-4 h-2 rounded-full bg-danger ml-2" /> Drop-off
                <div className="w-4 h-2 rounded-full bg-primary ml-2" /> Driver
              </div>
              {rides.map((ride, i) => (
                <div key={ride.id} className="flex items-center gap-2 text-xs text-slate-600">
                  <div className="w-5 h-1.5 rounded-full" style={{ backgroundColor: ROUTE_COLORS[i % ROUTE_COLORS.length] }} />
                  <span>{ride.id} — {ride.passenger}</span>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Side panel */}
        <div className="w-72 bg-white border-l border-dark-border overflow-y-auto flex flex-col flex-shrink-0">
          <div className="px-4 py-3 border-b border-dark-border">
            <p className="text-[10px] uppercase tracking-widest text-slate-500 font-semibold">Online Drivers</p>
          </div>
          <div className="divide-y divide-dark-border/40 flex-1">
            {drivers.map((d) => (
              <button
                key={d.id}
                onClick={() => setSelected(selected?.id === d.id ? null : d)}
                className={`w-full flex items-center gap-3 px-4 py-3 hover:bg-slate-50 text-left transition-colors ${
                  selected?.id === d.id ? 'bg-primary/5 border-l-2 border-primary' : ''
                }`}
              >
                <div className="relative flex-shrink-0">
                  <Avatar name={d.name} size={36} online={d.status === 'online'} />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-slate-800 truncate">{d.name}</p>
                  <p className="text-xs text-slate-500">{d.rides_today} rides today</p>
                </div>
                <div className="flex flex-col items-end gap-1">
                  <span className={`w-2 h-2 rounded-full ${d.status === 'online' ? 'bg-success' : 'bg-orange'}`} />
                  {d.status === 'online' && <Navigation01Icon size={10} className="text-primary" />}
                </div>
              </button>
            ))}
          </div>

          <div className="border-t border-dark-border px-4 py-3">
            <p className="text-[10px] uppercase tracking-widest text-slate-500 font-semibold mb-3">Active Rides</p>
            <div className="space-y-2">
              {rides.map((r, i) => (
                <div key={r.id} className="bg-slate-50 rounded-xl p-3 border border-dark-border/60">
                  <div className="flex items-center justify-between mb-1.5">
                    <span className="font-mono text-xs text-primary font-semibold">{r.id}</span>
                    <span className="text-[10px] text-success bg-success/10 rounded-full px-1.5 py-0.5 font-bold border border-success/20">ACTIVE</span>
                  </div>
                  <p className="text-xs text-slate-600 mb-2">{r.driver} → {r.passenger}</p>
                  <div className="space-y-1">
                    <div className="flex items-center gap-1.5 text-xs text-slate-500">
                      <div className="w-2 h-2 rounded-full bg-success flex-shrink-0" />
                      <span className="truncate">{r.pickup?.address}</span>
                    </div>
                    <div className="flex items-center gap-1.5 text-xs text-slate-500">
                      <div className="w-2 h-2 rounded-full bg-danger flex-shrink-0" />
                      <span className="truncate">{r.destination?.address}</span>
                    </div>
                  </div>
                  <div className="mt-2 pt-2 border-t border-dark-border/50 flex items-center gap-1.5 text-[10px] text-slate-500">
                    <div className="w-3 h-1 rounded-full" style={{ backgroundColor: ROUTE_COLORS[i % ROUTE_COLORS.length] }} />
                    Route mapped via OpenStreetMap
                  </div>
                </div>
              ))}
              {rides.length === 0 && (
                <div className="text-center py-6 text-slate-500 text-xs">No active rides</div>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
