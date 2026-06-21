import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import 'settings_notifier.dart';

class SettingsPage extends StatefulWidget {
  final SettingsNotifier notifier;

  const SettingsPage({super.key, required this.notifier});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _p1Controller;
  late final TextEditingController _p2Controller;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _p1Controller = TextEditingController(text: widget.notifier.nombreP1);
    _p2Controller = TextEditingController(text: widget.notifier.nombreP2);
  }

  @override
  void dispose() {
    _p1Controller.dispose();
    _p2Controller.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    await widget.notifier.guardar(_p1Controller.text, _p2Controller.text);
    if (mounted) {
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nombres guardados'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: ListenableBuilder(
        listenable: widget.notifier,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _p1Controller,
                decoration: const InputDecoration(
                  labelText: 'Nombre participante 1',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _p2Controller,
                decoration: const InputDecoration(
                  labelText: 'Nombre participante 2',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: _guardando ? null : _guardar,
                child: _guardando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Guardar nombres'),
              ),
              const SizedBox(height: AppSpacing.xl),
              const Divider(),
              const SizedBox(height: AppSpacing.md),
              Text('Soy yo', style: tt.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Identifica cuál participante eres en este dispositivo. Solo el otro puede verificar tus gastos.',
                style: tt.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _ParticipanteSelector(notifier: widget.notifier),
              const SizedBox(height: AppSpacing.xl),
              const Divider(),
              const SizedBox(height: AppSpacing.md),
              Text('Tema', style: tt.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Elige la apariencia de la app.',
                style: tt.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _TemaSelector(notifier: widget.notifier),
            ],
          );
        },
      ),
    );
  }
}

class _ParticipanteSelector extends StatelessWidget {
  final SettingsNotifier notifier;

  const _ParticipanteSelector({required this.notifier});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        _OptionTile(
          label: notifier.nombreP1,
          subtitle: 'Participante 1',
          selected: notifier.miParticipanteId == 'p1',
          onTap: () => notifier.guardarMiParticipante('p1'),
          cs: cs,
        ),
        const SizedBox(height: AppSpacing.sm),
        _OptionTile(
          label: notifier.nombreP2,
          subtitle: 'Participante 2',
          selected: notifier.miParticipanteId == 'p2',
          onTap: () => notifier.guardarMiParticipante('p2'),
          cs: cs,
        ),
      ],
    );
  }
}

class _TemaSelector extends StatelessWidget {
  final SettingsNotifier notifier;

  const _TemaSelector({required this.notifier});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ThemeMode>(
      segments: const [
        ButtonSegment(
          value: ThemeMode.light,
          icon: Icon(Icons.light_mode_outlined),
          label: Text('Claro'),
        ),
        ButtonSegment(
          value: ThemeMode.dark,
          icon: Icon(Icons.dark_mode_outlined),
          label: Text('Oscuro'),
        ),
        ButtonSegment(
          value: ThemeMode.system,
          icon: Icon(Icons.brightness_auto_outlined),
          label: Text('Automático'),
        ),
      ],
      selected: {notifier.themeMode},
      onSelectionChanged: (selection) {
        notifier.cambiarTema(selection.first);
      },
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme cs;

  const _OptionTile({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: selected ? cs.primaryContainer : null,
      child: ListTile(
        leading: Icon(
          selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
          color: selected ? cs.primary : cs.onSurfaceVariant,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(subtitle),
        onTap: onTap,
        trailing: selected
            ? Icon(Icons.check_circle, color: cs.primary)
            : null,
      ),
    );
  }
}
