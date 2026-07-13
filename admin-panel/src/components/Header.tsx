import { useState } from 'react';
import { Menu, Bell, Search, LogOut, User, Shield, Palette } from 'lucide-react';

interface HeaderProps {
  onMenuToggle: () => void;
  searchTerm: string;
  setSearchTerm: (term: string) => void;
  theme: string;
  onChangeTheme: (theme: string) => void;
}

const THEMES_LIST = [
  { id: 'theme-light-default', label: 'Frosted Opal', bg: '#f8fafc', accent: '#10b981' },
  { id: 'theme-nordic-frost', label: 'Nordic Frost', bg: '#f0f7ff', accent: '#0284c7' },
  { id: 'theme-emerald-glass', label: 'Emerald Glass', bg: '#f0fdf4', accent: '#059669' },
  { id: 'theme-midnight-violet', label: 'Midnight Violet', bg: '#f5f3ff', accent: '#7c3aed' },
  { id: 'theme-rose-sakura', label: 'Rose Sakura', bg: '#fff1f2', accent: '#e11d48' },
  { id: 'theme-cyberpunk', label: 'Cyberpunk Light', bg: '#faf5ff', accent: '#db2777' },
  { id: 'theme-sunset-gold', label: 'Sunset Gold', bg: '#fffbeb', accent: '#d97706' },
  { id: 'theme-ocean-abreeze', label: 'Ocean Pearl', bg: '#f0fdfa', accent: '#0d9488' },
  { id: 'theme-crimson-phantom', label: 'Crimson Light', bg: '#fef2f2', accent: '#dc2626' },
  { id: 'theme-forest-moss', label: 'Forest Moss', bg: '#f7fee7', accent: '#65a30d' },
  { id: 'theme-dark-slate', label: 'Minimal Slate', bg: '#f1f5f9', accent: '#334155' },
  { id: 'theme-retro-amber', label: 'Retro Amber', bg: '#fafaf9', accent: '#b45309' },
];

