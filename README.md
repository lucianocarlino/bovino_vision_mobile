# BovinoVision — Mobile

Aplicación móvil del sistema BovinoVision para el operario de campo: captura fotográfica, estimación de peso y consulta del rodeo. Está construida con **Flutter + Dart** y consume la API .NET de [`bovino_vision_backend`](../bovino_vision_backend).

El diseño copia la vista de celular de la web ([`bovino_vision_frontend`](../bovino_vision_frontend)). Usa los mismos tokens de color (verde para acciones y marca, marrón para el contexto del animal, fondo crema, sombras tintadas en verde), la tipografía Montserrat y los mismos componentes (tiles KPI, tarjetas, chips y asistente por pasos). La navegación es una barra inferior filtrada por los permisos del rol.

---

## Pantallas

| Sección | Ruta | Permiso | Qué hace |
| :--- | :--- | :--- | :--- |
| Login | `/login` | — | `POST /auth/sesion`; la sesión se recuerda hasta `expira_en` |
| Captura | `/captura`, `/captura/nueva` | `capturas_registrar` | Inicio con sesiones recientes y asistente de 4 pasos: animal, foto, estimación y resultado |
| Rodeo | `/animales`, `/animales/nuevo`, `/animales/:id` | `rodeo_consultar` | Listado con KPIs y filtros, alta de animal y ficha con pesajes, alertas y lotes |
| Lotes | `/lotes` | `rodeo_consultar` | Listado y alta de lotes (el alta requiere `rodeo_gestionar`) |
| Panel | `/panel` | `analitica_consultar` | KPIs, evolución de peso, alertas críticas, composición y reporte por período |
| Alertas | `/alertas` | `analitica_consultar` | Alertas activas; resolverlas requiere `rodeo_gestionar` |

El rol **Operario de Campo** ve Captura, Rodeo y Lotes. Usuarios y roles se administran desde la web.

**Sin conexión:** la app es *online*. Sin red o sin backend muestra "Sin conexión" y no permite capturar. La cola offline queda pendiente hasta que el backend acepte ids generados por el cliente, porque sin eso un reintento puede duplicar el pesaje.

---

## Arquitectura

```text
lib/
├── core/
│   ├── api/          # ApiClient (http + cookie de sesión), ApiException, ApiConfig (API_URL)
│   ├── auth/         # Session, SessionStore (archivo privado de la app), AuthController
│   ├── data/         # HerdApi y modelos compartidos: Animal, Lot, Breed, Alert
│   ├── format/       # Formatos argentinos (port de src/lib/formato.ts)
│   ├── network/      # ConnectivityService (interfaz de red + GET /health)
│   ├── router/       # go_router con redirecciones por sesión/permisos y AppShell
│   ├── theme/        # Tokens del design system y ThemeData
│   └── widgets/      # Botón, tarjeta, KPI, badge, avisos, gráfico de líneas, imagen de la API
├── features/
│   ├── auth/         # Login, splash y "sin acceso"
│   ├── capture/      # Inicio de captura y asistente
│   ├── rodeo/        # Listado, alta y ficha del animal
│   ├── lots/         # Lotes
│   ├── panel/        # Panel del rodeo
│   └── alerts/       # Alertas del rodeo
└── main.dart         # Inyección de dependencias (Provider) y MaterialApp.router
```

### Decisiones

- **Sesión por cookie reenviada a mano:** el backend autentica solo con la cookie `HttpOnly` `bovinovision_sesion` (no hay JWT ni bearer). Un cliente que no es navegador no tiene un almacén de cookies, así que `ApiClient` toma el token del `Set-Cookie` del login y lo envía en el header `Cookie`. El backend no exige CSRF ni chequea `Origin`, así que esto funciona igual que en la web. El token y la última sesión se guardan en el directorio de soporte privado de la app (`session.json`). Si la app abre sin red, confía en esa sesión hasta su vencimiento.
- **401 en cualquier pedido** (sesión vencida o revocada): se borra la sesión local y se vuelve al login con el aviso "Tu sesión terminó".
- **Errores:** las respuestas ProblemDetails se muestran con su `detail`; un fallo de red muestra "No se pudo conectar con el servidor. Revisá tu conexión.".
- **Fotos:** se toman con la cámara del sistema o la galería (`image_picker`) y se reducen a 1600 px y calidad JPEG 85, igual que la web. Se suben en multipart con el content type explícito, porque el backend lo valida. Las fotos guardadas se cargan desde `GET /imagenes/{id}` con la cookie de sesión.
- **Idioma:** la app fija el locale `es_AR` con `flutter_localizations`, así que los widgets de Material (por ejemplo el selector de fecha) aparecen en español y la fecha se escribe como `dd/mm/aaaa`.
- **Sin dependencias de UI externas:** Montserrat va como asset (`assets/fonts`, licencia OFL) y el gráfico está dibujado con `CustomPaint`.

---

## Requisitos

- Flutter `3.47.x` / Dart `3.13.x`.
- Android SDK (API 34+ recomendada), JDK 21 configurado en Flutter (`flutter config --jdk-dir`).
- Backend corriendo (ver el README de `bovino_vision_backend`): `docker compose up -d db` y `dotnet run --project src/BovinoVision.Api`. Escucha en el puerto `8000` y sus rutas no llevan prefijo `/api`. La semilla no crea un operario: creá uno desde la web con un administrador.

## Cómo correrlo

```bash
flutter pub get

# Emulador Android: 10.0.2.2 es el host de la PC (valor por defecto)
flutter run

# Celular físico en la misma red Wi-Fi: el backend debe escuchar en todas las interfaces
#   dotnet run --project src/BovinoVision.Api --urls http://0.0.0.0:8000
flutter run --dart-define=API_URL=http://<IP_DE_TU_PC>:8000
```

| Dónde corre la app | `API_URL` |
| :--- | :--- |
| Emulador Android | `http://10.0.2.2:8000` (por defecto) |
| Celular físico | `http://<IP_LOCAL_DE_TU_PC>:8000` |
| Backend publicado con HTTPS | `https://<host>` |

Las compilaciones de **debug y profile** permiten HTTP plano (`usesCleartextTraffic` en sus manifests). Una compilación **release** exige HTTPS, que es el comportamiento por defecto de Android.

En debug, la pantalla de login muestra la URL del servidor configurada para diagnosticar problemas de conexión.

---

## Tests y análisis

```bash
flutter analyze
flutter test
```

Los tests de widgets levantan la app completa contra una API falsa (`test/support/fake_api.dart`: `FakeApi`, `pumpApp`). Verifican pantallas, pedidos enviados (método, ruta, query, cuerpo y cookie), navegación y permisos sin emulador ni backend.
