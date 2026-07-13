import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { neon } from '@neondatabase/serverless';

const OTP_TTL_MINUTES = 5;
const JWT_TTL_SECONDS = 60 * 60 * 24 * 30;
const ADMIN_JWT_TTL_SECONDS = 60 * 60 * 8;
const PASSWORD_ITERATIONS = 100000;
const DEFAULT_ALLOWED_ORIGINS = [
  'https://grocery-admin-644.pages.dev',
  'http://localhost:5173',
  'http://localhost:3000',
];
const ORDER_STATUSES = ['Pending', 'Confirmed', 'Dispatched', 'Delivered', 'Cancelled'];

let sqlClient;
let sqlConnectionString;
let schemaReady;

const app = new Hono();

// Edge Cache Helpers
async function getCachedResponse(c) {
  if (c.req.header('bypass-cache') === 'true' || c.req.header('bypass-tunnel-reminder') === 'true') {
    return null;
  }
  try {
    const cache = caches.default;
    const response = await cache.match(c.req.raw);
    if (response) {
      const newResponse = new Response(response.body, response);
      newResponse.headers.set('x-cache-status', 'HIT');
      return newResponse;
    }
  } catch (err) {
    console.error('Cache match error:', err);
  }
  return null;
}

async function setCachedResponse(c, response) {
  try {
    const cache = caches.default;
    const resClone = response.clone();
    const newHeaders = new Headers(resClone.headers);
    newHeaders.set('Cache-Control', 'public, max-age=3600, s-maxage=3600');
    newHeaders.set('x-cache-status', 'MISS');
    const cachedResponse = new Response(resClone.body, {
      status: resClone.status,
      statusText: resClone.statusText,
      headers: newHeaders
    });
    c.executionCtx.waitUntil(cache.put(c.req.raw, cachedResponse.clone()));
  } catch (err) {
    console.error('Cache put error:', err);
  }
}

async function purgeCacheKeys(c, paths) {
  try {
    const cache = caches.default;
    const origin = new URL(c.req.url).origin;
    for (const path of paths) {
      const variations = [
        path,
        `${path}?limit=100`,
        `${path}?limit=20`,
        `${path}?limit=50`,
        `${path}?limit=10`
      ];
      for (const variation of variations) {
        const req = new Request(new URL(variation, origin), { method: 'GET' });
        c.executionCtx.waitUntil(cache.delete(req));
      }
    }
  } catch (err) {
    console.error('Cache purge error:', err);
  }
}

app.use('*', cors({
  origin: (origin, c) => {
    if (!origin) return origin;
    const env = c.env || {};
    const configured = (env.ALLOWED_ORIGINS || '')
      .split(',')
      .map((entry) => entry.trim())
      .filter(Boolean);
    const allowed = [...DEFAULT_ALLOWED_ORIGINS, ...configured];
    if (allowed.includes(origin) || /\.pages\.dev$/.test(origin)) {
      return origin;
    }
    return null;
  },
  allowHeaders: ['Content-Type', 'Authorization', 'X-Admin-Token', 'bypass-tunnel-reminder'],
  allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  credentials: true,
}));

app.onError((err, c) => {
  console.error('[Worker Error]', err);
  const statusCode = err.statusCode || err.status || 500;
  return c.json({
    status: 'error',
    statusCode,
    message: err.message || 'Internal Server Error',
  }, statusCode);
});

app.notFound((c) => c.json({
  status: 'error',
  statusCode: 404,
  message: `Not Found - ${new URL(c.req.url).pathname}`,
}, 404));

function getConnectionString(env) {
  return env.HYPERDRIVE?.connectionString || env.DATABASE_URL;
}

function getSql(env) {
  const connectionString = getConnectionString(env);
  if (!connectionString) {
    throw httpError('DATABASE_URL or HYPERDRIVE binding is required.', 500);
  }
  if (!sqlClient || sqlConnectionString !== connectionString) {
    sqlClient = neon(connectionString, {
      fullResults: true,
      fetchOptions: { priority: 'high' },
    });
    sqlConnectionString = connectionString;
  }
  return sqlClient;
}

async function query(env, text, params = []) {
  if (shouldAutoInitSchema(env)) {
    await ensureSchema(env);
  }
  return rawQuery(env, text, params);
}

async function rawQuery(env, text, params = []) {
  const sql = getSql(env);
  return withQueryRetry(() => sql.query(text, params, {
    fullResults: true,
    fetchOptions: { priority: 'high' },
  }));
}

function shouldAutoInitSchema(env) {
  const setting = String(env.AUTO_INIT_SCHEMA || '').toLowerCase();
  return setting === 'true' || (setting !== 'false' && env.ENVIRONMENT !== 'production');
}

async function withQueryRetry(runQuery, retries = 2) {
  let delay = 120;
  for (let attempt = 0; attempt <= retries; attempt += 1) {
    try {
      return await runQuery();
    } catch (error) {
      if (attempt === retries || !isTransientDbError(error)) throw error;
      await new Promise((resolve) => setTimeout(resolve, delay));
      delay *= 2;
    }
  }
  throw httpError('Database query failed.', 500);
}

function isTransientDbError(error) {
  const message = String(error?.message || error || '');
  return /timeout|network|fetch|connection|ECONNRESET|ETIMEDOUT|502|503|504/i.test(message);
}

