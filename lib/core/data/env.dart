class Env {
  static const apiBase = String.fromEnvironment('API_BASE',
      defaultValue: 'http://127.0.0.1:8000/api/v1');
  static const orgId =
      String.fromEnvironment('ORG_ID', defaultValue: 'demo-branch');
  static const apiKey = String.fromEnvironment(
    'API_KEY',
    defaultValue: '3f1b2a76-9d84-4a6b-bc5f-9f02d4a35c21',
  );
  static const pingIntervalSec = 60;
}
