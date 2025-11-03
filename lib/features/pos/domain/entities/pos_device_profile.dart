enum PosInputType { touch, keyboard }

enum PosMode { food, retail, service, appointment }

class PosSubType {
  const PosSubType({
    required this.key,
    required this.label,
    this.isDefault = false,
  });

  final String key;
  final String label;
  final bool isDefault;
}

class PosDeviceProfile {
  const PosDeviceProfile({
    required this.inputType,
    required this.posMode,
    this.subTypes = const [],
  });

  final PosInputType inputType;
  final PosMode posMode;
  final List<PosSubType> subTypes;

  PosSubType? get defaultSubType {
    if (subTypes.isEmpty) return null;
    return subTypes.firstWhere(
      (subType) => subType.isDefault,
      orElse: () => subTypes.first,
    );
  }
}
