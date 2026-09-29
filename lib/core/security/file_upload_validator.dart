/// File upload validator for Ochanya Gili media & inspiration assets.
/// Enforces size boundaries, extension whitelist, and MIME verification.
class FileValidationResult {
  final bool isValid;
  final String? errorMessage;

  const FileValidationResult({required this.isValid, this.errorMessage});

  static const valid = FileValidationResult(isValid: true);

  factory FileValidationResult.invalid(String message) =>
      FileValidationResult(isValid: false, errorMessage: message);
}

class FileUploadValidator {
  static const int maxImageSizeBytes = 10 * 1024 * 1024; // 10MB
  static const int maxDocumentSizeBytes = 20 * 1024 * 1024; // 20MB

  static const Set<String> allowedImageExtensions = {
    'jpg',
    'jpeg',
    'png',
    'webp',
  };

  static const Set<String> allowedDocumentExtensions = {
    'pdf',
    'jpg',
    'jpeg',
    'png',
    'webp',
  };

  /// Validates an image file before upload to Supabase Storage.
  static FileValidationResult validateImage({
    required String fileName,
    required int byteLength,
    String? mimeType,
  }) {
    if (byteLength <= 0) {
      return FileValidationResult.invalid('The selected file is empty.');
    }

    if (byteLength > maxImageSizeBytes) {
      return FileValidationResult.invalid(
        'File size (${(byteLength / (1024 * 1024)).toStringAsFixed(1)}MB) exceeds the 10MB limit.',
      );
    }

    final parts = fileName.split('.');
    if (parts.length < 2) {
      return FileValidationResult.invalid('File has no extension.');
    }

    final ext = parts.last.toLowerCase();
    if (!allowedImageExtensions.contains(ext)) {
      return FileValidationResult.invalid(
        'Unsupported image extension ($ext). Allowed: JPG, PNG, WebP.',
      );
    }

    if (mimeType != null && mimeType.isNotEmpty) {
      final cleanMime = mimeType.toLowerCase();
      if (!cleanMime.startsWith('image/')) {
        return FileValidationResult.invalid(
          'MIME type ($mimeType) does not match a valid image file.',
        );
      }
    }

    return FileValidationResult.valid;
  }
}
