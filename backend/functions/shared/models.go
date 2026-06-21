package shared

// Categoria represents an expense category.
type Categoria struct {
	ID            string `json:"id" dynamodbav:"categoriaId"`
	Nombre        string `json:"nombre" dynamodbav:"nombre"`
	Emoji         string `json:"emoji" dynamodbav:"emoji"`
	EsPredefinida bool   `json:"esPredefinida" dynamodbav:"esPredefinida"`
}

// Participante represents one of the two members of the couple.
type Participante struct {
	ID     string `json:"id" dynamodbav:"participanteId"`
	Nombre string `json:"nombre" dynamodbav:"nombre"`
}

// Gasto represents a single expense entry.
type Gasto struct {
	ID                      string  `json:"id" dynamodbav:"gastoId"`
	YearMonth               string  `json:"-" dynamodbav:"yearMonth"`
	Monto                   float64 `json:"monto" dynamodbav:"monto"`
	Descripcion             string  `json:"descripcion" dynamodbav:"descripcion"`
	CategoriaID             string  `json:"categoriaId" dynamodbav:"categoriaId"`
	CategoriaNombre         string  `json:"categoriaNombre" dynamodbav:"categoriaNombre"`
	PagadorID               string  `json:"pagadorId" dynamodbav:"pagadorId"`
	PagadorNombre           string  `json:"pagadorNombre" dynamodbav:"pagadorNombre"`
	Participante1ID         string  `json:"participante1Id" dynamodbav:"participante1Id"`
	Participante1Nombre     string  `json:"participante1Nombre" dynamodbav:"participante1Nombre"`
	Participante2ID         string  `json:"participante2Id" dynamodbav:"participante2Id"`
	Participante2Nombre     string  `json:"participante2Nombre" dynamodbav:"participante2Nombre"`
	EsCompartido            bool    `json:"esCompartido" dynamodbav:"esCompartido"`
	PorcentajeParticipante1 float64 `json:"porcentajeParticipante1" dynamodbav:"porcentajeParticipante1"`
	PorcentajeParticipante2 float64 `json:"porcentajeParticipante2" dynamodbav:"porcentajeParticipante2"`
	EsRecurrente            bool    `json:"esRecurrente" dynamodbav:"esRecurrente"`
	PerteneceAlSri          bool    `json:"perteneceAlSri" dynamodbav:"perteneceAlSri"`
	Timestamp               string  `json:"timestamp" dynamodbav:"timestamp"`
	Verificado              bool    `json:"verificado" dynamodbav:"verificado"`
	VerificadoPor           string  `json:"verificadoPor,omitempty" dynamodbav:"verificadoPor,omitempty"`
}

// Transferencia represents a money transfer between participants.
type Transferencia struct {
	ID           string  `json:"id" dynamodbav:"transferenciaId"`
	YearMonth    string  `json:"-" dynamodbav:"yearMonth"`
	Monto        float64 `json:"monto" dynamodbav:"monto"`
	Descripcion  string  `json:"descripcion" dynamodbav:"descripcion"`
	OrigenID     string  `json:"origenId" dynamodbav:"origenId"`
	OrigenNombre string  `json:"origenNombre" dynamodbav:"origenNombre"`
	DestinoID    string  `json:"destinoId" dynamodbav:"destinoId"`
	DestinoNombre string `json:"destinoNombre" dynamodbav:"destinoNombre"`
	Timestamp    string  `json:"timestamp" dynamodbav:"timestamp"`
}

// GastoMensual represents a recurring expense template or a generated instance.
type GastoMensual struct {
	ID                      string  `json:"id" dynamodbav:"gastoMensualId"`
	Tipo                    string  `json:"tipo" dynamodbav:"tipo"` // "plantilla" | "instancia"
	PlantillaID             string  `json:"plantillaId,omitempty" dynamodbav:"plantillaId,omitempty"`
	YearMonth               string  `json:"yearMonth,omitempty" dynamodbav:"yearMonth,omitempty"`
	GastoID                 string  `json:"gastoId,omitempty" dynamodbav:"gastoId,omitempty"`
	Monto                   float64 `json:"monto" dynamodbav:"monto"`
	Descripcion             string  `json:"descripcion" dynamodbav:"descripcion"`
	CategoriaID             string  `json:"categoriaId" dynamodbav:"categoriaId"`
	CategoriaNombre         string  `json:"categoriaNombre" dynamodbav:"categoriaNombre"`
	PagadorID               string  `json:"pagadorId" dynamodbav:"pagadorId"`
	PagadorNombre           string  `json:"pagadorNombre" dynamodbav:"pagadorNombre"`
	Participante1ID         string  `json:"participante1Id" dynamodbav:"participante1Id"`
	Participante1Nombre     string  `json:"participante1Nombre" dynamodbav:"participante1Nombre"`
	Participante2ID         string  `json:"participante2Id" dynamodbav:"participante2Id"`
	Participante2Nombre     string  `json:"participante2Nombre" dynamodbav:"participante2Nombre"`
	EsCompartido            bool    `json:"esCompartido" dynamodbav:"esCompartido"`
	PorcentajeParticipante1 float64 `json:"porcentajeParticipante1" dynamodbav:"porcentajeParticipante1"`
	PorcentajeParticipante2 float64 `json:"porcentajeParticipante2" dynamodbav:"porcentajeParticipante2"`
	PerteneceAlSri          bool    `json:"perteneceAlSri" dynamodbav:"perteneceAlSri"`
	CreadoEn                string  `json:"creadoEn" dynamodbav:"creadoEn"`
}

// ResumenCategoria holds the total and percentage for one category in a summary.
type ResumenCategoria struct {
	CategoriaID     string  `json:"categoriaId"`
	CategoriaNombre string  `json:"categoriaNombre"`
	Total           float64 `json:"total"`
	Porcentaje      float64 `json:"porcentaje"`
}

// Balance describes how much each participant has paid, owes, and spent by type.
type Balance struct {
	Participante1ID      string  `json:"participante1Id"`
	Participante1Nombre  string  `json:"participante1Nombre"`
	Participante2ID      string  `json:"participante2Id"`
	Participante2Nombre  string  `json:"participante2Nombre"`
	MontoPagadoP1        float64 `json:"montoPagadoP1"`
	MontoPagadoP2        float64 `json:"montoPagadoP2"`
	GastoIndividualP1    float64 `json:"gastoIndividualP1"`
	GastoIndividualP2    float64 `json:"gastoIndividualP2"`
	GastoCompartidoP1    float64 `json:"gastoCompartidoP1"`
	GastoCompartidoP2    float64 `json:"gastoCompartidoP2"`
	GastoSriP1           float64 `json:"gastoSriP1"`
	GastoSriP2           float64 `json:"gastoSriP2"`
	MontoDebeP1          float64 `json:"montoDebeP1"`
	MontoDebeP2          float64 `json:"montoDebeP2"`
	TransferenciasP1aP2  float64 `json:"transferenciasP1aP2"`
	TransferenciasP2aP1  float64 `json:"transferenciasP2aP1"`
}

// Resumen is the monthly summary response.
type Resumen struct {
	TotalMes           float64            `json:"totalMes"`
	GastosPorCategoria []ResumenCategoria `json:"gastosPorCategoria"`
	Balance            Balance            `json:"balance"`
	Transferencias     []Transferencia    `json:"transferencias"`
}
