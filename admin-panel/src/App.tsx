import { useState, useEffect } from 'react';
import Sidebar from './components/Sidebar';
import Header from './components/Header';
import ProductTable from './components/ProductTable';
import AddProductModal from './components/AddProductModal';
import EditProductModal from './components/EditProductModal';
import CategoryTable from './components/CategoryTable';
import OrdersTable from './components/OrdersTable';
import CustomerTable from './components/CustomerTable';
import AnalyticsView from './components/AnalyticsView';
import SettingsView from './components/SettingsView';
import { saveProducts, type Product } from './utils/mockApi';
import { getSwal, showToast } from './utils/alerts';
import { getAdminHeaders, getBackendUrl, formatPrice } from './utils/config';
import { 
  DollarSign, 
  Package, 
  Users,
  ShoppingCart,
  TrendingUp
} from 'lucide-react';

function WeeklySalesChart({ data }: { data: number[] }) {
  const maxVal = Math.max(...data, 1000);
  const points = data.map((val, idx) => {
    const x = 50 + idx * 70;
    const y = 180 - (val / maxVal) * 130;
    return { x, y, val };
  });

  const pathD = points.reduce((acc, p, idx) => {
    if (idx === 0) return `M ${p.x} ${p.y}`;
    const prev = points[idx - 1];
    const cpX1 = prev.x + 30;
    const cpY1 = prev.y;
    const cpX2 = p.x - 30;
    const cpY2 = p.y;
    return `${acc} C ${cpX1} ${cpY1}, ${cpX2} ${cpY2}, ${p.x} ${p.y}`;
  }, '');

  const areaD = points.length > 0 
    ? `${pathD} L ${points[points.length - 1].x} 180 L ${points[0].x} 180 Z` 
    : '';

  return (
    <svg className="w-full h-64" viewBox="0 0 520 220">
      <defs>
        <linearGradient id="chartGradient" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="#ac004d" stopOpacity="0.25" />
          <stop offset="100%" stopColor="#ac004d" stopOpacity="0.0" />
        </linearGradient>
      </defs>
      {/* Grid lines */}
      <line x1="40" y1="50" x2="490" y2="50" stroke="#e2e8f0" strokeDasharray="3" strokeWidth="0.5" />
      <line x1="40" y1="115" x2="490" y2="115" stroke="#e2e8f0" strokeDasharray="3" strokeWidth="0.5" />
      <line x1="40" y1="180" x2="490" y2="180" stroke="#cbd5e1" strokeWidth="1" />
      
      {/* Gradient fill */}
      {areaD && <path d={areaD} fill="url(#chartGradient)" />}
      
      {/* Smooth curve line */}
      {pathD && <path d={pathD} fill="none" stroke="#ac004d" strokeWidth="3" strokeLinecap="round" />}
      
      {/* Circles and values */}
      {points.map((p, idx) => (
        <g key={idx} className="group cursor-pointer">
          <circle 
            cx={p.x} 
            cy={p.y} 
            r="4.5" 
            fill="#ac004d" 
            stroke="#ffffff" 
            strokeWidth="1.5" 
            className="transition-all duration-200 group-hover:r-6"
          />
          <text 
            x={p.x} 
            y={p.y - 12} 
            textAnchor="middle" 
            className="text-[9px] font-bold fill-[#ac004d] opacity-0 group-hover:opacity-100 transition-opacity duration-200"
          >
            Rs.{p.val.toFixed(0)}
          </text>
        </g>
      ))}
      
      {/* Labels */}
      {['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((day, idx) => (
        <text 
          key={idx} 
          x={50 + idx * 70} 
          y={202} 
          textAnchor="middle" 
          className="text-xs font-semibold fill-[#5a3f45]"
        >
          {day}
        </text>
      ))}
    </svg>
  );
}

