import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/categoria.dart';
import '../../data/models/gasto.dart';
import '../../data/models/participante.dart';
import '../../data/repositories/categorias_repository.dart';
import '../../data/repositories/gastos_repository.dart';
import '../../data/repositories/participantes_repository.dart';
import '../settings/settings_notifier.dart';

class GastoFormArgs {
  final SettingsNotifier settingsNotifier;
  final Gasto? gasto;

  const GastoFormArgs({required this.settingsNotifier, this.gasto});
}

class GastoFormPage extends StatefulWidget {
  final SettingsNotifier settingsNotifier;
  final Gasto? gastoExistente;

  const GastoFormPage({
    super.key,
    required this.settingsNotifier,
    this.gastoExistente,
  });

  bool get esEdicion => gastoExistente != null;

  @override
  State<GastoFormPage> createState() => _GastoFormPageState();
}

class _GastoFormPageState extends State<GastoFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _nuevaCategoriaController = TextEditingController();
  final _nuevaCategoriaEmojiController = TextEditingController();
  final _montoP1Controller = TextEditingController();
  final _montoP2Controller = TextEditingController();

  final _categoriasRepo = CategoriasRepository();
  final _participantesRepo = ParticipantesRepository();
  final _gastosRepo = GastosRepository();

  List<Categoria> _categorias = [];
  List<Participante> _participantes = [];
  bool _cargando = true;
  bool _guardando = false;
  bool _sincronizandoMontos = false;

  Categoria? _categoriaSeleccionada;
  Participante? _pagadorSeleccionado;
  bool _esCompartido = true;
  double _porcentaje1 = 50;
  bool _esRecurrente = false;
  bool _perteneceAlSri = false;
  late DateTime _fecha;

  @override
  void initState() {
    super.initState();
    _fecha = widget.gastoExistente?.timestamp.toLocal() ?? DateTime.now();
    _montoController.addListener(_onMontoTotalChanged);
    _cargarDatos();
  }

  @override
  void dispose() {
    _montoController.dispose();
    _descripcionController.dispose();
    _nuevaCategoriaController.dispose();
    _nuevaCategoriaEmojiController.dispose();
    _montoP1Controller.dispose();
    _montoP2Controller.dispose();
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

          final existente = widget.gastoExistente;
          if (existente != null) {
            _montoController.text = existente.monto.toStringAsFixed(2);
            _descripcionController.text = existente.descripcion;
            _categoriaSeleccionada = _categorias.firstWhere(
              (c) => c.id == existente.categoriaId,
              orElse: () => _categorias.isNotEmpty
                  ? _categorias.first
                  : Categoria(
                      id: existente.categoriaId,
                      nombre: existente.categoriaNombre,
                      esPredefinida: false,
                    ),
            );
            _pagadorSeleccionado = _participantes.firstWhere(
              (p) => p.id == existente.pagadorId,
              orElse: () => _participantes.isNotEmpty
                  ? _participantes.first
                  : Participante(id: existente.pagadorId, nombre: existente.pagadorNombre),
            );
            _esCompartido = existente.esCompartido;
            _porcentaje1 = existente.porcentajeParticipante1;
            _esRecurrente = existente.esRecurrente;
            _perteneceAlSri = existente.perteneceAlSri;
          } else if (_participantes.isNotEmpty) {
            _pagadorSeleccionado = _participantes.first;
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

  String get _nombreP1 => widget.settingsNotifier.nombreP1;
  String get _nombreP2 => widget.settingsNotifier.nombreP2;

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

  Future<void> _seleccionarFecha() async {
    final seleccionada = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (seleccionada == null) return;
    setState(() {
      _fecha = DateTime(
        seleccionada.year,
        seleccionada.month,
        seleccionada.day,
        _fecha.hour,
        _fecha.minute,
        _fecha.second,
      );
    });
  }

  Future<void> _mostrarDialogNuevaCategoria() async {
    _nuevaCategoriaController.clear();
    _nuevaCategoriaEmojiController.text = emojiPorDefecto;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva categoría'),
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 64,
              child: TextField(
                controller: _nuevaCategoriaEmojiController,
                decoration: const InputDecoration(labelText: 'Emoji'),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextField(
                controller: _nuevaCategoriaController,
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
            child: const Text('Crear'),
          ),
        ],
      ),
    );

    if (confirmar == true &&
        _nuevaCategoriaController.text.trim().isNotEmpty &&
        mounted) {
      try {
        final nueva = await _categoriasRepo.crearCategoria(
          _nuevaCategoriaController.text.trim(),
          emoji: _nuevaCategoriaEmojiController.text,
        );
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
        timestamp: _fecha,
        verificado: widget.gastoExistente?.verificado ?? false,
        verificadoPor: widget.gastoExistente?.verificadoPor,
      );

      if (widget.esEdicion) {
        final gastoActualizado = Gasto(
          id: widget.gastoExistente!.id,
          monto: gasto.monto,
          descripcion: gasto.descripcion,
          categoriaId: gasto.categoriaId,
          categoriaNombre: gasto.categoriaNombre,
          pagadorId: gasto.pagadorId,
          pagadorNombre: gasto.pagadorNombre,
          participante1Id: gasto.participante1Id,
          participante1Nombre: gasto.participante1Nombre,
          participante2Id: gasto.participante2Id,
          participante2Nombre: gasto.participante2Nombre,
          esCompartido: gasto.esCompartido,
          porcentajeParticipante1: gasto.porcentajeParticipante1,
          porcentajeParticipante2: gasto.porcentajeParticipante2,
          esRecurrente: gasto.esRecurrente,
          perteneceAlSri: gasto.perteneceAlSri,
          timestamp: gasto.timestamp,
          verificado: gasto.verificado,
          verificadoPor: gasto.verificadoPor,
        );
        await _gastosRepo.actualizarGasto(gastoActualizado);
      } else {
        await _gastosRepo.crearGasto(gasto);
      }
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
    final cs = Theme.of(context).colorScheme;
    final dropdownStyle = TextStyle(
      color: cs.onSurface,
      fontWeight: FontWeight.w500,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.esEdicion ? 'Editar gasto' : 'Nuevo gasto'),
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
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.calendar_today_outlined),
                      title: const Text('Fecha'),
                      subtitle: Text(formatearFechaLarga(_fecha)),
                      trailing: const Icon(Icons.edit_outlined),
                      onTap: _seleccionarFecha,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<Categoria>(
                          key: ValueKey(_categoriaSeleccionada?.id),
                          initialValue: _categoriaSeleccionada,
                          style: dropdownStyle,
                          decoration: const InputDecoration(
                            labelText: 'Categoría',
                          ),
                          items: _categorias
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(
                                    '${c.emoji} ${c.nombre}',
                                    style: dropdownStyle,
                                  ),
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
                    style: dropdownStyle,
                    decoration: const InputDecoration(labelText: 'Quién pagó'),
                    items: _participantes
                        .map(
                          (p) => DropdownMenuItem(
                            value: p,
                            child: Text(
                              p.nombre,
                              style: dropdownStyle,
                            ),
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
                              onChanged: _onPorcentajeCambiado,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_nombreP2),
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
                                      labelText: _nombreP1,
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
                                      labelText: _nombreP2,
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