async function ensureSchema(env) {
  if (schemaReady) return schemaReady;
  schemaReady = (async () => {
    const client = { query: (text, params = []) => rawQuery(env, text, params) };
    try {
      await client.query(`
        CREATE TABLE IF NOT EXISTS categories (
          id SERIAL PRIMARY KEY,
          name VARCHAR(255) NOT NULL UNIQUE,
          slug VARCHAR(255) NOT NULL UNIQUE,
          image_url TEXT,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
      `);
      await client.query(`
        CREATE TABLE IF NOT EXISTS products (
          id SERIAL PRIMARY KEY,
          category_id INTEGER REFERENCES categories(id) ON DELETE SET NULL,
          title VARCHAR(255) NOT NULL,
          description TEXT,
          price DECIMAL(10, 2) NOT NULL CHECK (price >= 0),
          sale_price DECIMAL(10, 2) CHECK (sale_price IS NULL OR sale_price >= 0),
          unit VARCHAR(50),
          stock_quantity INTEGER DEFAULT 0 CHECK (stock_quantity >= 0),
          is_available BOOLEAN DEFAULT TRUE,
          image_url TEXT,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
      `);
      await client.query(`
        CREATE TABLE IF NOT EXISTS users (
          id SERIAL PRIMARY KEY,
          name VARCHAR(255),
          email VARCHAR(255) UNIQUE,
          phone VARCHAR(50),
          is_verified BOOLEAN DEFAULT false,
          phone_number VARCHAR(50),
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
      `);
      await client.query(`
        DO $$
        BEGIN
          IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='password') THEN
            ALTER TABLE users ADD COLUMN password VARCHAR(255);
          END IF;
          IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='location') THEN
            ALTER TABLE users ADD COLUMN location VARCHAR(255);
          END IF;
          IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='phone_number') THEN
            ALTER TABLE users ALTER COLUMN phone_number DROP NOT NULL;
          END IF;
        END
        $$;
      `);
      await client.query(`CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email ON users(email);`);
      await client.query(`
        CREATE TABLE IF NOT EXISTS otps (
          id SERIAL PRIMARY KEY,
          email VARCHAR(255),
          phone_number VARCHAR(50),
          otp VARCHAR(128) NOT NULL,
          expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
      `);
      await client.query(`ALTER TABLE otps ALTER COLUMN otp TYPE VARCHAR(128);`);
      await client.query(`CREATE INDEX IF NOT EXISTS idx_otps_email ON otps(email);`);
      await client.query(`
        CREATE TABLE IF NOT EXISTS orders (
          id SERIAL PRIMARY KEY,
          user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
          delivery_address TEXT NOT NULL,
          total_amount DECIMAL(10, 2) NOT NULL CHECK (total_amount >= 0),
          payment_method VARCHAR(50) DEFAULT 'COD',
          status VARCHAR(50) DEFAULT 'Pending',
          items JSONB NOT NULL,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
      `);
      await client.query(`CREATE INDEX IF NOT EXISTS idx_products_category_id ON products(category_id);`);
      await client.query(`CREATE INDEX IF NOT EXISTS idx_products_title_gin ON products USING gin (to_tsvector('english', title));`);
      await seedDefaults(client);
    } catch (error) {
      schemaReady = undefined;
      throw error;
    }
  })();
  return schemaReady;
}

async function seedDefaults(client) {
  const count = await client.query('SELECT COUNT(*) FROM categories;');
  if (Number(count.rows[0].count) === 0) {
    await client.query(`
      INSERT INTO categories (name, slug, image_url) VALUES
      ('Fruits', 'fruits', 'https://images.unsplash.com/photo-1619546813926-a78fa6372cd2?auto=format&fit=crop&q=80&w=400'),
      ('Vegetables', 'vegetables', 'https://images.unsplash.com/photo-1566385101042-1a0aa0c1268c?auto=format&fit=crop&q=80&w=400'),
      ('Dairy & Eggs', 'dairy-eggs', 'https://images.unsplash.com/photo-1550583724-b2692b85b150?auto=format&fit=crop&q=80&w=400'),
      ('Bakery', 'bakery', 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&q=80&w=400'),
      ('Meat & Seafood', 'meat-seafood', 'https://images.unsplash.com/photo-1607623814075-e51df1bdc82f?auto=format&fit=crop&q=80&w=400'),
      ('Pantry Staples', 'pantry-staples', 'https://images.unsplash.com/photo-1549203396-abae8a36a77b?auto=format&fit=crop&q=80&w=400'),
      ('Beverages', 'beverages', 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?auto=format&fit=crop&q=80&w=400'),
      ('Snacks', 'snacks', 'https://images.unsplash.com/photo-1599490659213-e2b9527b0876?auto=format&fit=crop&q=80&w=400');
    `);
  }
}

function httpError(message, statusCode = 500) {
  const error = new Error(message);
  error.statusCode = statusCode;
  return error;
}

async function jsonBody(c) {
  try {
    return await c.req.json();
  } catch {
    return {};
  }
}

function normalizeEmail(email) {
  return String(email || '').trim().toLowerCase();
}

function isValidEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

function bytesToHex(bytes) {
  return [...bytes].map((byte) => byte.toString(16).padStart(2, '0')).join('');
}

