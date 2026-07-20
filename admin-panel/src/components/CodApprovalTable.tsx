import { useState, useEffect, useCallback } from 'react';
import { getAdminHeaders, getBackendUrl } from '../utils/config';
import { showToast } from '../utils/alerts';
import {
  ShieldAlert,
  CheckCircle2,
  XCircle,
  Clock,
  RefreshCcw,
  Wallet,
  User,
  Bike,
  Package,
  AlertTriangle,
  ChevronDown,
  Settings2,
} from 'lucide-react';

interface CodRequest {
  id: number;
  order_id: number;
  rider_id: number;
  rider_name: string;
  rider_phone: string;
  customer_name: string;
  order_total: number;
  delivery_address: string;
  amount: number;
  status: 'pending' | 'approved' | 'rejected';
  approved_by: string | null;
  approved_at: string | null;
  reject_reason: string | null;
  rider_cod_limit: number | null;
  created_at: string;
}

interface Rider {
  id: number;
  name: string;
  phone: string;
}

const statusConfig = {
  pending: {
    label: 'Pending',
    icon: Clock,
    bg: 'bg-amber-50',
    text: 'text-amber-700',
    border: 'border-amber-200',
    dot: 'bg-amber-400',
  },
  approved: {
    label: 'Approved',
    icon: CheckCircle2,
    bg: 'bg-emerald-50',
    text: 'text-emerald-700',
    border: 'border-emerald-200',
    dot: 'bg-emerald-400',
  },
  rejected: {
    label: 'Rejected',
    icon: XCircle,
    bg: 'bg-red-50',
    text: 'text-red-700',
    border: 'border-red-200',
    dot: 'bg-red-400',
  },
};

const PRESET_LIMITS = [0, 5000, 10000, 15000, 25000];

