// pantalla_home.dart - Dashboard Principal de YoVerifico
// Este archivo demuestra la implementación de una UI responsiva, 
// gestión de estados globales y animaciones de entrada.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart'; // Animaciones interactivas
import 'package:auto_size_text/auto_size_text.dart'; // UI Adaptativa
import 'package:yoverifico_app/providers/usuario_provider.dart';
import 'package:yoverifico_app/providers/contingencia_provider.dart';

class PantallaHome extends StatefulWidget {
  const PantallaHome({super.key});

  @override
  State<PantallaHome> createState() => _PantallaHomeState();
}

class _PantallaHomeState extends State<PantallaHome> with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    // Orquestación de hidratación de datos al iniciar
    // Se sincroniza la contingencia ambiental y se verifica la versión de la app
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContingenciaProvider>().syncAndHydrate();
      _cargarDatosIniciales();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UsuarioProvider>(
      builder: (context, usuarioProvider, _) {
        final usuario = usuarioProvider.usuario;
        final contingencia = context.watch<ContingenciaProvider>();

        return Column(
          children: [
            // 1. COMPONENTES DE ALERTA DINÁMICA
            // Los banners de contingencia solo aparecen si el motor de descarte 
            // del backend/local detecta una alerta activa para el usuario.
            if (contingencia.hasHoy) _ContingenciaCard(label: 'Hoy'),
            if (contingencia.hasManana) _ContingenciaCard(label: 'Mañana'),

            // 2. CUERPO PRINCIPAL CON ANIMACIONES LOTTIE
            Expanded(
              child: Column(
                children: [
                  Text('¡Hola, ${usuario?.nombre}!'),
                  Lottie.asset('assets/animations/welcome.json'),
                  
                  // 3. GRID DE ACCIONES RESPONSIVO
                  // Implementación de un LayoutBuilder para adaptar el tamaño 
                  // de los botones (tiles) según el dispositivo.
                  Expanded(
                    child: _HomeActionsGrid(
                      items: [
                        _ActionItem(title: 'Mis Vehículos', route: '/vehiculos'),
                        _ActionItem(title: 'Agendar Cita', route: '/citas'),
                        _ActionItem(title: 'Consultar Adeudos', route: '/adeudos'),
                        // ... más acciones de negocio
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // 4. BANNER DE FIDELIZACIÓN (Rating/Share)
            const _RatingShareBottomBanner(),
          ],
        );
      },
    );
  }
}

// --- Componentes de UI Escalables ---
// Se utilizan Widgets privados para desacoplar la lógica visual y 
// facilitar el mantenimiento de la interfaz.