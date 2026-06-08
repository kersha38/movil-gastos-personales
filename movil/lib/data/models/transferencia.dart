String _isoWithOffsetT(DateTime dt) {
  final o = dt.timeZoneOffset;
  final sign = o.isNegative ? '-' : '+';
  final h = o.inHours.abs().toString().padLeft(2, '0');
  final m = (o.inMinutes.abs() % 60).toString().padLeft(2, '0');
  return '${dt.toIso8601String().substring(0, 19)}$sign$h:$m';
}

class Transferencia {
  final String? id;
  final double monto;
  final String descripcion;
  final String origenId;
  final String origenNombre;
  final String destinoId;
  final String destinoNombre;
  final DateTime timestamp;

  const Transferencia({
    this.id,
    required this.monto,
    required this.descripcion,
    required this.origenId,
    required this.origenNombre,
    required this.destinoId,
    required this.destinoNombre,
    required this.timestamp,
  });

  factory Transferencia.fromJson(Map<String, dynamic> json) => Transferencia(
        id: json['id'] as String?,
        monto: (json['monto'] as num).toDouble(),
        descripcion: json['descripcion'] as String? ?? '',
        origenId: json['origenId'] as String,
        origenNombre: json['origenNombre'] as String,
        destinoId: json['destinoId'] as String,
        destinoNombre: json['destinoNombre'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'monto': monto,
        'descripcion': descripcion,
        'origenId': origenId,
        'origenNombre': origenNombre,
        'destinoId': destinoId,
        'destinoNombre': destinoNombre,
        'timestamp': _isoWithOffsetT(timestamp),
      };
}
