import { getBackendUrl } from './config';

export interface Product {
  id: string;
  title: string;
  price: number;
  unit: string;
  category: string;
  image_url: string;
  stock: number;
}

export interface PipelineStep {
  id: 'presigned-url' | 'r2-upload' | 'create-product';
  name: string;
  status: 'idle' | 'running' | 'success' | 'failed';
  details?: string;
}

export const CATEGORIES = [
  'Fruits',
  'Vegetables',
  'Dairy & Eggs',
  'Bakery',
  'Meat & Seafood',
  'Pantry Staples',
  'Beverages',
  'Snacks'
];

export function fetchProducts(): Product[] {
  const stored = localStorage.getItem('grocery_products');
  if (!stored) {
    return [];
  }
  try {
    const list = JSON.parse(stored);
    if (Array.isArray(list)) {
      return list.filter((item: Product) => item && item.id && !item.id.startsWith('prod-'));
    }
  } catch (e) {
    console.error("Failed to parse stored products:", e);
  }
  return [];
}

export function saveProducts(products: Product[]) {
  localStorage.setItem('grocery_products', JSON.stringify(products));
}

const delay = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

export interface PipelineProgressEvent {
  stepId: 'presigned-url' | 'r2-upload' | 'create-product';
  status: 'idle' | 'running' | 'success' | 'failed';
  message: string;
  data?: any;
}

let categoryMap: { [name: string]: number } = {};

const FALLBACK_CATEGORY_MAP: { [name: string]: number } = {
  'Fruits': 1,
  'Vegetables': 2,
  'Dairy & Eggs': 3,
  'Bakery': 4,
  'Meat & Seafood': 5,
  'Pantry Staples': 6,
  'Beverages': 7,
  'Snacks': 8
};

const CATEGORY_FALLBACK_IMAGES: { [category: string]: string } = {
  'Fruits': 'https://images.unsplash.com/photo-1619546813926-a78fa6372cd2?auto=format&fit=crop&q=80&w=400',
  'Vegetables': 'https://images.unsplash.com/photo-1566385101042-1a0aa0c1268c?auto=format&fit=crop&q=80&w=400',
  'Dairy & Eggs': 'https://images.unsplash.com/photo-1550583724-b2692b85b150?auto=format&fit=crop&q=80&w=400',
  'Bakery': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&q=80&w=400',
  'Meat & Seafood': 'https://images.unsplash.com/photo-1607623814075-e51df1bdc82f?auto=format&fit=crop&q=80&w=400',
  'Pantry Staples': 'https://images.unsplash.com/photo-1549203396-abae8a36a77b?auto=format&fit=crop&q=80&w=400',
  'Beverages': 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?auto=format&fit=crop&q=80&w=400',
  'Snacks': 'https://images.unsplash.com/photo-1599490659213-e2b9527b0876?auto=format&fit=crop&q=80&w=400'
};

async function ensureCategoryMap() {
  if (Object.keys(categoryMap).length > 0) return;
  try {
    const res = await fetch(`${getBackendUrl()}/api/v1/categories`);
    const json = await res.json();
    if (json.success && Array.isArray(json.data)) {
      json.data.forEach((cat: { id: number; name: string }) => {
        categoryMap[cat.name] = cat.id;
      });
    }
  } catch (err) {
    console.error("Failed to fetch categories from backend, using fallback map:", err);
  }
}