export default function CodApprovalTable() {
  const [requests, setRequests] = useState<CodRequest[]>([]);
  const [riders, setRiders] = useState<Rider[]>([]);
  const [loading, setLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState<string>('');
  const [actionLoading, setActionLoading] = useState<number | null>(null);
  const [activeTab, setActiveTab] = useState<'queue' | 'limits'>('queue');
  const [riderLimits, setRiderLimits] = useState<Record<number, number>>({});
  const [customInputs, setCustomInputs] = useState<Record<number, string>>({});
  const [limitSaving, setLimitSaving] = useState<number | null>(null);

  const headers = getAdminHeaders();
  const backendUrl = getBackendUrl();

  const fetchRequests = useCallback(async () => {
    setLoading(true);
    try {
      const url = statusFilter
        ? `${backendUrl}/api/v1/admin/cod/approval-requests?status=${statusFilter}`
        : `${backendUrl}/api/v1/admin/cod/approval-requests`;
      const res = await fetch(url, { headers: { ...headers, 'bypass-tunnel-reminder': 'true' } });
      const json = await res.json();
      if (json.success) setRequests(json.data);
    } catch {
      showToast('error', 'Failed to load COD approval queue.');
    } finally {
      setLoading(false);
    }
  }, [statusFilter, backendUrl]);

  const fetchRiders = useCallback(async () => {
    try {
      const res = await fetch(`${backendUrl}/api/v1/admin/riders`, {
        headers: { ...headers, 'bypass-tunnel-reminder': 'true' },
      });
      const json = await res.json();
      if (json.success && Array.isArray(json.data)) {
        setRiders(json.data);
        const limits: Record<number, number> = {};
        await Promise.all(
          json.data.map(async (r: Rider) => {
            try {
              const lr = await fetch(`${backendUrl}/api/v1/admin/riders/${r.id}/cod-limit`, {
                headers: { ...headers, 'bypass-tunnel-reminder': 'true' },
              });
              const lj = await lr.json();
              limits[r.id] = parseFloat(lj.data?.cod_limit ?? 5000);
            } catch {
              limits[r.id] = 5000;
            }
          })
        );
        setRiderLimits(limits);
      }
    } catch {
      showToast('error', 'Failed to load riders.');
    }
  }, [backendUrl]);

  useEffect(() => { fetchRequests(); }, [fetchRequests]);
  useEffect(() => { if (activeTab === 'limits') fetchRiders(); }, [activeTab, fetchRiders]);

  const handleApprove = async (id: number) => {
    setActionLoading(id);
    try {
      const res = await fetch(`${backendUrl}/api/v1/admin/cod/approval-requests/${id}/approve`, {
        method: 'PATCH',
        headers: { ...headers, 'bypass-tunnel-reminder': 'true' },
      });
      const json = await res.json();
      if (json.success) {
        showToast('success', 'COD request approved. Rider can now accept the order.');
        fetchRequests();
      } else {
        showToast('error', json.message || 'Failed to approve.');
      }
    } catch {
      showToast('error', 'Network error while approving.');
    } finally {
      setActionLoading(null);
    }
  };

  const handleReject = async (id: number) => {
    const reason = prompt('Enter rejection reason (optional):') ?? 'Rejected by admin';
    setActionLoading(id);
    try {
      const res = await fetch(`${backendUrl}/api/v1/admin/cod/approval-requests/${id}/reject`, {
        method: 'PATCH',
        headers: { ...headers, 'Content-Type': 'application/json', 'bypass-tunnel-reminder': 'true' },
        body: JSON.stringify({ reason }),
      });
      const json = await res.json();
      if (json.success) {
        showToast('success', 'COD request rejected.');
        fetchRequests();
      } else {
        showToast('error', json.message || 'Failed to reject.');
      }
    } catch {
      showToast('error', 'Network error while rejecting.');
    } finally {
      setActionLoading(null);
    }
  };

  const handleSetLimit = async (riderId: number, limit: number) => {
    setLimitSaving(riderId);
    try {
      const res = await fetch(`${backendUrl}/api/v1/admin/riders/${riderId}/cod-limit`, {
        method: 'PUT',
        headers: { ...headers, 'Content-Type': 'application/json', 'bypass-tunnel-reminder': 'true' },
        body: JSON.stringify({ cod_limit: limit }),
      });
      const json = await res.json();
      if (json.success) {
        setRiderLimits(prev => ({ ...prev, [riderId]: limit }));
        showToast('success', `COD limit set to Rs. ${limit.toLocaleString()} for rider.`);
      } else {
        showToast('error', json.message || 'Failed to update limit.');
      }
    } catch {
      showToast('error', 'Network error updating COD limit.');
    } finally {
      setLimitSaving(null);
    }
  };

  const pendingCount = requests.filter(r => r.status === 'pending').length;

  return (
    <div className="space-y-5">
      {/* Page Header */}
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div className="flex items-center gap-3">
          <div className="flex h-11 w-11 items-center justify-center rounded-xl bg-orange-100 border border-orange-200">
            <ShieldAlert className="h-6 w-6 text-orange-600" />
          </div>
          <div>
            <h2 className="text-xl font-bold text-text-primary">COD Risk Management</h2>
            <p className="text-sm text-text-secondary">Manage high-value cash-on-delivery requests & rider limits</p>
          </div>
        </div>
        <button
          onClick={activeTab === 'queue' ? fetchRequests : fetchRiders}
          className="flex items-center gap-2 px-4 py-2 rounded-xl border border-border-card bg-panel text-text-secondary hover:bg-hover-panel text-sm font-semibold transition-all cursor-pointer"
        >
          <RefreshCcw className="h-4 w-4" />
          Refresh
        </button>
      </div>

      {/* Tabs */}
      <div className="flex gap-2 border-b border-border-card">
        <button
          id="cod-tab-queue"
          onClick={() => setActiveTab('queue')}
          className={`px-5 py-2.5 text-sm font-bold rounded-t-lg transition-all cursor-pointer ${
            activeTab === 'queue'
              ? 'bg-panel border border-b-0 border-border-card text-text-primary'
              : 'text-text-secondary hover:text-text-primary'
          }`}
        >
          Approval Queue
          {pendingCount > 0 && (
            <span className="ml-2 px-2 py-0.5 rounded-full text-[10px] font-black bg-orange-500 text-white">
              {pendingCount}
            </span>
          )}
        </button>
        <button
          id="cod-tab-limits"
          onClick={() => setActiveTab('limits')}
          className={`flex items-center gap-1.5 px-5 py-2.5 text-sm font-bold rounded-t-lg transition-all cursor-pointer ${
            activeTab === 'limits'
              ? 'bg-panel border border-b-0 border-border-card text-text-primary'
              : 'text-text-secondary hover:text-text-primary'
          }`}
        >
          <Settings2 className="h-4 w-4" />
          Rider COD Limits
        </button>
      </div>

      {/* ── APPROVAL QUEUE TAB ─────────────────── */}
      {activeTab === 'queue' && (
        <div className="space-y-4">
          {/* Status filter */}
          <div className="relative inline-block">
            <select
              id="cod-status-filter"
              value={statusFilter}
              onChange={e => setStatusFilter(e.target.value)}
              className="appearance-none pl-3 pr-8 py-2 rounded-xl border border-border-card bg-panel text-sm font-semibold text-text-primary cursor-pointer focus:outline-none focus:ring-2 focus:ring-orange-500/30"
            >
              <option value="">All Status</option>
              <option value="pending">Pending</option>
              <option value="approved">Approved</option>
              <option value="rejected">Rejected</option>
            </select>
            <ChevronDown className="absolute right-2 top-1/2 -translate-y-1/2 h-4 w-4 text-text-secondary pointer-events-none" />
          </div>

          {/* Summary stats */}
          <div className="grid grid-cols-3 gap-4">
            {(['pending', 'approved', 'rejected'] as const).map(s => {
              const cfg = statusConfig[s];
              const count = requests.filter(r => r.status === s).length;
              const Icon = cfg.icon;
              return (
                <div key={s} className={`flex items-center gap-3 p-4 rounded-xl border ${cfg.bg} ${cfg.border}`}>
                  <Icon className={`h-5 w-5 ${cfg.text}`} />
                  <div>
                    <p className={`text-xl font-black ${cfg.text}`}>{count}</p>
                    <p className={`text-xs font-semibold ${cfg.text} opacity-80`}>{cfg.label}</p>
                  </div>
                </div>
              );
            })}
          </div>

          {/* Table */}
          <div className="rounded-2xl border border-border-card bg-panel overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-border-card bg-hover-panel/40">
                    <th className="px-5 py-3.5 text-left text-xs font-bold text-text-secondary uppercase tracking-wider">Order ID</th>
                    <th className="px-5 py-3.5 text-left text-xs font-bold text-text-secondary uppercase tracking-wider">COD Amount</th>
                    <th className="px-5 py-3.5 text-left text-xs font-bold text-text-secondary uppercase tracking-wider">Customer</th>
                    <th className="px-5 py-3.5 text-left text-xs font-bold text-text-secondary uppercase tracking-wider">Rider</th>
                    <th className="px-5 py-3.5 text-left text-xs font-bold text-text-secondary uppercase tracking-wider">Risk Status</th>
                    <th className="px-5 py-3.5 text-left text-xs font-bold text-text-secondary uppercase tracking-wider">Submitted</th>
                    <th className="px-5 py-3.5 text-right text-xs font-bold text-text-secondary uppercase tracking-wider">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-border-card">
                  {loading ? (
                    <tr>
                      <td colSpan={7} className="px-5 py-12 text-center">
                        <div className="flex flex-col items-center gap-3">
                          <div className="h-8 w-8 rounded-full border-4 border-orange-500/30 border-t-orange-500 animate-spin" />
                          <p className="text-sm text-text-secondary font-medium">Loading COD queue...</p>
                        </div>
                      </td>
                    </tr>
                  ) : requests.length === 0 ? (
                    <tr>
                      <td colSpan={7} className="px-5 py-16 text-center">
                        <div className="flex flex-col items-center gap-3">
                          <div className="h-14 w-14 rounded-2xl bg-orange-50 flex items-center justify-center border border-orange-100">
                            <ShieldAlert className="h-7 w-7 text-orange-400" />
                          </div>
                          <p className="font-bold text-text-primary">No COD requests found</p>
                          <p className="text-sm text-text-secondary">
                            {statusFilter ? `No ${statusFilter} requests` : 'No COD approval requests yet'}
                          </p>
                        </div>
                      </td>
                    </tr>
                  ) : (
                    requests.map(req => {
                      const cfg = statusConfig[req.status] ?? statusConfig.pending;
                      const Icon = cfg.icon;
                      const riderLimit = req.rider_cod_limit ?? 5000;
                      const excess = parseFloat(String(req.amount)) - riderLimit;
                      const isLoading = actionLoading === req.id;

                      return (
                        <tr key={req.id} className="hover:bg-hover-panel/30 transition-colors">
                          <td className="px-5 py-4">
                            <div className="flex items-center gap-2">
                              <Package className="h-4 w-4 text-text-secondary" />
                              <span className="font-bold text-text-primary text-xs">#{req.order_id}</span>
                            </div>
                          </td>
                          <td className="px-5 py-4">
                            <div className="flex flex-col gap-1">
                              <span className="font-black text-text-primary text-sm">
                                Rs. {parseFloat(String(req.amount)).toLocaleString()}
                              </span>
                              {excess > 0 && (
                                <span className="flex items-center gap-1 text-[10px] font-bold text-red-600 bg-red-50 px-2 py-0.5 rounded-full border border-red-100 w-fit">
                                  <AlertTriangle className="h-3 w-3" />
                                  +Rs. {excess.toLocaleString()} over limit
                                </span>
                              )}
                            </div>
                          </td>
                          <td className="px-5 py-4">
                            <div className="flex items-center gap-2">
                              <User className="h-4 w-4 text-text-secondary shrink-0" />
                              <div>
                                <p className="font-semibold text-text-primary text-xs">{req.customer_name || 'Unknown'}</p>
                                <p className="text-[10px] text-text-secondary truncate max-w-[140px]">{req.delivery_address || '—'}</p>
                              </div>
                            </div>
                          </td>
                          <td className="px-5 py-4">
                            <div className="flex items-center gap-2">
                              <Bike className="h-4 w-4 text-text-secondary shrink-0" />
                              <div>
                                <p className="font-semibold text-text-primary text-xs">{req.rider_name || `Rider #${req.rider_id}`}</p>
                                <p className="text-[10px] text-text-secondary">Limit: Rs. {riderLimit.toLocaleString()}</p>
                              </div>
                            </div>
                          </td>
                          <td className="px-5 py-4">
                            <span className={`inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-[11px] font-bold border ${cfg.bg} ${cfg.text} ${cfg.border}`}>
                              <span className={`h-1.5 w-1.5 rounded-full ${cfg.dot}`} />
                              <Icon className="h-3 w-3" />
                              {cfg.label}
                            </span>
                            {req.approved_by && (
                              <p className="text-[10px] text-text-secondary mt-1">by {req.approved_by}</p>
                            )}
                          </td>
                          <td className="px-5 py-4 text-xs text-text-secondary whitespace-nowrap">
                            {new Date(req.created_at).toLocaleDateString('en-PK', {
                              day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit',
                            })}
                          </td>
                          <td className="px-5 py-4 text-right">
                            {req.status === 'pending' ? (
                              <div className="flex items-center justify-end gap-2">
                                <button
                                  id={`cod-approve-${req.id}`}
                                  onClick={() => handleApprove(req.id)}
                                  disabled={isLoading}
                                  className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-emerald-500 hover:bg-emerald-600 text-white text-xs font-bold transition-all disabled:opacity-60 cursor-pointer"
                                >
                                  {isLoading
                                    ? <div className="h-3.5 w-3.5 rounded-full border-2 border-white/30 border-t-white animate-spin" />
                                    : <CheckCircle2 className="h-3.5 w-3.5" />}
                                  Approve
                                </button>
                                <button
                                  id={`cod-reject-${req.id}`}
                                  onClick={() => handleReject(req.id)}
                                  disabled={isLoading}
                                  className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-red-100 hover:bg-red-200 text-red-700 text-xs font-bold transition-all disabled:opacity-60 cursor-pointer border border-red-200"
                                >
                                  <XCircle className="h-3.5 w-3.5" />
                                  Reject
                                </button>
                              </div>
                            ) : (
                              <span className="text-xs text-text-secondary italic">
                                {req.status === 'approved' ? '✓ Processed' : '✗ Rejected'}
                              </span>
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

      {/* ── RIDER COD LIMITS TAB ───────────────── */}
      {activeTab === 'limits' && (
        <div className="space-y-4">
          <div className="rounded-2xl border border-border-card bg-panel overflow-hidden">
            <div className="px-5 py-4 border-b border-border-card flex items-center gap-3">
              <Wallet className="h-5 w-5 text-orange-500" />
              <div>
                <p className="font-bold text-text-primary">Rider COD Limits</p>
                <p className="text-xs text-text-secondary">
                  Set the maximum cash-on-delivery amount each rider can accept without admin approval.
                </p>
              </div>
            </div>
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-border-card bg-hover-panel/40">
                    <th className="px-5 py-3.5 text-left text-xs font-bold text-text-secondary uppercase tracking-wider">Rider</th>
                    <th className="px-5 py-3.5 text-left text-xs font-bold text-text-secondary uppercase tracking-wider">Current Limit</th>
                    <th className="px-5 py-3.5 text-left text-xs font-bold text-text-secondary uppercase tracking-wider">Set New Limit</th>
                    <th className="px-5 py-3.5 text-right text-xs font-bold text-text-secondary uppercase tracking-wider">Save</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-border-card">
                  {riders.length === 0 ? (
                    <tr>
                      <td colSpan={4} className="px-5 py-12 text-center text-text-secondary text-sm">No riders found.</td>
                    </tr>
                  ) : (
                    riders.map(rider => {
                      const currentLimit = riderLimits[rider.id] ?? 5000;
                      const isSaving = limitSaving === rider.id;
                      return (
                        <tr key={rider.id} className="hover:bg-hover-panel/30 transition-colors">
                          <td className="px-5 py-4">
                            <div className="flex items-center gap-3">
                              <div className="h-9 w-9 rounded-full bg-orange-50 border border-orange-100 flex items-center justify-center">
                                <Bike className="h-5 w-5 text-orange-500" />
                              </div>
                              <div>
                                <p className="font-bold text-text-primary text-sm">{rider.name}</p>
                                <p className="text-xs text-text-secondary">{rider.phone}</p>
                              </div>
                            </div>
                          </td>
                          <td className="px-5 py-4">
                            <span className="px-3 py-1.5 rounded-lg bg-orange-50 border border-orange-100 text-orange-700 font-black text-sm">
                              Rs. {currentLimit.toLocaleString()}
                            </span>
                          </td>
                          <td className="px-5 py-4">
                            <div className="flex items-center gap-2 flex-wrap">
                              {PRESET_LIMITS.map(preset => (
                                <button
                                  key={preset}
                                  id={`limit-preset-${rider.id}-${preset}`}
                                  onClick={() => setRiderLimits(prev => ({ ...prev, [rider.id]: preset }))}
                                  className={`px-3 py-1.5 rounded-lg text-xs font-bold border transition-all cursor-pointer ${
                                    currentLimit === preset
                                      ? 'bg-orange-500 text-white border-orange-500'
                                      : 'bg-panel text-text-secondary border-border-card hover:border-orange-300 hover:text-orange-600'
                                  }`}
                                >
                                  {preset === 0 ? 'Rs. 0' : `Rs. ${(preset / 1000).toFixed(0)}k`}
                                </button>
                              ))}
                              <input
                                id={`limit-custom-${rider.id}`}
                                type="number"
                                placeholder="Custom"
                                min={0}
                                value={customInputs[rider.id] ?? ''}
                                onChange={e => {
                                  const val = e.target.value;
                                  setCustomInputs(prev => ({ ...prev, [rider.id]: val }));
                                  if (val) setRiderLimits(prev => ({ ...prev, [rider.id]: parseFloat(val) }));
                                }}
                                className="w-24 px-3 py-1.5 rounded-lg border border-border-card bg-panel text-text-primary text-xs font-semibold focus:outline-none focus:ring-2 focus:ring-orange-500/30 focus:border-orange-400"
                              />
                            </div>
                          </td>
                          <td className="px-5 py-4 text-right">
                            <button
                              id={`limit-save-${rider.id}`}
                              onClick={() => handleSetLimit(rider.id, currentLimit)}
                              disabled={isSaving}
                              className="flex items-center gap-2 px-4 py-2 rounded-xl bg-orange-500 hover:bg-orange-600 text-white text-xs font-bold transition-all disabled:opacity-60 cursor-pointer ml-auto"
                            >
                              {isSaving
                                ? <div className="h-3.5 w-3.5 rounded-full border-2 border-white/30 border-t-white animate-spin" />
                                : <CheckCircle2 className="h-3.5 w-3.5" />}
                              Save
                            </button>
                          </td>
                        </tr>
                      );
                    })
                  )}
                </tbody>
              </table>
            </div>
          </div>

          {/* Policy note */}
          <div className="flex items-start gap-3 p-4 rounded-xl border border-amber-200 bg-amber-50">
            <AlertTriangle className="h-5 w-5 text-amber-600 shrink-0 mt-0.5" />
            <div>
              <p className="font-bold text-amber-800 text-sm">COD Risk Policy</p>
              <p className="text-xs text-amber-700 mt-1 leading-relaxed">
                If a rider's COD limit is <strong>Rs. 0</strong>, they must request admin approval for ALL COD orders.
                Approvals are <strong>per-order</strong> and do not permanently raise the rider's limit.
                A rider with a Rs. 5,000 limit cannot accept a Rs. 15,000 COD order without admin clearance.
              </p>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
