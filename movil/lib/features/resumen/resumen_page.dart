import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../data/models/resumen.dart';
import 'resumen_notifier.dart';

class ResumenPage extends StatefulWidget {
  final ResumenNotifier notifier;

  const ResumenPage({super.key, required this.notifier});

  @override
  State<ResumenPage> createState() => _ResumenPageState();
}

class _ResumenPageState extends State<ResumenPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.notifier.cargar());
  }

  Future<void> _mostrarFiltroCategorias() async {
    final notifier = widget.notifier;
    if (notifier.categoriasDisponibles.isEmpty) return;

    var seleccion = Set<String>.from(notifier.categoriasFiltro);
    final resultado = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Filtrar por categoría',
                        style: Theme.of(ctx).textTheme.titleMedium),
                    TextButton(
                      onPressed: () => setSheetState(() => seleccion.clear()),
                      child: const Text('Limpiar'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: notifier.categoriasDisponibles.map((c) {
                    final activo = seleccion.contains(c.categoriaId);
                    return FilterChip(
                      label: Text(
                        '${c.categoriaNombre}  \$${c.total.toStringAsFixed(0)}',
                      ),
                      selected: activo,
                      onSelected: (v) => setSheetState(() {
                        if (v) {
                          seleccion.add(c.categoriaId);
                        } else {
                          seleccion.remove(c.categoriaId);
                        }
                      }),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, seleccion),
                  child: const Text('Aplicar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (resultado != null) {
      notifier.aplicarFiltro(resultado);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.notifier,
      builder: (ctx, _) {
        final notifier = widget.notifier;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Resumen'),
            actions: [
              if (notifier.resumen != null)
                IconButton(
                  icon: Icon(
                    notifier.filtroActivo
                        ? Icons.filter_list
                        : Icons.filter_list_outlined,
                  ),
                  tooltip: 'Filtrar por categoría',
                  onPressed: _mostrarFiltroCategorias,
                ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: 'Configuración',
                onPressed: () => context.push('/settings'),
              ),
            ],
          ),
          body: Column(
            children: [
              _MesSelector(notifier: notifier),
              Expanded(child: _Body(notifier: notifier)),
            ],
          ),
        );
      },
    );
  }
}

class _MesSelector extends StatelessWidget {
  final ResumenNotifier notifier;

  const _MesSelector({required this.notifier});

