// utils/redisClient.js
const IORedis = require('ioredis');

const {
    REDIS_URL,
    REDIS_HOST = 'localhost',
    REDIS_PORT = '6379',
    REDIS_PASS = '',
} = process.env;

const url = REDIS_URL || (
    REDIS_PASS
        ? `redis://default:${encodeURIComponent(REDIS_PASS)}@${REDIS_HOST}:${REDIS_PORT}`
        : `redis://${REDIS_HOST}:${REDIS_PORT}`
);


let client;
function getRedis() {
    if (!client) {
        const url = process.env.REDIS_URL || 'redis://localhost:6379';
        client = new IORedis(url, {
            lazyConnect: true,
            maxRetriesPerRequest: 2,
            enableOfflineQueue: false,
        });
        client.on('error', (e) => console.error('[redis] error:', e.message));
    }
    return client;
}

module.exports = { getRedis };
