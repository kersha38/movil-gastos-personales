import 'package:fl_chart/fl_chart.dart';
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.notifier,
      builder: (context, _) {
        final notifier = widget.notifier;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Resumen'),
            actions: [
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
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Mes anterior',
            onPressed: () => notifier.cambiarMes(-1),
          ),
          Text(
            '${_meses[notifier.selectedMes - 1]} ${notifier.selectedAnio}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Mes siguiente',
            onPressed: () => notifier.cambiarMes(1),
          ),
        ],
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
    return _ResumenContent(resumen: notifier.resumen!);
  }
}

class _ResumenContent extends StatelessWidget {
  final Resumen resumen;

  const _ResumenContent({required this.resumen});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _TotalCard(total: resumen.totalMes),
        const SizedBox(height: AppSpacing.sm),
        _BalanceCard(balance: resumen.balance),
        const SizedBox(height: AppSpacing.sm),
        if (resumen.gastosPorCategoria.isNotEmpty) ...[
          _PieChartCard(categorias: resumen.gastosPorCategoria),
          const SizedBox(height: AppSpacing.sm),
          _CategoriasList(categorias: resumen.gastosPorCategoria),
        ],
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _TotalCard extends StatelessWidget {
  final double total;

  const _TotalCard({required this.total});

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
              'Total del mes',
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
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final Balance balance;

  const _BalanceCard({required this.balance});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    String mensaje;
    if (balance.montoDebeP1 > 0) {
      mensaje =
          '${balance.participante1Nombre} debe \$${balance.montoDebeP1.toStringAsFixed(2)} a ${balance.participante2Nombre}';
    } else if (balance.montoDebeP2 > 0) {
      mensaje =
          '${balance.participante2Nombre} debe \$${balance.montoDebeP2.toStringAsFixed(2)} a ${balance.participante1Nombre}';
    } else {
      mensaje = 'Están al día';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Balance', style: tt.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(mensaje, style: tt.bodyMedium),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _ParticipantePago(
                    nombre: balance.participante1Nombre,
                    monto: balance.montoPagadoP1,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _ParticipantePago(
                    nombre: balance.participante2Nombre,
                    monto: balance.montoPagadoP2,
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

class _ParticipantePago extends StatelessWidget {
  final String nombre;
  final double monto;

  const _ParticipantePago({required this.nombre, required this.monto});

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
          Text(nombre, style: tt.labelMedium),
          Text(
            '\$${monto.toStringAsFixed(2)}',
            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _PieChartCard extends StatelessWidget {
  final List<ResumenCategoria> categorias;

  const _PieChartCard({required this.categorias});

  static const _chartColors = [
    Color(0xFF6750A4),
    Color(0xFF7B61FF),
    Color(0xFF03DAC6),
    Color(0xFFFF6B6B),
    Color(0xFFFFB347),
    Color(0xFF4CAF50),
    Color(0xFF2196F3),
    Color(0xFFE91E63),
  ];

  @override
  Widget build(BuildContext context) {
    final sections = categorias.asMap().entries.map((entry) {
      final i = entry.key;
      final cat = entry.value;
      return PieChartSectionData(
        value: cat.total,
        color: _chartColors[i % _chartColors.length],
        title: '${cat.porcentaje.toStringAsFixed(0)}%',
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Por categoría',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoriasList extends StatelessWidget {
  final List<ResumenCategoria> categorias;

  const _CategoriasList({required this.categorias});

  static const _chartColors = [
    Color(0xFF6750A4),
    Color(0xFF7B61FF),
    Color(0xFF03DAC6),
    Color(0xFFFF6B6B),
    Color(0xFFFFB347),
    Color(0xFF4CAF50),
    Color(0xFF2196F3),
    Color(0xFFE91E63),
  ];

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: categorias.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final cat = categorias[index];
          final color = _chartColors[index % _chartColors.length];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.2),
              child: Icon(Icons.circle, color: color, size: 12),
            ),
            title: Text(cat.categoriaNombre),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${cat.total.toStringAsFixed(2)}',
                  style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${cat.porcentaje.toStringAsFixed(1)}%',
                  style: tt.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        },
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
