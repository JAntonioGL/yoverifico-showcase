// lib/providers/usuario_provider.dart
// Gestor de identidad, sesión y límites de suscripción del usuario.

import 'package:flutter/material.dart';
import 'package:yoverifico_app/models/usuario.dart';
import 'package:yoverifico_app/models/entitlements.dart';

/// UsuarioProvider centraliza el estado de autenticación y los permisos
/// dinámicos del plan actual (máximo de vehículos, anuncios, etc.).
class UsuarioProvider with ChangeNotifier {
  // ======= Estado de Sesión =======
  Usuario? _usuario;
  String? _token;
  bool _isLoggedIn = false;

  // ======= Entitlements (Reglas de Negocio del Plan) =======
  String _codigoPlan = 'FREE';
  bool _conAnuncios = true;
  int _maximoVehiculos = 1;
  bool _esPersonalizado = false;
  String? _nombrePlan;

  // 🔹 Cupo de vehículos (Sincronizado con el Backend)
  int _vehiGuardados = 0;
  int _vehiRestantes = 0;
  bool _puedeAgregar = true;

  // ======= Getters Semánticos =======
  Usuario? get usuario => _usuario;
  String? get token => _token;
  bool get isLoggedIn => _isLoggedIn;

  // Getters de Plan
  String get codigoPlan => _codigoPlan;
  bool get conAnuncios => _conAnuncios;
  int get maximoVehiculos => _maximoVehiculos;
  bool get esPersonalizado => _esPersonalizado;

  // Getters de Capacidad
  int get vehiGuardados => _vehiGuardados;
  int get vehiRestantes => _vehiRestantes;
  bool get puedeAgregar => _puedeAgregar;

  // ======= Métodos de Gestión de Estado =======

  /// Establece la sesión completa tras un login o refresco de token.
  void setSesion({
    required Usuario usuario,
    required String token,
    required String codigoPlan,
    required bool conAnuncios,
    required int maximoVehiculos,
    bool esPersonalizado = false,
    String? nombrePlan,
    int? vehiGuardados,
    int? vehiRestantes,
    bool? puedeAgregar,
  }) {
    /* 1. Almacena el perfil del usuario y el JWT.
       2. Mapea los límites técnicos del plan (ej. si debe ver publicidad).
       3. Sincroniza los contadores de vehículos disponibles.
       4. Notifica a toda la app para habilitar/deshabilitar funciones Premium. */
  }

  /// Actualiza exclusivamente los permisos y cuotas del plan.
  void setEntitlements(Entitlements ent) {
    /* Permite actualizar los beneficios del usuario (ej. tras una compra exitosa)
       sin necesidad de reiniciar la sesión completa o volver a cargar el perfil. */
  }

  /// Limpia el estado del usuario (Cierre de sesión).
  void clear() {
    /* Resetea todas las variables a sus valores por defecto (FREE) 
       y notifica a la UI para redirigir al Login. */
  }

  /// Actualización parcial del perfil.
  void updateUsuario(Usuario nuevo) {
    /* Permite cambiar datos específicos como el nombre o foto de perfil
       manteniendo intactos los tokens y permisos del plan. */
  }
}
