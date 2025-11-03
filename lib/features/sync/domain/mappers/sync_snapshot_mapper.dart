import '../../data/models/sync_snapshot.dart';
import '../repositories/sync_repository.dart';

extension SyncSnapshotMapper on SyncSnapshot {
  SyncResult toDomainResult() {
    return SyncResult(
      syncedAt: syncedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
      status: status ?? 'unknown',
      apiVersion: apiVersion,
      schemaVersion: schemaVersion,
      dataVersion: dataVersion,
      tenant: tenant?.toDomain(),
      branch: branch?.toDomain(),
      features: features.map((feature) => feature.toDomain()).toList(),
      menu: menu?.toDomain(),
      theme: theme?.toDomain(),
      admins: admins.map((admin) => admin.toDomain()).toList(),
      device: device?.toDomain(),
      dineIn: dineIn?.toDomain(),
      sectionsChanged: sectionsChanged?.toDomain(),
      versions: versions?.toDomain(),
    );
  }
}

extension _TenantInfoMapper on TenantInfo {
  SyncTenant toDomain() {
    return SyncTenant(
      id: id ?? '',
      name: name ?? '',
      logo: logo,
      email: email,
      phone: phone,
      address: address,
      metaJson: metaJson,
      isActive: isActive,
      updatedAt: updatedAt,
    );
  }
}

extension _BranchInfoMapper on BranchInfo {
  SyncBranch toDomain() {
    return SyncBranch(
      id: id ?? '',
      tenantId: tenantId ?? '',
      name: name ?? '',
      code: code,
      address: address,
      metaJson: metaJson,
      isActive: isActive,
      updatedAt: updatedAt,
    );
  }
}

extension _FeatureInfoMapper on FeatureInfo {
  SyncFeature toDomain() {
    return SyncFeature(
      id: id ?? '',
      key: key ?? '',
      name: name ?? '',
      category: category,
      type: type,
      metaJson: metaJson,
      isActive: isActive,
      enabled: enabled,
      featureMetaJson: featureMetaJson,
    );
  }
}

extension _DeviceInfoMapper on DeviceInfo {
  SyncDevice toDomain() {
    return SyncDevice(
      name: name ?? '',
      inputType: inputType ?? 'UNKNOWN',
      posMode: posMode ?? 'UNKNOWN',
      defaultSubType: defaultSubType,
      subTypes: subTypes
          .map(
            (subType) => SyncDeviceSubType(
              key: subType.key ?? '',
              label: subType.label ?? '',
              isDefault: subType.isDefault ?? false,
            ),
          )
          .toList(),
      capabilities: List<String>.from(capabilities),
      metaJson: metaJson,
    );
  }
}

extension _ThemePayloadMapper on ThemePayload {
  SyncTheme toDomain() {
    return SyncTheme(
      mode: mode,
      primaryColor: light?.primary,
      accentColor: light?.accent,
      light: light?.toDomain(),
      dark: dark?.toDomain(),
      meta: metaJson == null ? null : <String, dynamic>{'raw': metaJson},
    );
  }
}

extension _ThemePaletteMapper on ThemePalette {
  SyncThemePalette toDomain() {
    return SyncThemePalette(
      primary: primary,
      accent: accent,
      background: background,
      surface: surface,
      text: text,
    );
  }
}

extension _AdminInfoMapper on AdminInfo {
  SyncAdmin toDomain() {
    return SyncAdmin(
      id: id ?? '',
      name: name ?? '',
      role: role,
      passcode: passcode,
      isActive: isActive,
      metaJson: metaJson,
    );
  }
}

extension _MenuPayloadMapper on MenuPayload {
  SyncMenu toDomain() {
    return SyncMenu(
      lastUpdatedAt: lastUpdatedAt,
      categories: categories.map((category) => category.toDomain()).toList(),
    );
  }
}

extension _MenuCategoryPayloadMapper on MenuCategoryPayload {
  SyncMenuCategory toDomain() {
    return SyncMenuCategory(
      id: id ?? '',
      name: name ?? '',
      displayOrder: displayOrder,
      subcategories:
          subcategories.map((subcategory) => subcategory.toDomain()).toList(),
    );
  }
}

