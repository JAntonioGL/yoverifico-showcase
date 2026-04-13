// middlewares/verifyAdminKey.js
require('dotenv').config();

function verifyAdminKey(req, res, next) {
    const key = req.headers['x-admin-api-key'];

    if (!key) {
        return res.status(401).json({ msg: 'Falta encabezado x-admin-api-key.' });
    }

    if (key !== process.env.ADMIN_API_KEY) {
        return res.status(403).json({ msg: 'API key inválida o no autorizada.' });
    }

    next();
}

module.exports = verifyAdminKey;
