package main

import (
	"math"
	"testing"

	"github.com/gastos/functions/shared"
)

// round2 rounds to 2 decimal places for comparisons.
func round2(v float64) float64 { return math.Round(v*100) / 100 }

func g(pagadorID string, monto float64, compartido bool, pct1, pct2 float64, sri bool) shared.Gasto {
	return shared.Gasto{
		ID:                      "gasto-1",
		PagadorID:               pagadorID,
		Monto:                   monto,
		EsCompartido:            compartido,
		PorcentajeParticipante1: pct1,
		PorcentajeParticipante2: pct2,
		PerteneceAlSri:          sri,
		CategoriaID:             "cat-1",
		CategoriaNombre:         "Alimentación",
	}
}

func tr(origenID, destinoID string, monto float64) shared.Transferencia {
	return shared.Transferencia{
		ID:        "tr-1",
		OrigenID:  origenID,
		DestinoID: destinoID,
		Monto:     monto,
	}
}

// ─── Caso base ───────────────────────────────────────────────────────────────

func TestSinGastos(t *testing.T) {
	c := calcularResumen(nil, nil)
	if c.totalMes != 0 || c.montoDebeP1 != 0 || c.montoDebeP2 != 0 {
		t.Fatalf("esperaba todo en cero, got total=%.2f debeP1=%.2f debeP2=%.2f",
			c.totalMes, c.montoDebeP1, c.montoDebeP2)
	}
}

// ─── Gastos individuales ─────────────────────────────────────────────────────

func TestGastoIndividualP1_NoGeneraDeuda(t *testing.T) {
	// Un gasto individual de p1 no le genera deuda a p2
	c := calcularResumen([]shared.Gasto{g("p1", 100, false, 100, 0, false)}, nil)
	if c.totalMes != 100 {
		t.Errorf("totalMes: want 100, got %.2f", c.totalMes)
	}
	if c.montoPagadoP1 != 100 {
		t.Errorf("montoPagadoP1: want 100, got %.2f", c.montoPagadoP1)
	}
	if c.gastoIndividualP1 != 100 {
		t.Errorf("gastoIndividualP1: want 100, got %.2f", c.gastoIndividualP1)
	}
	if c.montoDebeP1 != 0 || c.montoDebeP2 != 0 {
		t.Errorf("no debe haber deuda, got debeP1=%.2f debeP2=%.2f", c.montoDebeP1, c.montoDebeP2)
	}
}

func TestGastosIndividualesAmbos_NoGeneranDeuda(t *testing.T) {
	gastos := []shared.Gasto{
		g("p1", 50, false, 100, 0, false),
		g("p2", 80, false, 0, 100, false),
	}
	c := calcularResumen(gastos, nil)
	if c.totalMes != 130 {
		t.Errorf("totalMes: want 130, got %.2f", c.totalMes)
	}
	if c.montoDebeP1 != 0 || c.montoDebeP2 != 0 {
		t.Errorf("no debe haber deuda entre gastos individuales")
	}
}

// ─── Gasto compartido 50/50 ───────────────────────────────────────────────────

func TestCompartido5050_P1Paga_P2Debe(t *testing.T) {
	// P1 paga $100 compartido 50/50 → p2 debe $50 a p1
	c := calcularResumen([]shared.Gasto{g("p1", 100, true, 50, 50, false)}, nil)
	if c.montoDebeP2 != 50 {
		t.Errorf("montoDebeP2: want 50, got %.2f", c.montoDebeP2)
	}
	if c.montoDebeP1 != 0 {
		t.Errorf("montoDebeP1: want 0, got %.2f", c.montoDebeP1)
	}
	if c.gastoCompartidoP1 != 100 {
		t.Errorf("gastoCompartidoP1: want 100, got %.2f", c.gastoCompartidoP1)
	}
}

func TestCompartido5050_P2Paga_P1Debe(t *testing.T) {
	// P2 paga $80 compartido 50/50 → p1 debe $40 a p2
	c := calcularResumen([]shared.Gasto{g("p2", 80, true, 50, 50, false)}, nil)
	if c.montoDebeP1 != 40 {
		t.Errorf("montoDebeP1: want 40, got %.2f", c.montoDebeP1)
	}
	if c.montoDebeP2 != 0 {
		t.Errorf("montoDebeP2: want 0, got %.2f", c.montoDebeP2)
	}
}

