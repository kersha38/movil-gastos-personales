package shared

import (
	"encoding/json"

	"github.com/aws/aws-lambda-go/events"
)

func corsHeaders() map[string]string {
	return map[string]string{
		"Content-Type":                "application/json",
		"Access-Control-Allow-Origin": "*",
	}
}

// OkResponse returns a 200 JSON response.
func OkResponse(body any) (events.APIGatewayProxyResponse, error) {
	b, _ := json.Marshal(body)
	return events.APIGatewayProxyResponse{
		StatusCode: 200,
		Headers:    corsHeaders(),
		Body:       string(b),
	}, nil
}

// CreatedResponse returns a 201 JSON response.
func CreatedResponse(body any) (events.APIGatewayProxyResponse, error) {
	b, _ := json.Marshal(body)
	return events.APIGatewayProxyResponse{
		StatusCode: 201,
		Headers:    corsHeaders(),
		Body:       string(b),
	}, nil
}

// ErrResponse returns an error JSON response with the given status code.
func ErrResponse(status int, msg string) (events.APIGatewayProxyResponse, error) {
	b, _ := json.Marshal(map[string]string{"error": msg})
	return events.APIGatewayProxyResponse{
		StatusCode: status,
		Headers:    corsHeaders(),
		Body:       string(b),
	}, nil
}
