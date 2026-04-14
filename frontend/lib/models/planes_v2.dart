// lib/models/planes_v2.dart
import 'dart:convert';

/**
 * PlanV2 define la estructura de las suscripciones disponibles.
 * Mapea tanto beneficios de negocio (vehículos, anuncios) como
 * metadatos técnicos para la integración con pasarelas de pago.
 */
class PlanV2 {
  final int id;
  final String codigo; // Identificador único (ej. 'PLATINUM_V2').
  final String nombre; // Nombre comercial visible al usuario.
  final String descripcion; // Detalles de los beneficios incluidos.
  final int maximoVehiculos; // Límite de vehículos permitidos por el plan.
  final bool conAnuncios; // Define si el usuario verá publicidad.
  final double precioMxnAnual; // Precio de referencia en moneda local.
  final String currency; // Moneda (ej. 'MXN').

  // --- Metadatos de Tienda (Play Store) ---
  final String? playProductId; // ID del producto en Google Play.
  final String? playBasePlanId; // ID del plan base en la consola de Google.
  final String? playOfferId; // ID de la oferta específica (si aplica).

  // --- Flags de Estado y Control ---
  final int rank; // Orden de visualización en el catálogo.
  final bool esPersonalizado; // Indica si es un plan especial no público.
  final bool adquiribleEnApp; // Define si se puede comprar desde el móvil.
  final bool visibleEnApp; // Define si debe aparecer en el catálogo actual.
  final String periodoIso8601; // Frecuencia de cobro (ej. 'P1Y' para anual).

  const PlanV2({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.descripcion,
    required this.maximoVehiculos,
    required this.conAnuncios,
    required this.precioMxnAnual,
    required this.currency,
    this.playProductId,
    this.playBasePlanId,
    this.playOfferId,
    this.rank = 0,
    this.esPersonalizado = false,
    this.adquiribleEnApp = true,
    this.visibleEnApp = true,
    required this.periodoIso8601,
  });

  /**
   * FACTORY FROMJSON
   * Transforma la respuesta del API en una instancia de PlanV2.
   * Incluye lógica de normalización para asegurar que los tipos de datos
   * (como precios o booleanos) sean consistentes independientemente del backend.
   */
  factory PlanV2.fromJson(Map<String, dynamic> json) {
    return PlanV2(
      id: json['id'] as int,
      codigo: json['codigo'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      descripcion: json['descripcion'] as String? ?? '',
      maximoVehiculos: json['maximo_vehiculos'] as int? ?? 1,
      conAnuncios: json['con_anuncios'] == true,
      precioMxnAnual: (json['precio_mxn_anual'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'MXN',
      playProductId: json['play_product_id'] as String?,
      playBasePlanId: json['play_base_plan_id'] as String?,
      playOfferId: json['play_offer_id'] as String?,
      rank: json['rank'] as int? ?? 0,
      esPersonalizado: json['es_personalizado'] == true,
      adquiribleEnApp: json['adquirible_en_app'] != false,
      visibleEnApp: json['visible_en_app'] != false,
      periodoIso8601: json['periodo_iso8601'] as String? ?? 'P1Y',
    );
  }

  /**
   * MÉTODO TOJSON
   * Convierte la instancia a un mapa para persistencia local (cache)
   * o para enviar datos de vuelta al servidor si es necesario.
   */
  Map<String, dynamic> toJson() => {
    'id': id,
    'codigo': codigo,
    'nombre': nombre,
    'descripcion': descripcion,
    'maximo_vehiculos': maximoVehiculos,
    'con_anuncios': conAnuncios,
    'precio_mxn_anual': precioMxnAnual,
    'currency': currency,
    'play_product_id': playProductId,
    'play_base_plan_id': playBasePlanId,
    'play_offer_id': playOfferId,
    'rank': rank,
    'es_personalizado': esPersonalizado,
    'adquirible_en_app': adquiribleEnApp,
    'visible_en_app': visibleEnApp,
    'periodo_iso8601': periodoIso8601,
  };

  /**
   * GETTER DISPLAYPRICE
   * Proporciona un string formateado (ej. "$199.00 MXN") para ser
   * utilizado directamente en widgets de la interfaz de usuario.
   */
  String get displayPrice => '\$${precioMxnAnual.toStringAsFixed(2)} $currency';

  /**
   * GETTER PERIODTEXT
   * Traduce códigos técnicos de periodos (ISO8601) a términos amigables
   * para el usuario final (ej. de 'P1M' a 'Mensual').
   */
  String get periodText {
    if (periodoIso8601.contains('Y')) return 'Anual';
    if (periodoIso8601.contains('M')) return 'Mensual';
    return 'Recurrente';
  }
}