// ─── Gasto compartido 70/30 ───────────────────────────────────────────────────

func TestCompartido7030_P1Paga(t *testing.T) {
	// P1 paga $100, split 70% p1 / 30% p2 → p2 debe $30
	c := calcularResumen([]shared.Gasto{g("p1", 100, true, 70, 30, false)}, nil)
	if c.montoDebeP2 != 30 {
		t.Errorf("montoDebeP2: want 30, got %.2f", c.montoDebeP2)
	}
}

func TestCompartido7030_P2Paga(t *testing.T) {
	// P2 paga $100, split 70% p1 / 30% p2 → p1 debe $70
	c := calcularResumen([]shared.Gasto{g("p2", 100, true, 70, 30, false)}, nil)
	if c.montoDebeP1 != 70 {
		t.Errorf("montoDebeP1: want 70, got %.2f", c.montoDebeP1)
	}
}

// ─── Deuda neta (ambos pagan compartidos) ────────────────────────────────────

func TestDeudaNeta_AmbosPaganCompartido(t *testing.T) {
	// P1 paga $100 (50/50) → p2 debe $50
	// P2 paga $60  (50/50) → p1 debe $30
	// Neto: p2 debe $20 a p1
	gastos := []shared.Gasto{
		g("p1", 100, true, 50, 50, false),
		g("p2", 60, true, 50, 50, false),
	}
	c := calcularResumen(gastos, nil)
	if c.montoDebeP2 != 20 {
		t.Errorf("montoDebeP2: want 20, got %.2f", c.montoDebeP2)
	}
	if c.montoDebeP1 != 0 {
		t.Errorf("montoDebeP1: want 0, got %.2f", c.montoDebeP1)
	}
}

func TestDeudaNeta_P1DebeAlFinal(t *testing.T) {
	// P1 paga $40 (50/50) → p2 debe $20
	// P2 paga $200 (50/50) → p1 debe $100
	// Neto: p1 debe $80 a p2
	gastos := []shared.Gasto{
		g("p1", 40, true, 50, 50, false),
		g("p2", 200, true, 50, 50, false),
	}
	c := calcularResumen(gastos, nil)
	if c.montoDebeP1 != 80 {
		t.Errorf("montoDebeP1: want 80, got %.2f", c.montoDebeP1)
	}
	if c.montoDebeP2 != 0 {
		t.Errorf("montoDebeP2: want 0, got %.2f", c.montoDebeP2)
	}
}

func TestDeudaIgual_NadieDebe(t *testing.T) {
	// Ambos pagan $100 al 50/50 → net = 0
	gastos := []shared.Gasto{
		g("p1", 100, true, 50, 50, false),
		g("p2", 100, true, 50, 50, false),
	}
	c := calcularResumen(gastos, nil)
	if c.montoDebeP1 != 0 || c.montoDebeP2 != 0 {
		t.Errorf("nadie debe, got debeP1=%.2f debeP2=%.2f", c.montoDebeP1, c.montoDebeP2)
	}
}

// ─── Transferencias ───────────────────────────────────────────────────────────

func TestTransferencia_P2PagaDeuda(t *testing.T) {
	// P1 pagó $100 compartido 50/50 → p2 debe $50
	// P2 transfiere $50 a p1 → quedan al día
	gastos := []shared.Gasto{g("p1", 100, true, 50, 50, false)}
	trs := []shared.Transferencia{tr("p2", "p1", 50)}
	c := calcularResumen(gastos, trs)
	if c.montoDebeP1 != 0 || c.montoDebeP2 != 0 {
		t.Errorf("deberían estar al día, got debeP1=%.2f debeP2=%.2f", c.montoDebeP1, c.montoDebeP2)
	}
	if c.trP2aP1 != 50 {
		t.Errorf("trP2aP1: want 50, got %.2f", c.trP2aP1)
	}
}

