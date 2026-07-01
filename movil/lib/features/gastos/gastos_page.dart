import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../data/models/categoria.dart';
import '../../data/models/gasto.dart';
import '../../data/models/transferencia.dart';
import '../../data/repositories/categorias_repository.dart';
import '../settings/settings_notifier.dart';
import 'gasto_form_page.dart';
import 'gastos_notifier.dart';
import 'transferencia_form_page.dart';
import 'widgets/gasto_tile.dart';

class GastosPage extends StatefulWidget {
  final GastosNotifier notifier;
  final SettingsNotifier settingsNotifier;

  const GastosPage({
    super.key,
    required this.notifier,
    required this.settingsNotifier,
  });

  @override
  State<GastosPage> createState() => _GastosPageState();
}

enum _VistaFiltro { ambos, soloGastos, soloTransferencias }

class _GastosPageState extends State<GastosPage> {
  final _categoriasRepo = CategoriasRepository();
  final _scrollController = ScrollController();
  List<Categoria> _categorias = [];
  Set<String> _categoriaIdsFiltro = {};
  _VistaFiltro _vistaFiltro = _VistaFiltro.ambos;
  String? _pendingScrollId;

  Map<String, String> get _emojiPorCategoria =>
      Map.fromEntries(_categorias.map((c) => MapEntry(c.id, c.emoji)));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.notifier.cargar());
    _cargarCategorias();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _cargarCategorias() async {
    try {
      final cats = await _categoriasRepo.getCategorias();
      if (mounted) setState(() => _categorias = cats);
    } catch (_) {
      // El filtro es secundario — si falla, simplemente no se muestra.
    }
  }

  Future<void> _mostrarFiltroCategorias() async {
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
                  children: _categorias.map((c) {
                    final activo = seleccion.contains(c.id);
                    return FilterChip(
                      label: Text('${c.emoji} ${c.nombre}'),
                      selected: activo,
                      onSelected: (v) => setSheetState(() {
                        if (v) {
                          seleccion.add(c.id);
                        } else {
                          seleccion.remove(c.id);
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

  Future<void> _editarGasto(GastosNotifier notifier, Gasto gasto) async {
    final editado = await context.push<bool>(
      '/gastos/nuevo',
      extra: GastoFormArgs(
        settingsNotifier: widget.settingsNotifier,
        gasto: gasto,
      ),
    );
    if (editado == true) {
      _pendingScrollId = gasto.id;
      await notifier.cargar();
      _scrollToGasto();
    }
  }

  Future<void> _eliminarGasto(GastosNotifier notifier, Gasto gasto) async {
    try {
      await notifier.eliminarGasto(gasto.id!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar gasto: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _scrollToGasto() {
    final id = _pendingScrollId;
    if (id == null) return;
    _pendingScrollId = null;

    final notifier = widget.notifier;
    final gastosFiltrados = _categoriaIdsFiltro.isEmpty
        ? notifier.gastos
        : notifier.gastos
            .where((g) => _categoriaIdsFiltro.contains(g.categoriaId))
            .toList();

    final items = <(String, DateTime)>[
      ...gastosFiltrados.map((g) => (g.id!, g.timestamp)),
      ...notifier.transferencias.map((t) => (t.id!, t.timestamp)),
    ]..sort((a, b) => b.$2.compareTo(a.$2));

    final idx = items.indexWhere((item) => item.$1 == id);
    if (idx < 0) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      const itemH = 162.0;
      final offset = (idx * itemH)
          .clamp(0.0, _scrollController.position.maxScrollExtent);
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _agregarTransferencia() async {
    final result = await Navigator.of(context).push<Transferencia>(
      MaterialPageRoute(
        builder: (_) => const TransferenciaFormPage(),
        fullscreenDialog: true,
      ),
    );
    if (result != null) {
      try {
        await widget.notifier.crearTransferencia(result);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al guardar transferencia: $e'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.notifier, widget.settingsNotifier]),
      builder: (ctx, _) {
        final notifier = widget.notifier;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Gastos'),
            actions: [
              IconButton(
                icon: Icon(
                  _categoriaIdsFiltro.isEmpty
                      ? Icons.filter_list_outlined
                      : Icons.filter_list,
                ),
                tooltip: 'Filtrar por categoría',
                onPressed: _mostrarFiltroCategorias,
              ),
              IconButton(
                icon: const Icon(Icons.swap_horiz_outlined),
                tooltip: 'Nueva transferencia',
                onPressed: _agregarTransferencia,
              ),
              IconButton(
                icon: const Icon(Icons.refresh_outlined),
                tooltip: 'Actualizar',
                onPressed: notifier.cargar,
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
              _VistaSelector(
                valor: _vistaFiltro,
                onChanged: (v) => setState(() => _vistaFiltro = v),
              ),
              Expanded(child: _Body(
                notifier: notifier,
                miParticipanteId: widget.settingsNotifier.miParticipanteId,
                categoriaIdsFiltro: _categoriaIdsFiltro,
                vistaFiltro: _vistaFiltro,
                emojiPorCategoria: _emojiPorCategoria,
                scrollController: _scrollController,
                onEditar: (gasto) => _editarGasto(notifier, gasto),
                onEliminar: (gasto) => _eliminarGasto(notifier, gasto),
              )),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              final creado = await context.push<bool>(
                '/gastos/nuevo',
                extra: GastoFormArgs(settingsNotifier: widget.settingsNotifier),
              );
              if (creado == true) notifier.cargar();
            },
            tooltip: 'Agregar gasto',
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

class _MesSelector extends StatelessWidget {
  final GastosNotifier notifier;

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

class _VistaSelector extends StatelessWidget {
  final _VistaFiltro valor;
  final ValueChanged<_VistaFiltro> onChanged;

  const _VistaSelector({required this.valor, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: SegmentedButton<_VistaFiltro>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(
            value: _VistaFiltro.ambos,
            label: Text('Todos'),
            icon: Icon(Icons.list_outlined),
          ),
          ButtonSegment(
            value: _VistaFiltro.soloGastos,
            label: Text('Gastos'),
            icon: Icon(Icons.receipt_long_outlined),
          ),
          ButtonSegment(
            value: _VistaFiltro.soloTransferencias,
            label: Text('Pagos'),
            icon: Icon(Icons.swap_horiz_outlined),
          ),
        ],
        selected: {valor},
        onSelectionChanged: (s) => onChanged(s.first),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final GastosNotifier notifier;
  final String miParticipanteId;
  final Set<String> categoriaIdsFiltro;
  final _VistaFiltro vistaFiltro;
  final Map<String, String> emojiPorCategoria;
  final ScrollController scrollController;
  final void Function(Gasto gasto) onEditar;
  final void Function(Gasto gasto) onEliminar;

  const _Body({
    required this.notifier,
    required this.miParticipanteId,
    required this.categoriaIdsFiltro,
    required this.vistaFiltro,
    required this.emojiPorCategoria,
    required this.scrollController,
    required this.onEditar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    if (notifier.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (notifier.error != null) {
      return _ErrorView(message: notifier.error!, onRetry: notifier.cargar);
    }
    if (notifier.gastos.isEmpty && notifier.transferencias.isEmpty) {
      return const Center(child: Text('No hay gastos en este mes'));
    }

    final mostrarGastos = vistaFiltro != _VistaFiltro.soloTransferencias;
    final mostrarTransferencias = vistaFiltro != _VistaFiltro.soloGastos;

    final gastosFiltrados = !mostrarGastos
        ? <Gasto>[]
        : (categoriaIdsFiltro.isEmpty
            ? notifier.gastos
            : notifier.gastos
                .where((g) => categoriaIdsFiltro.contains(g.categoriaId))
                .toList());

    final transferenciasVisibles =
        mostrarTransferencias ? notifier.transferencias : <Transferencia>[];

    if (gastosFiltrados.isEmpty && transferenciasVisibles.isEmpty) {
      return const Center(child: Text('Sin registros para este filtro'));
    }

    // Merge gastos y transferencias ordenados por fecha desc
    final items = <_ListItem>[];
    for (final g in gastosFiltrados) {
      items.add(_ListItem.gasto(g));
    }
    for (final t in transferenciasVisibles) {
      items.add(_ListItem.transferencia(t));
    }
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom: AppSpacing.xxl,
      ),
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        if (item.gasto != null) {
          return GastoTile(
            gasto: item.gasto!,
            miParticipanteId: miParticipanteId,
            emoji: emojiPorCategoria[item.gasto!.categoriaId],
            onVerificar: (v) => notifier.verificarGasto(
              item.gasto!.id!,
              v,
              miParticipanteId,
            ),
            onTap: () => onEditar(item.gasto!),
            onEliminar: () => onEliminar(item.gasto!),
          );
        }
        return _TransferenciaTile(
          transferencia: item.transferencia!,
          onEliminar: () => notifier.eliminarTransferencia(item.transferencia!.id!),
        );
      },
    );
  }
}

class _ListItem {
  final Gasto? gasto;
  final Transferencia? transferencia;
  final DateTime timestamp;

  _ListItem.gasto(Gasto g)
      : gasto = g,
        transferencia = null,
        timestamp = g.timestamp;

  _ListItem.transferencia(Transferencia t)
      : gasto = null,
        transferencia = t,
        timestamp = t.timestamp;
}

class _TransferenciaTile extends StatelessWidget {
  final Transferencia transferencia;
  final VoidCallback onEliminar;

  const _TransferenciaTile({
    required this.transferencia,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: cs.secondaryContainer,
        child: Icon(Icons.swap_horiz, color: cs.onSecondaryContainer),
      ),
      title: Text(
        transferencia.descripcion.isEmpty
            ? 'Transferencia'
            : transferencia.descripcion,
        style: tt.bodyLarge,
      ),
      subtitle: Text(
        '${transferencia.origenNombre} → ${transferencia.destinoNombre}',
        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '\$${transferencia.monto.toStringAsFixed(2)}',
            style: tt.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.secondary,
            ),
          ),
        ],
      ),
      onLongPress: () => _confirmarEliminar(context),
    );
  }

  void _confirmarEliminar(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error),
                title: const Text('Eliminar transferencia'),
                subtitle: const Text('Esta acción no se puede deshacer'),
                onTap: () {
                  Navigator.pop(ctx);
                  onEliminar();
                },
              ),
            ],
          ),
        ),
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
