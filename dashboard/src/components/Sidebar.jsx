import React, { useState } from 'react';
import { NavLink, useNavigate } from 'react-router-dom';
import {
  LayoutDashboard, Bike, UserCheck, Users, BarChart3,
  FileText, Bell, Settings, LogOut, ChevronLeft, ChevronRight,
  TrendingUp, Activity, Trophy,
} from 'lucide-react';
import { cn } from '../lib/utils';

const NAV_GROUPS = [
  {
    label: 'Overview',
    items: [
      { path: '/', icon: LayoutDashboard, label: 'Dashboard', exact: true },
      { path: '/analytics', icon: BarChart3, label: 'Analytics' },
      { path: '/reports', icon: TrendingUp, label: 'Reports' },
      { path: '/top-riders', icon: Trophy, label: 'Top Riders' },
    ],
  },
  {
    label: 'Management',
    items: [
      { path: '/rides', icon: Bike, label: 'Rides' },
      { path: '/drivers', icon: UserCheck, label: 'Drivers' },
      { path: '/users', icon: Users, label: 'Users' },
    ],
  },
  {
    label: 'System',
    items: [
      { path: '/notifications', icon: Bell, label: 'Notifications' },
      { path: '/settings', icon: Settings, label: 'Settings' },
    ],
  },
];

export default function Sidebar() {
  const navigate = useNavigate();
  const [collapsed, setCollapsed] = useState(false);

  const logout = () => {
    localStorage.removeItem('admin_token');
    navigate('/login');
  };

  return (
    <aside
      className={cn(
        'relative flex flex-col h-screen bg-dark-card border-r border-dark-border transition-all duration-300',
        collapsed ? 'w-[68px]' : 'w-64'
      )}
    >
      {/* Logo */}
      <div className={cn(
        'flex items-center border-b border-dark-border flex-shrink-0',
        collapsed ? 'justify-center p-4' : 'px-4 py-4'
      )}>
        {collapsed ? (
          <img src="/logo.png" alt="KuboChain" className="w-9 h-9 object-contain" />
        ) : (
          <img src="/logo.png" alt="KuboChain" className="h-10 object-contain" />
        )}
      </div>

      {/* Collapse toggle */}
      <button
        onClick={() => setCollapsed((c) => !c)}
        className="absolute -right-3 top-[62px] z-10 w-6 h-6 rounded-full bg-dark-card border border-dark-border flex items-center justify-center text-gray-400 hover:text-white hover:border-primary/50 transition-all shadow-md"
      >
        {collapsed
          ? <ChevronRight size={12} strokeWidth={2.5} />
          : <ChevronLeft size={12} strokeWidth={2.5} />}
      </button>

      {/* Nav groups */}
      <nav className="flex-1 overflow-y-auto py-4 px-2 space-y-1">
        {NAV_GROUPS.map((group) => (
          <div key={group.label} className="mb-2">
            {!collapsed && (
              <p className="px-3 mb-1 text-[10px] font-semibold uppercase tracking-widest text-gray-600 select-none">
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
                      collapsed ? 'justify-center p-2.5' : 'px-3 py-2.5',
                      isActive
                        ? 'bg-primary/10 text-primary'
                        : 'text-gray-400 hover:bg-white/5 hover:text-white'
                    )
                  }
                >
                  {({ isActive }) => (
                    <>
                      <item.icon
                        size={18}
                        strokeWidth={isActive ? 2.5 : 1.8}
                        className={cn(
                          'flex-shrink-0 transition-all',
                          isActive ? 'text-primary' : 'text-gray-500 group-hover:text-white'
                        )}
                      />
                      {!collapsed && (
                        <span className="truncate">{item.label}</span>
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
        <button
          onClick={logout}
          title={collapsed ? 'Log Out' : undefined}
          className={cn(
            'group w-full flex items-center gap-3 rounded-xl text-sm font-medium text-gray-500 hover:bg-danger/10 hover:text-danger transition-all duration-150',
            collapsed ? 'justify-center p-2.5' : 'px-3 py-2.5'
          )}
        >
          <LogOut size={18} strokeWidth={1.8} className="flex-shrink-0 group-hover:text-danger transition-colors" />
          {!collapsed && <span>Log Out</span>}
        </button>
      </div>
    </aside>
  );
}
