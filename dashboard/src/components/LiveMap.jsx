import React, { useEffect, useRef } from 'react';
import { MapContainer, TileLayer, Marker, Popup, Polyline, useMap } from 'react-leaflet';
import L from 'leaflet';

// Fix default icon issue with webpack
delete L.Icon.Default.prototype._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png',
  iconUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png',
  shadowUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
});

const driverIcon = L.divIcon({
  className: '',
  html: `<div style="width:32px;height:32px;background:#2F80ED;border-radius:50%;border:3px solid white;display:flex;align-items:center;justify-content:center;box-shadow:0 2px 8px rgba(47,128,237,0.5)">
    <span style="font-size:16px">🛵</span>
  </div>`,
  iconSize: [32, 32],
  iconAnchor: [16, 16],
});

const pickupIcon = L.divIcon({
  className: '',
  html: `<div style="width:28px;height:28px;background:#27AE60;border-radius:50%;border:3px solid white;display:flex;align-items:center;justify-content:center;box-shadow:0 2px 6px rgba(39,174,96,0.5)">
    <span style="font-size:14px">📍</span>
  </div>`,
  iconSize: [28, 28],
  iconAnchor: [14, 14],
});

const destIcon = L.divIcon({
  className: '',
  html: `<div style="width:28px;height:28px;background:#EB5757;border-radius:50%;border:3px solid white;display:flex;align-items:center;justify-content:center;box-shadow:0 2px 6px rgba(235,87,87,0.5)">
    <span style="font-size:14px">🏁</span>
  </div>`,
  iconSize: [28, 28],
  iconAnchor: [14, 14],
});

function FitBounds({ drivers }) {
  const map = useMap();
  useEffect(() => {
    if (drivers && drivers.length > 0) {
      const coords = drivers
        .filter((d) => d.lat && d.lng)
        .map((d) => [d.lat, d.lng]);
      if (coords.length > 0) {
        map.fitBounds(coords, { padding: [50, 50] });
      }
    }
  }, [drivers, map]);
  return null;
}

export default function LiveMap({ drivers = [], activeRides = [], height = '400px' }) {
  const center = [-1.6792, 29.2228]; // Goma, DRC

  return (
    <MapContainer
      center={center}
      zoom={13}
      style={{ height, width: '100%', borderRadius: '16px' }}
      className="z-0"
    >
      <TileLayer
        url="https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png"
        attribution='&copy; <a href="https://carto.com">CARTO</a>'
        subdomains="abcd"
      />

      {/* Online drivers */}
      {drivers
        .filter((d) => d.lat && d.lng)
        .map((driver) => (
          <Marker
            key={driver.id || driver._id}
            position={[driver.lat, driver.lng]}
            icon={driverIcon}
          >
            <Popup>
              <div className="text-sm font-semibold">
                {driver.name || 'Driver'}
                <br />
                <span className="text-green-600 font-bold">● Online</span>
              </div>
            </Popup>
          </Marker>
        ))}

      {/* Active rides - pickup & destination */}
      {activeRides.map((ride) => (
        <React.Fragment key={ride._id}>
          {ride.pickup?.lat && (
            <Marker position={[ride.pickup.lat, ride.pickup.lng]} icon={pickupIcon}>
              <Popup>
                <div className="text-xs">
                  <strong>Pickup</strong><br />{ride.pickup.address}
                </div>
              </Popup>
            </Marker>
          )}
          {ride.destination?.lat && (
            <Marker position={[ride.destination.lat, ride.destination.lng]} icon={destIcon}>
              <Popup>
                <div className="text-xs">
                  <strong>Destination</strong><br />{ride.destination.address}
                </div>
              </Popup>
            </Marker>
          )}
          {ride.pickup?.lat && ride.destination?.lat && (
            <Polyline
              positions={[
                [ride.pickup.lat, ride.pickup.lng],
                [ride.destination.lat, ride.destination.lng],
              ]}
              pathOptions={{ color: '#2F80ED', weight: 2, dashArray: '6 4' }}
            />
          )}
        </React.Fragment>
      ))}

      {drivers.length > 0 && <FitBounds drivers={drivers} />}
    </MapContainer>
  );
}
