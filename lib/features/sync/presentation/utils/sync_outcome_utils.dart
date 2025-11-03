import '../../application/sync_service.dart';

String describeSyncOutcome(SyncOutcome? outcome) {
  if (outcome == null) {
    return 'Sync failed. Please try again.';
  }
  final message = outcome.message?.trim();
  switch (outcome.status) {
    case SyncOutcomeStatus.success:
      return (message?.isNotEmpty ?? false)
          ? message!
          : 'Sync completed successfully.';
    case SyncOutcomeStatus.cached:
      return (message?.isNotEmpty ?? false) ? message! : 'Already up to date.';
    case SyncOutcomeStatus.offlineNoData:
      return 'No network connection. Unable to sync.';
    case SyncOutcomeStatus.unauthenticated:
      return 'Session expired. Please sign in again.';
    case SyncOutcomeStatus.failure:
      return (message?.isNotEmpty ?? false)
          ? message!
          : 'Sync failed. Please try again.';
  }
}
