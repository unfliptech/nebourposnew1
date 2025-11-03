import 'package:connectivity_plus/connectivity_plus.dart';

enum ConnectivityStatus {
  online,
  offline,
}

class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  Stream<ConnectivityStatus> get onStatusChange =>
      _connectivity.onConnectivityChanged.map(_mapResults);

  Future<ConnectivityStatus> checkStatus() async {
    final results = await _connectivity.checkConnectivity();
    return _mapResults(results);
  }

  ConnectivityStatus _mapResults(List<ConnectivityResult> results) {
    if (results.isEmpty) {
      return ConnectivityStatus.offline;
    }
    final hasOnline = results.any(
      (result) => switch (result) {
        ConnectivityResult.bluetooth || ConnectivityResult.none => false,
        _ => true,
      },
    );
    return hasOnline ? ConnectivityStatus.online : ConnectivityStatus.offline;
  }
}
