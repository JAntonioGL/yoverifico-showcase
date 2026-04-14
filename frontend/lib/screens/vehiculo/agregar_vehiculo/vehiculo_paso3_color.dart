// lib/screens/vehiculo/agregar/paso3_color.sample.dart

/**
 * VehiculoPaso3Color gestiona la personalización visual del registro.
 * Implementa una cuadrícula reactiva de colores basada en el catálogo local.
 */
class VehiculoPaso3Color extends StatefulWidget {
  const VehiculoPaso3Color({super.key});

  @override
  State<VehiculoPaso3Color> createState() => _VehiculoPaso3ColorState();
}

class _VehiculoPaso3ColorState extends State<VehiculoPaso3Color> {
  int? _colorSeleccionadoId;

  /// Utilidad para transformar strings hexadecimales del catálogo a objetos Color de Flutter.
  Color _colorFromHex(String hexColor) {
    // Normaliza el string (ej. "#FFFFFF" -> 0xFFFFFFFF) y retorna el objeto Color.
    /* ... implementación de parseo ... */
  }

  /// Persiste el color seleccionado y avanza al último paso del registro.
  void _continuar() {
    /* 1. Validación de selección obligatoria.
       2. Actualización del buffer temporal en VehiculoProvider.setColorId().
       3. Navegación al Paso 4 (Alias y Confirmación). */
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paso 3: Color del Vehículo')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Animación temática (color_animation.json).
                  Lottie.asset('assets/animations/color_animation.json'),

                  const TituloAnimado(text: 'Color del Vehículo'),

                  // --- Grid de Selección Cromática ---
                  // Muestra las opciones del CatalogoProvider en 3 columnas.
                  GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 1,
                        ),
                    itemCount: catalogoProvider.colores.length,
                    itemBuilder: (ctx, index) {
                      final color = catalogoProvider.colores[index];
                      final isSelected = _colorSeleccionadoId == color.id;

                      // _buildColorCard renderiza la opción con un icono de auto
                      // teñido dinámicamente y un check visual si está seleccionado.
                      return _buildColorCard(color, isSelected);
                    },
                  ),
                ],
              ),
            ),
          ),

          // Footer Fijo: Botón de acción habilitado solo tras seleccionar una opción.
          _BotonPrincipal(
            texto: 'CONTINUAR',
            onPressed: (_colorSeleccionadoId != null) ? _continuar : null,
          ),
        ],
      ),
    );
  }
}
