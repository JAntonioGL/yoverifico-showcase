import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/vehiculo_modelos.dart';

enum EstadoCatalogo { inicial, cargando, listo, error }

class CatalogoProvider with ChangeNotifier {
  // Estado interno: Listas privadas para marcas, líneas, colores y estados.
  List<MarcaVehiculo> _marcas = [];
  List<LineaVehiculo> _lineas = [];
  List<ColorVehiculo> _colores = [];
  List<EstadoMexico> _estados = [];
  EstadoCatalogo _estado = EstadoCatalogo.inicial;

  // Getters: Proveen acceso público a los datos cargados y al estado actual.
  List<MarcaVehiculo> get marcas => _marcas;
  List<LineaVehiculo> get lineas => _lineas;
  List<ColorVehiculo> get colores => _colores;
  List<EstadoMexico> get estados => _estados;
  EstadoCatalogo get estado => _estado;

  CatalogoProvider() {
    // Constructor: Inicia automáticamente la carga de datos al instanciar el provider.
    cargarCatalogoDesdeAssets();
  }

  Future<void> cargarCatalogoDesdeAssets() async {
    /* 1. Cambia el estado a 'cargando' y notifica a la UI.
       2. Accede a la carpeta 'assets/data/' para leer los archivos JSON de:
          - Marcas
          - Líneas
          - Colores
          - Estados de la república
       3. Decodifica el texto JSON y lo convierte en objetos de modelo (Listas de clases).
       4. Asigna los resultados a las variables privadas.
       5. Cambia el estado a 'listo' y notifica a los widgets para que se redibujen.
       6. En caso de fallo (archivo inexistente o JSON mal formado), captura el error.
    */
  }
}
