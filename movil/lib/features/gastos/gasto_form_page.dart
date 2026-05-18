import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../data/models/categoria.dart';
import '../../data/models/gasto.dart';
import '../../data/models/participante.dart';
import '../../data/repositories/categorias_repository.dart';
import '../../data/repositories/gastos_repository.dart';
import '../../data/repositories/participantes_repository.dart';
import '../settings/settings_notifier.dart';

class GastoFormPage extends StatefulWidget {
  final SettingsNotifier settingsNotifier;

  const GastoFormPage({super.key, required this.settingsNotifier});

  @override
  State<GastoFormPage> createState() => _GastoFormPageState();
}

class _GastoFormPageState extends State<GastoFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _nuevaCategoriaController = TextEditingController();

  final _categoriasRepo = CategoriasRepository();
  final _participantesRepo = ParticipantesRepository();
  final _gastosRepo = GastosRepository();

  List<Categoria> _categorias = [];
  List<Participante> _participantes = [];
  bool _cargando = true;
  bool _guardando = false;

  Categoria? _categoriaSeleccionada;
  Participante? _pagadorSeleccionado;
  bool _esCompartido = true;
  double _porcentaje1 = 50;
  bool _esRecurrente = false;
  bool _perteneceAlSri = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _montoController.dispose();
    _descripcionController.dispose();
    _nuevaCategoriaController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    try {
      final results = await Future.wait([
        _categoriasRepo.getCategorias(),
        _participantesRepo.getParticipantes(),
      ]);
      if (mounted) {
        setState(() {
          _categorias = results[0] as List<Categoria>;
          _participantes = results[1] as List<Participante>;
          if (_participantes.isNotEmpty) {
            _pagadorSeleccionado = _participantes.first;
          }
          _cargando = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  double get _porcentaje2 => 100 - _porcentaje1;

  String get _nombreP1 => widget.settingsNotifier.nombreP1;
  String get _nombreP2 => widget.settingsNotifier.nombreP2;

  Future<void> _mostrarDialogNuevaCategoria() async {
    _nuevaCategoriaController.clear();
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva categoría'),
        content: TextField(
          controller: _nuevaCategoriaController,
          decoration: const InputDecoration(labelText: 'Nombre'),
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Crear'),
          ),
        ],
      ),
    );

    if (confirmar == true &&
        _nuevaCategoriaController.text.trim().isNotEmpty &&
        mounted) {
      try {
        final nueva = await _categoriasRepo
            .crearCategoria(_nuevaCategoriaController.text.trim());
        setState(() {
          _categorias.add(nueva);
          _categoriaSeleccionada = nueva;
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al crear categoría: $e'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoriaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una categoría'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_pagadorSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona quién pagó'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _guardando = true);
    try {
      final p1 = _participantes.isNotEmpty ? _participantes[0] : null;
      final p2 = _participantes.length > 1 ? _participantes[1] : null;

      final gasto = Gasto(
        monto: double.parse(_montoController.text.replaceAll(',', '.')),
        descripcion: _descripcionController.text.trim(),
        categoriaId: _categoriaSeleccionada!.id,
        categoriaNombre: _categoriaSeleccionada!.nombre,
        pagadorId: _pagadorSeleccionado!.id,
        pagadorNombre: _pagadorSeleccionado!.nombre,
        participante1Id: p1?.id ?? '',
        participante1Nombre: p1?.nombre ?? _nombreP1,
        participante2Id: p2?.id ?? '',
        participante2Nombre: p2?.nombre ?? _nombreP2,
        esCompartido: _esCompartido,
        porcentajeParticipante1: _esCompartido ? _porcentaje1 : 100,
        porcentajeParticipante2: _esCompartido ? _porcentaje2 : 0,
        esRecurrente: _esRecurrente,
        perteneceAlSri: _perteneceAlSri,
        timestamp: DateTime.now(),
      );

      await _gastosRepo.crearGasto(gasto);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo gasto'),
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
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Ingresa un monto';
                      final parsed = double.tryParse(v.replaceAll(',', '.'));
                      if (parsed == null) return 'Monto inválido';
                      if (parsed <= 0) return 'El monto debe ser mayor a 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _descripcionController,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'Ingresa una descripción'
                            : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<Categoria>(
                          key: ValueKey(_categoriaSeleccionada?.id),
                          initialValue: _categoriaSeleccionada,
                          decoration: const InputDecoration(
                            labelText: 'Categoría',
                          ),
                          items: _categorias
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c.nombre),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _categoriaSeleccionada = v),
                          validator: (v) =>
                              v == null ? 'Selecciona una categoría' : null,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      IconButton.filled(
                        onPressed: _mostrarDialogNuevaCategoria,
                        icon: const Icon(Icons.add),
                        tooltip: 'Nueva categoría',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<Participante>(
                    key: ValueKey(_pagadorSeleccionado?.id),
                    initialValue: _pagadorSeleccionado,
                    decoration: const InputDecoration(labelText: 'Quién pagó'),
                    items: _participantes
                        .map(
                          (p) => DropdownMenuItem(
                            value: p,
                            child: Text(p.nombre),
                          ),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _pagadorSeleccionado = v),
                    validator: (v) =>
                        v == null ? 'Selecciona quién pagó' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Card(
                    child: SwitchListTile(
                      title: const Text('Gasto compartido'),
                      subtitle: Text(
                        _esCompartido
                            ? 'Entre los dos participantes'
                            : 'Solo un participante',
                      ),
                      value: _esCompartido,
                      onChanged: (v) => setState(() => _esCompartido = v),
                    ),
                  ),
                  if (_esCompartido) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'División del gasto',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_nombreP1),
                                Text('${_porcentaje1.round()}%'),
                              ],
                            ),
                            Slider(
                              value: _porcentaje1,
                              min: 0,
                              max: 100,
                              divisions: 20,
                              onChanged: (v) =>
                                  setState(() => _porcentaje1 = v),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_nombreP2),
                                Text('${_porcentaje2.round()}%'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Card(
                    child: SwitchListTile(
                      title: const Text('Repetir cada mes'),
                      subtitle: const Text('Gasto recurrente mensual'),
                      value: _esRecurrente,
                      onChanged: (v) => setState(() => _esRecurrente = v),
                    ),
                  ),
                  Card(
                    child: SwitchListTile(
                      title: const Text('Factura SRI'),
                      subtitle: const Text('Gasto con comprobante fiscal'),
                      value: _perteneceAlSri,
                      onChanged: (v) => setState(() => _perteneceAlSri = v),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
    );
  }
}
