// lib/services/notificacion_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config.dart';
import '../services/auth_service.dart'; // 👈 para requestWithAutoRefresh

class NotificacionService {
  /// Programa una notificación desde la app (JWT requerido).
  /// Importante: la fecha se envía en UTC ISO-8601 (con 'Z').
  static Future<bool> programarNotificacion({
    required int idVehiculo,
    required String titulo,
    required String mensaje,
    required DateTime fechaProgramada, // hora local del usuario
  }) async {
    try {
      final url = Uri.parse('$backendBaseUrl/api/notificaciones/programar');

      // Enviar SIEMPRE en UTC para que el backend lo normalice bien
      final fechaIsoUtc = fechaProgramada.toUtc().toIso8601String();

      final resp = await AuthService.instance.requestWithAutoRefresh(
        (access) => http.post(
          url,
          headers: {
            'Authorization': 'Bearer $access',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'id_vehiculo': idVehiculo,
            'titulo': titulo,
            'mensaje': mensaje,
            'fecha_programada': fechaIsoUtc,
          }),
        ),
      );

      if (resp.statusCode == 201) {
        final json = jsonDecode(resp.body);
        // opcional: usa json['id_notificacion'] si lo necesitas
        return true;
      } else {
        // logs útiles para diagnóstico
        // ignore: avoid_print
        print('Error servicio notificación [${resp.statusCode}]: ${resp.body}');
        return false;
      }
    } catch (e) {
      // ignore: avoid_print
      print('Excepción al programar notificación: $e');
      return false;
    }
  }
}
