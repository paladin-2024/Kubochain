import React, { useEffect } from 'react';
import { MapContainer, TileLayer, CircleMarker, Tooltip, useMap } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';

const GOMA_CENTER = [-1.6792, 29.2228];

function FitBounds({ drivers }) {
  const map = useMap();
  useEffect(() => {
    const pts = drivers.filter((d) => d.lat && d.lng).map((d) => [d.lat, d.lng]);
    if (pts.length > 0) {
      try { map.fitBounds(pts, { padding: [40, 40], maxZoom: 15 }); } catch {}
    }
  }, [drivers, map]);
  return null;
}

export default function LiveMap({ drivers = [], activeRides = [], height = '400px' }) {
  return (
    <div style={{ height, borderRadius: 16, overflow: 'hidden', position: 'relative', zIndex: 0 }}>
      <MapContainer
        center={GOMA_CENTER}
        zoom={13}
        style={{ height: '100%', width: '100%' }}
        zoomControl
        scrollWheelZoom
        attributionControl={false}
      >
        <TileLayer
          url="https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png"
          attribution='&copy; <a href="https://carto.com/">CARTO</a>'
        />

        <FitBounds drivers={drivers} />

        {/* Driver dots */}
        {drivers.filter((d) => d.lat && d.lng).map((d) => (
          <CircleMarker
            key={d.id || d._id}
            center={[d.lat, d.lng]}
            radius={9}
            pathOptions={{ fillColor: '#2563EB', color: '#fff', weight: 2, fillOpacity: 1 }}
          >
            <Tooltip direction="top" offset={[0, -10]} opacity={0.95}>
              <span style={{ fontSize: 12, fontWeight: 600 }}>{d.name || 'Driver'}</span>
            </Tooltip>
          </CircleMarker>
        ))}

        {/* Ride pickup markers */}
        {activeRides.map((ride) => (
          <React.Fragment key={ride._id || ride.id}>
            {ride.pickup?.lat && (
              <CircleMarker
                center={[ride.pickup.lat, ride.pickup.lng]}
                radius={7}
                pathOptions={{ fillColor: '#16A34A', color: '#fff', weight: 2, fillOpacity: 1 }}
              >
                <Tooltip direction="top" offset={[0, -8]} opacity={0.95}>
                  <span style={{ fontSize: 11 }}>Pickup: {ride.pickup.address}</span>
                </Tooltip>
              </CircleMarker>
            )}
            {ride.destination?.lat && (
              <CircleMarker
                center={[ride.destination.lat, ride.destination.lng]}
                radius={7}
                pathOptions={{ fillColor: '#DC2626', color: '#fff', weight: 2, fillOpacity: 1 }}
              >
                <Tooltip direction="top" offset={[0, -8]} opacity={0.95}>
                  <span style={{ fontSize: 11 }}>Drop-off: {ride.destination.address}</span>
                </Tooltip>
              </CircleMarker>
            )}
          </React.Fragment>
        ))}
      </MapContainer>
    </div>
  );
}
