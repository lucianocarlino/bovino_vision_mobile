/// Backend base URL, set at build time:
/// `flutter run --dart-define=API_URL=http://192.168.0.10:8000`.
/// The default reaches a backend on the host machine from the Android emulator.
abstract final class ApiConfig {
  static const baseUrl = String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:8000');
}
