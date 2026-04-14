// lib/widgets/bloqueo_progreso.dart
import 'package:flutter/material.dart';

class BloqueoProgreso extends StatelessWidget {
  const BloqueoProgreso({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Flexible(
                child: Text(
                  'Cerrando sesión...\nPor favor espera.',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
