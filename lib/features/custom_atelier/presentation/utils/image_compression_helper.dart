import 'package:image_picker/image_picker.dart';

class ImageCompressionHelper {
  static final ImagePicker _picker = ImagePicker();

  /// Picks and compresses images client-side before upload to Storage
  static Future<List<XFile>> pickAndCompressImages({
    int maxWidth = 1600,
    int maxHeight = 1600,
    int imageQuality = 85,
  }) async {
    try {
      final List<XFile> picked = await _picker.pickMultiImage(
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: imageQuality,
      );
      return picked;
    } catch (_) {
      return [];
    }
  }

  /// Single image capture/pick with client-side compression
  static Future<XFile?> pickSingleCompressedImage({
    ImageSource source = ImageSource.gallery,
    int maxWidth = 1600,
    int maxHeight = 1600,
    int imageQuality = 85,
  }) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: imageQuality,
      );
      return file;
    } catch (_) {
      return null;
    }
  }
}
