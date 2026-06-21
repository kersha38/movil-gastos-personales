import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../data/models/categoria.dart';
import '../../data/models/gasto_mensual.dart';
import '../../data/models/participante.dart';
import '../../data/repositories/categorias_repository.dart';
import '../../data/repositories/participantes_repository.dart';

class PagoMensualFormPage extends StatefulWidget {
  final GastoMensual? initial; // null = crear nuevo

  const PagoMensualFormPage({super.key, this.initial});

  @override
  State<PagoMensualFormPage> createState() => _PagoMensualFormPageState();
}

class _PagoMensualFormPageState extends State<PagoMensualFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _montoP1Controller = TextEditingController();
  final _montoP2Controller = TextEditingController();

  final _catRepo = CategoriasRepository();
  final _partRepo = ParticipantesRepository();

  List<Categoria> _categorias = [];
  List<Participante> _participantes = [];
  Categoria? _categoriaSeleccionada;
  Participante? _pagadorSeleccionado;
  bool _esCompartido = true;
  double _porcentaje1 = 50;
  bool _perteneceAlSri = false;
  bool _cargando = true;
  bool _guardando = false;
  bool _sincronizandoMontos = false;

  @override
  void initState() {
    super.initState();
    _montoController.addListener(_onMontoTotalChanged);
    if (widget.initial != null) {
      final gm = widget.initial!;
      _montoController.text = gm.monto.toString();
      _descripcionController.text = gm.descripcion;
      _esCompartido = gm.esCompartido;
      _porcentaje1 = gm.porcentajeParticipante1;
      _perteneceAlSri = gm.perteneceAlSri;
    }
    _cargar();
  }

  @override
  void dispose() {
    _montoController.dispose();
    _descripcionController.dispose();
    _montoP1Controller.dispose();
    _montoP2Controller.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    try {
      final results = await Future.wait([
        _catRepo.getCategorias(),
        _partRepo.getParticipantes(),
      ]);
      final cats = results[0] as List<Categoria>;
      final parts = results[1] as List<Participante>;
      if (mounted) {
        setState(() {
          _categorias = cats;
          _participantes = parts;
          if (widget.initial != null) {
            _categoriaSeleccionada = cats
                .where((c) => c.id == widget.initial!.categoriaId)
                .firstOrNull;
            _pagadorSeleccionado = parts
                .where((p) => p.id == widget.initial!.pagadorId)
                .firstOrNull;
          } else {
            if (parts.isNotEmpty) _pagadorSeleccionado = parts.first;
          }
          _cargando = false;
        });
        _actualizarMontosDesdePorcentaje();
      }
    } catch (_) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  double get _porcentaje2 => 100 - _porcentaje1;

  double get _montoTotal =>
      double.tryParse(_montoController.text.replaceAll(',', '.')) ?? 0;

  void _onMontoTotalChanged() {
    if (_sincronizandoMontos || !_esCompartido) return;
    _actualizarMontosDesdePorcentaje();
  }

  void _actualizarMontosDesdePorcentaje() {
    _sincronizandoMontos = true;
    final total = _montoTotal;
    final monto1 = total * _porcentaje1 / 100;
    final monto2 = total - monto1;
    _montoP1Controller.text = total > 0 ? monto1.toStringAsFixed(2) : '';
    _montoP2Controller.text = total > 0 ? monto2.toStringAsFixed(2) : '';
    _sincronizandoMontos = false;
  }

  void _onPorcentajeCambiado(double v) {
    setState(() => _porcentaje1 = v);
    _actualizarMontosDesdePorcentaje();
  }

  void _onMontoP1Cambiado(String value) {
    if (_sincronizandoMontos) return;
    final total = _montoTotal;
    final monto1 = double.tryParse(value.replaceAll(',', '.'));
    if (total <= 0 || monto1 == null) return;
    final monto1Clamped = monto1.clamp(0, total);
    _sincronizandoMontos = true;
    setState(() => _porcentaje1 = (monto1Clamped / total) * 100);
    _montoP2Controller.text = (total - monto1Clamped).toStringAsFixed(2);
    _sincronizandoMontos = false;
  }

  void _onMontoP2Cambiado(String value) {
    if (_sincronizandoMontos) return;
    final total = _montoTotal;
    final monto2 = double.tryParse(value.replaceAll(',', '.'));
    if (total <= 0 || monto2 == null) return;
    final monto2Clamped = monto2.clamp(0, total);
    _sincronizandoMontos = true;
    setState(() => _porcentaje1 = ((total - monto2Clamped) / total) * 100);
    _montoP1Controller.text = (total - monto2Clamped).toStringAsFixed(2);
    _sincronizandoMontos = false;
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoriaSeleccionada == null || _pagadorSeleccionado == null) return;

    setState(() => _guardando = true);
    try {
      final p1 = _participantes.isNotEmpty ? _participantes[0] : null;
      final p2 = _participantes.length > 1 ? _participantes[1] : null;

      final gm = GastoMensual(
        id: widget.initial?.id,
        tipo: widget.initial?.tipo ?? 'plantilla',
        plantillaId: widget.initial?.plantillaId,
        yearMonth: widget.initial?.yearMonth,
        gastoId: widget.initial?.gastoId,
        monto: double.parse(_montoController.text.replaceAll(',', '.')),
        descripcion: _descripcionController.text.trim(),
        categoriaId: _categoriaSeleccionada!.id,
        categoriaNombre: _categoriaSeleccionada!.nombre,
        pagadorId: _pagadorSeleccionado!.id,
        pagadorNombre: _pagadorSeleccionado!.nombre,
        participante1Id: p1?.id ?? '',
        participante1Nombre: p1?.nombre ?? '',
        participante2Id: p2?.id ?? '',
        participante2Nombre: p2?.nombre ?? '',
        esCompartido: _esCompartido,
        porcentajeParticipante1: _esCompartido ? _porcentaje1 : 100,
        porcentajeParticipante2: _esCompartido ? _porcentaje2 : 0,
        perteneceAlSri: _perteneceAlSri,
        creadoEn: widget.initial?.creadoEn,
      );
      Navigator.of(context).pop(gm);
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
    final isEditing = widget.initial != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar pago mensual' : 'Nuevo pago mensual'),
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
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
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
                      labelText: 'Descripción',
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'Ingresa una descripción'
                            : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<Categoria>(
                    key: ValueKey(_categoriaSeleccionada?.id),
                    initialValue: _categoriaSeleccionada,
                    style: dropdownStyle,
                    decoration:
                        const InputDecoration(labelText: 'Categoría'),
                    items: _categorias
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text('${c.emoji} ${c.nombre}', style: dropdownStyle),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _categoriaSeleccionada = v),
                    validator: (v) =>
                        v == null ? 'Selecciona una categoría' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<Participante>(
                    key: ValueKey(_pagadorSeleccionado?.id),
                    initialValue: _pagadorSeleccionado,
                    style: dropdownStyle,
                    decoration:
                        const InputDecoration(labelText: 'Quién paga'),
                    items: _participantes
                        .map((p) => DropdownMenuItem(
                              value: p,
                              child: Text(p.nombre, style: dropdownStyle),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _pagadorSeleccionado = v),
                    validator: (v) =>
                        v == null ? 'Selecciona quién paga' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Card(
                    child: SwitchListTile(
                      title: const Text('Gasto compartido'),
                      value: _esCompartido,
                      onChanged: (v) {
                        setState(() => _esCompartido = v);
                        if (v) _actualizarMontosDesdePorcentaje();
                      },
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
                            Text('División',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall),
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_participantes.isNotEmpty
                                    ? _participantes[0].nombre
                                    : 'P1'),
                                Text('${_porcentaje1.round()}%'),
                              ],
                            ),
                            Slider(
                              value: _porcentaje1,
                              min: 0,
                              max: 100,
                              divisions: 20,
                              onChanged: _onPorcentajeCambiado,
                            ),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_participantes.length > 1
                                    ? _participantes[1].nombre
                                    : 'P2'),
                                Text('${_porcentaje2.round()}%'),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'O ingresa el monto de cada uno',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _montoP1Controller,
                                    decoration: InputDecoration(
                                      labelText: _participantes.isNotEmpty
                                          ? _participantes[0].nombre
                                          : 'P1',
                                      prefixText: '\$ ',
                                    ),
                                    keyboardType: const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    onChanged: _onMontoP1Cambiado,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: TextFormField(
                                    controller: _montoP2Controller,
                                    decoration: InputDecoration(
                                      labelText: _participantes.length > 1
                                          ? _participantes[1].nombre
                                          : 'P2',
                                      prefixText: '\$ ',
                                    ),
                                    keyboardType: const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    onChanged: _onMontoP2Cambiado,
                                  ),
                                ),
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
                      title: const Text('Factura SRI'),
                      value: _perteneceAlSri,
                      onChanged: (v) =>
                          setState(() => _perteneceAlSri = v),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
    );
  }
}
