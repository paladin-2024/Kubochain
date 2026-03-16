// Shape DB rows into the JSON the Flutter app expects

function formatUser(row) {
  if (!row) return null;
  return {
    _id: row.id,
    firstName: row.first_name,
    lastName: row.last_name,
    email: row.email,
    phone: row.phone,
    role: row.role,
    profileImage: row.profile_image,
    rating: parseFloat(row.rating),
    totalRides: row.total_rides,
    isActive: row.is_active,
    isVerified: true,
    createdAt: row.created_at,
  };
}

function formatDriver(row) {
  if (!row) return null;
  return {
    _id: row.id,
    userId: row.user_id,
    user: row.user_first_name ? {
      _id: row.user_id,
      firstName: row.user_first_name,
      lastName: row.user_last_name,
      phone: row.user_phone,
      rating: parseFloat(row.user_rating),
      profileImage: row.user_profile_image,
    } : null,
    vehicle: {
      make: row.vehicle_make,
      model: row.vehicle_model,
      color: row.vehicle_color,
      plateNumber: row.vehicle_plate,
      type: row.vehicle_type,
    },
    isVerified: row.is_verified,
    isOnline: row.is_online,
    lat: row.lat ? parseFloat(row.lat) : null,
    lng: row.lng ? parseFloat(row.lng) : null,
    rating: parseFloat(row.rating),
    totalRides: row.total_rides,
    totalEarnings: parseFloat(row.total_earnings),
    todayEarnings: parseFloat(row.today_earnings),
    createdAt: row.created_at,
  };
}

function formatRide(row) {
  if (!row) return null;
  return {
    _id: row.id,
    passenger: row.passenger_first_name ? {
      _id: row.passenger_id,
      firstName: row.passenger_first_name,
      lastName: row.passenger_last_name,
      phone: row.passenger_phone,
      rating: parseFloat(row.passenger_rating),
      profileImage: row.passenger_profile_image,
    } : null,
    driver: row.driver_id ? {
      _id: row.driver_id,
      user: row.driver_first_name ? {
        _id: row.driver_user_id,
        firstName: row.driver_first_name,
        lastName: row.driver_last_name,
        phone: row.driver_phone,
        rating: parseFloat(row.driver_rating || 5),
        profileImage: row.driver_profile_image,
      } : null,
      vehicle: {
        make: row.vehicle_make,
        model: row.vehicle_model,
        color: row.vehicle_color,
        plateNumber: row.vehicle_plate,
        type: row.vehicle_type,
      },
    } : null,
    pickup: {
      address: row.pickup_address,
      lat: parseFloat(row.pickup_lat),
      lng: parseFloat(row.pickup_lng),
    },
    destination: {
      address: row.destination_address,
      lat: parseFloat(row.destination_lat),
      lng: parseFloat(row.destination_lng),
    },
    status: row.status,
    price: parseFloat(row.price),
    distance: parseFloat(row.distance),
    estimatedMinutes: row.estimated_minutes,
    rideType: row.ride_type,
    cancelReason: row.cancel_reason,
    rating: row.rating,
    ratingComment: row.rating_comment,
    createdAt: row.created_at,
    acceptedAt: row.accepted_at,
    arrivedAt: row.arrived_at,
    startedAt: row.started_at,
    completedAt: row.completed_at,
  };
}

module.exports = { formatUser, formatDriver, formatRide };
