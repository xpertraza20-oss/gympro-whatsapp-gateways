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
import { getBackendUrl, setBackendUrl } from '../utils/config';

export default function SettingsView() {
  const [storeName, setStoreName] = useState('FreshCart PK');
  const [storeEmail, setStoreEmail] = useState('admin@freshcart.com');
  const [deliveryFee, setDeliveryFee] = useState('150');
  const [freeDeliveryThreshold, setFreeDeliveryThreshold] = useState('1500');
  const [codEnabled, setCodEnabled] = useState(true);
  const [stripeEnabled, setStripeEnabled] = useState(false);

  // Backend URL config
  const [backendUrl, setBackendUrlState] = useState(() => getBackendUrl());
  const [isTesting, setIsTesting] = useState(false);
  const [testStatus, setTestStatus] = useState<'idle' | 'success' | 'error'>('idle');

  const handleTestAndSaveBackendUrl = async () => {
    setIsTesting(true);
    setTestStatus('idle');
    try {
      const res = await fetch(`${backendUrl.replace(/\/+$/, '')}/api/health`, { signal: AbortSignal.timeout(5000) });
      if (res.ok) {
        setBackendUrl(backendUrl);
        setTestStatus('success');
        showToast('success', 'Backend URL connected and saved!');
      } else {
        setTestStatus('error');
        showToast('error', `Backend returned status ${res.status}`);
      }
    } catch (err: any) {
      setTestStatus('error');
      showToast('error', 'Could not connect to backend server.');
    } finally {
      setIsTesting(false);
    }
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
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between rounded-2xl border border-border-card bg-panel p-5">
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
        <div className="rounded-2xl border border-emerald-500/30 bg-panel p-5 space-y-4">
          <h3 className="text-sm font-bold uppercase tracking-wider text-text-primary flex items-center gap-2">
            <Server className="h-4.5 w-4.5 text-emerald-400" />
            Backend API Connection
          </h3>
          <p className="text-xs text-text-secondary">
            Set the public URL of your deployed backend API. This must be reachable from the internet (e.g., Railway, Render, ngrok).
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
                placeholder="https://your-backend.railway.app"
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
          </div>
          <div className={`text-xs rounded-lg px-3 py-2 ${
            testStatus === 'success' 
              ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20' 
              : testStatus === 'error'
                ? 'bg-red-500/10 text-red-400 border border-red-500/20'
                : 'bg-amber-500/10 text-amber-400 border border-amber-500/20'
          }`}>
            {testStatus === 'success' 
              ? '✅ Backend is online and URL saved. Products and categories will load from this server.' 
              : testStatus === 'error'
                ? '❌ Could not reach backend. Check the URL is publicly accessible (not localhost).'
                : '⚠️ Currently using: ' + backendUrl + ' — Click "Test & Save" to verify connection.'
            }
          </div>
        </div>

        {/* Section 1: Store profile */}
        <div className="rounded-2xl border border-border-card bg-panel p-5 space-y-4">
          <h3 className="text-sm font-bold uppercase tracking-wider text-text-primary flex items-center gap-2">
            <Store className="h-4.5 w-4.5 text-emerald-400" />
            Store Information
          </h3>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
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
          </div>
        </div>

        {/* Section 2: Delivery settings */}
        <div className="rounded-2xl border border-border-card bg-panel p-5 space-y-4">
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
        <div className="rounded-2xl border border-border-card bg-panel p-5 space-y-4">
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

        {/* Save button */}
        <div className="flex justify-end pt-2">
          <button
            type="submit"
            className="flex items-center justify-center gap-2 rounded-xl bg-gradient-to-r from-emerald-500 to-teal-500 px-6 py-3 text-sm font-bold text-slate-950 hover:brightness-110 active:scale-98 transition-all duration-200 cursor-pointer shadow-lg shadow-emerald-500/15"
          >
            <Save className="h-4.5 w-4.5" />
            Save Store Configuration
          </button>
        </div>
      </form>
    </div>
  );
}
