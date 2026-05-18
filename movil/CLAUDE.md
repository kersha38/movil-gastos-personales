# CLAUDE.md — Subagente Flutter (movil/)

App Flutter para registrar gastos de pareja. Material 3, sin paquetes de terceros para state management.

## Reglas obligatorias

Lee **siempre** estos dos archivos antes de generar cualquier widget o pantalla:

- [`design.md`](design.md) — sistema de diseño Material 3: colores, tipografía, espaciado, componentes
- [`flutter_rules.md`](flutter_rules.md) — guía de arquitectura y estilo Dart/Flutter

Resumen de las reglas más importantes:

- **Colores**: siempre `Theme.of(context).colorScheme.*` — nunca hex hardcodeados ni `Colors.*`
- **Tipografía**: siempre `Theme.of(context).textTheme.*` — nunca `TextStyle` manual
- **Espaciado**: siempre `AppSpacing.*` (xs=4, sm=8, md=16, lg=24, xl=32, xxl=48) — nunca valores arbitrarios
- **Botones**: `FilledButton` para acción principal, `OutlinedButton` secundaria — nunca `ElevatedButton`
- **Navegación**: `NavigationBar` — nunca `BottomNavigationBar`
- **Inputs**: `filled: true` por defecto en `InputDecoration`
- **Deprecated**: `withOpacity` → `withValues(alpha:)` | `DropdownButtonFormField.value` → `initialValue` + `key: ValueKey(...)`
- **Lint**: `(_, __)` → `(_, _)` para ignorar parámetros múltiples

## Arquitectura

```
lib/
├── core/theme/         # app_colors, app_spacing, app_text_theme, app_theme
├── data/
│   ├── models/         # Gasto, Categoria, Participante, Resumen — const + fromJson/toJson
│   ├── repositories/   # gastosRepository, categoriasRepository, etc.
│   └── services/
│       └── api_client.dart   # baseUrl — actualizar tras deploy del backend
├── features/
│   ├── resumen/        # ResumenPage + ResumenNotifier
│   ├── gastos/         # GastosPage + GastoFormPage + GastosNotifier + widgets/
│   └── settings/       # SettingsPage + SettingsNotifier
├── app.dart            # MaterialApp.router + GoRouter + StatefulShellRoute
└── main.dart           # async main, inicializa notifiers, await settingsNotifier.init()
```

## State management

`ChangeNotifier` + `ListenableBuilder`. Sin providers de terceros.

| Notifier | Responsabilidad |
|----------|----------------|
| `SettingsNotifier` | Nombres de p1/p2 (SharedPreferences) |
| `GastosNotifier` | Lista de gastos + mes/año seleccionado |
| `ResumenNotifier` | Resumen mensual + mes/año seleccionado |

## Navegación (go_router)

```
/           → ResumenPage
/gastos     → GastosPage
/gastos/nuevo → GastoFormPage
/settings   → SettingsPage
```

`StatefulShellRoute.indexedStack` para las 2 tabs principales (Resumen, Gastos).

## Conectar con el backend

Editar `lib/data/services/api_client.dart`:
```dart
static const String baseUrl = 'https://TU_API_ID.execute-api.us-east-1.amazonaws.com/prod';
```

## Comandos

```bash
flutter pub get          # instalar dependencias
flutter run              # correr en dispositivo/emulador
flutter analyze          # linter — debe pasar con 0 issues
flutter test             # tests
```

## Dependencias principales

| Paquete | Uso |
|---------|-----|
| `go_router` | Navegación declarativa |
| `fl_chart` | Pie chart en ResumenPage |
| `shared_preferences` | Persistir nombres de participantes |
| `http` | Llamadas a la API REST |
