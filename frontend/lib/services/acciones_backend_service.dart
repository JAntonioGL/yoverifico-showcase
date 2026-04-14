// lib/services/acciones_gateway.sample.dart
// Orquestador de flujos de trabajo (Workflow Orchestrator)

/**
 * AccionesBackendService gestiona la ejecución de tareas críticas
 * mediante un patrón de doble validación (Handshake).
 */
class AccionesGateway {
  
  /**
   * 1. Fase de Prechequeo:
   * Determina si el usuario tiene permisos o si debe cumplir un 
   * requisito previo (ej. Visualizar un Ad Recompensado) antes de proceder.
   */
  static Future<Prechequeo> validarAccion(String endpoint) async {
    // El backend genera un 'folio' único para asegurar que la acción 
    // sea atómica y vinculada a una validación previa.
    return await _peticionSegura(endpoint + '/prechequeo');
  }

  /**
   * 2. Fase de Ejecución:
   * Realiza el commit de la acción (Agregar Vehículo, Editar Verificación, etc.)
   * enviando el folio obtenido en el prechequeo para validar la integridad.
   */
  static Future<bool> ejecutarAccion(String endpoint, Map data, String? folio) async {
    // Se utiliza AuthService para garantizar que el JWT esté siempre fresco
    // mediante el sistema de Auto-Refresh implementado.
    final response = await _peticionSegura(endpoint + '/ejecutar', body: {
      ...data,
      'folio': folio,
    });
    
    return response.ok;
  }
}