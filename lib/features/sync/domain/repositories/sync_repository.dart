import '../../../auth/domain/entities/session.dart';

class SyncResult {
  const SyncResult({
    required this.syncedAt,
    required this.status,
    this.apiVersion,
    this.schemaVersion,
    this.dataVersion,
    this.tenant,
    this.branch,
    this.features = const <SyncFeature>[],
    this.menu,
    this.theme,
    this.admins = const <SyncAdmin>[],
    this.device,
    this.dineIn,
    this.sectionsChanged,
    this.versions,
  });

  final DateTime syncedAt;
  final String status;
  final String? apiVersion;
  final int? schemaVersion;
  final int? dataVersion;
  final SyncTenant? tenant;
  final SyncBranch? branch;
  final List<SyncFeature> features;
  final SyncMenu? menu;
  final SyncTheme? theme;
  final List<SyncAdmin> admins;
  final SyncDevice? device;
  final SyncDineIn? dineIn;
  final SyncSectionsChanged? sectionsChanged;
  final SyncVersions? versions;
}

class SyncTenant {
  const SyncTenant({
    required this.id,
    required this.name,
    this.logo,
    this.email,
    this.phone,
    this.address,
    this.metaJson,
    this.isActive,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String? logo;
  final String? email;
  final String? phone;
  final String? address;
  final String? metaJson;
  final bool? isActive;
  final DateTime? updatedAt;
}

class SyncBranch {
  const SyncBranch({
    required this.id,
    required this.tenantId,
    required this.name,
    this.code,
    this.address,
    this.metaJson,
    this.isActive,
    this.updatedAt,
  });

  final String id;
  final String tenantId;
  final String name;
  final String? code;
  final String? address;
  final String? metaJson;
  final bool? isActive;
  final DateTime? updatedAt;
}

class SyncFeature {
  const SyncFeature({
    required this.id,
    required this.key,
    required this.name,
    this.category,
    this.type,
    this.metaJson,
    this.isActive,
    this.enabled,
    this.featureMetaJson,
  });

  final String id;
  final String key;
  final String name;
  final String? category;
  final String? type;
  final String? metaJson;
  final bool? isActive;
  final bool? enabled;
  final String? featureMetaJson;
}

class SyncMenu {
  const SyncMenu({
    required this.lastUpdatedAt,
    this.categories = const <SyncMenuCategory>[],
  });

  final DateTime? lastUpdatedAt;
  final List<SyncMenuCategory> categories;
}

class SyncMenuCategory {
  const SyncMenuCategory({
    required this.id,
    required this.name,
    this.displayOrder,
    this.subcategories = const <SyncMenuSubcategory>[],
  });

  final String id;
  final String name;
  final int? displayOrder;
  final List<SyncMenuSubcategory> subcategories;
}

class SyncMenuSubcategory {
  const SyncMenuSubcategory({
    required this.id,
    required this.name,
    this.items = const <SyncMenuItem>[],
  });

  final String id;
  final String name;
  final List<SyncMenuItem> items;
}

class SyncMenuItem {
  const SyncMenuItem({
    required this.id,
    required this.name,
    required this.type,
    this.isFavourite,
    this.foodType,
    this.variationRequired,
    this.availableIn = const <String>[],
    this.hsnCode,
    this.shortcutCode,
    this.shortcutNumber,
    this.metaJson,
    this.variations = const <SyncMenuVariation>[],
  });

  final String id;
  final String name;
  final String type;
  final bool? isFavourite;
  final String? foodType;
  final bool? variationRequired;
  final List<String> availableIn;
  final String? hsnCode;
  final String? shortcutCode;
  final int? shortcutNumber;
  final String? metaJson;
  final List<SyncMenuVariation> variations;
}

class SyncMenuVariation {
  const SyncMenuVariation({
    required this.id,
    required this.name,
    this.isDefault,
    this.priceContexts = const <SyncPriceContext>[],
    this.modifierGroups = const <SyncMenuModifierGroup>[],
    this.metaJson,
  });

  final String id;
  final String name;
  final bool? isDefault;
  final List<SyncPriceContext> priceContexts;
  final List<SyncMenuModifierGroup> modifierGroups;
  final String? metaJson;
}

class SyncMenuModifierGroup {
  const SyncMenuModifierGroup({
    required this.id,
    required this.name,
    this.required,
    this.minSelect,
    this.maxSelect,
    this.modifiers = const <SyncMenuModifier>[],
    this.metaJson,
  });

  final String id;
  final String name;
  final bool? required;
  final int? minSelect;
  final int? maxSelect;
  final List<SyncMenuModifier> modifiers;
  final String? metaJson;
}

class SyncMenuModifier {
  const SyncMenuModifier({
    required this.id,
    required this.name,
    this.availableIn = const <String>[],
    this.priceContexts = const <SyncPriceContext>[],
    this.metaJson,
  });

  final String id;
  final String name;
  final List<String> availableIn;
  final List<SyncPriceContext> priceContexts;
  final String? metaJson;
}

class SyncPriceContext {
  const SyncPriceContext({
    required this.context,
    required this.amountMinor,
    required this.currency,
    this.gstRateBp,
    this.gstMode,
  });

  final String context;
  final int amountMinor;
  final String currency;
  final int? gstRateBp;
  final String? gstMode;
}

class SyncTheme {
  const SyncTheme({
    this.mode,
    this.primaryColor,
    this.accentColor,
    this.light,
    this.dark,
    this.meta,
  });

  final String? mode;
  final String? primaryColor;
  final String? accentColor;
  final SyncThemePalette? light;
  final SyncThemePalette? dark;
  final Map<String, dynamic>? meta;
}

class SyncThemePalette {
  const SyncThemePalette({
    this.primary,
    this.accent,
    this.background,
    this.surface,
    this.text,
  });

  final String? primary;
  final String? accent;
  final String? background;
  final String? surface;
  final String? text;
}

class SyncAdmin {
  const SyncAdmin({
    required this.id,
    required this.name,
    this.role,
    this.passcode,
    this.isActive,
    this.metaJson,
  });

  final String id;
  final String name;
  final String? role;
  final String? passcode;
  final bool? isActive;
  final String? metaJson;
}

class SyncDevice {
  const SyncDevice({
    required this.name,
    required this.inputType,
    required this.posMode,
    this.defaultSubType,
    this.subTypes = const <SyncDeviceSubType>[],
    this.capabilities = const <String>[],
    this.metaJson,
  });

  final String name;
  final String inputType;
  final String posMode;
  final String? defaultSubType;
  final List<SyncDeviceSubType> subTypes;
  final List<String> capabilities;
  final String? metaJson;
}

class SyncDeviceSubType {
  const SyncDeviceSubType({
    required this.key,
    required this.label,
    required this.isDefault,
  });

  final String key;
  final String label;
  final bool isDefault;
}

class SyncDineIn {
  const SyncDineIn({
    this.floors = const <SyncDineInFloor>[],
  });

  final List<SyncDineInFloor> floors;
}

class SyncDineInFloor {
  const SyncDineInFloor({
    required this.id,
    required this.name,
    this.sections = const <SyncDineInSection>[],
    this.tables = const <SyncDineInTable>[],
  });

  final String id;
  final String name;
  final List<SyncDineInSection> sections;
  final List<SyncDineInTable> tables;
}

class SyncDineInSection {
  const SyncDineInSection({
    required this.id,
    required this.name,
    this.tables = const <SyncDineInTable>[],
  });

  final String id;
  final String name;
  final List<SyncDineInTable> tables;
}

class SyncDineInTable {
  const SyncDineInTable({
    required this.id,
    required this.name,
    required this.capacity,
    this.status,
    this.attributes = const <String>[],
  });

  final String id;
  final String name;
  final int capacity;
  final String? status;
  final List<String> attributes;
}

class SyncSectionsChanged {
  const SyncSectionsChanged({
    this.menu,
    this.theme,
    this.features,
    this.admins,
  });

  final bool? menu;
  final bool? theme;
  final bool? features;
  final bool? admins;
}

class SyncVersions {
  const SyncVersions({
    this.menu,
    this.theme,
    this.features,
    this.admins,
    this.lastChangedAt,
  });

  final int? menu;
  final int? theme;
  final int? features;
  final int? admins;
  final DateTime? lastChangedAt;
}

abstract class SyncRepository {
  Future<SyncResult> bootstrap(Session session);
}
