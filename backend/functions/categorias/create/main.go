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

type createRequest struct {
	Nombre        string `json:"nombre"`
	Emoji         string `json:"emoji"`
	EsPredefinida bool   `json:"esPredefinida"`
}

func handler(ctx context.Context, req events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	var body createRequest
	if err := json.Unmarshal([]byte(req.Body), &body); err != nil || body.Nombre == "" {
		return shared.ErrResponse(400, "nombre is required")
	}

	emoji := body.Emoji
	if emoji == "" {
		emoji = "💲"
	}

	categoria := shared.Categoria{
		ID:            uuid.NewString(),
		Nombre:        body.Nombre,
		Emoji:         emoji,
		EsPredefinida: body.EsPredefinida,
	}

	cfg, err := config.LoadDefaultConfig(ctx, config.WithRegion(os.Getenv("REGION")))
	if err != nil {
		return shared.ErrResponse(500, "error loading AWS config")
	}

	item, err := attributevalue.MarshalMap(categoria)
	if err != nil {
		return shared.ErrResponse(500, "error marshalling categoria")
	}

	svc := dynamodb.NewFromConfig(cfg)
	_, err = svc.PutItem(ctx, &dynamodb.PutItemInput{
		TableName: strPtr(os.Getenv("CATEGORIAS_TABLE")),
		Item:      item,
	})
	if err != nil {
		return shared.ErrResponse(500, "error saving categoria")
	}

	_ = time.Now() // ensure time import used
	return shared.CreatedResponse(categoria)
}

func strPtr(s string) *string { return &s }

func main() { lambda.Start(handler) }
