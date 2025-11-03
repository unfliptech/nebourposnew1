import 'dart:async';

import 'package:dio/dio.dart';

class DioClient {
  DioClient({
    Dio? dio,
    required this.baseUrl,
    Future<String?> Function()? authHeaderProvider,
  })  : _authHeaderProvider = authHeaderProvider,
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl,
                connectTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(seconds: 30),
                validateStatus: (status) {
                  if (status == null) return false;
                  if (status == 304) return true;
                  return status >= 200 && status < 300;
                },
              ),
            ) {
    if (_authHeaderProvider != null) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            if (!options.headers.containsKey('Authorization')) {
              final header = await _resolveAuthHeader();
              if (header != null && header.isNotEmpty) {
                options.headers['Authorization'] = header;
              }
            }
            handler.next(options);
          },
        ),
      );
    }
  }

  final String baseUrl;
  final Dio _dio;
  final Future<String?> Function()? _authHeaderProvider;

  Dio get instance => _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<String?> _resolveAuthHeader() async {
    final provider = _authHeaderProvider;
    if (provider == null) {
      return null;
    }
    try {
      final header = await provider.call();
      return header?.trim();
    } catch (_) {
      return null;
    }
  }
}
