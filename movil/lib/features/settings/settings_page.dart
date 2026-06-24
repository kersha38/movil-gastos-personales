import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../data/models/categoria.dart';
import '../../data/repositories/categorias_repository.dart';
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
              const SizedBox(height: AppSpacing.xl),
              const Divider(),
              const SizedBox(height: AppSpacing.md),
              Text('Categorías', style: tt.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Edita el nombre o emoji de una categoría existente.',
                style: tt.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const _CategoriasEditor(),
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

class _CategoriasEditor extends StatefulWidget {
  const _CategoriasEditor();

  @override
  State<_CategoriasEditor> createState() => _CategoriasEditorState();
}

class _CategoriasEditorState extends State<_CategoriasEditor> {
  final _categoriasRepo = CategoriasRepository();
  List<Categoria> _categorias = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final categorias = await _categoriasRepo.getCategorias();
      if (mounted) setState(() => _categorias = categorias);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _editar(Categoria categoria) async {
    final nombreController = TextEditingController(text: categoria.nombre);
    final emojiController = TextEditingController(text: categoria.emoji);
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar categoría'),
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 64,
              child: TextField(
                controller: emojiController,
                decoration: const InputDecoration(labelText: 'Emoji'),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextField(
                controller: nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (confirmar != true || nombreController.text.trim().isEmpty) return;
    try {
      final actualizada = await _categoriasRepo.actualizarCategoria(
        categoria.id,
        nombreController.text.trim(),
        emoji: emojiController.text,
      );
      if (mounted) {
        setState(() {
          _categorias = _categorias
              .map((c) => c.id == actualizada.id ? actualizada : c)
              .toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar categoría: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      children: _categorias
          .map(
            (c) => Card(
              child: ListTile(
                leading: Text(c.emoji, style: const TextStyle(fontSize: 20)),
                title: Text(c.nombre),
                trailing: const Icon(Icons.edit_outlined),
                onTap: () => _editar(c),
              ),
            ),
          )
          .toList(),
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
