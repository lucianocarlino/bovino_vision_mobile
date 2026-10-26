# Rediseño de la app móvil y conexión con el backend

Objetivo: que la app Flutter se vea como la web de BovinoVision en el celular y que use la API .NET real en lugar de datos fijos.
Rama: `feat/rediseno-conexion-backend` (base `manu`). Entrega: un commit por unidad, sin push. Tests: `flutter test` + `flutter analyze`.
Referencias (solo lectura): `../bovino_vision_frontend` (rama `manu`, `src/index.css`, `src/components`, `src/features`) y `../bovino_vision_backend` (rama `manu`).

## Specs

- S1. "podemos rediseñar el frontend de la app para que sea más parecido al frontend web mobile de nuestro sistema BovinoVision?" → tokens del design system web (verde/marrón/crema, neutros, estados, sombras tintadas en verde), Montserrat empaquetada como asset (sin paquete), header blanco con logo y wordmark "Bovino"/"Vision" y botón de salir, barra inferior de 64 px con los ítems de la web filtrados por permisos (Captura, Rodeo, Lotes, Panel, Alertas).
- S2. "está pendiente conectar el front de la app con nuestro backend" → cliente HTTP (paquete `http`, aprobado) contra la API sin prefijo `/api`; URL por `--dart-define=API_URL=...` (por defecto `http://10.0.2.2:8000`); sesión con la cookie `bovinovision_sesion` reenviada en el header `Cookie`; errores ProblemDetails mostrando `detail`; 401 fuera del login cierra la sesión; HTTP plano habilitado en Android para desarrollo.
- S3. Login como la web: "Iniciar sesión", "Correo electrónico", "Contraseña", "Ingresar" / "Ingresando…"; la sesión se recuerda entre aperturas hasta `expira_en`.
- S4. Captura como la web: inicio con saludo, "Nueva captura", "Pesá sin arrear: 4 tomas y listo", "Sesiones recientes" (`GET /sesiones-captura`) y pastilla "En línea" / "Sin conexión"; asistente de 4 pasos (Animal, Foto, Estimación, Resultado) con `GET /animales?q=`, alta "Dar de alta “X”", `POST /capturas` multipart (`id_sesion`, `id_animal`, `imagen`), "Quitar foto", `POST /pesajes`, consulta de `GET /capturas/{id}` cada 1 s hasta `procesada`/`fallida`, `GET /pesajes/{id}`, "Confirmar y enviar" (`POST /capturas/{id}/confirmar`), "Tomar otra", "Tomar otra foto"; galería "Fotos de esta sesión".
- S5. Rodeo como la web: KPIs (Total animales, Peso promedio, GMD promedio, Alertas activas), búsqueda, chips "Todos / Lote X / Alertas", tarjetas con foto del último pesaje; ficha con KPIs, alertas, curva de crecimiento, pesajes e historial de lotes; alta de animal (`POST /animales`) con raza, sexo, nacimiento y lote.
- S6. Lotes: listado (`GET /lotes`) y alta (`POST /lotes`) con permiso `rodeo_gestionar`.
- S7. Decisión del usuario: "Online ahora (Recomendado)" — sin conexión se muestra "Sin conexión" y no se captura; se retira la sincronización simulada y los datos fijos. La cola offline queda para cuando el backend acepte ids generados por el cliente.
- Supuesto: Panel y Alertas solo aparecen con `analitica_consultar` (el Operario no lo tiene).

## Tasks

| ID | Specs | Ruta | Estado | Commit |
|----|-------|------|--------|--------|
| T1 | S1 | inline | hecho | 4bb92c9 |
| T2 | S2, S3, S7 | inline | hecho | 4bb92c9 |
| T3 | S4 | delegada (paralela con T4) | hecho | 29c19bc |
| T4 | S5, S6 | delegada (paralela con T3) | hecho | b3ef69f |
| T5 | S1, S7 | inline (limpieza, Panel/Alertas, tests de cierre) | hecho | 98ddeb4 + cierre |

Ruta: T3 y T4 son unidades independientes con superficies disjuntas (`lib/features/capture` vs `lib/features/rodeo` + `lib/features/lotes`), cada una de varios archivos → disparador de escritores en paralelo. T1/T2 son la base que ambas usan y se escriben inline primero.

Entrega: `single-pr` sobre la rama; commits por tarea. Riesgo: T2 toca autenticación (ítem 2) → verificador independiente al final.

## Log

- L1 (25/10/2026): "podemos rediseñar el frontend de la app para que sea más parecido al frontend web mobile de nuestro sistema BovinoVision? ademas, está pendiente conectar el front de la app con nuestro backend. Repos: bovino_vision_backend y bovino_vision_frontend"
- L2 (25/10/2026): el usuario eligió "Online ahora (Recomendado)" (incluye agregar `http`).
- L3: hallazgos de exploración — la app no hace ninguna llamada HTTP (la sync espera 700 ms y marca filas); el backend no tiene prefijo `/api`, escucha en 8000 y autentica solo por cookie `bovinovision_sesion` (`HttpOnly; Secure; SameSite=Strict`), sin CSRF ni chequeo de Origin, así que un cliente no navegador reenvía la cookie a mano; ids siempre generados en el servidor; el rol Operario de Campo no tiene `analitica_consultar`.
- L4: T1+T2 en un solo commit (`4bb92c9`) porque borrar las pantallas viejas era necesario para compilar con el tema nuevo. Base: `lib/core/{api,auth,data,format,network,router,theme,widgets}`, login, pantallas placeholder con los nombres de clase finales, helper `test/support/fake_api.dart` (`FakeApi`, `pumpApp`, `goTo`, `currentPath`). Multipart armado a mano para no sumar `http_parser`. Se quitaron `sqflite`, `path` y `camera` (sin uso). HTTP plano solo en los manifests de debug/profile. Evidencia: `flutter analyze` sin issues, `flutter test` 39/39.
- L5 (26/10/2026): los dos escritores se cortaron por el límite de uso y se retomaron. T4 entregado: `flutter test test/features/rodeo test/features/lots` 41/41 (repetido por el orquestador). Desvíos del escritor: tras "Agregar" vuelve al listado (como la web); no preselecciona el lote; búsqueda con debounce de 300 ms; el selector de fecha sale en inglés porque falta `flutter_localizations` (decisión pendiente del usuario: es un paquete del SDK pero agrega una entrada al pubspec). T5: Panel, Alertas, gráfico compartido `LineChartView` y README; `AlertCard` pasó de `Row` a `Wrap` porque desbordaba 31 px en 412 px de ancho. `analytics_test.dart` 10/10.
- L6 (26/10/2026): T3 entregado (`29c19bc`, 35 tests de captura). Chequeo de integración del orquestador: `flutter analyze` sin issues, `flutter test` 125/125, `flutter build apk --debug` OK.
- L7: verificador independiente (riesgo ítem 2, autenticación) con backend real sobre un Postgres descartable: S2–S7 PASS, S1 PARTIAL (solo revisión estática, sin dispositivo), sin bloqueantes. Prueba e2e con el `ApiClient`/`AuthController`/`CaptureApi` reales: login, cookie, sesión, 401 tras logout, 403 en `/panel` para el Operario, captura completa hasta `procesada` (400 kg) y confirmación. Advertencias: caché de `Image.network` por URL entre usuarios (corregida: se vacía al cerrar sesión, con test); un 401 en una imagen no cierra la sesión; el rol Administrador no tiene permisos de la app móvil; el backend acepta bytes arbitrarios rotulados como imagen.
- Pendiente de decisión del usuario: `flutter_localizations` (paquete del SDK) para que los selectores de fecha salgan en español.
