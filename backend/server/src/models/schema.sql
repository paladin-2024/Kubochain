-- KuboChain Database Schema
-- Run this in Neon SQL Editor: https://console.neon.tech

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =====================
-- USERS
-- =====================
CREATE TABLE IF NOT EXISTS users (
  id            UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  first_name    VARCHAR(100) NOT NULL,
  last_name     VARCHAR(100) NOT NULL,
  email         VARCHAR(255) NOT NULL UNIQUE,
  phone         VARCHAR(30)  NOT NULL,
  password      VARCHAR(255) NOT NULL,
  role          VARCHAR(20)  NOT NULL DEFAULT 'passenger'
                  CHECK (role IN ('passenger', 'rider', 'admin')),
  profile_image TEXT,
  rating        DECIMAL(3,2) DEFAULT 5.00,
  total_rides   INTEGER      DEFAULT 0,
  is_active     BOOLEAN      DEFAULT true,
  fcm_token     TEXT,
  created_at    TIMESTAMPTZ  DEFAULT NOW(),
  updated_at    TIMESTAMPTZ  DEFAULT NOW()
);

-- =====================
-- DRIVERS
-- =====================
CREATE TABLE IF NOT EXISTS drivers (
  id                   UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id              UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  vehicle_make         VARCHAR(100) DEFAULT 'Unknown',
  vehicle_model        VARCHAR(100) DEFAULT 'Unknown',
  vehicle_color        VARCHAR(50)  DEFAULT 'Black',
  vehicle_plate        VARCHAR(20)  DEFAULT '' UNIQUE,
  vehicle_type         VARCHAR(20)  DEFAULT 'motorcycle'
                         CHECK (vehicle_type IN ('motorcycle','car')),
  license              VARCHAR(100),
  is_verified          BOOLEAN      DEFAULT false,
  is_online            BOOLEAN      DEFAULT false,
  lat                  DECIMAL(10,8),
  lng                  DECIMAL(11,8),
  rating               DECIMAL(3,2) DEFAULT 5.00,
  total_rides          INTEGER      DEFAULT 0,
  total_earnings       DECIMAL(12,2) DEFAULT 0,
  today_earnings       DECIMAL(12,2) DEFAULT 0,
  last_earnings_reset  DATE         DEFAULT CURRENT_DATE,
  created_at           TIMESTAMPTZ  DEFAULT NOW()
);

-- =====================
-- RIDES
-- =====================
CREATE TABLE IF NOT EXISTS rides (
  id                  UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  passenger_id        UUID        REFERENCES users(id),
  driver_id           UUID        REFERENCES drivers(id),
  pickup_address      TEXT        NOT NULL,
  pickup_lat          DECIMAL(10,8) NOT NULL,
  pickup_lng          DECIMAL(11,8) NOT NULL,
  destination_address TEXT        NOT NULL,
  destination_lat     DECIMAL(10,8) NOT NULL,
  destination_lng     DECIMAL(11,8) NOT NULL,
  status              VARCHAR(20) NOT NULL DEFAULT 'pending'
                        CHECK (status IN ('pending','accepted','arriving','in_progress','awaiting_confirmation','completed','cancelled')),
  price               DECIMAL(10,2) NOT NULL,
  distance            DECIMAL(8,3)  NOT NULL,
  estimated_minutes   INTEGER,
  ride_type           VARCHAR(20)  DEFAULT 'economy'
                        CHECK (ride_type IN ('economy','premium')),
  cancel_reason       TEXT,
  cancelled_by        VARCHAR(20),
  rating              INTEGER      CHECK (rating BETWEEN 1 AND 5),
  rating_comment      TEXT,
  accepted_at         TIMESTAMPTZ,
  arrived_at          TIMESTAMPTZ,
  started_at          TIMESTAMPTZ,
  completed_at        TIMESTAMPTZ,
  driver_completed_at     TIMESTAMPTZ,
  passenger_confirmed_at  TIMESTAMPTZ,
  created_at          TIMESTAMPTZ  DEFAULT NOW()
);

-- =====================
-- MESSAGES
-- =====================
CREATE TABLE IF NOT EXISTS messages (
  id          UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  ride_id     UUID        REFERENCES rides(id) ON DELETE CASCADE,
  sender_id   UUID        REFERENCES users(id),
  receiver_id UUID        REFERENCES users(id),
  content     TEXT        NOT NULL,
  is_read     BOOLEAN     DEFAULT false,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_messages_ride     ON messages(ride_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender   ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_receiver ON messages(receiver_id);

-- =====================
-- OTP CODES
-- =====================
CREATE TABLE IF NOT EXISTS otp_codes (
  id         UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  phone      VARCHAR(30) NOT NULL,
  code       VARCHAR(6)  NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  used       BOOLEAN     DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_otp_phone ON otp_codes(phone);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_rides_passenger    ON rides(passenger_id);
CREATE INDEX IF NOT EXISTS idx_rides_driver       ON rides(driver_id);
CREATE INDEX IF NOT EXISTS idx_rides_status       ON rides(status);
CREATE INDEX IF NOT EXISTS idx_rides_created      ON rides(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_drivers_user       ON drivers(user_id);
CREATE INDEX IF NOT EXISTS idx_drivers_online     ON drivers(is_online);
CREATE INDEX IF NOT EXISTS idx_drivers_location   ON drivers(lat, lng);
