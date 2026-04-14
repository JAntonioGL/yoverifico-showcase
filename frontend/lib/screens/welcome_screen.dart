// screens/welcome_screen.dart (MODIFICADO)

import 'package:flutter/material.dart';
import '../widgets/mi_boton.dart'; // Ajusta la ruta si es necesario

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ... (Logo y texto de bienvenida se quedan igual)
              Image.asset(
                'assets/images/cuadrado_con_texto.png', // <-- Usa la ruta correcta a tu logo
                height: 120, // Ajusta el tamaño como necesites
              ),
              const SizedBox(height: 24),
              const Text(
                'Te damos la bienvenida a Yo Verifico',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Tu app para que no se te pase',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 60),

              // Botón de Iniciar Sesión
              MiBoton(
                texto: 'Iniciar Sesión',
                onPressed: () {
                  // Navega usando el nombre de la ruta
                  Navigator.pushNamed(context, '/login');
                },
              ),

              const SizedBox(height: 16),

              // Botón de Registrarse
              MiBoton(
                texto: 'Registrarse',
                onPressed: () {
                  // Navega usando el nombre de la ruta
                  Navigator.pushNamed(context, '/registro/paso1');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