func TestTransferencia_P2PagaParcial(t *testing.T) {
	// P1 pagó $100 compartido 50/50 → p2 debe $50
	// P2 transfiere $30 → p2 aún debe $20
	gastos := []shared.Gasto{g("p1", 100, true, 50, 50, false)}
	trs := []shared.Transferencia{tr("p2", "p1", 30)}
	c := calcularResumen(gastos, trs)
	if c.montoDebeP2 != 20 {
		t.Errorf("montoDebeP2: want 20, got %.2f", c.montoDebeP2)
	}
}

func TestTransferencia_P1PagaAP2_AumentaDeudaP2(t *testing.T) {
	// P1 pagó $100 compartido 50/50 → p2 debe $50
	// P1 transfiere $10 a p2 (adelanto / otro motivo) → p2 debe $60
	gastos := []shared.Gasto{g("p1", 100, true, 50, 50, false)}
	trs := []shared.Transferencia{tr("p1", "p2", 10)}
	c := calcularResumen(gastos, trs)
	if c.montoDebeP2 != 60 {
		t.Errorf("montoDebeP2: want 60, got %.2f", c.montoDebeP2)
	}
}

func TestTransferencia_SobrepagoP2(t *testing.T) {
	// P1 pagó $100 compartido 50/50 → p2 debe $50
	// P2 transfiere $70 → p1 le debe $20 a p2
	gastos := []shared.Gasto{g("p1", 100, true, 50, 50, false)}
	trs := []shared.Transferencia{tr("p2", "p1", 70)}
	c := calcularResumen(gastos, trs)
	if c.montoDebeP1 != 20 {
		t.Errorf("montoDebeP1: want 20, got %.2f", c.montoDebeP1)
	}
	if c.montoDebeP2 != 0 {
		t.Errorf("montoDebeP2: want 0, got %.2f", c.montoDebeP2)
	}
}

// ─── Escenario mixto completo ─────────────────────────────────────────────────

func TestEscenarioCompleto(t *testing.T) {
	// P1 paga: $200 individual + $100 compartido 50/50
	// P2 paga: $50 individual  + $80  compartido 70/30
	// Transferencia p2→p1: $15
	//
	// rawDebeP2 = 100 * 50/100 = 50   (su parte del $100 que pagó p1)
	// rawDebeP1 = 80  * 70/100 = 56   (su parte del $80  que pagó p2)
	// net = 50 - 56 - 15 + 0 = -21   → p1 debe $21 a p2

	gastos := []shared.Gasto{
		g("p1", 200, false, 100, 0, false),
		g("p1", 100, true, 50, 50, false),
		g("p2", 50, false, 0, 100, false),
		g("p2", 80, true, 70, 30, false),
	}
	trs := []shared.Transferencia{tr("p2", "p1", 15)}

	c := calcularResumen(gastos, trs)

	if c.totalMes != 430 {
		t.Errorf("totalMes: want 430, got %.2f", c.totalMes)
	}
	if c.montoPagadoP1 != 300 {
		t.Errorf("montoPagadoP1: want 300, got %.2f", c.montoPagadoP1)
	}
	if c.montoPagadoP2 != 130 {
		t.Errorf("montoPagadoP2: want 130, got %.2f", c.montoPagadoP2)
	}
	if c.gastoIndividualP1 != 200 {
		t.Errorf("gastoIndividualP1: want 200, got %.2f", c.gastoIndividualP1)
	}
	if c.gastoIndividualP2 != 50 {
		t.Errorf("gastoIndividualP2: want 50, got %.2f", c.gastoIndividualP2)
	}
	if c.gastoCompartidoP1 != 100 {
		t.Errorf("gastoCompartidoP1: want 100, got %.2f", c.gastoCompartidoP1)
	}
	if c.gastoCompartidoP2 != 80 {
		t.Errorf("gastoCompartidoP2: want 80, got %.2f", c.gastoCompartidoP2)
	}
	if c.montoDebeP1 != 21 {
		t.Errorf("montoDebeP1: want 21, got %.2f", c.montoDebeP1)
	}
	if c.montoDebeP2 != 0 {
		t.Errorf("montoDebeP2: want 0, got %.2f", c.montoDebeP2)
	}
}

// ─── SRI ─────────────────────────────────────────────────────────────────────

