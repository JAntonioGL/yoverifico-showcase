// lib/widgets/calcomania_referencia.dart
import 'package:flutter/material.dart';

/// Muestra una imagen de calcomanía (CDMX/EdoMex) con zoom,
/// y un selector compacto para alternar entre ambas versiones.
/// - estadoPreferido: 'CDMX' o 'MEX' (opcional; default 'CDMX')
/// - alto: alto sugerido del contenedor (opcional)
class CalcomaniaReferencia extends StatefulWidget {
  final String? estadoPreferido; // 'CDMX' | 'MEX'
  final double? alto;

  const CalcomaniaReferencia({
    super.key,
    this.estadoPreferido,
    this.alto,
  });

  @override
  State<CalcomaniaReferencia> createState() => _CalcomaniaReferenciaState();
}

class _CalcomaniaReferenciaState extends State<CalcomaniaReferencia> {
  late String _estadoActual; // 'CDMX' | 'MEX'

  @override
  void initState() {
    super.initState();
    final pref = (widget.estadoPreferido ?? 'CDMX').toUpperCase();
    _estadoActual = (pref == 'MEX') ? 'MEX' : 'CDMX';
  }

  @override
  Widget build(BuildContext context) {
    final bool esCdmx = _estadoActual == 'CDMX';
    final String asset = esCdmx
        ? 'assets/images/calcomania_ejemplo_cdmx.jpg'
        : 'assets/images/calcomania_ejemplo_edomex.jpg';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Selector compacto
        Row(
          children: [
            const Text(
              'Ejemplo de calcomanía:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'CDMX', label: Text('CDMX')),
                ButtonSegment(value: 'MEX', label: Text('EdoMex')),
              ],
              selected: {_estadoActual},
              onSelectionChanged: (sel) {
                if (sel.isNotEmpty) {
                  setState(() => _estadoActual = sel.first);
                }
              },
              multiSelectionEnabled: false,
              showSelectedIcon: false,
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Viewer con zoom
        Container(
          height: widget.alto ?? 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          clipBehavior: Clip.antiAlias,
          child: InteractiveViewer(
            minScale: 0.8,
            maxScale: 4.0,
            panEnabled: true,
            child: Image.asset(
              asset,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Center(
                child: Text('Ejemplo de calcomanía'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
