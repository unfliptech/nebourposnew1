import 'package:dio/dio.dart';

import '../../../../../core/data/dio_client.dart';
import '../../../../../core/data/env.dart';
import '../../../domain/entities/session.dart';
import '../../models/session_model.dart';
import '../../services/device_registration_payload.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._client);

  final DioClient _client;

  Future<SessionModel> registerDevice(
    DeviceRegistrationPayload request,
  ) async {
    final response = await _client.instance.post<Map<String, dynamic>>(
      '/pos/device/register',
      data: request.toJson(),
      options: Options(
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'x-api-key': Env.apiKey,
        },
      ),
    );

    final body = response.data ?? const <String, dynamic>{};
    final data = (body['data'] as Map<String, dynamic>?) ?? body;
    return SessionModel.fromApi(data);
  }

  Future<void> logoutDevice(Session session) async {
    await _client.instance.post<void>(
      '/pos/device/logout',
      data: {
        'device_id': session.deviceId,
        'device_token': session.deviceToken,
      },
      options: Options(headers: _buildSecureHeaders(session)),
    );
  }

  Map<String, dynamic> _buildSecureHeaders(Session session) {
    return <String, dynamic>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'x-api-key': Env.apiKey,
      'x-tenant-id': session.tenantId,
      'x-branch-id': session.stationId,
      'x-device-token': session.deviceToken,
      'Authorization': '${session.tokenType} ${session.accessToken}',
    };
  }
}
