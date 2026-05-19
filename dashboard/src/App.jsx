import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import Sidebar from './components/Sidebar';

import Dashboard from './pages/Dashboard';
import Login from './pages/Login';
import Rides from './pages/Rides';
import Drivers from './pages/Drivers';
import Users from './pages/Users';
import Analytics from './pages/Analytics';
import Reports from './pages/Reports';
import Notifications from './pages/Notifications';
import Settings from './pages/Settings';
import TopRiders from './pages/TopRiders';

// Operations
import Dispatch from './pages/Dispatch';
import SurgePricing from './pages/SurgePricing';
import Zones from './pages/Zones';
import RideInspector from './pages/RideInspector';

// People
import DriverOnboarding from './pages/DriverOnboarding';
import DriverProfile from './pages/DriverProfile';
import UserProfile from './pages/UserProfile';
import Staff from './pages/Staff';

// Finance
import FinanceDashboard from './pages/FinanceDashboard';
import Payouts from './pages/Payouts';
import Transactions from './pages/Transactions';

// Safety
import Incidents from './pages/Incidents';
import RatingsMonitor from './pages/RatingsMonitor';
import SosEmergency from './pages/SosEmergency';

// Growth
import Campaigns from './pages/Campaigns';
import Referrals from './pages/Referrals';
import Promotions from './pages/Promotions';
import AppBanners from './pages/AppBanners';

// Support
import SupportTickets from './pages/SupportTickets';

// System
import FeatureFlags from './pages/FeatureFlags';
import ApiHealth from './pages/ApiHealth';
import AppVersions from './pages/AppVersions';
import AuditLog from './pages/AuditLog';

const PrivateLayout = ({ children, fullscreen = false }) => {
  return (
    <div className="flex h-screen overflow-hidden bg-dark-bg">
      <Sidebar />
      <main className={[
        'flex-1 bg-dark-bg',
        fullscreen ? 'flex flex-col overflow-hidden' : 'overflow-y-auto',
      ].join(' ')}>
        {children}
      </main>
    </div>
  );
};

const PrivateRoute = ({ children, fullscreen = false }) => {
  const token = localStorage.getItem('admin_token');
  return token
    ? <PrivateLayout fullscreen={fullscreen}>{children}</PrivateLayout>
    : <Navigate to="/login" />;
};

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<Login />} />

        {/* Overview */}
        <Route path="/" element={<PrivateRoute><Dashboard /></PrivateRoute>} />
        <Route path="/analytics" element={<PrivateRoute><Analytics /></PrivateRoute>} />
        <Route path="/reports" element={<PrivateRoute><Reports /></PrivateRoute>} />
        <Route path="/top-riders" element={<PrivateRoute><TopRiders /></PrivateRoute>} />

        {/* Operations */}
        <Route path="/rides" element={<PrivateRoute><Rides /></PrivateRoute>} />
        <Route path="/rides/:id" element={<PrivateRoute><RideInspector /></PrivateRoute>} />
        <Route path="/dispatch" element={<PrivateRoute fullscreen><Dispatch /></PrivateRoute>} />
        <Route path="/surge" element={<PrivateRoute><SurgePricing /></PrivateRoute>} />
        <Route path="/zones" element={<PrivateRoute><Zones /></PrivateRoute>} />

        {/* People */}
        <Route path="/drivers" element={<PrivateRoute><Drivers /></PrivateRoute>} />
        <Route path="/drivers/:id" element={<PrivateRoute><DriverProfile /></PrivateRoute>} />
        <Route path="/onboarding" element={<PrivateRoute><DriverOnboarding /></PrivateRoute>} />
        <Route path="/users" element={<PrivateRoute><Users /></PrivateRoute>} />
        <Route path="/users/:id" element={<PrivateRoute><UserProfile /></PrivateRoute>} />
        <Route path="/staff" element={<PrivateRoute><Staff /></PrivateRoute>} />

        {/* Finance */}
        <Route path="/finance" element={<PrivateRoute><FinanceDashboard /></PrivateRoute>} />
        <Route path="/payouts" element={<PrivateRoute><Payouts /></PrivateRoute>} />
        <Route path="/transactions" element={<PrivateRoute><Transactions /></PrivateRoute>} />

        {/* Support */}
        <Route path="/support" element={<PrivateRoute><SupportTickets /></PrivateRoute>} />

        {/* Safety */}
        <Route path="/incidents" element={<PrivateRoute><Incidents /></PrivateRoute>} />
        <Route path="/ratings" element={<PrivateRoute><RatingsMonitor /></PrivateRoute>} />
        <Route path="/sos" element={<PrivateRoute><SosEmergency /></PrivateRoute>} />

        {/* Growth */}
        <Route path="/campaigns" element={<PrivateRoute><Campaigns /></PrivateRoute>} />
        <Route path="/referrals" element={<PrivateRoute><Referrals /></PrivateRoute>} />
        <Route path="/promotions" element={<PrivateRoute><Promotions /></PrivateRoute>} />
        <Route path="/banners" element={<PrivateRoute><AppBanners /></PrivateRoute>} />

        {/* System */}
        <Route path="/notifications" element={<PrivateRoute><Notifications /></PrivateRoute>} />
        <Route path="/features" element={<PrivateRoute><FeatureFlags /></PrivateRoute>} />
        <Route path="/health" element={<PrivateRoute><ApiHealth /></PrivateRoute>} />
        <Route path="/versions" element={<PrivateRoute><AppVersions /></PrivateRoute>} />
        <Route path="/audit" element={<PrivateRoute><AuditLog /></PrivateRoute>} />
        <Route path="/settings" element={<PrivateRoute><Settings /></PrivateRoute>} />

        <Route path="*" element={<Navigate to="/" />} />
      </Routes>
    </BrowserRouter>
  );
}
