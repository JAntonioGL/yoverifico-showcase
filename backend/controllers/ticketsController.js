// controllers/ticketsController.js
const path = require('path');
const fs = require('fs/promises');
const fssync = require('fs');
const crypto = require('crypto');
const multer = require('multer');
const pool = require('../db/pool');

// ---------- Config de uploads (carpeta privada en el VPS montada al contenedor) ----------
const UPLOAD_DIR = process.env.BUG_UPLOAD_DIR || '/data/bug-uploads'; // AJUSTA a tu ruta

// Crea la carpeta si no existe
async function ensureDir(dir) {
    try { await fs.mkdir(dir, { recursive: true }); } catch (_) { }
}

// Multer en memoria para validar/nombrar y luego escribir nosotros al disco
const upload = multer({
    storage: multer.memoryStorage(),
    limits: { files: 3, fileSize: 5 * 1024 * 1024 }, // 3 archivos, 5 MB c/u
    fileFilter: (_req, file, cb) => {
        const ok = ['image/webp', 'image/jpeg', 'image/png'].includes(file.mimetype);
        cb(ok ? null : new Error('MIME no permitido (use webp/jpeg/png)'), ok);
    }
});

// Helpers
const asEnumTrack = (v) => ({ internal: 'internal', closed: 'closed', prod: 'prod' }[String(v || '').toLowerCase()]);
const asEnumClas = (v) => ({ urgente: 'urgente', normal: 'normal' }[String(v || '').toLowerCase()]);
function trimOrNull(s) {
    if (s == null) return null;
    const t = String(s).trim();
    return t.length ? t : null;
}

// ========== USUARIO: POST /api/bugs  (una sola llamada multipart) ==========
const crearTicket = [
    upload.array('files', 3), // campo files[] desde Flutter/Postman
    async (req, res) => {
        const savedTemps = [];
        const movedFinals = [];
        try {
            const userId = req.usuarioId; // viene de verifyToken
            if (!userId) return res.status(401).json({ msg: 'No autorizado' });

            // Meta (text form-data)
            const {
                version,
                track: trackRaw,
                descripcion_breve: breveRaw,
                descripcion_detallada: detalleRaw,
                clasificacion: clasRaw
            } = req.body || {};

            const versionStr = trimOrNull(version);
            const track = asEnumTrack(trackRaw);
            const descripcion_breve = trimOrNull(breveRaw);
            const descripcion_detallada = trimOrNull(detalleRaw);
            const clasificacion = asEnumClas(clasRaw) || 'normal';

            if (!versionStr || !track || !descripcion_breve) {
                return res.status(400).json({ msg: 'Faltan campos: version, track (internal|closed|prod), descripcion_breve.' });
            }

            // Archivos validados por multer
            const files = Array.isArray(req.files) ? req.files : [];

            // Directorios base
            await ensureDir(UPLOAD_DIR);

            // 1) Guardar a TMP
            const tempDir = path.join(UPLOAD_DIR, 'tmp');
            await ensureDir(tempDir);

            for (const file of files) {
                const ext = file.mimetype === 'image/webp' ? '.webp'
                    : file.mimetype === 'image/png' ? '.png'
                        : file.mimetype === 'image/jpeg' ? '.jpg'
                            : '.bin';
                const name = crypto.randomUUID() + ext;
                const abs = path.join(tempDir, name);
                await fs.writeFile(abs, file.buffer, { flag: 'wx' });
                savedTemps.push({ absPath: abs, mime: file.mimetype, size: file.size });
            }

            // 2) Insertar ticket (SIN adjuntos) para obtener id
            const insertTicketSQL = `
        SELECT public._insertar_ticket_definer(
          $1::int,                -- user_id
          $2::text,               -- version
          $3::public.ticket_track,
          $4::text,               -- descripcion_breve
          $5::text,               -- descripcion_detallada
          $6::public.ticket_clasificacion,
          $7::jsonb               -- adjuntos (vacío)
        ) AS ticket_id
      `;
            const { rows: r1 } = await pool.query(insertTicketSQL, [
                userId, versionStr, track, descripcion_breve, descripcion_detallada, clasificacion, '[]'
            ]);
            const ticketId = r1?.[0]?.ticket_id;
            if (!ticketId) throw new Error('No se pudo crear ticket');

            // 3) Mover archivos a carpeta final del ticket
            const ticketDir = path.join(UPLOAD_DIR, 'bugs', String(ticketId));
            await ensureDir(ticketDir);

            const finalAdjuntos = [];
            for (const t of savedTemps) {
                const finalName = crypto.randomUUID() + path.extname(t.absPath);
                const finalAbs = path.join(ticketDir, finalName);
                await fs.rename(t.absPath, finalAbs);
                movedFinals.push(finalAbs);
                finalAdjuntos.push({
                    path_privado: finalAbs,   // ruta privada en el VPS
                    mime: t.mime,
                    tamano_bytes: t.size,
                    ancho_px: null,
                    alto_px: null
                });
            }

            // 4) Registrar adjuntos en DB (NO se vuelve a crear ticket)
            if (finalAdjuntos.length > 0) {
                await pool.query(
                    'SELECT public._agregar_adjuntos_definer($1::bigint, $2::jsonb)',
                    [ticketId, JSON.stringify(finalAdjuntos)]
                );
            }

            return res.status(201).json({ ticket_id: Number(ticketId), estado: 'open', clasificacion });
        } catch (err) {
            console.error('Error en crearTicket:', err);

            // Limpieza best-effort: borra finales y temporales si falló
            try {
                for (const p of movedFinals) { await fs.unlink(p).catch(() => { }); }
                for (const t of savedTemps) { await fs.unlink(t.absPath).catch(() => { }); }
            } catch (_) { }

            if (String(err.message || '').includes('MIME no permitido')) {
                return res.status(415).json({ msg: 'Tipo de archivo no permitido (usa webp/jpeg/png).' });
            }
            if (String(err.message || '').includes('File too large')) {
                return res.status(413).json({ msg: 'Archivo demasiado grande (máx. 5 MB por imagen).' });
            }
            return res.status(500).json({ msg: 'Error al crear ticket.' });
        }
    }
];


