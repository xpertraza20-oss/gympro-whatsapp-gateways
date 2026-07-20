import { useState, useEffect, useCallback } from 'react';
import { getAdminHeaders, getBackendUrl, formatPrice } from '../utils/config';
import { showToast } from '../utils/alerts';
import {
  DollarSign,
  TrendingUp,
  Percent,
  Store,
  Bike,
  CheckCircle2,
  Clock,
  RefreshCcw,
  Sliders,
  CircleDollarSign,
} from 'lucide-react';

interface FinancialStats {
  grossSales: number;
  commission: number;
  shopPayable: number;
  riderEarnings: number;
  refunds: number;
}

interface ShopCommissionSetting {
  id: number;
  name: string;
  commissionPercentage: number | null;
}

interface ShopSettlement {
  id: number;
  shop_id: number;
  shop_name: string;
  sales_amount: number;
  commission_amount: number;
  payable_amount: number;
  status: 'paid' | 'unpaid';
  paid_at: string | null;
  created_at: string;
}

interface RiderSettlement {
  id: number;
  rider_id: number;
  rider_name: string;
  rider_phone: string;
  deliveries_count: number;
  earnings_amount: number;
  cod_collected: number;
  status: 'paid' | 'pending';
  paid_at: string | null;
  created_at: string;
}

