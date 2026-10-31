enum AppMode { demo, live }

abstract final class ApiConfig {
  static const defaultBaseUrl = String.fromEnvironment(
    'NUMPE_API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api',
  );
}