// ========== SOPORTE: GET /admin/bugs  (lista, detalle, o binario) ==========
async function adminLeerTickets(req, res) {
    try {
        const { id, attachment, track = null, estado = null, user_id = null, limit = 50, offset = 0 } = req.query || {};

        // 1) Binario: ?id=123&attachment=456
        if (id && attachment) {
            const sql = `
    SELECT path_privado, mime, eliminado_en
    FROM public._obtener_adjunto_path_definer($1::bigint, $2::bigint)
    LIMIT 1
  `;
            const { rows } = await pool.query(sql, [Number(id), Number(attachment)]);
            const row = rows?.[0];
            if (!row || row.eliminado_en) return res.status(404).end();

            const abs = row.path_privado;
            if (!abs || !fssync.existsSync(abs)) return res.status(404).end();

            const stat = await fs.stat(abs);
            res.setHeader('Content-Type', row.mime || 'application/octet-stream');
            res.setHeader('Content-Length', stat.size);
            res.setHeader('Cache-Control', 'private, no-store');
            res.setHeader('Content-Disposition', `inline; filename="${path.basename(abs)}"`);
            return fssync.createReadStream(abs).pipe(res);
        }


        // 2) Detalle: ?id=123
        if (id) {
            const sqlTicket = `SELECT * FROM public._obtener_ticket_definer($1::bigint)`;
            const { rows: trows } = await pool.query(sqlTicket, [Number(id)]);
            if (!trows?.length || !trows[0]?._obtener_ticket_definer) {
                return res.status(404).json({ msg: 'No encontrado' });
            }
            const ticket = trows[0]._obtener_ticket_definer;

            const sqlAdj = `SELECT public._listar_adjuntos_definer($1::bigint) AS attachments`;
            const { rows: arows } = await pool.query(sqlAdj, [Number(id)]);
            const attachments = arows?.[0]?.attachments ?? [];

            return res.json({ ticket, attachments });
        }

        // 3) Listado paginado con filtros
        const sql = `
      SELECT * FROM public._listar_tickets_definer(
        $1::public.ticket_track, $2::public.ticket_estado, $3::int, $4::int, $5::int
      )
    `;
        const params = [
            track ? String(track) : null,
            estado ? String(estado) : null,
            user_id ? Number(user_id) : null,
            Number(limit) || 50,
            Number(offset) || 0
        ];
        const { rows } = await pool.query(sql, params);
        return res.json(rows || []);
    } catch (err) {
        console.error('Error en adminLeerTickets:', err);
        return res.status(500).json({ msg: 'Error al consultar tickets.' });
    }
}
// ========== SOPORTE: POST /admin/bugs/:id (estado + comentarios_dev) ==========
async function adminActualizarTicket(req, res) {
    try {
        const id = Number(req.params.id);
        if (!Number.isInteger(id) || id <= 0) return res.status(400).json({ msg: 'id inválido' });

        const estado = String(req.body?.estado || '').toLowerCase();
        const comentarios_dev = trimOrNull(req.body?.comentarios_dev);
        if (!['open', 'in_progress', 'resolved', 'closed'].includes(estado)) {
            return res.status(400).json({ msg: 'estado inválido' });
        }

        const sql = `SELECT public._actualizar_ticket_definer($1::bigint, $2::public.ticket_estado, $3::text)`;
        await pool.query(sql, [id, estado, comentarios_dev]);
        return res.json({ ok: true, id, estado, comentarios_dev: comentarios_dev || null });
    } catch (err) {
        console.error('Error en adminActualizarTicket:', err);
        return res.status(500).json({ msg: 'Error al actualizar ticket.' });
    }
}

module.exports = {
    crearTicket,
    adminLeerTickets,
    adminActualizarTicket,
};
