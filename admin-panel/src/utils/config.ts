const DEFAULT_BACKEND_URL =
  import.meta.env.VITE_BACKEND_URL || 'https://grocery-backend.xpertraza13.workers.dev';

/**
 * Returns the currently configured Backend Base URL.
 * Defaults to the Cloudflare Worker API.
 */
export const getBackendUrl = (): string => {
  const saved = localStorage.getItem('api_backend_url');
  if (saved) {
    // If it's a local address or tunnel, ignore it on production deployments to prevent mixed content/offline blocks
    if (saved.includes('localhost') || saved.includes('127.0.0.1') || saved.includes('loca.lt') || saved.includes('ngrok')) {
      return DEFAULT_BACKEND_URL;
    }
    return saved;
  }
  return DEFAULT_BACKEND_URL;
};

/**
 * Persists a custom Backend Base URL to local storage.
 */
export const setBackendUrl = (url: string) => {
  // Clean trailing slashes
  const cleaned = url.replace(/\/+$/, '');
  localStorage.setItem('api_backend_url', cleaned);
};

/**
 * Admin auth token is intentionally user-provided, not hardcoded in the bundle.
 */
export const getAdminToken = (): string => {
  return localStorage.getItem('api_admin_token') || import.meta.env.VITE_ADMIN_TOKEN || '';
};

export const setAdminToken = (token: string) => {
  localStorage.setItem('api_admin_token', token.trim());
};

export const clearAdminToken = () => {
  localStorage.removeItem('api_admin_token');
};

export const getAdminHeaders = (json = false): Record<string, string> => {
  const token = getAdminToken();
  return {
    ...(json ? { 'Content-Type': 'application/json' } : {}),
    ...(token ? { Authorization: `Bearer ${token}`, 'X-Admin-Token': token } : {}),
    'bypass-tunnel-reminder': 'true',
  };
};

/**
 * Returns the currently configured Currency Symbol (USD or PKR).
 * Defaults to 'PKR'.
 */
export const getCurrencySymbol = (): string => {
  return localStorage.getItem('api_currency_symbol') || 'PKR';
};

/**
 * Persists the user's selected Currency Symbol.
 */
export const setCurrencySymbol = (symbol: string) => {
  localStorage.setItem('api_currency_symbol', symbol);
};

/**
 * Helper function to format a price value globally based on the active currency configuration.
 */
export const formatPrice = (price: number | string): string => {
  const num = typeof price === 'number' ? price : parseFloat(price) || 0;
  const symbol = getCurrencySymbol();
  if (symbol === 'USD') {
    return `$${num.toFixed(2)}`;
  } else {
    // PKR / Rs. formatting
    return `Rs. ${num.toFixed(2)}`;
  }
};
