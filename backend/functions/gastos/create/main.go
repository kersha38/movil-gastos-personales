package main

import (
	"context"
	"encoding/json"
	"fmt"
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
	var gasto shared.Gasto
	if err := json.Unmarshal([]byte(req.Body), &gasto); err != nil {
		return shared.ErrResponse(400, "invalid request body")
	}
	if gasto.Monto <= 0 || gasto.Descripcion == "" || gasto.CategoriaID == "" {
		return shared.ErrResponse(400, "monto, descripcion and categoriaId are required")
	}

	gasto.ID = uuid.NewString()
	if gasto.Timestamp == "" {
		gasto.Timestamp = time.Now().UTC().Format(time.RFC3339)
	}

	ts, err := time.Parse(time.RFC3339, gasto.Timestamp)
	if err != nil {
		ts = time.Now().UTC()
		gasto.Timestamp = ts.Format(time.RFC3339)
	}
	gasto.YearMonth = fmt.Sprintf("%04d-%02d", ts.Year(), ts.Month())

	cfg, err2 := config.LoadDefaultConfig(ctx, config.WithRegion(os.Getenv("REGION")))
	if err2 != nil {
		return shared.ErrResponse(500, "error loading AWS config")
	}

	item, err := attributevalue.MarshalMap(gasto)
	if err != nil {
		return shared.ErrResponse(500, "error marshalling gasto")
	}

	svc := dynamodb.NewFromConfig(cfg)
	_, err = svc.PutItem(ctx, &dynamodb.PutItemInput{
		TableName: strPtr(os.Getenv("GASTOS_TABLE")),
		Item:      item,
	})
	if err != nil {
		return shared.ErrResponse(500, "error saving gasto")
	}

	return shared.CreatedResponse(gasto)
}

func strPtr(s string) *string { return &s }

func main() { lambda.Start(handler) }
