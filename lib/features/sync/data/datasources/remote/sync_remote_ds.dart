import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import '../../../../../core/data/dio_client.dart';
import '../../../../../core/data/env.dart';
import '../../../../auth/domain/entities/session.dart';

class SyncRemoteDataSource {
  SyncRemoteDataSource(this._client);

  final DioClient _client;

  Future<Response<Map<String, dynamic>>> sync({
    required Session session,
    required DateTime? lastSyncAt,
    List<Map<String, dynamic>> orders = const [],
    String? ifNoneMatch,
  }) {
    final headers = <String, dynamic>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'x-api-key': Env.apiKey,
      'x-tenant-id': session.tenantId,
      'x-branch-id': session.stationId,
      'x-device-token': session.deviceToken,
      'Authorization': '${session.tokenType} ${session.accessToken}',
      if (ifNoneMatch != null && ifNoneMatch.isNotEmpty)
        'If-None-Match': ifNoneMatch,
    };

    final body = {
      'device_id': session.deviceId,
      'station_id': session.stationId,
      'branch_id': session.stationId,
      'tenant_id': session.tenantId,
      'device_token': session.deviceToken,
      'last_sync_at': (lastSyncAt ?? DateTime.fromMillisecondsSinceEpoch(0))
          .toUtc()
          .toIso8601String(),
      'push': {
        'orders': orders,
        'payments': const [],
        'voided_orders': const [],
      },
    };

    developer.log('🚀 [SYNC REQUEST] POST /pos/sync');
    developer.log('Headers: $headers');
    developer.log('Body: $body');

    return _client.instance.post<Map<String, dynamic>>(
      '/pos/sync',
      data: body,
      options: Options(headers: headers),
    );
  }
}
