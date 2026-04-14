// lib/screens/vehiculo/agregar/introduccion_vehiculo.sample.dart

/**
 * IntroduccionVehiculoScreen prepara al usuario para el flujo de registro.
 * Reinicia el estado del buffer temporal (VehiculoProvider) para asegurar
 * una captura limpia de datos.
 */
class IntroduccionVehiculoScreen extends StatelessWidget {
  const IntroduccionVehiculoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar Nuevo Vehículo')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Título con entrada animada para mejorar el engagement.
              const TituloAnimado(text: 'Registra tu Vehículo'),

              // Copy educativo: Lista los documentos y datos necesarios.
              const CuerpoTextoAnimado(
                text:
                    'Para comenzar, necesitaremos datos básicos como '
                    'Marca, Línea, Modelo, Color y Placa.',
              ),

              // Elemento Visual: Animación Lottie temática de vehículo.
              AnimatedWidgetWrapper(
                delay: const Duration(milliseconds: 1800),
                child: Lottie.asset('assets/animations/car_animation.json'),
              ),

              // Acción Principal: Limpieza de estado y navegación.
              BotonPrincipal(
                texto: 'COMENZAR REGISTRO',
                onPressed: () {
                  // Se garantiza que el buffer temporal esté vacío antes de iniciar.
                  context.read<VehiculoProvider>().reset();
                  Navigator.pushNamed(context, '/vehiculo/agregar/paso1');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
