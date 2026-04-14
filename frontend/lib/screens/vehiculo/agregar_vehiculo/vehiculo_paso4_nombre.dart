// lib/screens/vehiculo/agregar/paso4_nombre.sample.dart

/**
 * VehiculoPaso4Nombre gestiona la personalización de la identidad del vehículo.
 * Implementa una previsualización dinámica del título y validación de longitud.
 */
class VehiculoPaso4Nombre extends StatefulWidget {
  const VehiculoPaso4Nombre({super.key});

  @override
  State<VehiculoPaso4Nombre> createState() => _VehiculoPaso4NombreState();
}

class _VehiculoPaso4NombreState extends State<VehiculoPaso4Nombre> {
  final TextEditingController _nombreCtrl = TextEditingController();

  /// Genera una previsualización del título final combinando alias, marca y línea.
  String _formateaPreview(String marca, String linea) {
    final alias = _nombreCtrl.text.trim();
    return alias.isNotEmpty ? '$alias ($marca $linea)' : '$marca $linea';
  }

  /// Valida el alias y actualiza el buffer temporal.
  void _continuar() {
    /* 1. Sanitización: Trim del texto ingresado.
       2. Validación: Solo alfanumérico y máximo 10 caracteres.
       3. Persistencia: Actualiza VehiculoProvider.setNombre().
       4. Navegación: Salta a la pantalla final de Confirmación. */
  }

  /// Permite avanzar sin asignar un alias personalizado.
  void _omitir() {
    context.read<VehiculoProvider>().setNombre(null);
    Navigator.pushNamed(context, '/vehiculo/agregar/confirmar');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paso 4: Ponle nombre')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Animación temática (name_animation.json).
            Lottie.asset('assets/animations/name_animation.json'),

            const TituloAnimado(text: 'Ponle nombre'),

            // --- Previsualización Dinámica ---
            // Muestra al usuario cómo se verá su vehículo en la lista principal.
            _buildLivePreviewCard(_formateaPreview(marca, linea)),

            // --- Input con Restricciones Técnicas ---
            TextField(
              controller: _nombreCtrl,
              maxLength: 10,
              textCapitalization: TextCapitalization.words,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 ]')),
              ],
              decoration: const InputDecoration(labelText: 'Nombre (opcional)'),
              onChanged: (_) =>
                  setState(() {}), // Dispara el refresco del preview
            ),

            // Acciones: Omitir (Outlined) o Continuar (Sólido)
            _buildActionButtons(onOmitir: _omitir, onContinuar: _continuar),
          ],
        ),
      ),
    );
  }
}
