import '../api/api_client.dart';
import 'herd_models.dart';

List<Map<String, Object?>> _list(Object? json) => (json as List).cast<Map<String, Object?>>();

/// Animals, lots and breeds: the herd endpoints shared by capture and rodeo.
class HerdApi {
  const HerdApi(this._client);

  final ApiClient _client;

  Future<List<Animal>> animals({String? lotId, String? query, bool? withActiveAlerts}) async {
    final json = await _client.get('/animales', query: {
      'id_lote': lotId,
      'q': (query == null || query.trim().isEmpty) ? null : query.trim(),
      'con_alertas_activas': withActiveAlerts,
    });
    return _list(json).map(Animal.fromJson).toList();
  }

  Future<Animal> animal(String id) async =>
      Animal.fromJson(await _client.get('/animales/$id') as Map<String, Object?>);

  /// 409 when the identifier already exists; 422 when it is blank.
  Future<Animal> createAnimal(NewAnimal animal) async =>
      Animal.fromJson(await _client.post('/animales', body: animal.toJson()) as Map<String, Object?>);

  Future<List<Lot>> lots() async => _list(await _client.get('/lotes')).map(Lot.fromJson).toList();

  /// 409 when the code already exists.
  Future<Lot> createLot({required String code, String? name, double? gmdTarget}) async {
    final json = await _client.post('/lotes', body: {
      'codigo': code.trim(),
      'nombre': (name == null || name.trim().isEmpty) ? null : name.trim(),
      'gmd_objetivo': gmdTarget,
    });
    return Lot.fromJson(json as Map<String, Object?>);
  }

  Future<List<Breed>> breeds() async => _list(await _client.get('/razas')).map(Breed.fromJson).toList();

  Future<List<Alert>> animalAlerts(String animalId) async =>
      _list(await _client.get('/animales/$animalId/alertas')).map(Alert.fromJson).toList();

  /// Active alerts of the whole establishment; needs `analitica_consultar`.
  Future<List<Alert>> activeAlerts() async => _list(await _client.get('/alertas')).map(Alert.fromJson).toList();

  /// 409 when the alert was already resolved; needs `rodeo_gestionar`.
  Future<void> resolveAlert(String alertId) => _client.post('/alertas/$alertId/resolver');
}