extension _MenuSubcategoryPayloadMapper on MenuSubcategoryPayload {
  SyncMenuSubcategory toDomain() {
    return SyncMenuSubcategory(
      id: id ?? '',
      name: name ?? '',
      items: items.map((item) => item.toDomain()).toList(),
    );
  }
}

extension _MenuItemPayloadMapper on MenuItemPayload {
  SyncMenuItem toDomain() {
    return SyncMenuItem(
      id: id ?? '',
      name: name ?? '',
      type: type ?? 'UNKNOWN',
      isFavourite: isFavourite,
      foodType: foodType,
      variationRequired: variationRequired,
      availableIn: List<String>.from(availableIn),
      hsnCode: hsnCode,
      shortcutCode: shortcutCode,
      shortcutNumber: shortcutNumber,
      metaJson: metaJson,
      variations: variations.map((variation) => variation.toDomain()).toList(),
    );
  }
}

extension _MenuVariationPayloadMapper on MenuVariationPayload {
  SyncMenuVariation toDomain() {
    return SyncMenuVariation(
      id: id ?? '',
      name: name ?? '',
      isDefault: isDefault,
      priceContexts:
          priceContexts.map((context) => context.toDomain()).toList(),
      modifierGroups:
          modifierGroups.map((group) => group.toDomain()).toList(),
      metaJson: metaJson,
    );
  }
}

extension _MenuModifierGroupPayloadMapper on MenuModifierGroupPayload {
  SyncMenuModifierGroup toDomain() {
    return SyncMenuModifierGroup(
      id: id ?? '',
      name: name ?? '',
      required: required,
      minSelect: minSelect,
      maxSelect: maxSelect,
      modifiers: modifiers.map((modifier) => modifier.toDomain()).toList(),
      metaJson: metaJson,
    );
  }
}

extension _MenuModifierPayloadMapper on MenuModifierPayload {
  SyncMenuModifier toDomain() {
    return SyncMenuModifier(
      id: id ?? '',
      name: name ?? '',
      availableIn: List<String>.from(availableIn),
      priceContexts:
          priceContexts.map((context) => context.toDomain()).toList(),
      metaJson: metaJson,
    );
  }
}

extension _MenuPriceContextPayloadMapper on MenuPriceContextPayload {
  SyncPriceContext toDomain() {
    return SyncPriceContext(
      context: context ?? '',
      amountMinor: amountMinor ?? 0,
      currency: currency ?? '',
      gstRateBp: gstRateBp,
      gstMode: gstMode,
    );
  }
}

extension _DineInPayloadMapper on DineInPayload {
  SyncDineIn toDomain() {
    return SyncDineIn(
      floors: floors.map((floor) => floor.toDomain()).toList(),
    );
  }
}

extension _DineInFloorPayloadMapper on DineInFloorPayload {
  SyncDineInFloor toDomain() {
    return SyncDineInFloor(
      id: id ?? '',
      name: name ?? '',
      sections: sections.map((section) => section.toDomain()).toList(),
      tables: tables.map((table) => table.toDomain()).toList(),
    );
  }
}

extension _DineInSectionPayloadMapper on DineInSectionPayload {
  SyncDineInSection toDomain() {
    return SyncDineInSection(
      id: id ?? '',
      name: name ?? '',
      tables: tables.map((table) => table.toDomain()).toList(),
    );
  }
}

extension _DineInTablePayloadMapper on DineInTablePayload {
  SyncDineInTable toDomain() {
    return SyncDineInTable(
      id: id ?? '',
      name: name ?? '',
      capacity: capacity ?? 0,
      status: status,
      attributes: List<String>.from(attributes),
    );
  }
}

extension _SectionsChangedPayloadMapper on SectionsChangedPayload {
  SyncSectionsChanged toDomain() {
    return SyncSectionsChanged(
      menu: menu,
      theme: theme,
      features: features,
      admins: admins,
    );
  }
}

extension _VersionsPayloadMapper on VersionsPayload {
  SyncVersions toDomain() {
    return SyncVersions(
      menu: menu,
      theme: theme,
      features: features,
      admins: admins,
      lastChangedAt: lastChangedAt,
    );
  }
}
