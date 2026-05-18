package main

import (
	"context"
	"os"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/attributevalue"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/gastos/functions/shared"
)

func handler(ctx context.Context, _ events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	cfg, err := config.LoadDefaultConfig(ctx, config.WithRegion(os.Getenv("REGION")))
	if err != nil {
		return shared.ErrResponse(500, "error loading AWS config")
	}

	svc := dynamodb.NewFromConfig(cfg)
	out, err := svc.Scan(ctx, &dynamodb.ScanInput{
		TableName: strPtr(os.Getenv("CATEGORIAS_TABLE")),
	})
	if err != nil {
		return shared.ErrResponse(500, "error scanning categorias")
	}

	var categorias []shared.Categoria
	if err := attributevalue.UnmarshalListOfMaps(out.Items, &categorias); err != nil {
		return shared.ErrResponse(500, "error unmarshalling categorias")
	}

	if categorias == nil {
		categorias = []shared.Categoria{}
	}
	return shared.OkResponse(categorias)
}

func strPtr(s string) *string { return &s }

func main() { lambda.Start(handler) }
