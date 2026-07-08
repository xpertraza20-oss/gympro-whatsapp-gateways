import { useState, useEffect } from 'react';
import Sidebar from './components/Sidebar';
import Header from './components/Header';
import ProductTable from './components/ProductTable';
import AddProductModal from './components/AddProductModal';
import CategoryTable from './components/CategoryTable';
import OrdersTable from './components/OrdersTable';
import CustomerTable from './components/CustomerTable';
import AnalyticsView from './components/AnalyticsView';
import SettingsView from './components/SettingsView';
import { saveProducts, type Product } from './utils/mockApi';
import { getSwal, showToast } from './utils/alerts';
import { getBackendUrl, formatPrice } from './utils/config';
import { 
  ShoppingBag, 
  TrendingUp, 
  DollarSign, 
  Package, 
  Activity,
  HelpCircle
} from 'lucide-react';

export default function App() {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [currentTab, setCurrentTab] = useState('products');
  const [searchTerm, setSearchTerm] = useState('');
  const [products, setProducts] = useState<Product[]>([]);
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);

  // Theme state: defaults to 'light'
  const [theme, setTheme] = useState<'dark' | 'light'>(() => {
    return (localStorage.getItem('admin_theme') as 'dark' | 'light') || 'light';
  });

  const toggleTheme = () => {
    setTheme(prev => {
      const next = prev === 'dark' ? 'light' : 'dark';
      localStorage.setItem('admin_theme', next);
      return next;
    });
  };

  // Sync theme class to document element for portals/modals/variables to render perfectly
  useEffect(() => {
    const root = window.document.documentElement;
    root.classList.remove('light', 'dark');
    root.classList.add(theme);
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
  }, []);

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
      const AUTH_TOKEN = 'admin-secret-token';
      try {
        const isBackendProduct = !isNaN(Number(id));
        if (isBackendProduct) {
          const res = await fetch(`${getBackendUrl()}/api/v1/admin/products/${id}`, {
            method: 'DELETE',
            headers: {
              'Authorization': `Bearer ${AUTH_TOKEN}`,
              'bypass-tunnel-reminder': 'true'
            }
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
          toggleTheme={toggleTheme}
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
                onDeleteProduct={handleDeleteProduct}
                searchTerm={searchTerm}
              />
            ) : currentTab === 'categories' ? (
              <CategoryTable />
            ) : currentTab === 'dashboard' ? (
              /* Premium Mock Dashboard View */
              <div className="space-y-6">
                {/* Stats Grid */}
                <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
                  {[
                    { 
                      label: 'Inventory Valuation', 
                      val: formatPrice(products.reduce((acc, p) => acc + (p.price * p.stock), 0)), 
                      change: 'Total stock value', 
                      icon: DollarSign, 
                      color: 'text-emerald-400', 
                      bg: 'bg-emerald-500/10' 
                    },
                    { 
                      label: 'Total Stock Items', 
                      val: products.reduce((acc, p) => acc + p.stock, 0).toLocaleString(), 
                      change: 'Items in warehouse', 
                      icon: ShoppingBag, 
                      color: 'text-blue-400', 
                      bg: 'bg-blue-500/10' 
                    },
                    { 
                      label: 'Avg Product Price', 
                      val: formatPrice(products.length > 0 ? (products.reduce((acc, p) => acc + p.price, 0) / products.length) : 0), 
                      change: 'Across all items', 
                      icon: Activity, 
                      color: 'text-purple-400', 
                      bg: 'bg-purple-500/10' 
                    },
                    { 
                      label: 'Low Stock SKU alert', 
                      val: String(products.filter(p => p.stock < 5).length), 
                      change: 'Reorder needed', 
                      icon: Package, 
                      color: 'text-red-400', 
                      bg: 'bg-red-500/10' 
                    },
                  ].map((stat, idx) => {
                    const Icon = stat.icon;
                    return (
                      <div key={idx} className="rounded-2xl border border-border-card bg-panel p-5 flex items-center justify-between">
                        <div>
                          <p className="text-xs font-semibold text-text-secondary uppercase tracking-wider">{stat.label}</p>
                          <h3 className="mt-2 text-2xl font-bold text-text-primary">{stat.val}</h3>
                          <span className="text-[10px] font-semibold text-text-secondary mt-1 block">{stat.change}</span>
                        </div>
                        <div className={`rounded-xl p-3 ${stat.color} ${stat.bg}`}>
                          <Icon className="h-6 w-6" />
                        </div>
                      </div>
                    );
                  })}
                </div>

                {/* Info Card / Testing Guide */}
                <div className="rounded-2xl border border-border-card bg-panel p-6 shadow-xl relative overflow-hidden">
                  <div className="absolute right-0 top-0 translate-x-12 -translate-y-12 h-64 w-64 rounded-full bg-emerald-500/5 blur-3xl" />
                  
                  <h3 className="text-lg font-bold text-text-primary flex items-center gap-2">
                    <HelpCircle className="h-5.5 w-5.5 text-emerald-400 animate-bounce" />
                    How to test the features:
                  </h3>
                  
                  <div className="mt-4 grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div className="space-y-4">
                      <div className="flex gap-3">
                        <span className="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-emerald-500/15 text-xs font-bold text-emerald-400 font-mono">1</span>
                        <div>
                          <p className="text-sm font-semibold text-text-primary">Go to Products Tab</p>
                          <p className="text-xs text-text-secondary mt-0.5">Click the "Products" sidebar button or the tab links to access inventory management.</p>
                        </div>
                      </div>

                      <div className="flex gap-3">
                        <span className="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-emerald-500/15 text-xs font-bold text-emerald-400 font-mono">2</span>
                        <div>
                          <p className="text-sm font-semibold text-text-primary">Add a New Product</p>
                          <p className="text-xs text-text-secondary mt-0.5">Click the "+ Add Product" button in the toolbar to open the creation overlay.</p>
                        </div>
                      </div>

                      <div className="flex gap-3">
                        <span className="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-emerald-500/15 text-xs font-bold text-emerald-400 font-mono">3</span>
                        <div>
                          <p className="text-sm font-semibold text-text-primary">Upload any large image</p>
                          <p className="text-xs text-text-secondary mt-0.5">Select a high-resolution PNG or JPG file. Watch it instantly get compressed to under 150KB as WebP in your browser using HTML5 Canvas!</p>
                        </div>
                      </div>
                    </div>

                    <div className="space-y-4">
                      <div className="flex gap-3">
                        <span className="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-emerald-500/15 text-xs font-bold text-emerald-400 font-mono">4</span>
                        <div>
                          <p className="text-sm font-semibold text-text-primary">Submit and Watch the Console</p>
                          <p className="text-xs text-text-secondary mt-0.5">The modal console prints step-by-step API actions: calling backend for presigned credentials, directly PUTing binary payload to Cloudflare R2, and finishing with metadata registration.</p>
                        </div>
                      </div>

                      <div className="flex gap-3">
                        <span className="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-emerald-500/15 text-xs font-bold text-emerald-400 font-mono">5</span>
                        <div>
                          <p className="text-sm font-semibold text-text-primary">Low Stock Highlights</p>
                          <p className="text-xs text-text-secondary mt-0.5">If you add a product with stock &lt; 5, its row will show with a subtle warning red alert color and a low stock warning indicator.</p>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>

                {/* Decorative Visual Charts */}
                <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
                  <div className="rounded-2xl border border-border-card bg-panel p-5">
                    <h4 className="text-sm font-semibold text-text-primary">Weekly System Activity</h4>
                    <div className="mt-6 flex h-48 items-end gap-2 border-b border-l border-border-card pb-2 pl-2">
                      {[65, 45, 75, 55, 90, 80, 95].map((h, i) => (
                        <div key={i} className="group relative flex-1 flex flex-col items-center">
                          <div 
                            style={{ height: `${h}%` }} 
                            className="w-full rounded-t-lg bg-gradient-to-t from-emerald-500/80 to-teal-400 hover:brightness-110 transition-all duration-300 shadow-[0_0_10px_rgba(16,185,129,0.15)]"
                          />
                          <span className="text-[10px] text-text-secondary mt-2 font-mono">
                            {['M', 'T', 'W', 'T', 'F', 'S', 'S'][i]}
                          </span>
                        </div>
                      ))}
                    </div>
                  </div>

                  <div className="rounded-2xl border border-border-card bg-panel p-5">
                    <h4 className="text-sm font-semibold text-text-primary">Category Catalog Distribution</h4>
                    <div className="mt-6 space-y-4">
                      {[
                        { name: 'Fruits', percentage: 35, count: 12 },
                        { name: 'Vegetables', percentage: 25, count: 8 },
                        { name: 'Dairy & Eggs', percentage: 15, count: 5 },
                        { name: 'Other categories', percentage: 25, count: 9 },
                      ].map((item, idx) => (
                        <div key={idx} className="space-y-1.5">
                          <div className="flex justify-between text-xs">
                            <span className="font-semibold text-text-primary">{item.name}</span>
                            <span className="font-mono text-text-secondary">{item.count} items ({item.percentage}%)</span>
                          </div>
                          <div className="h-2 w-full rounded-full bg-bg-input overflow-hidden">
                            <div 
                              style={{ width: `${item.percentage}%` }}
                              className="h-full rounded-full bg-gradient-to-r from-emerald-500 to-teal-500"
                            />
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                </div>
              </div>
            ) : currentTab === 'orders' ? (
              <OrdersTable />
            ) : currentTab === 'customers' ? (
              <CustomerTable />
            ) : currentTab === 'analytics' ? (
              <AnalyticsView />
            ) : currentTab === 'settings' ? (
              <SettingsView />
            ) : (
              /* General Under Construction view for other tabs */
              <div className="rounded-2xl border border-border-card bg-panel p-12 text-center">
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
      
    </div>
  );
}