export default function Header({ onMenuToggle, searchTerm, setSearchTerm, theme, onChangeTheme }: HeaderProps) {
  const [showProfileDropdown, setShowProfileDropdown] = useState(false);
  const [showThemeDropdown, setShowThemeDropdown] = useState(false);

  return (
    <header className="sticky top-0 z-30 flex h-16 w-full items-center justify-between border-b border-border-card/40 bg-body/75 backdrop-blur-md px-6 shadow-sm">
      {/* Left section: Hamburger for mobile & Search bar */}
      <div className="flex flex-1 items-center gap-4">
        <button
          onClick={onMenuToggle}
          className="rounded-xl p-2 text-text-secondary hover:bg-hover-panel hover:text-text-primary lg:hidden transition-colors"
        >
          <Menu className="h-6 w-6" />
        </button>

        <div className="relative max-w-md w-full hidden md:block">
          <span className="absolute inset-y-0 left-0 flex items-center pl-3.5 pointer-events-none">
            <Search className="h-4.5 w-4.5 text-text-secondary" />
          </span>
          <input
            type="text"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            placeholder="Global search products, categories, orders..."
            className="w-full rounded-xl bg-bg-input border border-border-card py-2 pl-10 pr-4 text-sm text-text-primary placeholder-text-secondary focus:outline-none focus:ring-2 focus:ring-accent-primary/20 focus:border-accent-primary transition-all duration-200"
          />
        </div>
      </div>

      {/* Right section: Actions & Profile */}
      <div className="flex items-center gap-4">
        {/* Search toggle for mobile */}
        <div className="relative md:hidden w-36">
          <input
            type="text"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            placeholder="Search..."
            className="w-full rounded-lg bg-bg-input border border-border-card py-1.5 pl-8 pr-2.5 text-xs text-text-primary focus:outline-none focus:border-accent-primary transition-colors"
          />
          <Search className="absolute left-2.5 top-2.5 h-3.5 w-3.5 text-text-secondary" />
        </div>

        {/* Palette Theme Dropdown */}
        <div className="relative">
          <button 
            onClick={() => setShowThemeDropdown(!showThemeDropdown)}
            className="rounded-xl p-2.5 text-text-secondary hover:bg-hover-panel hover:text-text-primary transition-all duration-200 cursor-pointer"
            title="Switch Dashboard Theme"
          >
            <Palette className="h-5 w-5" />
          </button>
          
          {showThemeDropdown && (
            <>
              <div className="fixed inset-0 z-40" onClick={() => setShowThemeDropdown(false)} />
              <div className="absolute right-0 mt-2.5 w-64 origin-top-right rounded-xl glass-panel p-2 shadow-2xl z-50 max-h-96 overflow-y-auto">
                <div className="px-3 py-2 border-b border-border-card/40 text-xs font-semibold text-text-secondary">
                  Dashboard Themes
                </div>
                <div className="py-1 grid grid-cols-1 gap-0.5">
                  {THEMES_LIST.map((t) => (
                    <button
                      key={t.id}
                      onClick={() => {
                        onChangeTheme(t.id);
                        setShowThemeDropdown(false);
                      }}
                      className={`flex w-full items-center gap-3 rounded-lg px-3 py-2 text-xs font-medium transition-colors hover:bg-hover-panel text-left ${
                        theme === t.id ? 'text-accent-primary bg-accent-primary/10' : 'text-text-secondary hover:text-text-primary'
                      }`}
                    >
                      <div className="flex h-5 w-9 shrink-0 overflow-hidden rounded-md border border-border-card/60">
                        <div className="w-1/2" style={{ backgroundColor: t.bg }} />
                        <div className="w-1/2" style={{ backgroundColor: t.accent }} />
                      </div>
                      <span className="truncate">{t.label}</span>
                    </button>
                  ))}
                </div>
              </div>
            </>
          )}
        </div>

        {/* Notifications */}
        <button className="relative rounded-xl p-2.5 text-text-secondary hover:bg-hover-panel hover:text-text-primary transition-all duration-200">
          <Bell className="h-5 w-5" />
          <span className="absolute top-2 right-2 h-2 w-2 rounded-full bg-accent-primary ring-2 ring-panel" />
        </button>

        {/* Profile Dropdown Toggle */}
        <div className="relative">
          <button
            onClick={() => setShowProfileDropdown(!showProfileDropdown)}
            className="flex items-center gap-2 rounded-xl p-1.5 hover:bg-hover-panel transition-all duration-200 focus:outline-none cursor-pointer"
          >
            <img
              src="https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&q=80&w=100"
              alt="Admin Profile"
              className="h-8 w-8 rounded-lg object-cover ring-2 ring-accent-primary/15"
            />
            <span className="hidden text-sm font-medium text-text-primary lg:block">ALI</span>
          </button>

          {showProfileDropdown && (
            <>
              {/* Overlay to close profile */}
              <div 
                className="fixed inset-0 z-40" 
                onClick={() => setShowProfileDropdown(false)}
              />
              <div className="absolute right-0 mt-2.5 w-56 origin-top-right rounded-xl glass-panel p-2 text-text-primary shadow-2xl z-50">
                <div className="px-3 py-2 border-b border-border-card/40">
                  <p className="text-xs text-text-secondary">Signed in as</p>
                  <p className="text-sm font-semibold text-text-primary truncate">ali@freshcart.com</p>
                </div>
                <div className="py-1">
                  <a
                    href="#profile"
                    className="flex items-center gap-2.5 rounded-lg px-3 py-2 text-sm text-text-secondary hover:bg-hover-panel hover:text-text-primary transition-colors"
                    onClick={() => setShowProfileDropdown(false)}
                  >
                    <User className="h-4.5 w-4.5" />
                    My Profile
                  </a>
                  <a
                    href="#admin"
                    className="flex items-center gap-2.5 rounded-lg px-3 py-2 text-sm text-text-secondary hover:bg-hover-panel hover:text-text-primary transition-colors"
                    onClick={() => setShowProfileDropdown(false)}
                  >
                    <Shield className="h-4.5 w-4.5" />
                    Security Settings
                  </a>
                </div>
                <div className="border-t border-border-card/40 pt-1">
                  <button
                    className="flex w-full items-center gap-2.5 rounded-lg px-3 py-2 text-sm text-red-400 hover:bg-red-500/10 transition-colors"
                    onClick={() => setShowProfileDropdown(false)}
                  >
                    <LogOut className="h-4.5 w-4.5" />
                    Log Out
                  </button>
                </div>
              </div>
            </>
          )}
        </div>
      </div>
    </header>
  );
}
