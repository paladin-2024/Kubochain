import React, { useState, useEffect, useRef, useCallback } from 'react';
import {
  GoogleMap, useJsApiLoader, Marker, DirectionsRenderer, InfoWindow,
} from '@react-google-maps/api';
import {
  Motorbike01Icon, MapPinpoint01Icon, MapsIcon, Activity01Icon,
  Refresh01Icon, Navigation01Icon,
} from 'hugeicons-react';
import api from '../config/api';

const GOMA_CENTER = { lat: -1.6792, lng: 29.2228 };
const LIBRARIES = ['places', 'geometry'];

// ─── Google Maps dark style ───────────────────────────────────────────────────
const MAP_DARK_STYLE = [
  { elementType: 'geometry',           stylers: [{ color: '#1a2744' }] },
  { elementType: 'labels.icon',        stylers: [{ visibility: 'off' }] },
  { elementType: 'labels.text.fill',   stylers: [{ color: '#8ab4f8' }] },
  { elementType: 'labels.text.stroke', stylers: [{ color: '#1a2744' }] },
  { featureType: 'administrative',        elementType: 'geometry',         stylers: [{ color: '#243b6b' }] },
  { featureType: 'administrative.locality', elementType: 'labels.text.fill', stylers: [{ color: '#bec8d0' }] },
  { featureType: 'poi',                    elementType: 'labels.text.fill', stylers: [{ color: '#6e8cb3' }] },
  { featureType: 'poi.park',               elementType: 'geometry',         stylers: [{ color: '#1a3320' }] },
  { featureType: 'road',                   elementType: 'geometry',         stylers: [{ color: '#304e87' }] },
  { featureType: 'road',                   elementType: 'geometry.stroke',  stylers: [{ color: '#1a2f55' }] },
  { featureType: 'road.arterial',          elementType: 'labels.text.fill', stylers: [{ color: '#6e98c4' }] },
  { featureType: 'road.highway',           elementType: 'geometry',         stylers: [{ color: '#3f6fbb' }] },
  { featureType: 'road.highway',           elementType: 'geometry.stroke',  stylers: [{ color: '#1f3a6e' }] },
  { featureType: 'road.highway',           elementType: 'labels.text.fill', stylers: [{ color: '#f3d19c' }] },
  { featureType: 'transit',               elementType: 'geometry',          stylers: [{ color: '#2f3948' }] },
  { featureType: 'water',                 elementType: 'geometry',          stylers: [{ color: '#0d1b3e' }] },
  { featureType: 'water',                 elementType: 'labels.text.fill',  stylers: [{ color: '#4e6d8c' }] },
];

// ─── Mock data (used until backend is connected) ──────────────────────────────
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

// ─── Route colors per ride ────────────────────────────────────────────────────
const ROUTE_COLORS = ['#6366F1', '#22C55E', '#F97316', '#EAB308', '#EF4444'];

// ─── SVG icon factory (called after Maps API is loaded) ───────────────────────
function makeDriverIcon(status) {
  const fill = status === 'busy' ? '#F97316' : '#22C55E';
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="38" height="38" viewBox="0 0 38 38">
    <circle cx="19" cy="19" r="17" fill="${fill}" stroke="white" stroke-width="3"/>
    <g transform="translate(7,10)" fill="white" stroke="white" stroke-width="0.3">
      <circle cx="5.5" cy="13.5" r="2.5" fill="white"/>
      <circle cx="18.5" cy="13.5" r="2.5" fill="white"/>
      <path d="M15 2h-2l-3 6H5" fill="none" stroke="white" stroke-width="1.8" stroke-linecap="round"/>
      <path d="M13 2l5 5-4 4" fill="none" stroke="white" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>
    </g>
  </svg>`;
  return {
    url: 'data:image/svg+xml;charset=UTF-8,' + encodeURIComponent(svg),
    scaledSize: new window.google.maps.Size(38, 38),
    anchor: new window.google.maps.Point(19, 19),
  };
}

function makePickupIcon() {
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="30" height="30" viewBox="0 0 30 30">
    <circle cx="15" cy="15" r="13" fill="#22C55E" stroke="white" stroke-width="2.5"/>
    <circle cx="15" cy="11" r="3.5" fill="white"/>
    <path d="M15 4C10.6 4 7 7.6 7 12c0 6.6 8 15 8 15s8-8.4 8-15c0-4.4-3.6-8-8-8z" fill="white" opacity="0.25"/>
  </svg>`;
  return {
    url: 'data:image/svg+xml;charset=UTF-8,' + encodeURIComponent(svg),
    scaledSize: new window.google.maps.Size(30, 30),
    anchor: new window.google.maps.Point(15, 15),
  };
}

