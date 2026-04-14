// lib/helpers/calificacion_helper.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yoverifico_app/config.dart';

class CalificacionHelper {
  static const String _clavePuedeMostrarMensaje =
      'puede_mostrar_mensaje_calificacion';
  static const String _claveUltimaVezMostrado =
      'ultima_vez_mostrado_calificacion';

  /// Obtiene instancia de SharedPreferences (uso interno)
  static Future<SharedPreferences> _prefs() async {
    return await SharedPreferences.getInstance();
  }

  /// Marca al usuario como elegible para ver el mensaje
  /// (Se usa cuando hace acciones importantes por primera vez).
  static Future<void> marcarUsuarioElegible() async {
    final prefs = await _prefs();
    final yaPuede = prefs.getBool(_clavePuedeMostrarMensaje) ?? false;
    if (!yaPuede) {
      await prefs.setBool(_clavePuedeMostrarMensaje, true);
    }
  }

  /// Lee si el usuario ya es elegible para ver el mensaje.
  static Future<bool> obtenerPuedeMostrarMensaje() async {
    final prefs = await _prefs();
    return prefs.getBool(_clavePuedeMostrarMensaje) ?? false;
  }

  /// Obtiene la última fecha en que se mostró el mensaje.
  /// Null = nunca se ha mostrado.
  static Future<DateTime?> obtenerUltimaVezMostrado() async {
    final prefs = await _prefs();
    final valor = prefs.getString(_claveUltimaVezMostrado);
    if (valor == null) return null;
    try {
      return DateTime.parse(valor);
    } catch (_) {
      return null;
    }
  }

  /// Guarda la fecha actual como última vez mostrado.
  static Future<void> registrarMostradoAhora() async {
    final prefs = await _prefs();
    final ahora = DateTime.now().toIso8601String();
    await prefs.setString(_claveUltimaVezMostrado, ahora);
  }

  // ---------------------------------------------------------------------------
  //  1) LÓGICA PARA PANTALLAS DE ACCIONES (flujo "forzado")
  // ---------------------------------------------------------------------------

  /// Llamar después de una acción importante (actualizar verificación, etc.).
  ///
  /// Devuelve true si **debe mostrarse** el popup AHORA en esa pantalla.
  ///
  /// Lógica:
  /// - Si puedeMostrarMensaje == false → lo pone en true y devuelve false (no mostrar).
  /// - Si puedeMostrarMensaje == true y ultimaVezMostrado == null → mostrar y registrar fecha.
  /// - Si puedeMostrarMensaje == true y ultimaVezMostrado != null → mostrar y registrar fecha.
  static Future<bool> evaluarMostrarDespuesDeAccion() async {
    final prefs = await _prefs();

    final puedeMostrar = prefs.getBool(_clavePuedeMostrarMensaje) ?? false;
    final ultimaStr = prefs.getString(_claveUltimaVezMostrado);
    DateTime? ultimaVezMostrado;
    if (ultimaStr != null) {
      try {
        ultimaVezMostrado = DateTime.parse(ultimaStr);
      } catch (_) {
        ultimaVezMostrado = null;
      }
    }

    // Caso A: todavía no es elegible → lo marcamos como elegible y NO mostramos
    if (!puedeMostrar) {
      await prefs.setBool(_clavePuedeMostrarMensaje, true);
      return false;
    }

    // Caso B: ya es elegible, siempre mostramos (sea primera vez o no)
    await registrarMostradoAhora();
    return true;
  }

  // ---------------------------------------------------------------------------
  //  2) LÓGICA PARA HOME / MIS VEHÍCULOS (flujo amable con días)
  // ---------------------------------------------------------------------------

  /// Llamar al entrar a Home o Mis Vehículos.
  ///
  /// Devuelve true si se debe mostrar el popup en esa pantalla.
  ///
  /// Lógica:
  /// - Si puedeMostrarMensaje == false → false.
  /// - Si puedeMostrarMensaje == true y ultimaVezMostrado == null → true (primer mensaje).
  /// - Si puedeMostrarMensaje == true y han pasado >= X días → true.
  /// - Si puedeMostrarMensaje == true y NO han pasado X días → false.
  static Future<bool> evaluarMostrarEnPantallaPrincipal() async {
    final prefs = await _prefs();

    final puedeMostrar = prefs.getBool(_clavePuedeMostrarMensaje) ?? false;
    if (!puedeMostrar) return false;

    final ultimaStr = prefs.getString(_claveUltimaVezMostrado);
    DateTime? ultimaVezMostrado;
    if (ultimaStr != null) {
      try {
        ultimaVezMostrado = DateTime.parse(ultimaStr);
      } catch (_) {
        ultimaVezMostrado = null;
      }
    }

    // Nunca se ha mostrado → primer mensaje
    if (ultimaVezMostrado == null) {
      await registrarMostradoAhora();
      return true;
    }

    final ahora = DateTime.now();
    final diferenciaDias = ahora.difference(ultimaVezMostrado).inDays;

    if (diferenciaDias >= diasEntrePromptsCalificacion) {
      await registrarMostradoAhora();
      return true;
    }

    return false;
  }
}
