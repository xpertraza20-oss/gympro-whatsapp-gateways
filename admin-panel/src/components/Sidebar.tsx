import { 
  ShoppingBag, 
  LayoutDashboard, 
  ShoppingCart, 
  Users, 
  BarChart3, 
  Settings, 
  X,
  Apple,
  FolderOpen,
  LogOut,
  Store,
  ShieldCheck,
  CheckSquare,
  ShieldAlert
} from 'lucide-react';

interface SidebarProps {
  isOpen: boolean;
  onClose: () => void;
  currentTab: string;
  setCurrentTab: (tab: string) => void;
  theme?: string;
}

export default function Sidebar({ isOpen, onClose, currentTab, setCurrentTab }: SidebarProps) {
  const sections = [
    {
      title: 'Core Management',
      items: [
        { id: 'dashboard', label: 'Dashboard', icon: LayoutDashboard },
        { id: 'products', label: 'Products', icon: ShoppingBag },
        { id: 'categories', label: 'Categories', icon: FolderOpen },
        { id: 'orders', label: 'Orders', icon: ShoppingCart },
      ]
    },
    {
      title: 'Verification & Approvals',
      items: [
        { id: 'shop_approvals', label: 'Shop Approvals', icon: Store },
        { id: 'rider_verification', label: 'Rider Verification', icon: ShieldCheck },
        { id: 'product_approvals', label: 'Product Approvals', icon: CheckSquare },
        { id: 'cod_approvals', label: 'COD Approvals', icon: ShieldAlert },
      ]
    },
    {
      title: 'Business Insights',
      items: [
        { id: 'customers', label: 'Customers', icon: Users },
        { id: 'analytics', label: 'Analytics', icon: BarChart3 },
        { id: 'financials', label: 'Financials', icon: DollarSign },
      ]
    },
    {
      title: 'Settings & Config',
      items: [
        { id: 'settings', label: 'Settings', icon: Settings },
      ]
    }
  ];

  return (
    <>
      {/* Mobile backdrop */}
      {isOpen && (
        <div 
          className="fixed inset-0 z-40 bg-slate-950/60 backdrop-blur-sm lg:hidden transition-opacity duration-300"
          onClick={onClose}
        />
      )}

      {/* Sidebar container */}
      <aside
        className={`fixed inset-y-0 left-0 z-50 flex w-64 flex-col bg-[#2e1d21] text-slate-100 transition-all duration-300 ease-in-out lg:static lg:translate-x-0 shadow-xl border-r border-[#ac004d]/10 overflow-y-auto sidebar-scroll ${
          isOpen ? 'translate-x-0' : '-translate-x-full'
        }`}
      >
        {/* Header/Brand */}
        <div className="px-6 py-5 flex items-center justify-between border-b border-white/5">
          <div className="flex items-center gap-2.5">
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-[#ac004d]/20 text-[#ffb1c2] border border-[#ac004d]/40 shadow-[0_0_15px_rgba(172,0,77,0.3)]">
              <Apple className="h-6 w-6 animate-pulse" />
            </div>
            <div>
              <h1 className="text-xl font-bold tracking-tight text-white font-headline-lg">FreshCart</h1>
              <p className="text-[10px] text-[#ffb1c2] font-bold tracking-wider uppercase">Admin Portal</p>
            </div>
          </div>
          <button 
            onClick={onClose}
            className="rounded-lg p-1.5 text-slate-400 hover:bg-white/5 hover:text-white lg:hidden transition-colors cursor-pointer"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        {/* Store Manager profile card */}
        <div className="px-4 mt-6">
          <div className="flex items-center space-x-3 bg-white/5 p-3 rounded-xl border border-white/5">
            <div className="w-10 h-10 rounded-full overflow-hidden bg-[#ffb1c2] flex items-center justify-center border border-white/10 shrink-0">
              <img 
                className="w-full h-full object-cover" 
                alt="Store Manager profile image"
                src="https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&q=80&w=100"
              />
            </div>
            <div className="overflow-hidden">
              <p className="font-semibold text-sm text-white truncate">Store Manager</p>
              <p className="text-xs text-slate-400 truncate">admin@freshcart.com</p>
            </div>
          </div>
        </div>

        {/* Navigation links grouped by section */}
        <nav className="flex-1 space-y-6 px-3 py-6">
          {sections.map((section, sIdx) => (
            <div key={sIdx} className="space-y-1.5">
              <p className="px-4 text-[10px] font-bold uppercase tracking-wider text-[#ffb1c2]/40">
                {section.title}
              </p>
              <div className="space-y-1">
                {section.items.map((item) => {
                  const Icon = item.icon;
                  const isActive = currentTab === item.id;
                  return (
                    <button
                      key={item.id}
                      onClick={() => {
                        setCurrentTab(item.id);
                        onClose();
                      }}
                      className={`flex w-full items-center justify-between rounded-xl px-4 py-2.5 text-sm font-semibold transition-all duration-200 group cursor-pointer ${
                        isActive 
                          ? 'bg-[#ac004d] text-white shadow-md shadow-[#ac004d]/25' 
                          : 'text-slate-300 hover:bg-white/5 hover:text-white'
                      }`}
                    >
                      <div className="flex items-center gap-3">
                        <Icon className={`h-4.5 w-4.5 transition-transform duration-200 group-hover:scale-110 ${isActive ? 'text-white' : 'text-slate-400 group-hover:text-white'}`} />
                        <span>{item.label}</span>
                      </div>
                    </button>
                  );
                })}
              </div>
            </div>
          ))}
        </nav>

        {/* Sidebar Footer/Logout */}
        <div className="p-4 border-t border-white/5 mt-auto">
          <button 
            onClick={() => {
              // Reset credentials & logout
              localStorage.removeItem('admin_api_key');
              window.location.reload();
            }}
            className="w-full flex items-center justify-center space-x-2 py-2.5 border border-white/10 hover:border-red-500/20 text-slate-300 hover:bg-red-500/10 hover:text-red-400 rounded-xl transition-all cursor-pointer font-semibold text-sm"
          >
            <LogOut className="h-4.5 w-4.5" />
            <span>Logout Portal</span>
          </button>
        </div>
      </aside>
    </>
  );
}
