import 'package:flutter/material.dart';

import '../../../data/models/gasto.dart';

class GastoTile extends StatelessWidget {
  final Gasto gasto;

  const GastoTile({super.key, required this.gasto});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final inicial = gasto.categoriaNombre.isNotEmpty
        ? gasto.categoriaNombre[0].toUpperCase()
        : '?';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: cs.primaryContainer,
        child: Text(
          inicial,
          style: TextStyle(
            color: cs.onPrimaryContainer,
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
              if (gasto.esRecurrente)
                Icon(
                  Icons.repeat,
                  size: 14,
                  color: cs.onSurfaceVariant,
                ),
              if (gasto.perteneceAlSri)
                Icon(
                  Icons.receipt_outlined,
                  size: 14,
                  color: cs.onSurfaceVariant,
                ),
              if (!gasto.esCompartido)
                Icon(
                  Icons.person_outline,
                  size: 14,
                  color: cs.onSurfaceVariant,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
