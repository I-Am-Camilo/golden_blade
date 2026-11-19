import 'package:flutter/material.dart';

import '../models/reserva.dart';
import '../services/reserva_service.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';

class PantallaAgenda extends StatefulWidget {
  const PantallaAgenda({super.key, this.servicioApi, this.fechaInicial});
  final ReservaService? servicioApi;
  final DateTime? fechaInicial;

  @override
  State<PantallaAgenda> createState() => _PantallaAgendaState();
}

class _PantallaAgendaState extends State<PantallaAgenda> {
  final _today = DateUtils.dateOnly(DateTime.now());
  late DateTime _day = _today;
  DateTimeRange? _range;
  bool _showCalendar = false;
  int? _status;
  int? _clienteId;
  int? _servicioId;
  int? _profesionalId;
  late final ReservaService _api;
  late Future<List<Reserva>> _consulta;
  @override
  void initState() {
    super.initState();
    _api = widget.servicioApi ?? ReservaService();
    _consulta = _api.listar();
    if (widget.fechaInicial != null) {
      _day = DateUtils.dateOnly(widget.fechaInicial!);
      _showCalendar = true;
    }
  }

  @override
  void dispose() {
    _api.cerrar();
    super.dispose();
  }

  void _recargar() {
    setState(() {
      _consulta = _api.listar();
    });
  }

  Future<void> _nueva() async {
    await Navigator.pushNamed(context, AppRoutes.reservationClient);
    if (mounted) _recargar();
  }

  Future<void> _selectRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
      initialDateRange: _range,
    );
    if (mounted && range != null) {
      setState(() => _range = range);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dates = MaterialLocalizations.of(context);
    final range = _range;
    return Theme(
      data: ThemeData.light(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          centerTitle: true,
          title: const Text('Agenda'),
          actions: [
            IconButton(
              tooltip: 'Actualizar agenda',
              onPressed: _recargar,
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              tooltip: 'Nueva reserva',
              icon: const Icon(Icons.add, color: AppColors.buttonGoldDark),
              onPressed: _nueva,
            ),
          ],
        ),
        body: FutureBuilder<List<Reserva>>(
          future: _consulta,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              final error = snapshot.error;
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        error is ReservaException
                            ? error.mensaje
                            : 'No se pudieron consultar las reservas.',
                        textAlign: TextAlign.center,
                      ),
                      TextButton(
                        onPressed: _recargar,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              );
            }
            final todas = snapshot.data!;

            final clientes = {for (final r in todas) r.clienteId: r.cliente};
            final servicios = {for (final r in todas) r.servicioId: r.servicio};
            final profesionales = {
              for (final r in todas)
                if (r.profesionalId != null) r.profesionalId!: r.profesional,
            };
            final entries = todas.where((entry) {
              if (_clienteId != null && entry.clienteId != _clienteId) {
                return false;
              }
              if (_servicioId != null && entry.servicioId != _servicioId) {
                return false;
              }
              if (_profesionalId != null &&
                  entry.profesionalId != _profesionalId) {
                return false;
              }
              final date = DateUtils.dateOnly(entry.cita);
              if (_status != null && entry.estado != _status) {
                return false;
              }
              if (_showCalendar) {
                return DateUtils.isSameDay(date, _day);
              }
              return range == null ||
                  (!date.isBefore(range.start) && !date.isAfter(range.end));
            }).toList();

            return SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: 520,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Lista'),
                            selected: !_showCalendar,
                            selectedColor: AppColors.goldAccent,
                            onSelected: (_) =>
                                setState(() => _showCalendar = false),
                          ),
                          ChoiceChip(
                            label: const Text('Calendario'),
                            selected: _showCalendar,
                            selectedColor: AppColors.goldAccent,
                            onSelected: (_) =>
                                setState(() => _showCalendar = true),
                          ),
                        ],
                      ),
                      if (_showCalendar)
                        CalendarDatePicker(
                          initialDate: _day,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100, 12, 31),
                          onDateChanged: (date) => setState(() => _day = date),
                        )
                      else
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.date_range_outlined),
                          title: Text(
                            range == null
                                ? 'Todas las fechas'
                                : '${dates.formatCompactDate(range.start)} – ${dates.formatCompactDate(range.end)}',
                          ),
                          onTap: _selectRange,
                          trailing: range == null
                              ? null
                              : IconButton(
                                  tooltip: 'Limpiar fechas',
                                  onPressed: () =>
                                      setState(() => _range = null),
                                  icon: const Icon(Icons.close),
                                ),
                        ),
                      DropdownButton<int>(
                        isExpanded: true,
                        value: _status ?? -1,
                        items: [
                          const DropdownMenuItem(
                            value: -1,
                            child: Text('Todos los estados'),
                          ),
                          for (
                            var index = 0;
                            index < Reserva.estados.length;
                            index++
                          )
                            DropdownMenuItem(
                              value: index,
                              child: Text(Reserva.estados[index]),
                            ),
                        ],
                        onChanged: (value) => setState(
                          () => _status = value == -1 ? null : value,
                        ),
                      ),
                      ExpansionTile(
                        title: const Text(
                          'Filtrar cliente, servicio y profesional',
                        ),
                        children: [
                          _filtro('Cliente', _clienteId, clientes, (valor) {
                            setState(() {
                              _clienteId = valor;
                            });
                          }),
                          _filtro('Servicio', _servicioId, servicios, (valor) {
                            setState(() {
                              _servicioId = valor;
                            });
                          }),
                          _filtro(
                            'Profesional',
                            _profesionalId,
                            profesionales,
                            (valor) {
                              setState(() {
                                _profesionalId = valor;
                              });
                            },
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _clienteId = null;
                            _servicioId = null;
                            _profesionalId = null;
                            _status = null;
                            _range = null;
                            _showCalendar = false;
                          });
                        },
                        child: const Text('Limpiar filtros'),
                      ),
                      const SizedBox(height: 12),
                      if (entries.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'No hay reservas para esta selección.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      for (final entry in entries)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            tileColor: AppColors.fieldBackground,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            leading: const Icon(
                              Icons.event_outlined,
                              color: AppColors.buttonGoldDark,
                            ),
                            title: Text(entry.cliente),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () async {
                              await Navigator.of(context).pushNamed(
                                AppRoutes.reservationDetail,
                                arguments: entry,
                              );
                              if (mounted) _recargar();
                            },
                            subtitle: Text(
                              '${entry.servicio} · ${entry.profesional}\n'
                              '${dates.formatCompactDate(entry.cita)} · '
                              '${TimeOfDay.fromDateTime(entry.cita).format(context)}\n'
                              '${entry.estadoTexto} · Reserva #${entry.id}',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _filtro(
    String etiqueta,
    int? seleccionado,
    Map<int, String> opciones,
    ValueChanged<int?> cambiar,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: DropdownButtonFormField<int>(
      key: ValueKey('$etiqueta-$seleccionado-${opciones.keys.join(",")}'),
      initialValue: opciones.containsKey(seleccionado) ? seleccionado : -1,
      isExpanded: true,
      decoration: InputDecoration(labelText: etiqueta),
      items: [
        const DropdownMenuItem(value: -1, child: Text('Todos')),
        for (final opcion in opciones.entries)
          DropdownMenuItem(
            value: opcion.key,
            child: Text(
              '${opcion.value} · ID ${opcion.key}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (valor) => cambiar(valor == -1 ? null : valor),
    ),
  );
}
