import 'dart:convert';
import 'dart:developer' as developer;

import '../../../../core/data/secure_storage.dart';
import '../../../../core/data/storage_keys.dart';
import '../../../auth/domain/entities/session.dart';
import '../../domain/mappers/sync_snapshot_mapper.dart';
import '../../domain/repositories/sync_repository.dart';
import '../datasources/local/meta_local_ds.dart';
import '../datasources/remote/sync_remote_ds.dart';
import '../models/sync_snapshot.dart';

class SyncRepositoryImpl implements SyncRepository {
  SyncRepositoryImpl(
    this._remote,
    this._metaLocal,
    this._storage,
  );

  final SyncRemoteDataSource _remote;
  final MetaLocalDataSource _metaLocal;
  final SecureStorage _storage;

  @override
  Future<SyncResult> bootstrap(Session session) async {
    final lastSync = _metaLocal.lastSyncAt;
    final existingSnapshot = _metaLocal.readSnapshot();
    final ifNoneMatch = await _storage.read(StorageKeys.syncEtag);

    final response = await _remote.sync(
      session: session,
      lastSyncAt: lastSync,
      ifNoneMatch: ifNoneMatch,
    );

    final etagHeader =
        response.headers.value('etag') ?? response.headers.value('ETag');
    if (etagHeader != null && etagHeader.isNotEmpty) {
      await _storage.write(StorageKeys.syncEtag, etagHeader);
    }

    if (response.statusCode == 304) {
      if (existingSnapshot != null) {
        developer
            .log('[SYNC] Not modified (304) -> using cached snapshot data');
        final cached = existingSnapshot.toDomainResult();
        return SyncResult(
          syncedAt: cached.syncedAt,
          status: 'not_modified',
          apiVersion: cached.apiVersion,
          schemaVersion: cached.schemaVersion,
          dataVersion: cached.dataVersion,
          tenant: cached.tenant,
          branch: cached.branch,
          features: List<SyncFeature>.from(cached.features),
          menu: cached.menu,
          theme: cached.theme,
          admins: List<SyncAdmin>.from(cached.admins),
          device: cached.device,
          dineIn: cached.dineIn,
          sectionsChanged: cached.sectionsChanged,
          versions: cached.versions,
        );
      }
      final now = DateTime.now().toUtc();
      return SyncResult(
        syncedAt: now,
        status: 'not_modified',
        apiVersion: null,
        schemaVersion: null,
        dataVersion: null,
        tenant: null,
        branch: null,
        features: const <SyncFeature>[],
        menu: null,
        theme: null,
        admins: const <SyncAdmin>[],
        device: null,
        dineIn: null,
        sectionsChanged: null,
        versions: null,
      );
    }

    if (response.statusCode != null &&
        response.statusCode! >= 400 &&
        response.statusCode != 200) {
      throw SyncFailureException(
        'Unexpected status code ${response.statusCode}',
      );
    }

    final body = response.data ?? const <String, dynamic>{};
    final payload = Map<String, dynamic>.from(body);
    final dataSection = _asMap(payload['data']);

    developer.log('[SYNC] Received keys: ${payload.keys}');

    final status = _string(payload['status']) ?? 'success';
    if (status.toLowerCase() == 'error') {
      final message =
          _string(payload['message']) ?? 'Sync failed due to server error.';
      throw SyncFailureException(message);
    }

    final syncedAt = _parseDateTime(
          payload['syncedAt'] ??
              payload['synced_at'] ??
              payload['serverTime'] ??
              payload['server_time'],
        ) ??
        DateTime.now().toUtc();

    final snapshot = SyncSnapshot()
      ..status = status
      ..apiVersion = _string(payload['apiVersion'])
      ..schemaVersion = _parseInt(payload['schemaVersion'])
      ..dataVersion = _parseInt(payload['dataVersion'])
      ..syncedAt = syncedAt
      ..tenant = _parseTenant(payload['tenant'] ?? dataSection?['tenant'])
      ..branch = _parseBranch(payload['branch'] ?? dataSection?['branch'])
      ..device = _parseDevice(payload['device'] ?? dataSection?['device'])
      ..features = _parseFeatures(
        payload['features'] ?? dataSection?['features'],
      )
      ..theme = _parseTheme(payload['theme'] ?? dataSection?['theme'])
      ..admins = _parseAdmins(payload['admins'] ?? dataSection?['admins'])
      ..menu = _parseMenu(payload['menu'] ?? dataSection?['menu'])
      ..dineIn = _parseDineIn(payload['dineIn'] ??
          payload['dine_in'] ??
          dataSection?['dineIn'] ??
          dataSection?['dine_in'])
      ..sectionsChanged = _parseSectionsChanged(
        payload['sectionsChanged'] ?? dataSection?['sectionsChanged'],
      )
      ..versions = _parseVersions(
        payload['versions'] ?? dataSection?['versions'],
      );

    developer.log(
      '[SYNC] Parsed snapshot '
      'status=${snapshot.status} '
      'syncedAt=${snapshot.syncedAt} '
      'features=${snapshot.features.length} '
      'admins=${snapshot.admins.length} '
      'categories=${snapshot.menu?.categories.length ?? 0}',
    );

    await _metaLocal.saveSnapshot(snapshot);
    await _storage.write(
      StorageKeys.lastSyncAt,
      snapshot.syncedAt?.toIso8601String() ?? '',
    );

    await _persistPublicKey(payload['security'] ?? dataSection?['security']);

    final result = snapshot.toDomainResult();
    developer.log(
      '[SYNC] Snapshot saved '
      'tenant=${result.tenant?.name} '
      'branch=${result.branch?.name} '
      'menuCategories=${result.menu?.categories.length ?? 0}',
    );
    return result;
  }

