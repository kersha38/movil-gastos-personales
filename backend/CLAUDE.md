# CLAUDE.md — Subagente Backend (backend/)

AWS CDK (TypeScript) + Go Lambdas + DynamoDB + API Gateway REST. Región `us-east-1`, perfil AWS `default`.

## Estructura

```
backend/
├── cdk/                    # CDK TypeScript
│   ├── bin/backend.ts      # Entrypoint — GastosBackendStack en us-east-1
│   ├── lib/backend-stack.ts # Stack completo: tablas, lambdas, API Gateway
│   ├── package.json        # aws-cdk-lib: 2.170.0 (pinned exacto, sin ^)
│   └── tsconfig.json
└── functions/              # Go Lambdas
    ├── go.mod              # module github.com/gastos/functions, Go 1.22
    ├── shared/
    │   ├── models.go       # Gasto, Categoria, Participante, Resumen structs
    │   └── response.go     # OkResponse, CreatedResponse, ErrResponse + CORS headers
    ├── categorias/list/    # GET /categorias
    ├── categorias/create/  # POST /categorias
    ├── participantes/list/ # GET /participantes
    ├── participantes/update/ # PUT /participantes/{id}
    ├── gastos/list/        # GET /gastos?mes=&anio=
    ├── gastos/create/      # POST /gastos
    ├── gastos/update/      # PUT /gastos/{id}
    └── resumen/get/        # GET /resumen?mes=&anio=
```

## DynamoDB — tablas

| Tabla | PK | SK | GSI |
|-------|----|----|-----|
| `gastos` | `gastoId` (S) | — | `MesIndex`: PK=`yearMonth`, SK=`fecha` |
| `categorias` | `categoriaId` (S) | — | — |
| `participantes` | `participanteId` (S) | — | — |

El campo `yearMonth` en Gasto tiene formato `"2026-05"` y se calcula al crear el gasto desde `fecha`.

## API — endpoints y CORS

Todos los endpoints tienen CORS configurado (`Access-Control-Allow-Origin: *`). El header va en cada respuesta desde `shared/response.go`.

| Método | Ruta | Lambda |
|--------|------|--------|
| GET | `/categorias` | `categorias/list` |
| POST | `/categorias` | `categorias/create` |
| GET | `/participantes` | `participantes/list` |
| PUT | `/participantes/{id}` | `participantes/update` |
| GET | `/gastos?mes=5&anio=2026` | `gastos/list` |
| POST | `/gastos` | `gastos/create` |
| PUT | `/gastos/{id}` | `gastos/update` |
| GET | `/resumen?mes=5&anio=2026` | `resumen/get` |

## Go Lambdas — convenciones

- Runtime: `PROVIDED_AL2023`, arquitectura `ARM64` (Graviton)
- Módulo: `github.com/gastos/functions`
- Dependencias: `github.com/aws/aws-lambda-go`, `github.com/aws/aws-sdk-go-v2`, `github.com/google/uuid`
- Compilación: CDK usa `BundlingOptions` con Docker para compilar los binarios Go
- Cada lambda vive en su propio `main.go` con `func main()` y `lambda.Start(handler)`

## CDK — notas importantes

- `aws-cdk-lib` y `aws-cdk` deben estar **pinneados exactos** a `2.170.0` (sin `^`) para evitar conflictos de peer deps con `constructs`
- Si `npm install` falla por permisos de caché: `npm install --cache /tmp/npm-cache-gastos`
- `npx tsc --noEmit` para verificar TypeScript sin emitir archivos

## Comandos

```bash
# CDK
cd cdk
npm install
npx cdk synth          # verifica el stack (no despliega)
npx cdk deploy         # despliega en AWS

# Go
cd functions
go mod tidy            # sincronizar dependencias
go build ./...         # compilar todos los paquetes
```

## Primer deploy + seed de datos

```bash
cd cdk && npx cdk bootstrap   # solo la primera vez por cuenta/región
npx cdk deploy

# Seed participantes (obligatorio antes de usar la app)
aws dynamodb put-item --table-name participantes --item '{"participanteId":{"S":"p1"},"nombre":{"S":"Participante 1"}}'
aws dynamodb put-item --table-name participantes --item '{"participanteId":{"S":"p2"},"nombre":{"S":"Participante 2"}}'

# Seed categorías predefinidas
for cat in "Alimentación" "Transporte" "Vivienda" "Salud" "Entretenimiento" "Educación" "Ropa" "Servicios"; do
  aws dynamodb put-item --table-name categorias \
    --item "{\"categoriaId\":{\"S\":\"$(uuidgen | tr '[:upper:]' '[:lower:]')\"},\"nombre\":{\"S\":\"$cat\"},\"esPredefinida\":{\"BOOL\":true}}"
done
```

Tras el deploy, copiar la URL del output `GastosBackendStack.ApiUrl` al `ApiClient.baseUrl` en `movil/lib/data/services/api_client.dart`.

## Build web + deploy a S3/CloudFront

El stack ya incluye un bucket S3 privado (`WebBucket`) servido vía CloudFront (`WebDistribution`), con outputs `WebBucketName` y `WebUrl`.

```bash
cd movil
flutter build web --release
aws s3 sync build/web/ s3://<WebBucketName>/ --delete
```

Si no tienes los outputs a mano: `aws cloudformation describe-stacks --stack-name GastosBackendStack --query "Stacks[0].Outputs"`.

Para invalidar la caché de CloudFront tras subir un build nuevo:
```bash
aws cloudfront list-distributions --query "DistributionList.Items[].{Id:Id,Domain:DomainName}"
aws cloudfront create-invalidation --distribution-id <ID> --paths "/*"
```
