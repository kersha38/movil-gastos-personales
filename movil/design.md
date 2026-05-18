# design.md — Flutter Material 3 Design System

> Este archivo define las reglas de diseño del proyecto. Todo código Flutter generado debe seguir estas convenciones sin excepción. No uses valores hardcodeados, no uses widgets deprecados, y no apliques estilos inline salvo que se indique explícitamente.

---

## 1. Material version

Este proyecto usa **Material 3** (Material You).

```dart
MaterialApp(
  theme: ThemeData(
    useMaterial3: true,
    colorScheme: lightColorScheme,
    textTheme: _textTheme,
  ),
  darkTheme: ThemeData(
    useMaterial3: true,
    colorScheme: darkColorScheme,
    textTheme: _textTheme,
  ),
  themeMode: ThemeMode.system,
)
```

---

## 2. Color scheme

Usa siempre `Theme.of(context).colorScheme` para acceder a los colores. **Nunca hardcodees hex ni uses `Colors.*` directamente en widgets.**

### Roles de color y su uso

| Token | Uso |
|---|---|
| `primary` | Botones principales, FAB, elementos activos |
| `onPrimary` | Texto/iconos sobre `primary` |
| `primaryContainer` | Chips seleccionados, fondos de cards activas |
| `onPrimaryContainer` | Texto/iconos sobre `primaryContainer` |
| `secondary` | Elementos de apoyo, badges |
| `onSecondary` | Texto/iconos sobre `secondary` |
| `secondaryContainer` | Chips inactivos, tabs no seleccionados |
| `onSecondaryContainer` | Texto/iconos sobre `secondaryContainer` |
| `tertiary` | Acentos, destacados opcionales |
| `surface` | Fondo de cards, sheets, diálogos |
| `onSurface` | Texto principal sobre `surface` |
| `surfaceVariant` | Fondos alternativos, campos de texto |
| `onSurfaceVariant` | Texto secundario, placeholders, iconos inactivos |
| `outline` | Bordes, dividers, campos sin foco |
| `outlineVariant` | Separadores sutiles |
| `error` | Estados de error en formularios |
| `onError` | Texto/iconos sobre `error` |
| `errorContainer` | Fondo de mensajes de error |
| `onErrorContainer` | Texto sobre `errorContainer` |
| `inverseSurface` | Snackbars, tooltips |
| `onInverseSurface` | Texto sobre `inverseSurface` |
| `scrim` | Overlay de modales y drawers |

### ColorScheme base (seed color)

```dart
const _seedColor = Color(0xFF6750A4); // Cambia este valor por tu color de marca

final lightColorScheme = ColorScheme.fromSeed(
  seedColor: _seedColor,
  brightness: Brightness.light,
);

final darkColorScheme = ColorScheme.fromSeed(
  seedColor: _seedColor,
  brightness: Brightness.dark,
);
```

### Acceso en widgets

```dart
// CORRECTO
final cs = Theme.of(context).colorScheme;
Container(color: cs.primaryContainer)

// INCORRECTO — nunca hagas esto
Container(color: const Color(0xFF6750A4))
Container(color: Colors.purple)
```

---

## 3. Tipografía

Usa siempre `Theme.of(context).textTheme` para estilos de texto. **No uses `TextStyle` con valores manuales de fontSize o fontWeight salvo en casos justificados.**

### Escala tipográfica de Material 3

| Estilo | Uso |
|---|---|
| `displayLarge` | Títulos de hero, pantallas de bienvenida |
| `displayMedium` | Títulos grandes de sección |
| `displaySmall` | Subtítulos de pantalla completa |
| `headlineLarge` | Encabezados de pantalla principal |
| `headlineMedium` | Encabezados de sección |
| `headlineSmall` | Títulos de card o sheet |
| `titleLarge` | AppBar title, títulos de lista |
| `titleMedium` | Subtítulos de items, labels de formulario |
| `titleSmall` | Labels secundarios |
| `bodyLarge` | Texto principal de contenido |
| `bodyMedium` | Texto de cuerpo estándar (default) |
| `bodySmall` | Texto de apoyo, captions |
| `labelLarge` | Texto de botones |
| `labelMedium` | Chips, tabs |
| `labelSmall` | Badges, texto muy pequeño |

### Fuente del proyecto

```dart
// En pubspec.yaml agregar la fuente deseada, por ejemplo:
// fonts:
//   - family: Roboto  ← M3 default, ya incluida en Flutter

final _textTheme = TextTheme(
  // Sobrescribe solo los estilos que necesiten fuente personalizada
  // Ejemplo con Google Fonts:
  // bodyLarge: GoogleFonts.inter(fontSize: 16),
);
```

### Acceso en widgets

```dart
// CORRECTO
Text('Hola', style: Theme.of(context).textTheme.titleLarge)

// INCORRECTO
Text('Hola', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
```

### Reglas de escritura