func TestGastoSri(t *testing.T) {
	// Un gasto SRI pagado por p1, individual
	c := calcularResumen([]shared.Gasto{g("p1", 120, false, 100, 0, true)}, nil)
	if c.gastoSriP1 != 120 {
		t.Errorf("gastoSriP1: want 120, got %.2f", c.gastoSriP1)
	}
	if c.gastoSriP2 != 0 {
		t.Errorf("gastoSriP2: want 0, got %.2f", c.gastoSriP2)
	}
	// SRI individual no genera deuda
	if c.montoDebeP1 != 0 || c.montoDebeP2 != 0 {
		t.Errorf("SRI individual no genera deuda")
	}
}

// ─── Categorías ──────────────────────────────────────────────────────────────

func TestGastosPorCategoria_Totales(t *testing.T) {
	gastos := []shared.Gasto{
		{ID: "1", PagadorID: "p1", Monto: 60, CategoriaID: "cat-A", CategoriaNombre: "Comida", EsCompartido: false, PorcentajeParticipante1: 100},
		{ID: "2", PagadorID: "p2", Monto: 40, CategoriaID: "cat-A", CategoriaNombre: "Comida", EsCompartido: false, PorcentajeParticipante2: 100},
		{ID: "3", PagadorID: "p1", Monto: 100, CategoriaID: "cat-B", CategoriaNombre: "Transporte", EsCompartido: false, PorcentajeParticipante1: 100},
	}
	c := calcularResumen(gastos, nil)

	catMap := map[string]shared.ResumenCategoria{}
	for _, rc := range c.gastosPorCategoria {
		catMap[rc.CategoriaID] = rc
	}

	if catMap["cat-A"].Total != 100 {
		t.Errorf("cat-A total: want 100, got %.2f", catMap["cat-A"].Total)
	}
	if catMap["cat-B"].Total != 100 {
		t.Errorf("cat-B total: want 100, got %.2f", catMap["cat-B"].Total)
	}
	// Porcentajes: 50% cada una sobre 200 total
	if round2(catMap["cat-A"].Porcentaje) != 50 {
		t.Errorf("cat-A porcentaje: want 50, got %.2f", catMap["cat-A"].Porcentaje)
	}
	if round2(catMap["cat-B"].Porcentaje) != 50 {
		t.Errorf("cat-B porcentaje: want 50, got %.2f", catMap["cat-B"].Porcentaje)
	}
}

func TestGastosPorCategoria_OrdenadosPorTotal(t *testing.T) {
	gastos := []shared.Gasto{
		{ID: "1", PagadorID: "p1", Monto: 30, CategoriaID: "cat-A", CategoriaNombre: "Pequeño", PorcentajeParticipante1: 100},
		{ID: "2", PagadorID: "p1", Monto: 200, CategoriaID: "cat-B", CategoriaNombre: "Grande", PorcentajeParticipante1: 100},
		{ID: "3", PagadorID: "p1", Monto: 80, CategoriaID: "cat-C", CategoriaNombre: "Mediano", PorcentajeParticipante1: 100},
	}
	c := calcularResumen(gastos, nil)
	if len(c.gastosPorCategoria) != 3 {
		t.Fatalf("want 3 categories, got %d", len(c.gastosPorCategoria))
	}
	// Deben estar en orden descendente: 200, 80, 30
	totales := []float64{c.gastosPorCategoria[0].Total, c.gastosPorCategoria[1].Total, c.gastosPorCategoria[2].Total}
	if totales[0] != 200 || totales[1] != 80 || totales[2] != 30 {
		t.Errorf("orden incorrecto, got %.0f %.0f %.0f", totales[0], totales[1], totales[2])
	}
}

// ─── Redondeo ─────────────────────────────────────────────────────────────────

func TestRedondeoDeuda(t *testing.T) {
	// $10 dividido en 3: p1Share=3.333..., rawDebeP2=3.333...
	gastos := []shared.Gasto{
		{ID: "1", PagadorID: "p1", Monto: 10, EsCompartido: true,
			PorcentajeParticipante1: 66.67, PorcentajeParticipante2: 33.33,
			CategoriaID: "cat-1"},
	}
	c := calcularResumen(gastos, nil)
	// p2Share = 10 * 33.33/100 = 3.333 → redondeado a 3.33
	if c.montoDebeP2 != 3.33 {
		t.Errorf("montoDebeP2: want 3.33, got %.4f", c.montoDebeP2)
	}
}
