import '../../../core/api/api_client.dart';
import '../../../core/data/herd_models.dart';

/// Lot endpoints beyond the list and create calls of `HerdApi`.
class LotsApi {
  const LotsApi(this._client);

  final ApiClient _client;

  /// Sends only the fields that change: the API keeps the stored value of a null field.
  /// 422 when the target is not positive.
  Future<Lot> updateLot(String id, {String? name, double? gmdTarget}) async {
    final json = await _client.put('/lotes/$id', body: {
      'nombre': ?name,
      'gmd_objetivo': ?gmdTarget,
    });
    return Lot.fromJson(json as Map<String, Object?>);
  }
}
