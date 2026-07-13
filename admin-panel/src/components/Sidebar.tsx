import { 
  ShoppingBag, 
  LayoutDashboard, 
  ShoppingCart, 
  Users, 
  BarChart3, 
  Settings, 
  X,
  Apple,
  FolderOpen
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
      title: 'Business Insights',
      items: [
        { id: 'customers', label: 'Customers', icon: Users },
        { id: 'analytics', label: 'Analytics', icon: BarChart3 },
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
        className={`fixed inset-y-0 left-0 z-50 flex w-72 flex-col glass-panel text-text-primary transition-all duration-300 ease-in-out lg:static lg:translate-x-0 shadow-2xl relative overflow-hidden ${
          isOpen ? 'translate-x-0' : '-translate-x-full'
        }`}
      >
        <div className="mesh-glow-orb -left-12 -top-12 h-32 w-32 bg-accent-primary/10" />

        {/* Header/Brand */}
        <div className="flex h-16 items-center justify-between px-6 border-b border-border-card/40 relative z-10">
          <div className="flex items-center gap-2.5">
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-accent-primary/15 text-accent-primary ring-1 ring-accent-primary/30 shadow-[0_0_15px_var(--accent-primary)]">
              <Apple className="h-6 w-6 animate-pulse" />
            </div>
            <div>
              <h1 className="text-lg font-bold tracking-tight text-text-primary">FreshCart</h1>
              <p className="text-[10px] text-accent-primary font-semibold tracking-wider uppercase">Admin Portal</p>
            </div>
          </div>
          <button 
            onClick={onClose}
            className="rounded-lg p-1.5 text-text-secondary hover:bg-hover-panel hover:text-text-primary lg:hidden transition-colors cursor-pointer"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        {/* Navigation links grouped by section */}
        <nav className="flex-1 space-y-6 px-4 py-6 overflow-y-auto relative z-10">
          {sections.map((section, sIdx) => (
            <div key={sIdx} className="space-y-2">
              <p className="px-4 text-[10px] font-bold uppercase tracking-wider text-text-secondary/60">
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
                      className={`flex w-full items-center justify-between rounded-xl px-4 py-2.5 text-sm font-semibold transition-all duration-200 group relative cursor-pointer ${
                        isActive 
                          ? 'bg-accent-primary/10 text-accent-primary border-l-4 border-accent-primary pl-3' 
                          : 'text-text-secondary hover:bg-hover-panel hover:text-text-primary border-l-4 border-transparent hover:translate-x-1'
                      }`}
                    >
                      <div className="flex items-center gap-3">
                        <Icon className={`h-4.5 w-4.5 transition-transform duration-200 group-hover:scale-110 ${isActive ? 'text-accent-primary' : 'text-text-secondary group-hover:text-text-primary'}`} />
                        <span>{item.label}</span>
                      </div>
                    </button>
                  );
                })}
              </div>
            </div>
          ))}
        </nav>

        {/* Sidebar Footer/Profile */}
        <div className="border-t border-border-card/40 p-4 bg-transparent relative z-10">
          <div className="flex items-center gap-3 rounded-xl p-2 hover:bg-hover-panel transition-colors">
            <div className="relative">
              <img
                src="https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&q=80&w=100"
                alt="Admin Profile"
                className="h-10 w-10 rounded-xl object-cover ring-2 ring-accent-primary/20"
              />
              <span className="absolute bottom-0 right-0 h-2.5 w-2.5 rounded-full bg-accent-primary ring-2 ring-panel" />
            </div>
            <div className="flex-1 overflow-hidden">
              <h4 className="truncate text-sm font-semibold text-text-primary">ALI</h4>
              <p className="truncate text-xs text-text-secondary">Admin Profile</p>
            </div>
          </div>
        </div>
      </aside>
    </>
  );
}