function base64UrlEncode(input) {
  const bytes = input instanceof Uint8Array ? input : new TextEncoder().encode(String(input));
  let binary = '';
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/g, '');
}

function base64UrlDecode(input) {
  const padded = String(input).replace(/-/g, '+').replace(/_/g, '/').padEnd(Math.ceil(input.length / 4) * 4, '=');
  const binary = atob(padded);
  return Uint8Array.from(binary, (char) => char.charCodeAt(0));
}

async function sha256Hex(value) {
  const digest = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(String(value)));
  return bytesToHex(new Uint8Array(digest));
}

async function hashPassword(password) {
  const salt = crypto.getRandomValues(new Uint8Array(16));
  const keyMaterial = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(password),
    'PBKDF2',
    false,
    ['deriveBits'],
  );
  const bits = await crypto.subtle.deriveBits(
    { name: 'PBKDF2', salt, iterations: PASSWORD_ITERATIONS, hash: 'SHA-256' },
    keyMaterial,
    256,
  );
  return `pbkdf2$${PASSWORD_ITERATIONS}$${base64UrlEncode(salt)}$${base64UrlEncode(new Uint8Array(bits))}`;
}

async function verifyPassword(password, stored) {
  if (!stored) return false;
  if (!stored.startsWith('pbkdf2$')) {
    return (await sha256Hex(password)) === stored;
  }
  const [, iterationText, saltText, hashText] = stored.split('$');
  const iterations = Number(iterationText);
  const salt = base64UrlDecode(saltText);
  const expected = hashText;
  const keyMaterial = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(password),
    'PBKDF2',
    false,
    ['deriveBits'],
  );
  const bits = await crypto.subtle.deriveBits(
    { name: 'PBKDF2', salt, iterations, hash: 'SHA-256' },
    keyMaterial,
    256,
  );
  return base64UrlEncode(new Uint8Array(bits)) === expected;
}

function getJwtSecret(env) {
  if (!env.JWT_SECRET) {
    throw httpError('JWT_SECRET is required.', 500);
  }
  return env.JWT_SECRET;
}

async function signJwt(env, payload, ttlSeconds = JWT_TTL_SECONDS) {
  const header = { alg: 'HS256', typ: 'JWT' };
  const now = Math.floor(Date.now() / 1000);
  const body = { ...payload, iat: now, exp: now + ttlSeconds };
  const unsigned = `${base64UrlEncode(JSON.stringify(header))}.${base64UrlEncode(JSON.stringify(body))}`;
  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(getJwtSecret(env)),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const signature = await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(unsigned));
  return `${unsigned}.${base64UrlEncode(new Uint8Array(signature))}`;
}

async function verifyJwt(env, token) {
  const [header, payload, signature] = String(token || '').split('.');
  if (!header || !payload || !signature) throw httpError('Unauthorized - Token is invalid', 401);
  const unsigned = `${header}.${payload}`;
  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(getJwtSecret(env)),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['verify'],
  );
  const ok = await crypto.subtle.verify(
    'HMAC',
    key,
    base64UrlDecode(signature),
    new TextEncoder().encode(unsigned),
  );
  if (!ok) throw httpError('Unauthorized - Token verification failed', 401);
  const decoded = JSON.parse(new TextDecoder().decode(base64UrlDecode(payload)));
  if (decoded.exp && decoded.exp < Math.floor(Date.now() / 1000)) {
    throw httpError('Unauthorized - Token expired', 401);
  }
  return decoded;
}

async function authenticateUser(c, next) {
  const auth = c.req.header('Authorization') || '';
  if (!auth.startsWith('Bearer ')) throw httpError('Unauthorized - Token is missing', 401);
  c.set('user', await verifyJwt(c.env, auth.slice(7)));
  await next();
}

async function adminAuth(c, next) {
  const auth = c.req.header('Authorization') || '';
  const adminHeaderToken = c.req.header('X-Admin-Token') || '';
  const token = auth.startsWith('Bearer ') ? auth.slice(7) : adminHeaderToken;
  const apiKey = c.env.ADMIN_API_KEY;

  if (apiKey && token === apiKey) {
    await next();
    return;
  }

  try {
    const decoded = await verifyJwt(c.env, token);
    if (decoded.role === 'admin') {
      await next();
      return;
    }
  } catch {
    // Fall through to 401.
  }

  throw httpError('Unauthorized - Admin privileges required', 401);
}

function generateOtp() {
  const bytes = crypto.getRandomValues(new Uint8Array(4));
  const value = new DataView(bytes.buffer).getUint32(0) % 1000000;
  return String(value).padStart(6, '0');
}

async function storeOtp(env, email, otp) {
  const otpHash = await sha256Hex(otp);
  await query(env, 'DELETE FROM otps WHERE email = $1;', [email]);
  await query(
    env,
    `INSERT INTO otps (email, otp, expires_at)
     VALUES ($1, $2, NOW() + ($3 || ' minutes')::interval);`,
    [email, otpHash, OTP_TTL_MINUTES],
  );
}

