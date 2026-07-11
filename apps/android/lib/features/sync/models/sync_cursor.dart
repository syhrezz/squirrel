/// Pull cursor — stores the high-water mark for incremental sync.
///
/// Every pull operation requests "give me all records changed after
/// lastPullTimestamp". This ensures we never re-download records we
/// already have and never miss records created while offline.
///
/// Stored in [DeviceInfo.lastPullTimestamp].
class SyncCursor {
  const SyncCursor({this.lastPullTimestamp});

  /// Epoch milliseconds of the most recent successful pull.
  /// Null = this device has never pulled from the server.
  final int? lastPullTimestamp;

  bool get isFirstSync => lastPullTimestamp == null;

  SyncCursor advance(int newTimestamp) {
    return SyncCursor(lastPullTimestamp: newTimestamp);
  }

  @override
  String toString() {
    if (lastPullTimestamp == null) return 'SyncCursor(virgin)';
    final dt = DateTime.fromMillisecondsSinceEpoch(lastPullTimestamp!);
    return 'SyncCursor($dt)';
  }
}
