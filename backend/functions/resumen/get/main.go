package main

import (
	"context"
	"fmt"
	"math"
	"os"
	"sort"
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

	// Query gastos for the month
	ymVal, _ := attributevalue.Marshal(yearMonth)
	gastosOut, err := svc.Query(ctx, &dynamodb.QueryInput{
		TableName:              strPtr(os.Getenv("GASTOS_TABLE")),
		IndexName:              strPtr("MesIndex"),
		KeyConditionExpression: aws.String("yearMonth = :ym"),
		ExpressionAttributeValues: map[string]types.AttributeValue{":ym": ymVal},
	})
	if err != nil {
		return shared.ErrResponse(500, "error querying gastos")
	}

	var gastos []shared.Gasto
	if err := attributevalue.UnmarshalListOfMaps(gastosOut.Items, &gastos); err != nil {
		return shared.ErrResponse(500, "error unmarshalling gastos")
	}

	// Scan participantes to get current names
	partOut, err := svc.Scan(ctx, &dynamodb.ScanInput{
		TableName: strPtr(os.Getenv("PARTICIPANTES_TABLE")),
	})
	if err != nil {
		return shared.ErrResponse(500, "error scanning participantes")
	}
	var participantes []shared.Participante
	_ = attributevalue.UnmarshalListOfMaps(partOut.Items, &participantes)

	p1Nombre, p2Nombre := "Participante 1", "Participante 2"
	for _, p := range participantes {
		switch p.ID {
		case "p1":
			p1Nombre = p.Nombre
		case "p2":
			p2Nombre = p.Nombre
		}
	}

	// Aggregate
	var totalMes float64
	var montoPagadoP1, montoPagadoP2 float64
	categoryTotals := map[string]shared.ResumenCategoria{}

	for _, g := range gastos {
		totalMes += g.Monto
		if g.PagadorID == "p1" {
			montoPagadoP1 += g.Monto
		} else {
			montoPagadoP2 += g.Monto
		}
		rc, ok := categoryTotals[g.CategoriaID]
		if !ok {
			rc = shared.ResumenCategoria{CategoriaID: g.CategoriaID, CategoriaNombre: g.CategoriaNombre}
		}
		rc.Total += g.Monto
		categoryTotals[g.CategoriaID] = rc
	}

	// Calculate percentages and sort by total desc
	gastosPorCategoria := make([]shared.ResumenCategoria, 0, len(categoryTotals))
	for _, rc := range categoryTotals {
		if totalMes > 0 {
			rc.Porcentaje = math.Round((rc.Total/totalMes)*10000) / 100
		}
		gastosPorCategoria = append(gastosPorCategoria, rc)
	}
	sort.Slice(gastosPorCategoria, func(i, j int) bool {
		return gastosPorCategoria[i].Total > gastosPorCategoria[j].Total
	})

	// Balance: each participant owes half of shared expenses they didn't pay
	var debeP1, debeP2 float64
	for _, g := range gastos {
		if !g.EsCompartido {
			continue
		}
		// What p1 owes on this expense
		p1Share := g.Monto * g.PorcentajeParticipante1 / 100
		p2Share := g.Monto * g.PorcentajeParticipante2 / 100

		if g.PagadorID == "p2" {
			debeP1 += p1Share
		} else if g.PagadorID == "p1" {
			debeP2 += p2Share
		}
	}

	// Net: if p1 owes p2 more than vice-versa
	net := debeP1 - debeP2
	var montoDebeP1, montoDebeP2 float64
	if net > 0 {
		montoDebeP1 = math.Round(net*100) / 100
	} else if net < 0 {
		montoDebeP2 = math.Round(-net*100) / 100
	}

	resumen := shared.Resumen{
		TotalMes:           math.Round(totalMes*100) / 100,
		GastosPorCategoria: gastosPorCategoria,
		Balance: shared.Balance{
			Participante1ID:     "p1",
			Participante1Nombre: p1Nombre,
			Participante2ID:     "p2",
			Participante2Nombre: p2Nombre,
			MontoPagadoP1:       math.Round(montoPagadoP1*100) / 100,
			MontoPagadoP2:       math.Round(montoPagadoP2*100) / 100,
			MontoDebeP1:         montoDebeP1,
			MontoDebeP2:         montoDebeP2,
		},
	}

	return shared.OkResponse(resumen)
}

func strPtr(s string) *string { return &s }

func main() { lambda.Start(handler) }
