import 'dart:ui';

/// Extension methods for Color to work around Flutter 3.27.4 deprecations
/// and runtime bugs in withValues().
extension ColorCompatExtension on Color {
  /// A drop-in replacement for `.withOpacity(x)` / `.withValues(alpha: x)`.
  ///
  /// Flutter 3.27.4 deprecates `withOpacity()` and ships a runtime bug in
  /// `withValues(alpha:)` that produces incorrect transparency.
  /// This method uses `Color.fromRGBO` which is stable across all versions.
  Color withAlphaCompat(double alpha) {
    return Color.fromRGBO((r * 255).round(), (g * 255).round(), (b * 255).round(), alpha);
  }
}
