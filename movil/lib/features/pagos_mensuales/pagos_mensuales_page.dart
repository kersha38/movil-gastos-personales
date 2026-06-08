import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../data/models/gasto_mensual.dart';
import 'pagos_mensuales_notifier.dart';
import 'pago_mensual_form_page.dart';

class PagosMensualesPage extends StatefulWidget {
  final PagosMensualesNotifier notifier;

  const PagosMensualesPage({super.key, required this.notifier});

  @override
  State<PagosMensualesPage> createState() => _PagosMensualesPageState();
}

class _PagosMensualesPageState extends State<PagosMensualesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => widget.notifier.cargar());
  }

  Future<void> _nuevaPlantilla() async {
    final result = await Navigator.of(context).push<GastoMensual>(
      MaterialPageRoute(
        builder: (_) => const PagoMensualFormPage(),
        fullscreenDialog: true,
      ),
    );
    if (result != null) {
      try {
        await widget.notifier.crearPlantilla(result);
      } catch (e) {
        if (mounted) _mostrarError('Error al crear: $e');
      }
    }
  }

  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.notifier,
      builder: (context, _) {
        final notifier = widget.notifier;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Pagos Mensuales'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_outlined),
                tooltip: 'Actualizar',
                onPressed: notifier.cargar,
              ),
            ],
          ),
          body: _Body(notifier: notifier, parent: this),
          floatingActionButton: FloatingActionButton(
            onPressed: _nuevaPlantilla,
            tooltip: 'Nueva plantilla',
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  final PagosMensualesNotifier notifier;
  final _PagosMensualesPageState parent;

  const _Body({required this.notifier, required this.parent});

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
                  size: 48, color: Theme.of(context).colorScheme.error),
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
    if (notifier.plantillas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.repeat_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'No hay pagos mensuales configurados.\nUsa el botón + para crear uno.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: AppSpacing.xxl,
      ),
      itemCount: notifier.plantillas.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) => _PlantillaTile(
        plantilla: notifier.plantillas[index],
        instancias: notifier.instanciasPorPlantilla[
                notifier.plantillas[index].id] ??
            [],
        notifier: notifier,
        parent: parent,
      ),
    );
  }
}

class _PlantillaTile extends StatefulWidget {
  final GastoMensual plantilla;
  final List<GastoMensual> instancias;
  final PagosMensualesNotifier notifier;
  final _PagosMensualesPageState parent;

  const _PlantillaTile({
    required this.plantilla,
    required this.instancias,
    required this.notifier,
    required this.parent,
  });

  @override
  State<_PlantillaTile> createState() => _PlantillaTileState();
}

class _PlantillaTileState extends State<_PlantillaTile> {
  bool _expanded = false;
  bool _instanciasCargadas = false;

  void _toggleExpand() {
    setState(() => _expanded = !_expanded);
    if (_expanded && !_instanciasCargadas) {
      _instanciasCargadas = true;
      widget.notifier.cargarInstancias(widget.plantilla.id!);
    }
  }

  Future<void> _editarPlantilla() async {
    final result = await Navigator.of(context).push<GastoMensual>(
      MaterialPageRoute(
        builder: (_) => PagoMensualFormPage(initial: widget.plantilla),
        fullscreenDialog: true,
      ),
    );
    if (result != null) {
      try {
        await widget.notifier.actualizarPlantilla(result);
      } catch (e) {
        if (mounted) widget.parent._mostrarError('Error al actualizar: $e');
      }
    }
  }

  Future<void> _eliminarPlantilla() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar plantilla'),
        content: const Text(
            'Se eliminará esta plantilla. Las instancias ya generadas no se borran.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await widget.notifier.eliminarPlantilla(widget.plantilla.id!);
      } catch (e) {
        if (mounted) widget.parent._mostrarError('Error al eliminar: $e');
      }
    }
  }

  Future<void> _editarInstancia(GastoMensual instancia) async {
    final result = await Navigator.of(context).push<GastoMensual>(
      MaterialPageRoute(
        builder: (_) => PagoMensualFormPage(initial: instancia),
        fullscreenDialog: true,
      ),
    );
    if (result != null) {
      try {
        await widget.notifier.actualizarInstancia(result);
      } catch (e) {
        if (mounted) widget.parent._mostrarError('Error al actualizar: $e');
      }
    }
  }

  Future<void> _eliminarInstancia(GastoMensual instancia) async {
    try {
      await widget.notifier
          .eliminarInstancia(widget.plantilla.id!, instancia.id!);
    } catch (e) {
      if (mounted) widget.parent._mostrarError('Error al eliminar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final p = widget.plantilla;

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: cs.primaryContainer,
              child: Icon(Icons.repeat, color: cs.onPrimaryContainer),
            ),
            title: Text(p.descripcion, style: tt.bodyLarge),
            subtitle: Text(
              '${p.categoriaNombre} · ${p.pagadorNombre} · \$${p.monto.toStringAsFixed(2)}/mes',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Editar plantilla',
                  onPressed: _editarPlantilla,
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: cs.error),
                  tooltip: 'Eliminar plantilla',
                  onPressed: _eliminarPlantilla,
                ),
                IconButton(
                  icon: Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                  ),
                  tooltip: 'Ver instancias',
                  onPressed: _toggleExpand,
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Icon(Icons.history, size: 16, color: cs.onSurfaceVariant),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Instancias generadas',
                    style: tt.labelMedium
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if (widget.instancias.isEmpty)
              Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  bottom: AppSpacing.md,
                ),
                child: Text(
                  'No hay instancias aún. El scheduler las genera el 1ro de cada mes.',
                  style: tt.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              )
            else
              ...widget.instancias.map(
                (inst) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.event_note_outlined, size: 18),
                  title: Text(inst.yearMonth ?? ''),
                  subtitle: Text('\$${inst.monto.toStringAsFixed(2)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        tooltip: 'Editar instancia',
                        onPressed: () => _editarInstancia(inst),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline,
                            size: 18, color: cs.error),
                        tooltip: 'Eliminar instancia',
                        onPressed: () => _eliminarInstancia(inst),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}
