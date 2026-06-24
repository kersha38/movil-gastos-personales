package main

import (
	"context"
	"encoding/json"
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

type verificarRequest struct {
	Verificado    bool   `json:"verificado"`
	VerificadoPor string `json:"verificadoPor"`
}

func handler(ctx context.Context, req events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	gastoID := req.PathParameters["id"]
	if gastoID == "" {
		return shared.ErrResponse(400, "gastoId is required")
	}

	var body verificarRequest
	if err := json.Unmarshal([]byte(req.Body), &body); err != nil {
		return shared.ErrResponse(400, "invalid request body")
	}
	if body.VerificadoPor != "p1" && body.VerificadoPor != "p2" {
		return shared.ErrResponse(400, "verificadoPor must be p1 or p2")
	}

	cfg, err := config.LoadDefaultConfig(ctx, config.WithRegion(os.Getenv("REGION")))
	if err != nil {
		return shared.ErrResponse(500, "error loading AWS config")
	}
	svc := dynamodb.NewFromConfig(cfg)

	gastoIDForGet, _ := attributevalue.Marshal(gastoID)
	getResult, err := svc.GetItem(ctx, &dynamodb.GetItemInput{
		TableName: strPtr(os.Getenv("GASTOS_TABLE")),
		Key: map[string]types.AttributeValue{
			"gastoId": gastoIDForGet,
		},
	})
	if err != nil {
		return shared.ErrResponse(500, "error fetching gasto")
	}
	if getResult.Item == nil {
		return shared.ErrResponse(404, "gasto not found")
	}
	var gasto shared.Gasto
	if err := attributevalue.UnmarshalMap(getResult.Item, &gasto); err != nil {
		return shared.ErrResponse(500, "error unmarshalling gasto")
	}
	if body.VerificadoPor == gasto.PagadorID {
		return shared.ErrResponse(403, "quien pagó el gasto no puede verificarlo")
	}

	verificadoVal, _ := attributevalue.Marshal(body.Verificado)
	verificadoPorVal, _ := attributevalue.Marshal(body.VerificadoPor)
	gastoIDVal, _ := attributevalue.Marshal(gastoID)

	_, err = svc.UpdateItem(ctx, &dynamodb.UpdateItemInput{
		TableName: strPtr(os.Getenv("GASTOS_TABLE")),
		Key: map[string]types.AttributeValue{
			"gastoId": gastoIDVal,
		},
		UpdateExpression: aws.String("SET verificado = :v, verificadoPor = :vp"),
		ExpressionAttributeValues: map[string]types.AttributeValue{
			":v":  verificadoVal,
			":vp": verificadoPorVal,
		},
	})
	if err != nil {
		return shared.ErrResponse(500, "error updating gasto")
	}

	return shared.OkResponse(map[string]interface{}{
		"id":            gastoID,
		"verificado":    body.Verificado,
		"verificadoPor": body.VerificadoPor,
	})
}

func strPtr(s string) *string { return &s }

func main() { lambda.Start(handler) }