function StatusDoughnutChart({ delivered, pending, cancelled }: { delivered: number, pending: number, cancelled: number }) {
  const total = delivered + pending + cancelled;
  const pDelivered = total > 0 ? (delivered / total) * 100 : 0;
  const pPending = total > 0 ? (pending / total) * 100 : 0;
  const pCancelled = total > 0 ? (cancelled / total) * 100 : 0;

  const radius = 35;
  const circumference = 2 * Math.PI * radius; // ~219.9

  const strokeDelivered = (pDelivered / 100) * circumference;
  const strokePending = (pPending / 100) * circumference;
  const strokeCancelled = (pCancelled / 100) * circumference;

  return (
    <div className="flex flex-col sm:flex-row items-center gap-6 justify-center w-full py-4">
      <div className="relative h-36 w-36 flex items-center justify-center">
        <svg className="h-full w-full -rotate-90" viewBox="0 0 100 100">
          {/* Background circle */}
          <circle cx="50" cy="50" r={radius} fill="transparent" stroke="#f1f5f9" strokeWidth="8" />
          
          {/* Delivered slice */}
          <circle
            cx="50"
            cy="50"
            r={radius}
            fill="transparent"
            stroke="#006b56"
            strokeWidth="10"
            strokeDasharray={`${strokeDelivered} ${circumference}`}
            strokeDashoffset={0}
            strokeLinecap="round"
          />
          {/* Pending slice */}
          <circle
            cx="50"
            cy="50"
            r={radius}
            fill="transparent"
            stroke="#ac004d"
            strokeWidth="10"
            strokeDasharray={`${strokePending} ${circumference}`}
            strokeDashoffset={-strokeDelivered}
            strokeLinecap="round"
          />
          {/* Cancelled slice */}
          <circle
            cx="50"
            cy="50"
            r={radius}
            fill="transparent"
            stroke="#ba1a1a"
            strokeWidth="10"
            strokeDasharray={`${strokeCancelled} ${circumference}`}
            strokeDashoffset={-(strokeDelivered + strokePending)}
            strokeLinecap="round"
          />
        </svg>
        <div className="absolute flex flex-col items-center justify-center">
          <span className="text-xl font-black text-[#27171b]">{total}</span>
          <span className="text-[9px] uppercase font-bold tracking-wider text-[#5a3f45]">Total</span>
        </div>
      </div>
      
      {/* Legend list */}
      <div className="space-y-1.5 shrink-0">
        <div className="flex items-center gap-2">
          <span className="h-2.5 w-2.5 rounded-full bg-[#006b56]" />
          <span className="text-xs font-semibold text-[#27171b]">Delivered: {delivered} ({pDelivered.toFixed(0)}%)</span>
        </div>
        <div className="flex items-center gap-2">
          <span className="h-2.5 w-2.5 rounded-full bg-[#ac004d]" />
          <span className="text-xs font-semibold text-[#27171b]">Pending: {pending} ({pPending.toFixed(0)}%)</span>
        </div>
        <div className="flex items-center gap-2">
          <span className="h-2.5 w-2.5 rounded-full bg-[#ba1a1a]" />
          <span className="text-xs font-semibold text-[#27171b]">Cancelled: {cancelled} ({pCancelled.toFixed(0)}%)</span>
        </div>
      </div>
    </div>
  );
}

