import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../router/app_router.dart';
import '../../application/pos_device_profile_provider.dart';
import '../../domain/entities/pos_device_profile.dart';
import '../../shared/widgets/pos_primary_app_bar.dart';
import '../../shared/widgets/pos_subtype_buttons.dart';
import '../../food/presentation/screens/dine_in_screen.dart';
import '../../food/presentation/screens/food_order_screen.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/passcode_provider.dart';
import '../../../sync/presentation/providers/auto_sync_provider.dart';
import '../../../sync/application/sync_service.dart';
import '../../../sync/presentation/utils/sync_outcome_utils.dart';
import '../../../../shared/utils/app_toast.dart';

enum PosSection { billing, operations, settings }

extension PosSectionExtension on PosSection {
  String get key {
    switch (this) {
      case PosSection.billing:
        return 'billing';
      case PosSection.operations:
        return 'operations';
      case PosSection.settings:
        return 'settings';
    }
  }

  String get label {
    switch (this) {
      case PosSection.billing:
        return 'Billing';
      case PosSection.operations:
        return 'Operations';
      case PosSection.settings:
        return 'Settings';
    }
  }
}

PosSection parsePosSection(String? key) {
  switch (key) {
    case 'operations':
      return PosSection.operations;
    case 'settings':
      return PosSection.settings;
    case 'billing':
    default:
      return PosSection.billing;
  }
}

class PosShellScreen extends ConsumerStatefulWidget {
  const PosShellScreen({
    super.key,
    this.initialSectionKey,
    this.initialSubTypeKey,
  });

  final String? initialSectionKey;
  final String? initialSubTypeKey;

  @override
  ConsumerState<PosShellScreen> createState() => _PosShellScreenState();
}

