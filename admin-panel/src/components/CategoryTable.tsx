import React, { useState, useEffect } from 'react';
import { 
  FolderPlus, 
  Trash2, 
  Edit3, 
  Check, 
  X, 
  FileImage, 
  Calendar,
  FolderOpen
} from 'lucide-react';
import { getSwal, showToast } from '../utils/alerts';
import { getAdminHeaders, getBackendUrl } from '../utils/config';

interface Category {
  id: number;
  name: string;
  slug: string;
  image_url: string | null;
  created_at: string;
}

export default function CategoryTable() {
  const [categories, setCategories] = useState<Category[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  
  // Form states for creating new category
  const [newName, setNewName] = useState('');
  const [newSlug, setNewSlug] = useState('');
  const [newImageUrl, setNewImageUrl] = useState('');
  const [isAdding, setIsAdding] = useState(false);

  // States for editing inline
  const [editingId, setEditingId] = useState<number | null>(null);
  const [editingName, setEditingName] = useState('');
  const [editingSlug, setEditingSlug] = useState('');
  const [editingImageUrl, setEditingImageUrl] = useState('');

  // Fetch categories from backend
  const fetchCategories = async () => {
    setIsLoading(true);
    try {
      const res = await fetch(`${getBackendUrl()}/api/v1/categories`, {
        headers: { 'bypass-tunnel-reminder': 'true' }
      });
      const json = await res.json();
      if (json.success && Array.isArray(json.data)) {
        setCategories(json.data);
      }
    } catch (err) {
      console.error("Failed to fetch categories:", err);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchCategories();
  }, []);

  // Autofill slug from name when adding
  const handleNameChange = (val: string) => {
    setNewName(val);
    setNewSlug(val.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, ''));
  };

  // Autofill slug from name when editing
  const handleEditingNameChange = (val: string) => {
    setEditingName(val);
    setEditingSlug(val.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, ''));
  };

  // Create Category
  const handleAddCategory = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newName || !newSlug) return;
    
    setIsLoading(true);
    const swal = getSwal();
    try {
      const res = await fetch(`${getBackendUrl()}/api/v1/admin/categories`, {
        method: 'POST',
        headers: getAdminHeaders(true),
        body: JSON.stringify({
          name: newName,
          slug: newSlug,
          image_url: newImageUrl || null
        })
      });

      const json = await res.json();
      if (res.ok && json.success) {
        setCategories(prev => [...prev, json.data]);
        setNewName('');
        setNewSlug('');
        setNewImageUrl('');
        setIsAdding(false);
        showToast('success', 'Category added successfully!');
      } else {
        swal.fire({
          title: 'Error!',
          text: json.message || "Failed to create category",
          icon: 'error'
        });
      }
    } catch (err) {
      console.error(err);
      swal.fire({
        title: 'Network Error',
        text: "Failed to connect to backend server.",
        icon: 'error'
      });
    } finally {
      setIsLoading(false);
    }
  };

  // Delete Category
  const handleDeleteCategory = async (id: number, name: string) => {
    const swal = getSwal();
    const result = await swal.fire({
      title: 'Delete Category?',
      text: `Are you sure you want to delete category "${name}"? This could affect products referencing it.`,
      icon: 'warning',
      showCancelButton: true,
      confirmButtonText: 'Yes, delete it',
      cancelButtonText: 'Cancel',
      reverseButtons: true
    });

    if (result.isConfirmed) {
      setIsLoading(true);
      try {
        const res = await fetch(`${getBackendUrl()}/api/v1/admin/categories/${id}`, {
          method: 'DELETE',
          headers: getAdminHeaders()
        });

        const json = await res.json();
        if (res.ok && json.success) {
          setCategories(prev => prev.filter(cat => cat.id !== id));
          showToast('success', 'Category deleted successfully!');
        } else {
          swal.fire({
            title: 'Error!',
            text: json.message || "Failed to delete category",
            icon: 'error'
          });
        }
      } catch (err) {
        console.error(err);
        swal.fire({
          title: 'Network Error',
          text: "Failed to delete category.",
          icon: 'error'
        });
      } finally {
        setIsLoading(false);
      }
    }
  };

  // Start Edit Mode
  const startEdit = (cat: Category) => {
    setEditingId(cat.id);
    setEditingName(cat.name);
    setEditingSlug(cat.slug);
    setEditingImageUrl(cat.image_url || '');
  };

  // Cancel Edit Mode
  const cancelEdit = () => {
    setEditingId(null);
    setEditingName('');
    setEditingSlug('');
    setEditingImageUrl('');
  };

  // Save/Update Category
  const handleUpdateCategory = async (id: number) => {
    if (!editingName || !editingSlug) return;

    setIsLoading(true);
    const swal = getSwal();
    try {
      const res = await fetch(`${getBackendUrl()}/api/v1/admin/categories/${id}`, {
        method: 'PUT',
        headers: getAdminHeaders(true),
        body: JSON.stringify({
          name: editingName,
          slug: editingSlug,
          image_url: editingImageUrl || null
        })
      });

      const json = await res.json();
      if (res.ok && json.success) {
        setCategories(prev => prev.map(cat => cat.id === id ? json.data : cat));
        cancelEdit();
        showToast('success', 'Category updated successfully!');
      } else {
        swal.fire({
          title: 'Error!',
          text: json.message || "Failed to update category",
          icon: 'error'
        });
      }
    } catch (err) {
      console.error(err);
      swal.fire({
        title: 'Network Error',
        text: "Failed to update category.",
        icon: 'error'
      });
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="space-y-6">
      {/* Top Banner Controls */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between rounded-2xl glass-panel p-5 float-card shadow-lg">
        <div>
          <h2 className="text-lg font-bold text-text-primary flex items-center gap-2">
            <FolderOpen className="h-5.5 w-5.5 text-emerald-400" />
            Categories Management
          </h2>
          <p className="text-xs text-text-secondary mt-0.5">Add, edit slugs, or delete active catalog groupings</p>
        </div>
        <button
          onClick={() => setIsAdding(!isAdding)}
          className="flex items-center justify-center gap-2 rounded-xl bg-gradient-to-r from-emerald-500 to-teal-500 px-4 py-2.5 text-sm font-semibold text-slate-950 hover:brightness-110 active:scale-98 transition-all duration-200 cursor-pointer shadow-lg shadow-emerald-500/15"
        >
          <FolderPlus className="h-4.5 w-4.5" />
          {isAdding ? 'Close Panel' : 'Add Category'}
        </button>
      </div>

      {/* Add New Category Panel */}
      {isAdding && (
        <form onSubmit={handleAddCategory} className="rounded-2xl glass-panel p-5 space-y-4 max-w-2xl float-card shadow-lg relative overflow-hidden">
          <div className="mesh-glow-orb right-0 top-0 h-32 w-32 bg-emerald-500/10" />
          <h3 className="text-sm font-bold uppercase tracking-wider text-text-primary relative z-10">Create New Category</h3>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 relative z-10">
            <div>
              <label className="block text-xs font-semibold text-text-secondary uppercase mb-1.5">Category Name *</label>
              <input
                type="text"
                required
                value={newName}
                onChange={(e) => handleNameChange(e.target.value)}
                placeholder="e.g. Organic Greens"
                className="w-full rounded-xl bg-bg-input border border-border-card px-4 py-2.5 text-sm text-text-primary focus:outline-none focus:border-emerald-500 transition-colors"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-text-secondary uppercase mb-1.5">Slug (Auto-generated) *</label>
              <input
                type="text"
                required
                value={newSlug}
                onChange={(e) => setNewSlug(e.target.value)}
                placeholder="organic-greens"
                className="w-full rounded-xl bg-bg-input border border-border-card px-4 py-2.5 text-sm text-text-primary focus:outline-none focus:border-emerald-500 transition-colors"
              />
            </div>
            <div className="md:col-span-2">
              <label className="block text-xs font-semibold text-text-secondary uppercase mb-1.5">Image URL (Optional)</label>
              <input
                type="text"
                value={newImageUrl}
                onChange={(e) => setNewImageUrl(e.target.value)}
                placeholder="https://images.unsplash.com/photo-..."
                className="w-full rounded-xl bg-bg-input border border-border-card px-4 py-2.5 text-sm text-text-primary focus:outline-none focus:border-emerald-500 transition-colors"
              />
            </div>
          </div>
          <div className="flex gap-2 justify-end relative z-10">
            <button
              type="button"
              onClick={() => setIsAdding(false)}
              className="rounded-xl border border-border-card bg-bg-input px-4 py-2 text-xs font-semibold text-text-secondary hover:bg-hover-panel hover:text-text-primary transition-colors cursor-pointer"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={isLoading || !newName || !newSlug}
              className="rounded-xl bg-emerald-500 px-5 py-2 text-xs font-bold text-slate-950 hover:brightness-110 active:scale-98 transition-colors cursor-pointer disabled:opacity-40"
            >
              Save Category
            </button>
          </div>
        </form>
      )}

      {/* Categories Table */}
      <div className="overflow-hidden rounded-2xl glass-panel shadow-xl float-card">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-border-card bg-panel text-xs font-semibold tracking-wider text-text-secondary">
                <th className="px-6 py-4.5">ID</th>
                <th className="px-6 py-4.5">Category Name</th>
                <th className="px-6 py-4.5">Slug URL</th>
                <th className="px-6 py-4.5">Created At</th>
                <th className="px-6 py-4.5 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border-card/60 text-sm">
              {categories.length > 0 ? (
                categories.map((cat) => {
                  const isEditing = editingId === cat.id;
                  return (
                    <tr key={cat.id} className="hover:bg-hover-panel transition-colors duration-150">
                      {/* ID */}
                      <td className="px-6 py-4 font-mono text-xs text-text-secondary">
                        #{cat.id}
                      </td>

                      {/* Name / Info */}
                      <td className="px-6 py-4">
                        {isEditing ? (
                          <input
                            type="text"
                            value={editingName}
                            onChange={(e) => handleEditingNameChange(e.target.value)}
                            className="rounded-lg bg-bg-input border border-border-card px-2.5 py-1.5 text-xs text-text-primary focus:outline-none focus:border-emerald-500"
                          />
                        ) : (
                          <div className="flex items-center gap-3">
                            {cat.image_url ? (
                              <img 
                                src={cat.image_url} 
                                alt={cat.name} 
                                className="h-9 w-9 rounded-lg object-cover bg-bg-input border border-border-card"
                              />
                            ) : (
                              <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-bg-input border border-border-card text-text-secondary">
                                <FileImage className="h-4 w-4" />
                              </div>
                            )}
                            <span className="font-semibold text-text-primary">{cat.name}</span>
                          </div>
                        )}
                      </td>

                      {/* Slug */}
                      <td className="px-6 py-4 font-mono text-xs text-text-secondary">
                        {isEditing ? (
                          <input
                            type="text"
                            value={editingSlug}
                            onChange={(e) => setEditingSlug(e.target.value)}
                            className="rounded-lg bg-bg-input border border-border-card px-2.5 py-1.5 text-xs text-text-primary focus:outline-none"
                          />
                        ) : (
                          <span className="rounded bg-bg-input px-2 py-0.5 border border-border-card text-emerald-400">
                            {cat.slug}
                          </span>
                        )}
                      </td>

                      {/* Created At */}
                      <td className="px-6 py-4 text-text-secondary text-xs">
                        <span className="flex items-center gap-1.5">
                          <Calendar className="h-3.5 w-3.5" />
                          {new Date(cat.created_at).toLocaleDateString(undefined, { 
                            year: 'numeric', 
                            month: 'short', 
                            day: 'numeric' 
                          })}
                        </span>
                      </td>

                      {/* Actions */}
                      <td className="px-6 py-4 text-right">
                        {isEditing ? (
                          <div className="flex items-center justify-end gap-2">
                            <button
                              onClick={() => handleUpdateCategory(cat.id)}
                              className="rounded-lg p-1.5 text-emerald-400 hover:bg-emerald-500/10 transition-colors cursor-pointer"
                              title="Save Changes"
                            >
                              <Check className="h-4.5 w-4.5" />
                            </button>
                            <button
                              onClick={cancelEdit}
                              className="rounded-lg p-1.5 text-text-secondary hover:bg-hover-panel transition-colors cursor-pointer"
                              title="Cancel"
                            >
                              <X className="h-4.5 w-4.5" />
                            </button>
                          </div>
                        ) : (
                          <div className="flex items-center justify-end gap-2">
                            <button
                              onClick={() => startEdit(cat)}
                              className="rounded-lg p-1.5 text-text-secondary hover:bg-hover-panel hover:text-text-primary transition-colors cursor-pointer"
                              title="Edit Category"
                            >
                              <Edit3 className="h-4.5 w-4.5" />
                            </button>
                            <button
                              onClick={() => handleDeleteCategory(cat.id, cat.name)}
                              className="rounded-lg p-1.5 text-text-secondary hover:bg-red-500/10 hover:text-red-400 transition-colors cursor-pointer"
                              title="Delete Category"
                            >
                              <Trash2 className="h-4.5 w-4.5" />
                            </button>
                          </div>
                        )}
                      </td>
                    </tr>
                  );
                })
              ) : (
                <tr>
                  <td colSpan={5} className="px-6 py-12 text-center text-text-secondary">
                    {isLoading ? 'Loading categories...' : 'No categories found.'}
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
