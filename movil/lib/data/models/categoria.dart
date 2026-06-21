const String emojiPorDefecto = '💲';

class Categoria {
  final String id;
  final String nombre;
  final String emoji;
  final bool esPredefinida;

  const Categoria({
    required this.id,
    required this.nombre,
    this.emoji = emojiPorDefecto,
    required this.esPredefinida,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) => Categoria(
        id: json['id'] as String,
        nombre: json['nombre'] as String,
        emoji: (json['emoji'] as String?)?.isNotEmpty == true
            ? json['emoji'] as String
            : emojiPorDefecto,
        esPredefinida: json['esPredefinida'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'emoji': emoji,
        'esPredefinida': esPredefinida,
      };
}
