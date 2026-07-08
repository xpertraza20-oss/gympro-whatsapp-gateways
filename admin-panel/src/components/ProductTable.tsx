import { useState, useMemo } from 'react';
import { type Product, CATEGORIES } from '../utils/mockApi';
import { 
  ChevronLeft, 
  ChevronRight, 
  AlertTriangle, 
  TrendingDown, 
  Plus, 
  Trash2, 
  ArrowUpDown,
  Filter
} from 'lucide-react';

interface ProductTableProps {
  products: Product[];
  onAddProductClick: () => void;
  onDeleteProduct: (id: string) => void;
  searchTerm: string;
}

export default function ProductTable({ 
  products, 
  onAddProductClick, 
  onDeleteProduct,
  searchTerm
}: ProductTableProps) {
  const [selectedCategory, setSelectedCategory] = useState<string>('All');
  const [sortField, setSortField] = useState<keyof Product>('title');
  const [sortOrder, setSortOrder] = useState<'asc' | 'desc'>('asc');
  
  // Pagination State
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 6;

  // Handle column sorting
  const handleSort = (field: keyof Product) => {
    if (sortField === field) {
      setSortOrder(sortOrder === 'asc' ? 'desc' : 'asc');
    } else {
      setSortField(field);
      setSortOrder('asc');
    }
  };

  // Filtered and sorted products
  const processedProducts = useMemo(() => {
    let result = [...products];

    // 1. Search Filter
    if (searchTerm.trim() !== '') {
      const term = searchTerm.toLowerCase();
      result = result.filter(p => 
        p.title.toLowerCase().includes(term) || 
        p.category.toLowerCase().includes(term) ||
        p.unit.toLowerCase().includes(term)
      );
    }

    // 2. Category Filter
    if (selectedCategory !== 'All') {
      result = result.filter(p => p.category === selectedCategory);
    }

    // 3. Sorting
    result.sort((a, b) => {
      const aVal = a[sortField];
      const bVal = b[sortField];

      if (typeof aVal === 'number' && typeof bVal === 'number') {
        return sortOrder === 'asc' ? aVal - bVal : bVal - aVal;
      }
      
      const strA = String(aVal).toLowerCase();
      const strB = String(bVal).toLowerCase();
      if (strA < strB) return sortOrder === 'asc' ? -1 : 1;
      if (strA > strB) return sortOrder === 'asc' ? 1 : -1;
      return 0;
    });

    return result;
  }, [products, searchTerm, selectedCategory, sortField, sortOrder]);

  // Pagination calculations
  const totalPages = Math.max(1, Math.ceil(processedProducts.length / itemsPerPage));
  
  // Adjust page if it exceeds total pages after filtering
  const activePage = currentPage > totalPages ? totalPages : currentPage;
  
  const paginatedProducts = useMemo(() => {
    const startIndex = (activePage - 1) * itemsPerPage;
    return processedProducts.slice(startIndex, startIndex + itemsPerPage);
  }, [processedProducts, activePage, itemsPerPage]);

  const startIndex = (activePage - 1) * itemsPerPage + 1;
  const endIndex = Math.min(activePage * itemsPerPage, processedProducts.length);

  return (
    <div className="space-y-6">
      {/* Metrics Row */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        <div className="rounded-2xl border border-border-card bg-panel p-5">
          <p className="text-xs font-semibold uppercase tracking-wider text-text-secondary">Total Catalog Items</p>
          <div className="mt-2 flex items-baseline justify-between">
            <span className="text-3xl font-bold text-text-primary">{products.length}</span>
            <span className="rounded-full bg-emerald-500/10 px-2 py-1 text-xs font-medium text-emerald-400">Active</span>
          </div>
        </div>

        <div className="rounded-2xl border border-border-card bg-panel p-5">
          <p className="text-xs font-semibold uppercase tracking-wider text-text-secondary">Low Stock Warning</p>
          <div className="mt-2 flex items-baseline justify-between">
            <span className="text-3xl font-bold text-red-400">
              {products.filter(p => p.stock < 5).length}
            </span>
            <span className="flex items-center gap-1 rounded-full bg-red-500/10 px-2 py-1 text-xs font-medium text-red-400">
              <TrendingDown className="h-3 w-3" /> Under 5 units
            </span>
          </div>
        </div>

        <div className="rounded-2xl border border-border-card bg-panel p-5">
          <p className="text-xs font-semibold uppercase tracking-wider text-text-secondary">Out of Stock</p>
          <div className="mt-2 flex items-baseline justify-between">
            <span className="text-3xl font-bold text-amber-500">
              {products.filter(p => p.stock === 0).length}
            </span>
            <span className="rounded-full bg-amber-500/10 px-2 py-1 text-xs font-medium text-amber-500">Urgent Reorder</span>
          </div>
        </div>
      </div>

      {/* Toolbar Controls */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between rounded-2xl border border-border-card bg-panel p-4">
        {/* Category Selector */}
        <div className="flex flex-wrap items-center gap-2">
          <span className="text-xs font-medium text-text-secondary flex items-center gap-1.5 mr-1">
            <Filter className="h-3.5 w-3.5" /> Filter Category:
          </span>
          <button
            onClick={() => { setSelectedCategory('All'); setCurrentPage(1); }}
            className={`rounded-lg px-3 py-1.5 text-xs font-semibold transition-all duration-200 cursor-pointer ${
              selectedCategory === 'All'
                ? 'bg-emerald-500 text-slate-950 shadow-md shadow-emerald-500/10'
                : 'bg-bg-input text-text-secondary hover:bg-hover-panel hover:text-text-primary border border-border-card'
            }`}
          >
            All
          </button>
          {CATEGORIES.map(category => (
            <button
              key={category}
              onClick={() => { setSelectedCategory(category); setCurrentPage(1); }}
              className={`rounded-lg px-3 py-1.5 text-xs font-semibold transition-all duration-200 cursor-pointer ${
                selectedCategory === category
                  ? 'bg-emerald-500 text-slate-950 shadow-md shadow-emerald-500/10'
                  : 'bg-bg-input text-text-secondary hover:bg-hover-panel hover:text-text-primary border border-border-card'
              }`}
            >
              {category}
            </button>
          ))}
        </div>

        {/* Action Button */}
        <button
          onClick={onAddProductClick}
          className="flex items-center justify-center gap-2 rounded-xl bg-gradient-to-r from-emerald-500 to-teal-500 px-4 py-2.5 text-sm font-semibold text-slate-950 hover:brightness-110 active:scale-98 transition-all duration-200 cursor-pointer shadow-lg shadow-emerald-500/15"
        >
          <Plus className="h-4 w-4" /> Add Product
        </button>
      </div>

      {/* Table Container */}
      <div className="overflow-hidden rounded-2xl border border-border-card bg-panel shadow-md">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-border-card bg-panel text-xs font-semibold tracking-wider text-text-secondary">
                <th className="px-6 py-4.5">Item</th>
                <th className="px-6 py-4.5 cursor-pointer hover:text-text-primary" onClick={() => handleSort('category')}>
                  <div className="flex items-center gap-1">
                    Category <ArrowUpDown className="h-3 w-3" />
                  </div>
                </th>
                <th className="px-6 py-4.5 cursor-pointer hover:text-text-primary" onClick={() => handleSort('price')}>
                  <div className="flex items-center gap-1">
                    Price <ArrowUpDown className="h-3 w-3" />
                  </div>
                </th>
                <th className="px-6 py-4.5">Unit</th>
                <th className="px-6 py-4.5 cursor-pointer hover:text-text-primary" onClick={() => handleSort('stock')}>
                  <div className="flex items-center gap-1">
                    Stock <ArrowUpDown className="h-3 w-3" />
                  </div>
                </th>
                <th className="px-6 py-4.5 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border-card/60 text-sm">
              {paginatedProducts.length > 0 ? (
                paginatedProducts.map((product) => {
                  const isLowStock = product.stock < 5;
                  return (
                    <tr
                      key={product.id}
                      className={`transition-colors duration-150 ${
                        isLowStock 
                          ? 'bg-red-500/[0.03] hover:bg-red-500/[0.06] border-l-2 border-red-500' 
                          : 'hover:bg-hover-panel border-l-2 border-transparent'
                      }`}
                    >
                      {/* Product Item / Info */}
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-4">
                          <img
                            src={product.image_url}
                            alt={product.title}
                            className="h-11 w-11 rounded-xl object-cover bg-bg-input border border-border-card"
                          />
                          <div>
                            <span className="font-semibold text-text-primary block">{product.title}</span>
                            <span className="text-xs text-text-secondary block">ID: {product.id}</span>
                          </div>
                        </div>
                      </td>

                      {/* Category */}
                      <td className="px-6 py-4 text-text-primary">
                        <span className="inline-flex items-center rounded-lg bg-bg-input px-2.5 py-1 text-xs font-semibold text-text-primary border border-border-card">
                          {product.category}
                        </span>
                      </td>

                      {/* Price */}
                      <td className="px-6 py-4 font-semibold text-text-primary">
                        ${product.price.toFixed(2)}
                      </td>

                      {/* Unit */}
                      <td className="px-6 py-4 text-text-secondary">
                        {product.unit}
                      </td>

                      {/* Stock Badge */}
                      <td className="px-6 py-4">
                        {isLowStock ? (
                          <span className="inline-flex items-center gap-1.5 rounded-lg bg-red-500/10 px-2.5 py-1 text-xs font-bold text-red-400 border border-red-500/20">
                            <AlertTriangle className="h-3.5 w-3.5 animate-bounce" />
                            {product.stock} left (Low)
                          </span>
                        ) : (
                          <span className="inline-flex items-center gap-1.5 rounded-lg bg-emerald-500/10 px-2.5 py-1 text-xs font-semibold text-emerald-400 border border-emerald-500/20">
                            {product.stock} in stock
                          </span>
                        )}
                      </td>

                      {/* Actions */}
                      <td className="px-6 py-4 text-right">
                        <button
                          onClick={() => onDeleteProduct(product.id)}
                          className="rounded-lg p-2 text-text-secondary hover:bg-red-500/10 hover:text-red-400 transition-colors cursor-pointer"
                          title="Delete Product"
                        >
                          <Trash2 className="h-4.5 w-4.5" />
                        </button>
                      </td>
                    </tr>
                  );
                })
              ) : (
                <tr>
                  <td colSpan={6} className="px-6 py-12 text-center text-text-secondary">
                    No products found matching filters.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination Section */}
        {processedProducts.length > 0 && (
          <div className="flex items-center justify-between border-t border-border-card bg-panel px-6 py-4 text-sm text-text-secondary">
            <div>
              Showing <span className="font-semibold text-text-primary">{startIndex}</span> to{' '}
              <span className="font-semibold text-text-primary">{endIndex}</span> of{' '}
              <span className="font-semibold text-text-primary">{processedProducts.length}</span> results
            </div>
            
            <div className="flex items-center gap-2">
              <button
                onClick={() => setCurrentPage(prev => Math.max(1, prev - 1))}
                disabled={activePage === 1}
                className="inline-flex items-center justify-center rounded-lg border border-border-card bg-panel p-2 text-text-secondary hover:bg-hover-panel hover:text-text-primary disabled:opacity-40 disabled:hover:bg-panel disabled:hover:text-text-secondary transition-colors cursor-pointer"
              >
                <ChevronLeft className="h-4 w-4" />
              </button>
              <span className="text-xs font-semibold text-text-primary">
                Page {activePage} of {totalPages}
              </span>
              <button
                onClick={() => setCurrentPage(prev => Math.min(totalPages, prev + 1))}
                disabled={activePage === totalPages}
                className="inline-flex items-center justify-center rounded-lg border border-border-card bg-panel p-2 text-text-secondary hover:bg-hover-panel hover:text-text-primary disabled:opacity-40 disabled:hover:bg-panel disabled:hover:text-text-secondary transition-colors cursor-pointer"
              >
                <ChevronRight className="h-4 w-4" />
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