- Usa **sentence case** en todos los textos de UI: botones, labels, títulos de sección.
- Nunca uses ALL CAPS salvo que el diseño lo requiera explícitamente.
- Limita los títulos de AppBar a 3-4 palabras máximo.
- Los mensajes de error deben ser accionables: "No se pudo cargar. Intenta de nuevo."

---

## 4. Espaciado y layout

Define las constantes de espaciado en un archivo `app_spacing.dart` y úsalas siempre.

```dart
// lib/core/theme/app_spacing.dart
abstract class AppSpacing {
  static const double xs  = 4.0;
  static const double sm  = 8.0;
  static const double md  = 16.0;
  static const double lg  = 24.0;
  static const double xl  = 32.0;
  static const double xxl = 48.0;
}
```

### Reglas de layout

- Padding horizontal de pantalla: `AppSpacing.md` (16dp) mínimo.
- Padding vertical entre secciones: `AppSpacing.lg` (24dp).
- Padding interno de cards: `AppSpacing.md` (16dp) en todos los lados.
- Gap entre elementos de lista: `AppSpacing.sm` (8dp).
- Nunca uses `SizedBox` con valores arbitrarios. Usa las constantes.

```dart
// CORRECTO
Padding(
  padding: const EdgeInsets.all(AppSpacing.md),
  child: ...,
)

// INCORRECTO
Padding(
  padding: const EdgeInsets.all(17),
  child: ...,
)
```

---

## 5. Componentes preferidos

### Botones

| Situación | Widget |
|---|---|
| Acción principal de la pantalla | `FilledButton` |
| Acción secundaria | `OutlinedButton` |
| Acción terciaria / menos énfasis | `TextButton` |
| Acción con icono prominente | `FilledButton.icon` |
| Acción flotante | `FloatingActionButton` o `FloatingActionButton.extended` |

```dart
// Acción principal
FilledButton(
  onPressed: () {},
  child: const Text('Continuar'),
)

// Acción secundaria
OutlinedButton(
  onPressed: () {},
  child: const Text('Cancelar'),
)

// NUNCA uses ElevatedButton — está deprecado en M3
// NUNCA uses RaisedButton — eliminado
```

### Campos de texto

Usa siempre `filled` como estilo por defecto de `InputDecoration`.

```dart
TextField(
  decoration: InputDecoration(
    labelText: 'Correo electrónico',
    hintText: 'ejemplo@correo.com',
    filled: true,
    border: const OutlineInputBorder(),
    prefixIcon: const Icon(Icons.email_outlined),
  ),
)
```

### Cards

```dart
// CORRECTO — usa Card con variantes M3
Card(
  child: Padding(
    padding: const EdgeInsets.all(AppSpacing.md),
    child: ...,
  ),
)

// Para cards con borde sin elevación
Card(
  elevation: 0,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
  ),
  child: ...,
)
```

### Navegación

| Situación | Widget |
|---|---|
| 3-5 destinos en móvil | `NavigationBar` |
| Navegación lateral en tablet/desktop | `NavigationRail` |
| Navegación lateral amplia | `NavigationDrawer` |
| Tabs dentro de una pantalla | `TabBar` + `TabBarView` |

```dart
// CORRECTO
NavigationBar(
  selectedIndex: _selectedIndex,
  onDestinationSelected: (i) => setState(() => _selectedIndex = i),
  destinations: const [
    NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Inicio'),
    NavigationDestination(icon: Icon(Icons.search_outlined), selectedIcon: Icon(Icons.search), label: 'Buscar'),
  ],
)

// NUNCA uses BottomNavigationBar — usa NavigationBar
```

### Listas

```dart
// Item estándar
ListTile(
  leading: const Icon(Icons.person_outline),
  title: const Text('Nombre del usuario'),
  subtitle: const Text('Descripción secundaria'),
  trailing: const Icon(Icons.chevron_right),
  onTap: () {},
)

// Separador entre items
const Divider(height: 1, indent: 16, endIndent: 16)
```

### Diálogos y sheets

```dart
// Diálogo de confirmación
showDialog(
  context: context,
  builder: (ctx) => AlertDialog(
    title: const Text('Confirmar acción'),
    content: const Text('¿Estás seguro de que deseas continuar?'),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
      FilledButton(onPressed: () {}, child: const Text('Confirmar')),
    ],
  ),
)

// Bottom sheet modal
showModalBottomSheet(
  context: context,
  useSafeArea: true,
  isScrollControlled: true,
  builder: (ctx) => DraggableScrollableSheet(...),
)
```

### Chips

```dart
// Filtro
FilterChip(
  label: const Text('Categoría'),
  selected: _selected,
  onSelected: (val) => setState(() => _selected = val),
)

// Acción
ActionChip(
  label: const Text('Agregar'),
  avatar: const Icon(Icons.add),
  onPressed: () {},
)
```

