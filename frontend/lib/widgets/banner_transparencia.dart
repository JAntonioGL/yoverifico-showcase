// widgets/banner_transparencia.dart
import 'package:flutter/material.dart';

class BannerTransparencia extends StatelessWidget {
  final String flowContext; // 'citas' | 'adeudos' | 'multas'
  final VoidCallback onMasInfo;

  const BannerTransparencia({
    super.key,
    required this.flowContext,
    required this.onMasInfo,
  });

  String _textoBanner(String flow) {
    final f = flow.toLowerCase();
    if (f == 'adeudos') {
      return 'Te llevaremos al portal oficial para consultar o pagar tus adeudos y podrás copiar tu placa para agilizar el trámite. También puedes abrirlo en el navegador de tu celular.';
    } else if (f == 'multas') {
      return 'Te llevaremos al sitio oficial para consultar o pagar tus multas y podrás copiar tu placa para agilizar el trámite. También puedes abrirlo en el navegador de tu celular.';
    }
    // default: citas
    return 'Te llevaremos al sitio oficial para agendar tu cita y podrás copiar tu placa para hacerlo más rápido. También puedes abrirlo en el navegador de tu celular.';
  }

  @override
  Widget build(BuildContext context) {
    final text = _textoBanner(flowContext);
    return Material(
      color: Colors.yellow.shade100,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 12.5, color: Colors.black87),
              ),
            ),
            const SizedBox(width: 6),
            TextButton(
              onPressed: onMasInfo,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              child: const Text(
                'Más info',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
