/// Public flush state guard used by example and plugin to prevent
/// concurrent flush operations from running at the same time.
class FlushState {
  /// True when a flush is currently in progress.
  static bool isFlushing = false;
}
