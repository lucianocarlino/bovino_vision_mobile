/// Mock de datos para el módulo Rodeo y Detalle de Animal
/// Respeta la estructura provista para el estado estático de la aplicación.
class RodeoMockData {
  static const Map<String, dynamic> rawJson = {
    "isOffline": false,
    "rodeoSummary": {
      "totalAnimals": 1248,
      "activeLotes": 6,
      "alerts": 3,
    },
    "animals": [
      {
        "id": "AR-339281-C",
        "lote": "A-12",
        "raza": "Aberdeen Angus",
        "peso": "452 kg",
        "estado": "Óptimo",
        "imagen": "assets/mock_cow1.jpg"
      },
      {
        "id": "AR-440192-K",
        "lote": "B-05",
        "raza": "Hereford",
        "peso": "388 kg",
        "estado": "Crecimiento",
        "imagen": "assets/mock_cow2.jpg"
      }
    ],
    "animalDetail": {
      "id": "AR-003421",
      "raza": "Aberdeen Angus",
      "sexo": "Macho",
      "edad": "24 meses",
      "lote": "A-12 - Potrero 4",
      "nacimiento": "15 mar 2022",
      "ultimoPeso": "482 kg",
      "imagen": "assets/mock_cow_detail.jpg"
    }
  };

  static bool get isOffline => rawJson["isOffline"] as bool;

  static Map<String, dynamic> get rodeoSummary =>
      rawJson["rodeoSummary"] as Map<String, dynamic>;

  static List<Map<String, dynamic>> get animals =>
      List<Map<String, dynamic>>.from(rawJson["animals"] as List);

  static Map<String, dynamic> get animalDetail =>
      rawJson["animalDetail"] as Map<String, dynamic>;
}
