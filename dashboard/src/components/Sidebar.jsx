import React, { useState, useMemo } from 'react';
import { NavLink, useNavigate } from 'react-router-dom';
import {
  DashboardSquare01Icon, ChartLineData01Icon, FileDownloadIcon, Award01Icon,
  Motorbike01Icon, UserCheck01Icon, UserGroupIcon, MapsIcon, Notification01Icon,
  Settings01Icon, LogoutSquare01Icon, ArrowLeft01Icon, ArrowRight01Icon,
  UserAdd01Icon, Wallet01Icon, Invoice01Icon, Coins01Icon, AlertDiamondIcon,
  StarCircleIcon, DangerIcon, Megaphone01Icon, GiftIcon, Image01Icon,
  ToggleOnIcon, CloudServerIcon, SmartPhone01Icon, FlashIcon, Route01Icon,
  Audit01Icon, UserEdit01Icon, BankIcon, PromotionIcon, Shield01Icon, CustomerSupportIcon,
  PencilEdit01Icon,
} from 'hugeicons-react';
import { cn } from '../lib/utils';
import Avatar from './Avatar';
import AvatarPicker from './AvatarPicker';

const NAV_GROUPS = [
  {
    label: 'Overview',
    items: [
      { path: '/', icon: DashboardSquare01Icon, label: 'Dashboard', exact: true },
      { path: '/analytics', icon: ChartLineData01Icon, label: 'Analytics' },
      { path: '/reports', icon: FileDownloadIcon, label: 'Reports' },
      { path: '/top-riders', icon: Award01Icon, label: 'Top Riders' },
    ],
  },
  {
    label: 'Operations',
    items: [
      { path: '/rides', icon: Motorbike01Icon, label: 'Rides' },
      { path: '/dispatch', icon: MapsIcon, label: 'Dispatch Map' },
      { path: '/surge', icon: FlashIcon, label: 'Surge Pricing' },
      { path: '/zones', icon: Route01Icon, label: 'Zones' },
    ],
  },
  {
    label: 'People',
    items: [
      { path: '/drivers', icon: UserCheck01Icon, label: 'Drivers' },
      { path: '/onboarding', icon: UserAdd01Icon, label: 'Onboarding Queue' },
      { path: '/users', icon: UserGroupIcon, label: 'Users' },
      { path: '/staff', icon: UserEdit01Icon, label: 'Admin Staff' },
      { path: '/support', icon: CustomerSupportIcon, label: 'Support Tickets' },
    ],
  },
  {
    label: 'Finance',
    items: [
      { path: '/finance', icon: Wallet01Icon, label: 'Finance Dashboard' },
      { path: '/payouts', icon: BankIcon, label: 'Payouts' },
      { path: '/transactions', icon: Invoice01Icon, label: 'Transactions' },
    ],
  },
  {
    label: 'Safety',
    items: [
      { path: '/incidents', icon: AlertDiamondIcon, label: 'Incidents' },
      { path: '/ratings', icon: StarCircleIcon, label: 'Ratings Monitor' },
      { path: '/sos', icon: DangerIcon, label: 'SOS Emergency' },
    ],
  },
  {
    label: 'Growth',
    items: [
      { path: '/campaigns', icon: Megaphone01Icon, label: 'Campaigns' },
      { path: '/referrals', icon: GiftIcon, label: 'Referrals' },
      { path: '/promotions', icon: PromotionIcon, label: 'Promotions' },
      { path: '/banners', icon: Image01Icon, label: 'App Banners' },
    ],
  },
  {
    label: 'System',
    items: [
      { path: '/notifications', icon: Notification01Icon, label: 'Notifications' },
      { path: '/features', icon: ToggleOnIcon, label: 'Feature Flags' },
      { path: '/health', icon: CloudServerIcon, label: 'API Health' },
      { path: '/versions', icon: SmartPhone01Icon, label: 'App Versions' },
      { path: '/audit', icon: Audit01Icon, label: 'Audit Log' },
      { path: '/settings', icon: Settings01Icon, label: 'Settings' },
    ],
  },
];

