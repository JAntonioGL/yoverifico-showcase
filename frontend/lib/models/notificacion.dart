// lib/models/notificacion.sample.dart
// Modelo de datos para alertas locales y remotas (FCM).

/**
 * Notificacion representa un mensaje en la bandeja de entrada del usuario.
 * Soporta alertas vinculadas a vehículos específicos o avisos globales.
 */
class Notificacion {
  final int? id; // Identificador único en la base de datos local (SQLite).
  final String titulo; // Encabezado visible de la alerta.
  final String cuerpo; // Contenido detallado del mensaje.
  final String?
  vehiculoId; // ID del auto relacionado (null para avisos globales).
  final String tipo; // Categoría (ej. 'contingencia', 'recordatorio').
  final DateTime fecha; // Marca de tiempo de recepción o generación.
  final bool leida; // Estado de interacción del usuario.

  // --- Metadatos de Infraestructura ---
  final String? dedupKey; // Clave para evitar notificaciones duplicadas.
  final String? source; // Origen del mensaje: 'local' o 'remote'.
  final String?
  severity; // Nivel de importancia para estilos UI: 'info' o 'critical'.
  final String? dataJson; // Payload original para auditoría o rehidratación.

  const Notificacion({
    this.id,
    required this.titulo,
    required this.cuerpo,
    this.vehiculoId,
    required this.tipo,
    required this.fecha,
    this.leida = false,
    this.dedupKey,
    this.source,
    this.severity,
    this.dataJson,
  });

  /// Crea una copia del objeto con campos actualizados (inmutabilidad).
  Notificacion copyWith({int? id, bool? leida}) {
    /* Implementación para actualización de estados parciales. */
    return Notificacion(
      id: id ?? this.id,
      titulo: this.titulo,
      cuerpo: this.cuerpo,
      vehiculoId: this.vehiculoId,
      tipo: this.tipo,
      fecha: this.fecha,
      leida: leida ?? this.leida,
      // ... otros campos ...
    );
  }

  /// Factory para mapear registros desde SQLite, normalizando tipos
  /// de datos para asegurar consistencia en la lógica de negocio.
  factory Notificacion.fromJson(Map<String, dynamic> json) {
    return Notificacion(
      id: json['id'] as int?,
      titulo: json['titulo'] as String? ?? '',
      cuerpo: json['cuerpo'] as String? ?? '',
      vehiculoId: json['vehiculo_id'] as String?,
      tipo: json['tipo_notificacion'] as String? ?? 'programada',
      fecha: DateTime.tryParse(json['fecha'] ?? '') ?? DateTime.now(),
      leida: json['leida'] == 1 || json['leida'] == true,
      dedupKey: json['dedup_key'] as String?,
      source: json['source'] as String?,
      severity: json['severity'] as String?,
      dataJson: json['data_json'] as String?,
    );
  }

  /// Serialización para persistencia en base de datos local.
  Map<String, dynamic> toJson() => {
    'id': id,
    'titulo': titulo,
    'cuerpo': cuerpo,
    'vehiculo_id': vehiculoId,
    'tipo_notificacion': tipo,
    'fecha': fecha.toIso8601String(),
    'leida': leida ? 1 : 0,
    'dedup_key': dedupKey,
    'source': source,
    'severity': severity,
    'data_json': dataJson,
  };
}
