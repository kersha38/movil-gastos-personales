import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../settings/settings_notifier.dart';
import 'gastos_notifier.dart';
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.notifier,
      builder: (context, _) {
        final notifier = widget.notifier;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Gastos'),
            actions: [
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
              Expanded(child: _Body(notifier: notifier)),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              final creado = await context.push<bool>(
                '/gastos/nuevo',
                extra: widget.settingsNotifier,
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

  const _Body({required this.notifier});

  @override
  Widget build(BuildContext context) {
    if (notifier.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (notifier.error != null) {
      return _ErrorView(message: notifier.error!, onRetry: notifier.cargar);
    }
    if (notifier.gastos.isEmpty) {
      return const Center(
        child: Text('No hay gastos en este mes'),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom: AppSpacing.xxl,
      ),
      itemCount: notifier.gastos.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) =>
          GastoTile(gasto: notifier.gastos[index]),
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
