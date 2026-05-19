import React from 'react';
import { Motorbike01Icon } from 'hugeicons-react';

const STATUS_STYLES = {
  pending:     'badge-pending',
  accepted:    'badge-accepted',
  arriving:    'badge-arriving',
  in_progress: 'badge-in_progress',
  completed:   'badge-completed',
  cancelled:   'badge-cancelled',
};

export default function RideTable({ rides = [], showDriver = true }) {
  const fmt = (date) =>
    date ? new Date(date).toLocaleString('en-US', { dateStyle: 'short', timeStyle: 'short' }) : '—';

  if (rides.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center py-16 text-slate-500 gap-3">
        <Motorbike01Icon size={36} />
        <div className="text-sm">No rides found</div>
      </div>
    );
  }

  return (
    <div className="overflow-x-auto">
      <table className="w-full text-sm">
        <thead>
          <tr className="border-b border-dark-border text-slate-500 text-xs uppercase tracking-wide">
            <th className="text-left py-3 px-4">Passenger</th>
            <th className="text-left py-3 px-4">Pickup</th>
            <th className="text-left py-3 px-4">Destination</th>
            {showDriver && <th className="text-left py-3 px-4">Driver</th>}
            <th className="text-left py-3 px-4">Status</th>
            <th className="text-right py-3 px-4">Fare</th>
            <th className="text-right py-3 px-4">Date</th>
          </tr>
        </thead>
        <tbody>
          {rides.map((ride) => (
            <tr
              key={ride._id}
              className="border-b border-dark-border/50 hover:bg-slate-50 transition-colors"
            >
              <td className="py-3 px-4">
                <div className="font-medium text-slate-800">
                  {ride.passenger
                    ? `${ride.passenger.firstName} ${ride.passenger.lastName}`
                    : '—'}
                </div>
                <div className="text-slate-500 text-xs">{ride.passenger?.phone}</div>
              </td>
              <td className="py-3 px-4">
                <div className="text-slate-600 max-w-[140px] truncate">{ride.pickup?.address?.split(',')[0]}</div>
              </td>
              <td className="py-3 px-4">
                <div className="text-slate-600 max-w-[140px] truncate">{ride.destination?.address?.split(',')[0]}</div>
              </td>
              {showDriver && (
                <td className="py-3 px-4">
                  {ride.driver?.user ? (
                    <div>
                      <div className="font-medium text-slate-800">
                        {ride.driver.user.firstName} {ride.driver.user.lastName}
                      </div>
                      <div className="text-slate-500 text-xs">{ride.driver.vehicle?.plateNumber}</div>
                    </div>
                  ) : (
                    <span className="text-slate-500">Unassigned</span>
                  )}
                </td>
              )}
              <td className="py-3 px-4">
                <span className={`px-2.5 py-1 rounded-full text-xs font-semibold ${STATUS_STYLES[ride.status] || ''}`}>
                  {ride.status?.replace('_', ' ')}
                </span>
              </td>
              <td className="py-3 px-4 text-right font-semibold text-slate-900">
                FC {ride.price?.toLocaleString()}
              </td>
              <td className="py-3 px-4 text-right text-slate-500 text-xs">{fmt(ride.createdAt)}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
