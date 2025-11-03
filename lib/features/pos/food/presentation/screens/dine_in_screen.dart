import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../sync/domain/repositories/sync_repository.dart';
import '../../../../sync/presentation/providers/meta_provider.dart';


class FoodDineInView extends ConsumerStatefulWidget {
  const FoodDineInView({super.key});

  @override
  ConsumerState<FoodDineInView> createState() => _FoodDineInViewState();
}

class _FoodDineInViewState extends ConsumerState<FoodDineInView> {
  bool _moveKot = false;

  @override
  Widget build(BuildContext context) {
    final dineInAsync = ref.watch(dineInSnapshotProvider);

    return dineInAsync.when(
      data: (dineIn) => _buildContent(context, dineIn),
      loading: (_) => const _DineInLoading(),
      error: (error, __) => _DineInError(message: error.toString()),
    );
  }

  Widget _buildContent(BuildContext context, SyncDineIn? dineIn) {
    final floors = _mapFloors(dineIn);

    if (floors.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatusLegend(
              moveKot: _moveKot,
              onMoveKotChanged: (value) {
                setState(() => _moveKot = value);
              },
            ),
            const SizedBox(height: 32),
            Expanded(
              child: Center(
                child: Text(
                  'No dine-in layout found. Run a sync to import floor configuration.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return DefaultTabController(
      length: floors.length,
      child: Column(
        children: [
          _buildTabBar(Theme.of(context), floors),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
            child: _StatusLegend(
              moveKot: _moveKot,
              onMoveKotChanged: (value) {
                setState(() => _moveKot = value);
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              physics: const ClampingScrollPhysics(),
              children: [
                for (final floor in floors) _FloorView(floor: floor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme, List<_FloorData> floors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.08),
          ),
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: TabBar(
        isScrollable: true,
        indicatorColor: theme.colorScheme.primary,
        labelColor: theme.colorScheme.onSurface,
        unselectedLabelColor:
            theme.colorScheme.onSurface.withValues(alpha: 0.6),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
        indicatorWeight: 3,
        tabs: [
          for (final floor in floors) Tab(text: floor.name),
        ],
      ),
    );
  }

  List<_FloorData> _mapFloors(SyncDineIn? dineIn) {
    if (dineIn == null) return const [];

    return dineIn.floors
        .map(
          (floor) => _FloorData(
            name: _fallbackName(floor.name, 'Floor'),
            sections: [
              ...floor.sections.map(
                (section) => _TableSection(
                  name: _fallbackName(section.name, 'Section'),
                  tables: _mapTables(section.tables),
                ),
              ),
              if (floor.tables.isNotEmpty)
                _TableSection(
                  name: 'General',
                  tables: _mapTables(floor.tables),
                ),
            ],
          ),
        )
        .toList();
  }

  List<_DiningTable> _mapTables(List<SyncDineInTable> tables) {
    return tables
        .map((table) {
          final status = _resolveStatus(table.status);
          return _DiningTable(
            name: _fallbackName(table.name, table.id),
            status: status,
            statusLabel: _formatStatusLabel(table.status),
            capacity: table.capacity,
            attributes: List<String>.from(table.attributes),
          );
        })
        .toList();
  }

  TableStatus _resolveStatus(String? rawStatus) {
    final value = rawStatus?.trim().toUpperCase();
    switch (value) {
      case 'RUNNING':
      case 'RUNNING_TABLE':
      case 'OCCUPIED':
        return TableStatus.runningTable;
      case 'RUNNING_KOT':
      case 'KOT':
        return TableStatus.runningKot;
      case 'PRINTED_BILL':
      case 'BILL_PRINTED':
        return TableStatus.printedBill;
      case 'VACANT':
      case 'AVAILABLE':
      case 'OPEN':
      default:
        return TableStatus.available;
    }
  }

  String _formatStatusLabel(String? rawStatus) {
    final value = rawStatus?.trim();
    if (value == null || value.isEmpty) {
      return 'Unknown';
    }
    final parts = value.split(RegExp(r'[_\s]+'));
    return parts
        .where((part) => part.isNotEmpty)
        .map(
          (part) => part.substring(0, 1).toUpperCase() +
              part.substring(1).toLowerCase(),
        )
        .join(' ');
  }

  String _fallbackName(String? value, String fallback) {
    final resolved = (value ?? '').trim();
    if (resolved.isNotEmpty) return resolved;
    final fallbackTrimmed = fallback.trim();
    if (fallbackTrimmed.isNotEmpty) return fallbackTrimmed;
    return 'Table';
  }
}

class _StatusLegend extends StatelessWidget {
  const _StatusLegend({
    required this.moveKot,
    required this.onMoveKotChanged,
  });

  final bool moveKot;
  final ValueChanged<bool> onMoveKotChanged;

  @override
  Widget build(BuildContext context) {
    final statusItems = TableStatus.values.map((status) {
      return _LegendItem(
        color: status.indicatorColor,
        label: status.label,
      );
    }).toList();

    return Wrap(
      spacing: 16,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch.adaptive(
              value: moveKot,
              onChanged: onMoveKotChanged,
            ),
            const SizedBox(width: 8),
            const Text(
              'Move KOT/Items',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        ...statusItems,
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _FloorView extends StatelessWidget {
  const _FloorView({required this.floor});

  final _FloorData floor;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final section in floor.sections) ...[
            _SectionHeader(title: section.name),
            const SizedBox(height: 12),
            _TablesGrid(tables: section.tables),
            const SizedBox(height: 28),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _TablesGrid extends StatelessWidget {
  const _TablesGrid({required this.tables});

  final List<_DiningTable> tables;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (tables.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.08),
          ),
        ),
        child: Center(
          child: Text(
            'No tables configured in this section.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const cardWidth = 180.0;
        const spacing = 16.0;
        final columns = (constraints.maxWidth / (cardWidth + spacing))
            .floor()
            .clamp(1, tables.length);

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final table in tables)
              SizedBox(
                width: columns > 1 ? cardWidth : constraints.maxWidth,
                child: _TableCard(table: table),
              ),
          ],
        );
      },
    );
  }
}

class _TableCard extends StatelessWidget {
  const _TableCard({required this.table});

  final _DiningTable table;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        table.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: table.status.indicatorColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                if (table.capacity > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Capacity: ${table.capacity}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  table.statusLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (table.attributes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: table.attributes
                        .map(
                          (attribute) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              attribute,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: table.status.footerColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              table.statusLabel,
              style: TextStyle(
                color: table.status.onFooterColor,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DineInLoading extends StatelessWidget {
  const _DineInLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

class _DineInError extends StatelessWidget {
  const _DineInError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 40,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 12),
            Text(
              'Failed to load dine-in layout',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

enum TableStatus {
  available,
  runningTable,
  runningKot,
  printedBill,
}

extension on TableStatus {
  String get label {
    switch (this) {
      case TableStatus.available:
        return 'Available';
      case TableStatus.runningTable:
        return 'Running Table';
      case TableStatus.runningKot:
        return 'Running KOT';
      case TableStatus.printedBill:
        return 'Printed Bill';
    }
  }

  Color get indicatorColor {
    switch (this) {
      case TableStatus.available:
        return const Color(0xFF202124);
      case TableStatus.runningTable:
        return const Color(0xFF1A73E8);
      case TableStatus.runningKot:
        return const Color(0xFF1B9E2F);
      case TableStatus.printedBill:
        return const Color(0xFFF57C00);
    }
  }

  Color get footerColor {
    switch (this) {
      case TableStatus.available:
        return const Color(0xFF202124);
      case TableStatus.runningTable:
        return const Color(0xFF1A73E8);
      case TableStatus.runningKot:
        return const Color(0xFF1B9E2F);
      case TableStatus.printedBill:
        return const Color(0xFFF57C00);
    }
  }

  Color get onFooterColor => Colors.white;
}

class _DiningTable {
  const _DiningTable({
    required this.name,
    required this.status,
    required this.statusLabel,
    this.capacity = 0,
    this.attributes = const <String>[],
  });

  final String name;
  final TableStatus status;
  final String statusLabel;
  final int capacity;
  final List<String> attributes;
}

class _TableSection {
  const _TableSection({
    required this.name,
    required this.tables,
  });

  final String name;
  final List<_DiningTable> tables;
}

class _FloorData {
  const _FloorData({required this.name, required this.sections});

  final String name;
  final List<_TableSection> sections;
}

