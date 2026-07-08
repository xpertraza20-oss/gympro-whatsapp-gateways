const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

const healthRoutes = require('./routes/healthRoutes');
const categoryRoutes = require('./routes/categoryRoutes');
const productRoutes = require('./routes/productRoutes');
const authRoutes = require('./routes/authRoutes');
const orderRoutes = require('./routes/orderRoutes');
const errorHandler = require('./middlewares/errorHandler');

const app = express();

// 1. Security Middlewares
app.use(helmet({
  crossOriginResourcePolicy: { policy: 'cross-origin' }
}));

const ALLOWED_ORIGINS = [
  'https://grocery-admin-644.pages.dev',
  'http://localhost:5173',
  'http://localhost:3000',
  ...(process.env.CORS_ORIGINS ? process.env.CORS_ORIGINS.split(',').map(s => s.trim()) : [])
];

app.use(cors({
  origin: (origin, callback) => {
    // Allow requests with no origin (like mobile apps, Postman, curl)
    if (!origin) return callback(null, true);
    // Allow if in list or if *.pages.dev
    if (ALLOWED_ORIGINS.includes(origin) || /\.pages\.dev$/.test(origin)) {
      return callback(null, true);
    }
    return callback(null, false);
  },
  credentials: true
}));

// 2. Logging Middleware
if (process.env.NODE_ENV !== 'test') {
  app.use(morgan(process.env.NODE_ENV === 'production' ? 'combined' : 'dev'));
}

// 3. Body Parsing Middlewares
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// 4. API Routes
app.use('/api/health', healthRoutes);
app.use('/api/v1/categories', categoryRoutes.publicRouter);
app.use('/api/v1/admin/categories', categoryRoutes.adminRouter);
app.use('/api/v1/products', productRoutes.publicRouter);
app.use('/api/v1/admin/products', productRoutes.adminRouter);
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/orders', orderRoutes);

// 5. Catch 404 and forward to error handler
app.use((req, res, next) => {
  const error = new Error(`Not Found - ${req.originalUrl}`);
  error.statusCode = 404;
  next(error);
});

// 6. Global Error Handler
app.use(errorHandler);

module.exports = app;
