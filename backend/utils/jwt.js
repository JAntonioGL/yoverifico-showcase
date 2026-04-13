/**
 * JWT Utility Module (Showcase Version)
 * Demuestra la gestión de tokens de sesión y tickets de un solo propósito (Signup/OTP).
 */

const jwt = require('jsonwebtoken');

// Configuración extraída de variables de entorno para mayor seguridad
const JWT_SECRET = process.env.JWT_SECRET;
const SESSION_OPTS = {
  audience: process.env.JWT_AUDIENCE,
  issuer:   process.env.JWT_ISSUER,
  expiresIn: '7d'
};

/**
 * Emite un token de sesión con claims personalizados.
 * Incluye el nivel de suscripción y límites de usuario para optimizar la lógica en el frontend.
 */
function emitirToken(userData) {
  const payload = {
    id: userData.id,
    plan: userData.plan,
    maxVehiculos: userData.maxVehiculos,
  };
  return jwt.sign(payload, JWT_SECRET, { ...SESSION_OPTS, algorithm: 'HS256' });
}

/**
 * Emite un "Ticket JWT" para el flujo de registro.
 * Este token es de corta duración y tiene una audiencia específica (signup),
 * lo que impide que sea utilizado en rutas de API generales.
 */
function emitirSignupTicket(email) {
  return jwt.sign(
    { email: email.toLowerCase(), purpose: 'signup' },
    JWT_SECRET,
    { 
        audience: 'yoverifico-signup', 
        issuer: 'yoverifico', 
        expiresIn: '10m', // Tiempo limitado para completar el registro
        algorithm: 'HS256' 
    }
  );
}

module.exports = { emitirToken, emitirSignupTicket };