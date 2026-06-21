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
	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
	"github.com/gastos/functions/shared"
)

func handler(ctx context.Context, req events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	id := req.PathParameters["id"]
	if id == "" {
		return shared.ErrResponse(400, "gastoId is required")
	}

	var gasto shared.Gasto
	if err := json.Unmarshal([]byte(req.Body), &gasto); err != nil {
		return shared.ErrResponse(400, "invalid request body")
	}
	if gasto.Monto <= 0 || gasto.Descripcion == "" || gasto.CategoriaID == "" {
		return shared.ErrResponse(400, "monto, descripcion and categoriaId are required")
	}

	// Full replace — keep ID from path
	gasto.ID = id

	if gasto.Timestamp == "" {
		gasto.Timestamp = time.Now().UTC().Format(time.RFC3339)
	}
	ts, err := time.Parse(time.RFC3339Nano, gasto.Timestamp)
	if err != nil {
		ts = time.Now().UTC()
		gasto.Timestamp = ts.Format(time.RFC3339)
	}
	quito := time.FixedZone("ECT", -5*60*60)
	tsLocal := ts.In(quito)
	gasto.YearMonth = fmt.Sprintf("%04d-%02d", tsLocal.Year(), tsLocal.Month())

	cfg, err := config.LoadDefaultConfig(ctx, config.WithRegion(os.Getenv("REGION")))
	if err != nil {
		return shared.ErrResponse(500, "error loading AWS config")
	}
	svc := dynamodb.NewFromConfig(cfg)

	item, err := attributevalue.MarshalMap(gasto)
	if err != nil {
		return shared.ErrResponse(500, "error marshalling gasto")
	}

	_, err = svc.PutItem(ctx, &dynamodb.PutItemInput{
		TableName:           strPtr(os.Getenv("GASTOS_TABLE")),
		Item:                item,
		ConditionExpression: strPtr("attribute_exists(gastoId)"),
	})
	if err != nil {
		var ccf *types.ConditionalCheckFailedException
		if isConditionalCheckFailed(err, &ccf) {
			return shared.ErrResponse(404, "gasto not found")
		}
		return shared.ErrResponse(500, "error updating gasto")
	}

	return shared.OkResponse(gasto)
}

func isConditionalCheckFailed(err error, target **types.ConditionalCheckFailedException) bool {
	_, ok := err.(*types.ConditionalCheckFailedException)
	return ok
}

func strPtr(s string) *string { return &s }

func main() { lambda.Start(handler) }
