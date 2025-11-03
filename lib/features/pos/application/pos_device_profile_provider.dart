import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/pos_device_profile.dart';

/// Temporary device profile provider.
/// TODO: replace with data sourced from device auth/sync payload.
final posDeviceProfileProvider = Provider<PosDeviceProfile>((ref) {
  return const PosDeviceProfile(
    inputType: PosInputType.touch,
    posMode: PosMode.food,
    subTypes: [
      PosSubType(key: 'dinein', label: 'Dine-In', isDefault: true),
      PosSubType(key: 'pickup', label: 'Pickup'),
      PosSubType(key: 'delivery', label: 'Delivery'),
    ],
  );
});