### Snackbars

```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: const Text('Cambios guardados'),
    behavior: SnackBarBehavior.floating,
    action: SnackBarAction(label: 'Deshacer', onPressed: () {}),
  ),
)
```

---

## 6. Iconos

- Usa siempre los iconos de `Icons.*` de Material.
- Prefiere la variante **outlined** para estados inactivos: `Icons.home_outlined`
- Usa la variante **filled** para estados activos: `Icons.home`
- Nunca uses paquetes de iconos externos salvo que el proyecto lo requiera explícitamente.
- Tamaño por defecto: `24dp`. No cambies el tamaño salvo justificación de diseño.

```dart
// CORRECTO — estado activo/inactivo diferenciado
Icon(isSelected ? Icons.bookmark : Icons.bookmark_outline)

// Para iconos decorativos, siempre agrega semanticLabel
Icon(Icons.info_outline, semanticLabel: 'Información')
```

---

## 7. Elevación y forma

### Border radius estándar

| Componente | Radius |
|---|---|
| Cards pequeñas | `12dp` |
| Cards grandes, modales | `16dp` |
| Botones | `100dp` (pill — M3 default) |
| Chips | `8dp` |
| Campos de texto | `4dp` arriba, `0dp` abajo (filled) |
| Bottom sheets | `28dp` arriba |
| Diálogos | `28dp` |

```dart
// Usa ShapeBorder consistente
RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
```

### Elevación

En Material 3 la elevación usa **tonal elevation** (color) en lugar de sombras.

- No agregues `BoxShadow` manual en cards o elementos estándar.
- Usa el parámetro `elevation` del widget (`Card`, `Dialog`, etc.) y deja que M3 aplique el color de tono correcto.

```dart
// CORRECTO
Card(elevation: 1, child: ...)   // Tonal elevation leve
Card(elevation: 3, child: ...)   // Más prominencia

// INCORRECTO
Container(
  decoration: BoxDecoration(
    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
  ),
)
```

---

## 8. Temas de componentes (ThemeData)

Centraliza la personalización de componentes en `ThemeData` y nunca la hagas widget por widget.

```dart
ThemeData(
  useMaterial3: true,
  colorScheme: lightColorScheme,

  // AppBar sin elevación, sin sombra
  appBarTheme: const AppBarTheme(
    centerTitle: false,
    elevation: 0,
    scrolledUnderElevation: 1,
  ),

  // Cards con border radius uniforme
  cardTheme: CardThemeData(
    elevation: 1,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    margin: const EdgeInsets.symmetric(horizontal: 0, vertical: AppSpacing.xs),
  ),

  // Inputs filled por defecto
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    border: const OutlineInputBorder(),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.sm,
    ),
  ),

  // FilledButton con padding generoso
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(0, 48),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
    ),
  ),

  // NavigationBar sin label en estado inactivo
  navigationBarTheme: NavigationBarThemeData(
    labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
    height: 72,
  ),
)
```

---

## 9. Accesibilidad

- Todos los `IconButton` deben tener `tooltip`.
- Las imágenes decorativas usan `excludeFromSemantics: true`.
- Las imágenes de contenido usan `Semantics(label: '...')`.
- El contraste mínimo de texto sobre fondo es **4.5:1** (WCAG AA).
- Los targets táctiles tienen mínimo **48×48dp**.
- Nunca uses `GestureDetector` con áreas menores a 48dp sin agregar un `SizedBox` que expanda el área.

```dart
// Área táctil mínima garantizada
SizedBox(
  width: 48,
  height: 48,
  child: IconButton(
    icon: const Icon(Icons.close),
    tooltip: 'Cerrar',
    onPressed: () {},
  ),
)
```

---

## 10. Lo que NO debes hacer

```dart
// ❌ Colores hardcodeados
color: const Color(0xFF6750A4)
color: Colors.purple

// ❌ TextStyle manual sin justificación
style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)

// ❌ Widgets deprecados en M3
BottomNavigationBar(...)
ElevatedButton(...)
RaisedButton(...)

// ❌ Sombras manuales en componentes estándar
BoxShadow(color: Colors.black26, blurRadius: 8)

// ❌ Espaciado arbitrario
SizedBox(height: 13)
EdgeInsets.all(17)

// ❌ Estilos inline que sobreescriben el tema
Card(color: Colors.white) // Usa surface del tema
AppBar(backgroundColor: Colors.blue) // Configúralo en appBarTheme
```

---

## 11. Estructura de archivos de tema

```
lib/
└── core/
    └── theme/
        ├── app_theme.dart        ← ThemeData principal (light + dark)
        ├── app_colors.dart       ← ColorScheme y seedColor
        ├── app_text_theme.dart   ← TextTheme personalizado
        └── app_spacing.dart      ← Constantes de espaciado
```

---

*Versión: Material 3 · Flutter 3.x · Última revisión: 2025*
