import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../data/models/participante.dart';
import '../../data/models/transferencia.dart';
import '../../data/repositories/participantes_repository.dart';

class TransferenciaFormPage extends StatefulWidget {
  const TransferenciaFormPage({super.key});

  @override
  State<TransferenciaFormPage> createState() => _TransferenciaFormPageState();
}

class _TransferenciaFormPageState extends State<TransferenciaFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _repo = ParticipantesRepository();

  List<Participante> _participantes = [];
  Participante? _origen;
  Participante? _destino;
  bool _cargando = true;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _montoController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    try {
      final ps = await _repo.getParticipantes();
      if (mounted) {
        setState(() {
          _participantes = ps;
          if (ps.length >= 2) {
            _origen = ps[0];
            _destino = ps[1];
          }
          _cargando = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_origen == null || _destino == null) return;
    if (_origen!.id == _destino!.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El origen y destino deben ser distintos'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _guardando = true);
    try {
      final t = Transferencia(
        monto: double.parse(_montoController.text.replaceAll(',', '.')),
        descripcion: _descripcionController.text.trim(),
        origenId: _origen!.id,
        origenNombre: _origen!.nombre,
        destinoId: _destino!.id,
        destinoNombre: _destino!.nombre,
        timestamp: DateTime.now(),
      );
      Navigator.of(context).pop(t);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dropdownStyle = TextStyle(
      color: Theme.of(context).colorScheme.onSurface,
      fontWeight: FontWeight.w500,
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva transferencia'),
        actions: [
          if (_guardando)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _guardar,
              child: const Text('Guardar'),
            ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _montoController,
                    decoration: const InputDecoration(
                      labelText: 'Monto',
                      prefixText: '\$ ',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Ingresa un monto';
                      final p = double.tryParse(v.replaceAll(',', '.'));
                      if (p == null) return 'Monto inválido';
                      if (p <= 0) return 'El monto debe ser mayor a 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _descripcionController,
                    decoration: const InputDecoration(
                      labelText: 'Descripción (opcional)',
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<Participante>(
                    key: ValueKey(_origen?.id),
                    initialValue: _origen,
                    style: dropdownStyle,
                    decoration: const InputDecoration(labelText: 'De (quién envía)'),
                    items: _participantes
                        .map((p) => DropdownMenuItem(
                              value: p,
                              child: Text(p.nombre, style: dropdownStyle),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _origen = v),
                    validator: (v) => v == null ? 'Selecciona el origen' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<Participante>(
                    key: ValueKey(_destino?.id),
                    initialValue: _destino,
                    style: dropdownStyle,
                    decoration: const InputDecoration(labelText: 'A (quién recibe)'),
                    items: _participantes
                        .map((p) => DropdownMenuItem(
                              value: p,
                              child: Text(p.nombre, style: dropdownStyle),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _destino = v),
                    validator: (v) => v == null ? 'Selecciona el destino' : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
    );
  }
}
