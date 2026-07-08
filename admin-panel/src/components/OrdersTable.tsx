import { useState } from 'react';
import { 
  ShoppingCart, 
  Search, 
  Eye, 
  Clock, 
  CheckCircle, 
  Truck, 
  XCircle
} from 'lucide-react';
import { getSwal, showToast } from '../utils/alerts';

interface OrderItem {
  id: string;
  customerName: string;
  email: string;
  itemsCount: number;
  totalAmount: number;
  status: 'Pending' | 'Shipped' | 'Completed' | 'Cancelled';
  date: string;
  paymentMethod: string;
}

const INITIAL_ORDERS: OrderItem[] = [
  { id: 'ORD-1041', customerName: 'Zeeshan Khan', email: 'zeeshan.khan@gmail.com', itemsCount: 5, totalAmount: 48.20, status: 'Pending', date: '2026-07-07', paymentMethod: 'Cash on Delivery' },
  { id: 'ORD-1040', customerName: 'Ayesha Ahmed', email: 'ayesha.ahmed@yahoo.com', itemsCount: 2, totalAmount: 12.50, status: 'Completed', date: '2026-07-06', paymentMethod: 'Stripe Credit' },
  { id: 'ORD-1039', customerName: 'Bilal Raza', email: 'bilal.raza@outlook.com', itemsCount: 8, totalAmount: 85.90, status: 'Shipped', date: '2026-07-05', paymentMethod: 'Cash on Delivery' },
  { id: 'ORD-1038', customerName: 'Marium Siddiqui', email: 'marium.s@gmail.com', itemsCount: 3, totalAmount: 32.40, status: 'Cancelled', date: '2026-07-04', paymentMethod: 'Stripe Credit' },
  { id: 'ORD-1037', customerName: 'Kamran Jameel', email: 'kamran.j@gmail.com', itemsCount: 4, totalAmount: 54.10, status: 'Completed', date: '2026-07-03', paymentMethod: 'Cash on Delivery' },
  { id: 'ORD-1036', customerName: 'Nida Fatima', email: 'nida.fatima@gmail.com', itemsCount: 1, totalAmount: 8.90, status: 'Completed', date: '2026-07-02', paymentMethod: 'Stripe Credit' }
];

export default function OrdersTable() {
  const [orders, setOrders] = useState<OrderItem[]>(INITIAL_ORDERS);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<'All' | 'Pending' | 'Shipped' | 'Completed' | 'Cancelled'>('All');

  // Filter orders
  const filteredOrders = orders.filter(order => {
    const matchesSearch = 
      order.id.toLowerCase().includes(searchTerm.toLowerCase()) ||
      order.customerName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      order.email.toLowerCase().includes(searchTerm.toLowerCase());
    
    const matchesStatus = statusFilter === 'All' || order.status === statusFilter;
    return matchesSearch && matchesStatus;
  });

  // Change status with SweetAlert2
  const handleUpdateStatus = async (id: string, currentStatus: string) => {
    const swal = getSwal();
    const result = await swal.fire({
      title: 'Update Order Status',
      text: `Select new status for order ${id}:`,
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
      cancelButtonText: 'Cancel'
    });

    if (result.isConfirmed && result.value) {
      setOrders(prev => prev.map(order => 
        order.id === id ? { ...order, status: result.value as any } : order
      ));
      showToast('success', `Order status updated to ${result.value}`);
    }
  };

  const getStatusStyle = (status: OrderItem['status']) => {
    switch (status) {
      case 'Pending':
        return 'bg-amber-500/10 text-amber-500 border-amber-500/20';
      case 'Shipped':
        return 'bg-blue-500/10 text-blue-500 border-blue-500/20';
      case 'Completed':
        return 'bg-emerald-500/10 text-emerald-500 border-emerald-500/20';
      case 'Cancelled':
        return 'bg-red-500/10 text-red-500 border-red-500/20';
    }
  };

  return (
    <div className="space-y-6">
      {/* Top Banner */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between rounded-2xl border border-border-card bg-panel p-5">
        <div>
          <h2 className="text-lg font-bold text-text-primary flex items-center gap-2">
            <ShoppingCart className="h-5.5 w-5.5 text-emerald-400" />
            Live Customer Orders
          </h2>
          <p className="text-xs text-text-secondary mt-0.5">Track, update shipping status, and audit billing metrics</p>
        </div>
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
            placeholder="Search orders, customers..."
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

      {/* Orders Table */}
      <div className="overflow-hidden rounded-2xl border border-border-card bg-panel shadow-md">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-border-card bg-panel text-xs font-semibold tracking-wider text-text-secondary">
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
                  <tr key={order.id} className="hover:bg-hover-panel transition-colors duration-150">
                    <td className="px-6 py-4 font-mono font-semibold text-text-primary">
                      {order.id}
                    </td>
                    <td className="px-6 py-4">
                      <div>
                        <span className="font-semibold text-text-primary block">{order.customerName}</span>
                        <span className="text-xs text-text-secondary block">{order.email}</span>
                      </div>
                    </td>
                    <td className="px-6 py-4 text-text-primary">
                      {order.itemsCount} items
                    </td>
                    <td className="px-6 py-4 font-semibold text-text-primary">
                      ${order.totalAmount.toFixed(2)}
                    </td>
                    <td className="px-6 py-4">
                      <span className={`inline-flex items-center gap-1 rounded-lg px-2.5 py-1 text-xs font-semibold border ${getStatusStyle(order.status)}`}>
                        {order.status === 'Pending' && <Clock className="h-3 w-3" />}
                        {order.status === 'Shipped' && <Truck className="h-3 w-3" />}
                        {order.status === 'Completed' && <CheckCircle className="h-3 w-3" />}
                        {order.status === 'Cancelled' && <XCircle className="h-3 w-3" />}
                        {order.status}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-text-secondary text-xs">
                      {order.date}
                    </td>
                    <td className="px-6 py-4 text-right">
                      <button
                        onClick={() => handleUpdateStatus(order.id, order.status)}
                        className="rounded-lg p-2 text-text-secondary hover:bg-hover-panel hover:text-text-primary transition-colors cursor-pointer"
                        title="Update Status"
                      >
                        <Eye className="h-4.5 w-4.5" />
                      </button>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={7} className="px-6 py-12 text-center text-text-secondary">
                    No orders found matching filters.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
