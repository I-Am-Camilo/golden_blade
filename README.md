# Golden Blade

Aplicación académica creada con Flutter y Dart, con las plataformas Android e iOS indicadas por el profesor.

## Abrir en VS Code

1. Abre esta carpeta, `golden_blade`, en VS Code.
2. Ejecuta `flutter pub get` si necesitas preparar las dependencias.
3. Abre la extensión Flutter Phone Preview y presiona `Start preview`. El arranque hasta el login se comprobó en este equipo el 19/11/2026.
4. Como alternativa, la función `vistaPreviaGoldenBlade` de `lib/main.dart` prepara la aplicación para `Flutter: Show Widget Preview`.

Flutter Widget Preview genera su soporte interno en `.widget_preview/`. Es una herramienta distinta de la extensión Flutter Phone Preview. En este equipo Phone Preview logró ejecutar la aplicación sin una carpeta `web/` en la raíz, aunque Flutter muestra una advertencia sobre esa plataforma. La alternativa Widget Preview todavía necesita comprobarse de forma interactiva desde VS Code.

## Estructura del código

- `lib/main.dart`: inicio de la aplicación.
- `lib/config/`: dirección pública de la API.
- `lib/models/`: datos y solicitudes.
- `lib/routes/`: navegación.
- `lib/screens/`: pantallas.
- `lib/services/`: peticiones HTTP y sesión.
- `lib/theme/`: colores.
- `lib/widgets/`: componentes compartidos.
- `assets/`: imágenes.
- `android/` e `ios/`: soporte de las dos plataformas móviles.

`.dart_tool/`, `.widget_preview/` y `build/` contienen archivos generados por las herramientas. El código de las pantallas se programa en Dart dentro de `lib/`.

Al marcar «Recordar sesión», Shared Preferences guarda esa elección y Flutter Secure Storage guarda el token y su vencimiento. El splash recupera únicamente sesiones vigentes. Sin marcar la casilla, la sesión queda solo en memoria. Cerrar sesión o recibir un 401 elimina lo guardado; no se almacena la contraseña ni se renueva el token automáticamente.

En Flutter Phone Preview, la persistencia pertenece al navegador y origen local de esa vista: un cambio de puerto o limpiar sus datos puede requerir ingresar de nuevo. Después de añadir estas dependencias, detén y vuelve a iniciar la vista previa para cargar los plugins.

El soporte iOS está generado; no se declara compilado o probado en un iPhone desde este equipo Windows.
