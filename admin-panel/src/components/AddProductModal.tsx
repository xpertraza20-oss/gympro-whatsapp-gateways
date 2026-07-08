import { useState, useRef, type ChangeEvent, type FormEvent } from 'react';
import { 
  X, 
  Upload, 
  Image as ImageIcon, 
  Scale, 
  ArrowRight, 
  CheckCircle, 
  AlertCircle,
  Loader2,
  Terminal,
  Database,
  CloudLightning,
  Coins
} from 'lucide-react';
import { compressImageToWebP, type CompressionResult } from '../utils/imageCompressor';
import { runMockUploadPipeline, CATEGORIES, type PipelineProgressEvent, type Product } from '../utils/mockApi';
import { getSwal, showToast } from '../utils/alerts';

interface AddProductModalProps {
  isOpen: boolean;
  onClose: () => void;
  onProductAdded: (newProduct: Product) => void;
}

export default function AddProductModal({ isOpen, onClose, onProductAdded }: AddProductModalProps) {
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
  
  // Pipeline/Network status state
  const [isUploading, setIsUploading] = useState(false);
  const [pipelineLogs, setPipelineLogs] = useState<{ timestamp: string; message: string; type: 'info' | 'success' | 'error' }[]>([]);
  const [steps, setSteps] = useState([
    { id: 'presigned-url', name: 'Get Presigned S3/R2 URL', status: 'idle' as 'idle' | 'running' | 'success' | 'failed' },
    { id: 'r2-upload', name: 'Upload binary file directly to R2', status: 'idle' as 'idle' | 'running' | 'success' | 'failed' },
    { id: 'create-product', name: 'Save product record & metadata', status: 'idle' as 'idle' | 'running' | 'success' | 'failed' },
  ]);

  const fileInputRef = useRef<HTMLInputElement>(null);

  if (!isOpen) return null;

  // Handle image file selection and compression
  const handleImageChange = async (e: ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setIsCompressing(true);
    setCompressionStats(null);
    setCompressedImage(null);

    // Revoke previous preview URL if any
    if (previewUrl) {
      URL.revokeObjectURL(previewUrl);
    }

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

  // Run S3/R2 upload and save product
  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    const swal = getSwal();
    if (!compressedImage) {
      swal.fire({
        title: 'Missing Image',
        text: 'Please select and compress an image first.',
        icon: 'warning'
      });
      return;
    }

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
      addLog("Starting product creation pipeline...");
      
      const newProduct = await runMockUploadPipeline(
        compressedImage,
        {
          title,
          price: priceNum,
          unit,
          category,
          stock: stockNum
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

      addLog("Pipeline execution complete! Adding product to table.", "success");
      showToast('success', 'Product created successfully!');
      
      // Clear forms
      setTimeout(() => {
        onProductAdded(newProduct);
        handleClose();
      }, 1000);

    } catch (err: any) {
      addLog(`Critical Pipeline Failure: ${err instanceof Error ? err.message : 'Unknown error'}`, 'error');
      swal.fire({
        title: 'Pipeline Error',
        text: `Failed to create product: ${err.message || err}`,
        icon: 'error'
      });
    } finally {
      setIsUploading(false);
    }
  };

  const handleClose = () => {
    // Clean states
    setTitle('');
    setPrice('');
    setUnit('1 kg bag');
    setCategory(CATEGORIES[0]);
    setStock('10');
    setCompressedImage(null);
    setCompressionStats(null);
    if (previewUrl) {
      URL.revokeObjectURL(previewUrl);
      setPreviewUrl(null);
    }
    setPipelineLogs([]);
    setIsUploading(false);
    onClose();
  };

  const formatSize = (bytes: number) => {
    return `${(bytes / 1024).toFixed(1)} KB`;
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-body/80 backdrop-blur-md overflow-y-auto">
      <div className="relative w-full max-w-4xl rounded-3xl border border-border-card bg-panel shadow-2xl transition-all duration-300">
        
        {/* Header */}
        <div className="flex items-center justify-between border-b border-border-card px-6 py-4.5">
          <div>
            <h2 className="text-xl font-bold text-text-primary flex items-center gap-2">
              <Database className="h-5.5 w-5.5 text-emerald-400" />
              Add New Catalog Product
            </h2>
            <p className="text-xs text-text-secondary mt-0.5">Define metadata, compress image assets, and publish to inventory</p>
          </div>
          <button
            onClick={handleClose}
            className="rounded-lg p-1.5 text-text-secondary hover:bg-hover-panel hover:text-text-primary transition-colors cursor-pointer"
          >
            <X className="h-5.5 w-5.5" />
          </button>
        </div>

        {/* Form Content */}
        <form onSubmit={handleSubmit} className="p-6">
          <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
            
            {/* Left side: Product details */}
            <div className="space-y-4.5">
              <div>
                <label className="block text-xs font-semibold text-text-secondary uppercase tracking-wider mb-1.5">
                  Product Title *
                </label>
                <input
                  type="text"
                  required
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  placeholder="e.g. Organic Honeycrisp Apples"
                  className="w-full rounded-xl bg-bg-input border border-border-card px-4 py-2.5 text-sm text-text-primary focus:outline-none focus:border-emerald-500 transition-colors"
                  disabled={isUploading}
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-semibold text-text-secondary uppercase tracking-wider mb-1.5">
                    Price (USD) *
                  </label>
                  <input
                    type="number"
                    step="0.01"
                    required
                    value={price}
                    onChange={(e) => setPrice(e.target.value)}
                    placeholder="e.g. 4.99"
                    className="w-full rounded-xl bg-bg-input border border-border-card px-4 py-2.5 text-sm text-text-primary focus:outline-none focus:border-emerald-500 transition-colors"
                    disabled={isUploading}
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-text-secondary uppercase tracking-wider mb-1.5">
                    Unit Size *
                  </label>
                  <input
                    type="text"
                    required
                    value={unit}
                    onChange={(e) => setUnit(e.target.value)}
                    placeholder="e.g. 1 kg bag, each"
                    className="w-full rounded-xl bg-bg-input border border-border-card px-4 py-2.5 text-sm text-text-primary focus:outline-none focus:border-emerald-500 transition-colors"
                    disabled={isUploading}
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-semibold text-text-secondary uppercase tracking-wider mb-1.5">
                    Category *
                  </label>
                  <select
                    value={category}
                    onChange={(e) => setCategory(e.target.value)}
                    className="w-full rounded-xl bg-bg-input border border-border-card px-4 py-2.5 text-sm text-text-primary focus:outline-none focus:border-emerald-500 transition-colors"
                    disabled={isUploading}
                  >
                    {CATEGORIES.map(cat => (
                      <option key={cat} value={cat}>{cat}</option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="block text-xs font-semibold text-text-secondary uppercase tracking-wider mb-1.5">
                    Initial Stock *
                  </label>
                  <input
                    type="number"
                    required
                    value={stock}
                    onChange={(e) => setStock(e.target.value)}
                    placeholder="e.g. 15"
                    className="w-full rounded-xl bg-bg-input border border-border-card px-4 py-2.5 text-sm text-text-primary focus:outline-none focus:border-emerald-500 transition-colors"
                    disabled={isUploading}
                  />
                </div>
              </div>

              {/* Image Selector Dropzone */}
              <div>
                <label className="block text-xs font-semibold text-text-secondary uppercase tracking-wider mb-1.5">
                  Product Image *
                </label>
                <div 
                  onClick={() => !isUploading && fileInputRef.current?.click()}
                  className={`flex flex-col items-center justify-center rounded-2xl border-2 border-dashed px-4 py-6 transition-all duration-200 text-center ${
                    previewUrl 
                      ? 'border-emerald-500/40 bg-emerald-500/[0.01]' 
                      : 'border-border-card bg-bg-input hover:border-text-secondary hover:bg-hover-panel'
                  } ${isUploading ? 'opacity-60 cursor-not-allowed' : 'cursor-pointer'}`}
                >
                  <input
                    type="file"
                    ref={fileInputRef}
                    onChange={handleImageChange}
                    accept="image/*"
                    className="hidden"
                    disabled={isUploading}
                  />
                  {previewUrl ? (
                    <div className="flex flex-col items-center gap-2">
                      <img 
                        src={previewUrl} 
                        alt="Preview" 
                        className="h-20 w-20 rounded-xl object-cover ring-2 ring-emerald-500/20" 
                      />
                      <span className="text-xs font-semibold text-emerald-400 flex items-center gap-1.5">
                        <CheckCircle className="h-4 w-4" /> Ready for Upload
                      </span>
                    </div>
                  ) : (
                    <div className="flex flex-col items-center gap-2">
                      {isCompressing ? (
                        <>
                          <Loader2 className="h-8 w-8 text-emerald-400 animate-spin" />
                          <span className="text-xs font-semibold text-emerald-400">Processing image client-side...</span>
                        </>
                      ) : (
                        <>
                          <div className="rounded-xl bg-panel p-2 text-text-secondary border border-border-card">
                            <Upload className="h-6 w-6" />
                          </div>
                          <span className="text-sm font-semibold text-text-primary">Upload Product Image</span>
                          <span className="text-xs text-text-secondary">Auto-converts to optimized WebP &lt; 150KB</span>
                        </>
                      )}
                    </div>
                  )}
                </div>
              </div>
            </div>

            {/* Right side: Image compression stats & Network pipeline console */}
            <div className="flex flex-col justify-between space-y-4">
              
              {/* Compression stats widget */}
              <div className="rounded-2xl border border-border-card bg-bg-input p-4.5 space-y-3.5">
                <h3 className="text-xs font-bold uppercase tracking-wider text-text-secondary flex items-center gap-1.5">
                  <Scale className="h-4 w-4 text-emerald-400" />
                  Client-Side WebP Compression Stats
                </h3>
                
                {compressionStats ? (
                  <div className="grid grid-cols-2 gap-4">
                    <div className="rounded-xl bg-panel/50 p-3 border border-border-card/40">
                      <p className="text-[10px] uppercase font-bold text-text-secondary">Original Size</p>
                      <p className="text-sm font-bold text-text-primary mt-0.5">{formatSize(compressionStats.originalSize)}</p>
                      <p className="text-[10px] text-text-secondary mt-1">{compressionStats.originalWidth}x{compressionStats.originalHeight}px</p>
                    </div>

                    <div className="rounded-xl bg-emerald-500/5 p-3 border border-emerald-500/20">
                      <p className="text-[10px] uppercase font-bold text-emerald-400">Compressed WebP</p>
                      <p className="text-sm font-bold text-emerald-355 mt-0.5">{formatSize(compressionStats.compressedSize)}</p>
                      <p className="text-[10px] text-emerald-500 mt-1 font-semibold">
                        -{Math.round((1 - compressionStats.compressedSize / compressionStats.originalSize) * 100)}% Reduction
                      </p>
                    </div>

                    <div className="col-span-2 flex items-center justify-between border-t border-border-card/60 pt-2.5 text-xs text-text-secondary">
                      <span className="flex items-center gap-1">
                        Quality: <span className="font-bold text-text-primary">{(compressionStats.qualityUsed * 100)}%</span>
                      </span>
                      <span className="flex items-center gap-1">
                        Iterations: <span className="font-bold text-text-primary">{compressionStats.iterations}</span>
                      </span>
                      <span className="rounded-full bg-emerald-500/10 px-2 py-0.5 text-[10px] font-bold text-emerald-400 border border-emerald-500/20">
                        &lt; 150KB Target Passed
                      </span>
                    </div>
                  </div>
                ) : (
                  <div className="flex h-28 flex-col items-center justify-center text-center text-text-secondary border border-dashed border-border-card/50 rounded-xl">
                    <ImageIcon className="h-6 w-6 mb-1 opacity-40 animate-pulse" />
                    <p className="text-xs">No image compressed yet.</p>
                    <p className="text-[10px] text-text-secondary">Select an asset file in the dropzone</p>
                  </div>
                )}
              </div>

              {/* Pipeline console widget */}
              <div className="flex-1 flex flex-col rounded-2xl border border-border-card bg-bg-input overflow-hidden min-h-[220px]">
                {/* Console header */}
                <div className="flex items-center justify-between bg-panel px-4 py-2 border-b border-border-card">
                  <div className="flex items-center gap-2">
                    <Terminal className="h-4 w-4 text-emerald-400" />
                    <span className="text-xs font-semibold text-text-secondary font-mono">deployment_pipeline_logger</span>
                  </div>
                  {isUploading && (
                    <span className="flex items-center gap-1 text-[10px] text-emerald-400 animate-pulse font-mono font-bold">
                      <Loader2 className="h-3 w-3 animate-spin" /> RUNNING
                    </span>
                  )}
                </div>

                {/* Console logs */}
                <div className="flex-1 p-3 overflow-y-auto font-mono text-xs text-text-secondary space-y-1 bg-bg-input max-h-[200px] min-h-[140px]">
                  {pipelineLogs.length > 0 ? (
                    pipelineLogs.map((log, idx) => (
                      <div key={idx} className="flex gap-2 items-start leading-relaxed whitespace-pre-wrap">
                        <span className="text-[10px] text-text-secondary shrink-0 mt-0.5">[{log.timestamp}]</span>
                        <span className={
                          log.type === 'success' ? 'text-emerald-400' :
                          log.type === 'error' ? 'text-red-400 font-bold' : 'text-text-primary'
                        }>
                          {log.message}
                        </span>
                      </div>
                    ))
                  ) : (
                    <div className="h-full flex flex-col items-center justify-center text-text-secondary">
                      <CloudLightning className="h-5 w-5 mb-1.5 opacity-30" />
                      <p className="text-[10px] uppercase font-bold tracking-wider">Pipeline Idle</p>
                      <p className="text-[10px] text-text-secondary mt-0.5">Submit the form to deploy image and register data</p>
                    </div>
                  )}
                </div>
              </div>
            </div>
          </div>

          {/* Visual Checklist for pipeline steps */}
          <div className="mt-6 border-t border-border-card/85 pt-5">
            <h4 className="text-xs font-bold uppercase tracking-wider text-text-secondary mb-3 flex items-center gap-1.5">
              <Coins className="h-4 w-4 text-emerald-400" />
              S3 Direct-to-R2 Cloud Infrastructure Checklist
            </h4>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-3.5">
              {steps.map(step => (
                <div 
                  key={step.id} 
                  className={`flex items-center gap-3 rounded-xl p-3 border transition-colors ${
                    step.status === 'success' ? 'border-emerald-500/20 bg-emerald-500/[0.02]' :
                    step.status === 'running' ? 'border-emerald-500/30 bg-hover-panel animate-pulse' :
                    step.status === 'failed' ? 'border-red-500/20 bg-red-500/[0.02]' :
                    'border-border-card bg-panel opacity-70'
                  }`}
                >
                  {step.status === 'success' && <CheckCircle className="h-5 w-5 text-emerald-400 shrink-0" />}
                  {step.status === 'running' && <Loader2 className="h-5 w-5 text-emerald-400 animate-spin shrink-0" />}
                  {step.status === 'failed' && <AlertCircle className="h-5 w-5 text-red-400 shrink-0" />}
                  {step.status === 'idle' && <div className="h-5 w-5 rounded-full border-2 border-slate-700 shrink-0" />}
                  
                  <div className="overflow-hidden">
                    <p className={`text-xs font-bold truncate ${
                      step.status === 'success' ? 'text-emerald-400' :
                      step.status === 'running' ? 'text-text-primary font-bold' :
                      step.status === 'failed' ? 'text-red-400' : 'text-text-secondary'
                    }`}>
                      {step.name}
                    </p>
                    <p className="text-[10px] text-text-secondary truncate mt-0.5">
                      {step.id === 'presigned-url' ? 'Sign bucket permissions' :
                       step.id === 'r2-upload' ? 'Avoid backend proxy load' :
                       'Store category/price in DB'}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Form Actions */}
          <div className="mt-6 flex justify-end gap-3.5 border-t border-border-card/85 pt-5">
            <button
              type="button"
              onClick={handleClose}
              disabled={isUploading}
              className="rounded-xl border border-border-card bg-bg-input px-5 py-2.5 text-sm font-semibold text-text-secondary hover:bg-hover-panel hover:text-text-primary transition-colors cursor-pointer disabled:opacity-40"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={!compressedImage || isUploading || isCompressing}
              className="flex items-center justify-center gap-2 rounded-xl bg-gradient-to-r from-emerald-500 to-teal-500 px-6 py-2.5 text-sm font-bold text-slate-950 hover:brightness-110 active:scale-98 disabled:opacity-40 disabled:pointer-events-none transition-all duration-200 cursor-pointer shadow-lg shadow-emerald-500/10"
            >
              {isUploading ? (
                <>
                  <Loader2 className="h-4.5 w-4.5 animate-spin" /> Deploying...
                </>
              ) : (
                <>
                  Publish Asset <ArrowRight className="h-4.5 w-4.5" />
                </>
              )}
            </button>
          </div>

        </form>

      </div>
    </div>
  );
}
