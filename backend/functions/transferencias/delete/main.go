package main

import (
	"context"
	"os"

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
		return shared.ErrResponse(400, "transferenciaId is required")
	}

	cfg, err := config.LoadDefaultConfig(ctx, config.WithRegion(os.Getenv("REGION")))
	if err != nil {
		return shared.ErrResponse(500, "error loading AWS config")
	}
	svc := dynamodb.NewFromConfig(cfg)

	keyVal, _ := attributevalue.Marshal(id)
	_, err = svc.DeleteItem(ctx, &dynamodb.DeleteItemInput{
		TableName: strPtr(os.Getenv("TRANSFERENCIAS_TABLE")),
		Key:       map[string]types.AttributeValue{"transferenciaId": keyVal},
	})
	if err != nil {
		return shared.ErrResponse(500, "error deleting transferencia")
	}

	return shared.OkResponse(map[string]string{"id": id})
}

func strPtr(s string) *string { return &s }

func main() { lambda.Start(handler) }