function makeDestIcon() {
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="30" height="30" viewBox="0 0 30 30">
    <circle cx="15" cy="15" r="13" fill="#EF4444" stroke="white" stroke-width="2.5"/>
    <path d="M8 15h14M15 8l7 7-7 7" fill="none" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
  </svg>`;
  return {
    url: 'data:image/svg+xml;charset=UTF-8,' + encodeURIComponent(svg),
    scaledSize: new window.google.maps.Size(30, 30),
    anchor: new window.google.maps.Point(15, 15),
  };
}

// ─── Main component ───────────────────────────────────────────────────────────
export default function Dispatch() {
  const [drivers, setDrivers] = useState(MOCK_DRIVERS);
  const [rides, setRides] = useState(MOCK_ACTIVE_RIDES);
  const [selected, setSelected] = useState(null);
  const [infoDriver, setInfoDriver] = useState(null);
  const [directions, setDirections] = useState({});
  const [fetching, setFetching] = useState(false);
  const mapRef = useRef(null);
  const wsRef = useRef(null);

  const apiKey = import.meta.env.VITE_GOOGLE_MAPS_API_KEY;

  const { isLoaded, loadError } = useJsApiLoader({
    googleMapsApiKey: apiKey || '',
    libraries: LIBRARIES,
  });

  const onMapLoad = useCallback((map) => { mapRef.current = map; }, []);

  // ── Road-following route algorithm ─────────────────────────────────────────
  const fetchRoadRoutes = useCallback(() => {
    if (!isLoaded || !window.google || !rides.length) return;
    const svc = new window.google.maps.DirectionsService();

    rides.forEach((ride, idx) => {
      if (!ride.pickup?.lat || !ride.destination?.lat) return;
      svc.route(
        {
          origin:      { lat: ride.pickup.lat,      lng: ride.pickup.lng },
          destination: { lat: ride.destination.lat, lng: ride.destination.lng },
          travelMode:  window.google.maps.TravelMode.DRIVING,
          optimizeWaypoints: true,
        },
        (result, status) => {
          if (status === 'OK') {
            setDirections((prev) => ({ ...prev, [ride.id]: { result, color: ROUTE_COLORS[idx % ROUTE_COLORS.length] } }));
          }
        }
      );
    });
  }, [isLoaded, rides]);

  useEffect(() => { fetchRoadRoutes(); }, [fetchRoadRoutes]);

  // ── Backend + WebSocket ────────────────────────────────────────────────────
  useEffect(() => {
    setFetching(true);
    Promise.all([
      api.get('/admin/drivers/online').catch(() => ({ data: null })),
      api.get('/admin/rides/active').catch(() => ({ data: null })),
    ]).then(([dRes, rRes]) => {
      if (dRes.data?.length) setDrivers(dRes.data);
      if (rRes.data?.length) setRides(rRes.data);
    }).finally(() => setFetching(false));

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
  }, []);

  const focusDriver = (d) => {
    setSelected(selected?.id === d.id ? null : d);
    if (mapRef.current && d.lat && d.lng) {
      mapRef.current.panTo({ lat: d.lat, lng: d.lng });
      mapRef.current.setZoom(16);
    }
  };

  const onlineCount = drivers.filter((d) => d.status === 'online').length;
  const busyCount   = drivers.filter((d) => d.status === 'busy').length;

  // ── No API key placeholder ─────────────────────────────────────────────────
  if (!apiKey) {
    return (
      <div className="flex flex-col h-full items-center justify-center gap-5 text-slate-500 p-8">
        <div className="w-20 h-20 rounded-2xl bg-dark-card border border-dark-border flex items-center justify-center">
          <MapsIcon size={36} className="text-primary" />
        </div>
        <div className="text-center">
          <p className="font-heading font-bold text-slate-900 text-xl mb-2">Google Maps API Key Required</p>
          <p className="text-sm text-slate-500 max-w-sm">
            Add <code className="text-primary bg-primary/10 px-1.5 py-0.5 rounded">VITE_GOOGLE_MAPS_API_KEY=your_key</code> to{' '}
            <code className="text-slate-600">dashboard/.env.local</code> and restart the dev server.
          </p>
        </div>
        <a
          href="https://console.cloud.google.com/google/maps-apis"
          target="_blank"
          rel="noreferrer"
          className="px-5 py-2.5 bg-primary text-white rounded-xl text-sm font-semibold hover:bg-primary-dark transition-colors"
        >
          Get API Key
        </a>
      </div>
    );
  }

  if (loadError) {
    return (
      <div className="flex items-center justify-center h-full text-danger">
        Failed to load Google Maps: {loadError.message}
      </div>
    );
  }

  if (!isLoaded) {
    return (
      <div className="flex flex-col h-full items-center justify-center gap-3">
        <div className="w-8 h-8 border-2 border-primary border-t-transparent rounded-full animate-spin" />
        <span className="text-slate-500 text-sm">Loading Google Maps…</span>
      </div>
    );
  }

  return (
    <div className="flex flex-col h-full">
      {/* ── Top bar ─────────────────────────────────────────────────────────── */}
      <div className="flex items-center gap-4 px-4 py-3 bg-dark-card border-b border-dark-border flex-wrap">
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
            onClick={() => { setDirections({}); fetchRoadRoutes(); }}
            className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-dark-bg border border-dark-border text-slate-500 hover:text-slate-800 text-xs transition-colors"
          >
            <Refresh01Icon size={12} className={fetching ? 'animate-spin' : ''} />
            Refresh routes
          </button>
        </div>
      </div>

      <div className="flex flex-1 overflow-hidden">
        {/* ── Map ─────────────────────────────────────────────────────────── */}
        <div className="flex-1 relative">
          <GoogleMap
            mapContainerStyle={{ height: '100%', width: '100%' }}
            center={GOMA_CENTER}
            zoom={14}
            onLoad={onMapLoad}
            options={{
              styles: MAP_DARK_STYLE,
              zoomControl: true,
              streetViewControl: false,
              mapTypeControl: false,
              fullscreenControl: true,
              gestureHandling: 'greedy',
            }}
          >
            {/* ── Road-following routes (Directions API) ───────────────── */}
            {Object.values(directions).map(({ result, color }, i) => (
              <DirectionsRenderer
                key={i}
                directions={result}
                options={{
                  suppressMarkers: true,
                  polylineOptions: {
                    strokeColor: color,
                    strokeWeight: 5,
                    strokeOpacity: 0.85,
                  },
                }}
              />
            ))}

            {/* ── Ride pickup & destination markers ───────────────────── */}
            {rides.map((ride) => (
              <React.Fragment key={ride.id}>
                {ride.pickup?.lat && (
                  <Marker
                    position={{ lat: ride.pickup.lat, lng: ride.pickup.lng }}
                    icon={makePickupIcon()}
                    title={`Pickup: ${ride.pickup.address}`}
                  />
                )}
                {ride.destination?.lat && (
                  <Marker
                    position={{ lat: ride.destination.lat, lng: ride.destination.lng }}
                    icon={makeDestIcon()}
                    title={`Destination: ${ride.destination.address}`}
                  />
                )}
              </React.Fragment>
            ))}

            {/* ── Driver markers ──────────────────────────────────────── */}
            {drivers.map((d) => (
              d.lat && d.lng ? (
                <Marker
                  key={d.id}
                  position={{ lat: d.lat, lng: d.lng }}
                  icon={makeDriverIcon(d.status)}
                  onClick={() => { setInfoDriver(d); focusDriver(d); }}
                  title={d.name}
                />
              ) : null
            ))}

            {/* ── Info window for selected driver ─────────────────────── */}
            {infoDriver && infoDriver.lat && infoDriver.lng && (
              <InfoWindow
                position={{ lat: infoDriver.lat, lng: infoDriver.lng }}
                onCloseClick={() => setInfoDriver(null)}
                options={{ pixelOffset: new window.google.maps.Size(0, -22) }}
              >
                <div style={{ fontFamily: 'DM Sans, sans-serif', minWidth: 140 }}>
                  <p style={{ fontWeight: 700, marginBottom: 4, color: '#0F172A' }}>{infoDriver.name}</p>
                  <p style={{ fontSize: 12, color: infoDriver.status === 'busy' ? '#F97316' : '#22C55E', fontWeight: 600 }}>
                    ● {infoDriver.status === 'busy' ? 'On Ride' : 'Available'}
                  </p>
                  <p style={{ fontSize: 11, color: '#64748B', marginTop: 4 }}>
                    {infoDriver.rides_today} rides today
                  </p>
                </div>
              </InfoWindow>
            )}
          </GoogleMap>

          {/* Route legend overlay */}
          {Object.keys(directions).length > 0 && (
            <div className="absolute bottom-4 left-4 bg-dark-card/90 backdrop-blur-sm border border-dark-border rounded-xl p-3 space-y-1.5">
              <p className="text-[10px] uppercase tracking-widest text-slate-500 font-semibold mb-2">Active Routes</p>
              {rides.map((ride, i) => (
                <div key={ride.id} className="flex items-center gap-2 text-xs text-slate-600">
                  <div className="w-5 h-1.5 rounded-full" style={{ backgroundColor: ROUTE_COLORS[i % ROUTE_COLORS.length] }} />
                  <span>{ride.id} — {ride.passenger}</span>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* ── Side panel ──────────────────────────────────────────────────── */}
        <div className="w-72 bg-dark-card border-l border-dark-border overflow-y-auto flex flex-col">
          {/* Drivers list */}
          <div className="px-4 py-3 border-b border-dark-border">
            <p className="text-[10px] uppercase tracking-widest text-slate-500 font-semibold">Online Drivers</p>
          </div>
          <div className="divide-y divide-dark-border/40 flex-1">
            {drivers.map((d) => (
              <button
                key={d.id}
                onClick={() => focusDriver(d)}
                className={`w-full flex items-center gap-3 px-4 py-3 hover:bg-slate-50 text-left transition-colors ${selected?.id === d.id ? 'bg-primary/8 border-l-2 border-primary' : ''}`}
              >
                <div className={`w-9 h-9 rounded-full border-2 flex items-center justify-center flex-shrink-0 ${
                  d.status === 'online' ? 'border-success bg-success/15' : 'border-orange bg-orange/15'
                }`}>
                  <Motorbike01Icon size={14} className={d.status === 'online' ? 'text-success' : 'text-orange'} />
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

          {/* Active rides */}
          <div className="border-t border-dark-border px-4 py-3">
            <p className="text-[10px] uppercase tracking-widest text-slate-500 font-semibold mb-3">Active Rides</p>
            <div className="space-y-2">
              {rides.map((r, i) => (
                <div key={r.id} className="bg-dark-bg rounded-xl p-3 border border-dark-border/60">
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
                  {directions[r.id] && (
                    <div className="mt-2 pt-2 border-t border-dark-border/50">
                      <div className="flex items-center gap-1.5 text-[10px] text-slate-500">
                        <div className="w-3 h-1 rounded-full" style={{ backgroundColor: ROUTE_COLORS[i % ROUTE_COLORS.length] }} />
                        <span>Route mapped via Google Maps</span>
                      </div>
                    </div>
                  )}
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