  static const _meses = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ColoredBox(
      color: cs.primary,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.chevron_left, color: cs.onPrimary),
              tooltip: 'Mes anterior',
              onPressed: () => notifier.cambiarMes(-1),
            ),
            Text(
              '${_meses[notifier.selectedMes - 1]} ${notifier.selectedAnio}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: cs.onPrimary,
                  ),
            ),
            IconButton(
              icon: Icon(Icons.chevron_right, color: cs.onPrimary),
              tooltip: 'Mes siguiente',
              onPressed: () => notifier.cambiarMes(1),
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final ResumenNotifier notifier;

  const _Body({required this.notifier});

  @override
  Widget build(BuildContext context) {
    if (notifier.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (notifier.error != null) {
      return _ErrorView(
        message: notifier.error!,
        onRetry: notifier.cargar,
      );
    }
    if (notifier.resumen == null) {
      return const Center(child: Text('Sin datos para este mes'));
    }
    return _ResumenContent(notifier: notifier);
  }
}

class _ResumenContent extends StatelessWidget {
  final ResumenNotifier notifier;

  const _ResumenContent({required this.notifier});

  @override
  Widget build(BuildContext context) {
    final resumen = notifier.resumen!;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _TotalCard(
          total: notifier.totalFiltrado,
          filtroActivo: notifier.filtroActivo,
          numCategorias: notifier.categoriasFiltro.length,
        ),
        const SizedBox(height: AppSpacing.sm),
        _DeudaCard(balance: resumen.balance),
        const SizedBox(height: AppSpacing.sm),
        _GastosPorPersonaCard(balance: resumen.balance),
        if (resumen.transferencias.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          _TransferenciasCard(transferencias: resumen.transferencias, balance: resumen.balance),
        ],
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _TotalCard extends StatelessWidget {
  final double total;
  final bool filtroActivo;
  final int numCategorias;

  const _TotalCard({
    required this.total,
    required this.filtroActivo,
    required this.numCategorias,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Card(
      color: cs.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              filtroActivo
                  ? 'Total filtrado ($numCategorias ${numCategorias == 1 ? 'categoría' : 'categorías'})'
                  : 'Total del mes',
              style: tt.labelLarge?.copyWith(color: cs.onPrimaryContainer),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '\$${total.toStringAsFixed(2)}',
              style: tt.displaySmall?.copyWith(
                color: cs.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (filtroActivo) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'El saldo y desglose muestran el mes completo',
                style: tt.bodySmall?.copyWith(
                  color: cs.onPrimaryContainer.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DeudaCard extends StatelessWidget {
  final Balance balance;

  const _DeudaCard({required this.balance});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    String deudor, acreedor;
    double monto;
    bool alDia = false;

    if (balance.montoDebeP1 > 0) {
      deudor = balance.participante1Nombre;
      acreedor = balance.participante2Nombre;
      monto = balance.montoDebeP1;
    } else if (balance.montoDebeP2 > 0) {
      deudor = balance.participante2Nombre;
      acreedor = balance.participante1Nombre;
      monto = balance.montoDebeP2;
    } else {
      deudor = '';
      acreedor = '';
      monto = 0;
      alDia = true;
    }

    final color = alDia ? cs.tertiaryContainer : cs.errorContainer;
    final onColor = alDia ? cs.onTertiaryContainer : cs.onErrorContainer;

    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(
              alDia ? Icons.check_circle_outline : Icons.account_balance_wallet_outlined,
              color: onColor,
              size: 28,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Saldo', style: tt.labelLarge?.copyWith(color: onColor)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    alDia
                        ? 'Están al día'
                        : '$deudor debe \$${monto.toStringAsFixed(2)} a $acreedor',
                    style: tt.bodyMedium?.copyWith(
                      color: onColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!alDia && (balance.transferenciasP1aP2 > 0 || balance.transferenciasP2aP1 > 0))
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        'Incluye transferencias realizadas',
                        style: tt.bodySmall?.copyWith(color: onColor.withValues(alpha: 0.8)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GastosPorPersonaCard extends StatelessWidget {
  final Balance balance;

  const _GastosPorPersonaCard({required this.balance});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Desglose por participante', style: tt.titleMedium),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _PersonaColumn(
                    nombre: balance.participante1Nombre,
                    totalPagado: balance.montoPagadoP1,
                    individual: balance.gastoIndividualP1,
                    compartido: balance.gastoCompartidoP1,
                    sri: balance.gastoSriP1,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _PersonaColumn(
                    nombre: balance.participante2Nombre,
                    totalPagado: balance.montoPagadoP2,
                    individual: balance.gastoIndividualP2,
                    compartido: balance.gastoCompartidoP2,
                    sri: balance.gastoSriP2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonaColumn extends StatelessWidget {
  final String nombre;
  final double totalPagado;
  final double individual;
  final double compartido;
  final double sri;

  const _PersonaColumn({
    required this.nombre,
    required this.totalPagado,
    required this.individual,
    required this.compartido,
    required this.sri,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            nombre,
            style: tt.labelMedium?.copyWith(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '\$${totalPagado.toStringAsFixed(2)}',
            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.xs),
          _Row(label: 'Individual', monto: individual),
          _Row(label: 'Compartido', monto: compartido),
          if (sri > 0) _Row(label: 'SRI', monto: sri),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final double monto;

  const _Row({required this.label, required this.monto});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          Text('\$${monto.toStringAsFixed(2)}',
              style: tt.bodySmall),
        ],
      ),
    );
  }
}

class _TransferenciasCard extends StatelessWidget {
  final List transferencias;
  final Balance balance;

  const _TransferenciasCard({
    required this.transferencias,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.swap_horiz, size: 18),
                const SizedBox(width: AppSpacing.xs),
                Text('Transferencias', style: tt.titleMedium),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (balance.transferenciasP1aP2 > 0)
              _TransRow(
                label:
                    '${balance.participante1Nombre} → ${balance.participante2Nombre}',
                monto: balance.transferenciasP1aP2,
                color: cs.primary,
              ),
            if (balance.transferenciasP2aP1 > 0)
              _TransRow(
                label:
                    '${balance.participante2Nombre} → ${balance.participante1Nombre}',
                monto: balance.transferenciasP2aP1,
                color: cs.secondary,
              ),
          ],
        ),
      ),
    );
  }
}

class _TransRow extends StatelessWidget {
  final String label;
  final double monto;
  final Color color;

  const _TransRow({
    required this.label,
    required this.monto,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(Icons.arrow_forward, size: 14, color: color),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(label,
                      style: tt.bodySmall, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
          Text(
            '\$${monto.toStringAsFixed(2)}',
            style: tt.bodySmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
