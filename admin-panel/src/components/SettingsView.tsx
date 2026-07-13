import React, { useState } from 'react';
import { 
  Settings, 
  Store, 
  CreditCard, 
  Truck, 
  Save,
  Server,
  Globe,
  Check
} from 'lucide-react';
import { getSwal, showToast } from '../utils/alerts';
import {
  clearAdminToken,
  getAdminToken,
  getBackendUrl,
  setAdminToken,
  setBackendUrl,
  getCurrencySymbol,
  setCurrencySymbol
} from '../utils/config';
import { Palette } from 'lucide-react';

interface SettingsViewProps {
  theme: string;
  setTheme: (theme: string) => void;
}

const THEMES_GRID = [
  { id: 'theme-light-default', label: 'Frosted Opal', bg: 'bg-[#f8fafc]', accent: 'bg-[#10b981]', desc: 'Bright frosted glass mode for high readability.' },
  { id: 'theme-nordic-frost', label: 'Nordic Frost', bg: 'bg-[#f0f7ff]', accent: 'bg-[#0284c7]', desc: 'Crisp polar ice blue background.' },
  { id: 'theme-emerald-glass', label: 'Emerald Glass', bg: 'bg-[#f0fdf4]', accent: 'bg-[#059669]', desc: 'Premium soft organic green blur.' },
  { id: 'theme-midnight-violet', label: 'Midnight Violet', bg: 'bg-[#f5f3ff]', accent: 'bg-[#7c3aed]', desc: 'Translucent lavender with violet accents.' },
  { id: 'theme-rose-sakura', label: 'Rose Sakura', bg: 'bg-[#fff1f2]', accent: 'bg-[#e11d48]', desc: 'Delicate light rose blossoms theme.' },
  { id: 'theme-cyberpunk', label: 'Cyberpunk Light', bg: 'bg-[#faf5ff]', accent: 'bg-[#db2777]', desc: 'Translucent lilac base with neon magenta highlights.' },
  { id: 'theme-sunset-gold', label: 'Sunset Gold', bg: 'bg-[#fffbeb]', accent: 'bg-[#d97706]', desc: 'Warm ivory background with golden copper.' },
  { id: 'theme-ocean-abreeze', label: 'Ocean Pearl', bg: 'bg-[#f0fdfa]', accent: 'bg-[#0d9488]', desc: 'Subtle ocean turquoise sand gradient.' },
  { id: 'theme-crimson-phantom', label: 'Crimson Light', bg: 'bg-[#fef2f2]', accent: 'bg-[#dc2626]', desc: 'Frosted coral red background accents.' },
  { id: 'theme-forest-moss', label: 'Forest Moss', bg: 'bg-[#f7fee7]', accent: 'bg-[#65a30d]', desc: 'Clean pastel moss green colorway.' },
  { id: 'theme-dark-slate', label: 'Minimal Slate', bg: 'bg-[#f1f5f9]', accent: 'bg-[#334155]', desc: 'Crisp minimal paper slate workspace.' },
  { id: 'theme-retro-amber', label: 'Retro Amber', bg: 'bg-[#fafaf9]', accent: 'bg-[#b45309]', desc: 'Vintage warm ivory and honey amber.' },
];

