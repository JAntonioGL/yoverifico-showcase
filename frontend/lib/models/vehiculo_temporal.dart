// lib/models/vehiculo_temporal.dart

class VehiculoTemporal {
  String? marca;
  String? linea;
  String? modelo;
  String? placa;
  String? color;
  int? estadoId; // 👈 ya estaba
  String? estadoNombre; // 👈 ya estaba
  String? nombre; // 👈 nuevo campo opcional (máx 10 caracteres)

  Map<String, dynamic> toJson() => {
        'marca': marca,
        'linea': linea,
        'modelo': modelo,
        'placa': placa,
        'color': color,
        'estado_id': estadoId, // importante para el backend
        'nombre': nombre, // 👈 lo enviamos si viene
      };
}
