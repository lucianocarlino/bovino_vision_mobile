# BovinoVision — Mobile

Aplicación móvil del sistema BovinoVision (captura fotográfica, estimación de peso bovino por visión artificial y trazabilidad offline-first), construida con **Flutter + Dart**.

Este componente está diseñado específicamente para operarios y veterinarios en entornos rurales con conectividad nula o intermitente, permitiendo registrar sesiones de pesaje biométrico en campo y encolar las transacciones para su sincronización automática con el backend.

---

## Arquitectura

El código fuente reside en `lib/`, estructurado bajo el patrón **Feature-First** combinado con principios de **Clean Architecture** para desacoplar presentación, lógica y persistencia local:

```text
lib/
├── core/                           # Fundamentos transversales de la aplicación
│   ├── database/                   # Persistencia local relacional (SQLite / sqflite)
│   │   ├── app_database.dart       # Singleton gestor de conexión y ciclo de vida de la BD
│   │   └── database_tables.dart    # Definición formal de esquemas DDL y llaves foráneas
│   ├── router/                     # Enrutamiento declarativo centralizado (GoRouter)
│   │   └── app_router.dart         # Definición de rutas (/ , /capture, /traceability, /sync)
│   └── theme/                      # Sistema de diseño y ergonomía visual para campo
│       ├── app_colors.dart         # Paleta de alto contraste para visibilidad bajo luz solar
│       └── app_theme.dart          # Configuración Material 3 (tipografía, tarjetas, botones)
├── features/                       # Módulos funcionales del sistema
│   └── home/                       # Dashboard principal del operario de campo
│       ├── data/                   # DTOs y modelos de datos
│       │   └── home_mock_data.dart # Modelos de usuario, métricas, estado de red y sesiones
│       └── presentation/           # Capa visual (UI)
│           ├── screens/            # Vistas principales (HomeScreen)
│           └── widgets/            # Componentes modulares reutilizables:
│               ├── capture_cta_button.dart   # Botón primario de disparo de sesión
│               ├── home_header.dart          # Perfil de usuario y estado de conexión
│               ├── metrics_grid.dart         # KPIs del rodeo (total, lotes, pesajes)
│               ├── recent_sessions_list.dart # Registro histórico de sesiones del día
│               └── sync_status_card.dart     # Monitor visual de cola SQLite/servidor
└── main.dart                       # Punto de entrada (configuración de bindings, orientación y tema)
```

### Decisiones de Arquitectura e Ingeniería

- **Offline-First Nativo:** La app no asume conectividad a Internet. Las operaciones se asientan primero en la base SQLite local (`bovino_vision_local.db`) y se encolan en la tabla `sync_queue` con patrón transaccional para resolverse asíncronamente cuando se detecte red.
- **Persistencia Relacional Local:** Se utiliza `sqflite` con llaves foráneas activadas (`PRAGMA foreign_keys = ON`) y cascada referencial para garantizar la integridad de datos entre `lotes`, `animals` y `captures`.
- **Enrutamiento Declarativo:** Implementado con `go_router`, facilitando el paso de parámetros fuertemente tipados, redirecciones por estado de sincronización y navegación desacoplada del `BuildContext`.
- **Diseño Ergonómico Rural:** Paleta cromática con alto contraste lumínico, fuentes legibles en exteriores y tarjetas con jerarquía clara para uso con una sola mano en manga o corral.

---

## Estado Actual del MVP

En esta etapa del proyecto se encuentran implementados:

- **Dashboard Principal de Campo:** Monitoreo en tiempo real de métricas del rodeo (total de animales, lotes activos y capturas del día).
- **Control de Conectividad y Sincronización:** Tarjeta de diagnóstico de estado de red (`Online` / `Offline`) y feedback visual del estado de sincronización local.
- **Historial de Sesiones Recientes:** Listado de sesiones de pesaje y sanidad con cantidad de animales procesados y marcas temporales.
- **Esquema de Base de Datos Local SQLite:** DDL de 4 tablas relacionales (`lotes`, `animals`, `captures`, `sync_queue`) preparadas para el almacenamiento en dispositivo.
- **Navegación Base:** Estructura de barra de navegación inferior (`NavigationBar` Material 3) para transicionar entre Inicio, Captura Móvil, Trazabilidad y Sincronización.

*Próximos incrementos planificados:* Integración directa con el sensor de cámara (`camera` package) con guía de encuadre perimetral, consumo de la API REST del backend (`POST /capturas`, `POST /pesajes`) y worker de sincronización en segundo plano.

---

## Requisitos

Para compilar y ejecutar la aplicación móvil se requiere:

- **Flutter SDK:** versión `3.16+` (verificado con Flutter `3.47.x` y Dart `3.13.x`).
- **Android Studio / VS Code** con los plugins oficiales de **Flutter** y **Dart** instalados.
- **Android SDK & Build-Tools** configurados (API 34+ recomendada).
- **Emulador Android** (AVD con imagen x86_64 o ARM64) o **Dispositivo físico Android** con modo depuración USB activado (ideal para validar rendimiento de interfaz y acceso a cámara).
- *(Opcional)* Backend de BovinoVision corriendo en `http://localhost:8000` si se desea validar interacción end-to-end.

---

## Cómo correrlo localmente

### 1. Verificar el entorno de desarrollo

Asegurate de que las herramientas de Flutter y la cadena de herramientas de Android estén en orden:

```bash
flutter doctor
```

### 2. Instalar dependencias

Desde la raíz de este repositorio (`bovino_vision_mobile`):

