import { useState, useEffect } from 'react';
import { 
  ShoppingCart, 
  Search, 
  RefreshCw, 
  Clock, 
  CheckCircle, 
  Truck, 
  XCircle,
  Eye,
  AlertCircle,
  MapPin,
  CreditCard,
  User,
  X
} from 'lucide-react';
import { getBackendUrl, formatPrice } from '../utils/config';
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
  status: 'Pending' | 'Shipped' | 'Completed' | 'Cancelled';
  date: string;
  paymentMethod: string;
  deliveryAddress?: string;
  items?: OrderItemDetails[] | string;
}

export default function OrdersTable() {
  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<'All' | 'Pending' | 'Shipped' | 'Completed' | 'Cancelled'>('All');
  
  // Modal details state
  const [selectedOrder, setSelectedOrder] = useState<Order | null>(null);
  const [isDetailsOpen, setIsDetailsOpen] = useState(false);
  const [updatingId, setUpdatingId] = useState<number | null>(null);

  const token = 'admin-secret-token';

  // Fetch live orders from Render backend
  const fetchOrders = async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await fetch(`${getBackendUrl()}/api/v1/admin/orders`, {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${token}`,
          'X-Admin-Token': token,
          'bypass-tunnel-reminder': 'true',
          'Content-Type': 'application/json'
        }
      });

      if (!res.ok) {
        throw new Error(`Server returned status: ${res.status}`);
      }

      const json = await res.json();
      if (json.success && Array.isArray(json.data)) {
        // Retrieve full items and address details
        // Backend maps: { id, customerName, email, itemsCount, totalAmount, status, date, paymentMethod }
        // We will fetch orders with items. If backend items field is a string, we parse it.
        const mapped: Order[] = json.data.map((order: any) => {
          let parsedItems: OrderItemDetails[] = [];
          if (order.items) {
            try {
              parsedItems = typeof order.items === 'string' ? JSON.parse(order.items) : order.items;
            } catch (e) {
              console.warn('Failed to parse items for order', order.id, e);
            }
          }
          return {
            id: order.id,
            customerName: order.customerName,
            email: order.email,
            itemsCount: order.itemsCount,
            totalAmount: order.totalAmount,
            status: order.status || 'Pending',
            date: order.date,
            paymentMethod: order.paymentMethod || 'COD',
            deliveryAddress: order.deliveryAddress || order.delivery_address || 'N/A',
            items: parsedItems
          };
        });
        setOrders(mapped);
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

  useEffect(() => {
    fetchOrders();
  }, []);

  // Update order status on backend
  const handleUpdateStatus = async (id: number, currentStatus: string, e?: React.MouseEvent) => {
    if (e) e.stopPropagation(); // Prevent opening modal details
    
    const swal = getSwal();
    const result = await swal.fire({
      title: 'Update Order Status',
      text: `Select new status for order #${id}:`,
      input: 'select',
      inputOptions: {
        'Pending': 'Pending',
        'Shipped': 'Shipped',
        'Completed': 'Completed',
        'Cancelled': 'Cancelled'
      },
      inputValue: currentStatus,
      showCancelButton: true,
      confirmButtonText: 'Update Status',
      cancelButtonText: 'Cancel',
      reverseButtons: true
    });

    if (result.isConfirmed && result.value) {
      setUpdatingId(id);
      try {
        const res = await fetch(`${getBackendUrl()}/api/v1/admin/orders/${id}`, {
          method: 'PUT',
          headers: {
            'Authorization': `Bearer ${token}`,
            'X-Admin-Token': token,
            'bypass-tunnel-reminder': 'true',
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({ status: result.value })
        });

        const json = await res.json();
        if (!res.ok) {
          throw new Error(json.message || 'Failed to update order status');
        }

        showToast('success', `Order status updated to ${result.value}`);
        
        // Update local state
        setOrders(prev => prev.map(order => 
          order.id === id ? { ...order, status: result.value as any } : order
        ));
        
        // Update details modal state if active
        if (selectedOrder && selectedOrder.id === id) {
          setSelectedOrder(prev => prev ? { ...prev, status: result.value as any } : null);
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

  const getStatusStyle = (status: Order['status']) => {
    switch (status) {
      case 'Pending':
        return 'bg-amber-500/10 text-amber-400 border-amber-500/20';
      case 'Shipped':
        return 'bg-blue-500/10 text-blue-400 border-blue-500/20';
      case 'Completed':
        return 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20';
      case 'Cancelled':
        return 'bg-red-500/10 text-red-400 border-red-500/20';
    }
  };

  // Filter orders
  const filteredOrders = orders.filter(order => {
    const matchesSearch = 
      String(order.id).toLowerCase().includes(searchTerm.toLowerCase()) ||
      order.customerName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      order.email.toLowerCase().includes(searchTerm.toLowerCase());
    
    const matchesStatus = statusFilter === 'All' || order.status === statusFilter;
    return matchesSearch && matchesStatus;
  });

  return (
    <div className="space-y-6">
      {/* Top Banner */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between rounded-2xl border border-border-card bg-panel p-5">
        <div>
          <h2 className="text-lg font-bold text-text-primary flex items-center gap-2">
            <ShoppingCart className="h-5.5 w-5.5 text-emerald-400" />
            Live Customer Orders
          </h2>
          <p className="text-xs text-text-secondary mt-0.5">
            Audit billing, view details, and track shipping status of all grocery orders.
          </p>
        </div>
        <button
          onClick={fetchOrders}
          disabled={loading}
          className="flex items-center gap-2 rounded-xl bg-emerald-500/10 hover:bg-emerald-500/20 text-emerald-400 border border-emerald-500/20 px-4 py-2 text-xs font-semibold transition-all cursor-pointer disabled:opacity-50"
        >
          <RefreshCw className={`h-3.5 w-3.5 ${loading ? 'animate-spin' : ''}`} />
          <span>Reload Data</span>
        </button>
      </div>

      {/* Filter and Search Toolbar */}
      <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between rounded-2xl border border-border-card bg-panel p-4">
        {/* Search */}
        <div className="relative max-w-xs w-full">
          <span className="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none">
            <Search className="h-4 w-4 text-text-secondary" />
          </span>
          <input
            type="text"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            placeholder="Search by ID, customer name..."
            className="w-full rounded-xl bg-bg-input border border-border-card py-2 pl-9 pr-4 text-sm text-text-primary focus:outline-none focus:border-emerald-500 transition-colors"
          />
        </div>

        {/* Status Filters */}
        <div className="flex flex-wrap gap-1.5">
          {(['All', 'Pending', 'Shipped', 'Completed', 'Cancelled'] as const).map((filter) => (
            <button
              key={filter}
              onClick={() => setStatusFilter(filter)}
              className={`rounded-lg px-3 py-1.5 text-xs font-semibold transition-all duration-200 cursor-pointer ${
                statusFilter === filter
                  ? 'bg-emerald-500 text-slate-950 shadow-md shadow-emerald-500/10'
                  : 'bg-bg-input text-text-secondary hover:bg-hover-panel hover:text-text-primary border border-border-card'
              }`}
            >
              {filter}
            </button>
          ))}
        </div>
      </div>

      {/* Orders Table container */}
      <div className="overflow-hidden rounded-2xl border border-border-card bg-panel shadow-md">
        {loading ? (
          <div className="flex flex-col items-center justify-center py-20 space-y-4">
            <RefreshCw className="h-8 w-8 text-emerald-400 animate-spin" />
            <span className="text-sm text-text-secondary font-medium">Fetching customer orders...</span>
          </div>
        ) : error ? (
          <div className="flex flex-col items-center justify-center py-16 px-6 text-center space-y-3">
            <div className="rounded-full bg-red-500/10 p-3 text-red-400 border border-red-500/20">
              <AlertCircle className="h-6 w-6" />
            </div>
            <h3 className="text-base font-bold text-text-primary">Failed to load data</h3>
            <p className="text-sm text-text-secondary max-w-md">{error}</p>
            <button
              onClick={fetchOrders}
              className="mt-2 rounded-xl bg-emerald-500 px-4 py-2 text-xs font-semibold text-slate-950 hover:brightness-110 active:scale-98 transition-all cursor-pointer"
            >
              Try Again
            </button>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="border-b border-border-card bg-panel/50 text-xs font-semibold tracking-wider text-text-secondary">
                  <th className="px-6 py-4.5">Order ID</th>
                  <th className="px-6 py-4.5">Customer</th>
                  <th className="px-6 py-4.5">Items</th>
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
                      className="hover:bg-hover-panel transition-colors duration-150 cursor-pointer"
                    >
                      <td className="px-6 py-4 font-mono font-semibold text-text-primary">
                        #{order.id}
                      </td>
                      <td className="px-6 py-4">
                        <div>
                          <span className="font-semibold text-text-primary block">{order.customerName}</span>
                          <span className="text-xs text-text-secondary block mt-0.5">{order.email}</span>
                        </div>
                      </td>
                      <td className="px-6 py-4 text-text-primary">
                        {order.itemsCount} items
                      </td>
                      <td className="px-6 py-4 font-semibold text-text-primary">
                        {formatPrice(order.totalAmount)}
                      </td>
                      <td className="px-6 py-4">
                        <span className={`inline-flex items-center gap-1.5 rounded-lg px-2.5 py-1 text-xs font-semibold border ${getStatusStyle(order.status)}`}>
                          {order.status === 'Pending' && <Clock className="h-3.5 w-3.5" />}
                          {order.status === 'Shipped' && <Truck className="h-3.5 w-3.5" />}
                          {order.status === 'Completed' && <CheckCircle className="h-3.5 w-3.5" />}
                          {order.status === 'Cancelled' && <XCircle className="h-3.5 w-3.5" />}
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
                          className="rounded-lg p-2 text-text-secondary hover:bg-hover-panel hover:text-emerald-400 transition-colors cursor-pointer"
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
                    <td colSpan={7} className="px-6 py-16 text-center text-text-secondary">
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
          <div className="relative w-full max-w-lg rounded-2xl border border-border-card bg-panel p-6 shadow-2xl animate-in fade-in zoom-in duration-200 max-h-[85vh] overflow-y-auto">
            {/* Close */}
            <button
              onClick={() => {
                setIsDetailsOpen(false);
                setSelectedOrder(null);
              }}
              className="absolute right-4 top-4 rounded-lg p-1.5 text-text-secondary hover:bg-hover-panel hover:text-text-primary transition-colors cursor-pointer"
            >
              <X className="h-5 w-5" />
            </button>

            {/* Header info */}
            <div className="pb-4 border-b border-border-card/60">
              <h3 className="text-lg font-bold text-text-primary flex items-center gap-2">
                <ShoppingCart className="h-5.5 w-5.5 text-emerald-400" />
                Order Details
              </h3>
              <p className="text-xs text-text-secondary mt-1 font-mono">Order ID: #{selectedOrder.id} | Date: {selectedOrder.date}</p>
            </div>

            {/* Customer information card */}
            <div className="mt-4 p-4 rounded-xl bg-bg-input border border-border-card/60 space-y-3.5">
              <div className="flex items-center gap-2 text-xs font-bold text-text-secondary uppercase tracking-wider">
                <User className="h-4 w-4 text-emerald-400" />
                <span>Customer Profile</span>
              </div>
              <div className="grid grid-cols-2 gap-4 text-sm">
                <div>
                  <span className="text-xs text-text-secondary block">Full Name</span>
                  <span className="font-semibold text-text-primary block mt-0.5">{selectedOrder.customerName}</span>
                </div>
                <div>
                  <span className="text-xs text-text-secondary block">Email Address</span>
                  <span className="font-semibold text-text-primary block mt-0.5">{selectedOrder.email}</span>
                </div>
              </div>
              <div className="border-t border-border-card/40 pt-3 flex gap-4 text-sm">
                <div className="flex-1">
                  <span className="text-xs text-text-secondary flex items-center gap-1">
                    <MapPin className="h-3.5 w-3.5 text-emerald-400" /> Delivery Location
                  </span>
                  <span className="font-medium text-text-primary block mt-0.5 leading-normal">{selectedOrder.deliveryAddress}</span>
                </div>
                <div>
                  <span className="text-xs text-text-secondary flex items-center gap-1">
                    <CreditCard className="h-3.5 w-3.5 text-emerald-400" /> Payment Type
                  </span>
                  <span className="font-medium text-text-primary block mt-0.5">{selectedOrder.paymentMethod}</span>
                </div>
              </div>
            </div>

            {/* Ordered Items List */}
            <div className="mt-5 space-y-3">
              <span className="text-xs font-bold text-text-secondary uppercase tracking-wider block">Cart Breakdown</span>
              <div className="border border-border-card rounded-xl overflow-hidden divide-y divide-border-card">
                {Array.isArray(selectedOrder.items) && selectedOrder.items.length > 0 ? (
                  selectedOrder.items.map((item, idx) => (
                    <div key={idx} className="p-3 flex items-center justify-between hover:bg-hover-panel transition-colors text-sm">
                      <div className="flex items-center gap-2.5">
                        {item.image_url ? (
                          <img
                            src={item.image_url}
                            alt={item.title}
                            className="h-9 w-9 rounded-lg object-cover border border-border-card bg-white shrink-0"
                          />
                        ) : (
                          <div className="h-9 w-9 rounded-lg bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 flex items-center justify-center font-bold text-xs shrink-0">
                            FC
                          </div>
                        )}
                        <div>
                          <span className="font-semibold text-text-primary block">{item.title}</span>
                          <span className="text-xs text-text-secondary block mt-0.5">
                            {formatPrice(item.price)} {item.unit ? `per ${item.unit}` : ''}
                          </span>
                        </div>
                      </div>
                      <div className="text-right shrink-0">
                        <span className="text-text-primary font-bold">x{item.quantity}</span>
                        <span className="text-xs text-text-secondary block mt-0.5">
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
                <span className="text-xs font-semibold text-text-secondary uppercase">Grand Invoice Bill</span>
                <span className={`ml-2.5 inline-flex items-center gap-1 rounded-md px-1.5 py-0.5 text-[10px] font-bold border ${getStatusStyle(selectedOrder.status)}`}>
                  {selectedOrder.status}
                </span>
              </div>
              <span className="text-xl font-bold text-emerald-400">{formatPrice(selectedOrder.totalAmount)}</span>
            </div>

            {/* Status change actions */}
            <div className="mt-6 flex gap-3">
              <button
                onClick={() => {
                  setIsDetailsOpen(false);
                  setSelectedOrder(null);
                }}
                className="flex-1 rounded-xl border border-border-card py-2.5 text-xs font-semibold text-text-secondary hover:bg-hover-panel transition-all cursor-pointer"
              >
                Close View
              </button>
              <button
                onClick={() => handleUpdateStatus(selectedOrder.id, selectedOrder.status)}
                className="flex-1 flex items-center justify-center gap-2 rounded-xl bg-emerald-500 py-2.5 text-xs font-semibold text-slate-950 hover:brightness-110 active:scale-98 transition-all cursor-pointer"
              >
                <Eye className="h-3.5 w-3.5" />
                <span>Update Status</span>
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
