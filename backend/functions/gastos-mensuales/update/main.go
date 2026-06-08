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
	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
	"github.com/gastos/functions/shared"
)

func handler(ctx context.Context, req events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	id := req.PathParameters["id"]
	if id == "" {
		return shared.ErrResponse(400, "id is required")
	}

	var gm shared.GastoMensual
	if err := json.Unmarshal([]byte(req.Body), &gm); err != nil {
		return shared.ErrResponse(400, "invalid request body")
	}
	if gm.Monto <= 0 || gm.Descripcion == "" || gm.CategoriaID == "" {
		return shared.ErrResponse(400, "monto, descripcion and categoriaId are required")
	}

	cfg, err := config.LoadDefaultConfig(ctx, config.WithRegion(os.Getenv("REGION")))
	if err != nil {
		return shared.ErrResponse(500, "error loading AWS config")
	}
	svc := dynamodb.NewFromConfig(cfg)

	// Full replace — keep ID and tipo
	gm.ID = id
	if gm.Tipo == "" {
		gm.Tipo = "plantilla"
	}
	if gm.CreadoEn == "" {
		gm.CreadoEn = time.Now().UTC().Format(time.RFC3339)
	}

	item, err := attributevalue.MarshalMap(gm)
	if err != nil {
		return shared.ErrResponse(500, "error marshalling gasto mensual")
	}

	keyVal, _ := attributevalue.Marshal(id)
	item["gastoMensualId"] = keyVal

	_, err = svc.PutItem(ctx, &dynamodb.PutItemInput{
		TableName:           strPtr(os.Getenv("GASTOS_MENSUALES_TABLE")),
		Item:                item,
		ConditionExpression: strPtr("attribute_exists(gastoMensualId)"),
	})
	if err != nil {
		var ccf *types.ConditionalCheckFailedException
		if isType(err, &ccf) {
			return shared.ErrResponse(404, "gasto mensual not found")
		}
		return shared.ErrResponse(500, "error updating gasto mensual")
	}

	return shared.OkResponse(gm)
}

func isType(err error, target interface{}) bool {
	// Simple type check helper
	switch target.(type) {
	case **types.ConditionalCheckFailedException:
		_, ok := err.(*types.ConditionalCheckFailedException)
		return ok
	}
	return false
}

func strPtr(s string) *string { return &s }

func main() { lambda.Start(handler) }
