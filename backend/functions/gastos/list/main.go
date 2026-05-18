package main

import (
	"context"
	"fmt"
	"os"
	"strconv"
	"time"

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
	now := time.Now()
	mes := now.Month()
	anio := now.Year()

	if v := req.QueryStringParameters["mes"]; v != "" {
		if n, err := strconv.Atoi(v); err == nil {
			mes = time.Month(n)
		}
	}
	if v := req.QueryStringParameters["anio"]; v != "" {
		if n, err := strconv.Atoi(v); err == nil {
			anio = n
		}
	}

	yearMonth := fmt.Sprintf("%04d-%02d", anio, mes)

	cfg, err := config.LoadDefaultConfig(ctx, config.WithRegion(os.Getenv("REGION")))
	if err != nil {
		return shared.ErrResponse(500, "error loading AWS config")
	}

	svc := dynamodb.NewFromConfig(cfg)

	ymVal, _ := attributevalue.Marshal(yearMonth)
	out, err := svc.Query(ctx, &dynamodb.QueryInput{
		TableName:              strPtr(os.Getenv("GASTOS_TABLE")),
		IndexName:              strPtr("MesIndex"),
		KeyConditionExpression: aws.String("yearMonth = :ym"),
		ExpressionAttributeValues: map[string]types.AttributeValue{
			":ym": ymVal,
		},
	})
	if err != nil {
		return shared.ErrResponse(500, "error querying gastos")
	}

	var gastos []shared.Gasto
	if err := attributevalue.UnmarshalListOfMaps(out.Items, &gastos); err != nil {
		return shared.ErrResponse(500, "error unmarshalling gastos")
	}

	if gastos == nil {
		gastos = []shared.Gasto{}
	}
	return shared.OkResponse(gastos)
}

func strPtr(s string) *string { return &s }

func main() { lambda.Start(handler) }
