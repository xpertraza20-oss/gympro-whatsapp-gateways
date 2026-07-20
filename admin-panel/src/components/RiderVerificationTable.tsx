import { useState, useEffect } from 'react';
import { 
  ShieldCheck, 
  Search, 
  RefreshCw, 
  Check, 
  X, 
  AlertCircle, 
  Eye, 
  Truck, 
  MapPin, 
  CreditCard, 
  FileText,
  AlertTriangle
} from 'lucide-react';
import { getAdminHeaders, getBackendUrl } from '../utils/config';
import { getSwal, showToast } from '../utils/alerts';

interface Rider {
  id: number;
  user_id: number;
  vehicle_type: string;
  vehicle_number: string;
  cnic: string; // May contain parsed layout e.g. "35201-1234567-1 | Details: Cycle/Bike: motorbike | No: ABC-123 | Bank: Account Details"
  status: string; // offline, online, busy
  verification_status: string; // 'pending', 'approved', 'rejected', 'suspended'
  current_location: string | null;
  created_at: string;
  rider_name: string;
  rider_phone: string;
  rider_email: string;
  rejection_reason: string | null;
  suspension_reason: string | null;
}

export default function RiderVerificationTable() {
  const [riders, setRiders] = useState<Rider[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('all'); // all, pending, approved, rejected, suspended
  
  // Details drawer state
  const [selectedRider, setSelectedRider] = useState<Rider | null>(null);
  const [isDetailsOpen, setIsDetailsOpen] = useState(false);

  const fetchRiders = async () => {
    setLoading(true);
    setError(null);
    try {
      const headers = getAdminHeaders(true);
      const backendUrl = getBackendUrl();
      const res = await fetch(`${backendUrl}/api/v1/admin/riders`, {
        method: 'GET',
        headers
      });

      if (!res.ok) {
        throw new Error(`Server returned status: ${res.status}`);
      }

      const json = await res.json();
      if (json.success && Array.isArray(json.data)) {
        setRiders(json.data);
      } else {
        throw new Error(json.message || 'Invalid riders data structure');
      }
    } catch (err: any) {
      console.error('Error fetching riders:', err);
      setError(err.message || 'Failed to connect to the backend server.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchRiders();
  }, []);

  const handleApprove = async (rider: Rider) => {
    const swal = getSwal();
    const confirm = await swal.fire({
      title: 'Approve Rider?',
      text: `Are you sure you want to approve "${rider.rider_name}"? This allows them to receive delivery requests.`,
      icon: 'question',
      showCancelButton: true,
      confirmButtonText: 'Yes, Approve',
      confirmButtonColor: '#006b56',
      cancelButtonColor: '#cbd5e1'
    });

    if (!confirm.isConfirmed) return;

    try {
      const res = await fetch(`${getBackendUrl()}/api/v1/admin/riders/${rider.id}/approve`, {
        method: 'PATCH',
        headers: getAdminHeaders(true)
      });
      const json = await res.json();
      if (res.ok && json.success) {
        showToast('success', 'Rider approved successfully!');
        fetchRiders();
        if (selectedRider?.id === rider.id) {
          setSelectedRider(prev => prev ? { ...prev, verification_status: 'approved', is_approved: true } : null);
        }
      } else {
        swal.fire('Error', json.message || 'Failed to approve rider.', 'error');
      }
    } catch (err: any) {
      swal.fire('Error', 'Connection failed.', 'error');
    }
  };

  const handleReject = async (rider: Rider) => {
    const swal = getSwal();
    const { value: reason } = await swal.fire({
      title: 'Reject Rider Profile',
      input: 'textarea',
      inputLabel: 'Reason for Rejection',
      inputPlaceholder: 'Describe why the documents or vehicle profile was rejected...',
      showCancelButton: true,
      confirmButtonText: 'Submit Rejection',
      confirmButtonColor: '#ba1a1a',
      cancelButtonColor: '#cbd5e1',
      inputValidator: (value) => {
        if (!value) {
          return 'Rejection reason is required!';
        }
        return null;
      }
    });

    if (!reason) return;

    try {
      const res = await fetch(`${getBackendUrl()}/api/v1/admin/riders/${rider.id}/reject`, {
        method: 'PATCH',
        headers: getAdminHeaders(true),
        body: JSON.stringify({ reason })
      });
      const json = await res.json();
      if (res.ok && json.success) {
        showToast('success', 'Rider application rejected.');
        fetchRiders();
        if (selectedRider?.id === rider.id) {
          setSelectedRider(prev => prev ? { ...prev, verification_status: 'rejected', rejection_reason: reason } : null);
        }
      } else {
        swal.fire('Error', json.message || 'Failed to reject rider.', 'error');
      }
    } catch (err: any) {
      swal.fire('Error', 'Connection failed.', 'error');
    }
  };

  const handleSuspend = async (rider: Rider) => {
    const swal = getSwal();
    const { value: reason } = await swal.fire({
      title: 'Suspend Rider Account',
      input: 'textarea',
      inputLabel: 'Reason for Suspension',
      inputPlaceholder: 'Describe why the rider is being suspended (e.g. poor rating, policy violation)...',
      showCancelButton: true,
      confirmButtonText: 'Suspend Rider',
      confirmButtonColor: '#d97706',
      cancelButtonColor: '#cbd5e1',
      inputValidator: (value) => {
        if (!value) {
          return 'Suspension reason is required!';
        }
        return null;
      }
    });

    if (!reason) return;

    try {
      const res = await fetch(`${getBackendUrl()}/api/v1/admin/riders/${rider.id}/suspend`, {
        method: 'PATCH',
        headers: getAdminHeaders(true),
        body: JSON.stringify({ reason })
      });
      const json = await res.json();
      if (res.ok && json.success) {
        showToast('success', 'Rider account suspended.');
        fetchRiders();
        if (selectedRider?.id === rider.id) {
          setSelectedRider(prev => prev ? { ...prev, verification_status: 'suspended', suspension_reason: reason } : null);
        }
      } else {
        swal.fire('Error', json.message || 'Failed to suspend rider.', 'error');
      }
    } catch (err: any) {
      swal.fire('Error', 'Connection failed.', 'error');
    }
  };

  // Helper to parse complex cnic details
  const parseCnicString = (cnicVal: string) => {
    const parts = cnicVal.split('|');
    let cnicNumber = parts[0]?.trim() || 'N/A';
    
    // Look for Bank details
    let bankDetails = 'Not Provided';
    const bankIndex = parts.findIndex(p => p.toLowerCase().includes('bank:'));
    if (bankIndex !== -1) {
      bankDetails = parts[bankIndex].replace(/bank:/i, '').trim();
    }

    return { cnicNumber, bankDetails };
  };

  const filteredRiders = riders.filter(rider => {
    const matchesSearch = 
      rider.rider_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      rider.vehicle_number.toLowerCase().includes(searchTerm.toLowerCase()) ||
      rider.rider_phone.includes(searchTerm);
    
    if (statusFilter === 'all') return matchesSearch;
    return matchesSearch && rider.verification_status === statusFilter;
  });

  return (
    <div className="space-y-6">
      {/* Header title */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 bg-white/60 p-6 rounded-2xl border border-border-card/30 shadow-md">
        <div>
          <h2 className="text-xl font-black text-text-primary flex items-center gap-2">
            <ShieldCheck className="h-6 w-6 text-[#ac004d]" /> Rider Verification Portal
          </h2>
          <p className="text-xs text-text-secondary mt-1">Audit vehicle documentation, licenses, and approve or suspend couriers.</p>
        </div>
        <button 
          onClick={fetchRiders} 
          disabled={loading}
          className="flex items-center gap-2 px-4 py-2 text-xs font-bold text-white bg-[#ac004d] hover:bg-[#ac004d]/90 rounded-xl transition-all cursor-pointer disabled:opacity-50"
        >
          <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} /> Refresh Lists
        </button>
      </div>

      {/* Filter controls */}
      <div className="flex flex-col md:flex-row gap-4 justify-between items-center bg-white/40 p-4 rounded-xl border border-border-card/20">
        <div className="relative w-full md:w-80">
          <Search className="absolute left-3 top-2.5 h-4.5 w-4.5 text-text-secondary/50" />
          <input 
            type="text" 
            placeholder="Search rider name, phone, vehicle..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full pl-9 pr-4 py-2 text-xs bg-white rounded-xl border border-border-card/40 focus:outline-none focus:border-[#ac004d]"
          />
        </div>

        <div className="flex flex-wrap gap-1.5 self-stretch md:self-auto">
          {['all', 'pending', 'approved', 'rejected', 'suspended'].map((status) => (
            <button
              key={status}
              onClick={() => setStatusFilter(status)}
              className={`px-3.5 py-1.5 rounded-lg text-xs font-bold capitalize transition-all cursor-pointer ${
                statusFilter === status 
                  ? 'bg-[#ac004d] text-white shadow-md' 
                  : 'bg-white hover:bg-hover-panel/40 text-text-secondary border border-border-card/40'
              }`}
            >
              {status}
            </button>
          ))}
        </div>
      </div>

      {/* Grid table */}
      <div className="rounded-2xl glass-panel shadow-lg overflow-hidden border border-border-card/30 bg-white">
        <div className="overflow-x-auto">
          <table className="w-full text-left">
            <thead className="bg-[#fff8f7]/60 border-b border-border-card/30">
              <tr>
                <th className="px-5 py-3.5 text-xs font-bold text-text-secondary uppercase tracking-wider">Rider</th>
                <th className="px-5 py-3.5 text-xs font-bold text-text-secondary uppercase tracking-wider">Phone number</th>
                <th className="px-5 py-3.5 text-xs font-bold text-text-secondary uppercase tracking-wider">Vehicle Details</th>
                <th className="px-5 py-3.5 text-xs font-bold text-text-secondary uppercase tracking-wider">Ride Status</th>
                <th className="px-5 py-3.5 text-xs font-bold text-text-secondary uppercase tracking-wider">Verification status</th>
                <th className="px-5 py-3.5 text-xs font-bold text-text-secondary uppercase tracking-wider text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border-card/20">
              {loading ? (
                <tr>
                  <td colSpan={6} className="px-5 py-12 text-center text-xs text-text-secondary">
                    <RefreshCw className="h-8 w-8 animate-spin mx-auto text-[#ac004d] mb-2" />
                    Fetching riders records...
                  </td>
                </tr>
              ) : error ? (
                <tr>
                  <td colSpan={6} className="px-5 py-12 text-center text-xs text-red-500 font-medium">
                    <AlertCircle className="h-8 w-8 mx-auto mb-2 text-red-500" />
                    {error}
                  </td>
                </tr>
              ) : filteredRiders.length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-5 py-12 text-center text-xs text-text-secondary">
                    No riders match the active criteria.
                  </td>
                </tr>
              ) : (
                filteredRiders.map((rider) => {
                  const statusColors: Record<string, string> = {
                    pending: 'bg-amber-100 text-amber-800 border-amber-200',
                    approved: 'bg-emerald-100 text-emerald-800 border-emerald-200',
                    rejected: 'bg-red-100 text-red-800 border-red-200',
                    suspended: 'bg-slate-100 text-slate-800 border-slate-200'
                  };

                  return (
                    <tr key={rider.id} className="hover:bg-hover-panel/20 transition-colors">
                      <td className="px-5 py-4">
                        <div className="flex items-center space-x-3">
                          <div className="h-10 w-10 rounded-full bg-[#ac004d]/5 border border-[#ac004d]/10 flex items-center justify-center shrink-0 text-xs font-bold text-slate-600">
                            🚴
                          </div>
                          <div>
                            <div className="font-bold text-xs text-text-primary">{rider.rider_name}</div>
                            <div className="text-[10px] text-text-secondary mt-0.5">{rider.rider_email}</div>
                          </div>
                        </div>
                      </td>
                      <td className="px-5 py-4 text-xs text-text-secondary font-medium">
                        {rider.rider_phone}
                      </td>
                      <td className="px-5 py-4 text-xs text-text-secondary">
                        <div className="font-bold text-text-primary capitalize">{rider.vehicle_type}</div>
                        <div className="text-[10px] text-text-secondary mt-0.5 uppercase tracking-wide bg-slate-50 border border-slate-200/50 rounded px-1.5 py-0.5 inline-block font-mono">
                          {rider.vehicle_number}
                        </div>
                      </td>
                      <td className="px-5 py-4 text-xs">
                        <span className={`px-2 py-0.5 rounded text-[10px] font-bold uppercase tracking-wider ${
                          rider.status === 'online' 
                            ? 'bg-emerald-50 text-emerald-600 border border-emerald-200/50'
                            : rider.status === 'busy'
                              ? 'bg-indigo-50 text-indigo-600 border border-indigo-200/50'
                              : 'bg-slate-100 text-slate-500 border border-slate-200/50'
                        }`}>
                          {rider.status}
                        </span>
                      </td>
                      <td className="px-5 py-4 text-xs">
                        <span className={`px-2.5 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider border ${
                          statusColors[rider.verification_status || 'pending']
                        }`}>
                          {rider.verification_status || 'pending'}
                        </span>
                      </td>
                      <td className="px-5 py-4 text-right">
                        <div className="flex items-center justify-end gap-1">
                          <button 
                            onClick={() => {
                              setSelectedRider(rider);
                              setIsDetailsOpen(true);
                            }}
                            title="View Rider Details"
                            className="p-1.5 bg-slate-100 hover:bg-[#ac004d]/10 text-slate-600 hover:text-[#ac004d] rounded-lg transition-colors cursor-pointer border border-border-card/30"
                          >
                            <Eye className="h-4.5 w-4.5" />
                          </button>

                          {rider.verification_status !== 'approved' && (
                            <button 
                              onClick={() => handleApprove(rider)}
                              title="Verify Rider"
                              className="p-1.5 bg-emerald-50 hover:bg-emerald-100 text-emerald-700 rounded-lg transition-colors cursor-pointer border border-emerald-200"
                            >
                              <Check className="h-4.5 w-4.5" />
                            </button>
                          )}

                          {rider.verification_status === 'pending' && (
                            <button 
                              onClick={() => handleReject(rider)}
                              title="Reject Rider"
                              className="p-1.5 bg-red-50 hover:bg-red-100 text-red-700 rounded-lg transition-colors cursor-pointer border border-red-200"
                            >
                              <X className="h-4.5 w-4.5" />
                            </button>
                          )}

                          {rider.verification_status === 'approved' && (
                            <button 
                              onClick={() => handleSuspend(rider)}
                              title="Suspend Rider"
                              className="p-1.5 bg-amber-50 hover:bg-amber-100 text-amber-700 rounded-lg transition-colors cursor-pointer border border-amber-200"
                            >
                              <AlertTriangle className="h-4.5 w-4.5" />
                            </button>
                          )}
                        </div>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Details Slide Drawer overlay */}
      {isDetailsOpen && selectedRider && (() => {
        const parsed = parseCnicString(selectedRider.cnic);
        
        return (
          <div className="fixed inset-0 z-50 overflow-hidden" aria-labelledby="slide-over-title" role="dialog" aria-modal="true">
            <div className="absolute inset-0 overflow-hidden">
              <div 
                className="absolute inset-0 bg-slate-950/60 backdrop-blur-sm transition-opacity" 
                onClick={() => setIsDetailsOpen(false)}
              />

              <div className="pointer-events-none fixed inset-y-0 right-0 flex max-w-full pl-10">
                <div className="pointer-events-auto w-screen max-w-md">
                  <div className="flex h-full flex-col overflow-y-scroll bg-white shadow-2xl border-l border-border-card/40">
                    
                    {/* Header */}
                    <div className="bg-[#fff8f7] px-6 py-5 border-b border-border-card/30 flex items-center justify-between">
                      <div className="flex items-center space-x-2.5">
                        <ShieldCheck className="h-5 w-5 text-[#ac004d]" />
                        <h2 className="text-sm font-bold text-text-primary uppercase tracking-wider">Rider Profile Audit</h2>
                      </div>
                      <button 
                        onClick={() => setIsDetailsOpen(false)}
                        className="rounded-lg p-1.5 text-slate-500 hover:bg-slate-100 hover:text-slate-700 cursor-pointer"
                      >
                        <X className="h-5 w-5" />
                      </button>
                    </div>

                    {/* Scrollable details body */}
                    <div className="flex-1 px-6 py-6 space-y-6">
                      
                      {/* Avatar placeholder card */}
                      <div className="flex items-center space-x-4 bg-[#fff8f7]/40 p-4 rounded-xl border border-border-card/20">
                        <div className="h-16 w-16 rounded-full bg-[#ac004d]/5 border-2 border-[#ac004d]/10 flex items-center justify-center text-3xl shrink-0 overflow-hidden">
                          🧔
                        </div>
                        <div className="min-w-0">
                          <h3 className="font-bold text-sm text-text-primary truncate">{selectedRider.rider_name}</h3>
                          <span className="text-[10px] font-bold text-text-secondary/70 tracking-wider uppercase block mt-0.5">{selectedRider.rider_phone}</span>
                          <span className={`px-2 py-0.5 rounded text-[9px] font-bold uppercase tracking-wider border bg-white mt-1.5 inline-block ${
                            selectedRider.verification_status === 'approved' 
                              ? 'text-emerald-700 border-emerald-200'
                              : 'text-amber-700 border-amber-200'
                          }`}>
                            {selectedRider.verification_status}
                          </span>
                        </div>
                      </div>

                      {/* Document Details: CNIC */}
                      <div className="space-y-3.5">
                        <div className="flex items-center space-x-1.5 border-b border-border-card/20 pb-2">
                          <FileText className="h-4.5 w-4.5 text-[#ac004d]" />
                          <h4 className="text-xs font-bold text-text-primary uppercase tracking-wider">Government ID (CNIC)</h4>
                        </div>
                        <div className="text-xs">
                          <span className="text-text-secondary/70 block">CNIC Number</span>
                          <span className="font-mono font-bold text-text-primary bg-slate-50 p-2 rounded border border-slate-200/50 mt-1 block select-all">
                            {parsed.cnicNumber}
                          </span>
                        </div>
                      </div>

                      {/* Grid cards for document images */}
                      <div className="grid grid-cols-2 gap-4">
                        <div>
                          <span className="text-[10px] font-bold text-text-secondary uppercase block mb-1.5">CNIC Front image</span>
                          <div className="h-24 rounded-lg border border-dashed border-border-card bg-slate-50 flex flex-col items-center justify-center text-slate-400 text-center p-2">
                            <span className="text-2xl mb-1">🪪</span>
                            <span className="text-[9px] font-bold text-slate-500 uppercase tracking-wider">CNIC Front</span>
                            <span className="text-[7px] text-slate-400 mt-0.5">Verified</span>
                          </div>
                        </div>
                        <div>
                          <span className="text-[10px] font-bold text-text-secondary uppercase block mb-1.5">CNIC Back image</span>
                          <div className="h-24 rounded-lg border border-dashed border-border-card bg-slate-50 flex flex-col items-center justify-center text-slate-400 text-center p-2">
                            <span className="text-2xl mb-1">🪪</span>
                            <span className="text-[9px] font-bold text-slate-500 uppercase tracking-wider">CNIC Back</span>
                            <span className="text-[7px] text-slate-400 mt-0.5">Verified</span>
                          </div>
                        </div>
                        <div>
                          <span className="text-[10px] font-bold text-text-secondary uppercase block mb-1.5">Selfie Profile</span>
                          <div className="h-24 rounded-lg border border-dashed border-border-card bg-slate-50 flex flex-col items-center justify-center text-slate-400 text-center p-2">
                            <span className="text-2xl mb-1">📸</span>
                            <span className="text-[9px] font-bold text-slate-500 uppercase tracking-wider">Selfie Upload</span>
                            <span className="text-[7px] text-slate-400 mt-0.5">Verified</span>
                          </div>
                        </div>
                        <div>
                          <span className="text-[10px] font-bold text-text-secondary uppercase block mb-1.5">Driving License</span>
                          <div className="h-24 rounded-lg border border-dashed border-border-card bg-slate-50 flex flex-col items-center justify-center text-slate-400 text-center p-2">
                            <span className="text-2xl mb-1">💳</span>
                            <span className="text-[9px] font-bold text-slate-500 uppercase tracking-wider">Driving License</span>
                            <span className="text-[7px] text-slate-400 mt-0.5">Verified</span>
                          </div>
                        </div>
                      </div>

                      {/* Section 2: Vehicle details */}
                      <div className="space-y-3.5">
                        <div className="flex items-center space-x-1.5 border-b border-border-card/20 pb-2">
                          <Truck className="h-4.5 w-4.5 text-[#ac004d]" />
                          <h4 className="text-xs font-bold text-text-primary uppercase tracking-wider">Vehicle & Route Info</h4>
                        </div>
                        <div className="grid grid-cols-2 gap-y-3 gap-x-4 text-xs">
                          <div>
                            <span className="text-text-secondary/70 block">Vehicle Type</span>
                            <span className="font-bold text-text-primary mt-0.5 block capitalize">{selectedRider.vehicle_type}</span>
                          </div>
                          <div>
                            <span className="text-text-secondary/70 block">Vehicle Number</span>
                            <span className="font-mono font-bold text-text-primary uppercase mt-0.5 block">{selectedRider.vehicle_number}</span>
                          </div>
                          <div className="col-span-2">
                            <span className="text-text-secondary/70 block">Base GPS Coordinate Location</span>
                            <div className="flex items-center gap-1.5 text-text-primary font-bold mt-1">
                              <MapPin className="h-4 w-4 text-[#ac004d]" />
                              <span className="select-all font-mono">{selectedRider.current_location || '31.4800, 74.3200'}</span>
                            </div>
                          </div>
                        </div>
                      </div>

                      {/* Section 3: Financials/Payouts */}
                      <div className="space-y-3.5">
                        <div className="flex items-center space-x-1.5 border-b border-border-card/20 pb-2">
                          <CreditCard className="h-4.5 w-4.5 text-[#ac004d]" />
                          <h4 className="text-xs font-bold text-text-primary uppercase tracking-wider">Payout details</h4>
                        </div>
                        <div className="text-xs">
                          <span className="text-text-secondary/70 block">Payment Method details</span>
                          <span className="text-text-primary font-bold mt-1 block bg-slate-50 p-2 border border-slate-200/50 rounded">
                            {parsed.bankDetails}
                          </span>
                        </div>
                      </div>

                      {/* Error log reports */}
                      {selectedRider.rejection_reason && (
                        <div className="bg-red-50 p-4 rounded-xl border border-red-200 text-xs">
                          <span className="font-bold text-red-800 uppercase block mb-1">Rejection Reason:</span>
                          <span className="text-red-700 font-medium">{selectedRider.rejection_reason}</span>
                        </div>
                      )}

                      {selectedRider.suspension_reason && (
                        <div className="bg-amber-50 p-4 rounded-xl border border-amber-200 text-xs">
                          <span className="font-bold text-amber-800 uppercase block mb-1">Suspension details:</span>
                          <span className="text-amber-700 font-medium">{selectedRider.suspension_reason}</span>
                        </div>
                      )}

                    </div>

                    {/* Bottom action panel */}
                    <div className="bg-[#fff8f7] px-6 py-4 border-t border-border-card/30 flex items-center justify-end gap-2.5">
                      {selectedRider.verification_status !== 'approved' && (
                        <button
                          onClick={() => handleApprove(selectedRider)}
                          className="flex items-center gap-1.5 px-4.5 py-2.5 text-xs font-bold text-white bg-emerald-600 hover:bg-emerald-700 rounded-xl transition-all cursor-pointer shadow-md"
                        >
                          <Check className="h-4.5 w-4.5" /> Verify & Approve
                        </button>
                      )}
                      
                      {selectedRider.verification_status === 'pending' && (
                        <button
                          onClick={() => handleReject(selectedRider)}
                          className="flex items-center gap-1.5 px-4.5 py-2.5 text-xs font-bold text-white bg-red-600 hover:bg-red-700 rounded-xl transition-all cursor-pointer shadow-md"
                        >
                          <X className="h-4.5 w-4.5" /> Reject Rider
                        </button>
                      )}

                      {selectedRider.verification_status === 'approved' && (
                        <button
                          onClick={() => handleSuspend(selectedRider)}
                          className="flex items-center gap-1.5 px-4.5 py-2.5 text-xs font-bold text-white bg-amber-600 hover:bg-amber-700 rounded-xl transition-all cursor-pointer shadow-md"
                        >
                          <AlertTriangle className="h-4.5 w-4.5" /> Suspend Rider
                        </button>
                      )}
                    </div>

                  </div>
                </div>
              </div>
            </div>
          </div>
        );
      })()}
    </div>
  );
}
