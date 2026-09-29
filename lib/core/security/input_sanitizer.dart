/// Input sanitizer for the Ochanya Gili platform.
/// Defends against XSS, script injections, and HTML tags in customer inputs.
class InputSanitizer {
  static final RegExp _scriptTagRegex = RegExp(
    r'<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>',
    multiLine: true,
    caseSensitive: false,
  );

  static final RegExp _htmlTagRegex = RegExp(
    r'<[^>]*>',
    multiLine: true,
    caseSensitive: false,
  );

  static final RegExp _javascriptUriRegex = RegExp(
    r'javascript:\s*',
    caseSensitive: false,
  );

  static final RegExp _eventHandlerRegex = RegExp(
    r'\bon\w+\s*=',
    caseSensitive: false,
  );

  /// Strips HTML tags, script blocks, event handlers, and javascript URIs.
  static String sanitize(String? input) {
    if (input == null || input.isEmpty) return '';
    var sanitized = input.replaceAll(_scriptTagRegex, '');
    sanitized = sanitized.replaceAll(_htmlTagRegex, '');
    sanitized = sanitized.replaceAll(_javascriptUriRegex, '');
    sanitized = sanitized.replaceAll(_eventHandlerRegex, '');
    return sanitized.trim();
  }

  /// Sanitizes multiline notes and descriptions while preserving intended newlines.
  static String sanitizeNotes(String? notes) {
    if (notes == null || notes.isEmpty) return '';
    final lines = notes.split('\n');
    return lines.map((l) => sanitize(l)).join('\n').trim();
  }
}
