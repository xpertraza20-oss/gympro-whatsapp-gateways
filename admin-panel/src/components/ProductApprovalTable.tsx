import { useState, useEffect } from 'react';
import { 
  CheckSquare, 
  Search, 
  RefreshCw, 
  Check, 
  X, 
  AlertCircle, 
  Eye, 
  Store, 
  Tag, 
  Layers, 
  DollarSign, 
  Box, 
  Calendar
} from 'lucide-react';
import { getAdminHeaders, getBackendUrl, formatPrice } from '../utils/config';
import { getSwal, showToast } from '../utils/alerts';

interface Product {
  id: number;
  category_id: number | null;
  title: string;
  description: string | null;
  price: number;
  sale_price: number | null;
  unit: string | null;
  stock_quantity: number;
  is_available: boolean;
  image_url: string | null;
  created_at: string;
  approval_status: string;
  rejection_reason: string | null;
  shop_id: number | null;
  category_name: string | null;
  shop_name: string | null;
  owner_name: string | null;
  owner_phone: string | null;
}

export default function ProductApprovalTable() {
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  
  // Details slide drawer state
  const [selectedProduct, setSelectedProduct] = useState<Product | null>(null);
  const [isDetailsOpen, setIsDetailsOpen] = useState(false);

  const fetchPendingProducts = async () => {
    setLoading(true);
    setError(null);
    try {
      const headers = getAdminHeaders(true);
      const backendUrl = getBackendUrl();
      const res = await fetch(`${backendUrl}/api/v1/admin/products/pending`, {
        method: 'GET',
        headers
      });

      if (!res.ok) {
        throw new Error(`Server returned status: ${res.status}`);
      }

      const json = await res.json();
      if (json.success && Array.isArray(json.data)) {
        setProducts(json.data);
      } else {
        throw new Error(json.message || 'Invalid products data structure');
      }
    } catch (err: any) {
      console.error('Error fetching pending products:', err);
      setError(err.message || 'Failed to connect to the backend server.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchPendingProducts();
  }, []);

  const handleApprove = async (product: Product) => {
    const swal = getSwal();
    const confirm = await swal.fire({
      title: 'Approve Product?',
      text: `Are you sure you want to approve "${product.title}"? It will become visible to all customer apps immediately.`,
      icon: 'question',
      showCancelButton: true,
      confirmButtonText: 'Yes, Approve',
      confirmButtonColor: '#006b56',
      cancelButtonColor: '#cbd5e1'
    });

    if (!confirm.isConfirmed) return;

    try {
      const res = await fetch(`${getBackendUrl()}/api/v1/admin/products/${product.id}/approve`, {
        method: 'PATCH',
        headers: getAdminHeaders(true)
      });
      const json = await res.json();
      if (res.ok && json.success) {
        showToast('success', 'Product approved successfully!');
        fetchPendingProducts();
        if (selectedProduct?.id === product.id) {
          setIsDetailsOpen(false);
          setSelectedProduct(null);
        }
      } else {
        swal.fire('Error', json.message || 'Failed to approve product.', 'error');
      }
    } catch (err: any) {
      swal.fire('Error', 'Connection failed.', 'error');
    }
  };

  const handleReject = async (product: Product) => {
    const swal = getSwal();
    const { value: reason } = await swal.fire({
      title: 'Reject Product Listing',
      input: 'textarea',
      inputLabel: 'Rejection Reason',
      inputPlaceholder: 'Explain why this product listing is rejected (e.g. invalid pricing, inappropriate description)...',
      showCancelButton: true,
      confirmButtonText: 'Reject Product',
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
      const res = await fetch(`${getBackendUrl()}/api/v1/admin/products/${product.id}/reject`, {
        method: 'PATCH',
        headers: getAdminHeaders(true),
        body: JSON.stringify({ reason })
      });
      const json = await res.json();
      if (res.ok && json.success) {
        showToast('success', 'Product listing rejected.');
        fetchPendingProducts();
        if (selectedProduct?.id === product.id) {
          setIsDetailsOpen(false);
          setSelectedProduct(null);
        }
      } else {
        swal.fire('Error', json.message || 'Failed to reject product.', 'error');
      }
    } catch (err: any) {
      swal.fire('Error', 'Connection failed.', 'error');
    }
  };

  const filteredProducts = products.filter(prod => {
    const matchesSearch = 
      prod.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
      (prod.shop_name && prod.shop_name.toLowerCase().includes(searchTerm.toLowerCase())) ||
      (prod.category_name && prod.category_name.toLowerCase().includes(searchTerm.toLowerCase()));
    
    return matchesSearch;
  });

  const formatToDDMMYYYY = (dateStr: string): string => {
    try {
      const d = new Date(dateStr);
      if (isNaN(d.getTime())) return dateStr;
      const day = String(d.getDate()).padStart(2, '0');
      const month = String(d.getMonth() + 1).padStart(2, '0');
      const year = d.getFullYear();
      return `${day}-${month}-${year}`;
    } catch {
      return dateStr;
    }
  };

  return (
    <div className="space-y-6">
      {/* Header section card */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 bg-white/60 p-6 rounded-2xl border border-border-card/30 shadow-md">
        <div>
          <h2 className="text-xl font-black text-text-primary flex items-center gap-2">
            <CheckSquare className="h-6 w-6 text-[#ac004d]" /> Product Approvals
          </h2>
          <p className="text-xs text-text-secondary mt-1">Audit and approve catalog items uploaded by merchant shopkeepers before publishing.</p>
        </div>
        <button 
          onClick={fetchPendingProducts} 
          disabled={loading}
          className="flex items-center gap-2 px-4 py-2 text-xs font-bold text-white bg-[#ac004d] hover:bg-[#ac004d]/90 rounded-xl transition-all cursor-pointer disabled:opacity-50"
        >
          <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} /> Refresh Pending list
        </button>
      </div>

      {/* Filter and Search */}
      <div className="flex flex-col md:flex-row gap-4 justify-between items-center bg-white/40 p-4 rounded-xl border border-border-card/20">
        <div className="relative w-full md:w-80">
          <Search className="absolute left-3 top-2.5 h-4.5 w-4.5 text-text-secondary/50" />
          <input 
            type="text" 
            placeholder="Search product, category, shop..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full pl-9 pr-4 py-2 text-xs bg-white rounded-xl border border-border-card/40 focus:outline-none focus:border-[#ac004d]"
          />
        </div>
        <div className="text-xs text-text-secondary font-bold">
          Pending Products Queue: <span className="text-[#ac004d] font-black">{filteredProducts.length}</span> items
        </div>
      </div>

      {/* Table grid */}
      <div className="rounded-2xl glass-panel shadow-lg overflow-hidden border border-border-card/30 bg-white">
        <div className="overflow-x-auto">
          <table className="w-full text-left">
            <thead className="bg-[#fff8f7]/60 border-b border-border-card/30">
              <tr>
                <th className="px-5 py-3.5 text-xs font-bold text-text-secondary uppercase tracking-wider">Product Info</th>
                <th className="px-5 py-3.5 text-xs font-bold text-text-secondary uppercase tracking-wider">Shop Name</th>
                <th className="px-5 py-3.5 text-xs font-bold text-text-secondary uppercase tracking-wider">Category</th>
                <th className="px-5 py-3.5 text-xs font-bold text-text-secondary uppercase tracking-wider">Price</th>
                <th className="px-5 py-3.5 text-xs font-bold text-text-secondary uppercase tracking-wider">Stock</th>
                <th className="px-5 py-3.5 text-xs font-bold text-text-secondary uppercase tracking-wider">Created Date</th>
                <th className="px-5 py-3.5 text-xs font-bold text-text-secondary uppercase tracking-wider">Status</th>
                <th className="px-5 py-3.5 text-xs font-bold text-text-secondary uppercase tracking-wider text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border-card/20">
              {loading ? (
                <tr>
                  <td colSpan={8} className="px-5 py-12 text-center text-xs text-text-secondary">
                    <RefreshCw className="h-8 w-8 animate-spin mx-auto text-[#ac004d] mb-2" />
                    Fetching pending catalog queue...
                  </td>
                </tr>
              ) : error ? (
                <tr>
                  <td colSpan={8} className="px-5 py-12 text-center text-xs text-red-500 font-medium">
                    <AlertCircle className="h-8 w-8 mx-auto mb-2 text-red-500" />
                    {error}
                  </td>
                </tr>
              ) : filteredProducts.length === 0 ? (
                <tr>
                  <td colSpan={8} className="px-5 py-12 text-center text-xs text-text-secondary">
                    No products pending approval.
                  </td>
                </tr>
              ) : (
                filteredProducts.map((prod) => (
                  <tr key={prod.id} className="hover:bg-hover-panel/20 transition-colors">
                    {/* Image and Name */}
                    <td className="px-5 py-4">
                      <div className="flex items-center space-x-3">
                        <div className="h-10 w-10 rounded-lg border border-border-card bg-slate-50 flex items-center justify-center shrink-0 overflow-hidden">
                          {prod.image_url ? (
                            <img className="w-full h-full object-cover" src={prod.image_url} alt={prod.title} />
                          ) : (
                            <span className="text-xl">📦</span>
                          )}
                        </div>
                        <div className="min-w-0">
                          <div className="font-bold text-xs text-text-primary truncate">{prod.title}</div>
                          <div className="text-[10px] text-text-secondary truncate mt-0.5">{prod.unit || '1 unit'}</div>
                        </div>
                      </div>
                    </td>

                    {/* Shop Name */}
                    <td className="px-5 py-4 text-xs text-text-secondary">
                      <div className="flex items-center gap-1">
                        <Store className="h-3.5 w-3.5 text-[#ac004d]/70 shrink-0" />
                        <span className="font-bold text-text-primary">{prod.shop_name || 'Demo Merchant'}</span>
                      </div>
                    </td>

                    {/* Category */}
                    <td className="px-5 py-4 text-xs">
                      <span className="px-2 py-0.5 bg-slate-100 text-slate-700 border border-slate-200 rounded text-[10px] font-bold uppercase tracking-wider">
                        {prod.category_name || 'Grocery'}
                      </span>
                    </td>

                    {/* Price */}
                    <td className="px-5 py-4 text-xs font-bold text-text-primary">
                      {formatPrice(prod.price)}
                    </td>

                    {/* Stock */}
                    <td className="px-5 py-4 text-xs font-medium text-text-secondary">
                      {prod.stock_quantity}
                    </td>

                    {/* Created Date */}
                    <td className="px-5 py-4 text-xs text-text-secondary">
                      <div className="flex items-center gap-1">
                        <Calendar className="h-3.5 w-3.5 text-slate-400" />
                        {formatToDDMMYYYY(prod.created_at)}
                      </div>
                    </td>

                    {/* Status */}
                    <td className="px-5 py-4 text-xs">
                      <span className="px-2.5 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider border bg-amber-100 text-amber-800 border-amber-200">
                        {prod.approval_status || 'pending'}
                      </span>
                    </td>

                    {/* Actions */}
                    <td className="px-5 py-4 text-right">
                      <div className="flex items-center justify-end gap-1">
                        <button 
                          onClick={() => {
                            setSelectedProduct(prod);
                            setIsDetailsOpen(true);
                          }}
                          title="View Product Details"
                          className="p-1.5 bg-slate-100 hover:bg-[#ac004d]/10 text-slate-600 hover:text-[#ac004d] rounded-lg transition-colors cursor-pointer border border-border-card/30"
                        >
                          <Eye className="h-4.5 w-4.5" />
                        </button>

                        <button 
                          onClick={() => handleApprove(prod)}
                          title="Approve Product"
                          className="p-1.5 bg-emerald-50 hover:bg-emerald-100 text-emerald-700 rounded-lg transition-colors cursor-pointer border border-emerald-200"
                        >
                          <Check className="h-4.5 w-4.5" />
                        </button>

                        <button 
                          onClick={() => handleReject(prod)}
                          title="Reject Product"
                          className="p-1.5 bg-red-50 hover:bg-red-100 text-red-700 rounded-lg transition-colors cursor-pointer border border-red-200"
                        >
                          <X className="h-4.5 w-4.5" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Details view slide-over drawer overlay */}
      {isDetailsOpen && selectedProduct && (
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
                      <CheckSquare className="h-5 w-5 text-[#ac004d]" />
                      <h2 className="text-sm font-bold text-text-primary uppercase tracking-wider">Product Information</h2>
                    </div>
                    <button 
                      onClick={() => setIsDetailsOpen(false)}
                      className="rounded-lg p-1.5 text-slate-500 hover:bg-slate-100 hover:text-slate-700 cursor-pointer"
                    >
                      <X className="h-5 w-5" />
                    </button>
                  </div>

                  {/* Body details */}
                  <div className="flex-1 px-6 py-6 space-y-6">
                    {/* Display Photo */}
                    <div className="relative h-44 rounded-xl overflow-hidden bg-slate-50 border border-border-card/30 flex items-center justify-center">
                      {selectedProduct.image_url ? (
                        <img className="w-full h-full object-cover" src={selectedProduct.image_url} alt={selectedProduct.title} />
                      ) : (
                        <span className="text-5xl">📦</span>
                      )}
                      
                      <div className="absolute top-3 right-3 bg-amber-500 text-white px-2.5 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider shadow">
                        {selectedProduct.approval_status}
                      </div>
                    </div>

                    {/* Section 1: Item specs */}
                    <div className="space-y-4">
                      <div>
                        <span className="text-[10px] font-black text-text-secondary/70 uppercase tracking-wide block">Product Name</span>
                        <h3 className="font-bold text-base text-text-primary mt-1">{selectedProduct.title}</h3>
                        <p className="text-xs text-text-secondary/80 mt-1.5 bg-slate-50 p-2.5 border border-slate-200/50 rounded italic">
                          {selectedProduct.description || 'No description provided by merchant.'}
                        </p>
                      </div>

                      <div className="grid grid-cols-2 gap-4 text-xs">
                        <div>
                          <span className="text-text-secondary/70 block">Category</span>
                          <span className="font-bold text-text-primary mt-0.5 flex items-center gap-1">
                            <Layers className="h-4.5 w-4.5 text-slate-400" /> {selectedProduct.category_name || 'Grocery'}
                          </span>
                        </div>
                        <div>
                          <span className="text-text-secondary/70 block">Brand</span>
                          <span className="font-bold text-text-primary mt-0.5 flex items-center gap-1">
                            <Tag className="h-4.5 w-4.5 text-slate-400" /> Generic
                          </span>
                        </div>
                        <div>
                          <span className="text-text-secondary/70 block">Selling Price</span>
                          <span className="font-bold text-[#ac004d] text-sm mt-0.5 flex items-center gap-0.5">
                            <DollarSign className="h-4 w-4" /> {selectedProduct.price}
                          </span>
                        </div>
                        <div>
                          <span className="text-text-secondary/70 block">Stock Level</span>
                          <span className="font-bold text-text-primary mt-0.5 flex items-center gap-1">
                            <Box className="h-4.5 w-4.5 text-slate-400" /> {selectedProduct.stock_quantity} ({selectedProduct.unit || '1 unit'})
                          </span>
                        </div>
                      </div>
                    </div>

                    {/* Section 2: Shop owner info */}
                    <div className="space-y-3 border-t border-border-card/20 pt-4">
                      <div className="flex items-center space-x-1 text-[#ac004d]">
                        <Store className="h-4 w-4" />
                        <h4 className="text-xs font-bold uppercase tracking-wider">Merchant / Shop Details</h4>
                      </div>
                      <div className="grid grid-cols-2 gap-y-3 gap-x-4 text-xs">
                        <div>
                          <span className="text-text-secondary/70 block">Store Name</span>
                          <span className="font-bold text-text-primary mt-0.5 block">{selectedProduct.shop_name || 'Demo Merchant'}</span>
                        </div>
                        <div>
                          <span className="text-text-secondary/70 block">Owner Name</span>
                          <span className="font-bold text-text-primary mt-0.5 block">{selectedProduct.owner_name || 'Zeeshan Khan'}</span>
                        </div>
                        <div className="col-span-2">
                          <span className="text-text-secondary/70 block">Contact Phone</span>
                          <span className="font-bold text-text-primary mt-0.5 block">{selectedProduct.owner_phone || '1122334455'}</span>
                        </div>
                      </div>
                    </div>

                  </div>

                  {/* Sticky Footer */}
                  <div className="bg-[#fff8f7] px-6 py-4 border-t border-border-card/30 flex items-center justify-end gap-2">
                    <button
                      onClick={() => handleApprove(selectedProduct)}
                      className="flex items-center gap-1.5 px-4 py-2 text-xs font-bold text-white bg-emerald-600 hover:bg-emerald-700 rounded-xl transition-all cursor-pointer shadow-md"
                    >
                      <Check className="h-4 w-4" /> Approve Listing
                    </button>
                    <button
                      onClick={() => handleReject(selectedProduct)}
                      className="flex items-center gap-1.5 px-4 py-2 text-xs font-bold text-white bg-red-600 hover:bg-red-700 rounded-xl transition-all cursor-pointer shadow-md"
                    >
                      <X className="h-4 w-4" /> Reject Listing
                    </button>
                  </div>

                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
