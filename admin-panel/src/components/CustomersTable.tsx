import { useState } from 'react';
import { 
  Users, 
  Search, 
  UserX, 
  UserCheck, 
  MessageSquare
} from 'lucide-react';
import { getSwal, showToast } from '../utils/alerts';
import { formatPrice } from '../utils/config';

interface CustomerItem {
  id: string;
  name: string;
  email: string;
  ordersPlaced: number;
  totalSpent: number;
  status: 'Active' | 'Suspended';
  joinDate: string;
  location: string;
}

const INITIAL_CUSTOMERS: CustomerItem[] = [
  { id: 'CST-201', name: 'Zeeshan Khan', email: 'zeeshan.khan@gmail.com', ordersPlaced: 15, totalSpent: 724.80, status: 'Active', joinDate: '2026-01-10', location: 'Karachi, PK' },
  { id: 'CST-202', name: 'Ayesha Ahmed', email: 'ayesha.ahmed@yahoo.com', ordersPlaced: 8, totalSpent: 312.40, status: 'Active', joinDate: '2026-02-15', location: 'Lahore, PK' },
  { id: 'CST-203', name: 'Bilal Raza', email: 'bilal.raza@outlook.com', ordersPlaced: 22, totalSpent: 1145.90, status: 'Active', joinDate: '2026-01-02', location: 'Islamabad, PK' },
  { id: 'CST-204', name: 'Marium Siddiqui', email: 'marium.s@gmail.com', ordersPlaced: 3, totalSpent: 92.40, status: 'Suspended', joinDate: '2026-04-20', location: 'Rawalpindi, PK' },
  { id: 'CST-205', name: 'Kamran Jameel', email: 'kamran.j@gmail.com', ordersPlaced: 11, totalSpent: 485.50, status: 'Active', joinDate: '2026-03-01', location: 'Faisalabad, PK' },
  { id: 'CST-206', name: 'Nida Fatima', email: 'nida.fatima@gmail.com', ordersPlaced: 1, totalSpent: 8.90, status: 'Active', joinDate: '2026-06-25', location: 'Peshawar, PK' }
];

