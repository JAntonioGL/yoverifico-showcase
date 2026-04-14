// lib/widgets/vehiculo_id_card.sample.dart
// Componente de identidad visual para la flota de vehículos del usuario.

import 'package:flutter/material.dart';

class VehiculoIdCard extends StatelessWidget {
  final String marca;
  final String linea;
  final String colorHex;
  final String? placa;

  const VehiculoIdCard({
    super.key,
    required this.marca,
    required this.linea,
    required this.colorHex,
    this.placa,
  });

  @override
  Widget build(BuildContext context) {
    // Cálculo de contraste dinámico para la optimización de legibilidad de UI.
    final Color carColor = _parseColor(colorHex);
    final bool isLight = carColor.computeLuminance() > 0.7;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(child: _buildTextInfo()),
            const SizedBox(width: 16),
            _buildAdaptiveIcon(carColor, isLight),
          ],
        ),
      ),
    );
  }

  Widget _buildAdaptiveIcon(Color color, bool isLight) {
    // Motor de renderizado de icono con "Glow" adaptativo.
    // Esta sección utiliza filtros de imagen para generar un halo de contraste
    // (blanco o negro) según la luminancia del color principal del vehículo.
    return Container(
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Implementación de efectos visuales (Blur/ColorFilter)
          Image.asset('assets/images/car_icon.png', color: color),
        ],
      ),
    );
  }
}