async function sendOtp(env, email, otp, purpose) {
  const isSignup = purpose === 'signup';
  const subject = isSignup ? 'FreshCart email verification code' : 'FreshCart login code';
  const html = buildOtpEmailHtml(otp, isSignup);
  const text = `Your FreshCart verification code is ${otp}. It expires in ${OTP_TTL_MINUTES} minutes.`;
  const from = env.EMAIL_FROM || 'onboarding@resend.dev';

  if (env.EMAIL?.send) {
    await env.EMAIL.send({
      to: email,
      from: { email: from, name: 'FreshCart' },
      subject,
      html,
      text,
    });
    return;
  }

  if (env.RESEND_API_KEY) {
    const response = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${env.RESEND_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: `FreshCart <${from}>`,
        to: [email],
        subject,
        html,
        text,
      }),
    });
    if (!response.ok) {
      const errText = await response.text();
      console.error('[Resend Error]', errText);
      throw httpError(`Email provider rejected the OTP message. Resend error: ${errText}`, 502);
    }
    return;
  }

  if (env.LEGACY_EMAIL_BASE_URL) {
    const response = await fetch(`${String(env.LEGACY_EMAIL_BASE_URL).replace(/\/+$/, '')}/api/v1/auth/request-otp`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, purpose }),
    });
    if (response.ok) return;
    throw httpError('Legacy email endpoint rejected the OTP message.', 502);
  }

  if (env.OTP_DELIVERY_MODE === 'debug' || env.ENVIRONMENT !== 'production') {
    console.warn(`[OTP debug] ${email}: ${otp}`);
    return;
  }

  throw httpError('Email service is not configured for OTP delivery.', 503);
}

function buildOtpEmailHtml(otp, isSignup) {
  return `<!doctype html>
<html>
  <body style="margin:0;background:#f3f7f5;font-family:Arial,sans-serif;color:#10231b">
    <table width="100%" cellpadding="0" cellspacing="0" style="padding:32px 16px">
      <tr>
        <td align="center">
          <table width="100%" cellpadding="0" cellspacing="0" style="max-width:520px;background:#ffffff;border-radius:18px;overflow:hidden;border:1px solid #dbe7e0">
            <tr>
              <td style="background:linear-gradient(135deg,#047857,#10b981);padding:30px;text-align:center;color:white">
                <h1 style="margin:0;font-size:24px">FreshCart</h1>
                <p style="margin:8px 0 0;color:#d1fae5">Fresh groceries delivered fast</p>
              </td>
            </tr>
            <tr>
              <td style="padding:32px">
                <h2 style="margin:0 0 10px;font-size:20px">${isSignup ? 'Verify your email' : 'Your login code'}</h2>
                <p style="margin:0 0 20px;color:#51645b;line-height:1.6">Use this one-time password to continue. It expires in ${OTP_TTL_MINUTES} minutes.</p>
                <div style="background:#ecfdf5;border:1px solid #a7f3d0;border-radius:14px;padding:24px;text-align:center">
                  <div style="font-size:40px;font-weight:800;letter-spacing:10px;color:#047857;font-family:Consolas,monospace">${otp}</div>
                </div>
                <p style="margin:20px 0 0;color:#8a9a92;font-size:12px">If you did not request this code, you can ignore this email.</p>
              </td>
            </tr>
          </table>
        </td>
      </tr>
    </table>
  </body>
</html>`;
}

function userPayload(user) {
  return {
    id: user.id,
    name: user.name || '',
    email: user.email || '',
    phone: user.phone || user.phone_number || '',
    location: user.location || '',
    is_verified: Boolean(user.is_verified),
  };
}

async function issueUserToken(env, user) {
  return signJwt(env, {
    id: user.id,
    email: user.email,
    phoneNumber: user.phone || user.phone_number || '',
  });
}

function normalizeOrderStatus(status) {
  const statusText = String(status || '').trim();
  const legacyMap = {
    Shipped: 'Dispatched',
    Completed: 'Delivered',
  };
  return legacyMap[statusText] || statusText;
}

function parseItems(items) {
  if (Array.isArray(items)) return items;
  if (typeof items === 'string') {
    try {
      const parsed = JSON.parse(items);
      return Array.isArray(parsed) ? parsed : [];
    } catch {
      return [];
    }
  }
  return [];
}

function publicBaseUrl(c) {
  return c.env.PUBLIC_WORKER_URL || new URL(c.req.url).origin;
}

async function createUploadToken(env, payload) {
  return signJwt(env, { type: 'upload', ...payload }, 60 * 5);
}

async function verifyUploadToken(env, token, key) {
  const decoded = await verifyJwt(env, token);
  if (decoded.type !== 'upload' || decoded.key !== key) {
    throw httpError('Invalid upload token.', 401);
  }
  return decoded;
}

app.get('/', (c) => c.json({
  status: 'active',
  message: 'FreshCart Grocery Delivery Backend API is running successfully.',
  environment: c.env.ENVIRONMENT || 'production',
  version: '1.0.0',
  endpoints: {
    health: '/api/health',
    dbHealth: '/api/health/db'
  }
}));

// Health
app.get('/api/health', (c) => c.json({
  status: 'UP',
  runtime: 'Cloudflare Workers',
  timestamp: new Date().toISOString(),
}));

