import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../../../core/data/connectivity_service.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../router/app_router.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/sync_status_badge.dart';
import '../../../auth/domain/entities/session.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/passcode_provider.dart';
import '../../../printing/providers/printer_provider.dart';
import '../../../pos/application/pos_navigation_provider.dart';
import '../../../sync/application/sync_service.dart';
import '../../../sync/domain/mappers/sync_snapshot_mapper.dart';
import '../../../sync/domain/repositories/sync_repository.dart';
import '../../../sync/presentation/providers/auto_sync_provider.dart';
import '../../../sync/presentation/providers/meta_provider.dart';
import '../providers/home_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _dumpSnapshot(WidgetRef ref) {
    final meta = ref.read(metaLocalDataSourceProvider);
    final snapshot = meta.readSnapshot();
    if (snapshot == null) {
      debugPrint('[ISAR] No SyncSnapshot stored.');
      return;
    }
    final result = snapshot.toDomainResult();
    final map = _syncResultToDebugMap(result);
    const encoder = JsonEncoder.withIndent('  ');
    debugPrint('[ISAR] SyncSnapshot:\n${encoder.convert(map)}');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final homeState = ref.watch(homeProvider);
    final connectivity = ref.watch(connectivityStatusProvider);
    final passcodeStatus = ref.watch(passcodeStatusProvider);

    authState.whenOrNull(
      data: (session) {
        if (session == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.go(SignInRoute.path);
            }
          });
        }
      },
    );

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Nebour POS'),
        actions: [
          if (passcodeStatus.requiresPasscode)
            TextButton.icon(
              onPressed: () {
                final defaultRoute = ref.read(defaultPosRouteProvider);
                ref
                    .read(passcodeStatusProvider.notifier)
                    .lock(pendingRoute: defaultRoute);
                if (context.mounted) {
                  context.go(PasscodeRoute.path);
                }
              },
              icon: const Icon(Icons.lock_outline),
              label: const Text('Lock to Passcode'),
            ),
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.bug_report_outlined),
              tooltip: 'Dump snapshot',
              onPressed: () => _dumpSnapshot(ref),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) {
                context.go(SignInRoute.path);
              }
            },
          ),
        ],
      ),
      body: homeState.when(
        data: (data) => _HomeView(
          state: data,
          isOnline: connectivity.value != ConnectivityStatus.offline,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Unable to load home data: $error'),
        ),
      ),
    );
  }
}

class _HomeView extends ConsumerStatefulWidget {
  const _HomeView({
    required this.state,
    required this.isOnline,
  });

  final HomeState state;
  final bool isOnline;

  @override
  ConsumerState<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<_HomeView> {
  bool _isSyncing = false;

  Future<void> _runSync() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final outcome =
          await ref.read(syncServiceProvider).synchronize();
      if (!mounted) return;
      switch (outcome.status) {
        case SyncOutcomeStatus.success:
          messenger.showSnackBar(
            const SnackBar(content: Text('Sync completed successfully')),
          );
          ref.invalidate(homeProvider);
          break;
        case SyncOutcomeStatus.cached:
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                outcome.message ?? 'Using cached sync data.',
              ),
            ),
          );
          ref.invalidate(homeProvider);
          break;
        case SyncOutcomeStatus.offlineNoData:
          messenger.showSnackBar(
            const SnackBar(
              content: Text('No network connection. Please try again later.'),
            ),
          );
          break;
        case SyncOutcomeStatus.unauthenticated:
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Session expired. Please sign in again.'),
            ),
          );
          await ref.read(authControllerProvider.notifier).logout();
          break;
        case SyncOutcomeStatus.failure:
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                outcome.message ?? 'Sync failed. Please retry.',
              ),
            ),
          );
          break;
      }
    } catch (error) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Sync failed: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final lastOutcome = ref.watch(lastSyncOutcomeProvider);
    final autoSync = ref.watch(autoSyncControllerProvider);
    final syncResult = state.syncResult ?? lastOutcome?.result;
    final theme = Theme.of(context);
    final session = state.session;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _SyncSummaryCard(
          state: state,
          syncResult: syncResult,
          lastOutcome: lastOutcome,
          isOnline: widget.isOnline,
          isSyncing: _isSyncing,
          autoSync: autoSync,
          onManualSync: _runSync,
        ),
        const SizedBox(height: 16),
        if (syncResult != null) ...[
          _FeatureListCard(result: syncResult),
          const SizedBox(height: 16),
          _AdminsCard(result: syncResult),
          const SizedBox(height: 16),
          _MenuItemsCard(result: syncResult),
          const SizedBox(height: 16),
          _ThemePreviewCard(result: syncResult),
          const SizedBox(height: 16),
          _PasscodeInfoCard(result: syncResult),
          const SizedBox(height: 16),
        ] else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'No sync data is available yet. Run sync to populate data.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
        const _PrinterSetupCard(),
        const SizedBox(height: 16),
        _DeviceDetailsCard(session: session),
      ],
    );
  }
}
class _SyncSummaryCard extends StatelessWidget {
  const _SyncSummaryCard({
    required this.state,
    required this.syncResult,
    required this.lastOutcome,
    required this.isOnline,
    required this.isSyncing,
    required this.autoSync,
    required this.onManualSync,
  });

