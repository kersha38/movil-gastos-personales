# CLAUDE.md — Orquestador

App móvil para que **una pareja registre y visualice gastos compartidos** en Ecuador. Dos participantes fijos (`p1` y `p2`) con nombres configurables. Sin autenticación. El campo `perteneceAlSri` indica comprobante fiscal deducible (SRI Ecuador).

## Estructura del monorepo

```
movil-gastos-personales/
├── movil/          # App Flutter — tiene su propio CLAUDE.md
├── backend/        # AWS CDK + Go Lambdas + DynamoDB — tiene su propio CLAUDE.md
└── CLAUDE.md       # Este archivo (orquestador)
```

Cada subcarpeta tiene su propio `CLAUDE.md` con instrucciones específicas. Ábrelos cuando trabajes dentro de esa subcarpeta.

## Contrato de API (frontend ↔ backend)

| Método | Ruta | Descripción |
|--------|------|-------------|
| GET | `/categorias` | Lista categorías |
| POST | `/categorias` | Crea categoría |
| GET | `/participantes` | Lista p1 y p2 |
| PUT | `/participantes/{id}` | Actualiza nombre |
| GET | `/gastos?mes=5&anio=2026` | Lista gastos del mes |
| POST | `/gastos` | Crea gasto |
| PUT | `/gastos/{id}` | Actualiza gasto (reemplazo completo) |
| GET | `/resumen?mes=5&anio=2026` | Resumen mensual |

## Modelo de datos principal — Gasto

```json
{
  "gastoId": "uuid",
  "descripcion": "string",
  "monto": 25.50,
  "fecha": "2026-05-17T10:00:00Z",
  "categoriaId": "uuid",
  "categoriaNombre": "string",
  "pagadorId": "p1 | p2",
  "porcentajeP1": 50,
  "esRecurrente": false,
  "perteneceAlSri": false,
  "yearMonth": "2026-05"
}
```

## Decisiones de diseño clave

- **Sin auth**: participantes fijos `p1`/`p2`; nombres configurables en Settings y sincronizados vía `PUT /participantes/{id}`.
- **Sin tab de Ingresos**: está en el roadmap, no implementada.
- **SRI**: campo `perteneceAlSri` para comprobantes fiscales deducibles (Ecuador).
- **CORS**: todos los endpoints del backend aceptan `*` en Access-Control-Allow-Origin.

## Estado del proyecto

| Módulo | Estado |
|--------|--------|
| App Flutter (`movil/`) | Estructura completa — pendiente conectar backend real |
| Backend (`backend/`) | CDK + Lambdas listos — pendiente primer deploy |
| Autenticación | No implementada (roadmap) |
| Pantalla Ingresos | No implementada (roadmap) |

## Primer deploy — pasos en orden

1. `cd backend/cdk && npm install && npx cdk bootstrap && npx cdk deploy`
2. Copiar la URL del output `GastosBackendStack.ApiUrl`
3. Actualizar `movil/lib/data/services/api_client.dart` → `ApiClient.baseUrl`
4. Seed de DynamoDB — ver `backend/CLAUDE.md`
5. `cd movil && flutter run`

## Publicar la versión web (S3 + CloudFront)

El stack ya crea el bucket S3 y la distribución CloudFront (outputs `WebBucketName` y `WebUrl`).

```bash
cd movil && flutter build web --release
aws s3 sync build/web/ s3://<WebBucketName>/ --delete
```

Detalle completo (incluyendo invalidación de caché de CloudFront) en `backend/CLAUDE.md`.