app.get('/api/health/db', async (c) => {
  const start = Date.now();
  const result = await rawQuery(c.env, 'SELECT NOW();');
  return c.json({
    status: 'UP',
    database: c.env.HYPERDRIVE ? 'PostgreSQL via Hyperdrive' : 'PostgreSQL',
    connection: 'Healthy',
    latency: `${Date.now() - start}ms`,
    dbTime: result.rows[0].now,
  });
});

// Auth
app.post('/api/v1/auth/signup', async (c) => {
  const body = await jsonBody(c);
  const email = normalizeEmail(body.email);
  if (!body.name || !email || !body.password) {
    throw httpError('Name, email, and password are required.', 400);
  }
  if (!isValidEmail(email)) throw httpError('Please provide a valid email address.', 400);

  const existing = await query(c.env, 'SELECT id, is_verified FROM users WHERE email = $1', [email]);
  if (existing.rows.length > 0 && existing.rows[0].is_verified) {
    throw httpError('An account with this email already exists. Please log in instead.', 409);
  }

  const passwordHash = await hashPassword(body.password);
  await query(
    c.env,
    `INSERT INTO users (name, email, phone, phone_number, location, password, is_verified)
     VALUES ($1, $2, $3, $3, $4, $5, false)
     ON CONFLICT (email)
     DO UPDATE SET name = EXCLUDED.name, phone = EXCLUDED.phone, phone_number = EXCLUDED.phone_number,
       location = EXCLUDED.location, password = EXCLUDED.password, is_verified = false
     RETURNING *;`,
    [String(body.name).trim(), email, body.phone || null, body.location || null, passwordHash],
  );

  const otp = generateOtp();
  await storeOtp(c.env, email, otp);
  await sendOtp(c.env, email, otp, 'signup');

  return c.json({
    success: true,
    requiresOtp: true,
    email,
    message: 'Verification code sent to your email.',
    ...(c.env.OTP_DELIVERY_MODE === 'debug' ? { debugOtp: otp } : {}),
  });
});

app.post('/api/v1/auth/login', async (c) => {
  const body = await jsonBody(c);
  const email = normalizeEmail(body.email);
  if (!email || !body.password) throw httpError('Email address and password are required.', 400);

  const userRes = await query(c.env, 'SELECT * FROM users WHERE email = $1', [email]);
  if (userRes.rows.length === 0) throw httpError('No account found with this email. Please sign up first.', 404);
  const user = userRes.rows[0];
  const passwordOk = await verifyPassword(body.password, user.password);
  if (!passwordOk) throw httpError('Incorrect password. Please try again.', 401);

  if (user.password && !user.password.startsWith('pbkdf2$')) {
    await query(c.env, 'UPDATE users SET password = $1 WHERE id = $2', [await hashPassword(body.password), user.id]);
  }

  const otp = generateOtp();
  await storeOtp(c.env, email, otp);
  await sendOtp(c.env, email, otp, 'login');

  return c.json({
    success: true,
    requiresOtp: true,
    email,
    message: 'Login code sent to your email.',
    ...(c.env.OTP_DELIVERY_MODE === 'debug' ? { debugOtp: otp } : {}),
  });
});

app.post('/api/v1/auth/request-otp', async (c) => {
  const body = await jsonBody(c);
  const email = normalizeEmail(body.email || body.phoneNumber);
  if (!email || !isValidEmail(email)) throw httpError('A valid email is required.', 400);
  const userRes = await query(c.env, 'SELECT id FROM users WHERE email = $1', [email]);
  if (userRes.rows.length === 0) throw httpError('No account found with this email.', 404);
  const otp = generateOtp();
  await storeOtp(c.env, email, otp);
  await sendOtp(c.env, email, otp, body.purpose || 'login');
  return c.json({
    success: true,
    email,
    message: 'A fresh verification code has been sent.',
    ...(c.env.OTP_DELIVERY_MODE === 'debug' ? { debugOtp: otp } : {}),
  });
});

app.post('/api/v1/auth/verify-otp', async (c) => {
  const body = await jsonBody(c);
  const email = normalizeEmail(body.email);
  const otp = String(body.otp || '').trim();
  if (!email || !otp) throw httpError('Email and OTP are required.', 400);

  const otpHash = await sha256Hex(otp);
  const otpRes = await query(
    c.env,
    `SELECT id FROM otps
     WHERE email = $1 AND (otp = $2 OR otp = $3) AND expires_at > NOW()
     ORDER BY created_at DESC LIMIT 1;`,
    [email, otpHash, otp],
  );
  if (otpRes.rows.length === 0) throw httpError('Invalid or expired OTP code.', 401);

  await query(c.env, 'DELETE FROM otps WHERE email = $1;', [email]);
  const userRes = await query(
    c.env,
    'UPDATE users SET is_verified = true WHERE email = $1 RETURNING *;',
    [email],
  );
  if (userRes.rows.length === 0) throw httpError('User not found.', 404);
  const user = userRes.rows[0];
  const token = await issueUserToken(c.env, user);
  return c.json({
    success: true,
    message: 'OTP verified successfully.',
    token,
    user: userPayload(user),
  });
});

