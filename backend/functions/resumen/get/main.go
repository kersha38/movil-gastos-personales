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

	ymVal, _ := attributevalue.Marshal(yearMonth)

	// Query gastos and transferencias in parallel
	type gastosResult struct {
		items []shared.Gasto
		err   error
	}
	type transferenciasResult struct {
		items []shared.Transferencia
		err   error
	}

	gasCh := make(chan gastosResult, 1)
	trCh := make(chan transferenciasResult, 1)

	go func() {
		out, err := svc.Query(ctx, &dynamodb.QueryInput{
			TableName:              strPtr(os.Getenv("GASTOS_TABLE")),
			IndexName:              strPtr("MesIndex"),
			KeyConditionExpression: aws.String("yearMonth = :ym"),
			ExpressionAttributeValues: map[string]types.AttributeValue{":ym": ymVal},
		})
		if err != nil {
			gasCh <- gastosResult{err: err}
			return
		}
		var gastos []shared.Gasto
		_ = attributevalue.UnmarshalListOfMaps(out.Items, &gastos)
		gasCh <- gastosResult{items: gastos}
	}()

	go func() {
		out, err := svc.Query(ctx, &dynamodb.QueryInput{
			TableName:              strPtr(os.Getenv("TRANSFERENCIAS_TABLE")),
			IndexName:              strPtr("MesIndex"),
			KeyConditionExpression: aws.String("yearMonth = :ym"),
			ExpressionAttributeValues: map[string]types.AttributeValue{":ym": ymVal},
		})
		if err != nil {
			trCh <- transferenciasResult{err: err}
			return
		}
		var tr []shared.Transferencia
		_ = attributevalue.UnmarshalListOfMaps(out.Items, &tr)
		trCh <- transferenciasResult{items: tr}
	}()

	gasRes := <-gasCh
	if gasRes.err != nil {
		return shared.ErrResponse(500, "error querying gastos")
	}
	trRes := <-trCh
	if trRes.err != nil {
		return shared.ErrResponse(500, "error querying transferencias")
	}

	gastos := gasRes.items
	transferencias := trRes.items
	if transferencias == nil {
		transferencias = []shared.Transferencia{}
	}

	// Participante names
	partOut, _ := svc.Scan(ctx, &dynamodb.ScanInput{
		TableName: strPtr(os.Getenv("PARTICIPANTES_TABLE")),
	})
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

	// Aggregate gastos
	var totalMes float64
	var montoPagadoP1, montoPagadoP2 float64
	var gastoIndividualP1, gastoIndividualP2 float64
	var gastoCompartidoP1, gastoCompartidoP2 float64
	var gastoSriP1, gastoSriP2 float64
	categoryTotals := map[string]shared.ResumenCategoria{}

	for _, g := range gastos {
		totalMes += g.Monto

		if g.PagadorID == "p1" {
			montoPagadoP1 += g.Monto
			if !g.EsCompartido {
				gastoIndividualP1 += g.Monto
			} else {
				gastoCompartidoP1 += g.Monto
			}
			if g.PerteneceAlSri {
				gastoSriP1 += g.Monto
			}
		} else {
			montoPagadoP2 += g.Monto
			if !g.EsCompartido {
				gastoIndividualP2 += g.Monto
			} else {
				gastoCompartidoP2 += g.Monto
			}
			if g.PerteneceAlSri {
				gastoSriP2 += g.Monto
			}
		}

		rc, ok := categoryTotals[g.CategoriaID]
		if !ok {
			rc = shared.ResumenCategoria{CategoriaID: g.CategoriaID, CategoriaNombre: g.CategoriaNombre}
		}
		rc.Total += g.Monto
		categoryTotals[g.CategoriaID] = rc
	}

	// Category percentages
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

	// Raw debt from shared expenses
	var rawDebeP1, rawDebeP2 float64
	for _, g := range gastos {
		if !g.EsCompartido {
			continue
		}
		p1Share := g.Monto * g.PorcentajeParticipante1 / 100
		p2Share := g.Monto * g.PorcentajeParticipante2 / 100
		if g.PagadorID == "p2" {
			rawDebeP1 += p1Share
		} else if g.PagadorID == "p1" {
			rawDebeP2 += p2Share
		}
	}

	// Transfers: p1→p2 reduces p1's debt / increases p2's debt; p2→p1 does opposite
	var trP1aP2, trP2aP1 float64
	for _, t := range transferencias {
		if t.OrigenID == "p1" && t.DestinoID == "p2" {
			trP1aP2 += t.Monto
		} else if t.OrigenID == "p2" && t.DestinoID == "p1" {
			trP2aP1 += t.Monto
		}
	}

	// Net: positive means p2 still owes p1 after adjusting transfers
	// rawDebeP1 = what p1 owes p2 from shared expenses paid by p2
	// rawDebeP2 = what p2 owes p1 from shared expenses paid by p1
	// trP2aP1 = p2 already paid p1 this amount (reduces p2's debt)
	// trP1aP2 = p1 already paid p2 this amount (reduces p1's debt)
	netP2owesP1 := rawDebeP2 - rawDebeP1 - trP2aP1 + trP1aP2

	var montoDebeP1, montoDebeP2 float64
	if netP2owesP1 > 0 {
		montoDebeP2 = math.Round(netP2owesP1*100) / 100
	} else if netP2owesP1 < 0 {
		montoDebeP1 = math.Round(-netP2owesP1*100) / 100
	}

	r2f := func(v float64) float64 { return math.Round(v*100) / 100 }

	resumen := shared.Resumen{
		TotalMes:           r2f(totalMes),
		GastosPorCategoria: gastosPorCategoria,
		Balance: shared.Balance{
			Participante1ID:     "p1",
			Participante1Nombre: p1Nombre,
			Participante2ID:     "p2",
			Participante2Nombre: p2Nombre,
			MontoPagadoP1:       r2f(montoPagadoP1),
			MontoPagadoP2:       r2f(montoPagadoP2),
			GastoIndividualP1:   r2f(gastoIndividualP1),
			GastoIndividualP2:   r2f(gastoIndividualP2),
			GastoCompartidoP1:   r2f(gastoCompartidoP1),
			GastoCompartidoP2:   r2f(gastoCompartidoP2),
			GastoSriP1:          r2f(gastoSriP1),
			GastoSriP2:          r2f(gastoSriP2),
			MontoDebeP1:         montoDebeP1,
			MontoDebeP2:         montoDebeP2,
			TransferenciasP1aP2: r2f(trP1aP2),
			TransferenciasP2aP1: r2f(trP2aP1),
		},
		Transferencias: transferencias,
	}

	return shared.OkResponse(resumen)
}

func strPtr(s string) *string { return &s }

func main() { lambda.Start(handler) }
