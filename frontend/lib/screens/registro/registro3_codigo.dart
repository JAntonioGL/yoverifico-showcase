// lib/screens/registro/registro3_codigo.sample.dart

/**
 * Registro3Codigo es una pantalla de transición de estado:
 * Fase A: Validación de código de 6 dígitos con Timer de reenvío.
 * Fase B: Creación de perfil (Nombre y Password seguro).
 */
class _Registro3CodigoState extends State<Registro3Codigo> {
  bool _mostrarFormularioFinal = false; // Controla el cambio de vista interno.

  /// Valida el OTP y obtiene el ticket de registro del backend.
  Future<void> _validarCodigo() async {
    // Tras verificar satisfactoriamente, activa el formulario de perfil.
    setState(() => _mostrarFormularioFinal = true);
  }

  /// Procesa el alta final del usuario y establece la sesión.
  Future<void> _completarRegistro() async {
    /* 1. Validación de reglas de negocio en password (6-12 chars, no secuencias).
       2. Envío de datos al AuthService.registroEmail().
       3. establecerSesionCompleta(): Hidrata proveedores y genera alertas locales.
       4. Navegación atómica: pushNamedAndRemoveUntil('/home'). */
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _mostrarFormularioFinal
          ? _PasoFinal(
              onCrearCuenta: _completarRegistro,
            ) // Formulario de perfil
          : _PasoCodigo(onValidarCodigo: _validarCodigo), // Formulario de OTP
    );
  }
}
