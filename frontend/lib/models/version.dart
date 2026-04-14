// lib/models/version_policy.sample.dart
// Modelo para la gestión de políticas de actualización y ciclo de vida de la app.

/// Define el nivel de obligatoriedad de una actualización.
enum VersionDecision { ok, soft, hard, mismatch }

/**
 * VersionPolicyModel encapsula la respuesta del servidor respecto a la 
 * validez de la versión instalada y metadatos de diagnóstico local.
 */
class VersionPolicyModel {
  // ====== Atributos de Control (Backend) ======
  final VersionDecision decision; // Decisión de cumplimiento: OK | SOFT | HARD.
  final int latest; // Última versión disponible en la tienda.
  final String updateUrl; // Enlace directo a Play Store / App Store.
  final String? message; // Nota informativa para el usuario.

  // ====== Atributos de Diagnóstico (Cliente) ======
  final int appBuild; // BuildNumber actual del dispositivo.
  final DateTime lastCheckedAt; // Marca de tiempo de la última sincronización.
  final String source; // Origen de la validación (Login, Auto, Manual).

  const VersionPolicyModel({
    required this.decision,
    required this.latest,
    required this.updateUrl,
    this.message,
    required this.appBuild,
    required this.lastCheckedAt,
    required this.source,
  });

  // --- Helpers de Estado Crítico ---

  /// Indica si la app debe bloquearse hasta ser actualizada.
  bool get isHardUpdate => decision == VersionDecision.hard;

  /// Indica si hay una mejora disponible pero no obligatoria.
  bool get isSoftUpdate => decision == VersionDecision.soft;

  /**
   * Determina si la política almacenada en caché ha expirado.
   * Evita consultas excesivas al servidor respetando un TTL (Time To Live).
   */
  bool isStale(Duration ttl) {
    return DateTime.now().difference(lastCheckedAt) >= ttl;
  }

  /// Factory para construir el modelo integrando la respuesta del
  /// servidor con el contexto actual del hardware y la plataforma.
  factory VersionPolicyModel.fromSync({
    required Map<String, dynamic> payload,
    required int localBuild,
    required String trigger,
  }) {
    /* Lógica de normalización de datos y mapeo de decisiones. */
    return VersionPolicyModel(
      decision: _parseDecision(payload['decision']),
      latest: payload['latest'] ?? 0,
      updateUrl: payload['update_url'] ?? '',
      message: payload['message'],
      appBuild: localBuild,
      lastCheckedAt: DateTime.now(),
      source: trigger,
    );
  }

  /// Serialización para persistencia en SharedPreferences.
  Map<String, dynamic> toJson() => {
    'decision': decision.name,
    'latest': latest,
    'updateUrl': updateUrl,
    'appBuild': appBuild,
    'lastCheckedAt': lastCheckedAt.toIso8601String(),
    // ... otros campos ...
  };
}
