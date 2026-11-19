import '../screens/pantalla_jornadas.dart';

import 'package:flutter/material.dart';

import '../services/sesion_service.dart';
import '../services/almacenamiento_sesion_service.dart';

import '../models/servicio.dart';
import '../models/cierre.dart';
import '../models/comision.dart';
import '../screens/pantalla_detalle_comision.dart';
import '../screens/pantalla_cierre_generado.dart';
import '../screens/pantalla_detalle_cierre.dart';
import '../models/reserva.dart';
import '../models/profesional.dart';
import '../models/especialidad.dart';

import '../screens/pantalla_inasistencias.dart';
import '../screens/pantalla_panel_administrativo.dart';
import '../screens/pantalla_agenda.dart';
import '../screens/pantalla_cierres.dart';
import '../screens/pantalla_comisiones.dart';
import '../screens/pantalla_nuevo_cierre.dart';
import '../screens/pantalla_resumen_cierre.dart';
import '../models/cliente.dart';
import '../screens/pantalla_detalle_cliente.dart';
import '../screens/pantalla_clientes.dart';
import '../screens/pantalla_formulario_cliente.dart';
import '../screens/login_screen.dart';
import '../screens/pantalla_formulario_profesional.dart';
import '../screens/pantalla_detalle_profesional.dart';
import '../screens/pantalla_profesionales.dart';
import '../screens/pantalla_formulario_servicio.dart';
import '../screens/pantalla_restablecer_contrasena.dart';
import '../screens/pantalla_seleccionar_profesional.dart';
import '../screens/pantalla_reserva_creada.dart';
import '../screens/pantalla_detalle_reserva.dart';
import '../screens/pantalla_reagendar_reserva.dart';
import '../screens/pantalla_cancelar_reserva.dart';
import '../screens/pantalla_revisar_reserva.dart';
import '../screens/pantalla_seleccionar_fecha_hora.dart';
import '../screens/pantalla_servicios.dart';
import '../screens/pantalla_especialidades.dart';
import '../screens/pantalla_formulario_especialidad.dart';
import '../screens/splash_screen.dart';
import '../screens/pantalla_codigo_verificacion.dart';
import '../screens/pantalla_bienvenida.dart';
import '../screens/pantalla_horario_semanal.dart';