app.put('/api/v1/auth/profile', authenticateUser, async (c) => {
  const body = await jsonBody(c);
  const user = c.get('user');
  const updateRes = await query(
    c.env,
    `UPDATE users
     SET name = COALESCE($1, name),
         phone = COALESCE($2, phone),
         phone_number = COALESCE($2, phone_number),
         location = COALESCE($3, location)
     WHERE id = $4
     RETURNING *;`,
    [
      body.name ? String(body.name).trim() : null,
      body.phone ? String(body.phone).trim() : null,
      body.location ? String(body.location).trim() : null,
      user.id,
    ],
  );
  if (updateRes.rows.length === 0) throw httpError('User not found.', 404);
  return c.json({ success: true, message: 'Profile updated successfully.', user: userPayload(updateRes.rows[0]) });
});

// Admin auth
app.post('/api/v1/admin/auth/login', async (c) => {
  const body = await jsonBody(c);
  const expected = c.env.ADMIN_PASSWORD || c.env.ADMIN_API_KEY;
  if (!expected) throw httpError('ADMIN_PASSWORD or ADMIN_API_KEY is required.', 500);
  if (body.password !== expected) throw httpError('Invalid admin password.', 401);
  const token = await signJwt(c.env, { role: 'admin' }, ADMIN_JWT_TTL_SECONDS);
  return c.json({ success: true, token, expiresIn: ADMIN_JWT_TTL_SECONDS });
});

app.post('/api/v1/admin/system/init-db', adminAuth, async (c) => {
  await ensureSchema(c.env);
  return c.json({
    success: true,
    message: 'Database schema is ready.',
  });
});

// Categories
app.get('/api/v1/categories', async (c) => {
  const cached = await getCachedResponse(c);
  if (cached) return cached;

  const result = await query(c.env, 'SELECT * FROM categories ORDER BY name ASC;');
  const res = c.json({ success: true, data: result.rows });
  await setCachedResponse(c, res);
  return res;
});

app.post('/api/v1/admin/categories', adminAuth, async (c) => {
  const body = await jsonBody(c);
  if (!body.name || !body.slug) throw httpError('Category name and slug are required', 400);
  const result = await query(
    c.env,
    'INSERT INTO categories (name, slug, image_url) VALUES ($1, $2, $3) RETURNING *;',
    [body.name, body.slug, body.image_url || null],
  );
  await purgeCacheKeys(c, ['/api/v1/categories']);
  return c.json({ success: true, message: 'Category created successfully.', data: result.rows[0] }, 201);
});

app.put('/api/v1/admin/categories/:id', adminAuth, async (c) => {
  const body = await jsonBody(c);
  if (!body.name || !body.slug) throw httpError('Category name and slug are required', 400);
  const result = await query(
    c.env,
    'UPDATE categories SET name = $1, slug = $2, image_url = $3 WHERE id = $4 RETURNING *;',
    [body.name, body.slug, body.image_url || null, c.req.param('id')],
  );
  if (result.rowCount === 0) throw httpError('Category not found', 404);
  await purgeCacheKeys(c, ['/api/v1/categories']);
  return c.json({ success: true, message: 'Category updated successfully.', data: result.rows[0] });
});

app.delete('/api/v1/admin/categories/:id', adminAuth, async (c) => {
  const result = await query(c.env, 'DELETE FROM categories WHERE id = $1 RETURNING *;', [c.req.param('id')]);
  if (result.rowCount === 0) throw httpError('Category not found', 404);
  await purgeCacheKeys(c, ['/api/v1/categories']);
  return c.json({ success: true, message: 'Category deleted successfully.', data: result.rows[0] });
});

// Products
app.get('/api/v1/products', async (c) => {
  const cached = await getCachedResponse(c);
  if (cached) return cached;

  const pageNum = Math.max(1, parseInt(c.req.query('page') || '1', 10) || 1);
  const limitNum = Math.min(100, Math.max(1, parseInt(c.req.query('limit') || '20', 10) || 20));
  const offset = (pageNum - 1) * limitNum;
  const conditions = [];
  const params = [];
  const categoryId = c.req.query('category_id');
  const search = c.req.query('search');

  if (categoryId) {
    params.push(parseInt(categoryId, 10));
    conditions.push(`p.category_id = $${params.length}`);
  }
  if (search?.trim()) {
    params.push(search.trim());
    conditions.push(`to_tsvector('english', p.title) @@ plainto_tsquery('english', $${params.length})`);
  }
  const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';
  const count = await query(c.env, `SELECT COUNT(*) FROM products p ${where};`, params);
  const totalItems = Number(count.rows[0].count);
  const itemParams = [...params, limitNum, offset];
  const result = await query(
    c.env,
    `SELECT p.*, c.name as category_name
     FROM products p
     LEFT JOIN categories c ON p.category_id = c.id
     ${where}
     ORDER BY p.created_at DESC
     LIMIT $${itemParams.length - 1} OFFSET $${itemParams.length};`,
    itemParams,
  );
  const res = c.json({
    success: true,
    pagination: {
      totalItems,
      totalPages: Math.ceil(totalItems / limitNum),
      page: pageNum,
      limit: limitNum,
    },
    data: result.rows,
  });
  await setCachedResponse(c, res);
  return res;
});

app.get('/api/v1/products/:id', async (c) => {
  const result = await query(
    c.env,
    `SELECT p.*, c.name as category_name
     FROM products p
     LEFT JOIN categories c ON p.category_id = c.id
     WHERE p.id = $1;`,
    [c.req.param('id')],
  );
  if (result.rowCount === 0) throw httpError('Product not found', 404);
  return c.json({ success: true, data: result.rows[0] });
});

