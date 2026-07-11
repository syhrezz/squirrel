/// Exponential backoff retry policy for failed sync queue entries.
///
/// Retry delays (minutes): 1 → 2 → 4 → 8 → 16 → 30 (cap)
///
/// After each failure, [nextRetryAt] is set to now + delay.
/// The sync engine skips entries where nextRetryAt > now.
class RetryPolicy {
  const RetryPolicy();

  static const int _maxDelayMinutes = 30;

  static const List<int> _delaysMinutes = [1, 2, 4, 8, 16, 30];

  /// Computes the next retry timestamp (epoch ms) given the current retry count.
  ///
  /// [retryCount] is the number of attempts already made (0-based).
  int nextRetryAt(int retryCount) {
    final delayMinutes = retryCount < _delaysMinutes.length
        ? _delaysMinutes[retryCount]
        : _maxDelayMinutes;
    final delayMs = delayMinutes * 60 * 1000;
    return DateTime.now().millisecondsSinceEpoch + delayMs;
  }

  /// Human-readable description of the delay for the given retry count.
  String describeDelay(int retryCount) {
    final delayMinutes = retryCount < _delaysMinutes.length
        ? _delaysMinutes[retryCount]
        : _maxDelayMinutes;
    if (delayMinutes == 1) return '1 menit';
    if (delayMinutes < 60) return '$delayMinutes menit';
    return '${delayMinutes ~/ 60} jam';
  }
}
