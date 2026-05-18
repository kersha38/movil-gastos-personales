# Backend — Gastos Personales

AWS CDK (TypeScript) + Go Lambda + DynamoDB + API Gateway.

## Prerequisites

- AWS CLI configured (`default` profile, region `us-east-1`)
- Node.js ≥ 18
- Go ≥ 1.22
- Docker (required for CDK Go bundling)

## Setup

```bash
# Install CDK dependencies
cd cdk && npm install

# Download Go dependencies
cd ../functions && go mod tidy
```

## Deploy

```bash
# First time only — bootstrap CDK in your account
cd cdk && npx cdk bootstrap

# Deploy the stack
npx cdk deploy
```

After deploy, the API URL is printed as a stack output:
```
GastosBackendStack.ApiUrl = https://xxxxxx.execute-api.us-east-1.amazonaws.com/prod/
```

## Update Flutter app

Open `movil/lib/data/services/api_client.dart` and replace:
```dart
static const String baseUrl = 'https://api.example.com';
```
with the URL from the stack output (without trailing slash).

## Seed initial data

After the first deploy, seed the DynamoDB tables:

```bash
# Seed participantes
aws dynamodb put-item --table-name participantes --item '{"participanteId":{"S":"p1"},"nombre":{"S":"Participante 1"}}'
aws dynamodb put-item --table-name participantes --item '{"participanteId":{"S":"p2"},"nombre":{"S":"Participante 2"}}'

# Seed categorias predefinidas
for cat in "Alimentación" "Transporte" "Vivienda" "Salud" "Entretenimiento" "Educación" "Ropa" "Servicios"; do
  aws dynamodb put-item --table-name categorias \
    --item "{\"categoriaId\":{\"S\":\"$(uuidgen | tr '[:upper:]' '[:lower:]')\"},\"nombre\":{\"S\":\"$cat\"},\"esPredefinida\":{\"BOOL\":true}}"
done
```

## API Reference

| Method | Path | Description |
|--------|------|-------------|
| GET | /categorias | List categories |
| POST | /categorias | Create category |
| GET | /participantes | List both participants |
| PUT | /participantes/{id} | Update participant name |
| GET | /gastos?mes=5&anio=2026 | List expenses for month |
| POST | /gastos | Create expense |
| GET | /resumen?mes=5&anio=2026 | Monthly summary |
