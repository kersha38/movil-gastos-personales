class Categoria {
  final String id;
  final String nombre;
  final bool esPredefinida;

  const Categoria({
    required this.id,
    required this.nombre,
    required this.esPredefinida,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) => Categoria(
        id: json['id'] as String,
        nombre: json['nombre'] as String,
        esPredefinida: json['esPredefinida'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'esPredefinida': esPredefinida,
      };
}
