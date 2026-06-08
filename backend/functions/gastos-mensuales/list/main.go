package main

import (
	"context"
	"os"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/attributevalue"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
	"github.com/gastos/functions/shared"
)

func handler(ctx context.Context, req events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	// ?tipo=plantilla (default) | instancia; ?plantillaId=xxx for instances of one template
	tipo := req.QueryStringParameters["tipo"]
	if tipo == "" {
		tipo = "plantilla"
	}
	plantillaID := req.QueryStringParameters["plantillaId"]

	cfg, err := config.LoadDefaultConfig(ctx, config.WithRegion(os.Getenv("REGION")))
	if err != nil {
		return shared.ErrResponse(500, "error loading AWS config")
	}
	svc := dynamodb.NewFromConfig(cfg)

	var items []shared.GastoMensual

	if plantillaID != "" {
		// Query by templateId using TemplateIdIndex
		pidVal, _ := attributevalue.Marshal(plantillaID)
		out, err := svc.Query(ctx, &dynamodb.QueryInput{
			TableName:              strPtr(os.Getenv("GASTOS_MENSUALES_TABLE")),
			IndexName:              strPtr("TemplateIdIndex"),
			KeyConditionExpression: aws.String("plantillaId = :pid"),
			ExpressionAttributeValues: map[string]types.AttributeValue{":pid": pidVal},
		})
		if err != nil {
			return shared.ErrResponse(500, "error querying gastos-mensuales")
		}
		_ = attributevalue.UnmarshalListOfMaps(out.Items, &items)
	} else {
		// Query by tipo using TipoIndex
		tipoVal, _ := attributevalue.Marshal(tipo)
		out, err := svc.Query(ctx, &dynamodb.QueryInput{
			TableName:              strPtr(os.Getenv("GASTOS_MENSUALES_TABLE")),
			IndexName:              strPtr("TipoIndex"),
			KeyConditionExpression: aws.String("tipo = :t"),
			ExpressionAttributeValues: map[string]types.AttributeValue{":t": tipoVal},
		})
		if err != nil {
			return shared.ErrResponse(500, "error querying gastos-mensuales")
		}
		_ = attributevalue.UnmarshalListOfMaps(out.Items, &items)
	}

	if items == nil {
		items = []shared.GastoMensual{}
	}

	return shared.OkResponse(items)
}

func strPtr(s string) *string { return &s }

func main() { lambda.Start(handler) }
