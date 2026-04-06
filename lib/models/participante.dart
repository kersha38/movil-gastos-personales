class Participante {
  final String id;
  final String nombre;

  Participante({required this.id, required this.nombre});

  factory Participante.fromJson(Map<String, dynamic> json) => Participante(
        id: json['id'] as String,
        nombre: json['nombre'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
      };
}
