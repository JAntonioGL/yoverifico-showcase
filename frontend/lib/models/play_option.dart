// lib/models/play_option.sample.dart
// Modelo para la gestión de ofertas y precios regionales de Google Play.

/**
 * PlayOption encapsula los detalles de facturación de una suscripción 
 * recuperada directamente desde la Google Play Billing Library.
 */
class PlayOption {
  final String
  offerToken; // Token único requerido por Google para procesar la compra.
  final String basePlanId; // Identificador del plan base en Play Console.
  final String
  priceString; // Precio crudo devuelto por la tienda (ej. '199.00').
  final String currencyCode; // Código de moneda (ej. 'MXN', 'USD').
  final String
  periodIso8601; // Periodo de cobro en formato estándar (ej. 'P1Y').

  // --- Propiedades derivadas para la Interfaz de Usuario ---
  final String displayPrice; // Precio formateado (ej. 'MXN 199.00').
  final String periodText; // Traducción amigable del periodo (ej. 'Anual').

  PlayOption({
    required this.offerToken,
    required this.basePlanId,
    required this.priceString,
    required this.currencyCode,
    required this.periodIso8601,
    required this.displayPrice,
    required this.periodText,
  });

  /**
   * Factory para reconstruir la opción desde el caché local o la API.
   * Centraliza la lógica de formateo para asegurar que la UI sea consistente.
   */
  factory PlayOption.fromJson(Map<String, dynamic> json) {
    final price = json['price']?.toString() ?? '0.00';
    final currency = json['currency'] ?? 'MXN';
    final isoPeriod = json['period_iso8601'] ?? 'P1M';

    return PlayOption(
      offerToken: json['token'] as String,
      basePlanId: json['base_plan_id'] as String,
      priceString: price,
      currencyCode: currency,
      periodIso8601: isoPeriod,
      displayPrice: '$currency $price',
      periodText: _getPeriodText(isoPeriod), // Lógica de mapeo ISO -> Texto
    );
  }

  /// Serialización para persistencia en SharedPreferences.
  Map<String, dynamic> toJson() => {
    'token': offerToken,
    'base_plan_id': basePlanId,
    'price': priceString,
    'currency': currencyCode,
    'period_iso8601': periodIso8601,
  };
}
