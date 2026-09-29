// TEMPLATE-CORE: Master switch for all demo/seed fallbacks.
// Set to false to strip every DEMO-SEED block at once for production
// or when reselling this codebase as a clean template.
// Search tag to find removable blocks: DEMO-SEED
class DemoConfig {
  static const bool enabled = true;

  // When false, image fallbacks return empty instead of Unsplash URLs.
  // Keep true for pitches/demos, false for clean client handoff.
  static const bool useUnsplashPlaceholders = true;
}
