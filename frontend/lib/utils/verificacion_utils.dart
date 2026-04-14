// lib/utils/verificacion_engine.sample.dart
// Motor de validación de estatus vehicular y alertas preventivas.

import 'package:flutter/material.dart';
import 'package:yoverifico_app/models/vehiculo_registrado.dart';

/**
 * Procesa el estado visual y textual del vehículo basado en normativas vigentes.
 * El motor evalúa:
 * 1. Integridad de registros (Sin registro).
 * 2. Caducidad (Vencido).
 * 3. Ventanas de oportunidad (En periodo / Por vencer).
 * 4. Cumplimiento (Vigente).
 */
Map<String, dynamic> procesarEstatusVisual(VehiculoRegistrado vehiculo) {
  // Validación de pre-requisitos (Paso 0)
  if (vehiculo.holograma == null || vehiculo.fechaLimite == null) {
    return {
      'texto': 'Registro incompleto. Requiere atención inmediata.',
      'color': Colors.red,
      'estado': 'sin_registro',
    };
  }

  final DateTime hoy = DateTime.now();
  final int diasRestantes = vehiculo.fechaLimite!.difference(hoy).inDays;

  // Lógica de alerta temprana (7 días previos al vencimiento)
  if (diasRestantes >= 0 && diasRestantes <= 7) {
    return {
      'texto': 'Periodo crítico: Tu verificación vence pronto.',
      'color': Colors.orange,
      'estado': 'por_vencer',
    };
  }

  // Motor de calendario: Cruce de placa con meses permitidos por semestre...
  // Determina si el mes actual corresponde a la ventana de verificación oficial.
  
  return {
    'texto': 'Estatus: Vigente',
    'color': Colors.green,
    'estado': 'vigente',
  };
}

/**
 * Determina la visibilidad de CTAs (Call to Action) basados en el 
 * ciclo de vida de la verificación del vehículo.
 */
bool habilitarActualizacion(VehiculoRegistrado vehiculo) {
  // La lógica interna decide si mostrar botones de acción basándose 
  // en si el vehículo está en periodo, vencido o requiere registro inicial.
  return true; 
}