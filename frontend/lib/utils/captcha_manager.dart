import 'dart:async';
import 'package:flutter_gcaptcha_v3/recaptca_config.dart';

/// ---------------------------------------------------------------------------
/// CaptchaManager: Centraliza la obtención, cacheo y gestión del token de reCAPTCHA v3.
/// ---------------------------------------------------------------------------
class CaptchaManager {
  CaptchaManager._();
  static final CaptchaManager instance = CaptchaManager._();

  String? _lastToken;
  DateTime? _lastAt;
  Completer<String>? _pending; // Para manejar solicitudes concurrentes

  /// Llamado por el WebView cuando llega el token.
  void onTokenFromWebView(String token) {
    if (token.isEmpty) return;
    _lastToken = token;
    _lastAt = DateTime.now();

    // Completa la promesa si hay una espera activa.
    final p = _pending;
    if (p != null && !p.isCompleted) {
      p.complete(token);
    }
  }

  /// Indica si el token cacheado es fresco (< 60s).
  bool get _fresh =>
      _lastToken != null &&
      _lastAt != null &&
      DateTime.now().difference(_lastAt!).inSeconds < 60;

  /// Limpia explícitamente el estado cacheado. Crucial para flujos de varios pasos.
  void clearTokenAndState() {
    _lastToken = null;
    _lastAt = null;
    _pending =
        null; // No forzamos la finalización de un Completer, solo lo descartamos
  }

  /// Precalienta el WebView/reCAPTCHA en segundo plano.
  Future<void> prewarm() async {
    try {
      await RecaptchaHandler.executeV3(action: 'prewarm');
    } catch (_) {
      // Ignorar errores de precalentamiento.
    }
  }

  /// Solicita un token fresco de reCAPTCHA v3.
  ///
  /// @param action La acción (ej. 'login', 'pwd_recovery_check') que debe registrarse en reCAPTCHA.
  /// @param forceNew Si es true, ignora el token cacheado y fuerza una nueva ejecución (¡USAR EN RECUPERACIÓN!).
  /// @param timeout Tiempo máximo de espera para que el WebView devuelva el token.
  Future<String?> requestToken({
    required String action, // Ahora es requerido
    bool forceNew = false,
    Duration timeout =
        const Duration(seconds: 8), // Tiempo aumentado para mitigar fallos
  }) async {
    // 1. Manejo del Cache (Solo si NO se fuerza uno nuevo)
    // El cache es útil para login/acciones rápidas que reusan la misma action.
    if (!forceNew && _fresh) {
      return _lastToken;
    }

    // 2. Manejo de Reentrada
    if (_pending != null && !_pending!.isCompleted) {
      try {
        return await _pending!.future.timeout(timeout);
      } catch (_) {
        return null; // Falló por timeout al colgarse de una espera existente
      }
    }

    // 3. Disparar nueva ejecución
    _pending = Completer<String>();

    try {
      // 🚀 Dispara la ejecución con la action específica
      await RecaptchaHandler.executeV3(action: action);
    } catch (_) {
      // Fallo en el bridge de comunicación
      final p = _pending;
      _pending = null;
      if (p != null && !p.isCompleted) {
        p.completeError(Exception('executeV3 failed'));
      }
      return null;
    }

    // 4. Esperar el token
    try {
      final t = await _pending!.future.timeout(timeout);
      return t;
    } catch (_) {
      return null; // Falló por timeout al esperar el token
    } finally {
      _pending = null; // Limpia el estado para la siguiente solicitud
    }
  }
}
