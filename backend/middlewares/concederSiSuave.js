// middlewares/concederSiSuave.js
const pool = require('../db/pool');
const ADS = require('../config/adsConfig');

/**
 * Si el modo es "suave", concede el pase (idempotente) y expone req._paseConcedidoSuave = true
 * Requiere que el cliente envíe el `folio` en body (el mismo que se dio en prechequeo).
 */
module.exports = async function concederSiSuave(req, res, next) {
    try {
        if (ADS.modo_aplicacion !== 'suave') return next();

        const { folio } = req.body || {};
        if (!folio) {
            // En "suave" permitimos pasar aún sin folio, pero marcamos que no se pudo conceder explícitamente
            req._paseConcedidoSuave = false;
            return next();
        }

        // Idempotente: si ya estaba concedido, tu función debe devolver el mismo estado sin fallar
        await pool.query(
            'SELECT marcar_pase_concedido($1::uuid, $2::text) AS resultado',
            [folio, 'soft_suave'] // indicamos origen "soft_suave" para trazabilidad
        );
        req._paseConcedidoSuave = true;
        return next();
    } catch (e) {
        // En modo “suave” no bloqueamos: dejamos seguir pero registramos
        console.error('concederSiSuave error:', e);
        req._paseConcedidoSuave = false;
        return next();
    }
};
