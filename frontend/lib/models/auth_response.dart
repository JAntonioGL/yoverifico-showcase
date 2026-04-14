// lib/models/auth_response.sample.dart
// Modelo que encapsula la respuesta exitosa del servidor tras la autenticación.

import 'usuario.dart';
import 'entitlements.dart';

/**
 * AuthResponse representa el payload de sesión del usuario.
 * Integra el token de acceso JWT y el perfil de beneficios del plan.
 */
class AuthResponse {
  final String token; // Access Token (JWT) para peticiones autenticadas.
  final Usuario usuario; // Perfil básico del usuario (Nombre, ID, Correo).
  final Entitlements
  entitlements; // Configuración de beneficios y límites del plan.
  final String? context; // Metadatos adicionales sobre el origen de la sesión.

  AuthResponse({
    required this.token,
    required this.usuario,
    required this.entitlements,
    this.context,
  });

  /// Factory para construir el modelo desde la respuesta JSON del API de YoVerifico.
  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: (json['token'] ?? '').toString(),
      usuario: Usuario.fromJson(json['usuario'] ?? {}),
      entitlements: Entitlements.fromJson(json['entitlements'] ?? {}),
      context: json['context']?.toString(),
    );
  }

  /// Serialización para persistencia local en caché.
  Map<String, dynamic> toJson() => {
    'token': token,
    'usuario': usuario.toJson(),
    'entitlements': entitlements.toJson(),
    if (context != null) 'context': context,
  };
}