  final HomeState state;
  final SyncResult? syncResult;
  final SyncOutcome? lastOutcome;
  final bool isOnline;
  final bool isSyncing;
  final AutoSyncState autoSync;
  final VoidCallback onManualSync;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lastSyncedAt = state.lastSyncedAt?.toLocal();
    final tenantName =
        syncResult?.tenant?.name ?? state.snapshot?.tenant?.name ?? 'Unknown tenant';
    final branchName =
        syncResult?.branch?.name ?? state.snapshot?.branch?.name ?? 'Unknown branch';
    final featureCount = syncResult?.features.length ?? 0;
    final adminCount = syncResult?.admins.length ?? 0;

    final menu = syncResult?.menu;
    final categoryCount = menu?.categories.length ?? 0;
    final subcategoryCount = menu == null
        ? 0
        : menu.categories
            .expand((category) => category.subcategories)
            .length;
    final itemCount = menu == null
        ? 0
        : menu.categories
            .expand((category) => category.subcategories)
            .expand((subcategory) => subcategory.items)
            .length;

    var tableCount = 0;
    if (syncResult?.dineIn != null) {
      for (final floor in syncResult!.dineIn!.floors) {
        tableCount += floor.tables.length;
        for (final section in floor.sections) {
          tableCount += section.tables.length;
        }
      }
    }

