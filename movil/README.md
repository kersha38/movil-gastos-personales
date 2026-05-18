# movil — App Flutter de Gastos Personales

App móvil (iOS / Android) para registrar y visualizar gastos de pareja. Subproyecto del monorepo [gastos-personales](../README.md).

## Correr la app

```bash
flutter pub get
flutter run
```

## Arquitectura

```
lib/
├── core/theme/         # Tema centralizado (colores, tipografía, espaciado)
│   ├── app_colors.dart     # ColorScheme light/dark — seed Color(0xFF6750A4)
│   ├── app_spacing.dart    # Constantes AppSpacing (xs=4 … xxl=48)
│   ├── app_text_theme.dart # TextTheme
│   └── app_theme.dart      # lightTheme / darkTheme
│
├── data/
│   ├── models/         # Modelos de dominio (Gasto, Categoria, Participante, Resumen)
│   ├── repositories/   # Acceso a datos — llaman a ApiClient
│   └── services/
│       └── api_client.dart  # HTTP client — actualizar baseUrl tras deploy
│
├── features/
│   ├── resumen/        # Tab 0: total del mes, balance, pie chart por categoría
│   ├── gastos/         # Tab 1: lista de gastos + formulario de nuevo gasto
│   └── settings/       # Configuración de nombres de participantes
│
├── app.dart            # MaterialApp.router + GoRouter + NavigationBar
└── main.dart           # Entrypoint — inicializa notifiers
```

### State management

`ChangeNotifier` + `ListenableBuilder`. Sin paquetes de terceros.

| Notifier | Responsabilidad |
|----------|----------------|
| `SettingsNotifier` | Nombres de participantes (persiste en SharedPreferences) |
| `GastosNotifier` | Lista de gastos + mes/año seleccionado |
| `ResumenNotifier` | Resumen mensual + mes/año seleccionado |

### Navegación

`go_router` con `StatefulShellRoute` para las dos tabs principales.

```
/           → ResumenPage
/gastos     → GastosPage
/gastos/nuevo → GastoFormPage
/settings   → SettingsPage
```

### Reglas de diseño

- Material 3 (`useMaterial3: true`), light + dark theme
- `NavigationBar` (no `BottomNavigationBar`)
- `FilledButton` para acciones primarias (no `ElevatedButton`)
- Nunca colores hardcodeados — siempre `Theme.of(context).colorScheme.*`
- Nunca `TextStyle` manual — siempre `Theme.of(context).textTheme.*`
- Espaciado con constantes `AppSpacing` (nunca valores arbitrarios)

Ver [design.md](design.md) y [flutter_rules.md](flutter_rules.md) para las reglas completas.

## Conectar con el backend

Edita `lib/data/services/api_client.dart`:

```dart
static const String baseUrl = 'https://TU_API_ID.execute-api.us-east-1.amazonaws.com/prod';
```

Ver [backend/README.md](../backend/README.md) para obtener la URL tras el deploy.

## Dependencias principales

| Paquete | Uso |
|---------|-----|
| `go_router` | Navegación declarativa |
| `fl_chart` | Pie chart en la página de Resumen |
| `shared_preferences` | Persistir nombres de participantes |
| `http` | Llamadas a la API REST |