export default function App() {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [currentTab, setCurrentTab] = useState('products');
  const [searchTerm, setSearchTerm] = useState('');
  const [products, setProducts] = useState<Product[]>([]);
  const [orders, setOrders] = useState<any[]>([]);
  const [customers, setCustomers] = useState<any[]>([]);
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [editingProduct, setEditingProduct] = useState<Product | null>(null);

  // Load dashboard stats (orders & customers)
  const loadDashboardStats = async () => {
    try {
      const headers = getAdminHeaders();
      const backendUrl = getBackendUrl();

      // Fetch orders
      const ordersRes = await fetch(`${backendUrl}/api/v1/admin/orders`, {
        headers: { ...headers, 'bypass-tunnel-reminder': 'true' }
      });
      if (ordersRes.ok) {
        const json = await ordersRes.json();
        if (json.success && Array.isArray(json.data)) {
          setOrders(json.data);
        }
      }

      // Fetch customers
      const usersRes = await fetch(`${backendUrl}/api/v1/admin/users`, {
        headers: { ...headers, 'bypass-tunnel-reminder': 'true' }
      });
      if (usersRes.ok) {
        const json = await usersRes.json();
        if (json.success && json.data && Array.isArray(json.data.users)) {
          setCustomers(json.data.users);
        }
      }
    } catch (err) {
      console.warn("Failed to load dashboard metrics:", err);
    }
  };

  const handleProductUpdated = (updatedProduct: Product) => {
    setProducts(prev => prev.map(p => p.id === updatedProduct.id ? updatedProduct : p));
  };

  // Theme state: defaults to 'theme-foodexpress'
  const [theme, setTheme] = useState<string>(() => {
    return localStorage.getItem('admin_theme') || 'theme-foodexpress';
  });

  const changeTheme = (newTheme: string) => {
    setTheme(newTheme);
    localStorage.setItem('admin_theme', newTheme);
  };

  // Sync theme class to document element for portals/modals/variables to render perfectly
  useEffect(() => {
    const root = window.document.documentElement;
    const themeClasses = [
      'theme-light-default', 'theme-dark-slate', 'theme-emerald-glass', 'theme-midnight-violet',
      'theme-nordic-frost', 'theme-cyberpunk', 'theme-sunset-gold', 'theme-rose-sakura',
      'theme-crimson-phantom', 'theme-forest-moss', 'theme-ocean-abreeze', 'theme-retro-amber',
      'light', 'dark'
    ];
    root.classList.remove(...themeClasses);
    root.classList.add(theme);
    
    // Compatibility flag for 3rd party components
    if (theme === 'theme-light-default') {
      root.classList.add('light');
    } else {
      root.classList.add('dark');
    }
  }, [theme]);

  // Load products from backend (live/real-time)
  const loadBackendProducts = async () => {
    try {
      const res = await fetch(`${getBackendUrl()}/api/v1/products?limit=100`, {
        headers: { 'bypass-tunnel-reminder': 'true' }
      });
      const json = await res.json();
      if (json.success && Array.isArray(json.data)) {
        const mapped: Product[] = json.data.map((item: any) => ({
          id: String(item.id),
          title: item.title,
          price: parseFloat(item.price),
          unit: item.unit || '',
          category: item.category_name || 'Fruits',
          image_url: item.image_url || '',
          stock: item.stock_quantity ?? 0
        }));
        setProducts(mapped);
      } else {
        throw new Error("Invalid structure returned");
      }
    } catch (err) {
      console.warn("Failed to load products from backend:", err);
      setProducts([]);
    }
  };

  useEffect(() => {
    loadBackendProducts();
    loadDashboardStats();
  }, [currentTab]);

  const handleProductAdded = (newProduct: Product) => {
    setProducts(prev => [newProduct, ...prev]);
  };

  const handleDeleteProduct = async (id: string) => {
    const swal = getSwal();
    const result = await swal.fire({
      title: 'Delete Product?',
      text: "Are you sure you want to delete this product? This action cannot be undone.",
      icon: 'warning',
      showCancelButton: true,
      confirmButtonText: 'Yes, delete it',
      cancelButtonText: 'Cancel',
      reverseButtons: true
    });

    if (result.isConfirmed) {
      try {
        const isBackendProduct = !isNaN(Number(id));
        if (isBackendProduct) {
          const res = await fetch(`${getBackendUrl()}/api/v1/admin/products/${id}`, {
            method: 'DELETE',
            headers: getAdminHeaders()
          });
          if (!res.ok) {
            throw new Error(`Backend response status ${res.status}`);
          }
        }
        
        // Remove locally from state and mock fallback
        const updated = products.filter(p => p.id !== id);
        setProducts(updated);
        saveProducts(updated);
        
        showToast('success', 'Product deleted successfully!');
      } catch (err: any) {
        console.error("Failed to delete product:", err);
        swal.fire({
          title: 'Error!',
          text: `Failed to delete product from database: ${err.message}`,
          icon: 'error'
        });
      }
    }
  };

  return (
    <div className={`flex h-screen w-screen overflow-hidden font-sans transition-colors duration-200 ${theme} bg-body text-text-primary`}>
      
      {/* Sidebar Component */}
      <Sidebar 
        isOpen={sidebarOpen} 
        onClose={() => setSidebarOpen(false)} 
        currentTab={currentTab} 
        setCurrentTab={setCurrentTab} 
        theme={theme}
      />

      {/* Main Content Area */}
      <div className="flex flex-1 flex-col overflow-hidden">
        
        {/* Top Header */}
        <Header 
          onMenuToggle={() => setSidebarOpen(true)} 
          searchTerm={searchTerm} 
          setSearchTerm={setSearchTerm} 
          theme={theme}
          onChangeTheme={changeTheme}
        />

        {/* Content Container */}
        <main className="flex-1 overflow-y-auto p-6 bg-body">
          <div className="mx-auto max-w-7xl space-y-6">
            
            {/* Header Title Bar */}
            <div className="flex flex-col gap-2 md:flex-row md:items-center md:justify-between">
              <div>
                <h1 className="text-2xl font-bold tracking-tight text-text-primary capitalize">
                  {currentTab === 'products' ? 'Product Inventory Management' : `${currentTab} Overview`}
                </h1>
                <p className="text-sm text-text-secondary">
                  {currentTab === 'products' 
                    ? 'Search, filter, edit, and add catalog items with automatic client-side asset optimization' 
                    : 'System analytics, server health, and operations logs'}
                </p>
              </div>

              {/* Breadcrumb info */}
              <div className="flex items-center gap-2 rounded-xl bg-panel px-3 py-1.5 text-xs font-semibold text-text-secondary border border-border-card">
                <span className="h-2 w-2 rounded-full bg-emerald-500 animate-pulse" />
                <span>Live System Status</span>
              </div>
            </div>

            {/* Render Tab Views */}
            {currentTab === 'products' ? (
              <ProductTable 
                products={products}
                onAddProductClick={() => setIsAddModalOpen(true)}
                onEditProductClick={(product) => setEditingProduct(product)}
                onDeleteProduct={handleDeleteProduct}
                searchTerm={searchTerm}
              />
            ) : currentTab === 'categories' ? (
              <CategoryTable />
            ) : currentTab === 'dashboard' ? (
              (() => {
                const weeklySales = (() => {
                  const sales = [0, 0, 0, 0, 0, 0, 0];
                  orders.forEach(o => {
                    if (o.status !== 'Cancelled' && o.created_at) {
                      const date = new Date(o.created_at);
                      const day = date.getDay();
                      const idx = day === 0 ? 6 : day - 1;
                      sales[idx] += o.totalAmount || 0;
                    }
                  });
                  if (sales.every(s => s === 0)) {
                    return [1200, 1900, 1500, 2400, 2100, 3200, 2800];
                  }
                  return sales;
                })();

                const statusCounts = (() => {
                  let delivered = 0;
                  let pending = 0;
                  let cancelled = 0;
                  orders.forEach(o => {
                    const status = (o.status || '').toLowerCase();
                    if (status === 'delivered' || status === 'completed') {
                      delivered++;
                    } else if (status === 'cancelled') {
                      cancelled++;
                    } else {
                      pending++;
                    }
                  });
                  if (delivered === 0 && pending === 0 && cancelled === 0) {
                    return { delivered: 75, pending: 20, cancelled: 5 };
                  }
                  return { delivered, pending, cancelled };
                })();

                const recentOrdersList = orders.slice(0, 4);
                const topProductsList = [...products].sort((a, b) => b.stock - a.stock).slice(0, 4);

                return (
                  <div className="space-y-6">
                    {/* KPI Stats Bento Grid */}
                    <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4">
                      {[
                        { 
                          label: 'Total Orders', 
                          val: orders.length.toLocaleString(), 
                          change: 'All registered transactions', 
                          icon: ShoppingCart, 
                          color: 'text-[#ac004d]', 
                          bg: 'bg-[#ac004d]/10' 
                        },
                        { 
                          label: 'Net Revenue', 
                          val: formatPrice(orders.filter(o => o.status !== 'Cancelled').reduce((acc, o) => acc + o.totalAmount, 0)), 
                          change: 'Excluding cancelled orders', 
                          icon: DollarSign, 
                          color: 'text-[#006b56]', 
                          bg: 'bg-[#006b56]/10' 
                        },
                        { 
                          label: 'Active Customers', 
                          val: customers.length.toString(), 
                          change: 'Verified shopper profiles', 
                          icon: Users, 
                          color: 'text-indigo-600', 
                          bg: 'bg-indigo-600/10' 
                        },
                        { 
                          label: 'Pending Orders', 
                          val: orders.filter(o => (o.status || '').toLowerCase() === 'pending').length.toString(), 
                          change: 'Requires prompt shipping', 
                          icon: Package, 
                          color: 'text-amber-600', 
                          bg: 'bg-amber-600/10' 
                        },
                      ].map((stat, idx) => {
                        const Icon = stat.icon;
                        return (
                          <div key={idx} className="rounded-2xl glass-card float-card p-5 flex items-center justify-between shadow-lg">
                            <div>
                              <p className="text-xs font-bold text-text-secondary uppercase tracking-wider">{stat.label}</p>
                              <h3 className="mt-2 text-2xl font-black text-text-primary">{stat.val}</h3>
                              <span className="text-[10px] font-bold text-text-secondary mt-1 block">{stat.change}</span>
                            </div>
                            <div className={`rounded-xl p-3 ${stat.color} ${stat.bg}`}>
                              <Icon className="h-6 w-6" />
                            </div>
                          </div>
                        );
                      })}
                    </div>

                    {/* Chart visualizations */}
                    <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
                      {/* Weekly Sales (Line chart) */}
                      <div className="lg:col-span-2 rounded-2xl glass-panel p-5 float-card shadow-lg relative overflow-hidden">
                        <div className="mesh-glow-orb right-0 top-0 h-40 w-40 bg-[#ac004d]/5" />
                        <div className="flex justify-between items-center mb-6 relative z-10">
                          <h4 className="text-sm font-bold text-text-primary uppercase tracking-wider">Weekly Revenue Analytics</h4>
                          <span className="text-xs font-semibold text-text-secondary">Last 7 Days</span>
                        </div>
                        <div className="relative z-10">
                          <WeeklySalesChart data={weeklySales} />
                        </div>
                      </div>

                      {/* Order Status Distribution (Doughnut chart) */}
                      <div className="rounded-2xl glass-panel p-5 float-card shadow-lg relative overflow-hidden">
                        <div className="mesh-glow-orb left-0 bottom-0 h-40 w-40 bg-[#006b56]/5" />
                        <h4 className="text-sm font-bold text-text-primary uppercase tracking-wider mb-6 relative z-10">Order Status Distribution</h4>
                        <div className="relative z-10 flex h-full items-center justify-center pb-6">
                          <StatusDoughnutChart 
                            delivered={statusCounts.delivered} 
                            pending={statusCounts.pending} 
                            cancelled={statusCounts.cancelled} 
                          />
                        </div>
                      </div>
                    </div>

                    {/* Split Table & Top Lists */}
                    <div className="grid grid-cols-1 xl:grid-cols-4 gap-6 items-start">
                      {/* Recent Orders table */}
                      <div className="xl:col-span-3 rounded-2xl glass-panel shadow-lg overflow-hidden border border-border-card/30">
                        <div className="p-5 border-b border-border-card/40 flex justify-between items-center bg-white/40">
                          <h4 className="text-sm font-bold text-text-primary uppercase tracking-wider">Recent Live Orders</h4>
                          <button onClick={() => setCurrentTab('orders')} className="text-[#ac004d] font-bold text-xs hover:underline cursor-pointer">
                            View All Orders
                          </button>
                        </div>
                        <div className="overflow-x-auto">
                          <table className="w-full text-left">
                            <thead className="bg-[#fff8f7]/60 border-b border-border-card/30">
                              <tr>
                                <th className="px-5 py-3 text-xs font-bold text-text-secondary uppercase tracking-wider">Order ID</th>
                                <th className="px-5 py-3 text-xs font-bold text-text-secondary uppercase tracking-wider">Customer</th>
                                <th className="px-5 py-3 text-xs font-bold text-text-secondary uppercase tracking-wider">Amount</th>
                                <th className="px-5 py-3 text-xs font-bold text-text-secondary uppercase tracking-wider">Status</th>
                                <th className="px-5 py-3 text-xs font-bold text-text-secondary uppercase tracking-wider">Action</th>
                              </tr>
                            </thead>
                            <tbody className="divide-y divide-border-card/20">
                              {recentOrdersList.length === 0 ? (
                                <tr>
                                  <td colSpan={5} className="px-5 py-6 text-center text-xs text-text-secondary">
                                    No registered orders available.
                                  </td>
                                </tr>
                              ) : (
                                recentOrdersList.map((order) => (
                                  <tr key={order.id} className="hover:bg-hover-panel/40 transition-colors">
                                    <td className="px-5 py-3.5 text-xs font-bold text-text-primary">#FC-{order.id}</td>
                                    <td className="px-5 py-3.5 text-xs text-text-secondary">
                                      <div>{order.customerName}</div>
                                      <div className="text-[10px] text-text-secondary/50 font-mono mt-0.5">{order.email}</div>
                                    </td>
                                    <td className="px-5 py-3.5 text-xs font-black text-text-primary">{formatPrice(order.totalAmount)}</td>
                                    <td className="px-5 py-3.5 text-xs">
                                      <span className={`px-2.5 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider ${
                                        order.status === 'Delivered' 
                                          ? 'bg-[#006b56]/10 text-[#006b56] border border-[#006b56]/20'
                                          : order.status === 'Cancelled'
                                            ? 'bg-red-500/10 text-red-500 border border-red-500/20'
                                            : 'bg-[#ac004d]/10 text-[#ac004d] border border-[#ac004d]/20'
                                      }`}>
                                        {order.status}
                                      </span>
                                    </td>
                                    <td className="px-5 py-3.5 text-xs">
                                      <button 
                                        onClick={() => setCurrentTab('orders')}
                                        className="text-[#ac004d] font-bold text-xs hover:text-[#ac004d]/80 cursor-pointer"
                                      >
                                        Details
                                      </button>
                                    </td>
                                  </tr>
                                ))
                              )}
                            </tbody>
                          </table>
                        </div>
                      </div>

                      {/* Top Products side list */}
                      <div className="rounded-2xl glass-panel p-5 float-card shadow-lg relative overflow-hidden">
                        <div className="mesh-glow-orb right-0 top-0 h-32 w-32 bg-amber-500/5" />
                        <h4 className="text-sm font-bold text-text-primary uppercase tracking-wider mb-5 relative z-10">Top Stock Items</h4>
                        <div className="space-y-4 relative z-10">
                          {topProductsList.length === 0 ? (
                            <p className="text-xs text-center text-text-secondary py-4">No products in inventory.</p>
                          ) : (
                            topProductsList.map((prod) => (
                              <div key={prod.id} className="flex items-center space-x-3.5">
                                <div className="w-11 h-11 rounded-lg overflow-hidden bg-white border border-border-card/40 shrink-0 flex items-center justify-center p-0.5">
                                  <img 
                                    className="w-full h-full object-contain" 
                                    src={prod.image_url || 'https://images.unsplash.com/photo-1610348725531-843dff14c78c?auto=format&fit=crop&q=80&w=100'} 
                                    alt={prod.title}
                                  />
                                </div>
                                <div className="flex-1 min-w-0">
                                  <p className="font-bold text-xs text-text-primary truncate">{prod.title}</p>
                                  <p className="text-[10px] text-text-secondary/60 mt-0.5">{prod.stock} left in stock • {prod.unit}</p>
                                </div>
                                <p className="font-black text-xs text-[#006b56]">{formatPrice(prod.price)}</p>
                              </div>
                            ))
                          )}
                        </div>
                        <button 
                          onClick={() => setCurrentTab('products')} 
                          className="w-full mt-6 py-2.5 bg-[#ac004d]/10 hover:bg-[#ac004d]/25 text-[#ac004d] font-bold text-xs rounded-xl transition-all cursor-pointer border border-[#ac004d]/10"
                        >
                          Manage Inventory
                        </button>
                      </div>
                    </div>
                  </div>
                );
              })()
            ) : currentTab === 'orders' ? (
              <OrdersTable />
            ) : currentTab === 'customers' ? (
              <CustomerTable />
            ) : currentTab === 'analytics' ? (
              <AnalyticsView />
            ) : currentTab === 'settings' ? (
              <SettingsView theme={theme} setTheme={changeTheme} />
            ) : (
              /* General Under Construction view for other tabs */
              <div className="rounded-2xl glass-panel p-12 text-center float-card shadow-lg">
                <div className="mx-auto flex h-12 w-12 items-center justify-center rounded-xl bg-bg-input border border-border-card text-text-secondary mb-4 animate-pulse">
                  <TrendingUp className="h-6 w-6" />
                </div>
                <h3 className="text-lg font-bold text-text-primary">Tab under development</h3>
                <p className="text-sm text-text-secondary mt-1 max-w-sm mx-auto">
                  The {currentTab} view is scheduled for the next iteration. Access Product Management or Dashboard to test functionality.
                </p>
                <button
                  onClick={() => setCurrentTab('products')}
                  className="mt-5 rounded-xl bg-emerald-500 px-4 py-2 text-xs font-semibold text-slate-950 hover:brightness-110 active:scale-98 transition-all duration-200 cursor-pointer"
                >
                  Return to Products
                </button>
              </div>
            )}

          </div>
        </main>
      </div>

      {/* Add Product Modal Overlay */}
      <AddProductModal 
        isOpen={isAddModalOpen} 
        onClose={() => setIsAddModalOpen(false)} 
        onProductAdded={handleProductAdded}
      />

      {/* Edit Product Modal Overlay */}
      <EditProductModal 
        isOpen={editingProduct !== null} 
        onClose={() => setEditingProduct(null)} 
        product={editingProduct}
        onProductUpdated={handleProductUpdated}
      />
      
    </div>
  );
}
