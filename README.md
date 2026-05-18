# Gastos Personales — Monorepo

App móvil para que una pareja registre y visualice sus gastos compartidos. Permite categorizar gastos, definir quién pagó, dividir el monto entre ambos participantes, marcar gastos recurrentes y comprobantes fiscales (SRI Ecuador).

## Estructura del monorepo

```
movil-gastos-personales/
├── movil/              # App Flutter (iOS / Android)
│   ├── design.md           # Sistema de diseño Material 3 (colores, tipografía, espaciado)
│   └── flutter_rules.md    # Guía de estilo y arquitectura Flutter
├── backend/            # API REST — AWS CDK + Go Lambdas + DynamoDB
└── README.md           # Este archivo
```

## Arquitectura de agentes

Este proyecto sigue una **arquitectura de subagentes** para su desarrollo con IA:

```
Agente orquestador  (Claude — conversación principal)
├── Define el contrato de API entre frontend y backend
├── Coordina decisiones de diseño e integración
├── Resuelve conflictos entre subcarpetas
│
├── Subagente movil/    → Implementa la app Flutter
│   ├── Estructura por features (resumen, gastos, settings)
│   ├── Sigue design.md y flutter_rules.md
│   └── Consume la API del backend
│
└── Subagente backend/  → Implementa la infraestructura AWS
    ├── CDK TypeScript define el stack
    ├── Go Lambdas implementan la lógica
    └── DynamoDB almacena los datos
```

### Contrato de API (entre subagentes)

```
GET    /categorias                    → List<Categoria>
POST   /categorias                    → Categoria
GET    /participantes                 → List<Participante>  (siempre 2: p1 y p2)
PUT    /participantes/{id}            → Participante
GET    /gastos?mes=5&anio=2026        → List<Gasto>
POST   /gastos                        → Gasto
GET    /resumen?mes=5&anio=2026       → Resumen
```

El modelo de datos completo está documentado en [backend/README.md](backend/README.md).

## Estado del proyecto

| Módulo | Estado |
|--------|--------|
| App Flutter (movil/) | Estructura base completa, pendiente conectar a backend real |
| Backend (backend/) | CDK + Lambdas listos, pendiente primer deploy |
| Autenticación | No implementada (roadmap) |
| Pantalla de ingresos | No implementada (roadmap) |

## Primeros pasos

### 1. Levantar el backend

```bash
cd backend
# Ver backend/README.md para instrucciones completas
```

### 2. Correr la app

```bash
cd movil
flutter pub get
flutter run
```

### 3. Conectar app con backend

Después del primer `cdk deploy`, actualiza la URL base en:
```
movil/lib/data/services/api_client.dart → ApiClient.baseUrl
```

## Decisiones de diseño relevantes

- **Sin autenticación por ahora**: los dos participantes son fijos (`p1` y `p2`). Sus nombres se configuran localmente en la app (Settings) y se sincronizan con el backend vía `PUT /participantes/{id}`.
- **SRI**: el campo `perteneceAlSri` indica que el gasto tiene comprobante fiscal deducible (Sistema de Rentas Internas, Ecuador).
- **Sin tab de Ingresos**: la pantalla existe en el roadmap pero no está implementada aún.
- **Estado local**: `ChangeNotifier` + `ListenableBuilder` sin paquetes de terceros de state management.
- **Navegación**: `go_router` con `StatefulShellRoute` para las dos tabs principales.
