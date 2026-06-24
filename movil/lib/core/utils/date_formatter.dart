import 'package:intl/intl.dart';

String formatearFechaLarga(DateTime fecha) {
  final local = fecha.toLocal();
  final formato = DateFormat("EEEE, dd 'de' MMMM 'del' yyyy", 'es');
  final texto = formato.format(local);
  return texto[0].toUpperCase() + texto.substring(1);
}
