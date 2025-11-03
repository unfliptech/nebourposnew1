import 'package:isar/isar.dart';

part 'sync_snapshot.g.dart';

@collection
class SyncSnapshot {
  SyncSnapshot();

  Id id = SyncSnapshot.primaryId;

  static const int primaryId = 1;

  String? status;
  String? apiVersion;
  int? schemaVersion;
  int? dataVersion;
  DateTime? syncedAt;

  TenantInfo? tenant;
  BranchInfo? branch;
  DeviceInfo? device;
  List<FeatureInfo> features = <FeatureInfo>[];
  ThemePayload? theme;
  List<AdminInfo> admins = <AdminInfo>[];
  MenuPayload? menu;
  DineInPayload? dineIn;
  SectionsChangedPayload? sectionsChanged;
  VersionsPayload? versions;

  DateTime? createdAt;
  DateTime? updatedAt;

  bool get hasData => syncedAt != null;
}

@embedded
class TenantInfo {
  String? id;
  String? name;
  String? logo;
  String? email;
  String? phone;
  String? address;
  String? metaJson;
  bool? isActive;
  DateTime? updatedAt;
}

@embedded
class BranchInfo {
  String? id;
  String? tenantId;
  String? name;
  String? code;
  String? address;
  String? metaJson;
  bool? isActive;
  DateTime? updatedAt;
}

@embedded
class DeviceInfo {
  String? name;
  String? inputType;
  String? posMode;
  String? defaultSubType;
  List<DeviceSubTypeInfo> subTypes = <DeviceSubTypeInfo>[];
  List<String> capabilities = <String>[];
  String? metaJson;
}

@embedded
class DeviceSubTypeInfo {
  String? key;
  String? label;
  bool? isDefault;
}

@embedded
class FeatureInfo {
  String? id;
  String? key;
  String? name;
  String? category;
  String? type;
  bool? isActive;
  bool? enabled;
  String? metaJson;
  String? featureMetaJson;
}

@embedded
class ThemePayload {
  String? mode;
  ThemePalette? light;
  ThemePalette? dark;
  String? metaJson;
}

@embedded
class ThemePalette {
  String? primary;
  String? accent;
  String? background;
  String? surface;
  String? text;
}

@embedded
class AdminInfo {
  String? id;
  String? name;
  String? role;
  String? passcode;
  bool? isActive;
  String? metaJson;
}

@embedded
class MenuPayload {
  DateTime? lastUpdatedAt;
  List<MenuCategoryPayload> categories = <MenuCategoryPayload>[];
}

@embedded
class MenuCategoryPayload {
  String? id;
  String? name;
  int? displayOrder;
  List<MenuSubcategoryPayload> subcategories = <MenuSubcategoryPayload>[];
}

@embedded
class MenuSubcategoryPayload {
  String? id;
  String? name;
  List<MenuItemPayload> items = <MenuItemPayload>[];
}

@embedded
class MenuItemPayload {
  String? id;
  String? name;
  bool? isFavourite;
  String? foodType;
  String? type;
  bool? variationRequired;
  List<String> availableIn = <String>[];
  String? hsnCode;
  String? shortcutCode;
  int? shortcutNumber;
  String? metaJson;
  List<MenuVariationPayload> variations = <MenuVariationPayload>[];
}

@embedded
class MenuVariationPayload {
  String? id;
  String? name;
  bool? isDefault;
  List<MenuPriceContextPayload> priceContexts = <MenuPriceContextPayload>[];
  List<MenuModifierGroupPayload> modifierGroups =
      <MenuModifierGroupPayload>[];
  String? metaJson;
}

@embedded
class MenuModifierGroupPayload {
  String? id;
  String? name;
  bool? required;
  int? minSelect;
  int? maxSelect;
  List<MenuModifierPayload> modifiers = <MenuModifierPayload>[];
  String? metaJson;
}

@embedded
class MenuModifierPayload {
  String? id;
  String? name;
  List<String> availableIn = <String>[];
  List<MenuPriceContextPayload> priceContexts = <MenuPriceContextPayload>[];
  String? metaJson;
}

@embedded
class MenuPriceContextPayload {
  String? context;
  int? amountMinor;
  String? currency;
  int? gstRateBp;
  String? gstMode;
}

@embedded
class DineInPayload {
  List<DineInFloorPayload> floors = <DineInFloorPayload>[];
}

@embedded
class DineInFloorPayload {
  String? id;
  String? name;
  List<DineInSectionPayload> sections = <DineInSectionPayload>[];
  List<DineInTablePayload> tables = <DineInTablePayload>[];
}

@embedded
class DineInSectionPayload {
  String? id;
  String? name;
  List<DineInTablePayload> tables = <DineInTablePayload>[];
}

@embedded
class DineInTablePayload {
  String? id;
  String? name;
  int? capacity;
  String? status;
  List<String> attributes = <String>[];
}

@embedded
class SectionsChangedPayload {
  bool? menu;
  bool? theme;
  bool? features;
  bool? admins;
}

@embedded
class VersionsPayload {
  int? menu;
  int? theme;
  int? features;
  int? admins;
  DateTime? lastChangedAt;
}
