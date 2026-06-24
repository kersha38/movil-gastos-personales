import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/gasto.dart';

class GastoTile extends StatelessWidget {
  final Gasto gasto;
  final String miParticipanteId;
  final Future<void> Function(bool verificado)? onVerificar;
  final VoidCallback? onTap;

  const GastoTile({
    super.key,
    required this.gasto,
    this.miParticipanteId = '',
    this.onVerificar,
    this.onTap,
  });

  bool get _puedeVerificar =>
      miParticipanteId.isNotEmpty && gasto.pagadorId != miParticipanteId;

  String get _verificadorNombre => gasto.pagadorId == gasto.participante1Id
      ? gasto.participante2Nombre
      : gasto.participante1Nombre;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final inicial = gasto.categoriaNombre.isNotEmpty
        ? gasto.categoriaNombre[0].toUpperCase()
        : '?';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
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
            '${gasto.categoriaNombre} · ${gasto.pagadorNombre}\n'
            '${formatearFechaLarga(gasto.timestamp)}',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          isThreeLine: true,
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
          onTap: onTap,
        ),
        Container(
          width: double.infinity,
          color: gasto.verificado ? cs.tertiaryContainer : cs.secondaryContainer,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          alignment: Alignment.centerRight,
          child: Text(
            gasto.verificado
                ? 'Verificado'
                : 'Pendiente verificar por $_verificadorNombre',
            style: tt.labelSmall?.copyWith(
              color: gasto.verificado
                  ? cs.onTertiaryContainer
                  : cs.onSecondaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Editar'),
              ),
            ),
            if (_puedeVerificar && onVerificar != null)
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _verificar(context, !gasto.verificado),
                  icon: Icon(
                    gasto.verificado
                        ? Icons.cancel_outlined
                        : Icons.verified_outlined,
                    size: 18,
                    color: gasto.verificado ? cs.error : cs.tertiary,
                  ),
                  label: Text(
                    gasto.verificado ? 'Quitar verificación' : 'Verificar',
                    style: TextStyle(
                      color: gasto.verificado ? cs.error : cs.tertiary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _verificar(BuildContext context, bool nuevoEstado) async {
    try {
      await onVerificar!(nuevoEstado);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo actualizar la verificación: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