class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const resetPassword = '/reset-password';
  static const verificationCode = '/verification-code';
  static const welcome = '/welcome';
  static const adminPanel = '/admin-panel';
  static const specialties = '/specialties';
  static const services = '/services';
  static const professionals = '/professionals';
  static const agenda = '/agenda';
  static const closings = '/closings';
  static const commissions = '/commissions';
  static const commissionDetail = '/commission-detail';
  static const newClosing = '/new-closing';
  static const closingCreated = '/closing-created';
  static const closingDetail = '/closing-detail';
  static const closingSummary = '/closing-summary';
  static const reservationClient = '/reservation-client';
  static const rescheduleReservation = '/reschedule-reservation';
  static const cancelReservation = '/cancel-reservation';
  static const reservationService = '/reservation-service';
  static const reservationProfessional = '/reservation-professional';
  static const reservationTime = '/reservation-time';
  static const reservationReview = '/reservation-review';
  static const reservationCreated = '/reservation-created';
  static const reservationDetail = '/reservation-detail';
  static const clients = '/clients';
  static const newClient = '/new-client';
  static const editClient = '/edit-client';
  static const clientDetail = '/client-detail';
  static const newProfessional = '/new-professional';
  static const editProfessional = '/edit-professional';
  static const professionalDetail = '/professional-detail';
  static const weeklySchedule = '/weekly-schedule';
  static const schedules = '/schedules';
  static const absences = '/absences';
  static const newService = '/new-service';
  static const editService = '/edit-service';
  static const newSpecialty = '/new-specialty';
  static const editSpecialty = '/edit-specialty';

  // Las rutas de acceso son públicas; las demás requieren una sesión activa.
  static Route<dynamic> generarRuta(RouteSettings settings) {
    var nombre = settings.name ?? login;
    const publicas = [splash, login, resetPassword, verificationCode];
    if (!publicas.contains(nombre) && !SesionService.activa) nombre = login;
    final builder = screens[nombre] ?? screens[login]!;
    return MaterialPageRoute(
      settings: RouteSettings(
        name: nombre,
        arguments: nombre == settings.name ? settings.arguments : null,
      ),
      builder: builder,
    );
  }

  static final screens = <String, WidgetBuilder>{
    splash: (context) => SplashScreen(
      onFinished: () async {
        try {
          final sesion = await AlmacenamientoSesionService.recuperar();
          if (!context.mounted) return;
          if (sesion != null) SesionService.iniciar(sesion);
        } catch (_) {
          // Si el dispositivo no permite leer el almacenamiento, pedimos login.
          SesionService.cerrar();
        }
        if (!context.mounted) return;
        Navigator.of(context)
            .pushReplacementNamed(SesionService.activa ? adminPanel : login);
      },
    ),
    login: (context) => const LoginScreen(),
    resetPassword: (context) => const PantallaRestablecerContrasena(),
    verificationCode: (context) => const PantallaCodigoVerificacion(),
    welcome: (context) => const PantallaBienvenida(),
    adminPanel: (context) => const PantallaPanelAdministrativo(),
    specialties: (context) => const PantallaEspecialidades(),
    services: (context) => const PantallaServicios(),
    professionals: (context) => const PantallaProfesionales(),
    agenda: (context) {
      final fecha = ModalRoute.of(context)?.settings.arguments;
      return PantallaAgenda(fechaInicial: fecha is DateTime ? fecha : null);
    },
    closings: (context) => const PantallaCierres(),
    commissionDetail: (context) {
      final comision = ModalRoute.of(context)?.settings.arguments;
      if (comision is Comision) {
        return PantallaDetalleComision(comision: comision);
      }
      return const PantallaComisiones();
    },
    commissions: (context) {
      final cierre = ModalRoute.of(context)?.settings.arguments;
      return PantallaComisiones(
        cierre: cierre is Cierre ? cierre : null,
        profesional: cierre is Profesional ? cierre : null,
      );
    },
    newClosing: (context) => const PantallaNuevoCierre(),
    closingCreated: (context) {
      final cierre = ModalRoute.of(context)?.settings.arguments;
      if (cierre is Cierre) return PantallaCierreGenerado(cierre: cierre);
      return const PantallaCierres();
    },
    closingDetail: (context) {
      final cierre = ModalRoute.of(context)?.settings.arguments;
      if (cierre is Cierre) return PantallaDetalleCierre(cierre: cierre);
      return const PantallaCierres();
    },
    closingSummary: (context) {
      final periodo = ModalRoute.of(context)?.settings.arguments;
      if (periodo is DateTimeRange) {
        return PantallaResumenCierre(periodo: periodo);
      }
      return const PantallaNuevoCierre();
    },
    reservationClient: (context) => const PantallaClientes(selecting: true),
    reservationService: (context) {
      final client = ModalRoute.of(context)?.settings.arguments;
      if (client is Cliente) {
        return PantallaServicios(cliente: client);
      }
      return const PantallaClientes(selecting: true);
    },
    reservationProfessional: (context) {
      final selection = ModalRoute.of(context)?.settings.arguments;
      if (selection is (Cliente, Servicio, String)) {
        return PantallaSeleccionarProfesional(
          client: selection.$1,
          service: selection.$2,
          nombreEspecialidad: selection.$3,
        );
      }
      return const PantallaClientes(selecting: true);
    },
    reservationTime: (context) {
      final selection = ModalRoute.of(context)?.settings.arguments;
      if (selection is (Cliente, Servicio, List<Profesional>, String)) {
        return PantallaSeleccionarFechaHora(
          client: selection.$1,
          service: selection.$2,
          professionals: selection.$3,
          professionalLabel: selection.$4,
        );
      }
      return const PantallaClientes(selecting: true);
    },
    reservationReview: (context) {
      final selection = ModalRoute.of(context)?.settings.arguments;
      if (selection is (Cliente, Servicio, String, DateTime, int?)) {
        return PantallaRevisarReserva(
          client: selection.$1,
          service: selection.$2,
          professionalLabel: selection.$3,
          appointment: selection.$4,
          profesionalId: selection.$5,
        );
      }
      return const PantallaClientes(selecting: true);
    },
    rescheduleReservation: (context) {
      final reserva = ModalRoute.of(context)?.settings.arguments;
      return reserva is Reserva
          ? PantallaReagendarReserva(reserva: reserva)
          : const PantallaAgenda();
    },
    cancelReservation: (context) {
      final reserva = ModalRoute.of(context)?.settings.arguments;
      return reserva is Reserva
          ? PantallaCancelarReserva(reserva: reserva)
          : const PantallaAgenda();
    },
    reservationDetail: (context) {
      final reservation = ModalRoute.of(context)?.settings.arguments;
      if (reservation is Reserva) {
        return PantallaDetalleReserva(reserva: reservation);
      }
      return const PantallaAgenda();
    },
    reservationCreated: (context) {
      final reservation = ModalRoute.of(context)?.settings.arguments;
      if (reservation is Reserva) {
        return PantallaReservaCreada(reserva: reservation);
      }
      return const PantallaAgenda();
    },
    clients: (context) => const PantallaClientes(),
    clientDetail: (context) {
      final selection = ModalRoute.of(context)?.settings.arguments;
      if (selection is Cliente) {
        return PantallaDetalleCliente(cliente: selection);
      }
      return const PantallaClientes();
    },
    editClient: (context) {
      final selection = ModalRoute.of(context)?.settings.arguments;
      if (selection is Cliente) {
        return PantallaFormularioCliente(cliente: selection);
      }
      return const PantallaClientes();
    },
    newClient: (context) => const PantallaFormularioCliente(),
    professionalDetail: (context) {
      final selection = ModalRoute.of(context)?.settings.arguments;
      if (selection is Profesional) {
        return PantallaDetalleProfesional(profesional: selection);
      }
      return const PantallaProfesionales();
    },
    absences: (context) {
      final professional = ModalRoute.of(context)?.settings.arguments;
      if (professional is Profesional) {
        return PantallaInasistencias(professional: professional);
      }
      return const PantallaProfesionales();
    },
    schedules: (context) => const PantallaJornadas(),
    weeklySchedule: (context) {
      final professional = ModalRoute.of(context)?.settings.arguments;
      if (professional is Profesional) {
        return PantallaHorarioSemanal(professional: professional);
      }
      return const PantallaProfesionales();
    },
    newProfessional: (context) => const PantallaFormularioProfesional(),
    editProfessional: (context) {
      final selection = ModalRoute.of(context)?.settings.arguments;
      if (selection is Profesional) {
        return PantallaFormularioProfesional(profesional: selection);
      }
      return const PantallaProfesionales();
    },
    newService: (context) => const PantallaFormularioServicio(),
    editService: (context) {
      final service = ModalRoute.of(context)?.settings.arguments;
      if (service is Servicio) {
        return PantallaFormularioServicio(servicio: service);
      }
      return const PantallaServicios();
    },
    newSpecialty: (context) => const PantallaFormularioEspecialidad(),
    editSpecialty: (context) {
      final specialty = ModalRoute.of(context)?.settings.arguments;
      if (specialty is Especialidad) {
        return PantallaFormularioEspecialidad(especialidad: specialty);
      }
      return const PantallaEspecialidades();
    },
  };
}
