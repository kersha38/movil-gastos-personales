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
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: ListView(
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
                : const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
