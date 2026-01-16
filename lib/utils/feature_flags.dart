library;

/// Feature flags controlled via `--dart-define=...`.
///
/// Keep defaults OFF for any feature that requires backend changes.

/// Enables UI scaffolding for media upload (reels/stories) via presigned URLs.
/// Default: OFF (backend endpoints may not exist yet).
const bool kEnableMediaUpload =
    bool.fromEnvironment('ENABLE_MEDIA_UPLOAD', defaultValue: false);

/// Enables product reviews/ratings UI and API calls.
/// Default: OFF (backend endpoints may not exist yet).
const bool kEnableProductReviews =
    bool.fromEnvironment('ENABLE_PRODUCT_REVIEWS', defaultValue: false);

