import { useState, useEffect } from 'react';
import { 
  Users, 
  Search, 
  RefreshCw, 
  Mail, 
  Phone, 
  Calendar,
  AlertCircle
} from 'lucide-react';
import { getBackendUrl } from '../utils/config';

interface Customer {
  id: number;
  name: string;
  email: string;
  phone: string;
  joining_date: string;
  is_verified: boolean;
}

export default function CustomerTable() {
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [searchTerm, setSearchTerm] = useState('');

  // Fetch live customers from Render backend
  const fetchCustomers = async () => {
    setLoading(true);
    setError(null);
    try {
      const token = 'admin-secret-token';
      const res = await fetch(`${getBackendUrl()}/api/v1/admin/users?limit=100`, {
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
      if (json.success && json.data && Array.isArray(json.data.users)) {
        setCustomers(json.data.users);
      } else {
        throw new Error(json.message || 'Invalid user data format');
      }
    } catch (err: any) {
      console.error('Error fetching customers:', err);
      setError(err.message || 'Failed to connect to the backend server.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchCustomers();
  }, []);

  // Format to DD-MM-YYYY format
  const formatToDDMMYYYY = (dateStr: string): string => {
    try {
      const d = new Date(dateStr);
      if (isNaN(d.getTime())) return dateStr;
      const day = String(d.getDate()).padStart(2, '0');
      const month = String(d.getMonth() + 1).padStart(2, '0');
      const year = d.getFullYear();
      return `${day}-${month}-${year}`;
    } catch (e) {
      return dateStr;
    }
  };

  // Helper for initials
  const getInitials = (name: string): string => {
    const cleanName = name.replace(/[^a-zA-Z\s]/g, '').trim();
    const parts = cleanName.split(/\s+/);
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return cleanName.substring(0, Math.min(2, cleanName.length)).toUpperCase() || 'FC';
  };

  // Helper for colorful placeholder initials backgrounds
  const getAvatarColor = (name: string): string => {
    const colors = [
      'bg-red-500/10 text-red-400 border-red-500/20',
      'bg-blue-500/10 text-blue-400 border-blue-500/20',
      'bg-emerald-500/10 text-emerald-400 border-emerald-500/20',
      'bg-amber-500/10 text-amber-400 border-amber-500/20',
      'bg-purple-500/10 text-purple-400 border-purple-500/20',
      'bg-pink-500/10 text-pink-400 border-pink-500/20',
      'bg-indigo-500/10 text-indigo-400 border-indigo-500/20',
    ];
    let sum = 0;
    for (let i = 0; i < name.length; i++) {
      sum += name.charCodeAt(i);
    }
    return colors[sum % colors.length];
  };

  // Client-side search / filter logic
  const filteredCustomers = customers.filter(c => 
    c.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    c.email.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="space-y-6">
      {/* Top Header Section */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between rounded-2xl border border-border-card bg-panel p-5">
        <div>
          <h2 className="text-lg font-bold text-text-primary flex items-center gap-2">
            <Users className="h-5.5 w-5.5 text-emerald-400" />
            Registered Customer Base
          </h2>
          <p className="text-xs text-text-secondary mt-0.5">
            Audit registered and verified customers on the FreshCart application.
          </p>
        </div>
        <button
          onClick={fetchCustomers}
          disabled={loading}
          className="flex items-center gap-2 rounded-xl bg-emerald-500/10 hover:bg-emerald-500/20 text-emerald-400 border border-emerald-500/20 px-4 py-2 text-xs font-semibold transition-all cursor-pointer disabled:opacity-50"
        >
          <RefreshCw className={`h-3.5 w-3.5 ${loading ? 'animate-spin' : ''}`} />
          <span>Reload Data</span>
        </button>
      </div>

      {/* Filter and Search Toolbar */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between rounded-2xl border border-border-card bg-panel p-4">
        <div className="relative max-w-xs w-full">
          <span className="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none">
            <Search className="h-4 w-4 text-text-secondary" />
          </span>
          <input
            type="text"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            placeholder="Search customers by name or email..."
            className="w-full rounded-xl bg-bg-input border border-border-card py-2 pl-9 pr-4 text-sm text-text-primary focus:outline-none focus:border-emerald-500 transition-colors"
          />
        </div>
        <div className="text-xs text-text-secondary">
          Showing {filteredCustomers.length} of {customers.length} verified customers
        </div>
      </div>

      {/* Customers Table Container */}
      <div className="overflow-hidden rounded-2xl border border-border-card bg-panel shadow-md">
        {loading ? (
          <div className="flex flex-col items-center justify-center py-20 space-y-4">
            <RefreshCw className="h-8 w-8 text-emerald-400 animate-spin" />
            <span className="text-sm text-text-secondary font-medium">Fetching verified customers...</span>
          </div>
        ) : error ? (
          <div className="flex flex-col items-center justify-center py-16 px-6 text-center space-y-3">
            <div className="rounded-full bg-red-500/10 p-3 text-red-400 border border-red-500/20">
              <AlertCircle className="h-6 w-6" />
            </div>
            <h3 className="text-base font-bold text-text-primary">Failed to load data</h3>
            <p className="text-sm text-text-secondary max-w-md">{error}</p>
            <button
              onClick={fetchCustomers}
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
                  <th className="px-6 py-4.5">Customer</th>
                  <th className="px-6 py-4.5">Email Status</th>
                  <th className="px-6 py-4.5">Phone Number</th>
                  <th className="px-6 py-4.5">Registration Date</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border-card/60 text-sm">
                {filteredCustomers.length > 0 ? (
                  filteredCustomers.map((customer) => {
                    const avatarColorClass = getAvatarColor(customer.name);
                    const initials = getInitials(customer.name);
                    
                    return (
                      <tr key={customer.id} className="hover:bg-hover-panel transition-colors duration-150">
                        {/* Profile Info with Avatar */}
                        <td className="px-6 py-4">
                          <div className="flex items-center gap-3">
                            <div className={`flex h-10 w-10 shrink-0 items-center justify-center rounded-xl border text-sm font-bold ${avatarColorClass}`}>
                              {initials}
                            </div>
                            <div>
                              <span className="font-semibold text-text-primary block leading-tight">{customer.name}</span>
                              <span className="text-xs text-text-secondary block mt-0.5">{customer.email}</span>
                            </div>
                          </div>
                        </td>
                        
                        {/* Email Badge */}
                        <td className="px-6 py-4">
                          <span className="inline-flex items-center gap-1.5 rounded-lg px-2.5 py-1 text-xs font-semibold border bg-emerald-500/10 text-emerald-400 border-emerald-500/20">
                            <Mail className="h-3 w-3" />
                            <span>Verified</span>
                          </span>
                        </td>
                        
                        {/* Phone Container */}
                        <td className="px-6 py-4">
                          <div className="flex items-center gap-2 text-text-primary">
                            <div className="rounded-lg bg-bg-input p-1.5 border border-border-card text-text-secondary">
                              <Phone className="h-3.5 w-3.5" />
                            </div>
                            <span className="font-mono text-xs">{customer.phone}</span>
                          </div>
                        </td>
                        
                        {/* Registration Date (DD-MM-YYYY) */}
                        <td className="px-6 py-4 text-text-secondary text-xs">
                          <div className="flex items-center gap-2">
                            <Calendar className="h-3.5 w-3.5 text-text-secondary" />
                            <span>{formatToDDMMYYYY(customer.joining_date)}</span>
                          </div>
                        </td>
                      </tr>
                    );
                  })
                ) : (
                  <tr>
                    <td colSpan={4} className="px-6 py-16 text-center text-text-secondary">
                      No customers found matching search term.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}
