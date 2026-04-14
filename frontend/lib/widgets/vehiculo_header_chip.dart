import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/vehiculo_registrado.dart';
import '../providers/catalogo_provider.dart';
import '../models/vehiculo_modelos.dart';

/// Muestra una línea centrada con el ícono del vehículo (color real),
/// su nombre o línea, y la placa, sobre un fondo azul claro.
class VehiculoHeaderChip extends StatelessWidget {
  final VehiculoRegistrado vehiculo;
  final bool center;

  const VehiculoHeaderChip({
    super.key,
    required this.vehiculo,
    this.center = true,
  });

  @override
  Widget build(BuildContext context) {
    final catalogo = context.watch<CatalogoProvider>();

    // Marca / línea
    final linea = catalogo.lineas.firstWhere(
      (l) => l.id == vehiculo.lineaId,
      orElse: () => const LineaVehiculo(id: 0, nombre: 'N/A', marcaId: 0),
    );
    final marca = catalogo.marcas.firstWhere(
      (m) => m.id == linea.marcaId,
      orElse: () => const MarcaVehiculo(id: 0, nombre: 'N/A'),
    );

    // Color del ícono
    final colorModelo = catalogo.colores.firstWhere(
      (c) => c.id == vehiculo.colorId,
      orElse: () => const ColorVehiculo(id: 0, nombre: 'N/A', hex: '000000'),
    );
    final Color iconColor = _hexToColor(colorModelo.hex);

    // Texto principal
    final bool hasNombre =
        vehiculo.nombre != null && vehiculo.nombre!.trim().isNotEmpty;
    final String titulo =
        hasNombre ? vehiculo.nombre!.trim() : '${marca.nombre} ${linea.nombre}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      margin: const EdgeInsets.only(top: 8, bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F2FF), // azul muy claro
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment:
            center ? MainAxisAlignment.center : MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          Icon(Icons.directions_car, color: iconColor, size: 22),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '$titulo  •  Placa: ${vehiculo.placa}',
              textAlign: center ? TextAlign.center : TextAlign.start,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey.shade800,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _hexToColor(String hex) {
    final cleaned = hex.replaceAll('#', '').padLeft(6, '0');
    return Color(int.parse('0xFF$cleaned'));
  }
}