app.post('/api/v1/admin/products', adminAuth, async (c) => {
  const body = await jsonBody(c);
  if (!body.title || body.price === undefined) throw httpError('Product title and price are required', 400);
  const result = await query(
    c.env,
    `INSERT INTO products (category_id, title, description, price, sale_price, unit, stock_quantity, is_available, image_url)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
     RETURNING *;`,
    [
      body.category_id || null,
      body.title,
      body.description || null,
      body.price,
      body.sale_price !== undefined ? body.sale_price : null,
      body.unit || null,
      body.stock_quantity !== undefined ? body.stock_quantity : 0,
      body.is_available !== undefined ? body.is_available : true,
      body.image_url || null,
    ],
  );
  await purgeCacheKeys(c, ['/api/v1/products']);
  return c.json({ success: true, message: 'Product created successfully.', data: result.rows[0] }, 201);
});

app.put('/api/v1/admin/products/:id', adminAuth, async (c) => {
  const body = await jsonBody(c);
  if (!body.title || body.price === undefined) throw httpError('Product title and price are required', 400);
  const result = await query(
    c.env,
    `UPDATE products
     SET category_id = $1, title = $2, description = $3, price = $4, sale_price = $5,
       unit = $6, stock_quantity = $7, is_available = $8, image_url = $9
     WHERE id = $10
     RETURNING *;`,
    [
      body.category_id || null,
      body.title,
      body.description || null,
      body.price,
      body.sale_price !== undefined ? body.sale_price : null,
      body.unit || null,
      body.stock_quantity !== undefined ? body.stock_quantity : 0,
      body.is_available !== undefined ? body.is_available : true,
      body.image_url || null,
      c.req.param('id'),
    ],
  );
  if (result.rowCount === 0) throw httpError('Product not found', 404);
  await purgeCacheKeys(c, ['/api/v1/products']);
  return c.json({ success: true, message: 'Product updated successfully.', data: result.rows[0] });
});

app.delete('/api/v1/admin/products/:id', adminAuth, async (c) => {
  const result = await query(c.env, 'DELETE FROM products WHERE id = $1 RETURNING *;', [c.req.param('id')]);
  if (result.rowCount === 0) throw httpError('Product not found', 404);
  await purgeCacheKeys(c, ['/api/v1/products']);
  return c.json({ success: true, message: 'Product deleted successfully.', data: result.rows[0] });
});

app.post('/api/v1/admin/products/presign', adminAuth, async (c) => {
  const body = await jsonBody(c);
  if (!body.filename || !body.contentType) throw httpError('filename and contentType are required in request body', 400);
  const allowed = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp', 'image/svg+xml'];
  const contentType = String(body.contentType).toLowerCase();
  if (!allowed.includes(contentType)) throw httpError(`Invalid contentType "${contentType}". Only image uploads are allowed.`, 400);
  const cleanBase = String(body.filename).replace(/[^a-zA-Z0-9._-]/g, '_');
  const key = `products/${Date.now()}-${cleanBase}`;
  const uploadToken = await createUploadToken(c.env, { key, contentType });
  const uploadUrl = `${publicBaseUrl(c)}/api/v1/admin/products/upload/${encodeURIComponent(key)}?token=${uploadToken}`;
  const downloadUrl = c.env.R2_PUBLIC_URL
    ? `${String(c.env.R2_PUBLIC_URL).replace(/\/+$/, '')}/${key}`
    : uploadUrl.replace('/api/v1/admin/products/upload/', '/api/v1/assets/');
  return c.json({
    success: true,
    message: 'Upload URL generated successfully.',
    data: { key, uploadUrl, downloadUrl, expiresIn: '300 seconds' },
  });
});

app.put('/api/v1/admin/products/upload/:key{.+}', async (c) => {
  const key = decodeURIComponent(c.req.param('key'));
  const token = c.req.query('token');
  const upload = await verifyUploadToken(c.env, token, key);
  if (!c.env.R2_BUCKET?.put) throw httpError('R2_BUCKET binding is not configured.', 503);
  await c.env.R2_BUCKET.put(key, c.req.raw.body, {
    httpMetadata: { contentType: upload.contentType || c.req.header('Content-Type') || 'application/octet-stream' },
  });
  return c.json({ success: true, key });
});

app.get('/api/v1/assets/:key{.+}', async (c) => {
  if (!c.env.R2_BUCKET?.get) throw httpError('R2_BUCKET binding is not configured.', 503);
  const key = decodeURIComponent(c.req.param('key'));
  const object = await c.env.R2_BUCKET.get(key);
  if (!object) throw httpError('Asset not found', 404);
  return new Response(object.body, {
    headers: {
      'Content-Type': object.httpMetadata?.contentType || 'application/octet-stream',
      'Cache-Control': 'public, max-age=31536000, immutable',
    },
  });
});

