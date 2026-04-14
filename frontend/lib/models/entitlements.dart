// lib/models/entitlements.sample.dart
// Modelo de derechos y límites de suscripción (Business Rules).

/**
 * Entitlements define las capacidades técnicas habilitadas para el usuario.
 * Controla límites de flota, visualización de publicidad y acceso a funciones premium.
 */
class Entitlements {
  final String planCode; // Identificador del plan (ej. 'FREE', 'PRO').
  final bool hasAds; // Determina si se inyecta lógica de publicidad.
  final int vehicleLimit; // Capacidad máxima de la flota permitida.

  // Gestión de cuotas en tiempo real
  final int storedVehicles; // Conteo actual de registros en la nube.
  final int remainingSlots; // Espacios disponibles para nuevos registros.
  final bool canAddMore; // Flag de control para la UI de 'Agregar Vehículo'.

  // Metadatos de personalización
  final bool
  isCustomPlan; // Bloquea/habilita la visibilidad del catálogo público.
  final String?
  friendlyName; // Nombre comercial del plan (ej. 'Plan Colaborador').

  Entitlements({
    required this.planCode,
    required this.hasAds,
    required this.vehicleLimit,
    this.storedVehicles = 0,
    this.remainingSlots = 0,
    this.canAddMore = true,
    this.isCustomPlan = false,
    this.friendlyName,
  });

  /// Factory que normaliza la respuesta del backend, manejando
  /// múltiples alias para asegurar compatibilidad entre versiones del API.
  factory Entitlements.fromJson(Map<String, dynamic> json) {
    return Entitlements(
      planCode: (json['codigo_plan'] ?? 'FREE').toString(),
      hasAds: json['con_anuncios'] ?? true,
      vehicleLimit: _toInt(json['maximo_vehiculos'], defaultVal: 1),
      storedVehicles: _toInt(json['vehi_guardados']),
      remainingSlots: _toInt(json['vehi_restantes']),
      canAddMore: json['puede_agregar'] == true,
      isCustomPlan: json['es_personalizado'] == true,
      friendlyName: (json['plan_nombre'] ?? json['nombre_plan'])?.toString(),
    );
  }

  /// Serialización para almacenamiento seguro en persistencia local.
  Map<String, dynamic> toJson() => {
    'codigo_plan': planCode,
    'con_anuncios': hasAds,
    'maximo_vehiculos': vehicleLimit,
    'vehi_guardados': storedVehicles,
    'vehi_restantes': remainingSlots,
    'puede_agregar': canAddMore,
    'es_personalizado': isCustomPlan,
    if (friendlyName != null) 'plan_nombre': friendlyName,
  };

  /// Helper privado para garantizar la integridad de tipos numéricos.
  static int _toInt(dynamic v, {int defaultVal = 0}) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? defaultVal;
    return defaultVal;
  }
}
