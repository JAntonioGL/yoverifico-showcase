// lib/models/vehiculo_registrado.sample.dart
// Modelo central para la gestión de activos vehiculares y alertas legales.

/**
 * VehiculoRegistrado encapsula la identidad y el estatus legal de un vehículo.
 * Provee la estructura necesaria para calcular los periodos de verificación 
 * y las alertas de circulación preventiva.
 */
class VehiculoRegistrado {
  final int idVehiculo; // Identificador único persistido en base de datos.
  final String placa; // Identificador legal primario.
  final String modelo; // Año / Versión del vehículo.
  final String? alias; // Nombre amigable personalizado (ej. "Coche de Papá").
  final String? holograma; // Tipo de holograma (0, 00, 1, 2).
  final String ultimoDigito; // Dígito clave para el calendario de verificación.

  // --- Relaciones con Catálogos ---
  final int lineaId; // Referencia al catálogo de Marcas/Modelos.
  final int colorId; // Referencia al catálogo de Colores.
  final int estadoId; // Jurisdicción estatal para normas de tránsito.

  // --- Estado de Verificación ---
  final bool? verificadoP1; // Estatus del primer semestre del año.
  final DateTime? fechaP1; // Fecha exacta de la última verificación realizada.
  final DateTime?
  fechaLimite; // Fecha crítica calculada por el motor de reglas.

  VehiculoRegistrado({
    required this.idVehiculo,
    required this.placa,
    required this.modelo,
    this.alias,
    this.holograma,
    required this.lineaId,
    required this.colorId,
    required this.estadoId,
    required this.ultimoDigito,
    this.verificadoP1,
    this.fechaP1,
    this.fechaLimite,
    // ... otros campos de seguimiento de verificación ...
  });

  /// Getter Semántico: Prioriza el alias sobre la placa para mejorar la UX.
  String get displayNombre =>
      (alias != null && alias!.isNotEmpty) ? alias! : placa;

  /**
   * Factory que transforma el payload del servidor.
   * Maneja el parseo defensivo de fechas y la normalización de 
   * tipos numéricos/booleanos para evitar errores de ejecución.
   */
  factory VehiculoRegistrado.fromJson(Map<String, dynamic> json) {
    return VehiculoRegistrado(
      idVehiculo: json['id_vehiculo'] as int,
      placa: json['placa'].toString(),
      modelo: json['modelo'].toString(),
      alias: json['nombre'] as String?,
      holograma: json['holograma'] as String?,
      lineaId: json['linea_id'] as int,
      colorId: json['color_id'] as int,
      estadoId: json['estado_id'] as int,
      ultimoDigito: json['ultimo_digito'].toString(),
      verificadoP1: json['verificado_p1'] == true,
      fechaP1: _parseDate(json['fecha_p1']),
      fechaLimite: _parseDate(json['fecha_limite']),
    );
  }

  /// Serialización para persistencia local o sincronización de cambios.
  Map<String, dynamic> toJson() => {
    'id_vehiculo': idVehiculo,
    'placa': placa,
    'nombre': alias,
    'holograma': holograma,
    'fecha_limite': fechaLimite?.toIso8601String(),
    // ... mapeo completo para sincronización ...
  };

  static DateTime? _parseDate(dynamic value) =>
      value != null ? DateTime.tryParse(value.toString()) : null;
}