export default function Sidebar() {
  const navigate = useNavigate();
  const [collapsed, setCollapsed] = useState(false);
  const [showPicker, setShowPicker] = useState(false);
  const [avatarSeed, setAvatarSeed] = useState(() => localStorage.getItem('admin_avatar_seed') || null);

  const adminUser = useMemo(() => {
    try { return JSON.parse(localStorage.getItem('admin_user') || '{}'); } catch { return {}; }
  }, []);

  const handleAvatarSelect = (seed) => {
    if (seed) {
      localStorage.setItem('admin_avatar_seed', seed);
      setAvatarSeed(seed);
    } else {
      localStorage.removeItem('admin_avatar_seed');
      setAvatarSeed(null);
    }
    setShowPicker(false);
  };

  const logout = () => {
    localStorage.removeItem('admin_token');
    localStorage.removeItem('admin_user');
    navigate('/login');
  };

  return (
    <aside
      className={cn(
        'relative flex flex-col h-screen bg-white border-r border-dark-border transition-all duration-300 flex-shrink-0',
        collapsed ? 'w-[68px]' : 'w-64'
      )}
    >
      {/* Logo */}
      <div className={cn(
        'flex items-center gap-3 border-b border-dark-border flex-shrink-0',
        collapsed ? 'justify-center p-4' : 'px-4 py-4'
      )}>
        <img
          src="/logo.png"
          alt="KuboChain"
          className="w-9 h-9 object-contain flex-shrink-0"
        />
        {!collapsed && (
          <div>
            <div className="font-heading font-black text-slate-900 text-lg leading-none tracking-tight">KuboChain</div>
            <div className="text-[10px] text-slate-400 font-medium mt-0.5 uppercase tracking-widest">Command Center</div>
          </div>
        )}
      </div>

      {/* Collapse toggle */}
      <button
        onClick={() => setCollapsed((c) => !c)}
        className="absolute -right-3 top-[62px] z-10 w-6 h-6 rounded-full bg-white border border-dark-border flex items-center justify-center text-slate-500 hover:border-primary/60 transition-all shadow-sm"
        title={collapsed ? 'Expand sidebar' : 'Collapse sidebar'}
      >
        {collapsed
          ? <ArrowRight01Icon size={10} />
          : <ArrowLeft01Icon size={10} />}
      </button>

      {/* Nav groups */}
      <nav className="flex-1 overflow-y-auto py-3 px-2 space-y-0.5">
        {NAV_GROUPS.map((group) => (
          <div key={group.label} className="mb-1">
            {!collapsed && (
              <p className="px-3 pt-3 pb-1 text-[10px] font-semibold uppercase tracking-widest text-slate-400 select-none">
                {group.label}
              </p>
            )}
            {collapsed && <div className="border-t border-dark-border/60 my-2 mx-2" />}
            <div className="space-y-0.5">
              {group.items.map((item) => (
                <NavLink
                  key={item.path}
                  to={item.path}
                  end={item.exact}
                  title={collapsed ? item.label : undefined}
                  className={({ isActive }) =>
                    cn(
                      'group flex items-center gap-3 rounded-xl text-sm font-medium transition-all duration-150',
                      collapsed ? 'justify-center p-2.5' : 'px-3 py-2',
                      isActive
                        ? 'bg-primary/10 text-primary'
                        : 'text-slate-500 hover:bg-slate-100 hover:text-slate-800'
                    )
                  }
                >
                  {({ isActive }) => (
                    <>
                      <item.icon
                        size={17}
                        className={cn(
                          'flex-shrink-0 transition-all',
                          isActive ? 'text-primary' : 'text-slate-400 group-hover:text-slate-700'
                        )}
                      />
                      {!collapsed && (
                        <span className="truncate text-[13px]">{item.label}</span>
                      )}
                      {!collapsed && isActive && (
                        <span className="ml-auto w-1.5 h-1.5 rounded-full bg-primary flex-shrink-0" />
                      )}
                    </>
                  )}
                </NavLink>
              ))}
            </div>
          </div>
        ))}
      </nav>

      {/* Footer */}
      <div className={cn('border-t border-dark-border p-2', collapsed ? '' : 'px-2')}>
        {!collapsed && adminUser.name && (
          <div className="flex items-center gap-2.5 px-3 py-2 mb-1">
            <button
              onClick={() => setShowPicker(true)}
              className="relative group flex-shrink-0"
              title="Change avatar"
            >
              <Avatar name={adminUser.name} size={30} seed={avatarSeed || undefined} />
              <span className="absolute inset-0 rounded-full bg-black/30 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center">
                <PencilEdit01Icon size={11} className="text-white" />
              </span>
            </button>
            <div className="flex-1 min-w-0">
              <p className="text-xs font-semibold text-slate-700 truncate">{adminUser.name}</p>
              <p className="text-[10px] text-slate-400 truncate">{adminUser.email}</p>
            </div>
          </div>
        )}
        {collapsed && adminUser.name && (
          <div className="flex justify-center py-2 mb-1">
            <button
              onClick={() => setShowPicker(true)}
              className="relative group"
              title="Change avatar"
            >
              <Avatar name={adminUser.name} size={30} seed={avatarSeed || undefined} />
              <span className="absolute inset-0 rounded-full bg-black/30 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center">
                <PencilEdit01Icon size={11} className="text-white" />
              </span>
            </button>
          </div>
        )}
        <button
          onClick={logout}
          title={collapsed ? 'Log Out' : undefined}
          className={cn(
            'group w-full flex items-center gap-3 rounded-xl text-sm font-medium text-slate-500 hover:bg-red-50 hover:text-danger transition-all duration-150',
            collapsed ? 'justify-center p-2.5' : 'px-3 py-2.5'
          )}
        >
          <LogoutSquare01Icon size={17} className="flex-shrink-0 group-hover:text-danger transition-colors" />
          {!collapsed && <span className="text-[13px]">Log Out</span>}
        </button>
      </div>
      {showPicker && (
        <AvatarPicker
          currentSeed={avatarSeed}
          onSelect={handleAvatarSelect}
          onClose={() => setShowPicker(false)}
        />
      )}
    </aside>
  );
}
