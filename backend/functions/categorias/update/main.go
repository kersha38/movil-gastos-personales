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
	Emoji  string `json:"emoji"`
}

func handler(ctx context.Context, req events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	id := req.PathParameters["id"]
	if id == "" {
		return shared.ErrResponse(400, "id path parameter is required")
	}

	var body updateRequest
	if err := json.Unmarshal([]byte(req.Body), &body); err != nil || body.Nombre == "" || body.Emoji == "" {
		return shared.ErrResponse(400, "nombre and emoji are required")
	}

	cfg, err := config.LoadDefaultConfig(ctx, config.WithRegion(os.Getenv("REGION")))
	if err != nil {
		return shared.ErrResponse(500, "error loading AWS config")
	}

	svc := dynamodb.NewFromConfig(cfg)

	pk, _ := attributevalue.Marshal(id)
	nombreVal, _ := attributevalue.Marshal(body.Nombre)
	emojiVal, _ := attributevalue.Marshal(body.Emoji)

	out, err := svc.UpdateItem(ctx, &dynamodb.UpdateItemInput{
		TableName:                 strPtr(os.Getenv("CATEGORIAS_TABLE")),
		Key:                       map[string]types.AttributeValue{"categoriaId": pk},
		UpdateExpression:          aws.String("SET #n = :nombre, emoji = :emoji"),
		ExpressionAttributeNames:  map[string]string{"#n": "nombre"},
		ExpressionAttributeValues: map[string]types.AttributeValue{":nombre": nombreVal, ":emoji": emojiVal},
		ConditionExpression:       aws.String("attribute_exists(categoriaId)"),
		ReturnValues:              types.ReturnValueAllNew,
	})
	if err != nil {
		return shared.ErrResponse(404, "categoria not found")
	}

	var categoria shared.Categoria
	if err := attributevalue.UnmarshalMap(out.Attributes, &categoria); err != nil {
		return shared.ErrResponse(500, "error unmarshalling response")
	}

	return shared.OkResponse(categoria)
}

func strPtr(s string) *string { return &s }

func main() { lambda.Start(handler) }