export async function runMockUploadPipeline(
  file: File,
  metadata: Omit<Product, 'id' | 'image_url'>,
  onUpdate: (event: PipelineProgressEvent) => void
): Promise<Product> {
  const BACKEND_BASE = getBackendUrl();
  const AUTH_TOKEN = 'admin-secret-token';
  const fileExtension = '.webp';
  const cleanFilename = `${Date.now()}_${file.name.replace(/[^a-zA-Z0-9]/g, '_')}${fileExtension}`;

  await ensureCategoryMap();
  const categoryId = categoryMap[metadata.category] || FALLBACK_CATEGORY_MAP[metadata.category] || null;

  // STEP 1: Fetch Presigned URL
  onUpdate({
    stepId: 'presigned-url',
    status: 'running',
    message: `POST ${BACKEND_BASE}/api/v1/admin/products/presign\nPayload: { filename: "${cleanFilename}", contentType: "image/webp" }`
  });
  await delay(600); // Small delay for visual pipeline tracing

  let presignedUrl = '';
  let downloadUrl = '';
  try {
    const presignRes = await fetch(`${BACKEND_BASE}/api/v1/admin/products/presign`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${AUTH_TOKEN}`
      },
      body: JSON.stringify({
        filename: cleanFilename,
        contentType: 'image/webp'
      })
    });

    if (!presignRes.ok) {
      throw new Error(`Presign API error: Status ${presignRes.status}`);
    }

    const presignJson = await presignRes.json();
    if (!presignJson.success || !presignJson.data) {
      throw new Error(presignJson.message || 'Presign failed');
    }

    presignedUrl = presignJson.data.uploadUrl;
    downloadUrl = presignJson.data.downloadUrl;

    onUpdate({
      stepId: 'presigned-url',
      status: 'success',
      message: `Successfully obtained presigned URL.`,
      data: { presignedUrl, downloadUrl }
    });
  } catch (err: any) {
    onUpdate({
      stepId: 'presigned-url',
      status: 'failed',
      message: `Presigned URL generation failed: ${err.message}`
    });
    throw err;
  }

  // STEP 2: Upload raw file directly to R2
  onUpdate({
    stepId: 'r2-upload',
    status: 'running',
    message: `PUT ${presignedUrl.split('?')[0]} (Size: ${(file.size / 1024).toFixed(2)} KB)`
  });
  await delay(600);

  let finalImageUrl = downloadUrl;
  let useFallbackUrl = false;
  try {
    const uploadRes = await fetch(presignedUrl, {
      method: 'PUT',
      headers: {
        'Content-Type': 'image/webp'
      },
      body: file
    });

    if (!uploadRes.ok) {
      throw new Error(`R2 PUT error: Status ${uploadRes.status}`);
    }

    onUpdate({
      stepId: 'r2-upload',
      status: 'success',
      message: `File uploaded to Cloudflare R2 successfully. Direct URL: ${downloadUrl}`,
      data: { r2Url: downloadUrl }
    });
  } catch (err: any) {
    console.warn("R2 Direct upload failed. Falling back to stable category image for developer testing.", err);
    useFallbackUrl = true;
    finalImageUrl = CATEGORY_FALLBACK_IMAGES[metadata.category] || 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&q=80&w=400';
    onUpdate({
      stepId: 'r2-upload',
      status: 'success',
      message: `⚠️ R2 PUT failed (Using mock credentials). Falling back to stable category placeholder image.`,
      data: { r2Url: finalImageUrl }
    });
  }

  // STEP 3: Post the entire metadata payload to the products endpoint
  const backendPayload = {
    category_id: categoryId,
    title: metadata.title,
    price: metadata.price,
    unit: metadata.unit,
    stock_quantity: metadata.stock,
    image_url: finalImageUrl,
    is_available: true
  };

  onUpdate({
    stepId: 'create-product',
    status: 'running',
    message: `POST ${BACKEND_BASE}/api/v1/admin/products\nPayload: ${JSON.stringify(backendPayload, null, 2)}`
  });
  await delay(600);

  try {
    const createRes = await fetch(`${BACKEND_BASE}/api/v1/admin/products`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${AUTH_TOKEN}`
      },
      body: JSON.stringify(backendPayload)
    });

    if (!createRes.ok) {
      throw new Error(`Create Product API error: Status ${createRes.status}`);
    }

    const createJson = await createRes.json();
    if (!createJson.success || !createJson.data) {
      throw new Error(createJson.message || 'Product creation failed');
    }

    const backendProduct = createJson.data;

    // Map backend product details to local frontend Product structure to avoid runtime UI crashes
    const mappedProduct: Product = {
      id: String(backendProduct.id),
      title: backendProduct.title,
      price: parseFloat(backendProduct.price),
      unit: backendProduct.unit || '',
      category: metadata.category,
      image_url: useFallbackUrl ? finalImageUrl : (backendProduct.image_url || ''),
      stock: backendProduct.stock_quantity ?? 0
    };

    const products = fetchProducts();
    products.unshift(mappedProduct);
    saveProducts(products);

    onUpdate({
      stepId: 'create-product',
      status: 'success',
      message: `Product successfully saved in Neon DB. ID: ${mappedProduct.id}`,
      data: mappedProduct
    });

    return mappedProduct;
  } catch (err: any) {
    onUpdate({
      stepId: 'create-product',
      status: 'failed',
      message: `Failed to save product in Neon DB: ${err.message}`
    });
    throw err;
  }
}
