import { useState, useEffect } from 'react';
import { 
  Store, 
  Search, 
  RefreshCw, 
  Check, 
  X, 
  AlertCircle, 
  Eye, 
  User, 
  Phone, 
  MapPin, 
  Clock, 
  FileText,
  AlertTriangle
} from 'lucide-react';
import { getAdminHeaders, getBackendUrl } from '../utils/config';
import { getSwal, showToast } from '../utils/alerts';

interface Shop {
  id: number;
  owner_id: number;
  shop_name: string;
  shop_address: string;
  map_location: string | null;
  cnic: string; // May contain parsed layout e.g. "35201-1234567-1 | Account: John Doe | Bank: Bank Details"
  status: string; // Legacy status
  approval_status: string; // 'pending', 'approved', 'rejected', 'suspended'
  category: string | null;
  opening_time: string | null;
  closing_time: string | null;
  image_url: string | null; // Shop display photo or local path
  created_at: string;
  owner_name: string;
  owner_phone: string;
  owner_email: string;
  rejection_reason: string | null;
  suspension_reason: string | null;
}

export default function ShopApprovalsTable() {
  const [shops, setShops] = useState<Shop[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('all'); // all, pending, approved, rejected, suspended
  
  // Details drawer/modal state
  const [selectedShop, setSelectedShop] = useState<Shop | null>(null);
  const [isDetailsOpen, setIsDetailsOpen] = useState(false);

  const fetchShops = async () => {
    setLoading(true);
    setError(null);
    try {
      const headers = getAdminHeaders(true);
      const backendUrl = getBackendUrl();
      const res = await fetch(`${backendUrl}/api/v1/admin/shops`, {
        method: 'GET',
        headers
      });

      if (!res.ok) {
        throw new Error(`Server returned status: ${res.status}`);
      }

      const json = await res.json();
      if (json.success && Array.isArray(json.data)) {
        setShops(json.data);
      } else {
        throw new Error(json.message || 'Invalid shops data structure');
      }
    } catch (err: any) {
      console.error('Error fetching shops:', err);
      setError(err.message || 'Failed to connect to the backend server.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchShops();
  }, []);

  const handleApprove = async (shop: Shop) => {
    const swal = getSwal();
    const confirm = await swal.fire({
      title: 'Approve Shop?',
      text: `Are you sure you want to approve "${shop.shop_name}"? This will allow them to log in and sell products.`,
      icon: 'question',
      showCancelButton: true,
      confirmButtonText: 'Yes, Approve',
      confirmButtonColor: '#006b56',
      cancelButtonColor: '#cbd5e1'
    });

    if (!confirm.isConfirmed) return;

    try {
      const res = await fetch(`${getBackendUrl()}/api/v1/admin/shops/${shop.id}/approve`, {
        method: 'PATCH',
        headers: getAdminHeaders(true)
      });
      const json = await res.json();
      if (res.ok && json.success) {
        showToast('success', 'Shop approved successfully!');
        fetchShops();
        if (selectedShop?.id === shop.id) {
          setSelectedShop(prev => prev ? { ...prev, approval_status: 'approved', is_approved: true } : null);
        }
      } else {
        swal.fire('Error', json.message || 'Failed to approve shop.', 'error');
      }
    } catch (err: any) {
      swal.fire('Error', 'Connection failed.', 'error');
    }
  };

  const handleReject = async (shop: Shop) => {
    const swal = getSwal();
    const { value: reason } = await swal.fire({
      title: 'Reject Shop Application',
      input: 'textarea',
      inputLabel: 'Rejection Reason',
      inputPlaceholder: 'Type why the shop is being rejected (e.g. Invalid CNIC or documents)...',
      inputAttributes: {
        'aria-label': 'Type your rejection reason here'
      },
      showCancelButton: true,
      confirmButtonText: 'Submit Rejection',
      confirmButtonColor: '#ba1a1a',
      cancelButtonColor: '#cbd5e1',
      inputValidator: (value) => {
        if (!value) {
          return 'You must provide a rejection reason!';
        }
        return null;
      }
    });

    if (!reason) return;

    try {
      const res = await fetch(`${getBackendUrl()}/api/v1/admin/shops/${shop.id}/reject`, {
        method: 'PATCH',
        headers: getAdminHeaders(true),
        body: JSON.stringify({ reason })
      });
      const json = await res.json();
      if (res.ok && json.success) {
        showToast('success', 'Shop application rejected.');
        fetchShops();
        if (selectedShop?.id === shop.id) {
          setSelectedShop(prev => prev ? { ...prev, approval_status: 'rejected', rejection_reason: reason } : null);
        }
      } else {
        swal.fire('Error', json.message || 'Failed to reject shop.', 'error');
      }
    } catch (err: any) {
      swal.fire('Error', 'Connection failed.', 'error');
    }
  };

  const handleSuspend = async (shop: Shop) => {
    const swal = getSwal();
    const { value: reason } = await swal.fire({
      title: 'Suspend Shop Account',
      input: 'textarea',
      inputLabel: 'Suspension Reason',
      inputPlaceholder: 'Enter suspension details or violation reasons...',
      inputAttributes: {
        'aria-label': 'Type your suspension reason here'
      },
      showCancelButton: true,
      confirmButtonText: 'Suspend Account',
      confirmButtonColor: '#d97706',
      cancelButtonColor: '#cbd5e1',
      inputValidator: (value) => {
        if (!value) {
          return 'You must provide a suspension reason!';
        }
        return null;
      }
    });

    if (!reason) return;

    try {
      const res = await fetch(`${getBackendUrl()}/api/v1/admin/shops/${shop.id}/suspend`, {
        method: 'PATCH',
        headers: getAdminHeaders(true),
        body: JSON.stringify({ reason })
      });
      const json = await res.json();
      if (res.ok && json.success) {
        showToast('success', 'Shop account suspended.');
        fetchShops();
        if (selectedShop?.id === shop.id) {
          setSelectedShop(prev => prev ? { ...prev, approval_status: 'suspended', suspension_reason: reason } : null);
        }
      } else {
        swal.fire('Error', json.message || 'Failed to suspend shop.', 'error');
      }
    } catch (err: any) {
      swal.fire('Error', 'Connection failed.', 'error');
    }
  };

  // Parsing helper to clean CNIC value (e.g. extracting main CNIC or payout method details)
  const parseCnicString = (cnicVal: string) => {
    const parts = cnicVal.split('|');
    return {
      cnicNumber: parts[0]?.trim() || 'N/A',
      bankDetails: parts.slice(1).join(' | ').trim() || 'Not Provided'
    };
  };

  // Filter list
  const filteredShops = shops.filter(shop => {
    const matchesSearch = 
      shop.shop_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      shop.owner_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      shop.owner_phone.includes(searchTerm);
    
    if (statusFilter === 'all') return matchesSearch;
    return matchesSearch && shop.approval_status === statusFilter;
  });

  return (
    <div className="space-y-6">
      {/* Title Header Card */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 bg-white/60 p-6 rounded-2xl border border-border-card/30 shadow-md">
        <div>
          <h2 className="text-xl font-black text-text-primary flex items-center gap-2">
            <Store className="h-6 w-6 text-[#ac004d]" /> Shop Approvals & Verification
          </h2>
          <p className="text-xs text-text-secondary mt-1">Review, approve, reject, or suspend registered merchant shop profiles.</p>
        </div>
        <button 
          onClick={fetchShops} 
          disabled={loading}
          className="flex items-center gap-2 px-4 py-2 text-xs font-bold text-white bg-[#ac004d] hover:bg-[#ac004d]/90 rounded-xl transition-all cursor-pointer disabled:opacity-50"
        >
          <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} /> Refresh Lists
        </button>
      </div>

      {/* Filter and Search Section */}
      <div className="flex flex-col md:flex-row gap-4 justify-between items-center bg-white/40 p-4 rounded-xl border border-border-card/20">
        {/* Search Input */}
        <div className="relative w-full md:w-80">
          <Search className="absolute left-3 top-2.5 h-4.5 w-4.5 text-text-secondary/50" />
          <input 
            type="text" 
            placeholder="Search shop, owner, phone..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full pl-9 pr-4 py-2 text-xs bg-white rounded-xl border border-border-card/40 focus:outline-none focus:border-[#ac004d]"
          />
        </div>

        {/* Tab filters */}
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

      {/* Table Content */}
      <div className="rounded-2xl glass-panel shadow-lg overflow-hidden border border-border-card/30 bg-white">
        <div className="overflow-x-auto">
          <table className="w-full text-left">
            <thead className="bg-[#fff8f7]/60 border-b border-border-card/30">
              <tr>
                <th className="px-5 py-3.5 text-xs font-bold text-text-secondary uppercase tracking-wider">Shop details</th>
                <th className="px-5 py-3.5 text-xs font-bold text-text-secondary uppercase tracking-wider">Owner information</th>
                <th className="px-5 py-3.5 text-xs font-bold text-text-secondary uppercase tracking-wider">Category</th>
                <th className="px-5 py-3.5 text-xs font-bold text-text-secondary uppercase tracking-wider">Opening Hours</th>
                <th className="px-5 py-3.5 text-xs font-bold text-text-secondary uppercase tracking-wider">Verification status</th>
                <th className="px-5 py-3.5 text-xs font-bold text-text-secondary uppercase tracking-wider text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border-card/20">
              {loading ? (
                <tr>
                  <td colSpan={6} className="px-5 py-12 text-center text-xs text-text-secondary">
                    <RefreshCw className="h-8 w-8 animate-spin mx-auto text-[#ac004d] mb-2" />
                    Fetching shops profiles...
                  </td>
                </tr>
              ) : error ? (
                <tr>
                  <td colSpan={6} className="px-5 py-12 text-center text-xs text-red-500 font-medium">
                    <AlertCircle className="h-8 w-8 mx-auto mb-2 text-red-500" />
                    {error}
                  </td>
                </tr>
              ) : filteredShops.length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-5 py-12 text-center text-xs text-text-secondary">
                    No shops match the selected filters.
                  </td>
                </tr>
              ) : (
                filteredShops.map((shop) => {
                  const statusColors: Record<string, string> = {
                    pending: 'bg-amber-100 text-amber-800 border-amber-200',
                    approved: 'bg-emerald-100 text-emerald-800 border-emerald-200',
                    rejected: 'bg-red-100 text-red-800 border-red-200',
                    suspended: 'bg-slate-100 text-slate-800 border-slate-200'
                  };

                  return (
                    <tr key={shop.id} className="hover:bg-hover-panel/20 transition-colors">
                      <td className="px-5 py-4">
                        <div className="flex items-center space-x-3">
                          <div className="h-10 w-10 rounded-lg bg-[#ac004d]/5 border border-[#ac004d]/10 flex items-center justify-center shrink-0 text-lg font-bold">
                            🏪
                          </div>
                          <div className="min-w-0">
                            <div className="font-bold text-xs text-text-primary truncate">{shop.shop_name}</div>
                            <div className="text-[10px] text-text-secondary truncate mt-0.5">{shop.shop_address}</div>
                          </div>
                        </div>
                      </td>
                      <td className="px-5 py-4 text-xs text-text-secondary">
                        <div className="font-bold text-text-primary">{shop.owner_name}</div>
                        <div className="flex items-center gap-1 mt-0.5 text-text-secondary/80">
                          <Phone className="h-3 w-3 shrink-0" /> {shop.owner_phone}
                        </div>
                      </td>
                      <td className="px-5 py-4 text-xs">
                        <span className="px-2 py-0.5 bg-slate-100 text-slate-700 border border-slate-200 rounded text-[10px] font-bold uppercase tracking-wider">
                          {shop.category || 'Grocery'}
                        </span>
                      </td>
                      <td className="px-5 py-4 text-xs text-text-secondary">
                        <div className="flex items-center gap-1">
                          <Clock className="h-3 w-3" /> {shop.opening_time || '09:00'} - {shop.closing_time || '21:00'}
                        </div>
                      </td>
                      <td className="px-5 py-4 text-xs">
                        <span className={`px-2.5 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider border ${
                          statusColors[shop.approval_status || 'pending']
                        }`}>
                          {shop.approval_status || 'pending'}
                        </span>
                      </td>
                      <td className="px-5 py-4 text-right">
                        <div className="flex items-center justify-end gap-1">
                          {/* View details */}
                          <button 
                            onClick={() => {
                              setSelectedShop(shop);
                              setIsDetailsOpen(true);
                            }}
                            title="View Details"
                            className="p-1.5 bg-slate-100 hover:bg-[#ac004d]/10 text-slate-600 hover:text-[#ac004d] rounded-lg transition-colors cursor-pointer border border-border-card/30"
                          >
                            <Eye className="h-4.5 w-4.5" />
                          </button>

                          {/* Action button triggers */}
                          {shop.approval_status !== 'approved' && (
                            <button 
                              onClick={() => handleApprove(shop)}
                              title="Approve Shop"
                              className="p-1.5 bg-emerald-50 hover:bg-emerald-100 text-emerald-700 rounded-lg transition-colors cursor-pointer border border-emerald-200"
                            >
                              <Check className="h-4.5 w-4.5" />
                            </button>
                          )}

                          {shop.approval_status === 'pending' && (
                            <button 
                              onClick={() => handleReject(shop)}
                              title="Reject Shop"
                              className="p-1.5 bg-red-50 hover:bg-red-100 text-red-700 rounded-lg transition-colors cursor-pointer border border-red-200"
                            >
                              <X className="h-4.5 w-4.5" />
                            </button>
                          )}

                          {shop.approval_status === 'approved' && (
                            <button 
                              onClick={() => handleSuspend(shop)}
                              title="Suspend Shop"
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

      {/* Details Slide-over Drawer UI */}
      {isDetailsOpen && selectedShop && (() => {
        const parsed = parseCnicString(selectedShop.cnic);
        
        return (
          <div className="fixed inset-0 z-50 overflow-hidden" aria-labelledby="slide-over-title" role="dialog" aria-modal="true">
            <div className="absolute inset-0 overflow-hidden">
              {/* Overlay background */}
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
                        <Store className="h-5 w-5 text-[#ac004d]" />
                        <h2 className="text-sm font-bold text-text-primary uppercase tracking-wider">Shop Profile Details</h2>
                      </div>
                      <button 
                        onClick={() => setIsDetailsOpen(false)}
                        className="rounded-lg p-1.5 text-slate-500 hover:bg-slate-100 hover:text-slate-700 cursor-pointer"
                      >
                        <X className="h-5 w-5" />
                      </button>
                    </div>

                    {/* Content Body */}
                    <div className="flex-1 px-6 py-6 space-y-6">
                      
                      {/* Shop Display Banner Image */}
                      <div className="relative h-44 rounded-xl overflow-hidden bg-slate-100 border border-border-card/30 flex items-center justify-center">
                        {selectedShop.image_url ? (
                          <img 
                            className="w-full h-full object-cover" 
                            src={selectedShop.image_url.startsWith('http') ? selectedShop.image_url : 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&q=80&w=400'} 
                            alt={selectedShop.shop_name}
                          />
                        ) : (
                          <div className="flex flex-col items-center justify-center text-slate-400">
                            <span className="text-4xl">🏪</span>
                            <span className="text-[10px] font-bold uppercase mt-2 text-slate-400">No Image Uploaded</span>
                          </div>
                        )}
                        
                        <div className="absolute top-3 right-3">
                          <span className={`px-2.5 py-1 rounded-full text-[10px] font-bold uppercase border bg-white shadow-sm ${
                            selectedShop.approval_status === 'approved' 
                              ? 'text-emerald-700 border-emerald-200' 
                              : selectedShop.approval_status === 'pending'
                                ? 'text-amber-700 border-amber-200'
                                : 'text-red-700 border-red-200'
                          }`}>
                            {selectedShop.approval_status}
                          </span>
                        </div>
                      </div>

                      {/* Section 1: Owner Information */}
                      <div className="space-y-3.5">
                        <div className="flex items-center space-x-1.5 border-b border-border-card/20 pb-2">
                          <User className="h-4.5 w-4.5 text-[#ac004d]" />
                          <h4 className="text-xs font-bold text-text-primary uppercase tracking-wider">Owner Information</h4>
                        </div>
                        <div className="grid grid-cols-2 gap-y-3 gap-x-4 text-xs">
                          <div>
                            <span className="text-text-secondary/70 block">Full Name</span>
                            <span className="font-bold text-text-primary mt-0.5 block">{selectedShop.owner_name}</span>
                          </div>
                          <div>
                            <span className="text-text-secondary/70 block">Phone Number</span>
                            <span className="font-bold text-text-primary mt-0.5 block">{selectedShop.owner_phone}</span>
                          </div>
                          <div className="col-span-2">
                            <span className="text-text-secondary/70 block">CNIC / Account Identifier</span>
                            <span className="font-mono text-text-primary bg-slate-50 p-2 rounded border border-slate-200/50 mt-1 block select-all">
                              {parsed.cnicNumber}
                            </span>
                          </div>
                          <div className="col-span-2">
                            <span className="text-text-secondary/70 block">Bank Account Details</span>
                            <span className="text-text-primary font-medium bg-slate-50 p-2 rounded border border-slate-200/50 mt-1 block">
                              {parsed.bankDetails}
                            </span>
                          </div>
                        </div>
                      </div>

                      {/* CNIC Front & Back Placeholder cards */}
                      <div className="grid grid-cols-2 gap-4">
                        <div>
                          <span className="text-[10px] font-bold text-text-secondary uppercase block mb-1.5">CNIC Front</span>
                          <div className="h-28 rounded-lg border border-dashed border-border-card/80 bg-slate-50 flex flex-col items-center justify-center text-slate-400 p-2 text-center">
                            <FileText className="h-6 w-6 text-[#ac004d]/40 mb-1" />
                            <span className="text-[9px] font-bold uppercase tracking-wider text-slate-500">Document Uploaded</span>
                            <span className="text-[8px] text-slate-400 mt-0.5">Verification Ready</span>
                          </div>
                        </div>
                        <div>
                          <span className="text-[10px] font-bold text-text-secondary uppercase block mb-1.5">CNIC Back</span>
                          <div className="h-28 rounded-lg border border-dashed border-border-card/80 bg-slate-50 flex flex-col items-center justify-center text-slate-400 p-2 text-center">
                            <FileText className="h-6 w-6 text-[#ac004d]/40 mb-1" />
                            <span className="text-[9px] font-bold uppercase tracking-wider text-slate-500">Document Uploaded</span>
                            <span className="text-[8px] text-slate-400 mt-0.5">Verification Ready</span>
                          </div>
                        </div>
                      </div>

                      {/* Section 2: Shop Details */}
                      <div className="space-y-3.5">
                        <div className="flex items-center space-x-1.5 border-b border-border-card/20 pb-2">
                          <Store className="h-4.5 w-4.5 text-[#ac004d]" />
                          <h4 className="text-xs font-bold text-text-primary uppercase tracking-wider">Shop Details</h4>
                        </div>
                        <div className="grid grid-cols-2 gap-y-3 gap-x-4 text-xs">
                          <div>
                            <span className="text-text-secondary/70 block">Shop Name</span>
                            <span className="font-bold text-text-primary mt-0.5 block">{selectedShop.shop_name}</span>
                          </div>
                          <div>
                            <span className="text-text-secondary/70 block">Business Category</span>
                            <span className="font-bold text-text-primary mt-0.5 block">{selectedShop.category || 'Grocery'}</span>
                          </div>
                          <div className="col-span-2">
                            <span className="text-text-secondary/70 block">Store Address</span>
                            <span className="text-text-primary font-medium mt-0.5 block">{selectedShop.shop_address}</span>
                          </div>
                          <div>
                            <span className="text-text-secondary/70 block">Hours of Operation</span>
                            <div className="flex items-center gap-1.5 text-text-primary font-bold mt-1">
                              <Clock className="h-4 w-4 text-slate-400" />
                              {selectedShop.opening_time || '09:00'} - {selectedShop.closing_time || '21:00'}
                            </div>
                          </div>
                          <div>
                            <span className="text-text-secondary/70 block">GPS Map Location</span>
                            <div className="flex items-center gap-1.5 text-text-primary font-bold mt-1">
                              <MapPin className="h-4 w-4 text-[#ac004d]" />
                              <span className="select-all font-mono">{selectedShop.map_location || '31.4800, 74.3200'}</span>
                            </div>
                          </div>
                        </div>
                      </div>

                      {/* Rejection / Suspension Banner logs */}
                      {selectedShop.rejection_reason && (
                        <div className="bg-red-50 p-4 rounded-xl border border-red-200 text-xs">
                          <span className="font-bold text-red-800 uppercase block mb-1">Rejection Reason:</span>
                          <span className="text-red-700 font-medium">{selectedShop.rejection_reason}</span>
                        </div>
                      )}

                      {selectedShop.suspension_reason && (
                        <div className="bg-amber-50 p-4 rounded-xl border border-amber-200 text-xs">
                          <span className="font-bold text-amber-800 uppercase block mb-1">Suspension details:</span>
                          <span className="text-amber-700 font-medium">{selectedShop.suspension_reason}</span>
                        </div>
                      )}

                    </div>

                    {/* Bottom Sticky Action Footer */}
                    <div className="bg-[#fff8f7] px-6 py-4 border-t border-border-card/30 flex items-center justify-end gap-2.5">
                      {selectedShop.approval_status !== 'approved' && (
                        <button
                          onClick={() => handleApprove(selectedShop)}
                          className="flex items-center gap-1.5 px-4.5 py-2.5 text-xs font-bold text-white bg-emerald-600 hover:bg-emerald-700 rounded-xl transition-all cursor-pointer shadow-md"
                        >
                          <Check className="h-4 w-4" /> Approve
                        </button>
                      )}
                      
                      {selectedShop.approval_status === 'pending' && (
                        <button
                          onClick={() => handleReject(selectedShop)}
                          className="flex items-center gap-1.5 px-4.5 py-2.5 text-xs font-bold text-white bg-red-600 hover:bg-red-700 rounded-xl transition-all cursor-pointer shadow-md"
                        >
                          <X className="h-4 w-4" /> Reject Application
                        </button>
                      )}

                      {selectedShop.approval_status === 'approved' && (
                        <button
                          onClick={() => handleSuspend(selectedShop)}
                          className="flex items-center gap-1.5 px-4.5 py-2.5 text-xs font-bold text-white bg-amber-600 hover:bg-amber-700 rounded-xl transition-all cursor-pointer shadow-md"
                        >
                          <AlertTriangle className="h-4 w-4" /> Suspend Store
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