export default function SettingsView({ theme, setTheme }: SettingsViewProps) {
  const [storeName, setStoreName] = useState('FreshCart PK');
  const [storeEmail, setStoreEmail] = useState('admin@freshcart.com');
  const [deliveryFee, setDeliveryFee] = useState('150');
  const [freeDeliveryThreshold, setFreeDeliveryThreshold] = useState('1500');
  const [codEnabled, setCodEnabled] = useState(true);
  const [stripeEnabled, setStripeEnabled] = useState(false);

  // Currency config
  const [currency, setCurrency] = useState(() => getCurrencySymbol());

  // Backend URL config
  const [backendUrl, setBackendUrlState] = useState(() => getBackendUrl());
  const [adminToken, setAdminTokenState] = useState(() => getAdminToken());
  const [isTesting, setIsTesting] = useState(false);
  const [testStatus, setTestStatus] = useState<'idle' | 'success' | 'error'>('idle');

  const handleTestAndSaveBackendUrl = async () => {
    setIsTesting(true);
    setTestStatus('idle');
    try {
      const res = await fetch(`${backendUrl.replace(/\/+$/, '')}/api/v1/products?limit=1`);
      if (res.ok) {
        setBackendUrl(backendUrl);
        setTestStatus('success');
        showToast('success', 'Backend URL connected and saved!');
        setTimeout(() => {
          window.location.reload();
        }, 1000);
      } else {
        setTestStatus('error');
        showToast('error', `Backend returned status ${res.status}`);
      }
    } catch {
      setTestStatus('error');
      showToast('error', 'Could not connect to backend server.');
    } finally {
      setIsTesting(false);
    }
  };

  const handleResetBackendUrl = () => {
    localStorage.removeItem('api_backend_url');
    setBackendUrlState('https://grocery-backend.xpertraza13.workers.dev');
    setTestStatus('idle');
    showToast('success', 'Reset to default backend URL successfully!');
    setTimeout(() => {
      window.location.reload();
    }, 1000);
  };

  const handleSaveAdminToken = () => {
    if (!adminToken.trim()) {
      clearAdminToken();
      showToast('success', 'Admin API key cleared.');
      return;
    }
    setAdminToken(adminToken);
    showToast('success', 'Admin API key saved for this browser.');
  };

  const handleCurrencyChange = (newSymbol: string) => {
    setCurrencySymbol(newSymbol);
    setCurrency(newSymbol);
    showToast('success', `Currency preference updated to ${newSymbol}!`);
    setTimeout(() => {
      window.location.reload();
    }, 800);
  };

  const handleSaveSettings = (e: React.FormEvent) => {
    e.preventDefault();
    const swal = getSwal();
    swal.fire({
      title: 'Save Changes?',
      text: 'Are you sure you want to update the store settings?',
      icon: 'question',
      showCancelButton: true,
      confirmButtonText: 'Yes, save',
      cancelButtonText: 'Cancel'
    }).then((result) => {
      if (result.isConfirmed) {
        showToast('success', 'Settings updated successfully!');
      }
    });
  };

  return (
    <div className="space-y-6">
      {/* Top Banner */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between rounded-2xl glass-panel p-5 float-card shadow-lg">
        <div>
          <h2 className="text-lg font-bold text-text-primary flex items-center gap-2">
            <Settings className="h-5.5 w-5.5 text-emerald-400" />
            General System Settings
          </h2>
          <p className="text-xs text-text-secondary mt-0.5">Configure payment gateways, shipping parameters, and metadata attributes</p>
        </div>
      </div>

      <form onSubmit={handleSaveSettings} className="space-y-6 max-w-4xl">
        {/* Section 0: Backend API URL */}
        <div className="rounded-2xl glass-panel border border-emerald-500/30 p-5 space-y-4 relative overflow-hidden float-card shadow-lg">
          <div className="mesh-glow-orb right-0 top-0 h-32 w-32 bg-emerald-500/10" />
          <h3 className="text-sm font-bold uppercase tracking-wider text-text-primary flex items-center gap-2">
            <Server className="h-4.5 w-4.5 text-emerald-400" />
            Backend API Connection
          </h3>
          <p className="text-xs text-text-secondary">
            Set the public URL of your deployed Cloudflare Worker backend API.
          </p>
          <div className="flex flex-col sm:flex-row gap-3 items-start sm:items-end">
            <div className="flex-1">
              <label className="block text-xs font-semibold text-text-secondary uppercase mb-1.5 flex items-center gap-1.5">
                <Globe className="h-3.5 w-3.5" />
                Backend Base URL
              </label>
              <input
                type="url"
                value={backendUrl}
                onChange={(e) => { setBackendUrlState(e.target.value); setTestStatus('idle'); }}
                placeholder="https://your-worker.your-subdomain.workers.dev"
                className="w-full rounded-xl bg-bg-input border border-border-card px-4 py-2.5 text-sm text-text-primary focus:outline-none focus:border-emerald-500 transition-colors font-mono"
              />
            </div>
            <button
              type="button"
              onClick={handleTestAndSaveBackendUrl}
              disabled={isTesting}
              className={`flex items-center gap-2 px-5 py-2.5 rounded-xl text-sm font-semibold transition-all whitespace-nowrap ${
                testStatus === 'success' 
                  ? 'bg-emerald-500 text-white' 
                  : testStatus === 'error' 
                    ? 'bg-red-500/20 text-red-400 border border-red-500/40' 
                    : 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/40 hover:bg-emerald-500/30'
              }`}
            >
              {isTesting ? (
                <span className="h-4 w-4 border-2 border-emerald-400 border-t-transparent rounded-full animate-spin" />
              ) : testStatus === 'success' ? (
                <Check className="h-4 w-4" />
              ) : (
                <Server className="h-4 w-4" />
              )}
              {isTesting ? 'Testing...' : testStatus === 'success' ? 'Connected!' : 'Test & Save'}
            </button>
            <button
              type="button"
              onClick={handleResetBackendUrl}
              className="flex items-center gap-2 px-5 py-2.5 rounded-xl text-sm font-semibold transition-all whitespace-nowrap bg-bg-input text-text-secondary border border-border-card hover:text-text-primary hover:bg-panel"
            >
              Reset to Default
            </button>
          </div>
          <div className={`text-xs rounded-lg px-3 py-2 ${
            testStatus === 'success' 
              ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20' 
              : testStatus === 'error'
                ? 'bg-red-500/10 text-red-400 border border-red-500/20'
                : 'bg-amber-500/10 text-amber-400 border border-amber-500/20'
          }`}>
            {testStatus === 'success' 
              ? 'Backend is online and URL saved. Products and categories will load from this server.' 
              : testStatus === 'error'
                ? 'Could not reach backend. Check that the Worker URL is publicly accessible.'
                : 'Currently using: ' + backendUrl + ' - click "Test & Save" to verify connection.'
            }
          </div>

          <div className="grid grid-cols-1 gap-3 border-t border-border-card pt-4 md:grid-cols-[1fr_auto] md:items-end">
            <div>
              <label className="block text-xs font-semibold text-text-secondary uppercase mb-1.5">
                Admin API Key
              </label>
              <input
                type="password"
                value={adminToken}
                onChange={(e) => setAdminTokenState(e.target.value)}
                placeholder="Paste Cloudflare Worker ADMIN_API_KEY"
                className="w-full rounded-xl bg-bg-input border border-border-card px-4 py-2.5 text-sm text-text-primary focus:outline-none focus:border-emerald-500 transition-colors font-mono"
              />
            </div>
            <button
              type="button"
              onClick={handleSaveAdminToken}
              className="flex items-center justify-center gap-2 px-5 py-2.5 rounded-xl text-sm font-semibold transition-all whitespace-nowrap bg-bg-input text-text-secondary border border-border-card hover:text-text-primary hover:bg-panel"
            >
              <Check className="h-4 w-4" />
              Save Key
            </button>
          </div>
        </div>

        {/* Section 1: Store profile */}
        <div className="rounded-2xl glass-panel p-5 space-y-4 float-card shadow-lg">
          <h3 className="text-sm font-bold uppercase tracking-wider text-text-primary flex items-center gap-2">
            <Store className="h-4.5 w-4.5 text-emerald-400" />
            Store Information
          </h3>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div>
              <label className="block text-xs font-semibold text-text-secondary uppercase mb-1.5">Store Display Name</label>
              <input
                type="text"
                value={storeName}
                onChange={(e) => setStoreName(e.target.value)}
                className="w-full rounded-xl bg-bg-input border border-border-card px-4 py-2.5 text-sm text-text-primary focus:outline-none focus:border-emerald-500 transition-colors"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-text-secondary uppercase mb-1.5">Contact Notification Email</label>
              <input
                type="email"
                value={storeEmail}
                onChange={(e) => setStoreEmail(e.target.value)}
                className="w-full rounded-xl bg-bg-input border border-border-card px-4 py-2.5 text-sm text-text-primary focus:outline-none focus:border-emerald-500 transition-colors"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-text-secondary uppercase mb-1.5">System Currency</label>
              <select
                value={currency}
                onChange={(e) => handleCurrencyChange(e.target.value)}
                className="w-full rounded-xl bg-bg-input border border-border-card px-4 py-2.5 text-sm text-text-primary focus:outline-none focus:border-emerald-500 transition-colors cursor-pointer"
              >
                <option value="PKR">Pakistani Rupee (Rs. / PKR)</option>
                <option value="USD">US Dollar ($ / USD)</option>
              </select>
            </div>
          </div>
        </div>

        {/* Section 2: Delivery settings */}
        <div className="rounded-2xl glass-panel p-5 space-y-4 float-card shadow-lg">
          <h3 className="text-sm font-bold uppercase tracking-wider text-text-primary flex items-center gap-2">
            <Truck className="h-4.5 w-4.5 text-emerald-400" />
            Shipping & Logistics configuration
          </h3>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-semibold text-text-secondary uppercase mb-1.5">Flat Delivery Fee (PKR)</label>
              <input
                type="number"
                value={deliveryFee}
                onChange={(e) => setDeliveryFee(e.target.value)}
                className="w-full rounded-xl bg-bg-input border border-border-card px-4 py-2.5 text-sm text-text-primary focus:outline-none focus:border-emerald-500 transition-colors"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-text-secondary uppercase mb-1.5">Free Delivery Minimum Order (PKR)</label>
              <input
                type="number"
                value={freeDeliveryThreshold}
                onChange={(e) => setFreeDeliveryThreshold(e.target.value)}
                className="w-full rounded-xl bg-bg-input border border-border-card px-4 py-2.5 text-sm text-text-primary focus:outline-none focus:border-emerald-500 transition-colors"
              />
            </div>
          </div>
        </div>

        {/* Section 3: Payments */}
        <div className="rounded-2xl glass-panel p-5 space-y-4 float-card shadow-lg">
          <h3 className="text-sm font-bold uppercase tracking-wider text-text-primary flex items-center gap-2">
            <CreditCard className="h-4.5 w-4.5 text-emerald-400" />
            Merchant Payment Gateways
          </h3>
          <div className="space-y-3.5">
            <div className="flex items-center justify-between p-3 rounded-xl border border-border-card bg-bg-input">
              <div>
                <p className="text-sm font-semibold text-text-primary">Cash on Delivery (COD)</p>
                <p className="text-xs text-text-secondary">Accept physical currency payment on parcel drop-off</p>
              </div>
              <input 
                type="checkbox"
                checked={codEnabled}
                onChange={(e) => setCodEnabled(e.target.checked)}
                className="h-5 w-5 rounded border-border-card text-emerald-500 focus:ring-emerald-500/20"
              />
            </div>

            <div className="flex items-center justify-between p-3 rounded-xl border border-border-card bg-bg-input">
              <div>
                <p className="text-sm font-semibold text-text-primary">Stripe Credit Card processing</p>
                <p className="text-xs text-text-secondary">Enable live client-side credit card authorization and deposit payouts</p>
              </div>
              <input 
                type="checkbox"
                checked={stripeEnabled}
                onChange={(e) => setStripeEnabled(e.target.checked)}
                className="h-5 w-5 rounded border-border-card text-emerald-500 focus:ring-emerald-500/20"
              />
            </div>
          </div>
        </div>

        {/* Section 4: Premium Dashboard Themes */}
        <div className="rounded-2xl glass-panel p-5 space-y-4 float-card shadow-lg relative overflow-hidden">
          <div className="mesh-glow-orb right-0 top-0 h-32 w-32 bg-accent-primary/10" />
          <h3 className="text-sm font-bold uppercase tracking-wider text-text-primary flex items-center gap-2 relative z-10">
            <Palette className="h-4.5 w-4.5 text-accent-primary" />
            Premium Themes Selection
          </h3>
          <p className="text-xs text-text-secondary relative z-10">
            Select one of the 12 gorgeous high-fidelity themes. Changes apply instantly.
          </p>
          <div className="flex flex-col gap-2 relative z-10 max-w-xl">
            {THEMES_GRID.map((t) => (
              <button
                key={t.id}
                type="button"
                onClick={() => setTheme(t.id)}
                className={`flex items-center justify-between rounded-xl p-3 border transition-all duration-200 cursor-pointer ${
                  theme === t.id
                    ? 'border-accent-primary bg-accent-primary/5 ring-1 ring-accent-primary/10 shadow-md'
                    : 'border-border-card/40 bg-bg-input hover:border-border-card hover:bg-hover-panel'
                }`}
              >
                <div className="flex items-center gap-4">
                  {/* Swatch circle */}
                  <div className="flex h-8 w-14 shrink-0 overflow-hidden rounded-lg border border-border-card/60">
                    <div className={`w-1/2 ${t.bg}`} />
                    <div className={`w-1/2 ${t.accent}`} />
                  </div>
                  <div>
                    <span className="text-xs font-bold text-text-primary block">{t.label}</span>
                    <span className="text-[10px] text-text-secondary block mt-0.5">{t.desc}</span>
                  </div>
                </div>
                
                {/* Active check indicator */}
                {theme === t.id && (
                  <div className="flex h-5 w-5 items-center justify-center rounded-full bg-accent-primary text-white font-bold text-xs shrink-0 shadow-sm">
                    ✓
                  </div>
                )}
              </button>
            ))}
          </div>
        </div>

        {/* Save button */}
        <div className="flex justify-end pt-2">
          <button
            type="submit"
            className="flex items-center justify-center gap-2 rounded-xl bg-gradient-to-r from-accent-primary to-accent-secondary px-6 py-3 text-sm font-bold text-white hover:brightness-110 hover:shadow-xl hover:shadow-accent-primary/25 active:scale-98 transition-all duration-300 cursor-pointer shadow-lg shadow-accent-primary/15"
          >
            <Save className="h-4.5 w-4.5" />
            Save Store Configuration
          </button>
        </div>
      </form>
    </div>
  );
}
