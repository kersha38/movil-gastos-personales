package main

import (
	"context"
	"encoding/json"
	"os"
	"time"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/attributevalue"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/google/uuid"
	"github.com/gastos/functions/shared"
)

func handler(ctx context.Context, req events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	var gm shared.GastoMensual
	if err := json.Unmarshal([]byte(req.Body), &gm); err != nil {
		return shared.ErrResponse(400, "invalid request body")
	}
	if gm.Monto <= 0 || gm.Descripcion == "" || gm.CategoriaID == "" {
		return shared.ErrResponse(400, "monto, descripcion and categoriaId are required")
	}

	gm.ID = uuid.NewString()
	gm.Tipo = "plantilla"
	gm.CreadoEn = time.Now().UTC().Format(time.RFC3339)

	cfg, err := config.LoadDefaultConfig(ctx, config.WithRegion(os.Getenv("REGION")))
	if err != nil {
		return shared.ErrResponse(500, "error loading AWS config")
	}

	item, err := attributevalue.MarshalMap(gm)
	if err != nil {
		return shared.ErrResponse(500, "error marshalling gasto mensual")
	}

	svc := dynamodb.NewFromConfig(cfg)
	_, err = svc.PutItem(ctx, &dynamodb.PutItemInput{
		TableName: strPtr(os.Getenv("GASTOS_MENSUALES_TABLE")),
		Item:      item,
	})
	if err != nil {
		return shared.ErrResponse(500, "error saving gasto mensual")
	}

	return shared.CreatedResponse(gm)
}

func strPtr(s string) *string { return &s }

func main() { lambda.Start(handler) }
