class GastoMensual {
  final String? id;
  final String tipo; // 'plantilla' | 'instancia'
  final String? plantillaId;
  final String? yearMonth;
  final String? gastoId;
  final double monto;
  final String descripcion;
  final String categoriaId;
  final String categoriaNombre;
  final String pagadorId;
  final String pagadorNombre;
  final String participante1Id;
  final String participante1Nombre;
  final String participante2Id;
  final String participante2Nombre;
  final bool esCompartido;
  final double porcentajeParticipante1;
  final double porcentajeParticipante2;
  final bool perteneceAlSri;
  final String? creadoEn;

  const GastoMensual({
    this.id,
    required this.tipo,
    this.plantillaId,
    this.yearMonth,
    this.gastoId,
    required this.monto,
    required this.descripcion,
    required this.categoriaId,
    required this.categoriaNombre,
    required this.pagadorId,
    required this.pagadorNombre,
    required this.participante1Id,
    required this.participante1Nombre,
    required this.participante2Id,
    required this.participante2Nombre,
    required this.esCompartido,
    required this.porcentajeParticipante1,
    required this.porcentajeParticipante2,
    required this.perteneceAlSri,
    this.creadoEn,
  });

  factory GastoMensual.fromJson(Map<String, dynamic> json) => GastoMensual(
        id: json['id'] as String?,
        tipo: json['tipo'] as String? ?? 'plantilla',
        plantillaId: json['plantillaId'] as String?,
        yearMonth: json['yearMonth'] as String?,
        gastoId: json['gastoId'] as String?,
        monto: (json['monto'] as num).toDouble(),
        descripcion: json['descripcion'] as String,
        categoriaId: json['categoriaId'] as String,
        categoriaNombre: json['categoriaNombre'] as String,
        pagadorId: json['pagadorId'] as String,
        pagadorNombre: json['pagadorNombre'] as String,
        participante1Id: json['participante1Id'] as String,
        participante1Nombre: json['participante1Nombre'] as String,
        participante2Id: json['participante2Id'] as String,
        participante2Nombre: json['participante2Nombre'] as String,
        esCompartido: json['esCompartido'] as bool,
        porcentajeParticipante1:
            (json['porcentajeParticipante1'] as num).toDouble(),
        porcentajeParticipante2:
            (json['porcentajeParticipante2'] as num).toDouble(),
        perteneceAlSri: json['perteneceAlSri'] as bool,
        creadoEn: json['creadoEn'] as String?,
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'tipo': tipo,
        if (plantillaId != null) 'plantillaId': plantillaId,
        if (yearMonth != null) 'yearMonth': yearMonth,
        if (gastoId != null) 'gastoId': gastoId,
        'monto': monto,
        'descripcion': descripcion,
        'categoriaId': categoriaId,
        'categoriaNombre': categoriaNombre,
        'pagadorId': pagadorId,
        'pagadorNombre': pagadorNombre,
        'participante1Id': participante1Id,
        'participante1Nombre': participante1Nombre,
        'participante2Id': participante2Id,
        'participante2Nombre': participante2Nombre,
        'esCompartido': esCompartido,
        'porcentajeParticipante1': porcentajeParticipante1,
        'porcentajeParticipante2': porcentajeParticipante2,
        'perteneceAlSri': perteneceAlSri,
        if (creadoEn != null) 'creadoEn': creadoEn,
      };

  GastoMensual copyWith({
    String? id,
    String? tipo,
    double? monto,
    String? descripcion,
    String? categoriaId,
    String? categoriaNombre,
    String? pagadorId,
    String? pagadorNombre,
    String? participante1Id,
    String? participante1Nombre,
    String? participante2Id,
    String? participante2Nombre,
    bool? esCompartido,
    double? porcentajeParticipante1,
    double? porcentajeParticipante2,
    bool? perteneceAlSri,
  }) => GastoMensual(
        id: id ?? this.id,
        tipo: tipo ?? this.tipo,
        plantillaId: plantillaId,
        yearMonth: yearMonth,
        gastoId: gastoId,
        monto: monto ?? this.monto,
        descripcion: descripcion ?? this.descripcion,
        categoriaId: categoriaId ?? this.categoriaId,
        categoriaNombre: categoriaNombre ?? this.categoriaNombre,
        pagadorId: pagadorId ?? this.pagadorId,
        pagadorNombre: pagadorNombre ?? this.pagadorNombre,
        participante1Id: participante1Id ?? this.participante1Id,
        participante1Nombre: participante1Nombre ?? this.participante1Nombre,
        participante2Id: participante2Id ?? this.participante2Id,
        participante2Nombre: participante2Nombre ?? this.participante2Nombre,
        esCompartido: esCompartido ?? this.esCompartido,
        porcentajeParticipante1:
            porcentajeParticipante1 ?? this.porcentajeParticipante1,
        porcentajeParticipante2:
            porcentajeParticipante2 ?? this.porcentajeParticipante2,
        perteneceAlSri: perteneceAlSri ?? this.perteneceAlSri,
        creadoEn: creadoEn,
      );
}
