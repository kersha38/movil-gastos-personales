class Gasto {
  final String? id;
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
  final bool esRecurrente;
  final bool perteneceAlSri;
  final DateTime timestamp;

  const Gasto({
    this.id,
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
    required this.esRecurrente,
    required this.perteneceAlSri,
    required this.timestamp,
  });

  factory Gasto.fromJson(Map<String, dynamic> json) => Gasto(
        id: json['id'] as String?,
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
        esRecurrente: json['esRecurrente'] as bool,
        perteneceAlSri: json['perteneceAlSri'] as bool,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
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
        'esRecurrente': esRecurrente,
        'perteneceAlSri': perteneceAlSri,
        'timestamp': timestamp.toUtc().toIso8601String(),
      };
}
