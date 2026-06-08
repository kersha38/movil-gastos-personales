import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../data/models/gasto.dart';

class GastoTile extends StatelessWidget {
  final Gasto gasto;
  final String miParticipanteId;
  final Future<void> Function(bool verificado)? onVerificar;

  const GastoTile({
    super.key,
    required this.gasto,
    this.miParticipanteId = '',
    this.onVerificar,
  });

  bool get _puedeVerificar =>
      miParticipanteId.isNotEmpty && gasto.pagadorId != miParticipanteId;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final inicial = gasto.categoriaNombre.isNotEmpty
        ? gasto.categoriaNombre[0].toUpperCase()
        : '?';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: gasto.verificado
            ? cs.tertiaryContainer
            : cs.primaryContainer,
        child: Text(
          inicial,
          style: TextStyle(
            color: gasto.verificado
                ? cs.onTertiaryContainer
                : cs.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(gasto.descripcion, style: tt.bodyLarge),
      subtitle: Text(
        '${gasto.categoriaNombre} · ${gasto.pagadorNombre}',
        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '\$${gasto.monto.toStringAsFixed(2)}',
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (gasto.verificado)
                Icon(Icons.verified, size: 14, color: cs.tertiary),
              if (gasto.esRecurrente)
                Icon(Icons.repeat, size: 14, color: cs.onSurfaceVariant),
              if (gasto.perteneceAlSri)
                Icon(Icons.receipt_outlined, size: 14, color: cs.onSurfaceVariant),
              if (!gasto.esCompartido)
                Icon(Icons.person_outline, size: 14, color: cs.onSurfaceVariant),
            ],
          ),
        ],
      ),
      onLongPress: _puedeVerificar && onVerificar != null
          ? () => _mostrarMenuVerificar(context)
          : null,
    );
  }

  void _mostrarMenuVerificar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  gasto.verificado
                      ? Icons.cancel_outlined
                      : Icons.verified_outlined,
                  color: gasto.verificado ? cs.error : cs.tertiary,
                ),
                title: Text(
                  gasto.verificado
                      ? 'Quitar verificación'
                      : 'Marcar como verificado',
                ),
                subtitle: Text(
                  gasto.verificado
                      ? '¿Desmarcar este gasto?'
                      : 'Confirmas que este gasto es correcto',
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  onVerificar!(!gasto.verificado);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
