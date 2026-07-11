import 'dart:async';
import '../models/sync_models.dart';
import '../services/sync_service.dart';

/// Manages when synchronization runs.
///
/// Responsibilities:
/// - Trigger sync on app start
/// - Trigger sync every 30 minutes
/// - Trigger sync when connectivity is restored
/// - Trigger sync on manual request
/// - Prevent duplicate concurrent sync sessions (mutex)
///
/// Business features never interact with SyncManager directly.
/// They call [SyncManager.requestSync] at most, which is fire-and-forget.
class SyncManager {
  SyncManager({required this._syncService});

  final SyncService _syncService;

  static const Duration _periodicInterval = Duration(minutes: 30);

  Timer? _periodicTimer;
  bool _disposed = false;

  // Simple boolean mutex — only one sync may run at a time.
  // Dart is single-threaded so this is safe without atomic operations.
  bool _syncInProgress = false;

  /// The result of the most recently completed sync session.
  SyncResult? lastResult;

  /// Starts the periodic 30-minute sync timer and triggers an initial sync.
  ///
  /// Should be called once when the app initializes.
  void start() {
    if (_disposed) return;
    _startPeriodicTimer();
    // Trigger an initial sync after a short delay so the app UI can load first.
    Future.delayed(const Duration(seconds: 3), () => requestSync());
  }

  /// Stops the periodic timer and releases resources.
  void dispose() {
    _disposed = true;
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  /// Requests a sync session.
  ///
  /// If a session is already running, the request is silently ignored.
  /// This is intentional — callers do not need to coordinate.
  ///
  /// Returns immediately. Sync runs in the background.
  Future<void> requestSync() async {
    if (_disposed) return;
    if (_syncInProgress) return; // mutex: ignore if already running
    if (_syncService.isRunning) return;

    _syncInProgress = true;
    try {
      lastResult = await _syncService.sync();
    } finally {
      _syncInProgress = false;
    }
  }

  /// Notifies the manager that internet connectivity has been restored.
  /// Triggers an immediate sync attempt.
  void onConnectivityRestored() {
    requestSync();
  }

  /// Returns true if a sync session is currently in progress.
  bool get isSyncing => _syncInProgress || _syncService.isRunning;

  void _startPeriodicTimer() {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(_periodicInterval, (_) {
      if (!_disposed) requestSync();
    });
  }
}
