import { 
  BarChart3, 
  TrendingUp, 
  ArrowUpRight, 
  ArrowDownRight,
  ShoppingBag,
  DollarSign,
  Users
} from 'lucide-react';

import { formatPrice } from '../utils/config';

export default function AnalyticsView() {
  const reports = [
    { label: 'Weekly Revenue', val: formatPrice(14248.50), rate: '+12.5%', dir: 'up', icon: DollarSign, color: 'text-emerald-400', bg: 'bg-emerald-500/10' },
    { label: 'Conversion Rate', val: '3.42%', rate: '+0.8%', dir: 'up', icon: TrendingUp, color: 'text-blue-400', bg: 'bg-blue-500/10' },
    { label: 'Customer Retention', val: '78.5%', rate: '-1.2%', dir: 'down', icon: Users, color: 'text-purple-400', bg: 'bg-purple-500/10' },
    { label: 'Average Ticket Size', val: formatPrice(48.20), rate: '+3.1%', dir: 'up', icon: ShoppingBag, color: 'text-amber-400', bg: 'bg-amber-500/10' }
  ];

  return (
    <div className="space-y-6">
      {/* Top Banner */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between rounded-2xl border border-border-card bg-panel p-5">
        <div>
          <h2 className="text-lg font-bold text-text-primary flex items-center gap-2">
            <BarChart3 className="h-5.5 w-5.5 text-emerald-400" />
            System Performance & Analytics
          </h2>
          <p className="text-xs text-text-secondary mt-0.5">Real-time charts, conversion tracking, and core business metrics</p>
        </div>
      </div>

      {/* Analytics Stats Grid */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {reports.map((report, idx) => {
          const Icon = report.icon;
          return (
            <div key={idx} className="rounded-2xl border border-border-card bg-panel p-5 flex items-center justify-between">
              <div>
                <p className="text-xs font-semibold text-text-secondary uppercase tracking-wider">{report.label}</p>
                <h3 className="mt-2 text-2xl font-bold text-text-primary">{report.val}</h3>
                <span className={`inline-flex items-center gap-1 text-[10px] font-bold mt-1 px-1.5 py-0.5 rounded ${
                  report.dir === 'up' 
                    ? 'bg-emerald-500/10 text-emerald-400' 
                    : 'bg-red-500/10 text-red-400'
                }`}>
                  {report.dir === 'up' ? <ArrowUpRight className="h-3 w-3" /> : <ArrowDownRight className="h-3 w-3" />}
                  {report.rate} vs last week
                </span>
              </div>
              <div className={`rounded-xl p-3 ${report.color} ${report.bg}`}>
                <Icon className="h-6 w-6" />
              </div>
            </div>
          );
        })}
      </div>

      {/* Interactive Charts Panel */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Main Chart: Sales Performance */}
        <div className="lg:col-span-2 rounded-2xl border border-border-card bg-panel p-5 space-y-4">
          <div className="flex justify-between items-center border-b border-border-card pb-3">
            <h4 className="text-sm font-bold text-text-primary uppercase tracking-wider">Weekly Revenue Analytics</h4>
            <span className="text-xs text-text-secondary">Mon, Jul 1 - Sun, Jul 7</span>
          </div>
          
          {/* Custom SVG Bar Chart */}
          <div className="flex h-64 items-end gap-3.5 border-b border-l border-border-card pb-3 pl-3 pt-4">
            {[
              { day: 'Mon', val: 1200, height: '40%' },
              { day: 'Tue', val: 1800, height: '60%' },
              { day: 'Wed', val: 1500, height: '50%' },
              { day: 'Thu', val: 2400, height: '80%' },
              { day: 'Fri', val: 2100, height: '70%' },
              { day: 'Sat', val: 3000, height: '100%' },
              { day: 'Sun', val: 2700, height: '90%' }
            ].map((bar, i) => (
              <div key={i} className="group relative flex-1 flex flex-col items-center">
                {/* Tooltip */}
                <span className="absolute bottom-full mb-2 bg-slate-950 text-slate-100 text-[10px] font-bold px-2 py-1 rounded shadow-lg opacity-0 group-hover:opacity-100 transition-opacity z-10 pointer-events-none">
                  ${bar.val.toLocaleString()}
                </span>
                {/* Bar */}
                <div 
                  style={{ height: bar.height }} 
                  className="w-full rounded-t-lg bg-gradient-to-t from-emerald-500/85 to-teal-400 hover:brightness-110 transition-all duration-300 shadow-[0_0_10px_rgba(16,185,129,0.1)]"
                />
                <span className="text-[10px] text-text-secondary mt-2 font-mono">{bar.day}</span>
              </div>
            ))}
          </div>
        </div>

        {/* Category Sales Distribution */}
        <div className="rounded-2xl border border-border-card bg-panel p-5 space-y-4">
          <div className="flex justify-between items-center border-b border-border-card pb-3">
            <h4 className="text-sm font-bold text-text-primary uppercase tracking-wider">Top Performing Categories</h4>
          </div>
          
          <div className="space-y-4.5 pt-2">
            {[
              { name: 'Fruits & Berries', percentage: 42, count: 18, color: 'from-emerald-500 to-teal-500' },
              { name: 'Vegetables', percentage: 28, count: 12, color: 'from-emerald-400 to-green-500' },
              { name: 'Dairy & Eggs', percentage: 18, count: 8, color: 'from-blue-500 to-indigo-500' },
              { name: 'Bakery & Sweets', percentage: 12, count: 5, color: 'from-purple-500 to-pink-500' }
            ].map((item, idx) => (
              <div key={idx} className="space-y-1.5">
                <div className="flex justify-between text-xs">
                  <span className="font-semibold text-text-primary">{item.name}</span>
                  <span className="font-mono text-text-secondary">{item.percentage}%</span>
                </div>
                <div className="h-2 w-full rounded-full bg-bg-input overflow-hidden border border-border-card">
                  <div 
                    style={{ width: `${item.percentage}%` }}
                    className={`h-full rounded-full bg-gradient-to-r ${item.color}`}
                  />
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