  Future<void> _persistPublicKey(dynamic securityRaw) async {
    final security = _asMap(securityRaw);
    if (security == null) return;
    final newKey = _string(security['publicKey'])?.trim();
    if (newKey == null || newKey.isEmpty) return;

    final currentKey = await _storage.read(StorageKeys.syncPublicKey);
    if (currentKey != null && currentKey.isNotEmpty && currentKey != newKey) {
      await _storage.write(StorageKeys.syncPublicKeyPrevious, currentKey);
    }
    if (currentKey != newKey) {
      await _storage.write(StorageKeys.syncPublicKey, newKey);
    }
  }

  TenantInfo? _parseTenant(dynamic raw) {
    final map = _asMap(raw);
    if (map == null || map.isEmpty) return null;
    return TenantInfo()
      ..id = _string(map['id'])
      ..name = _string(map['name'])
      ..logo = _string(map['logo'])
      ..email = _string(map['email'])
      ..phone = _string(map['phone'])
      ..address = _string(map['address'])
      ..metaJson = _encodeJson(map['meta'])
      ..isActive = _parseBool(map['isActive'] ?? map['is_active'])
      ..updatedAt = _parseDateTime(map['updatedAt'] ?? map['updated_at']);
  }

  BranchInfo? _parseBranch(dynamic raw) {
    final map = _asMap(raw);
    if (map == null || map.isEmpty) return null;
    return BranchInfo()
      ..id = _string(map['id'])
      ..tenantId = _string(map['tenantId'] ?? map['tenant_id'])
      ..name = _string(map['name'])
      ..code = _string(map['code'])
      ..address = _string(map['address'])
      ..metaJson = _encodeJson(map['meta'])
      ..isActive = _parseBool(map['isActive'] ?? map['is_active'])
      ..updatedAt = _parseDateTime(map['updatedAt'] ?? map['updated_at']);
  }

