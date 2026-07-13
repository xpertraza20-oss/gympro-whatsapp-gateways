import { useState, useRef, useEffect, type ChangeEvent, type FormEvent } from 'react';
import { 
  X, 
  Upload, 
  Image as ImageIcon, 
  Scale, 
  ArrowRight, 
  Loader2, 
  Terminal,
  Database
} from 'lucide-react';
import { compressImageToWebP, type CompressionResult } from '../utils/imageCompressor';
import { runMockUpdatePipeline, CATEGORIES, type PipelineProgressEvent, type Product } from '../utils/mockApi';
import { getSwal, showToast } from '../utils/alerts';

interface EditProductModalProps {
  isOpen: boolean;
  onClose: () => void;
  product: Product | null;
  onProductUpdated: (updatedProduct: Product) => void;
}

const formatSize = (bytes: number) => {
  return `${(bytes / 1024).toFixed(1)} KB`;
};

export default function EditProductModal({ isOpen, onClose, product, onProductUpdated }: EditProductModalProps) {
  // Form state
  const [title, setTitle] = useState('');
  const [price, setPrice] = useState('');
  const [unit, setUnit] = useState('1 kg bag');
  const [category, setCategory] = useState(CATEGORIES[0]);
  const [stock, setStock] = useState('10');
  
  // Image & Compression State
  const [compressedImage, setCompressedImage] = useState<File | null>(null);
  const [compressionStats, setCompressionStats] = useState<CompressionResult | null>(null);
  const [isCompressing, setIsCompressing] = useState(false);
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const [imageUrl, setImageUrl] = useState('');
  
  // Pipeline/Network status state
  const [isUploading, setIsUploading] = useState(false);
  const [pipelineLogs, setPipelineLogs] = useState<{ timestamp: string; message: string; type: 'info' | 'success' | 'error' }[]>([]);
  const [steps, setSteps] = useState([
    { id: 'presigned-url', name: 'Get Presigned S3/R2 URL', status: 'idle' as 'idle' | 'running' | 'success' | 'failed' },
    { id: 'r2-upload', name: 'Upload binary file directly to R2', status: 'idle' as 'idle' | 'running' | 'success' | 'failed' },
    { id: 'create-product', name: 'Save product record & metadata', status: 'idle' as 'idle' | 'running' | 'success' | 'failed' },
  ]);

  const fileInputRef = useRef<HTMLInputElement>(null);

  // Load product data when opened or product changes
  useEffect(() => {
    if (product && isOpen) {
      setTitle(product.title);
      setPrice(String(product.price));
      setUnit(product.unit || 'each');
      setCategory(product.category);
      setStock(String(product.stock));
      setPreviewUrl(product.image_url || null);
      setImageUrl(product.image_url || '');
      setCompressedImage(null);
      setCompressionStats(null);
      setPipelineLogs([]);
      setSteps([
        { id: 'presigned-url', name: 'Get Presigned S3/R2 URL', status: 'idle' },
        { id: 'r2-upload', name: 'Upload binary file directly to R2', status: 'idle' },
        { id: 'create-product', name: 'Save product record & metadata', status: 'idle' },
      ]);
    }
  }, [product, isOpen]);

  if (!isOpen || !product) return null;

  // Handle image file selection and compression
  const handleImageChange = async (e: ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setIsCompressing(true);
    setCompressionStats(null);
    setCompressedImage(null);

    try {
      // Compress the image down to < 150KB and WebP
      const result = await compressImageToWebP(file, 150, 1000);
      setCompressedImage(result.compressedFile);
      setCompressionStats(result);
      
      // Use local ObjectURL for form preview
      const localUrl = URL.createObjectURL(result.compressedFile);
      setPreviewUrl(localUrl);
    } catch (err) {
      console.error("Compression error:", err);
      getSwal().fire({
        title: 'Compression Error',
        text: 'Failed to compress the selected image. Please verify that the image format is valid.',
        icon: 'error'
      });
    } finally {
      setIsCompressing(false);
    }
  };

  // Run update pipeline
  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    const swal = getSwal();

    const priceNum = parseFloat(price);
    const stockNum = parseInt(stock, 10);
    if (isNaN(priceNum) || priceNum <= 0) {
      swal.fire({
        title: 'Invalid Price',
        text: 'Please enter a valid price (greater than 0).',
        icon: 'warning'
      });
      return;
    }
    if (isNaN(stockNum) || stockNum < 0) {
      swal.fire({
        title: 'Invalid Stock Count',
        text: 'Please enter a valid stock count (0 or greater).',
        icon: 'warning'
      });
      return;
    }

    setIsUploading(true);
    setPipelineLogs([]);
    
    // Reset steps
    setSteps([
      { id: 'presigned-url', name: 'Get Presigned S3/R2 URL', status: 'idle' },
      { id: 'r2-upload', name: 'Upload binary file directly to R2', status: 'idle' },
      { id: 'create-product', name: 'Save product record & metadata', status: 'idle' },
    ]);

    const addLog = (message: string, type: 'info' | 'success' | 'error' = 'info') => {
      const time = new Date().toLocaleTimeString();
      setPipelineLogs(prev => [...prev, { timestamp: time, message, type }]);
    };

    try {
      addLog("Starting product update pipeline...");
      
      const updatedProduct = await runMockUpdatePipeline(
        product.id,
        compressedImage,
        {
          title,
          price: priceNum,
          unit,
          category,
          stock: stockNum,
          image_url: imageUrl
        },
        (progress: PipelineProgressEvent) => {
          // Update visual checklist
          setSteps(prev => prev.map(s => s.id === progress.stepId ? { ...s, status: progress.status } : s));
          
          // Add terminal log
          if (progress.status === 'running') {
            addLog(progress.message, 'info');
          } else if (progress.status === 'success') {
            addLog(progress.message, 'success');
            if (progress.data) {
              addLog(`Data returned: ${JSON.stringify(progress.data, null, 2)}`, 'info');
            }
          } else if (progress.status === 'failed') {
            addLog(`Step failed: ${progress.message}`, 'error');
          }
        }
      );

      addLog("Pipeline execution complete! Updating product in table.", "success");
      showToast('success', 'Product updated successfully!');
      
      setTimeout(() => {
        onProductUpdated(updatedProduct);
        onClose();
      }, 1000);

    } catch (err: any) {
      addLog(`Critical Pipeline Failure: ${err instanceof Error ? err.message : 'Unknown error'}`, 'error');
      swal.fire({
        title: 'Pipeline Error',
        text: `Failed to update product: ${err.message || err}`,
        icon: 'error'
      });
    } finally {
      setIsUploading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/60 backdrop-blur-sm animate-fade-in">
      <div className="relative w-full max-w-4xl max-h-[90vh] overflow-y-auto rounded-3xl glass-panel shadow-2xl border border-white/10 flex flex-col md:flex-row bg-slate-900 text-slate-100">
        
        {/* Left Side: Image upload & Compression stats */}
        <div className="w-full md:w-1/2 p-6 md:p-8 flex flex-col justify-between border-b md:border-b-0 md:border-r border-white/10">
          <div>
            <div className="flex items-center justify-between mb-6">
              <h3 className="text-xl font-bold text-white flex items-center gap-2">
                <ImageIcon className="h-5 w-5 text-emerald-400" /> Product Image
              </h3>
            </div>

            {/* Preview Box */}
            <div 
              onClick={() => !isUploading && fileInputRef.current?.click()}
              className={`group relative flex h-64 cursor-pointer items-center justify-center overflow-hidden rounded-2xl border-2 border-dashed transition-all duration-300 ${
                previewUrl 
                  ? 'border-emerald-500/50 hover:border-emerald-400' 
                  : 'border-white/10 hover:border-emerald-500/50 bg-slate-950/30'
              }`}
            >
              {previewUrl ? (
                <>
                  <img 
                    src={previewUrl} 
                    alt="Preview" 
                    className="h-full w-full object-cover transition-transform duration-300 group-hover:scale-103"
                  />
                  <div className="absolute inset-0 bg-slate-950/40 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity duration-200">
                    <span className="rounded-full bg-white/10 px-4 py-2 text-xs font-bold backdrop-blur-md border border-white/20">Change Image</span>
                  </div>
                </>
              ) : (
                <div className="text-center p-4">
                  <Upload className="mx-auto h-10 w-10 text-slate-400 group-hover:text-emerald-400 group-hover:scale-110 transition-all duration-300" />
                  <p className="mt-2 text-sm font-semibold text-slate-300">Upload Product Image</p>
                  <p className="mt-1 text-xs text-slate-500">Formats: JPG, PNG, WEBP</p>
                </div>
              )}
              
              {isCompressing && (
                <div className="absolute inset-0 flex flex-col items-center justify-center bg-slate-900/80 backdrop-blur-xs">
                  <Loader2 className="h-8 w-8 animate-spin text-emerald-400" />
                  <span className="mt-2 text-xs font-bold text-slate-300">Compressing Image...</span>
                </div>
              )}
            </div>

            <input 
              type="file" 
              ref={fileInputRef} 
              onChange={handleImageChange}
              accept="image/*"
              className="hidden"
            />

            <div className="mt-3">
              <label className="block text-xs font-semibold text-slate-400 mb-1.5">
                Or Paste Public Image URL
              </label>
              <input
                type="url"
                value={imageUrl}
                onChange={(e) => {
                  setImageUrl(e.target.value);
                  if (e.target.value.trim()) {
                    setPreviewUrl(e.target.value.trim());
                    setCompressedImage(null);
                  }
                }}
                placeholder="https://example.com/image.jpg"
                className="w-full rounded-xl bg-slate-950/40 border border-white/10 px-4 py-2.5 text-sm text-white focus:border-emerald-500 focus:outline-none"
                disabled={isUploading}
              />
            </div>

            {/* Compression Stats */}
            {compressionStats && (
              <div className="mt-6 rounded-2xl bg-emerald-500/5 border border-emerald-500/10 p-4">
                <h4 className="text-xs font-bold uppercase tracking-wider text-emerald-400 flex items-center gap-1.5">
                  <Scale className="h-3.5 w-3.5" /> WebP Smart Compression Stats
                </h4>
                <div className="mt-3 grid grid-cols-2 gap-4">
                  <div>
                    <span className="text-xxs text-slate-400 block font-medium">Original Size</span>
                    <span className="text-sm font-bold text-slate-200">{formatSize(compressionStats.originalSize)}</span>
                  </div>
                  <div>
                    <span className="text-xxs text-slate-400 block font-medium">Compressed Size</span>
                    <span className="text-sm font-bold text-emerald-400">{formatSize(compressionStats.compressedSize)}</span>
                  </div>
                  <div>
                    <span className="text-xxs text-slate-400 block font-medium">Resolution Change</span>
                    <span className="text-sm font-bold text-slate-200">{compressionStats.originalWidth}x{compressionStats.originalHeight} → {compressionStats.compressedWidth}x{compressionStats.compressedHeight}</span>
                  </div>
                  <div>
                    <span className="text-xxs text-slate-400 block font-medium">Size Reduction</span>
                    <span className="text-sm font-bold text-emerald-400">-{Math.round((1 - compressionStats.compressedSize / compressionStats.originalSize) * 100)}%</span>
                  </div>
                </div>
              </div>
            )}
          </div>

          <div className="mt-6 text-xxs text-slate-500 leading-relaxed font-medium">
            Smart Compression optimizes images using WebP in-browser to reduce latency, database footprint, and bandwidth usage on mobile devices.
          </div>
        </div>

        {/* Right Side: Form details & pipeline */}
        <div className="w-full md:w-1/2 p-6 md:p-8 flex flex-col justify-between">
          <button 
            onClick={onClose}
            className="absolute top-4 right-4 rounded-xl p-1.5 text-slate-400 hover:bg-white/5 hover:text-white transition-colors cursor-pointer"
          >
            <X className="h-5 w-5" />
          </button>

          <form onSubmit={handleSubmit} className="space-y-4">
            <h3 className="text-xl font-bold text-white mb-6">Edit Product Details</h3>
            
            <div>
              <label className="text-xs font-semibold text-slate-400">Product Title</label>
              <input 
                type="text" 
                value={title}
                onChange={e => setTitle(e.target.value)}
                required
                className="mt-1.5 w-full rounded-xl bg-slate-950/40 border border-white/10 px-4 py-2.5 text-sm text-white focus:border-emerald-500 focus:outline-none"
                placeholder="Fresh Strawberries"
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="text-xs font-semibold text-slate-400">Price ($)</label>
                <input 
                  type="number" 
                  step="0.01"
                  value={price}
                  onChange={e => setPrice(e.target.value)}
                  required
                  className="mt-1.5 w-full rounded-xl bg-slate-950/40 border border-white/10 px-4 py-2.5 text-sm text-white focus:border-emerald-500 focus:outline-none"
                  placeholder="4.99"
                />
              </div>
              <div>
                <label className="text-xs font-semibold text-slate-400">Unit Description</label>
                <input 
                  type="text" 
                  value={unit}
                  onChange={e => setUnit(e.target.value)}
                  required
                  className="mt-1.5 w-full rounded-xl bg-slate-950/40 border border-white/10 px-4 py-2.5 text-sm text-white focus:border-emerald-500 focus:outline-none"
                  placeholder="250g pack"
                />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="text-xs font-semibold text-slate-400">Category</label>
                <select 
                  value={category}
                  onChange={e => setCategory(e.target.value)}
                  className="mt-1.5 w-full rounded-xl bg-slate-950/40 border border-white/10 px-3 py-2.5 text-sm text-white focus:border-emerald-500 focus:outline-none"
                >
                  {CATEGORIES.map(cat => <option key={cat} value={cat} className="bg-slate-900">{cat}</option>)}
                </select>
              </div>
              <div>
                <label className="text-xs font-semibold text-slate-400">Initial Stock</label>
                <input 
                  type="number" 
                  value={stock}
                  onChange={e => setStock(e.target.value)}
                  required
                  className="mt-1.5 w-full rounded-xl bg-slate-950/40 border border-white/10 px-4 py-2.5 text-sm text-white focus:border-emerald-500 focus:outline-none"
                  placeholder="50"
                />
              </div>
            </div>

            {/* Pipeline status visual Checklist */}
            {isUploading && (
              <div className="mt-6 rounded-2xl bg-slate-950/40 border border-white/10 p-4 space-y-3">
                <h4 className="text-xs font-bold uppercase tracking-wider text-slate-400 flex items-center gap-1.5">
                  <Database className="h-3.5 w-3.5" /> Pipeline Progress
                </h4>
                <div className="space-y-2">
                  {steps.map(step => (
                    <div key={step.id} className="flex items-center justify-between text-xs">
                      <span className="font-semibold text-slate-300">{step.name}</span>
                      <span className={`font-bold uppercase tracking-wider ${
                        step.status === 'success' ? 'text-emerald-400' :
                        step.status === 'failed' ? 'text-red-400' :
                        step.status === 'running' ? 'text-blue-400 animate-pulse' :
                        'text-slate-500'
                      }`}>{step.status}</span>
                    </div>
                  ))}
                </div>

                {/* Pipeline logs terminal */}
                <div className="rounded-xl bg-slate-950 p-3 h-32 overflow-y-auto border border-white/5 font-mono text-xxs leading-relaxed">
                  <div className="flex items-center gap-1 mb-2 text-slate-400 border-b border-white/5 pb-1 font-sans">
                    <Terminal className="h-3.5 w-3.5 text-emerald-400" /> Pipeline Console Logs
                  </div>
                  {pipelineLogs.map((log, idx) => (
                    <div key={idx} className={`mb-1 ${
                      log.type === 'success' ? 'text-emerald-400' :
                      log.type === 'error' ? 'text-red-400' : 'text-slate-300'
                    }`}>
                      <span className="text-slate-600 mr-1.5">[{log.timestamp}]</span>
                      {log.message}
                    </div>
                  ))}
                </div>
              </div>
            )}

            <div className="mt-6 flex items-center gap-3">
              <button 
                type="button"
                onClick={onClose}
                disabled={isUploading}
                className="w-1/3 rounded-xl border border-white/10 py-3 text-sm font-semibold text-slate-300 hover:bg-white/5 disabled:opacity-50 cursor-pointer text-center"
              >
                Cancel
              </button>
              <button 
                type="submit"
                disabled={isUploading || isCompressing}
                className="w-2/3 flex items-center justify-center gap-2 rounded-xl bg-gradient-to-r from-emerald-500 to-teal-500 py-3 text-sm font-bold text-slate-950 hover:brightness-110 active:scale-98 transition-all disabled:opacity-50 disabled:pointer-events-none cursor-pointer"
              >
                {isUploading ? (
                  <>
                    <Loader2 className="h-4 w-4 animate-spin" /> Saving Changes...
                  </>
                ) : (
                  <>
                    Save Changes <ArrowRight className="h-4 w-4" />
                  </>
                )}
              </button>
            </div>
          </form>
        </div>

      </div>
    </div>
  );
}
