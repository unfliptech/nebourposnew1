import 'package:flutter/material.dart';

import '../../domain/entities/pos_device_profile.dart';

class PosSubtypeButtons extends StatelessWidget {
  const PosSubtypeButtons({
    super.key,
    required this.subTypes,
    required this.onSelect,
    this.activeSubTypeKey,
  });

  final List<PosSubType> subTypes;
  final ValueChanged<PosSubType> onSelect;
  final String? activeSubTypeKey;

  @override
  Widget build(BuildContext context) {
    if (subTypes.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final subType in subTypes)
          _SubtypeButton(
            subType: subType,
            isActive: subType.key == activeSubTypeKey,
            onSelect: onSelect,
          ),
      ],
    );
  }
}

class _SubtypeButton extends StatelessWidget {
  const _SubtypeButton({
    required this.subType,
    required this.isActive,
    required this.onSelect,
  });

  final PosSubType subType;
  final bool isActive;
  final ValueChanged<PosSubType> onSelect;

  @override
  Widget build(BuildContext context) {
    final bg = isActive ? const Color(0xFFE53935) : Colors.white;
    final fg = isActive ? Colors.white : const Color(0xFFE53935);
    final borderColor =
        isActive ? const Color(0xFFE53935) : const Color(0xFFE53935);

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: borderColor),
        ),
        elevation: isActive ? 0 : 0,
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
      onPressed: () => onSelect(subType),
      child: Text(subType.label.toUpperCase()),
    );
  }
}