class _PosShellScreenState extends ConsumerState<PosShellScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late PosSection _section;
  PosSubType? _activeSubType;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(posDeviceProfileProvider);
    _section = parsePosSection(widget.initialSectionKey);
    _activeSubType = _resolveInitialSubType(profile);
  }

  @override
  void didUpdateWidget(covariant PosShellScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSectionKey != oldWidget.initialSectionKey ||
        widget.initialSubTypeKey != oldWidget.initialSubTypeKey) {
      final profile = ref.read(posDeviceProfileProvider);
      setState(() {
        _section = parsePosSection(widget.initialSectionKey);
        _activeSubType = _resolveInitialSubType(profile);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(posDeviceProfileProvider);
    final subTypes = profile.subTypes;
    final autoSyncState = ref.watch(autoSyncControllerProvider);
    final isSyncing = autoSyncState.status == AutoSyncStatus.syncing;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: PosPrimaryAppBar(
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        onNewOrderTap: _section == PosSection.billing && subTypes.isNotEmpty
            ? () => _showNewOrderDialog(context, subTypes)
            : null,
        onManualSyncTap: () => _handleManualSync(context),
        onLockTap: () => _handleLock(context),
        onLogoutTap: () => _handleLogout(context),
        isManualSyncing: isSyncing,
      ),
      drawer: _buildDrawer(context),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            sections: PosSection.values,
            selected: _section,
            onSelected: (section) => _onSectionSelected(section, profile),
          ),
          if (_section == PosSection.billing)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _ActionButton(
                    label: 'CUSTOM CHECK',
                    onTap: () => _handleCustomCheck(context),
                  ),
                  if (subTypes.isNotEmpty)
                    PosSubtypeButtons(
                      subTypes: subTypes,
                      activeSubTypeKey: _activeSubType?.key,
                      onSelect: (subType) =>
                          _selectSubType(context, profile, subType),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Expanded(child: _buildSectionBody(profile)),
        ],
      ),
    );
  }

  Widget _buildSectionBody(PosDeviceProfile profile) {
    switch (_section) {
      case PosSection.billing:
        final subType = _activeSubType ?? profile.defaultSubType;
        if (profile.posMode == PosMode.food && subType?.key == 'dinein') {
          return const FoodDineInView();
        }
        final label = subType?.label ?? 'Orders';
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: FoodOrderView(label: label),
        );
      case PosSection.operations:
        return const _PlaceholderView(message: 'Operations coming soon');
      case PosSection.settings:
        return const _PlaceholderView(message: 'Settings coming soon');
    }
  }

  void _onSectionSelected(PosSection section, PosDeviceProfile profile) {
    if (_section == section) return;
    setState(() => _section = section);
    _syncRoute(profile, section: section);
  }

  PosSubType? _resolveInitialSubType(PosDeviceProfile profile) {
    if (profile.subTypes.isEmpty) return null;
    if (widget.initialSubTypeKey == null) return profile.defaultSubType;
    return profile.subTypes.firstWhere(
      (subType) => subType.key == widget.initialSubTypeKey,
      orElse: () => profile.defaultSubType ?? profile.subTypes.first,
    );
  }

  void _selectSubType(
    BuildContext context,
    PosDeviceProfile profile,
    PosSubType subType,
  ) {
    if (_activeSubType?.key == subType.key) return;
    setState(() => _activeSubType = subType);
    _syncRoute(profile, subType: subType);
  }

  void _syncRoute(
    PosDeviceProfile profile, {
    PosSection? section,
    PosSubType? subType,
  }) {
    final path = _resolveRoute(profile, section: section, subType: subType);
    context.go(path);
  }

  String _resolveRoute(
    PosDeviceProfile profile, {
    PosSection? section,
    PosSubType? subType,
  }) {
    final targetSection = section ?? _section;
    final targetSubType = subType ?? _activeSubType ?? profile.defaultSubType;
    return PosRoute.pathFor(
      sectionKey: targetSection.key,
      subTypeKey: targetSubType?.key,
    );
  }

  Future<void> _handleManualSync(BuildContext context) async {
    final controller = ref.read(autoSyncControllerProvider.notifier);
    final outcome = await controller.runManualSync();
    if (!context.mounted) return;

    final message = describeSyncOutcome(outcome);
    showAppToast(context, message, _toastTypeForOutcome(outcome));

    if (outcome != null &&
        outcome.status == SyncOutcomeStatus.unauthenticated &&
        context.mounted) {
      context.go(SignInRoute.path);
    }
  }

  AppToastType _toastTypeForOutcome(SyncOutcome? outcome) {
    if (outcome == null) return AppToastType.error;
    switch (outcome.status) {
      case SyncOutcomeStatus.success:
      case SyncOutcomeStatus.cached:
        return AppToastType.success;
      case SyncOutcomeStatus.offlineNoData:
      case SyncOutcomeStatus.failure:
      case SyncOutcomeStatus.unauthenticated:
        return AppToastType.error;
    }
  }

  void _handleLock(BuildContext context) {
    final profile = ref.read(posDeviceProfileProvider);
    final route = _resolveRoute(profile);
    ref.read(passcodeStatusProvider.notifier).lock(pendingRoute: route);
    context.go(PasscodeRoute.path);
  }

  Future<void> _handleLogout(BuildContext context) async {
    await ref.read(authControllerProvider.notifier).logout();
    if (!context.mounted) return;
    context.go(SignInRoute.path);
  }

  Future<void> _showNewOrderDialog(
    BuildContext context,
    List<PosSubType> subTypes,
  ) async {
    final selected = await showDialog<PosSubType>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create New Order'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final subType in subTypes)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      subType.label,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: subType.key == _activeSubType?.key
                        ? const Icon(Icons.check_circle_outline,
                            color: Color(0xFFE53935))
                        : null,
                    onTap: () => Navigator.of(context).pop(subType),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (selected != null && context.mounted) {
      _selectSubType(context, ref.read(posDeviceProfileProvider), selected);
    }
  }

  void _handleCustomCheck(BuildContext context) {
    showAppToast(
      context,
      'Custom checks will be available soon.',
      AppToastType.info,
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Image.asset(
                  'assets/nebour-logo-dark.png',
                  height: 36,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            for (final section in PosSection.values)
              ListTile(
                leading: Icon(_sectionIcon(section)),
                title: Text(
                  section.label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                selected: section == _section,
                onTap: () {
                  Navigator.of(context).pop();
                  _onSectionSelected(
                      section, ref.read(posDeviceProfileProvider));
                },
              ),
          ],
        ),
      ),
    );
  }

  IconData _sectionIcon(PosSection section) {
    switch (section) {
      case PosSection.billing:
        return Icons.receipt_long;
      case PosSection.operations:
        return Icons.workspaces;
      case PosSection.settings:
        return Icons.settings_outlined;
    }
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.sections,
    required this.selected,
    required this.onSelected,
  });

  final List<PosSection> sections;
  final PosSection selected;
  final ValueChanged<PosSection> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Wrap(
        spacing: 12,
        children: [
          for (final section in sections)
            _SectionChip(
              section: section,
              isActive: section == selected,
              onTap: () => onSelected(section),
            ),
        ],
      ),
    );
  }
}

class _SectionChip extends StatelessWidget {
  const _SectionChip({
    required this.section,
    required this.isActive,
    required this.onTap,
  });

  final PosSection section;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFFE53935);
    return ChoiceChip(
      label: Text(
        section.label.toUpperCase(),
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isActive ? Colors.white : activeColor,
        ),
      ),
      selected: isActive,
      onSelected: (_) => onTap(),
      selectedColor: activeColor,
      backgroundColor: Colors.white,
      side: const BorderSide(color: activeColor),
      pressElevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE53935),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
      onPressed: onTap,
      child: Text(label),
    );
  }
}

class _PlaceholderView extends StatelessWidget {
  const _PlaceholderView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}
