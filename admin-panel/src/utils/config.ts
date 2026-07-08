/**
 * Returns the currently configured Backend Base URL.
 * Defaults to the public localtunnel URL so deployed frontend works.
 */
export const getBackendUrl = (): string => {
  return localStorage.getItem('api_backend_url') || 'https://grocery-backend-api.loca.lt';
};

/**
 * Persists a custom Backend Base URL to local storage.
 */
export const setBackendUrl = (url: string) => {
  // Clean trailing slashes
  const cleaned = url.replace(/\/+$/, '');
  localStorage.setItem('api_backend_url', cleaned);
};
