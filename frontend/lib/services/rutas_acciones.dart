// lib/services/rutas_gateway.sample.dart
// Diccionario centralizado de endpoints para flujos transaccionales.

/**
 * RutasAcciones centraliza los paths de la API que implementan 
 * el patrón de Prechequeo (Gating) y Ejecución.
 */
class RutasGateway {
  // Cada acción crítica requiere dos pasos para garantizar la integridad
  // del flujo de negocio y la monetización por anuncios.

  // --- GESTIÓN DE FLOTA ---
  static const String agregarVehiculoPre = '/api/v1/vehicle/add/check';
  static const String agregarVehiculoExe = '/api/v1/vehicle/add/commit';

  static const String editarVehiculoPre = '/api/v1/vehicle/edit/check';
  static const String editarVehiculoExe = '/api/v1/vehicle/edit/commit';

  // --- CICLO DE VIDA DE VERIFICACIÓN ---
  static const String actualizarVerifPre = '/api/v1/verify/update/check';
  static const String actualizarVerifExe = '/api/v1/verify/update/commit';

  // --- SEGURIDAD ---
  static const String eliminarVehiculoPre = '/api/v1/vehicle/delete/check';
  static const String eliminarVehiculoExe = '/api/v1/vehicle/delete/commit';
}
