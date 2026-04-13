const pool = require('../db/pool');

const getVersionPolicy = async (req, res) => {
    console.log('SE LLAMO VERSION POLICY');
    try {

        // Headers esperados
        const appId = req.header('X-App-Id');
        const platform = (req.header('X-App-Platform') || '').toLowerCase(); // 'android' | 'ios'
        const trackHeader = (req.header('X-Track') || '').toLowerCase();     // 'internal' | 'closed' | 'prod'
        const buildHeader = req.header('X-App-Build');

        // Validación básica de headers
        if (!appId || !platform || !trackHeader || !buildHeader) {
            return res.status(400).json({
                msg: 'Faltan headers requeridos: X-App-Id, X-App-Platform, X-Track, X-App-Build'
            });
        }

        const build = Number.parseInt(buildHeader, 10);
        if (!Number.isInteger(build) || build <= 0) {
            return res.status(400).json({ msg: 'X-App-Build debe ser un entero positivo' });
        }

        // Busca la política y la banda que "contenga" el build
        // La vista une app_track (bandas) + app_version_policy (min/rec/last)
        const { rows } = await pool.query(
            `
      SELECT
        app_id,
        platform,
        track,
        versioncode_min_range,
        versioncode_max_range,
        versioncode_min,
        versioncode_recommended,
        versioncode_latest,
        update_url,
        message_soft,
        message_hard,
        updated_at,
        updated_by
      FROM public.vista_app_politica_con_rangos
      WHERE app_id = $1
        AND platform = $2
        AND $3 BETWEEN versioncode_min_range AND versioncode_max_range
      LIMIT 1
      `,
            [appId, platform, build]
        );

        if (rows.length === 0) {
            // No hay banda que cubra este build → trata como "app no reconocida / fuera de canal"
            return res.status(400).json({
                decision: 'mismatch',
                message: 'Build fuera de cualquier banda configurada para la app/plataforma',
                received: { appId, platform, trackHeader, build }
            });
        }

        const policy = rows[0];

        // Doble candado: comparar track inferido (por banda) vs X-Track
        if (policy.track !== trackHeader) {
            return res.status(400).json({
                decision: 'mismatch',
                expected_track: policy.track,
                received_track: trackHeader,
                message: 'Build no coincide con el canal declarado (banda vs X-Track). Reinstala desde el programa correcto.'
            });
        }

        // Decisión por versión
        const { versioncode_min: min, versioncode_recommended: rec, versioncode_latest: last } = policy;

        if (build < min) {
            // Bloqueo duro → 426 Upgrade Required
            return res.status(426).json({
                decision: 'hard',
                track: policy.track,
                min,
                latest: last,
                message: policy.message_hard || 'Actualiza para continuar.',
                update_url: policy.update_url
            });
        }

        if (build < rec) {
            // Sugerido → 200
            return res.status(200).json({
                decision: 'soft',
                track: policy.track,
                recommended: rec,
                latest: last,
                message: policy.message_soft || 'Hay una nueva versión disponible.',
                update_url: policy.update_url
            });
        }

        // Todo bien → 200
        return res.status(200).json({
            decision: 'ok',
            track: policy.track,
            latest: last,
            updated_at: policy.updated_at,
            updated_by: policy.updated_by
        });
    } catch (error) {
        console.error('Error en getVersionPolicy:', error);
        return res.status(500).json({ msg: 'Error al obtener política de versión' });
    }
};

module.exports = { getVersionPolicy };
