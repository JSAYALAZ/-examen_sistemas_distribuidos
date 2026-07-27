# Stage 1: Builder
FROM node:22-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm test

# Stage 2: Production
FROM node:22-alpine AS production
RUN apk update && apk upgrade --no-cache
WORKDIR /app
ENV NODE_ENV=production PORT=3000
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force && rm -rf /usr/local/lib/node_modules/npm

COPY --from=builder /app/server.js ./
COPY --from=builder /app/db.js ./
COPY --from=builder /app/public ./public
COPY --from=builder /app/data ./data

EXPOSE 3000
CMD ["node", "server.js"]