  DeviceInfo? _parseDevice(dynamic raw) {
    final map = _asMap(raw);
    if (map == null || map.isEmpty) return null;
    final info = DeviceInfo()
      ..name = _string(map['name'])
      ..inputType = _string(map['inputType'] ?? map['input_type'])
      ..posMode = _string(map['posMode'] ?? map['pos_mode'])
      ..defaultSubType = _string(map['defaultSubType'] ?? map['default_sub_type'])
      ..metaJson = _encodeJson(map['meta']);
    info.capabilities = _stringList(map['capabilities']);
    info.subTypes = _asList(map['subTypes'] ?? map['sub_type'])
        .map((entry) {
          final subtype = _asMap(entry);
          if (subtype == null) return null;
          return DeviceSubTypeInfo()
            ..key = _string(subtype['key'])
            ..label = _string(subtype['label'])
            ..isDefault =
                _parseBool(subtype['isDefault'] ?? subtype['is_default']);
        })
        .whereType<DeviceSubTypeInfo>()
        .toList();
    return info;
  }

  List<FeatureInfo> _parseFeatures(dynamic raw) {
    final list = _asList(raw);
    if (list.isEmpty) return <FeatureInfo>[];
    return list
        .map((entry) {
          final map = _asMap(entry);
          if (map == null) return null;
          return FeatureInfo()
            ..id = _string(map['id'])
            ..key = _string(map['key'])
            ..name = _string(map['name'])
            ..category = _string(map['category'])
            ..type = _string(map['type'])
            ..isActive = _parseBool(map['isActive'] ?? map['is_active'])
            ..enabled = _parseBool(map['enabled'])
            ..metaJson = _encodeJson(map['meta'])
            ..featureMetaJson = _encodeJson(map['featureMeta'] ?? map['feature_meta']);
        })
        .whereType<FeatureInfo>()
        .toList();
  }

  ThemePayload? _parseTheme(dynamic raw) {
    final map = _asMap(raw);
    if (map == null || map.isEmpty) return null;
    return ThemePayload()
      ..mode = _string(map['mode'])
      ..light = _parseThemePalette(map['light'])
      ..dark = _parseThemePalette(map['dark'])
      ..metaJson = _encodeJson(map['meta']);
  }

  ThemePalette? _parseThemePalette(dynamic raw) {
    final map = _asMap(raw);
    if (map == null || map.isEmpty) return null;
    return ThemePalette()
      ..primary = _string(map['primary'])
      ..accent = _string(map['accent'])
      ..background = _string(map['background'])
      ..surface = _string(map['surface'])
      ..text = _string(map['text']);
  }

  List<AdminInfo> _parseAdmins(dynamic raw) {
    final list = _asList(raw);
    if (list.isEmpty) return <AdminInfo>[];
    return list
        .map((entry) {
          final map = _asMap(entry);
          if (map == null) return null;
          return AdminInfo()
            ..id = _string(map['id'])
            ..name = _string(map['name'])
            ..role = _string(map['role'])
            ..isActive = _parseBool(map['isActive'] ?? map['is_active'])
            ..passcode = _string(map['passcode'])
            ..metaJson = _encodeJson(map['meta']);
        })
        .whereType<AdminInfo>()
        .toList();
  }

  MenuPayload? _parseMenu(dynamic raw) {
    final map = _asMap(raw);
    if (map == null || map.isEmpty) return null;
    final payload = MenuPayload()
      ..lastUpdatedAt =
          _parseDateTime(map['lastUpdatedAt'] ?? map['last_updated_at']);
    payload.categories = _asList(map['categories'])
        .map(_parseMenuCategory)
        .whereType<MenuCategoryPayload>()
        .toList();
    return payload;
  }

  MenuCategoryPayload? _parseMenuCategory(dynamic raw) {
    final map = _asMap(raw);
    if (map == null || map.isEmpty) return null;
    final category = MenuCategoryPayload()
      ..id = _string(map['id'])
      ..name = _string(map['name'])
      ..displayOrder = _parseInt(map['displayOrder'] ?? map['display_order']);
    category.subcategories = _asList(map['subcategories'])
        .map(_parseMenuSubcategory)
        .whereType<MenuSubcategoryPayload>()
        .toList();
    return category;
  }