export default function CustomersTable() {
  const [customers, setCustomers] = useState<CustomerItem[]>(INITIAL_CUSTOMERS);
  const [searchTerm, setSearchTerm] = useState('');

  // Filter customers
  const filteredCustomers = customers.filter(customer => 
    customer.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    customer.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
    customer.id.toLowerCase().includes(searchTerm.toLowerCase()) ||
    customer.location.toLowerCase().includes(searchTerm.toLowerCase())
  );

  // Toggle Ban / Unban
  const handleToggleStatus = async (id: string, name: string, currentStatus: 'Active' | 'Suspended') => {
    const swal = getSwal();
    const actionText = currentStatus === 'Active' ? 'Suspend' : 'Activate';
    
    const result = await swal.fire({
      title: `${actionText} Account?`,
      text: `Are you sure you want to ${actionText.toLowerCase()} customer account for "${name}"?`,
      icon: currentStatus === 'Active' ? 'warning' : 'question',
      showCancelButton: true,
      confirmButtonText: `Yes, ${actionText}`,
      cancelButtonText: 'Cancel',
      reverseButtons: true
    });

    if (result.isConfirmed) {
      setCustomers(prev => prev.map(customer => 
        customer.id === id 
          ? { ...customer, status: currentStatus === 'Active' ? 'Suspended' : 'Active' } 
          : customer
      ));
      showToast('success', `Customer account successfully ${currentStatus === 'Active' ? 'Suspended' : 'Activated'}`);
    }
  };

  // Send Mock Message
  const handleSendMessage = async (name: string) => {
    const swal = getSwal();
    const result = await swal.fire({
      title: `Message to ${name}`,
      input: 'textarea',
      inputPlaceholder: 'Type your message/notification here...',
      inputAttributes: {
        'aria-label': 'Type your message here'
      },
      showCancelButton: true,
      confirmButtonText: 'Send Notification',
      cancelButtonText: 'Cancel'
    });

    if (result.isConfirmed && result.value) {
      showToast('success', `Message successfully sent to ${name}!`);
    }
  };

  return (
    <div className="space-y-6">
      {/* Top Banner */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between rounded-2xl border border-border-card bg-panel p-5">
        <div>
          <h2 className="text-lg font-bold text-text-primary flex items-center gap-2">
            <Users className="h-5.5 w-5.5 text-emerald-400" />
            Registered Customer Base
          </h2>
          <p className="text-xs text-text-secondary mt-0.5">Audit customer purchase logs, message directly, or enforce account policies</p>
        </div>
      </div>

      {/* Filter and Search Toolbar */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between rounded-2xl border border-border-card bg-panel p-4">
        {/* Search */}
        <div className="relative max-w-xs w-full">
          <span className="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none">
            <Search className="h-4 w-4 text-text-secondary" />
          </span>
          <input
            type="text"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            placeholder="Search customers by name, email, location..."
            className="w-full rounded-xl bg-bg-input border border-border-card py-2 pl-9 pr-4 text-sm text-text-primary focus:outline-none focus:border-emerald-500 transition-colors"
          />
        </div>
      </div>

      {/* Customers Table */}
      <div className="overflow-hidden rounded-2xl border border-border-card bg-panel shadow-md">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-border-card bg-panel text-xs font-semibold tracking-wider text-text-secondary">
                <th className="px-6 py-4.5">Customer ID</th>
                <th className="px-6 py-4.5">Profile</th>
                <th className="px-6 py-4.5">Location</th>
                <th className="px-6 py-4.5">Orders Placed</th>
                <th className="px-6 py-4.5">Total Value</th>
                <th className="px-6 py-4.5">Status</th>
                <th className="px-6 py-4.5">Join Date</th>
                <th className="px-6 py-4.5 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border-card/60 text-sm">
              {filteredCustomers.length > 0 ? (
                filteredCustomers.map((customer) => (
                  <tr key={customer.id} className="hover:bg-hover-panel transition-colors duration-150">
                    <td className="px-6 py-4 font-mono font-semibold text-text-primary">
                      {customer.id}
                    </td>
                    <td className="px-6 py-4">
                      <div>
                        <span className="font-semibold text-text-primary block">{customer.name}</span>
                        <span className="text-xs text-text-secondary block">{customer.email}</span>
                      </div>
                    </td>
                    <td className="px-6 py-4 text-text-primary">
                      {customer.location}
                    </td>
                    <td className="px-6 py-4 text-text-primary">
                      {customer.ordersPlaced} orders
                    </td>
                    <td className="px-6 py-4 font-semibold text-text-primary">
                      {formatPrice(customer.totalSpent)}
                    </td>
                    <td className="px-6 py-4">
                      <span className={`inline-flex items-center gap-1 rounded-lg px-2.5 py-1 text-xs font-semibold border ${
                        customer.status === 'Active'
                          ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20'
                          : 'bg-red-500/10 text-red-400 border-red-500/20'
                      }`}>
                        {customer.status === 'Active' ? 'Active' : 'Suspended'}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-text-secondary text-xs">
                      {customer.joinDate}
                    </td>
                    <td className="px-6 py-4 text-right">
                      <div className="flex items-center justify-end gap-1.5">
                        {/* Send Notification */}
                        <button
                          onClick={() => handleSendMessage(customer.name)}
                          className="rounded-lg p-2 text-text-secondary hover:bg-hover-panel hover:text-text-primary transition-colors cursor-pointer"
                          title="Send Message"
                        >
                          <MessageSquare className="h-4.5 w-4.5" />
                        </button>
                        
                        {/* Toggle Suspend/Ban */}
                        <button
                          onClick={() => handleToggleStatus(customer.id, customer.name, customer.status)}
                          className={`rounded-lg p-2 transition-colors cursor-pointer ${
                            customer.status === 'Active'
                              ? 'text-text-secondary hover:bg-red-500/10 hover:text-red-400'
                              : 'text-emerald-400 hover:bg-emerald-500/10 hover:text-emerald-500'
                          }`}
                          title={customer.status === 'Active' ? 'Suspend Account' : 'Activate Account'}
                        >
                          {customer.status === 'Active' ? <UserX className="h-4.5 w-4.5" /> : <UserCheck className="h-4.5 w-4.5" />}
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={8} className="px-6 py-12 text-center text-text-secondary">
                    No customers found matching search term.
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
