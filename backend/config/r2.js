const { S3Client } = require('@aws-sdk/client-s3');

const {
  R2_ACCOUNT_ID,
  R2_ACCESS_KEY_ID,
  R2_SECRET_ACCESS_KEY,
  R2_BUCKET_NAME,
  R2_PUBLIC_URL,
  R2_PUBLIC_BASE_URL
} = process.env;

const missingVars = [];
if (!R2_ACCOUNT_ID) missingVars.push('R2_ACCOUNT_ID');
if (!R2_ACCESS_KEY_ID) missingVars.push('R2_ACCESS_KEY_ID');
if (!R2_SECRET_ACCESS_KEY) missingVars.push('R2_SECRET_ACCESS_KEY');
if (!R2_BUCKET_NAME) missingVars.push('R2_BUCKET_NAME');

if (missingVars.length > 0) {
  const errMsg = `Cloudflare R2 storage integration is missing configuration variables: ${missingVars.join(', ')}`;
  if (process.env.NODE_ENV === 'production') {
    throw new Error(errMsg);
  } else {
    console.warn(`⚠️ [R2 Config Warning]: ${errMsg}. File uploads will fail.`);
  }
}

// Set up the S3 compatible client for Cloudflare R2
const s3Client = new S3Client({
  region: 'auto', // Cloudflare R2 does not require a specific region, 'auto' is recommended
  endpoint: `https://${R2_ACCOUNT_ID || 'dummy'}.r2.cloudflarestorage.com`,
  credentials: {
    accessKeyId: R2_ACCESS_KEY_ID || 'dummy',
    secretAccessKey: R2_SECRET_ACCESS_KEY || 'dummy'
  },
  // Ensure signature is v4 for R2 compatibility
  signatureVersion: 'v4'
});

module.exports = {
  s3Client,
  bucketName: R2_BUCKET_NAME,
  publicUrl: R2_PUBLIC_URL || R2_PUBLIC_BASE_URL || (R2_ACCOUNT_ID && R2_BUCKET_NAME ? `https://${R2_ACCOUNT_ID}.r2.cloudflarestorage.com/${R2_BUCKET_NAME}` : '')
};
