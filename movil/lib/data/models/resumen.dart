class ResumenCategoria {
  final String categoriaId;
  final String categoriaNombre;
  final double total;
  final double porcentaje;

  const ResumenCategoria({
    required this.categoriaId,
    required this.categoriaNombre,
    required this.total,
    required this.porcentaje,
  });

  factory ResumenCategoria.fromJson(Map<String, dynamic> json) =>
      ResumenCategoria(
        categoriaId: json['categoriaId'] as String,
        categoriaNombre: json['categoriaNombre'] as String,
        total: (json['total'] as num).toDouble(),
        porcentaje: (json['porcentaje'] as num).toDouble(),
      );
}

class Balance {
  final String participante1Id;
  final String participante1Nombre;
  final String participante2Id;
  final String participante2Nombre;
  final double montoPagadoP1;
  final double montoPagadoP2;
  final double montoDebeP1;
  final double montoDebeP2;

  const Balance({
    required this.participante1Id,
    required this.participante1Nombre,
    required this.participante2Id,
    required this.participante2Nombre,
    required this.montoPagadoP1,
    required this.montoPagadoP2,
    required this.montoDebeP1,
    required this.montoDebeP2,
  });

  factory Balance.fromJson(Map<String, dynamic> json) => Balance(
        participante1Id: json['participante1Id'] as String,
        participante1Nombre: json['participante1Nombre'] as String,
        participante2Id: json['participante2Id'] as String,
        participante2Nombre: json['participante2Nombre'] as String,
        montoPagadoP1: (json['montoPagadoP1'] as num).toDouble(),
        montoPagadoP2: (json['montoPagadoP2'] as num).toDouble(),
        montoDebeP1: (json['montoDebeP1'] as num).toDouble(),
        montoDebeP2: (json['montoDebeP2'] as num).toDouble(),
      );
}

class Resumen {
  final double totalMes;
  final List<ResumenCategoria> gastosPorCategoria;
  final Balance balance;

  const Resumen({
    required this.totalMes,
    required this.gastosPorCategoria,
    required this.balance,
  });

  factory Resumen.fromJson(Map<String, dynamic> json) => Resumen(
        totalMes: (json['totalMes'] as num).toDouble(),
        gastosPorCategoria: (json['gastosPorCategoria'] as List<dynamic>)
            .map((e) =>
                ResumenCategoria.fromJson(e as Map<String, dynamic>))
            .toList(),
        balance: Balance.fromJson(json['balance'] as Map<String, dynamic>),
      );
}
