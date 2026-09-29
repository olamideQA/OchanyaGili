class AppConstants {
  static const String appName = 'Ochanya Gili';
  
  // Supabase tables
  static const String profilesTable = 'profiles';
  static const String productsTable = 'products';
  static const String ordersTable = 'orders';
  static const String categoriesTable = 'categories';
  
  // Storage buckets
  static const String productsBucket = 'products';
  static const String collectionsBucket = 'collections';
  static const String lookbookBucket = 'lookbook';
  static const String journalBucket = 'journal';
  static const String avatarsBucket = 'avatars';
  static const String customRequestsBucket = 'custom_requests';
  // Backward compatibility alias
  static const String productImagesBucket = productsBucket;
  static const String avatarImagesBucket = avatarsBucket;
  
  // Animations
  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration defaultAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);
}
