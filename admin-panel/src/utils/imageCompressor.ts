export interface CompressionResult {
  compressedFile: File;
  originalSize: number;
  compressedSize: number;
  originalWidth: number;
  originalHeight: number;
  compressedWidth: number;
  compressedHeight: number;
  qualityUsed: number;
  iterations: number;
}

/**
 * Compresses an image file in the browser, converting it to .webp format and ensuring it is under 150KB.
 * It iteratively reduces the quality and scales down the image if necessary.
 */
export async function compressImageToWebP(
  file: File,
  maxSizeKB: number = 150,
  maxDimensions: number = 1200
): Promise<CompressionResult> {
  const originalSize = file.size;
  const targetSizeBytes = maxSizeKB * 1024;

  // Load the file as an Image object
  const image = await new Promise<HTMLImageElement>((resolve, reject) => {
    const img = new Image();
    img.onload = () => resolve(img);
    img.onerror = (err) => reject(err);
    img.src = URL.createObjectURL(file);
  });

  const originalWidth = image.width;
  const originalHeight = image.height;

  // Initial scaling calculation
  let scale = 1.0;
  if (originalWidth > maxDimensions || originalHeight > maxDimensions) {
    scale = maxDimensions / Math.max(originalWidth, originalHeight);
  }

  let width = Math.round(originalWidth * scale);
  let height = Math.round(originalHeight * scale);

  const canvas = document.createElement("canvas");
  const ctx = canvas.getContext("2d");
  if (!ctx) {
    throw new Error("Could not get 2D context from canvas");
  }

  let quality = 0.85;
  let iterations = 0;
  let compressedBlob: Blob | null = null;

  // Loop to reduce quality and scale until size is within threshold
  while (iterations < 10) {
    iterations++;
    canvas.width = width;
    canvas.height = height;

    // Clear canvas and draw
    ctx.clearRect(0, 0, width, height);
    ctx.drawImage(image, 0, 0, width, height);

    compressedBlob = await new Promise<Blob | null>((resolve) => {
      canvas.toBlob((blob) => resolve(blob), "image/webp", quality);
    });

    if (!compressedBlob) {
      throw new Error("Canvas encoding failed");
    }

    if (compressedBlob.size <= targetSizeBytes) {
      break; // Successfully compressed under target size!
    }

    // Decimate quality first
    if (quality > 0.3) {
      quality -= 0.15;
    } else {
      // If quality is already low, start shrinking the dimensions
      width = Math.round(width * 0.8);
      height = Math.round(height * 0.8);
      quality = 0.5; // Reset quality slightly for the smaller dimensions
    }
  }

  if (!compressedBlob) {
    throw new Error("Image compression failed");
  }

  // Create a new File from the blob
  const originalNameWithoutExt = file.name.substring(0, file.name.lastIndexOf('.')) || file.name;
  const compressedName = `${originalNameWithoutExt}.webp`;
  
  const compressedFile = new File([compressedBlob], compressedName, {
    type: "image/webp",
    lastModified: Date.now(),
  });

  // Clean up Object URL
  URL.revokeObjectURL(image.src);

  return {
    compressedFile,
    originalSize,
    compressedSize: compressedFile.size,
    originalWidth,
    originalHeight,
    compressedWidth: width,
    compressedHeight: height,
    qualityUsed: Number(quality.toFixed(2)),
    iterations,
  };
}