// Orders
app.post('/api/v1/orders', authenticateUser, async (c) => {
  const body = await jsonBody(c);
  const user = c.get('user');
  if (!body.items || !body.delivery_address || body.total_amount === undefined) {
    throw httpError('Items, delivery address, and total amount are required.', 400);
  }
  const result = await query(
    c.env,
    `INSERT INTO orders (user_id, delivery_address, total_amount, payment_method, items, status)
     VALUES ($1, $2, $3, $4, $5, $6)
     RETURNING *;`,
    [user.id, body.delivery_address, body.total_amount, body.payment_method || 'COD', JSON.stringify(body.items), 'Pending'],
  );
  return c.json({ success: true, message: 'Order placed successfully.', data: result.rows[0] }, 201);
});

app.get('/api/v1/orders/history', authenticateUser, async (c) => {
  const user = c.get('user');
  const result = await query(c.env, 'SELECT * FROM orders WHERE user_id = $1 ORDER BY created_at DESC;', [user.id]);
  return c.json({ success: true, data: result.rows });
});

app.get('/api/v1/orders/:id', authenticateUser, async (c) => {
  const user = c.get('user');
  const result = await query(c.env, 'SELECT * FROM orders WHERE id = $1 AND user_id = $2;', [c.req.param('id'), user.id]);
  if (result.rows.length === 0) throw httpError('Order not found.', 404);
  return c.json({ success: true, data: result.rows[0] });
});

app.get('/api/v1/admin/orders', adminAuth, async (c) => {
  const result = await query(
    c.env,
    `SELECT o.id, o.delivery_address, o.total_amount, o.payment_method, o.status, o.items, o.created_at,
       u.name AS customer_name, u.email AS customer_email
     FROM orders o
     LEFT JOIN users u ON o.user_id = u.id
     ORDER BY o.created_at DESC;`,
  );
  return c.json({
    success: true,
    data: result.rows.map((row) => {
      const items = parseItems(row.items);
      return {
        id: row.id,
        customerName: row.customer_name || 'Anonymous',
        email: row.customer_email || 'N/A',
        itemsCount: items.length,
        totalAmount: parseFloat(row.total_amount),
        status: normalizeOrderStatus(row.status),
        date: new Date(row.created_at).toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' }),
        paymentMethod: row.payment_method,
        deliveryAddress: row.delivery_address,
        delivery_address: row.delivery_address,
        items,
        created_at: row.created_at,
      };
    }),
  });
});

app.put('/api/v1/admin/orders/:id', adminAuth, async (c) => {
  const body = await jsonBody(c);
  const status = normalizeOrderStatus(body.status);
  if (!ORDER_STATUSES.includes(status)) throw httpError('Invalid order status.', 400);
  const result = await query(c.env, 'UPDATE orders SET status = $1 WHERE id = $2 RETURNING *;', [status, c.req.param('id')]);
  if (result.rows.length === 0) throw httpError('Order not found.', 404);
  return c.json({ success: true, message: 'Order status updated successfully.', data: result.rows[0] });
});

// Admin users
app.get('/api/v1/admin/users', adminAuth, async (c) => {
  const page = Math.max(1, parseInt(c.req.query('page') || '1', 10) || 1);
  const limit = Math.min(100, Math.max(1, parseInt(c.req.query('limit') || '20', 10) || 20));
  const offset = (page - 1) * limit;
  const count = await query(c.env, 'SELECT COUNT(*) FROM users WHERE is_verified = true;');
  const total = Number(count.rows[0].count);
  const users = await query(
    c.env,
    `SELECT id, name, email, COALESCE(phone, phone_number) AS phone, is_verified, created_at
     FROM users
     WHERE is_verified = true
     ORDER BY created_at DESC
     LIMIT $1 OFFSET $2;`,
    [limit, offset],
  );
  const totalPages = Math.ceil(total / limit);
  return c.json({
    success: true,
    data: {
      users: users.rows.map((user) => ({
        id: user.id,
        name: user.name || 'N/A',
        email: user.email || 'N/A',
        phone: user.phone || 'N/A',
        joining_date: new Date(user.created_at).toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' }),
        is_verified: user.is_verified,
      })),
      pagination: { page, limit, total, total_pages: totalPages, has_next: page < totalPages, has_prev: page > 1 },
    },
  });
});

app.put('/api/v1/admin/users/:id', adminAuth, async (c) => {
  const body = await jsonBody(c);
  if (!body.name || !body.email) throw httpError('Name and email are required fields.', 400);
  const email = normalizeEmail(body.email);
  const conflict = await query(c.env, 'SELECT id FROM users WHERE email = $1 AND id != $2;', [email, c.req.param('id')]);
  if (conflict.rows.length > 0) throw httpError('This email is already in use by another customer.', 409);
  const result = await query(
    c.env,
    'UPDATE users SET name = $1, email = $2, phone = $3, phone_number = $3 WHERE id = $4 RETURNING *;',
    [String(body.name).trim(), email, body.phone ? String(body.phone).trim() : null, c.req.param('id')],
  );
  if (result.rows.length === 0) throw httpError('Customer not found.', 404);
  return c.json({ success: true, message: 'Customer details updated successfully.', user: userPayload(result.rows[0]) });
});

app.delete('/api/v1/admin/users/:id', adminAuth, async (c) => {
  const result = await query(c.env, 'DELETE FROM users WHERE id = $1 RETURNING *;', [c.req.param('id')]);
  if (result.rows.length === 0) throw httpError('Customer not found.', 404);
  return c.json({ success: true, message: 'Customer account successfully deleted.' });
});

export default app;
