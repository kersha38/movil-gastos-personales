import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../data/models/resumen.dart';
import 'graficos_notifier.dart';

class GraficosPage extends StatefulWidget {
  final GraficosNotifier notifier;

  const GraficosPage({super.key, required this.notifier});

  @override
  State<GraficosPage> createState() => _GraficosPageState();
}

class _GraficosPageState extends State<GraficosPage> {
  int? _touched;
  Set<String> _categoriaIdsFiltro = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => widget.notifier.cargar());
  }

  List<ResumenCategoria> _filtrarYRecalcular(List<ResumenCategoria> todas) {
    if (_categoriaIdsFiltro.isEmpty) return todas;
    final filtradas = todas
        .where((c) => _categoriaIdsFiltro.contains(c.categoriaId))
        .toList();
    final totalFiltrado = filtradas.fold<double>(0, (s, c) => s + c.total);
    if (totalFiltrado <= 0) return filtradas;
    return filtradas
        .map((c) => ResumenCategoria(
              categoriaId: c.categoriaId,
              categoriaNombre: c.categoriaNombre,
              total: c.total,
              porcentaje: (c.total / totalFiltrado) * 100,
            ))
        .toList();
  }

  Future<void> _mostrarFiltroCategorias(List<ResumenCategoria> disponibles) async {
    var seleccion = Set<String>.from(_categoriaIdsFiltro);
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
                  children: disponibles.map((c) {
                    final activo = seleccion.contains(c.categoriaId);
                    return FilterChip(
                      label: Text(c.categoriaNombre),
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
    if (resultado != null) setState(() => _categoriaIdsFiltro = resultado);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.notifier,
      builder: (context, _) {
        final notifier = widget.notifier;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Gráficos'),
            actions: [
              IconButton(
                icon: Icon(
                  _categoriaIdsFiltro.isEmpty
                      ? Icons.filter_list_outlined
                      : Icons.filter_list,
                ),
                tooltip: 'Filtrar por categoría',
                onPressed: notifier.categorias.isEmpty
                    ? null
                    : () => _mostrarFiltroCategorias(notifier.categorias),
              ),
            ],
          ),
          body: Column(
            children: [
              _MesSelector(notifier: notifier),
              Expanded(child: _Body(
                notifier: notifier,
                categorias: _filtrarYRecalcular(notifier.categorias),
                touched: _touched,
                onTouch: (i) => setState(() => _touched = i),
              )),
            ],
          ),
        );
      },
    );
  }
}

class _MesSelector extends StatelessWidget {
  final GraficosNotifier notifier;

  const _MesSelector({required this.notifier});

  static const _meses = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
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
            style: tt.titleMedium,
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
  final GraficosNotifier notifier;
  final List<ResumenCategoria> categorias;
  final int? touched;
  final ValueChanged<int?> onTouch;

  const _Body({
    required this.notifier,
    required this.categorias,
    required this.touched,
    required this.onTouch,
  });

  @override
  Widget build(BuildContext context) {
    if (notifier.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (notifier.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error),
              const SizedBox(height: AppSpacing.md),
              Text(notifier.error!, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: notifier.cargar,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    if (notifier.categorias.isEmpty) {
      return const Center(child: Text('Sin gastos en este mes'));
    }
    if (categorias.isEmpty) {
      return const Center(child: Text('Sin gastos para esta categoría'));
    }
    return _GraficosContent(
      categorias: categorias,
      touched: touched,
      onTouch: onTouch,
    );
  }
}

class _GraficosContent extends StatelessWidget {
  final List<ResumenCategoria> categorias;
  final int? touched;
  final ValueChanged<int?> onTouch;

  const _GraficosContent({
    required this.categorias,
    required this.touched,
    required this.onTouch,
  });

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
    final totalGlobal =
        categorias.fold<double>(0, (s, c) => s + c.total);

    final sections = categorias.asMap().entries.map((entry) {
      final i = entry.key;
      final cat = entry.value;
      final isTouched = touched == i;
      return PieChartSectionData(
        value: cat.total,
        color: _chartColors[i % _chartColors.length],
        title: isTouched ? '\$${cat.total.toStringAsFixed(0)}' : '${cat.porcentaje.toStringAsFixed(0)}%',
        radius: isTouched ? 100 : 80,
        titleStyle: TextStyle(
          fontSize: isTouched ? 14 : 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gastos por categoría', style: tt.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Total: \$${totalGlobal.toStringAsFixed(2)}',
                  style: tt.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 240,
                  child: PieChart(
                    PieChartData(
                      sections: sections,
                      centerSpaceRadius: 48,
                      sectionsSpace: 2,
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) {
                          if (!event.isInterestedForInteractions ||
                              response == null ||
                              response.touchedSection == null) {
                            onTouch(null);
                            return;
                          }
                          onTouch(
                              response.touchedSection!.touchedSectionIndex);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categorias.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final cat = categorias[index];
              final color = _chartColors[index % _chartColors.length];
              final isSelected = touched == index;
              return ListTile(
                selected: isSelected,
                onTap: () => onTouch(isSelected ? null : index),
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
                      style: tt.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${cat.porcentaje.toStringAsFixed(1)}%',
                      style: tt.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}
