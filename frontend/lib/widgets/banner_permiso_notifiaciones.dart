import 'package:flutter/material.dart';

class BannerPermisoNotifiaciones extends StatelessWidget {
  final bool visible;
  final VoidCallback onActivate;

  const BannerPermisoNotifiaciones({
    super.key,
    required this.visible,
    required this.onActivate,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    // Misma UI compacta que ya utilizas.
    return Material(
      elevation: 4.0,
      child: Container(
        color: Colors.amber[600],
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            const Icon(Icons.notifications_off, color: Colors.black),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Activa las notificaciones para recibir recordatorios o alertas importantes como contingencias o posibles vencimientos en tus verificaciones.',
                style: TextStyle(color: Colors.black),
              ),
            ),
            TextButton(
              onPressed: onActivate,
              child: const Text(
                'Activar',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
