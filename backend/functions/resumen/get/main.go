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

	calc := calcularResumen(gastos, transferencias)

	r2f := func(v float64) float64 { return math.Round(v*100) / 100 }

	resumen := shared.Resumen{
		TotalMes:           r2f(calc.totalMes),
		GastosPorCategoria: calc.gastosPorCategoria,
		Balance: shared.Balance{
			Participante1ID:     "p1",
			Participante1Nombre: p1Nombre,
			Participante2ID:     "p2",
			Participante2Nombre: p2Nombre,
			MontoPagadoP1:       r2f(calc.montoPagadoP1),
			MontoPagadoP2:       r2f(calc.montoPagadoP2),
			GastoIndividualP1:   r2f(calc.gastoIndividualP1),
			GastoIndividualP2:   r2f(calc.gastoIndividualP2),
			GastoCompartidoP1:   r2f(calc.gastoCompartidoP1),
			GastoCompartidoP2:   r2f(calc.gastoCompartidoP2),
			GastoSriP1:          r2f(calc.gastoSriP1),
			GastoSriP2:          r2f(calc.gastoSriP2),
			MontoDebeP1:         calc.montoDebeP1,
			MontoDebeP2:         calc.montoDebeP2,
			TransferenciasP1aP2: r2f(calc.trP1aP2),
			TransferenciasP2aP1: r2f(calc.trP2aP1),
		},
		Transferencias: transferencias,
	}

	return shared.OkResponse(resumen)
}

func strPtr(s string) *string { return &s }

// resumenCalc holds raw (unrounded) aggregation results.
type resumenCalc struct {
	totalMes           float64
	montoPagadoP1      float64
	montoPagadoP2      float64
	gastoIndividualP1  float64
	gastoIndividualP2  float64
	gastoCompartidoP1  float64
	gastoCompartidoP2  float64
	gastoSriP1         float64
	gastoSriP2         float64
	montoDebeP1        float64
	montoDebeP2        float64
	trP1aP2            float64
	trP2aP1            float64
	gastosPorCategoria []shared.ResumenCategoria
}

// calcularResumen computes the monthly balance from a list of gastos and
// transferencias. It is a pure function with no AWS dependencies, which makes
// it directly unit-testable.
//
// Deuda neta:
//
//	rawDebeP2 = lo que p2 debe a p1 (su parte de gastos compartidos pagados por p1)
//	rawDebeP1 = lo que p1 debe a p2 (su parte de gastos compartidos pagados por p2)
//	netP2owesP1 = rawDebeP2 - rawDebeP1 - trP2aP1 + trP1aP2
//	  > 0  → p2 aún le debe a p1
//	  < 0  → p1 le debe a p2 (montoDebeP1 = -net)
func calcularResumen(gastos []shared.Gasto, transferencias []shared.Transferencia) resumenCalc {
	var c resumenCalc
	categoryTotals := map[string]shared.ResumenCategoria{}

	for _, g := range gastos {
		c.totalMes += g.Monto

		if g.PagadorID == "p1" {
			c.montoPagadoP1 += g.Monto
			if !g.EsCompartido {
				c.gastoIndividualP1 += g.Monto
			} else {
				c.gastoCompartidoP1 += g.Monto
			}
			if g.PerteneceAlSri {
				c.gastoSriP1 += g.Monto
			}
		} else {
			c.montoPagadoP2 += g.Monto
			if !g.EsCompartido {
				c.gastoIndividualP2 += g.Monto
			} else {
				c.gastoCompartidoP2 += g.Monto
			}
			if g.PerteneceAlSri {
				c.gastoSriP2 += g.Monto
			}
		}

		rc := categoryTotals[g.CategoriaID]
		if rc.CategoriaID == "" {
			rc = shared.ResumenCategoria{CategoriaID: g.CategoriaID, CategoriaNombre: g.CategoriaNombre}
		}
		rc.Total += g.Monto
		categoryTotals[g.CategoriaID] = rc
	}

	// Porcentaje por categoría
	cats := make([]shared.ResumenCategoria, 0, len(categoryTotals))
	for _, rc := range categoryTotals {
		if c.totalMes > 0 {
			rc.Porcentaje = math.Round((rc.Total/c.totalMes)*10000) / 100
		}
		cats = append(cats, rc)
	}
	sort.Slice(cats, func(i, j int) bool { return cats[i].Total > cats[j].Total })
	c.gastosPorCategoria = cats

	// Deuda bruta: lo que cada participante debe al otro por gastos compartidos
	var rawDebeP1, rawDebeP2 float64
	for _, g := range gastos {
		if !g.EsCompartido {
			continue
		}
		// p1Share = parte proporcional de p1 en este gasto
		// p2Share = parte proporcional de p2 en este gasto
		p1Share := g.Monto * g.PorcentajeParticipante1 / 100
		p2Share := g.Monto * g.PorcentajeParticipante2 / 100
		if g.PagadorID == "p2" {
			// p2 pagó; p1 debe reintegrar su parte
			rawDebeP1 += p1Share
		} else if g.PagadorID == "p1" {
			// p1 pagó; p2 debe reintegrar su parte
			rawDebeP2 += p2Share
		}
	}

	// Transferencias realizadas
	for _, t := range transferencias {
		if t.OrigenID == "p1" && t.DestinoID == "p2" {
			c.trP1aP2 += t.Monto
		} else if t.OrigenID == "p2" && t.DestinoID == "p1" {
			c.trP2aP1 += t.Monto
		}
	}

	// Deuda neta (positivo = p2 le debe a p1)
	netP2owesP1 := rawDebeP2 - rawDebeP1 - c.trP2aP1 + c.trP1aP2
	if netP2owesP1 > 0 {
		c.montoDebeP2 = math.Round(netP2owesP1*100) / 100
	} else if netP2owesP1 < 0 {
		c.montoDebeP1 = math.Round(-netP2owesP1*100) / 100
	}

	return c
}

func main() { lambda.Start(handler) }
