import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../data/models/gasto.dart';
import '../../data/models/transferencia.dart';
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

class _GastosPageState extends State<GastosPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.notifier.cargar());
  }

  Future<void> _editarGasto(GastosNotifier notifier, Gasto gasto) async {
    final editado = await context.push<bool>(
      '/gastos/nuevo',
      extra: GastoFormArgs(
        settingsNotifier: widget.settingsNotifier,
        gasto: gasto,
      ),
    );
    if (editado == true) notifier.cargar();
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
      builder: (context, _) {
        final notifier = widget.notifier;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Gastos'),
            actions: [
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
              Expanded(child: _Body(
                notifier: notifier,
                miParticipanteId: widget.settingsNotifier.miParticipanteId,
                onEditar: (gasto) => _editarGasto(notifier, gasto),
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

class _Body extends StatelessWidget {
  final GastosNotifier notifier;
  final String miParticipanteId;
  final void Function(Gasto gasto) onEditar;

  const _Body({
    required this.notifier,
    required this.miParticipanteId,
    required this.onEditar,
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

    // Merge gastos and transferencias sorted by timestamp desc
    final items = <_ListItem>[];
    for (final g in notifier.gastos) {
      items.add(_ListItem.gasto(g));
    }
    for (final t in notifier.transferencias) {
      items.add(_ListItem.transferencia(t));
    }
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return ListView.separated(
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
            onVerificar: (v) => notifier.verificarGasto(
              item.gasto!.id!,
              v,
              miParticipanteId,
            ),
            onTap: () => onEditar(item.gasto!),
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