    final syncStatus = _resolveSyncStatus(lastOutcome, isSyncing);
    final autoSyncLabel = _describeAutoSync(autoSync.status);
    final nextRunLabel = autoSync.nextRunAt != null
        ? 'Next run: ${autoSync.nextRunAt!.toLocal()}'
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Sync overview',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                SyncStatusBadge(status: syncStatus),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 24,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _SummaryStat(label: 'Tenant', value: tenantName),
                _SummaryStat(label: 'Branch', value: branchName),
                _SummaryStat(
                  label: 'Last synced',
                  value: lastSyncedAt?.toString() ?? 'Never',
                ),
                _SummaryStat(
                  label: 'Connectivity',
                  value: isOnline ? 'Online' : 'Offline',
                ),
                _SummaryStat(label: 'Auto sync', value: autoSyncLabel),
              ],
            ),
            if (nextRunLabel != null) ...[
              const SizedBox(height: 8),
              Text(
                nextRunLabel,
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (syncResult != null) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 24,
                runSpacing: 16,
                children: [
                  _SummaryMetric(
                    label: 'Features',
                    value: featureCount.toString(),
                  ),
                  _SummaryMetric(
                    label: 'Admins',
                    value: adminCount.toString(),
                  ),
                  _SummaryMetric(
                    label: 'Menu items',
                    value: itemCount.toString(),
                    subtitle:
                        '$categoryCount categories · $subcategoryCount sections',
                  ),
                  _SummaryMetric(
                    label: 'Tables',
                    value: tableCount.toString(),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: isSyncing ? null : onManualSync,
                icon: isSyncing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync),
                label: Text(isSyncing ? 'Syncing…' : 'Run sync'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SyncStatus _resolveSyncStatus(SyncOutcome? outcome, bool isSyncing) {
    if (isSyncing) {
      return SyncStatus.syncing;
    }
    final status = outcome?.status;
    if (status == null) {
      return SyncStatus.idle;
    }
    switch (status) {
      case SyncOutcomeStatus.success:
      case SyncOutcomeStatus.cached:
        return SyncStatus.success;
      case SyncOutcomeStatus.offlineNoData:
      case SyncOutcomeStatus.unauthenticated:
      case SyncOutcomeStatus.failure:
        return SyncStatus.error;
    }
  }

  String _describeAutoSync(AutoSyncStatus status) {
    switch (status) {
      case AutoSyncStatus.idle:
        return 'Idle';
      case AutoSyncStatus.syncing:
        return 'Syncing…';
      case AutoSyncStatus.success:
        return 'Up to date';
      case AutoSyncStatus.error:
        return 'Attention required';
    }
  }
}
class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    this.subtitle,
  });

  final String label;
  final String value;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
class _FeatureListCard extends StatelessWidget {
  const _FeatureListCard({required this.result});

  final SyncResult result;

  @override
  Widget build(BuildContext context) {
    final features = result.features;
    final theme = Theme.of(context);
    if (features.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'No features were included in the latest sync.',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enabled features', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            ...features.map(
              (feature) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        feature.name,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          feature.key,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          feature.enabled == true ? 'Enabled' : 'Disabled',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: feature.enabled == true
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _AdminsCard extends StatelessWidget {
  const _AdminsCard({required this.result});

  final SyncResult result;

  @override
  Widget build(BuildContext context) {
    final admins = result.admins;
    final theme = Theme.of(context);
    if (admins.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'No admins were included in the latest sync.',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Administrators', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            ...admins.map(
              (admin) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      admin.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Role: ${admin.role ?? '—'} · Passcode: ${admin.passcode ?? '—'} · Active: ${admin.isActive == true ? 'Yes' : 'No'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _MenuItemsCard extends StatelessWidget {
  const _MenuItemsCard({required this.result});

  final SyncResult result;

  @override
  Widget build(BuildContext context) {
    final menu = result.menu;
    final categories = menu?.categories ?? const <SyncMenuCategory>[];
    final theme = Theme.of(context);

    if (menu == null || categories.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'No menu categories were synced.',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }

    final categorySummaries = categories.map((category) {
      final subcategoryCount = category.subcategories.length;
      final itemCount = category.subcategories
          .expand((subcategory) => subcategory.items)
          .length;
      return '${category.name} · $subcategoryCount sections · $itemCount items';
    }).toList();

    final samples = _collectSamples(menu);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Menu overview', style: theme.textTheme.titleMedium),
            if (menu.lastUpdatedAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Updated at: ${menu.lastUpdatedAt!.toLocal()}',
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            ...categorySummaries.map(
              (summary) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(summary, style: theme.textTheme.bodyMedium),
              ),
            ),
            if (samples.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Sample items', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              ...samples.map(
                (item) {
                  final parts = <String>[
                    item.itemName,
                    item.subcategoryName,
                    item.categoryName,
                    if (item.priceLabel != null) item.priceLabel!,
                  ].where((part) => part.trim().isNotEmpty).toList();
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      parts.join(' · '),
                      style: theme.textTheme.bodyMedium,
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<_MenuDisplayItem> _collectSamples(
    SyncMenu menu, {
    int maxSamples = 8,
  }) {
    final samples = <_MenuDisplayItem>[];
    for (final category in menu.categories) {
      for (final subcategory in category.subcategories) {
        for (final item in subcategory.items) {
          samples.add(
            _MenuDisplayItem(
              categoryName: category.name,
              subcategoryName: subcategory.name,
              itemName: item.name,
              priceLabel: _resolvePriceLabel(item),
            ),
          );
          if (samples.length >= maxSamples) {
            return samples;
          }
        }
      }
    }
    return samples;
  }

  String? _resolvePriceLabel(SyncMenuItem item) {
    final context = _pickPriceContext(item);
    if (context == null) {
      return null;
    }
    final amount = context.amountMinor / 100.0;
    final currency = context.currency.trim().toUpperCase();
    if (currency == 'INR') {
      return '?${amount.toStringAsFixed(2)}';
    }
    if (currency.isEmpty) {
      return amount.toStringAsFixed(2);
    }
    return '$currency ${amount.toStringAsFixed(2)}';
  }

  SyncPriceContext? _pickPriceContext(SyncMenuItem item) {
    SyncPriceContext? fallback;
    for (final variation in item.variations) {
      for (final context in variation.priceContexts) {
        if (context.amountMinor <= 0) {
          continue;
        }
        fallback ??= context;
        if (context.context.toUpperCase() == 'DINE_IN') {
          return context;
        }
      }
    }
    return fallback;
  }
}

class _MenuDisplayItem {
  const _MenuDisplayItem({
    required this.categoryName,
    required this.subcategoryName,
    required this.itemName,
    this.priceLabel,
  });

  final String categoryName;
  final String subcategoryName;
  final String itemName;
  final String? priceLabel;
}
class _ThemePreviewCard extends StatelessWidget {
  const _ThemePreviewCard({required this.result});

  final SyncResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final payload = result.theme;

    if (payload == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'No theme configuration was provided in the last sync.',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }

    final meta = payload.meta ?? <String, dynamic>{};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Theme payload', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            _infoRow(context, 'Mode', payload.mode ?? 'system'),
            if ((payload.primaryColor ?? '').isNotEmpty)
              _infoRow(context, 'Primary', payload.primaryColor!),
            if ((payload.accentColor ?? '').isNotEmpty)
              _infoRow(context, 'Accent', payload.accentColor!),
            const SizedBox(height: 16),
            _buildPaletteSection(context, 'Light palette', payload.light),
            const SizedBox(height: 16),
            _buildPaletteSection(context, 'Dark palette', payload.dark),
            if (meta.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Meta', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              ...meta.entries.map(
                (entry) => _infoRow(
                  context,
                  entry.key,
                  entry.value.toString(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildPaletteSection(
    BuildContext context,
    String title,
    SyncThemePalette? palette,
  ) {
    final theme = Theme.of(context);
    final entries = <_PaletteEntry>[
      _PaletteEntry('Primary', palette?.primary),
      _PaletteEntry('Accent', palette?.accent),
      _PaletteEntry('Background', palette?.background),
      _PaletteEntry('Surface', palette?.surface),
      _PaletteEntry('Text', palette?.text),
    ]
        .where((entry) => entry.colorHex != null && entry.colorHex!.isNotEmpty)
        .toList();

    if (entries.isEmpty) {
      return Text(
        '$title: not provided',
        style: theme.textTheme.bodyMedium,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: entries
              .map((entry) => _ColorSwatchTile(entry: entry))
              .toList(),
        ),
      ],
    );
  }
}

class _PaletteEntry {
  const _PaletteEntry(this.label, this.colorHex);

  final String label;
  final String? colorHex;
}

class _ColorSwatchTile extends StatelessWidget {
  const _ColorSwatchTile({required this.entry});

  final _PaletteEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _parseHexColor(entry.colorHex);
    final borderColor = theme.colorScheme.outline.withAlpha((0.12 * 255).round());
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color ?? theme.colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          entry.label,
          style: theme.textTheme.labelSmall,
        ),
        if (entry.colorHex != null)
          Text(
            entry.colorHex!,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}
class _PasscodeInfoCard extends StatelessWidget {
  const _PasscodeInfoCard({required this.result});

  final SyncResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final feature = result.features.firstWhere(
      (feature) => feature.key.toUpperCase() == 'REQUIRE_PASSCODE',
      orElse: () => const SyncFeature(
        id: '',
        key: '',
        name: '',
      ),
    );
    final hasFeature = feature.key.isNotEmpty;
    final isEnabled = hasFeature ? (feature.enabled ?? false) : false;
    final adminsWithPasscodes = result.admins
        .where((admin) => (admin.passcode?.isNotEmpty ?? false))
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Passcode configuration',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text(
              hasFeature ? feature.name : 'No passcode feature in sync',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _SummaryStat(
              label: 'Feature key',
              value: hasFeature ? feature.key : '-',
            ),
            _SummaryStat(
              label: 'Requirement active',
              value: isEnabled ? 'Yes' : 'No',
            ),
            const SizedBox(height: 12),
            Text(
              'Admins with passcodes (${adminsWithPasscodes.length})',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            if (adminsWithPasscodes.isEmpty)
              Text(
                'No passcodes were provided in the latest sync.',
                style: theme.textTheme.bodyMedium,
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: adminsWithPasscodes
                    .map(
                      (admin) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          '${admin.name} · Passcode: ${admin.passcode}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}
