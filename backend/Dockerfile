# ===== Deps =====
FROM node:20-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production --no-audit --no-fund

# ===== Runtime =====
FROM node:20-alpine
ENV NODE_ENV=production
WORKDIR /app

# Instalar PM2 en runtime
RUN npm i -g pm2

# Usuario no root
RUN addgroup -S app && adduser -S app -G app

# Copiar deps y código con ownership del usuario app
COPY --from=deps /app/node_modules /app/node_modules
COPY --chown=app:app . /app

USER app
EXPOSE 3000

# Usar PM2 en modo clúster: 1 worker por CPU que vea el contenedor
CMD ["pm2-runtime", "start", "index.js", "-i", "3", "--name", "yv_api"]
