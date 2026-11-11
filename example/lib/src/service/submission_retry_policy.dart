/// Exponential backoff for pending submissions that failed to send.
///
/// After each failed attempt the next try is delayed by
/// `baseDelay * 2^(attempts - 1)`, capped at [maxDelay]. After [maxAttempts]
/// failures the submission is marked as failed and no longer retried.
class SubmissionRetryPolicy {
  const SubmissionRetryPolicy({
    this.maxAttempts = 8,
    this.baseDelay = const Duration(seconds: 30),
    this.maxDelay = const Duration(hours: 1),
  });

  final int maxAttempts;
  final Duration baseDelay;
  final Duration maxDelay;

  /// Delay before the next attempt, given the number of failed [attempts].
  Duration delayAfter(int attempts) {
    final exponent = (attempts - 1).clamp(0, 30);
    final delay = baseDelay * (1 << exponent);
    return delay > maxDelay ? maxDelay : delay;
  }

  /// Whether [attempts] failures use up every allowed try.
  bool isExhausted(int attempts) => attempts >= maxAttempts;
}