export default function FinancialDashboard() {
  const [activeTab, setActiveTab] = useState<'dashboard' | 'commissions' | 'settlements'>('dashboard');
  const [stats, setStats] = useState<FinancialStats>({
    grossSales: 0,
    commission: 0,
    shopPayable: 0,
    riderEarnings: 0,
    refunds: 0,
  });
  const [globalCommissionPct, setGlobalCommissionPct] = useState<number>(10);
  const [shops, setShops] = useState<ShopCommissionSetting[]>([]);
  const [shopSettlements, setShopSettlements] = useState<ShopSettlement[]>([]);
  const [riderSettlements, setRiderSettlements] = useState<RiderSettlement[]>([]);
  
  const [loading, setLoading] = useState<boolean>(true);
  const [editingShopId, setEditingShopId] = useState<number | null>(null);
  const [tempShopPct, setTempShopPct] = useState<string>('');
  const [globalPctInput, setGlobalPctInput] = useState<string>('');
  
  const [payingShopId, setPayingShopId] = useState<number | null>(null);
  const [payingRiderId, setPayingRiderId] = useState<number | null>(null);

  const headers = getAdminHeaders();
  const backendUrl = getBackendUrl();

  const fetchStats = useCallback(async () => {
    try {
      const res = await fetch(`${backendUrl}/api/v1/admin/financials/dashboard`, {
        headers: { ...headers, 'bypass-tunnel-reminder': 'true' }
      });
      const json = await res.json();
      if (json.success && json.data) {
        setStats(json.data);
      }
    } catch {
      console.error('Failed to load dashboard stats.');
    }
  }, [backendUrl]);

  const fetchSettings = useCallback(async () => {
    try {
      const res = await fetch(`${backendUrl}/api/v1/admin/financials/settings`, {
        headers: { ...headers, 'bypass-tunnel-reminder': 'true' }
      });
      const json = await res.json();
      if (json.success && json.data) {
        setGlobalCommissionPct(json.data.globalCommissionPercentage);
        setGlobalPctInput(String(json.data.globalCommissionPercentage));
        setShops(json.data.shops);
      }
    } catch {
      console.error('Failed to load commission settings.');
    }
  }, [backendUrl]);

  const fetchSettlements = useCallback(async () => {
    try {
      const shopRes = await fetch(`${backendUrl}/api/v1/admin/financials/shop-settlements`, {
        headers: { ...headers, 'bypass-tunnel-reminder': 'true' }
      });
      const shopJson = await shopRes.json();
      if (shopJson.success && Array.isArray(shopJson.data)) {
        setShopSettlements(shopJson.data);
      }

      const riderRes = await fetch(`${backendUrl}/api/v1/admin/financials/rider-settlements`, {
        headers: { ...headers, 'bypass-tunnel-reminder': 'true' }
      });
      const riderJson = await riderRes.json();
      if (riderJson.success && Array.isArray(riderJson.data)) {
        setRiderSettlements(riderJson.data);
      }
    } catch {
      console.error('Failed to load settlements.');
    }
  }, [backendUrl]);

  const loadAll = useCallback(async () => {
    setLoading(true);
    await Promise.all([fetchStats(), fetchSettings(), fetchSettlements()]);
    setLoading(false);
  }, [fetchStats, fetchSettings, fetchSettlements]);

  useEffect(() => {
    loadAll();
  }, [loadAll]);

  const handleUpdateGlobalPct = async () => {
    const val = parseFloat(globalPctInput);
    if (isNaN(val) || val < 0 || val > 100) {
      showToast('error', 'Please enter a valid percentage between 0 and 100.');
      return;
    }
    try {
      const res = await fetch(`${backendUrl}/api/v1/admin/financials/settings`, {
        method: 'PUT',
        headers: { ...headers, 'Content-Type': 'application/json', 'bypass-tunnel-reminder': 'true' },
        body: JSON.stringify({ global_commission_percentage: val }),
      });
      const json = await res.json();
      if (json.success) {
        setGlobalCommissionPct(val);
        showToast('success', `Global commission set to ${val}% successfully.`);
      }
    } catch {
      showToast('error', 'Failed to update global percentage.');
    }
  };

  const handleUpdateShopPct = async (shopId: number) => {
    const val = tempShopPct === '' ? null : parseFloat(tempShopPct);
    if (val !== null && (isNaN(val) || val < 0 || val > 100)) {
      showToast('error', 'Please enter a valid percentage between 0 and 100.');
      return;
    }
    try {
      const res = await fetch(`${backendUrl}/api/v1/admin/financials/shops/${shopId}/commission`, {
        method: 'PUT',
        headers: { ...headers, 'Content-Type': 'application/json', 'bypass-tunnel-reminder': 'true' },
        body: JSON.stringify({ commission_percentage: val }),
      });
      const json = await res.json();
      if (json.success) {
        setShops(prev => prev.map(s => s.id === shopId ? { ...s, commissionPercentage: val } : s));
        setEditingShopId(null);
        showToast('success', 'Shop commission rate updated.');
      }
    } catch {
      showToast('error', 'Failed to update shop commission.');
    }
  };

  const handlePayShop = async (settlementId: number) => {
    setPayingShopId(settlementId);
    try {
      const res = await fetch(`${backendUrl}/api/v1/admin/financials/shop-settlements/${settlementId}/pay`, {
        method: 'PATCH',
        headers: { ...headers, 'bypass-tunnel-reminder': 'true' },
      });
      const json = await res.json();
      if (json.success) {
        setShopSettlements(prev => prev.map(s => s.id === settlementId ? { ...s, status: 'paid', paid_at: new Date().toISOString() } : s));
        showToast('success', 'Settlement marked as paid.');
        fetchStats();
      }
    } catch {
      showToast('error', 'Failed to update settlement status.');
    } finally {
      setPayingShopId(null);
    }
  };

  const handlePayRider = async (settlementId: number) => {
    setPayingRiderId(settlementId);
    try {
      const res = await fetch(`${backendUrl}/api/v1/admin/financials/rider-settlements/${settlementId}/pay`, {
        method: 'PATCH',
        headers: { ...headers, 'bypass-tunnel-reminder': 'true' },
      });
      const json = await res.json();
      if (json.success) {
        setRiderSettlements(prev => prev.map(r => r.id === settlementId ? { ...r, status: 'paid', paid_at: new Date().toISOString() } : r));
        showToast('success', 'Rider earnings marked as paid.');
        fetchStats();
      }
    } catch {
      showToast('error', 'Failed to update rider payment status.');
    } finally {
      setPayingRiderId(null);
    }
  };

  if (loading) {
    return (
      <div className="flex flex-col items-center justify-center py-20 bg-panel border border-border-card rounded-2xl">
        <div className="h-10 w-10 rounded-full border-4 border-emerald-500/30 border-t-emerald-500 animate-spin" />
        <p className="mt-4 text-sm font-semibold text-text-secondary">Loading financial dashboard...</p>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Top Title Section */}
      <div className="flex items-center justify-between flex-wrap gap-4">
        <div className="flex items-center gap-3">
          <div className="flex h-11 w-11 items-center justify-center rounded-xl bg-emerald-100 border border-emerald-200">
            <CircleDollarSign className="h-6 w-6 text-emerald-600 animate-pulse" />
          </div>
          <div>
            <h2 className="text-xl font-bold text-text-primary">Marketplace Financial System</h2>
            <p className="text-sm text-text-secondary">Track sales, commission percentages, settlements, and rider payouts</p>
          </div>
        </div>
        <button
          onClick={loadAll}
          className="flex items-center gap-2 px-4 py-2 rounded-xl border border-border-card bg-panel text-text-secondary hover:bg-hover-panel text-sm font-semibold transition-all cursor-pointer shadow-sm"
        >
          <RefreshCcw className="h-4 w-4" />
          Refresh Stats
        </button>
      </div>

      {/* Tabs */}
      <div className="flex gap-2 border-b border-border-card">
        <button
          id="fin-tab-dashboard"
          onClick={() => setActiveTab('dashboard')}
          className={`px-5 py-2.5 text-sm font-bold rounded-t-lg transition-all cursor-pointer ${
            activeTab === 'dashboard'
              ? 'bg-panel border border-b-0 border-border-card text-text-primary'
              : 'text-text-secondary hover:text-text-primary'
          }`}
        >
          Overview & Insights
        </button>
        <button
          id="fin-tab-commissions"
          onClick={() => setActiveTab('commissions')}
          className={`px-5 py-2.5 text-sm font-bold rounded-t-lg transition-all cursor-pointer ${
            activeTab === 'commissions'
              ? 'bg-panel border border-b-0 border-border-card text-text-primary'
              : 'text-text-secondary hover:text-text-primary'
          }`}
        >
          Commission Rates
        </button>
        <button
          id="fin-tab-settlements"
          onClick={() => setActiveTab('settlements')}
          className={`px-5 py-2.5 text-sm font-bold rounded-t-lg transition-all cursor-pointer ${
            activeTab === 'settlements'
              ? 'bg-panel border border-b-0 border-border-card text-text-primary'
              : 'text-text-secondary hover:text-text-primary'
          }`}
        >
          Merchant & Rider Settlements
        </button>
      </div>

      {/* TAB: Overview & Insights */}
      {activeTab === 'dashboard' && (
        <div className="space-y-6">
          {/* Summary Cards */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4">
            {/* Gross Sales */}
            <div className="rounded-2xl border border-border-card bg-panel p-5 float-card shadow-sm flex items-start gap-4">
              <div className="p-3 bg-blue-50 text-blue-600 rounded-xl">
                <TrendingUp className="h-5 w-5" />
              </div>
              <div>
                <p className="text-xs font-bold text-text-secondary uppercase tracking-wider">Gross Sales</p>
                <p className="text-xl font-black text-text-primary mt-1">{formatPrice(stats.grossSales)}</p>
                <span className="text-[10px] text-emerald-600 font-bold bg-emerald-50 px-1.5 py-0.5 rounded mt-2 block w-fit">
                  Total Volume
                </span>
              </div>
            </div>

            {/* Commissions */}
            <div className="rounded-2xl border border-border-card bg-panel p-5 float-card shadow-sm flex items-start gap-4">
              <div className="p-3 bg-emerald-50 text-emerald-600 rounded-xl">
                <Percent className="h-5 w-5" />
              </div>
              <div>
                <p className="text-xs font-bold text-text-secondary uppercase tracking-wider">Platform Comm.</p>
                <p className="text-xl font-black text-text-primary mt-1">{formatPrice(stats.commission)}</p>
                <span className="text-[10px] text-emerald-600 font-bold bg-emerald-50 px-1.5 py-0.5 rounded mt-2 block w-fit">
                  Platform Earning
                </span>
              </div>
            </div>

            {/* Shop Payable */}
            <div className="rounded-2xl border border-border-card bg-panel p-5 float-card shadow-sm flex items-start gap-4">
              <div className="p-3 bg-amber-50 text-amber-600 rounded-xl">
                <Store className="h-5 w-5" />
              </div>
              <div>
                <p className="text-xs font-bold text-text-secondary uppercase tracking-wider">Shop Payables</p>
                <p className="text-xl font-black text-text-primary mt-1">{formatPrice(stats.shopPayable)}</p>
                <span className="text-[10px] text-amber-600 font-bold bg-amber-50 px-1.5 py-0.5 rounded mt-2 block w-fit">
                  To Merchants
                </span>
              </div>
            </div>

            {/* Rider Earnings */}
            <div className="rounded-2xl border border-border-card bg-panel p-5 float-card shadow-sm flex items-start gap-4">
              <div className="p-3 bg-indigo-50 text-indigo-600 rounded-xl">
                <Bike className="h-5 w-5" />
              </div>
              <div>
                <p className="text-xs font-bold text-text-secondary uppercase tracking-wider">Rider Earnings</p>
                <p className="text-xl font-black text-text-primary mt-1">{formatPrice(stats.riderEarnings)}</p>
                <span className="text-[10px] text-indigo-600 font-bold bg-indigo-50 px-1.5 py-0.5 rounded mt-2 block w-fit">
                  Delivery Fees
                </span>
              </div>
            </div>

            {/* Refunds */}
            <div className="rounded-2xl border border-border-card bg-panel p-5 float-card shadow-sm flex items-start gap-4">
              <div className="p-3 bg-rose-50 text-rose-600 rounded-xl">
                <DollarSign className="h-5 w-5" />
              </div>
              <div>
                <p className="text-xs font-bold text-text-secondary uppercase tracking-wider">Refunds/Adjusts</p>
                <p className="text-xl font-black text-text-primary mt-1">{formatPrice(stats.refunds)}</p>
                <span className="text-[10px] text-rose-600 font-bold bg-rose-50 px-1.5 py-0.5 rounded mt-2 block w-fit">
                  Deductions
                </span>
              </div>
            </div>
          </div>

          {/* Simple distribution graph card */}
          <div className="rounded-2xl border border-border-card bg-panel p-6 shadow-sm">
            <h3 className="font-bold text-text-primary text-sm mb-4">Financial Flow Distribution</h3>
            <div className="h-6 w-full rounded-full bg-slate-100 overflow-hidden flex">
              {stats.grossSales > 0 ? (
                <>
                  <div
                    style={{ width: `${(stats.commission / stats.grossSales) * 100}%` }}
                    className="bg-emerald-500 h-full hover:brightness-95 transition-all cursor-help"
                    title={`Commission: ${((stats.commission / stats.grossSales) * 100).toFixed(1)}%`}
                  />
                  <div
                    style={{ width: `${(stats.shopPayable / stats.grossSales) * 100}%` }}
                    className="bg-amber-400 h-full hover:brightness-95 transition-all cursor-help"
                    title={`Shop Earning: ${((stats.shopPayable / stats.grossSales) * 100).toFixed(1)}%`}
                  />
                  <div
                    style={{ width: `${(stats.riderEarnings / stats.grossSales) * 100}%` }}
                    className="bg-indigo-500 h-full hover:brightness-95 transition-all cursor-help"
                    title={`Rider Payout: ${((stats.riderEarnings / stats.grossSales) * 100).toFixed(1)}%`}
                  />
                </>
              ) : (
                <div className="w-full bg-slate-200 h-full" />
              )}
            </div>
            <div className="flex items-center gap-6 mt-4 flex-wrap text-xs font-semibold text-text-secondary">
              <div className="flex items-center gap-2">
                <span className="h-3 w-3 bg-emerald-500 rounded" />
                <span>Platform Commission ({stats.grossSales > 0 ? ((stats.commission / stats.grossSales) * 100).toFixed(1) : 0}%)</span>
              </div>
              <div className="flex items-center gap-2">
                <span className="h-3 w-3 bg-amber-400 rounded" />
                <span>Shop Payouts ({stats.grossSales > 0 ? ((stats.shopPayable / stats.grossSales) * 100).toFixed(1) : 0}%)</span>
              </div>
              <div className="flex items-center gap-2">
                <span className="h-3 w-3 bg-indigo-500 rounded" />
                <span>Rider Payouts ({stats.grossSales > 0 ? ((stats.riderEarnings / stats.grossSales) * 100).toFixed(1) : 0}%)</span>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* TAB: Commission Settings */}
      {activeTab === 'commissions' && (
        <div className="space-y-6">
          {/* Global Commission Setting */}
          <div className="rounded-2xl border border-border-card bg-panel p-5 shadow-sm flex flex-col md:flex-row md:items-center justify-between gap-4">
            <div className="flex items-start gap-3">
              <div className="p-3 bg-emerald-50 text-emerald-600 rounded-xl mt-0.5">
                <Sliders className="h-5 w-5" />
              </div>
              <div>
                <p className="font-bold text-text-primary text-sm">Global Commission Percentage</p>
                <p className="text-xs text-text-secondary mt-1">
                  Default percentage fee charged to all shops unless a custom commission rate override is set.
                </p>
              </div>
            </div>
            <div className="flex items-center gap-2 shrink-0">
              <div className="relative">
                <input
                  id="global-pct-input"
                  type="number"
                  placeholder="10.00"
                  step="0.01"
                  min="0"
                  max="100"
                  value={globalPctInput}
                  onChange={e => setGlobalPctInput(e.target.value)}
                  className="w-28 pl-4 pr-8 py-2 rounded-xl border border-border-card bg-panel text-text-primary font-bold text-sm focus:ring-2 focus:ring-emerald-500/30"
                />
                <span className="absolute right-3 top-1/2 -translate-y-1/2 font-bold text-text-secondary text-sm">%</span>
              </div>
              <button
                id="global-pct-save"
                onClick={handleUpdateGlobalPct}
                className="px-4 py-2 rounded-xl bg-emerald-500 hover:bg-emerald-600 text-white text-xs font-bold transition-all cursor-pointer"
              >
                Save Default
              </button>
            </div>
          </div>

          {/* Shop Overrides Table */}
          <div className="rounded-2xl border border-border-card bg-panel overflow-hidden">
            <div className="px-5 py-4 border-b border-border-card">
              <h3 className="font-bold text-text-primary text-sm">Shop Commission Overrides</h3>
              <p className="text-xs text-text-secondary mt-0.5">Configure distinct custom commission percentages for specific merchants.</p>
            </div>
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-border-card bg-hover-panel/40">
                    <th className="px-5 py-3 text-left text-xs font-bold text-text-secondary uppercase">Shop Name</th>
                    <th className="px-5 py-3 text-left text-xs font-bold text-text-secondary uppercase">Rate Status</th>
                    <th className="px-5 py-3 text-left text-xs font-bold text-text-secondary uppercase">Commission Rate</th>
                    <th className="px-5 py-3 text-right text-xs font-bold text-text-secondary uppercase">Action</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-border-card">
                  {shops.map(shop => {
                    const hasOverride = shop.commissionPercentage !== null;
                    const rate = hasOverride ? shop.commissionPercentage : globalCommissionPct;
                    const isEditing = editingShopId === shop.id;

                    return (
                      <tr key={shop.id} className="hover:bg-hover-panel/30 transition-colors">
                        <td className="px-5 py-4 font-bold text-text-primary">{shop.name}</td>
                        <td className="px-5 py-4">
                          <span className={`inline-flex px-2 py-0.5 rounded text-[10px] font-bold ${
                            hasOverride ? 'bg-indigo-50 text-indigo-700 border border-indigo-200' : 'bg-slate-50 text-slate-600 border border-slate-200'
                          }`}>
                            {hasOverride ? 'Custom override' : 'Using default'}
                          </span>
                        </td>
                        <td className="px-5 py-4">
                          {isEditing ? (
                            <div className="relative inline-block w-24">
                              <input
                                id={`shop-pct-edit-${shop.id}`}
                                type="number"
                                step="0.01"
                                placeholder={String(globalCommissionPct)}
                                value={tempShopPct}
                                onChange={e => setTempShopPct(e.target.value)}
                                className="w-full pl-3 pr-7 py-1 rounded-lg border border-border-card bg-panel text-text-primary text-xs font-bold"
                              />
                              <span className="absolute right-2 top-1/2 -translate-y-1/2 text-xs font-bold text-text-secondary">%</span>
                            </div>
                          ) : (
                            <span className="font-black text-text-primary text-sm">{rate}%</span>
                          )}
                        </td>
                        <td className="px-5 py-4 text-right">
                          {isEditing ? (
                            <div className="flex items-center justify-end gap-2">
                              <button
                                id={`shop-pct-save-${shop.id}`}
                                onClick={() => handleUpdateShopPct(shop.id)}
                                className="px-2.5 py-1 text-[11px] font-bold text-white bg-emerald-500 rounded hover:bg-emerald-600"
                              >
                                Save
                              </button>
                              <button
                                onClick={() => setEditingShopId(null)}
                                className="px-2.5 py-1 text-[11px] font-bold text-text-secondary bg-slate-100 rounded hover:bg-slate-200"
                              >
                                Cancel
                              </button>
                            </div>
                          ) : (
                            <button
                              id={`shop-pct-edit-btn-${shop.id}`}
                              onClick={() => {
                                setEditingShopId(shop.id);
                                setTempShopPct(shop.commissionPercentage !== null ? String(shop.commissionPercentage) : '');
                              }}
                              className="text-xs font-bold text-emerald-500 hover:text-emerald-600 underline cursor-pointer"
                            >
                              Configure Rate
                            </button>
                          )}
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}

      {/* TAB: Settlements */}
      {activeTab === 'settlements' && (
        <div className="space-y-6">
          {/* Shop Settlements */}
          <div className="rounded-2xl border border-border-card bg-panel overflow-hidden">
            <div className="px-5 py-4 border-b border-border-card flex items-center justify-between">
              <div>
                <h3 className="font-bold text-text-primary text-sm">Merchant Settlements Queue</h3>
                <p className="text-xs text-text-secondary mt-0.5">Pay out accumulated payable earnings to merchant shops.</p>
              </div>
              <span className="px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-amber-50 text-amber-700 border border-amber-200">
                {shopSettlements.filter(s => s.status === 'unpaid').length} Unpaid
              </span>
            </div>
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-border-card bg-hover-panel/40">
                    <th className="px-5 py-3 text-left text-xs font-bold text-text-secondary uppercase">Merchant Shop</th>
                    <th className="px-5 py-3 text-left text-xs font-bold text-text-secondary uppercase">Gross Sales</th>
                    <th className="px-5 py-3 text-left text-xs font-bold text-text-secondary uppercase">Commission Charged</th>
                    <th className="px-5 py-3 text-left text-xs font-bold text-text-secondary uppercase">Net Payable</th>
                    <th className="px-5 py-3 text-left text-xs font-bold text-text-secondary uppercase">Status</th>
                    <th className="px-5 py-3 text-right text-xs font-bold text-text-secondary uppercase">Payout</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-border-card">
                  {shopSettlements.length === 0 ? (
                    <tr>
                      <td colSpan={6} className="px-5 py-8 text-center text-text-secondary">No shop settlements found.</td>
                    </tr>
                  ) : (
                    shopSettlements.map(settlement => {
                      const isUnpaid = settlement.status === 'unpaid';
                      const isPaying = payingShopId === settlement.id;
                      return (
                        <tr key={settlement.id} className="hover:bg-hover-panel/30 transition-colors">
                          <td className="px-5 py-4">
                            <div className="font-bold text-text-primary text-sm">{settlement.shop_name}</div>
                            <div className="text-[10px] text-text-secondary">Ref Order #{settlement.id}</div>
                          </td>
                          <td className="px-5 py-4 text-text-primary font-semibold">{formatPrice(settlement.sales_amount)}</td>
                          <td className="px-5 py-4 text-red-600 font-semibold">-{formatPrice(settlement.commission_amount)}</td>
                          <td className="px-5 py-4 text-emerald-600 font-black">{formatPrice(settlement.payable_amount)}</td>
                          <td className="px-5 py-4">
                            <span className={`inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider ${
                              isUnpaid ? 'bg-amber-50 text-amber-700 border border-amber-200' : 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                            }`}>
                              {isUnpaid ? <Clock className="h-3 w-3" /> : <CheckCircle2 className="h-3 w-3" />}
                              {settlement.status}
                            </span>
                            {!isUnpaid && settlement.paid_at && (
                              <p className="text-[9px] text-text-secondary mt-1">Paid: {new Date(settlement.paid_at).toLocaleDateString()}</p>
                            )}
                          </td>
                          <td className="px-5 py-4 text-right">
                            {isUnpaid ? (
                              <button
                                id={`pay-shop-${settlement.id}`}
                                onClick={() => handlePayShop(settlement.id)}
                                disabled={isPaying}
                                className="px-3.5 py-1.5 rounded-lg bg-emerald-500 hover:bg-emerald-600 text-white text-xs font-bold transition-all disabled:opacity-60 cursor-pointer shadow-sm"
                              >
                                {isPaying ? 'Processing...' : 'Release Payout'}
                              </button>
                            ) : (
                              <span className="text-xs text-text-secondary italic">Processed</span>
                            )}
                          </td>
                        </tr>
                      );
                    })
                  )}
                </tbody>
              </table>
            </div>
          </div>

          {/* Rider Settlements */}
          <div className="rounded-2xl border border-border-card bg-panel overflow-hidden">
            <div className="px-5 py-4 border-b border-border-card flex items-center justify-between">
              <div>
                <h3 className="font-bold text-text-primary text-sm">Rider Settlements Queue</h3>
                <p className="text-xs text-text-secondary mt-0.5">Disburse delivery fees and settle cash collections with active riders.</p>
              </div>
              <span className="px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-amber-550 text-amber-700 border border-amber-200">
                {riderSettlements.filter(r => r.status === 'pending').length} Pending
              </span>
            </div>
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-border-card bg-hover-panel/40">
                    <th className="px-5 py-3 text-left text-xs font-bold text-text-secondary uppercase">Rider Identity</th>
                    <th className="px-5 py-3 text-left text-xs font-bold text-text-secondary uppercase">Runs Count</th>
                    <th className="px-5 py-3 text-left text-xs font-bold text-text-secondary uppercase">COD Collected</th>
                    <th className="px-5 py-3 text-left text-xs font-bold text-text-secondary uppercase">Earnings Amount</th>
                    <th className="px-5 py-3 text-left text-xs font-bold text-text-secondary uppercase">Status</th>
                    <th className="px-5 py-3 text-right text-xs font-bold text-text-secondary uppercase">Payout</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-border-card">
                  {riderSettlements.length === 0 ? (
                    <tr>
                      <td colSpan={6} className="px-5 py-8 text-center text-text-secondary">No rider settlements found.</td>
                    </tr>
                  ) : (
                    riderSettlements.map(settlement => {
                      const isPending = settlement.status === 'pending';
                      const isPaying = payingRiderId === settlement.id;
                      return (
                        <tr key={settlement.id} className="hover:bg-hover-panel/30 transition-colors">
                          <td className="px-5 py-4">
                            <div className="font-bold text-text-primary text-sm">{settlement.rider_name || `Rider #${settlement.rider_id}`}</div>
                            <div className="text-xs text-text-secondary">{settlement.rider_phone}</div>
                          </td>
                          <td className="px-5 py-4 text-text-primary font-semibold">{settlement.deliveries_count} Deliveries</td>
                          <td className="px-5 py-4 text-rose-600 font-bold">{formatPrice(settlement.cod_collected)}</td>
                          <td className="px-5 py-4 text-emerald-600 font-black">{formatPrice(settlement.earnings_amount)}</td>
                          <td className="px-5 py-4">
                            <span className={`inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider ${
                              isPending ? 'bg-amber-50 text-amber-700 border border-amber-200' : 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                            }`}>
                              {isPending ? <Clock className="h-3 w-3" /> : <CheckCircle2 className="h-3 w-3" />}
                              {isPending ? 'Pending' : 'Settled'}
                            </span>
                            {!isPending && settlement.paid_at && (
                              <p className="text-[9px] text-text-secondary mt-1">Paid: {new Date(settlement.paid_at).toLocaleDateString()}</p>
                            )}
                          </td>
                          <td className="px-5 py-4 text-right">
                            {isPending ? (
                              <button
                                id={`pay-rider-${settlement.id}`}
                                onClick={() => handlePayRider(settlement.id)}
                                disabled={isPaying}
                                className="px-3.5 py-1.5 rounded-lg bg-emerald-500 hover:bg-emerald-600 text-white text-xs font-bold transition-all disabled:opacity-60 cursor-pointer shadow-sm"
                              >
                                {isPaying ? 'Processing...' : 'Settle & Disburse'}
                              </button>
                            ) : (
                              <span className="text-xs text-text-secondary italic">Processed</span>
                            )}
                          </td>
                        </tr>
                      );
                    })
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
