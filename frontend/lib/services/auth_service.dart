// lib/services/auth_manager.sample.dart
// Gestor central de identidad y seguridad JWT.

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/**
 * AuthService gestiona el ciclo de vida de la sesión.
 * Implementa el patrón Singleton para asegurar una única fuente de verdad.
 */
class AuthManager {
  static final AuthManager instance = AuthManager._();
  final _storage = const FlutterSecureStorage();

  /**
   * Ejecuta peticiones HTTP con lógica de auto-refresco de tokens.
   * Si el Access Token expira, el servicio intenta obtener uno nuevo 
   * usando el Refresh Token antes de fallar.
   */
  Future<dynamic> requestWithAutoRefresh(Function(String token) request) async {
    String? token = await _getAccessToken();
    
    // Intento inicial
    var response = await request(token!);
    
    // Si hay error 401 (Unauthorized), disparamos flujo de refresco
    if (response.statusCode == 401) {
      final newToken = await refreshJwtSilencioso();
      if (newToken != null) {
        return await request(newToken); // Reintento transparente
      }
    }
    return response;
  }

  /**
   * Refresco silencioso de sesión.
   * Utiliza un Refresh Token almacenado de forma segura (AES-256) 
   * para obtener un nuevo set de credenciales sin molestar al usuario.
   */
  Future<String?> refreshJwtSilencioso() async {
    final refreshToken = await _storage.read(key: 'refresh_token');
    // Lógica de comunicación con el endpoint /refresh...
    return "nuevo_access_token";
  }
}