  MenuSubcategoryPayload? _parseMenuSubcategory(dynamic raw) {
    final map = _asMap(raw);
    if (map == null || map.isEmpty) return null;
    final subcategory = MenuSubcategoryPayload()
      ..id = _string(map['id'])
      ..name = _string(map['name']);
    subcategory.items = _asList(map['items'])
        .map(_parseMenuItem)
        .whereType<MenuItemPayload>()
        .toList();
    return subcategory;
  }

  MenuItemPayload? _parseMenuItem(dynamic raw) {
    final map = _asMap(raw);
    if (map == null || map.isEmpty) return null;
    final item = MenuItemPayload()
      ..id = _string(map['id'])
      ..name = _string(map['name'])
      ..isFavourite = _parseBool(map['isFavourite'] ?? map['is_favourite'])
      ..foodType = _string(map['foodType'] ?? map['food_type'])
      ..type = _string(map['type'])
      ..variationRequired =
          _parseBool(map['variationRequired'] ?? map['variation_required'])
      ..hsnCode = _string(map['hsnCode'] ?? map['hsn_code'])
      ..shortcutCode = _string(map['shortcutCode'] ?? map['shortcut_code'])
      ..shortcutNumber =
          _parseInt(map['shortcutNumber'] ?? map['shortcut_number'])
      ..metaJson = _encodeJson(map['meta']);
    item.availableIn = _stringList(map['availableIn'] ?? map['available_in']);
    item.variations = _asList(map['variations'])
        .map(_parseMenuVariation)
        .whereType<MenuVariationPayload>()
        .toList();
    return item;
  }

  MenuVariationPayload? _parseMenuVariation(dynamic raw) {
    final map = _asMap(raw);
    if (map == null || map.isEmpty) return null;
    final variation = MenuVariationPayload()
      ..id = _string(map['id'])
      ..name = _string(map['name'])
      ..isDefault = _parseBool(map['isDefault'] ?? map['is_default'])
      ..metaJson = _encodeJson(map['meta']);
    variation.priceContexts = _asList(map['priceContexts'] ?? map['price_contexts'])
        .map(_parsePriceContext)
        .whereType<MenuPriceContextPayload>()
        .toList();
    variation.modifierGroups =
        _asList(map['modifierGroups'] ?? map['modifier_groups'])
            .map(_parseModifierGroup)
            .whereType<MenuModifierGroupPayload>()
            .toList();
    return variation;
  }

  MenuModifierGroupPayload? _parseModifierGroup(dynamic raw) {
    final map = _asMap(raw);
    if (map == null || map.isEmpty) return null;
    final group = MenuModifierGroupPayload()
      ..id = _string(map['id'])
      ..name = _string(map['name'])
      ..required = _parseBool(map['required'])
      ..minSelect = _parseInt(map['minSelect'] ?? map['min_select'])
      ..maxSelect = _parseInt(map['maxSelect'] ?? map['max_select'])
      ..metaJson = _encodeJson(map['meta']);
    group.modifiers = _asList(map['modifiers'])
        .map(_parseModifier)
        .whereType<MenuModifierPayload>()
        .toList();
    return group;
  }

  MenuModifierPayload? _parseModifier(dynamic raw) {
    final map = _asMap(raw);
    if (map == null || map.isEmpty) return null;
    final modifier = MenuModifierPayload()
      ..id = _string(map['id'])
      ..name = _string(map['name'])
      ..metaJson = _encodeJson(map['meta']);
    modifier.availableIn =
        _stringList(map['availableIn'] ?? map['available_in']);
    modifier.priceContexts = _asList(map['priceContexts'] ?? map['price_contexts'])
        .map(_parsePriceContext)
        .whereType<MenuPriceContextPayload>()
        .toList();
    return modifier;
  }

  MenuPriceContextPayload? _parsePriceContext(dynamic raw) {
    final map = _asMap(raw);
    if (map == null || map.isEmpty) return null;
    return MenuPriceContextPayload()
      ..context = _string(map['context'])
      ..amountMinor = _parseInt(map['amountMinor'] ?? map['amount_minor'])
      ..currency = _string(map['currency'])
      ..gstRateBp = _parseInt(map['gstRateBp'] ?? map['gst_rate_bp'])
      ..gstMode = _string(map['gstMode'] ?? map['gst_mode']);
  }

