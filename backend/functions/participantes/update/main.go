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

type updateRequest struct {
	Nombre string `json:"nombre"`
}

func handler(ctx context.Context, req events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	id := req.PathParameters["id"]
	if id == "" {
		return shared.ErrResponse(400, "id path parameter is required")
	}

	var body updateRequest
	if err := json.Unmarshal([]byte(req.Body), &body); err != nil || body.Nombre == "" {
		return shared.ErrResponse(400, "nombre is required")
	}

	cfg, err := config.LoadDefaultConfig(ctx, config.WithRegion(os.Getenv("REGION")))
	if err != nil {
		return shared.ErrResponse(500, "error loading AWS config")
	}

	svc := dynamodb.NewFromConfig(cfg)

	pk, _ := attributevalue.Marshal(id)
	nombreVal, _ := attributevalue.Marshal(body.Nombre)

	out, err := svc.UpdateItem(ctx, &dynamodb.UpdateItemInput{
		TableName: strPtr(os.Getenv("PARTICIPANTES_TABLE")),
		Key:       map[string]types.AttributeValue{"participanteId": pk},
		UpdateExpression: aws.String("SET #n = :nombre"),
		ExpressionAttributeNames:  map[string]string{"#n": "nombre"},
		ExpressionAttributeValues: map[string]types.AttributeValue{":nombre": nombreVal},
		ConditionExpression:       aws.String("attribute_exists(participanteId)"),
		ReturnValues:              types.ReturnValueAllNew,
	})
	if err != nil {
		return shared.ErrResponse(404, "participante not found")
	}

	var participante shared.Participante
	if err := attributevalue.UnmarshalMap(out.Attributes, &participante); err != nil {
		return shared.ErrResponse(500, "error unmarshalling response")
	}

	return shared.OkResponse(participante)
}

func strPtr(s string) *string { return &s }

func main() { lambda.Start(handler) }
