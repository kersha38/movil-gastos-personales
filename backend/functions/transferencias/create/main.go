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
	var t shared.Transferencia
	if err := json.Unmarshal([]byte(req.Body), &t); err != nil {
		return shared.ErrResponse(400, "invalid request body")
	}
	if t.Monto <= 0 || t.OrigenID == "" || t.DestinoID == "" {
		return shared.ErrResponse(400, "monto, origenId and destinoId are required")
	}
	if t.OrigenID == t.DestinoID {
		return shared.ErrResponse(400, "origen and destino must be different")
	}

	t.ID = uuid.NewString()
	if t.Timestamp == "" {
		t.Timestamp = time.Now().UTC().Format(time.RFC3339)
	}

	ts, err := time.Parse(time.RFC3339Nano, t.Timestamp)
	if err != nil {
		ts = time.Now().UTC()
		t.Timestamp = ts.Format(time.RFC3339)
	}
	quito := time.FixedZone("ECT", -5*60*60)
	tsLocal := ts.In(quito)
	t.YearMonth = fmt.Sprintf("%04d-%02d", tsLocal.Year(), tsLocal.Month())

	cfg, err2 := config.LoadDefaultConfig(ctx, config.WithRegion(os.Getenv("REGION")))
	if err2 != nil {
		return shared.ErrResponse(500, "error loading AWS config")
	}

	item, err := attributevalue.MarshalMap(t)
	if err != nil {
		return shared.ErrResponse(500, "error marshalling transferencia")
	}

	svc := dynamodb.NewFromConfig(cfg)
	_, err = svc.PutItem(ctx, &dynamodb.PutItemInput{
		TableName: strPtr(os.Getenv("TRANSFERENCIAS_TABLE")),
		Item:      item,
	})
	if err != nil {
		return shared.ErrResponse(500, "error saving transferencia")
	}

	return shared.CreatedResponse(t)
}

func strPtr(s string) *string { return &s }

func main() { lambda.Start(handler) }
