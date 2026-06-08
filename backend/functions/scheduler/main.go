package main

import (
	"context"
	"fmt"
	"os"
	"time"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/attributevalue"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
	"github.com/google/uuid"
	"github.com/gastos/functions/shared"
)

func handler(ctx context.Context) error {
	cfg, err := config.LoadDefaultConfig(ctx, config.WithRegion(os.Getenv("REGION")))
	if err != nil {
		return fmt.Errorf("error loading AWS config: %w", err)
	}
	svc := dynamodb.NewFromConfig(cfg)

	// Query all plantillas
	tipoVal, _ := attributevalue.Marshal("plantilla")
	out, err := svc.Query(ctx, &dynamodb.QueryInput{
		TableName:              strPtr(os.Getenv("GASTOS_MENSUALES_TABLE")),
		IndexName:              strPtr("TipoIndex"),
		KeyConditionExpression: aws.String("tipo = :t"),
		ExpressionAttributeValues: map[string]types.AttributeValue{":t": tipoVal},
	})
	if err != nil {
		return fmt.Errorf("error querying plantillas: %w", err)
	}

	var plantillas []shared.GastoMensual
	if err := attributevalue.UnmarshalListOfMaps(out.Items, &plantillas); err != nil {
		return fmt.Errorf("error unmarshalling plantillas: %w", err)
	}

	now := time.Now().UTC()
	quito := time.FixedZone("ECT", -5*60*60)
	localNow := now.In(quito)
	yearMonth := fmt.Sprintf("%04d-%02d", localNow.Year(), localNow.Month())
	timestamp := now.Format(time.RFC3339)

	for _, p := range plantillas {
		gastoID := uuid.NewString()

		// Create gasto in gastos table
		gasto := shared.Gasto{
			ID:                      gastoID,
			YearMonth:               yearMonth,
			Monto:                   p.Monto,
			Descripcion:             p.Descripcion,
			CategoriaID:             p.CategoriaID,
			CategoriaNombre:         p.CategoriaNombre,
			PagadorID:               p.PagadorID,
			PagadorNombre:           p.PagadorNombre,
			Participante1ID:         p.Participante1ID,
			Participante1Nombre:     p.Participante1Nombre,
			Participante2ID:         p.Participante2ID,
			Participante2Nombre:     p.Participante2Nombre,
			EsCompartido:            p.EsCompartido,
			PorcentajeParticipante1: p.PorcentajeParticipante1,
			PorcentajeParticipante2: p.PorcentajeParticipante2,
			EsRecurrente:            true,
			PerteneceAlSri:          p.PerteneceAlSri,
			Timestamp:               timestamp,
			Verificado:              false,
		}
		gastoItem, err := attributevalue.MarshalMap(gasto)
		if err != nil {
			continue
		}
		_, _ = svc.PutItem(ctx, &dynamodb.PutItemInput{
			TableName: strPtr(os.Getenv("GASTOS_TABLE")),
			Item:      gastoItem,
		})

		// Create instancia in gastos-mensuales
		instancia := shared.GastoMensual{
			ID:                      uuid.NewString(),
			Tipo:                    "instancia",
			PlantillaID:             p.ID,
			YearMonth:               yearMonth,
			GastoID:                 gastoID,
			Monto:                   p.Monto,
			Descripcion:             p.Descripcion,
			CategoriaID:             p.CategoriaID,
			CategoriaNombre:         p.CategoriaNombre,
			PagadorID:               p.PagadorID,
			PagadorNombre:           p.PagadorNombre,
			Participante1ID:         p.Participante1ID,
			Participante1Nombre:     p.Participante1Nombre,
			Participante2ID:         p.Participante2ID,
			Participante2Nombre:     p.Participante2Nombre,
			EsCompartido:            p.EsCompartido,
			PorcentajeParticipante1: p.PorcentajeParticipante1,
			PorcentajeParticipante2: p.PorcentajeParticipante2,
			PerteneceAlSri:          p.PerteneceAlSri,
			CreadoEn:                timestamp,
		}
		instanciaItem, err := attributevalue.MarshalMap(instancia)
		if err != nil {
			continue
		}
		_, _ = svc.PutItem(ctx, &dynamodb.PutItemInput{
			TableName: strPtr(os.Getenv("GASTOS_MENSUALES_TABLE")),
			Item:      instanciaItem,
		})
	}

	return nil
}

func strPtr(s string) *string { return &s }

func main() { lambda.Start(handler) }
