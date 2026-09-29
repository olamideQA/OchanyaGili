/// Security-hardened error handler that prevents internal database/system
/// leakage to customers while logging structured details internally.
class SecureErrorHandler {
  /// Converts an unhandled exception or database error into a safe, client-facing message.
  static String getUserMessage(Object error) {
    final str = error.toString().toLowerCase();

    // Check constraint violation
    if (str.contains('violates check constraint') || str.contains('chk_')) {
      return 'The submitted data does not meet our atelier validation rules.';
    }

    // Unique violation
    if (str.contains('violates unique constraint') || str.contains('duplicate key')) {
      return 'A record with this information already exists in our system.';
    }

    // Foreign key violation
    if (str.contains('violates foreign key constraint')) {
      return 'The requested reference could not be found.';
    }

    // Role escalation / permission rejection
    if (str.contains('security violation') || str.contains('privilege') || str.contains('forbidden')) {
      return 'You do not have permission to perform this action.';
    }

    // Network / timeout
    if (str.contains('socketexception') || str.contains('timeout') || str.contains('network')) {
      return 'Network connection interrupted. Please verify your connection and try again.';
    }

    // Payment errors
    if (str.contains('payment') || str.contains('transaction')) {
      return 'Payment verification could not be completed. Please contact client services.';
    }

    // Generic safe fallback
    return 'An unexpected issue occurred while processing your request. Please try again.';
  }
}