  DineInPayload? _parseDineIn(dynamic raw) {
    final map = _asMap(raw);
    if (map == null || map.isEmpty) return null;
    final payload = DineInPayload();
    payload.floors = _asList(map['floors'])
        .map(_parseDineInFloor)
        .whereType<DineInFloorPayload>()
        .toList();
    return payload;
  }

  DineInFloorPayload? _parseDineInFloor(dynamic raw) {
    final map = _asMap(raw);
    if (map == null || map.isEmpty) return null;
    final floor = DineInFloorPayload()
      ..id = _string(map['id'])
      ..name = _string(map['name']);
    floor.sections = _asList(map['sections'])
        .map(_parseDineInSection)
        .whereType<DineInSectionPayload>()
        .toList();
    floor.tables = _asList(map['tables'])
        .map(_parseDineInTable)
        .whereType<DineInTablePayload>()
        .toList();
    return floor;
  }

  DineInSectionPayload? _parseDineInSection(dynamic raw) {
    final map = _asMap(raw);
    if (map == null || map.isEmpty) return null;
    final section = DineInSectionPayload()
      ..id = _string(map['id'])
      ..name = _string(map['name']);
    section.tables = _asList(map['tables'])
        .map(_parseDineInTable)
        .whereType<DineInTablePayload>()
        .toList();
    return section;
  }

  DineInTablePayload? _parseDineInTable(dynamic raw) {
    final map = _asMap(raw);
    if (map == null || map.isEmpty) return null;
    final table = DineInTablePayload()
      ..id = _string(map['id'])
      ..name = _string(map['name'])
      ..capacity = _parseInt(map['capacity'])
      ..status = _string(map['status'])
      ..attributes = _stringList(map['attributes']);
    return table;
  }

  SectionsChangedPayload? _parseSectionsChanged(dynamic raw) {
    final map = _asMap(raw);
    if (map == null || map.isEmpty) return null;
    return SectionsChangedPayload()
      ..menu = _parseBool(map['menu'])
      ..theme = _parseBool(map['theme'])
      ..features = _parseBool(map['features'])
      ..admins = _parseBool(map['admins']);
  }

  VersionsPayload? _parseVersions(dynamic raw) {
    final map = _asMap(raw);
    if (map == null || map.isEmpty) return null;
    return VersionsPayload()
      ..menu = _parseInt(map['menu'])
      ..theme = _parseInt(map['theme'])
      ..features = _parseInt(map['features'])
      ..admins = _parseInt(map['admins'])
      ..lastChangedAt =
          _parseDateTime(map['lastChangedAt'] ?? map['last_changed_at']);
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      try {
        return value.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      } catch (_) {
        return Map<String, dynamic>.from(
          Map<dynamic, dynamic>.from(value),
        );
      }
    }
    return null;
  }

  List<dynamic> _asList(dynamic value) {
    if (value is List) return value;
    return const <dynamic>[];
  }

  String? _string(dynamic value) {
    if (value == null) return null;
    final stringValue = value.toString();
    return stringValue.isEmpty ? null : stringValue;
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  bool? _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.toLowerCase().trim();
      if (normalized == 'true' || normalized == '1') return true;
      if (normalized == 'false' || normalized == '0') return false;
    }
    return null;
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toUtc();
    if (value is String && value.isNotEmpty) {
      try {
        return DateTime.parse(value).toUtc();
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  List<String> _stringList(dynamic value) {
    final list = _asList(value);
    if (list.isEmpty) return <String>[];
    return list
        .map((entry) => _string(entry))
        .whereType<String>()
        .toList(growable: false);
  }

  String? _encodeJson(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : value;
    try {
      return jsonEncode(value);
    } catch (_) {
      return value.toString();
    }
  }
}

class LoggedOutException implements Exception {
  const LoggedOutException();
}

class SyncFailureException implements Exception {
  SyncFailureException(this.message);
  final String message;
  @override
  String toString() => 'SyncFailureException: $message';
}
