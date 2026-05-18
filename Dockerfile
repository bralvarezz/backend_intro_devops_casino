# ---------- Etapa builder ---------- backend_intro_devops_casino/Dockerfile

FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./

RUN if [ -f package-lock.json ]; then \
      npm ci --omit=dev; \
    else \
      echo ">>> WARNING: package-lock.json missing, using npm install"; \
      npm install --omit=dev; \
    fi

COPY . .

# ---------- Etapa runtime ----------
FROM node:20-alpine AS runtime

ENV NODE_ENV=production

WORKDIR /app

COPY --from=builder --chown=node:node /app/node_modules ./node_modules
COPY --from=builder --chown=node:node /app/package*.json ./
COPY --from=builder --chown=node:node /app/src ./src

RUN mkdir -p /data && chown -R node:node /data

USER node

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "const req=require('http').get('http://127.0.0.1:3000/health',r=>process.exit(r.statusCode===200?0:1));req.on('error',()=>process.exit(1));req.setTimeout(2000,()=>{req.destroy();process.exit(1)})"

CMD ["node", "src/server.js"]