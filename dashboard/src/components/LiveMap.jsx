import React, { useRef, useCallback } from 'react';
import { GoogleMap, useJsApiLoader, Marker } from '@react-google-maps/api';

const GOMA_CENTER = { lat: -1.6792, lng: 29.2228 };
const LIBRARIES = ['geometry'];

const MAP_STYLE = [
  { elementType: 'geometry',           stylers: [{ color: '#1a2744' }] },
  { elementType: 'labels.icon',        stylers: [{ visibility: 'off' }] },
  { elementType: 'labels.text.fill',   stylers: [{ color: '#8ab4f8' }] },
  { elementType: 'labels.text.stroke', stylers: [{ color: '#1a2744' }] },
  { featureType: 'road',               elementType: 'geometry',         stylers: [{ color: '#304e87' }] },
  { featureType: 'road.highway',       elementType: 'geometry',         stylers: [{ color: '#3f6fbb' }] },
  { featureType: 'water',              elementType: 'geometry',         stylers: [{ color: '#0d1b3e' }] },
  { featureType: 'poi.park',           elementType: 'geometry',         stylers: [{ color: '#1a3320' }] },
  { featureType: 'administrative.locality', elementType: 'labels.text.fill', stylers: [{ color: '#bec8d0' }] },
];

function makeIcon(color, scale = 8) {
  if (!window.google) return null;
  return {
    path: window.google.maps.SymbolPath.CIRCLE,
    fillColor: color,
    fillOpacity: 1,
    strokeColor: '#ffffff',
    strokeWeight: 2,
    scale,
  };
}

export default function LiveMap({ drivers = [], activeRides = [], height = '400px' }) {
  const mapRef = useRef(null);
  const apiKey = import.meta.env.VITE_GOOGLE_MAPS_API_KEY;

  const { isLoaded, loadError } = useJsApiLoader({
    googleMapsApiKey: apiKey || '',
    libraries: LIBRARIES,
  });

  const onMapLoad = useCallback((map) => {
    mapRef.current = map;
    if (drivers.length > 0) {
      const bounds = new window.google.maps.LatLngBounds();
      drivers.filter((d) => d.lat && d.lng).forEach((d) => bounds.extend({ lat: d.lat, lng: d.lng }));
      if (!bounds.isEmpty()) map.fitBounds(bounds, 60);
    }
  }, [drivers]);

  if (!apiKey) {
    return (
      <div
        style={{ height, borderRadius: 16 }}
        className="bg-dark-bg border border-dark-border flex flex-col items-center justify-center gap-2 text-slate-500 text-sm"
      >
        <span className="text-3xl">🗺</span>
        <span>Set VITE_GOOGLE_MAPS_API_KEY to enable map</span>
      </div>
    );
  }

  if (loadError || !isLoaded) {
    return (
      <div style={{ height, borderRadius: 16 }} className="bg-dark-bg border border-dark-border flex items-center justify-center">
        {loadError
          ? <span className="text-danger text-sm">Map failed to load</span>
          : <div className="w-6 h-6 border-2 border-primary border-t-transparent rounded-full animate-spin" />}
      </div>
    );
  }

  return (
    <GoogleMap
      mapContainerStyle={{ height, width: '100%', borderRadius: 16 }}
      center={GOMA_CENTER}
      zoom={13}
      onLoad={onMapLoad}
      options={{
        styles: MAP_STYLE,
        zoomControl: true,
        streetViewControl: false,
        mapTypeControl: false,
        fullscreenControl: false,
        gestureHandling: 'cooperative',
      }}
    >
      {/* Driver dots */}
      {drivers.filter((d) => d.lat && d.lng).map((d) => (
        <Marker
          key={d.id || d._id}
          position={{ lat: d.lat, lng: d.lng }}
          icon={makeIcon('#6366F1', 9)}
          title={d.name || 'Driver'}
        />
      ))}

      {/* Ride pickup markers */}
      {activeRides.map((ride) => (
        <React.Fragment key={ride._id || ride.id}>
          {ride.pickup?.lat && (
            <Marker
              position={{ lat: ride.pickup.lat, lng: ride.pickup.lng }}
              icon={makeIcon('#22C55E', 8)}
              title={`Pickup: ${ride.pickup.address}`}
            />
          )}
          {ride.destination?.lat && (
            <Marker
              position={{ lat: ride.destination.lat, lng: ride.destination.lng }}
              icon={makeIcon('#EF4444', 8)}
              title={`Destination: ${ride.destination.address}`}
            />
          )}
        </React.Fragment>
      ))}
    </GoogleMap>
  );
}
