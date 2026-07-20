import { useState, useEffect } from 'react';
import {
  ShoppingCart,
  Search,
  RefreshCw,
  Truck,
  Eye,
  AlertCircle,
  MapPin,
  User,
  X,
  Store,
  Calendar
} from 'lucide-react';
import { getAdminHeaders, getBackendUrl, formatPrice } from '../utils/config';
import { getSwal, showToast } from '../utils/alerts';

interface OrderItemDetails {
  id: string | number;
  title: string;
  price: number;
  quantity: number;
  unit?: string;
  image_url?: string;
}

interface Order {
  id: number;
  customerName: string;
  email: string;
  itemsCount: number;
  totalAmount: number;
  status: string;
  date: string;
  paymentMethod: string;
  deliveryAddress?: string;
  cancelReason?: string;
  items?: OrderItemDetails[];
  shopId?: number;
  shopName: string;
  riderId?: number;
  riderName: string;
  created_at?: string;
}

interface TimelineEvent {
  status: string;
  changed_by: string;
  created_at: string;
}

export default function OrdersTable() {
  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  
  // Custom Filter State Inputs
  const [searchTerm, setSearchTerm] = useState('');
  const [customerFilter, setCustomerFilter] = useState('');
  const [shopFilter, setShopFilter] = useState('');
  const [riderFilter, setRiderFilter] = useState('');
  const [statusFilter, setStatusFilter] = useState('All');
  const [dateFilter, setDateFilter] = useState('');

  // Modal details state
  const [selectedOrder, setSelectedOrder] = useState<Order | null>(null);
  const [isDetailsOpen, setIsDetailsOpen] = useState(false);
  const [updatingId, setUpdatingId] = useState<number | null>(null);

  // Timeline events tracking state
  const [timeline, setTimeline] = useState<TimelineEvent[]>([]);
  const [loadingTimeline, setLoadingTimeline] = useState(false);

  // Fetch live orders from Cloudflare Worker backend
  const fetchOrders = async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await fetch(`${getBackendUrl()}/api/v1/admin/orders`, {
        method: 'GET',
        headers: getAdminHeaders(true)
      });

      if (!res.ok) {
        throw new Error(`Server returned status: ${res.status}`);
      }

      const json = await res.json();
      if (json.success && Array.isArray(json.data)) {
        setOrders(json.data);
      } else {
        throw new Error(json.message || 'Invalid orders data format');
      }
    } catch (err: any) {
      console.error('Error fetching orders:', err);
      setError(err.message || 'Failed to connect to the backend server.');
    } finally {
      setLoading(false);
    }
  };

  const fetchTimeline = async (orderId: number) => {
    setLoadingTimeline(true);
    try {
      const res = await fetch(`${getBackendUrl()}/api/v1/orders/${orderId}/history`, {
        headers: getAdminHeaders(true)
      });
      if (res.ok) {
        const json = await res.json();
        if (json.success && Array.isArray(json.data)) {
          setTimeline(json.data);
        }
      }
    } catch (e) {
      console.error('Error fetching order timeline history:', e);
    } finally {
      setLoadingTimeline(false);
    }
  };

  useEffect(() => {
    fetchOrders();
  }, []);

  useEffect(() => {
    if (selectedOrder) {
      fetchTimeline(selectedOrder.id);
    } else {
      setTimeline([]);
    }
  }, [selectedOrder]);

  // Update order status on backend
  const handleUpdateStatus = async (id: number, currentStatus: string, e?: React.MouseEvent) => {
    if (e) e.stopPropagation(); // Prevent opening modal details

    const swal = getSwal();
    const result = await swal.fire({
      title: `Update Order #${id}`,
      html: `<p style="margin:0;font-size:13px">Select new status for this order:</p>`,
      input: 'select',
      inputOptions: {
        'pending': '⏳  pending',
        'accepted': '🤝  accepted',
        'rejected': '❌  rejected',
        'preparing': '🍳  preparing',
        'ready_for_pickup': '📦  ready for pickup',
        'rider_assigned': '🏍️  rider assigned',
        'picked_up': '🛍️  picked up',
        'on_the_way': '🚚  on the way',
        'delivered': '📦  delivered',
        'cancelled': '🚫  cancelled'
      },
      inputValue: currentStatus.toLowerCase(),
      showCancelButton: true,
      confirmButtonText: 'Update Status',
      cancelButtonText: 'Cancel',
      reverseButtons: true
    });

    if (result.isConfirmed && result.value) {
      let cancelReason = '';
      if (result.value === 'cancelled' || result.value === 'rejected') {
        const reasonResult = await swal.fire({
          title: 'Reason Statement',
          text: 'Please specify the reason for cancelling/rejecting this order:',
          input: 'text',
          inputPlaceholder: 'e.g., Out of stock, customer request...',
          showCancelButton: true,
          confirmButtonText: 'Submit Reason',
          cancelButtonText: 'Go Back',
          reverseButtons: true,
          inputValidator: (value) => {
            if (!value) {
              return 'You must enter a reason!';
            }
            return null;
          }
        });

        if (!reasonResult.isConfirmed) {
          return;
        }
        cancelReason = reasonResult.value;
      }

      setUpdatingId(id);
      try {
        const res = await fetch(`${getBackendUrl()}/api/v1/admin/orders/${id}`, {
          method: 'PUT',
          headers: getAdminHeaders(true),
          body: JSON.stringify({ 
            status: result.value,
            cancel_reason: cancelReason 
          })
        });

        const json = await res.json();
        if (!res.ok) {
          throw new Error(json.message || 'Failed to update order status');
        }

        showToast('success', `Order status updated to ${result.value}`);

        // Update local state
        setOrders(prev => prev.map(order =>
          order.id === id ? { ...order, status: result.value, cancelReason: cancelReason } : order
        ));

        // Update details modal state if active
        if (selectedOrder && selectedOrder.id === id) {
          setSelectedOrder(prev => prev ? { ...prev, status: result.value, cancelReason: cancelReason } : null);
          fetchTimeline(id);
        }
      } catch (err: any) {
        console.error('Failed to update status:', err);
        swal.fire({
          title: 'Error!',
          text: err.message || 'Failed to update status on server.',
          icon: 'error'
        });
      } finally {
        setUpdatingId(null);
      }
    }
  };

  const getStatusStyle = (status: string) => {
    const s = String(status || '').toLowerCase();
    if (s === 'pending') return 'bg-amber-100 text-amber-800 border-amber-200';
    if (s === 'accepted' || s === 'preparing' || s === 'ready_for_pickup') return 'bg-blue-100 text-blue-800 border-blue-200';
    if (s === 'rider_assigned' || s === 'picked_up' || s === 'on_the_way') return 'bg-indigo-100 text-indigo-800 border-indigo-200';
    if (s === 'delivered') return 'bg-emerald-100 text-emerald-800 border-emerald-200';
    return 'bg-red-100 text-red-800 border-red-200';
  };

  // Filter orders
  const filteredOrders = orders.filter(order => {
    const matchesId = searchTerm ? String(order.id).toLowerCase().includes(searchTerm.toLowerCase()) : true;
    const matchesCustomer = customerFilter ? (
      order.customerName.toLowerCase().includes(customerFilter.toLowerCase()) ||
      order.email.toLowerCase().includes(customerFilter.toLowerCase())
    ) : true;
    const matchesShop = shopFilter ? (order.shopName || '').toLowerCase().includes(shopFilter.toLowerCase()) : true;
    const matchesRider = riderFilter ? (order.riderName || '').toLowerCase().includes(riderFilter.toLowerCase()) : true;
    const matchesStatus = statusFilter === 'All' ? true : order.status.toLowerCase() === statusFilter.toLowerCase();
    const matchesDate = dateFilter ? (
      order.date.toLowerCase().includes(dateFilter.toLowerCase()) || 
      (order.created_at && order.created_at.includes(dateFilter))
    ) : true;

    return matchesId && matchesCustomer && matchesShop && matchesRider && matchesStatus && matchesDate;
  });

  return (
    <div className="space-y-6">
      {/* Top Banner */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between rounded-2xl glass-panel p-5 float-card shadow-lg bg-white">
        <div>
          <h2 className="text-lg font-bold text-text-primary flex items-center gap-2">
            <ShoppingCart className="h-5.5 w-5.5 text-emerald-500" />
            Live Customer Orders
          </h2>
          <p className="text-xs text-text-secondary mt-0.5">
            Audit billing, view details, and track shipping status of all grocery orders.
          </p>
        </div>
        <button
          onClick={fetchOrders}
          disabled={loading}
          className="flex items-center gap-2 rounded-xl bg-emerald-500/10 hover:bg-emerald-500/20 text-emerald-600 border border-emerald-500/20 px-4 py-2 text-xs font-semibold transition-all cursor-pointer disabled:opacity-50"
        >
          <RefreshCw className={`h-3.5 w-3.5 ${loading ? 'animate-spin' : ''}`} />
          <span>Reload Data</span>
        </button>
      </div>

      {/* Advanced Filtering and Search Toolbar */}
      <div className="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-6 gap-3.5 rounded-2xl glass-panel p-4 float-card shadow-lg bg-white">
        {/* Search ID */}
        <div className="relative">
          <Search className="absolute left-3 top-2.5 h-4 w-4 text-text-secondary/60" />
          <input
            type="text"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            placeholder="Order ID..."
            className="w-full pl-9 pr-3 py-2 text-xs rounded-xl bg-bg-input border border-border-card text-text-primary focus:outline-none focus:border-emerald-500"
          />
        </div>

        {/* Filter Customer */}
        <div className="relative">
          <User className="absolute left-3 top-2.5 h-4 w-4 text-text-secondary/60" />
          <input
            type="text"
            value={customerFilter}
            onChange={(e) => setCustomerFilter(e.target.value)}
            placeholder="Customer name/email..."
            className="w-full pl-9 pr-3 py-2 text-xs rounded-xl bg-bg-input border border-border-card text-text-primary focus:outline-none focus:border-emerald-500"
          />
        </div>

        {/* Filter Shop */}
        <div className="relative">
          <Store className="absolute left-3 top-2.5 h-4 w-4 text-text-secondary/60" />
          <input
            type="text"
            value={shopFilter}
            onChange={(e) => setShopFilter(e.target.value)}
            placeholder="Shop name..."
            className="w-full pl-9 pr-3 py-2 text-xs rounded-xl bg-bg-input border border-border-card text-text-primary focus:outline-none focus:border-emerald-500"
          />
        </div>

        {/* Filter Rider */}
        <div className="relative">
          <Truck className="absolute left-3 top-2.5 h-4 w-4 text-text-secondary/60" />
          <input
            type="text"
            value={riderFilter}
            onChange={(e) => setRiderFilter(e.target.value)}
            placeholder="Rider name..."
            className="w-full pl-9 pr-3 py-2 text-xs rounded-xl bg-bg-input border border-border-card text-text-primary focus:outline-none focus:border-emerald-500"
          />
        </div>

        {/* Filter Date */}
        <div className="relative">
          <Calendar className="absolute left-3 top-2.5 h-4 w-4 text-text-secondary/60" />
          <input
            type="text"
            value={dateFilter}
            onChange={(e) => setDateFilter(e.target.value)}
            placeholder="YYYY-MM-DD or Date..."
            className="w-full pl-9 pr-3 py-2 text-xs rounded-xl bg-bg-input border border-border-card text-text-primary focus:outline-none focus:border-emerald-500"
          />
        </div>

        {/* Filter Status */}
        <div>
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="w-full px-3 py-2 text-xs rounded-xl bg-bg-input border border-border-card text-text-primary focus:outline-none focus:border-emerald-500"
          >
            <option value="All">All Statuses</option>
            <option value="pending">Pending</option>
            <option value="accepted">Accepted</option>
            <option value="rejected">Rejected</option>
            <option value="preparing">Preparing</option>
            <option value="ready_for_pickup">Ready For Pickup</option>
            <option value="rider_assigned">Rider Assigned</option>
            <option value="picked_up">Picked Up</option>
            <option value="on_the_way">On The Way</option>
            <option value="delivered">Delivered</option>
            <option value="cancelled">Cancelled</option>
          </select>
        </div>
      </div>

      {/* Orders Table container */}
      <div className="overflow-hidden rounded-2xl glass-panel shadow-xl float-card bg-white">
        {loading ? (
          <div className="flex flex-col items-center justify-center py-20 space-y-4">
            <RefreshCw className="h-8 w-8 text-emerald-500 animate-spin" />
            <span className="text-sm text-text-secondary font-medium">Fetching customer orders...</span>
          </div>
        ) : error ? (
          <div className="flex flex-col items-center justify-center py-16 px-6 text-center space-y-3">
            <div className="rounded-full bg-red-500/10 p-3 text-red-500 border border-red-500/20">
              <AlertCircle className="h-6 w-6" />
            </div>
            <h3 className="text-base font-bold text-text-primary">Failed to load data</h3>
            <p className="text-sm text-text-secondary max-w-md">{error}</p>
            <button
              onClick={fetchOrders}
              className="mt-2 rounded-xl bg-emerald-500 px-4 py-2 text-xs font-semibold text-white hover:brightness-110 active:scale-98 transition-all cursor-pointer"
            >
              Try Again
            </button>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="border-b border-border-card bg-[#fff8f7]/60 text-xs font-semibold tracking-wider text-text-secondary">
                  <th className="px-6 py-4.5">Order ID</th>
                  <th className="px-6 py-4.5">Customer</th>
                  <th className="px-6 py-4.5">Items</th>
                  <th className="px-6 py-4.5">Merchant Shop</th>
                  <th className="px-6 py-4.5">Rider Assignee</th>
                  <th className="px-6 py-4.5">Total Amount</th>
                  <th className="px-6 py-4.5">Status</th>
                  <th className="px-6 py-4.5">Date</th>
                  <th className="px-6 py-4.5 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border-card/60 text-sm">
                {filteredOrders.length > 0 ? (
                  filteredOrders.map((order) => (
                    <tr
                      key={order.id}
                      onClick={() => {
                        setSelectedOrder(order);
                        setIsDetailsOpen(true);
                      }}
                      className="hover:bg-[#fff8f7]/40 transition-colors duration-150 cursor-pointer"
                    >
                      <td className="px-6 py-4 font-mono font-bold text-text-primary">
                        #{order.id}
                      </td>
                      <td className="px-6 py-4">
                        <div>
                          <span className="font-bold text-text-primary block">{order.customerName}</span>
                          <span className="text-[10px] text-text-secondary block mt-0.5">{order.email}</span>
                        </div>
                      </td>
                      <td className="px-6 py-4 text-text-primary font-medium">
                        {order.itemsCount} items
                      </td>
                      {/* Shop Name */}
                      <td className="px-6 py-4 text-xs font-bold text-text-primary flex items-center gap-1.5 pt-6">
                        <Store className="h-3.5 w-3.5 text-[#ac004d]" />
                        {order.shopName || 'Demo Shop'}
                      </td>
                      {/* Rider Name */}
                      <td className="px-6 py-4 text-xs text-text-secondary">
                        {order.riderName || 'Not Assigned'}
                      </td>
                      <td className="px-6 py-4 font-bold text-text-primary">
                        {formatPrice(order.totalAmount)}
                      </td>
                      <td className="px-6 py-4">
                        <span className={`inline-flex items-center gap-1 rounded-full px-2.5 py-0.5 text-[10px] font-bold uppercase tracking-wider border ${getStatusStyle(order.status)}`}>
                          <span>{order.status}</span>
                        </span>
                      </td>
                      <td className="px-6 py-4 text-text-secondary text-xs">
                        {order.date}
                      </td>
                      <td className="px-6 py-4 text-right">
                        <button
                          onClick={(e) => handleUpdateStatus(order.id, order.status, e)}
                          disabled={updatingId === order.id}
                          className="rounded-lg p-2 text-text-secondary hover:bg-hover-panel hover:text-[#ac004d] transition-colors cursor-pointer border border-border-card"
                          title="Change Status"
                        >
                          {updatingId === order.id ? (
                            <RefreshCw className="h-4.5 w-4.5 animate-spin" />
                          ) : (
                            <Eye className="h-4.5 w-4.5" />
                          )}
                        </button>
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan={9} className="px-6 py-16 text-center text-text-secondary">
                      No orders found matching filters.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* ─── MODAL: ORDER DETAILS ────────────────────────────────────────── */}
      {isDetailsOpen && selectedOrder && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/60 backdrop-blur-sm">
          <div className="relative w-full max-w-lg rounded-2xl glass-panel p-6 shadow-2xl animate-in fade-in zoom-in duration-200 max-h-[85vh] overflow-y-auto float-card bg-white">
            {/* Close */}
            <button
              onClick={() => {
                setIsDetailsOpen(false);
                setSelectedOrder(null);
              }}
              className="absolute right-4 top-4 rounded-lg p-1.5 text-text-secondary hover:bg-slate-100 hover:text-text-primary transition-colors cursor-pointer border"
            >
              <X className="h-5 w-5" />
            </button>

            {/* Header info */}
            <div className="pb-4 border-b border-border-card/60">
              <h3 className="text-sm font-black text-text-primary flex items-center gap-2 uppercase tracking-wider">
                <ShoppingCart className="h-5 w-5 text-[#ac004d]" />
                Order Dashboard
              </h3>
              <p className="text-xs text-text-secondary mt-1 font-mono">Order ID: #{selectedOrder.id} | Date: {selectedOrder.date}</p>
            </div>

            {/* Customer, Shop, Rider Profiles Card */}
            <div className="mt-4 p-4 rounded-xl bg-slate-50 border border-border-card/60 space-y-4">
              {/* Customer */}
              <div>
                <span className="text-[10px] font-black text-text-secondary uppercase tracking-wider block">Customer Details</span>
                <span className="font-bold text-text-primary block mt-0.5 text-xs">{selectedOrder.customerName} ({selectedOrder.email})</span>
                <span className="text-xs text-text-secondary flex items-center gap-1 mt-1 leading-normal">
                  <MapPin className="h-3.5 w-3.5 text-slate-400 shrink-0" /> {selectedOrder.deliveryAddress}
                </span>
              </div>

              {/* Shop info */}
              <div className="border-t border-border-card/40 pt-3">
                <span className="text-[10px] font-black text-text-secondary uppercase tracking-wider block">Merchant Shop</span>
                <span className="font-bold text-text-primary mt-0.5 text-xs flex items-center gap-1">
                  <Store className="h-4 w-4 text-[#ac004d]" /> {selectedOrder.shopName} (ID: {selectedOrder.shopId || 'N/A'})
                </span>
              </div>

              {/* Rider info */}
              <div className="border-t border-border-card/40 pt-3">
                <span className="text-[10px] font-black text-text-secondary uppercase tracking-wider block">Rider Assignee</span>
                <span className="font-bold text-text-primary mt-0.5 text-xs flex items-center gap-1">
                  <Truck className="h-4 w-4 text-slate-400" /> {selectedOrder.riderName} (ID: {selectedOrder.riderId || 'N/A'})
                </span>
              </div>

              {/* Payment Details */}
              <div className="border-t border-border-card/40 pt-3 flex justify-between items-center text-xs">
                <div>
                  <span className="text-[10px] font-black text-text-secondary uppercase block">Payment Method</span>
                  <span className="font-bold text-text-primary mt-0.5 block uppercase">{selectedOrder.paymentMethod}</span>
                </div>
                <span className={`inline-flex items-center gap-1 rounded-full px-2.5 py-0.5 text-[10px] font-bold uppercase tracking-wider border ${getStatusStyle(selectedOrder.status)}`}>
                  {selectedOrder.status}
                </span>
              </div>
            </div>

            {/* Cancel/Rejection Reason */}
            {selectedOrder.cancelReason && (
              <div className="mt-4 p-4 rounded-xl bg-red-50 border border-red-200 text-xs text-red-800">
                <div className="font-bold flex items-center gap-1.5 uppercase tracking-wider mb-1">
                  <AlertCircle className="h-4 w-4" />
                  <span>Cancellation/Rejection Reason</span>
                </div>
                <p className="font-medium">{selectedOrder.cancelReason}</p>
              </div>
            )}

            {/* Live Vertical Status Timeline history tracking */}
            <div className="mt-5 space-y-3 pt-4 border-t border-border-card/40">
              <span className="text-xs font-bold text-text-secondary uppercase tracking-wider block">Order Status History Timeline</span>
              {loadingTimeline ? (
                <div className="text-xs text-text-secondary py-2 text-center">Fetching timeline events...</div>
              ) : timeline.length === 0 ? (
                <div className="text-xs text-text-secondary py-2 text-center">No timeline records registered.</div>
              ) : (
                <div className="relative pl-6 border-l-2 border-slate-200 space-y-4">
                  {timeline.map((t, idx) => (
                    <div key={idx} className="relative">
                      {/* Bullet icon */}
                      <span className="absolute -left-[30px] top-0.5 h-3.5 w-3.5 rounded-full bg-emerald-500 border-2 border-white flex items-center justify-center shadow" />
                      <div className="text-xs">
                        <span className="font-bold text-text-primary capitalize">{t.status.replace(/_/g, ' ')}</span>
                        <span className="text-[10px] text-text-secondary ml-2 font-medium">by {t.changed_by}</span>
                        <span className="text-[9px] text-text-secondary block mt-0.5">
                          {new Date(t.created_at).toLocaleString('en-US', { year: 'numeric', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' })}
                        </span>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>

            {/* Ordered Items List */}
            <div className="mt-5 space-y-3 border-t border-border-card/40 pt-4">
              <span className="text-xs font-bold text-text-secondary uppercase tracking-wider block">Cart breakdown</span>
              <div className="border border-border-card rounded-xl overflow-hidden divide-y divide-border-card max-h-44 overflow-y-auto">
                {Array.isArray(selectedOrder.items) && selectedOrder.items.length > 0 ? (
                  selectedOrder.items.map((item, idx) => (
                    <div key={idx} className="p-2.5 flex items-center justify-between hover:bg-slate-50 transition-colors text-xs">
                      <div className="flex items-center gap-2">
                        {item.image_url ? (
                          <img
                            src={item.image_url}
                            alt={item.title}
                            className="h-8 w-8 rounded-lg object-cover border bg-white shrink-0"
                          />
                        ) : (
                          <div className="h-8 w-8 rounded-lg bg-emerald-50 border border-emerald-200 text-emerald-700 flex items-center justify-center font-bold text-xs shrink-0">
                            📦
                          </div>
                        )}
                        <div>
                          <span className="font-bold text-text-primary block">{item.title}</span>
                          <span className="text-[10px] text-text-secondary block mt-0.5">
                            {formatPrice(item.price)} {item.unit ? `per ${item.unit}` : ''}
                          </span>
                        </div>
                      </div>
                      <div className="text-right shrink-0">
                        <span className="text-text-primary font-bold">x{item.quantity}</span>
                        <span className="text-[10px] text-text-secondary block mt-0.5">
                          {formatPrice(item.price * item.quantity)}
                        </span>
                      </div>
                    </div>
                  ))
                ) : (
                  <div className="p-4 text-center text-xs text-text-secondary">
                    No item list found for this order.
                  </div>
                )}
              </div>
            </div>

            {/* Price Subtotal block */}
            <div className="mt-5 pt-4 border-t border-border-card/60 flex items-center justify-between">
              <div>
                <span className="text-xs font-bold text-text-secondary uppercase">Grand Invoice Bill</span>
              </div>
              <span className="text-lg font-black text-emerald-600">{formatPrice(selectedOrder.totalAmount)}</span>
            </div>

            {/* Status change actions */}
            <div className="mt-6 flex gap-3">
              <button
                onClick={() => {
                  setIsDetailsOpen(false);
                  setSelectedOrder(null);
                }}
                className="flex-1 rounded-xl border border-border-card py-2 text-xs font-bold text-text-secondary hover:bg-slate-50 transition-all cursor-pointer"
              >
                Close View
              </button>
              <button
                onClick={() => handleUpdateStatus(selectedOrder.id, selectedOrder.status)}
                className="flex-1 flex items-center justify-center gap-1.5 rounded-xl bg-emerald-600 py-2 text-xs font-bold text-white hover:brightness-110 active:scale-98 transition-all cursor-pointer shadow-md"
              >
                <Eye className="h-4 w-4" />
                <span>Update Status</span>
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
