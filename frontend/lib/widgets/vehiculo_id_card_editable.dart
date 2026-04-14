// widgets/vehiculo_id_card.sample.dart
// Componente de identidad vehicular con soporte para edición dinámica.

import 'package:flutter/material.dart';

class VehiculoIdCard extends StatelessWidget {
  final String marca;
  final String linea;
  final String colorHex;
  final bool modoEdicion;

  // Callbacks para desacoplar la UI de la lógica de negocio
  final VoidCallback? onEdit;

  const VehiculoIdCard({
    super.key,
    required this.marca,
    required this.linea,
    required this.colorHex,
    this.modoEdicion = false,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    // Implementación de lógica de contraste adaptativo
    final Color carColor = _parseColor(colorHex);
    final bool isLightColor = carColor.computeLuminance() > 0.7;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(child: _buildInfoColumn(context)),
            _buildVehicleIcon(carColor, isLightColor),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleIcon(Color color, bool isLight) {
    // Representación del motor de renderizado de imagen con tinte dinámico.
    // En la versión original, se aplica un ImageFilter.blur y ColorFilter
    // adaptativo para generar un efecto de 'glow' basado en la luminancia.
    return Stack(
      alignment: Alignment.center,
      children: [
        if (isLight) _buildDynamicShadow(),
        Image.asset(
          'assets/images/car_icon.png',
          color: color,
          colorBlendMode: BlendMode.srcIn,
        ),
      ],
    );
  }

  // Métodos privados para organizar la construcción de filas editables...
}
