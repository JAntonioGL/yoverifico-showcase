// lib/services/recuperar_gateway.sample.dart
// Orquestador del flujo de recuperación de credenciales y seguridad OTP.

/**
 * RecuperarService gestiona el ciclo de vida del restablecimiento de contraseña.
 * Implementa un flujo de tres factores: Solicitud -> Verificación -> Reset.
 */
class RecuperarGateway {
  static final RecuperarGateway instance = RecuperarGateway._();
  RecuperarGateway._();

  /**
   * 1. Solicitud de Código (OTP):
   * Dispara el envío de un código de verificación al correo del usuario.
   * Requiere validación de reCAPTCHA v3 para prevenir ataques de enumeración.
   */
  Future<void> solicitarCodigo(String correo, String captchaToken) async {
    // El servicio comunica al backend el deseo de resetear la cuenta.
    // Se gestiona un 'cooldown' en el servidor para evitar spam.
    await _post('/api/auth/password/otp/request', {
      'correo': correo,
      'captchaToken': captchaToken,
    });
  }

  /**
   * 2. Verificación de Identidad:
   * Valida el código OTP ingresado por el usuario.
   * Si es correcto, el backend emite un 'Ticket de Verificación' (JWT corto).
   */
  Future<String> verificarCodigo(String correo, String codigo) async {
    // Esta fase es crítica: el ticket devuelto es el único medio
    // autorizado para realizar el cambio final de contraseña.
    final response = await _post('/api/auth/password/otp/verify', {
      'correo': correo,
      'codigo': codigo,
    });
    return response['ticket']; // JWT de propósito específico
  }

  /**
   * 3. Ejecución del Cambio:
   * Realiza el cambio de contraseña utilizando el Ticket obtenido.
   * El ticket garantiza que el usuario que cambia la clave es el mismo 
   * que verificó el correo minutos antes.
   */
  Future<void> actualizarPassword(String ticket, String nuevaPassword) async {
    // Commit final de la nueva credencial.
    await _post('/api/auth/password/reset', {
      'ticket': ticket,
      'newPassword': nuevaPassword,
    });
  }
}