```bash
flutter pub get
```

### 3. Identificar dispositivos o emuladores disponibles

Listá los dispositivos activos o emuladores configurados en tu máquina:

```bash
flutter devices
```

Si necesitás iniciar un emulador desde la línea de comandos:

```bash
flutter emulators
flutter emulators --launch <nombre_del_emulador>
```

### 4. Ejecutar la aplicación

Lanzá la app en el dispositivo o emulador deseado:

```bash
# Ejecutar en el dispositivo por defecto
flutter run

# O especificar un target explícito (ej. emulador Android)
flutter run -d emulator-5554

# O ejecutar en modo Windows Desktop para desarrollo rápido de UI
flutter run -d windows
```

### Atajos útiles en la consola durante la ejecución:
- `r` — **Hot Reload** (recarga cambios en widgets en milisegundos sin perder estado).
- `R` — **Hot Restart** (reinicia la aplicación y resetea el estado en memoria).
- `p` — Alterna la visualización de guías de diseño (*debug painting*).
- `q` — Detiene la ejecución.

---

## Guía de Prueba para Evaluación (Testing Funcional)

Para que estudiantes o evaluadores de la carrera de Ingeniería en Sistemas puedan validar el comportamiento del sistema desarrollado:

1. **Inspección del Dashboard Principal:**
   - Observá la barra superior con el identificador del sistema y el botón de notificaciones que reporta el estado del motor SQLite local.
   - Verificá la tarjeta de usuario (`Francisco López`) con el avatar de iniciales (`FL`) y el badge verde de conectividad activa.
2. **Diagnóstico de Sincronización Offline:**
   - Hacé tap sobre el botón de sincronización dentro del banner verde (`Sincronización completa`).
   - Se disparará un `SnackBar` contextual que valida la integridad de la base local y notifica si hay transacciones pendientes en la cola.
3. **Métricas de Rodeo (KPIs):**
   - Verificá el grid de 3 métricas consolidadas: *Total Rodeo (1248)*, *Lotes Activos (6)* y *Capturas Hoy (42)*.
4. **Acción Primaria de Captura:**
   - Presioná el botón flotante/destacado **INICIAR CAPTURA**. Comprobá la respuesta visual y la validación de permisos de sesión de pesaje.
5. **Historial de Sesiones:**
   - Hacé tap en cualquiera de las tarjetas de sesiones recientes (*Lote Norte - Pesaje* o *Corral Central - Sanidad*). Se desplegará el detalle del lote y los animales procesados.
6. **Pull-to-Refresh:**
   - Deslizá la pantalla hacia abajo para ejecutar el gesto de actualización; el indicador recargará el estado y refrescará los indicadores en memoria.
7. **Navegación Inferior:**
   - Navegá entre las pestañas `Inicio`, `Captura`, `Trazabilidad` y `Sincronización` para observar el ruteo declarativo (`go_router`) y la delimitación modular de las próximas etapas.

---

## Persistencia Local y Esquema Relacional (SQLite)

La arquitectura offline-first se fundamenta en los esquemas definidos en `lib/core/database/database_tables.dart`:

| Tabla | Propósito de Negocio | Claves e Integridad |
| :--- | :--- | :--- |
| `lotes` | Catálogo de lotes o rodeos del establecimiento. | `id` (PK), control de auditoría y `sync_status`. |
| `animals` | Maestro de bovinos con caravana y último peso registrado. | `id` (PK), `caravana_id` (UNIQUE), `FK (lote_id) -> lotes(id) ON DELETE CASCADE`. |
| `captures` | Registro individual de cada pesaje biométrico por imagen. | `id` (PK), `peso_estimado`, `confianza`, `imagen_path`, `FKs -> animals, lotes`. |
| `sync_queue` | Cola de operaciones pendientes de transmisión al backend. | `id` (PK), `entity_type`, `action`, `payload` (JSON), `retry_count`, `status`. |

Para inspeccionar o depurar la base SQLite en el emulador Android podés usar:

```bash
adb shell "run-as com.example.bovino_vision_mobile ls -la /data/data/com.example.bovino_vision_mobile/databases/"
```

---

## Configuración de Red para Pruebas con backend

Cuando el backend (`bovino_vision_backend`) esté corriendo localmente en el puerto `8000`, la dirección IP de conexión varía según el dispositivo donde corra Flutter:

| Entorno de Ejecución Mobile | URL base para apuntar a la API FastAPI |
| :--- | :--- |
| **Android Emulator** | `http://10.0.2.2:8000` *(alias especial del host en el emulador de Google)* |
| **Dispositivo Android Físico** | `http://<IP_LOCAL_DE_TU_PC>:8000` *(ambos conectados a la misma red Wi-Fi)* |
| **Windows Desktop / Web** | `http://localhost:8000` |

---

## Tests

El proyecto cuenta con pruebas automatizadas de widgets y smoke tests que validan el correcto montaje del árbol de componentes y la visualización de datos críticos:

```bash
flutter test
```

Los tests ejecutan de forma aislada sin requerir un dispositivo físico ni emulador levantado, inicializando el árbol de widgets contra los mocks estáticos del dominio.

---

## Análisis de Código y Lint

El proyecto sigue estrictamente las directrices oficiales de estilo de Dart y Flutter:

```bash
flutter analyze
```

Las reglas están centralizadas en `analysis_options.yaml` extendiendo `package:flutter_lints/flutter.yaml`. Se requiere código libre de errores, warnings y deprecaciones antes de cada integración.
