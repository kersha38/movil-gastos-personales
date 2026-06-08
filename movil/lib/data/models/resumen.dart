import 'transferencia.dart';

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
  final double gastoIndividualP1;
  final double gastoIndividualP2;
  final double gastoCompartidoP1;
  final double gastoCompartidoP2;
  final double gastoSriP1;
  final double gastoSriP2;
  final double montoDebeP1;
  final double montoDebeP2;
  final double transferenciasP1aP2;
  final double transferenciasP2aP1;

  const Balance({
    required this.participante1Id,
    required this.participante1Nombre,
    required this.participante2Id,
    required this.participante2Nombre,
    required this.montoPagadoP1,
    required this.montoPagadoP2,
    required this.gastoIndividualP1,
    required this.gastoIndividualP2,
    required this.gastoCompartidoP1,
    required this.gastoCompartidoP2,
    required this.gastoSriP1,
    required this.gastoSriP2,
    required this.montoDebeP1,
    required this.montoDebeP2,
    required this.transferenciasP1aP2,
    required this.transferenciasP2aP1,
  });

  factory Balance.fromJson(Map<String, dynamic> json) => Balance(
        participante1Id: json['participante1Id'] as String,
        participante1Nombre: json['participante1Nombre'] as String,
        participante2Id: json['participante2Id'] as String,
        participante2Nombre: json['participante2Nombre'] as String,
        montoPagadoP1: (json['montoPagadoP1'] as num).toDouble(),
        montoPagadoP2: (json['montoPagadoP2'] as num).toDouble(),
        gastoIndividualP1: (json['gastoIndividualP1'] as num? ?? 0).toDouble(),
        gastoIndividualP2: (json['gastoIndividualP2'] as num? ?? 0).toDouble(),
        gastoCompartidoP1:
            (json['gastoCompartidoP1'] as num? ?? 0).toDouble(),
        gastoCompartidoP2:
            (json['gastoCompartidoP2'] as num? ?? 0).toDouble(),
        gastoSriP1: (json['gastoSriP1'] as num? ?? 0).toDouble(),
        gastoSriP2: (json['gastoSriP2'] as num? ?? 0).toDouble(),
        montoDebeP1: (json['montoDebeP1'] as num).toDouble(),
        montoDebeP2: (json['montoDebeP2'] as num).toDouble(),
        transferenciasP1aP2:
            (json['transferenciasP1aP2'] as num? ?? 0).toDouble(),
        transferenciasP2aP1:
            (json['transferenciasP2aP1'] as num? ?? 0).toDouble(),
      );
}

class Resumen {
  final double totalMes;
  final List<ResumenCategoria> gastosPorCategoria;
  final Balance balance;
  final List<Transferencia> transferencias;

  const Resumen({
    required this.totalMes,
    required this.gastosPorCategoria,
    required this.balance,
    required this.transferencias,
  });

  factory Resumen.fromJson(Map<String, dynamic> json) => Resumen(
        totalMes: (json['totalMes'] as num).toDouble(),
        gastosPorCategoria: (json['gastosPorCategoria'] as List<dynamic>)
            .map((e) =>
                ResumenCategoria.fromJson(e as Map<String, dynamic>))
            .toList(),
        balance: Balance.fromJson(json['balance'] as Map<String, dynamic>),
        transferencias: (json['transferencias'] as List<dynamic>? ?? [])
            .map((e) => Transferencia.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
