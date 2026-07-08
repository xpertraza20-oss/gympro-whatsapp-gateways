const { PutObjectCommand } = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');
const { s3Client, bucketName, publicUrl } = require('../config/r2');
const path = require('path');

/**
 * Generates a presigned PUT URL for secure, direct upload to Cloudflare R2.
 * Returns both the client upload endpoint (valid for 5 minutes) and the final public download asset path.
 */
const generatePresignedUrl = async (req, res, next) => {
  try {
    const { filename, contentType } = req.body;

    // 1. Basic payload validations
    if (!filename || !contentType) {
      const error = new Error('filename and contentType are required in request body');
      error.statusCode = 400;
      return next(error);
    }

    // 2. Content-type limit validation (restrict to image extensions)
    const allowedContentTypes = [
      'image/jpeg',
      'image/jpg',
      'image/png',
      'image/gif',
      'image/webp',
      'image/svg+xml'
    ];

    if (!allowedContentTypes.includes(contentType.toLowerCase())) {
      const error = new Error(`Invalid contentType "${contentType}". Only image uploads are allowed.`);
      error.statusCode = 400;
      return next(error);
    }

    // 3. Generate a unique name collision-free key
    const fileExtension = path.extname(filename);
    const baseName = path.basename(filename, fileExtension).replace(/[^a-zA-Z0-9]/g, '_');
    const uniqueKey = `products/${Date.now()}-${baseName}${fileExtension}`;

    // 4. Create PutObjectCommand
    const command = new PutObjectCommand({
      Bucket: bucketName,
      Key: uniqueKey,
      ContentType: contentType
    });

    // 5. Generate secure cryptographically signed URL
    let uploadUrl;
    try {
      // Valid for 5 minutes (300 seconds)
      uploadUrl = await getSignedUrl(s3Client, command, { expiresIn: 300 });
    } catch (s3Error) {
      console.error('Failed to communicate with Cloudflare R2 service:', s3Error);
      
      const storageError = new Error('Cloud storage communication failed. Check your R2 settings.');
      storageError.statusCode = 502; // Bad Gateway
      storageError.details = s3Error.message;
      return next(storageError);
    }

    // 6. Build the public asset retrieval URL
    const cleanPublicUrlBase = publicUrl.endsWith('/') ? publicUrl.slice(0, -1) : publicUrl;
    const downloadUrl = `${cleanPublicUrlBase}/${uniqueKey}`;

    res.status(200).json({
      success: true,
      message: 'Presigned upload URL generated successfully.',
      data: {
        key: uniqueKey,
        uploadUrl,
        downloadUrl,
        expiresIn: '300 seconds'
      }
    });
  } catch (err) {
    next(err);
  }
};

module.exports = {
  generatePresignedUrl
};
