import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../router/app_router.dart';
import '../domain/entities/pos_device_profile.dart';
import 'pos_device_profile_provider.dart';

final defaultPosRouteProvider = Provider<String>((ref) {
  final profile = ref.watch(posDeviceProfileProvider);
  return resolveDefaultRoute(profile);
});

String resolveDefaultRoute(PosDeviceProfile profile) {
  final defaultSubType =
      profile.posMode == PosMode.food ? profile.defaultSubType : null;

  return PosRoute.pathFor(
    sectionKey: 'billing',
    subTypeKey: defaultSubType?.key,
  );
}
