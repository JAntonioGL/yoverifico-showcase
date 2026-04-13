const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_DATABASE,
  password: process.env.DB_PASSWORD,
  port: process.env.DB_PORT,
  // Si estamos en producción, usa el objeto de configuración SSL.
  // Si no (local/docker), ponlo en false para que conecte plano.
  ssl: process.env.NODE_ENV === 'production'
    ? { rejectUnauthorized: false }
    : false,
  max: 10,                // 🔹 máximo de conexiones simultáneas por proceso
  idleTimeoutMillis: 10000, // 🔹 cierra conexiones inactivas después de 10s
});

module.exports = pool;
